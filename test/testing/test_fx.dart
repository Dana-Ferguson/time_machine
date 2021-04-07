// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';
import 'dart:mirrors';
import 'dart:io';

import 'package:test/test.dart';
import 'package:time_machine/src/time_machine_internal.dart';
import '../text/pattern_test_data.dart';
import 'test_fx_attributes.dart';

// todo: should this be a separate test_package?
// todo: it seems the test runner is synchronous, I guess that's okay
//  --> before I integrated test.dart, we were asynchronous
//      (async tests ran in parallel, but I can see that doing weird things to the tests)
// todo: can we had the stack_trace portions from here?

// Note: this won't work for Dart4Web applications
// I was going to use Reflectable, but it's 2.0 version adds too much boiler (in a viral fashion --> fixable via build.yaml???)
// Transformers are dead in 2.0, long live build.yaml???
// #feature: I would love if I could drop a comment right above this like `#var_color:F3D4D2` and then this variable gets a special color;
const bool testGenTest = false;
String? _classVarName;
StringBuffer _gen_sb_imports = StringBuffer();
StringBuffer _gen_sb_methodCalls = StringBuffer();
String _testFilePath = 'unknown_test.dart';

Iterable<TestCase> toTestCases(TestCaseSource testCaseSource, ObjectMirror mirror) {
  var argumentsSource = mirror.getField(testCaseSource.source).reflectee as Iterable?;

  if (argumentsSource == null || argumentsSource.isEmpty) return const [];
  var testCases = <TestCase>[];

  for (var arguments in argumentsSource) {
    if (arguments is TestCaseData) {
      if (arguments.arguments is List) testCases.add(TestCase(arguments.arguments as Iterable, arguments.name));
      else testCases.add(TestCase([arguments.arguments], arguments.name));
    }
    else if (arguments is List) testCases.add(TestCase(arguments));
    else testCases.add(TestCase([arguments]));
  }

  return testCases;
}

int _skippedTotal = 0;

Future runTests() async {
  // this doesn't work, but I believe it should
  // var lib = currentMirrorSystem().isolate.rootLibrary.declarations;
  // this works! (but will require more boilerplate than I want)
  // var lib4 = currentMirrorSystem().findLibrary(new Symbol('testFx'));

  var testLibs = currentMirrorSystem()
      .libraries.values.where((lib) => lib.uri.scheme == 'file' && lib.uri.path.endsWith('_test.dart'))
      .toList(growable: false);

  var futures = <Future>[];

  for (var lib in testLibs) {
    if (testGenTest) _printImport(lib.uri);

    for (DeclarationMirror declaration in lib.declarations.values) {
      if (testGenTest && declaration is MethodMirror && _nameOf(declaration) == 'setup') _setupMethod = true;
      if (declaration.metadata.isEmpty) continue;

      var test = declaration.metadata.where((m) => m.reflectee is Test).map((m) => m.reflectee as Test).toList(growable: false);
      if (test.isEmpty) continue;

      // todo: merge with other code
      // should we collate all found test names?
      var testName = test.first.name;
      if (testName == null) {
        var libSimpleName= _stripSymbol(lib.simpleName);
        var sb = StringBuffer();
        if (libSimpleName.isNotEmpty) sb..write(libSimpleName)..write('.');
        sb.write(_stripSymbol(declaration.simpleName));
        testName = sb.toString();
      }

      var skipThisTest = declaration.metadata.any((m) => m.reflectee is SkipMe);
      if (skipThisTest) {
        _skippedTotal++;
        var reason = (declaration.metadata.firstWhere((m) => m.reflectee is SkipMe).reflectee as SkipMe).reason;
        if (reason == null) print('skipped $testName');
        else print('skipped $testName because $reason');
        continue;
      }

      if (declaration is MethodMirror) {
        futures.addAll(_runTest(lib, declaration, testName));
      } else if (declaration is ClassMirror) {
        futures.addAll(_runTestsInClass(lib, declaration, testName));
      }
    }
  }

  if (_skippedTotal != 0) print('Total Tests Skipped = $_skippedTotal;');
  if (testGenTest) _writeTestGenFile();

  await Future.wait(futures);
}

void _writeTestGenFile() {
  var sb = StringBuffer();
  sb.writeln("import 'dart:async';");
  sb.writeln("import 'dart:math' as math;");
  sb.writeln();
  sb.writeln("import 'package:test/test.dart';");
  sb.writeln();
  sb.writeln("import 'package:time_machine/src/time_machine_internal.dart';");
  sb.writeln("import '../time_machine_testing.dart';");
  if (_includeTestCulturesImport) {
    sb.writeln("import '../text/test_cultures.dart';");
  }
  sb.writeln();

  sb.write(_gen_sb_imports);
  sb.writeln();

  sb.writeln('Future main() async {');
  sb.writeln('  await TimeMachine.initialize();');
  if (_getTzdb) {
    sb.writeln('  var tzdb = await DateTimeZoneProviders.tzdb;');
  }
  if (_setupMethod) {
    sb.writeln('  await setup();');
  }
  sb.writeln();
  sb.write(_gen_sb_methodCalls);
  sb.writeln('}');


  var file = File(_testFilePath);
  file.writeAsString(sb.toString(), mode: FileMode.writeOnly);

  print("written '$_testFilePath' to drive.");
}

void _printImport(Uri uri) {
  var sb = _gen_sb_imports..write("import '.."); // test/");
  var path = uri.pathSegments;

  for (var p in path.skipWhile((p) => p != 'test').skip(1)) {
    sb..write('/')..write(p);
  }
  sb..write("';")..writeln();

  _testFilePath = '/' + path.takeWhile((p) => p != 'test').join('/') + '/test/test_gen/' + path.last;
}

void _printTestCall(ObjectMirror mirror, MethodMirror method, String testName, [TestCase? testCase]) {
  var sb = _gen_sb_methodCalls..write("  test('$testName', () ");

  var isFuture = method.returnType.hasReflectedType && method.returnType.reflectedType == Future;
  isFuture = true; // note: this is an override
  if (isFuture) sb.write('async => await ');
  //  else sb.write('=> ');

  if (_classVarName != null/*mirror is ClassMirror*/) sb..write(_classVarName)..write('.');

  sb.write(_nameOf(method));

  sb.write ('(');
  if (testCase != null) {
    var first = true;
    for (var arg in testCase.arguments) {
      if (!first) {
        sb.write(', ');
      }
      else {
        first = false;
      }

      sb.write(_printNewObject(arg));
    }
  }
  // ${testCase.arguments.join(', ')});
  sb.write ('));');

  sb.writeln();
}

bool _includeTestCulturesImport = false;
bool _getTzdb = false;
bool _setupMethod = false;

String _printNewObject(Object obj) {
  var sb = StringBuffer();
if (obj is String) {
    // todo: I need to scape this?
    sb..write("'")..write(_escapeText(obj))..write("'");
  }
  else if (obj is Culture) {
    var name = obj.name;
    if (name == '') {
      sb.write('null');
    }
    else if (name == 'AwkwardAmPmDesignatorCulture') {
      sb.write('TestCultures.AwkwardAmPmDesignatorCulture');
      _includeTestCulturesImport = true;
    }
    else if (name == 'AwkwardDayOfWeekCulture') {
      sb.write('TestCultures.AwkwardDayOfWeekCulture');
      _includeTestCulturesImport = true;
    }
    else if (name == 'GenitiveNameTestCultureWithLeadingNames') {
      sb.write('TestCultures.GenitiveNameTestCultureWithLeadingNames');
      _includeTestCulturesImport = true;
    }
    else if (name == 'GenitiveNameTestCulture') {
      sb.write('TestCultures.GenitiveNameTestCulture');
      _includeTestCulturesImport = true;
    }
    else if (name == 'fi-FI-DotTimeSeparator') {
      sb.write('TestCultures.DotTimeSeparator');
      _includeTestCulturesImport = true;
    }
    else if (name == 'fr-FI') {
      sb.write('TestCultures.DotTimeSeparator');
      _includeTestCulturesImport = true;
    }
    else if (name == 'fr-CA') {
      sb.write('TestCultures.FrCa');
      _includeTestCulturesImport = true;
    }
    else if (name == 'fr-FR') {
      sb.write('TestCultures.FrFr');
      _includeTestCulturesImport = true;
    }
    else if (name == 'en-US') {
      sb.write('TestCultures.EnUs');
      _includeTestCulturesImport = true;
    }
    /*else if (name == '') {
      sb.write('TestCultures.');
    }*/
    else if (name == Culture.invariantId) {
      sb.write('Cultures.invariantCulture');
    }
    // see: LocaltimePatternTests.CreateCustomAmPmCulture
    else if (name == 'ampmDesignators') {
      sb.write("new Culture('ampmDesignators'/*Culture.invariantCultureId*/, (new DateTimeFormatInfoBuilder.invariantCulture()..amDesignator = '${obj
          .dateTimeFormat.amDesignator}'..pmDesignator = '${obj.dateTimeFormat.pmDesignator}').Build())");
    }
    else sb.write('await Cultures.getCulture("$name")');
  }
  else if (obj is PatternTestData) {
    sb.write('new ${obj.runtimeType}(${_printNewObject(obj.Value)})');
    if (obj.defaultTemplate != null) sb.write('..defaultTemplate =${_printNewObject(obj.defaultTemplate)}');
    sb.write('..culture = ${_printNewObject(obj.culture)}');
    if (obj.standardPattern != null) sb.write('..standardPattern =${obj.standardPatternCode}');
    sb.write('..pattern =${_printNewObject(obj.pattern)}');
    sb.write('..text =${_printNewObject(obj.text)}');
    if (obj.template != null) sb.write('..template =${_printNewObject(obj.template)}');
    sb.write('..description =${_printNewObject(obj.description)}');
    if (obj.message != null) sb.write('..message =${_printNewObject(obj.message!)}');
    if (obj.parameters.isNotEmpty) sb.write('..parameters.addAll(${_printNewObject(obj.parameters)})');
    ;
  }
  else if (obj is AnnualDate) {
    sb.write('new AnnualDate(${obj.month}, ${obj.day})');
  }
  else if (obj is List) {
    if (obj.isEmpty) {
      sb.write('[]');
    } else {
      sb.write('[');

      sb.write(_printNewObject(obj.first));
      for (var item in obj.skip(1)) {
        sb..write(', ')..write(_printNewObject(item));
      }

      sb.write(']');
    }
  }
  else if (obj is num) {
    sb.write(obj);
  }
  else if (obj is CalendarSystem) {
    // todo: pull this information directly from CalendarSystem?
    if (obj.id == 'Gregorian') {
      sb.write('CalendarSystem.gregorian');
    } else if (obj.id == 'ISO') {
      sb.write('CalendarSystem.iso');
    } else if (obj.id == 'Julian') {
      sb.write('CalendarSystem.julian');
    }
    else {
      sb.write('CalendarSystem.${obj.id}');
    }
  }
  else if (obj is Instant) {
    var span = obj.timeSinceEpoch;
    var ms = span.inMilliseconds;
    var ns = ITime.nanosecondsIntervalOf(span);
    sb.write('IInstant.trusted(ISpan.trusted($ms, $ns))');
  }
  else if (obj is Time) {
    var span = obj;
    var ms = span.inMilliseconds;
    var ns = ITime.nanosecondsIntervalOf(span);
    sb.write('ISpan.trusted($ms, $ns)');
  }
  else if (obj is DateTimeZone) {
    _getTzdb = true;
    sb.write('await tzdb["${obj.id}"]');
  }
  else if (obj is DayOfWeek) {
    sb.write('DayOfWeek.${obj.toString().toLowerCase()}');
  }
  else if (obj is HebrewMonthNumbering) {
    // sb.write('HebrewMonthNumbering.${obj.toString().toLowerCase()}');
    sb.write(obj);
  }
  else if (obj is CalendarOrdinal) {
    sb.write('new CalendarOrdinal(${obj.value})');
  }
  else if (obj is YearMonthDayCalculator) {
    sb.write('new ${obj.runtimeType}()');
  }
  else if (obj is InstantPattern) {
    // sb.write('InstantPattern.createWithCulture(${_printNewObject(obj.patternText)}, ${_printNewObject(InstantPatterns.patternOf(obj))})');
    sb.write('InstantPattern.general');
  }
  else if (obj is ZonedDateTime) {
    var instant = obj.toInstant();
    var zone = obj.zone;
    var calendar = obj.calendar;
    sb.write('new ZonedDateTime(${_printNewObject(instant)}, ${_printNewObject(zone)}, ${_printNewObject(calendar)})');
  }
  else if (obj is LocalDate) {
    var year = obj.year;
    var month = obj.monthOfYear;
    var day = obj.dayOfMonth;
    var calendar = obj.calendar;
    sb.write('new LocalDate($year, $month, $day, ${_printNewObject(calendar)})');
  }
  else if (obj is LocalTime) {
    var nanoseconds = obj.timeSinceMidnight.inNanoseconds;
    sb.write('ILocalTime.fromNanoseconds($nanoseconds)');
  }
  else if (obj is LocalDateTime) {
    sb.write('new LocalDateTime(${_printNewObject(obj.calendarDate)}, ${_printNewObject(obj.clockTime)})');
  }
  else if (obj is OffsetDate) {
    var date = obj.calendarDate;
    var offset = obj.offset;
    sb.write('new OffsetDate(${_printNewObject(date)}, ${_printNewObject(offset)})');
  }
  else if (obj is Offset) {
    var seconds = obj.inSeconds;
    sb.write('new Offset.fromSeconds($seconds)');
  }
  else if (obj is OffsetDateTime) {
    var localDateTime = obj.localDateTime;
    var offset = obj.offset;
    sb.write('new OffsetDateTime(${_printNewObject(localDateTime)}, ${_printNewObject(offset)})');
  }
  else if (obj is OffsetTime) {
    var time = obj.clockTime;
    var offset= obj.offset;
    sb.write('new OffsetTime(${_printNewObject(time)}, ${_printNewObject(offset)})');
  }
  else if (obj is bool) {
    sb.write(obj);
  }
  else if (obj is PeriodUnits) {
    sb.write('new PeriodUnits(${obj.value})');
  }
  else {
    sb.write('"Type = ${obj.runtimeType}; toString = ${obj.toString()}"');
  }

  // sb.write('/*${obj.runtimeType}*/');

  return sb.toString();
}

// we're doing this in the worst way possible
String _escapeText(String text) {
  text = text.replaceAll("\\", '\\\\');
  text = text.replaceAll('"', '\\"');
  text = text.replaceAll("'", "\\'");
  return text;
}

Iterable<Future> _runTest(ObjectMirror mirror, MethodMirror method, String testName) {
  var futures = <Future>[];

  var testCases = method
      .metadata
      .where((m) => m.reflectee is TestCase)
      .map((m) => m.reflectee as TestCase)
      .toList();

  method
      .metadata
      .where((m) => m.reflectee is TestCaseSource)
      .map((m) => toTestCases(m.reflectee as TestCaseSource, mirror))
      .fold(null, (p, e) => testCases.addAll(e));

  if (testCases.isEmpty) {
    var name = testName; // '${method.simpleName}';

    if (testGenTest) _printTestCall(mirror, method, testName);
    if (method.returnType.hasReflectedType && method.returnType.reflectedType == Future) {
      // var returnMirror = mirror.invoke(method.simpleName, []);
      // futures.add(returnMirror.reflectee);

      test(name, () async {
        var returnMirror = mirror.invoke(method.simpleName, []);
        await returnMirror.reflectee;
      });
    }
    else {
      test(name, () => mirror.invoke(method.simpleName, []));
    }
  }
  else {
    for (var testCase in testCases) {
      var name = '$testName.${testCase.description ?? testCase.arguments}'; // '${method.simpleName}_${i++}';

      if (testGenTest) _printTestCall(mirror, method, testName, testCase);
      if (method.returnType.hasReflectedType && method.returnType.reflectedType == Future) {
        //var returnMirror = mirror.invoke(method.simpleName, testCase.arguments);
        //futures.add(returnMirror.reflectee);

        test(name, () async {
          var returnMirror = mirror.invoke(method.simpleName, testCase.arguments.toList());
          await returnMirror.reflectee;
        });
      }
      else {
        final argsList = testCase.arguments.toList();
        final singleNullArg = argsList.length == 1 && argsList.first == null;
        if (!singleNullArg) {
          test(name, () => mirror.invoke(method.simpleName, argsList));
        }
      }
    }
  }

  return futures;
}

Iterable<Future> _runTestsInClass(LibraryMirror lib, ClassMirror classMirror, String testGroupName) {
  var futures = <Future>[];

  var instance = classMirror.newInstance(const Symbol(''), []);
  if (testGenTest)
  {
    _classVarName = _stripSymbol(classMirror.simpleName).toLowerCase();
    _gen_sb_methodCalls.write('  var $_classVarName = new ${_stripSymbol(classMirror.simpleName)}();\n\n');
  }
  var declarations = <DeclarationMirror>[...classMirror.declarations.values];
  while (classMirror.superclass != null) {
    classMirror = classMirror.superclass!;
    declarations.addAll(classMirror.declarations.values);
  }

  for(DeclarationMirror declaration in declarations) {
    if (declaration is MethodMirror && declaration.metadata.any((m) => m.reflectee is Test)) {
      if (declaration.metadata.isEmpty) continue;
      var test = declaration.metadata.where((m) => m.reflectee is Test).map((m) => m.reflectee as Test).toList(growable: false);
      if (test.isEmpty) continue;

      // should we collate all found test names?
      var testName = '$testGroupName.${test.first.name ?? _stripSymbol(declaration.simpleName)}'; //test.first.name ?? '${lib.simpleName}.${declaration.simpleName}';

      var skipThisTest = declaration.metadata.any((m) => m.reflectee is SkipMe);
      if (skipThisTest) {
        _skippedTotal++;
        var reason = (declaration.metadata.firstWhere((m) => m.reflectee is SkipMe).reflectee as SkipMe).reason;
        if (reason == null) print('skipped $testName');
        else print('skipped $testName because $reason');
        continue;
      }

      // easy, because no sub classes
      futures.addAll(_runTest(instance, declaration, testName));
    }
  }

  if (testGenTest) {
    _classVarName = null;
  }

  return futures;
}

String _stripSymbol(Symbol symbol) {
  var text = symbol.toString();
  return text.substring(8, text.toString().length-2);
}

String _nameOf(MethodMirror method) => _stripSymbol(method.simpleName);
