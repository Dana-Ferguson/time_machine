// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';
import 'dart:mirrors';
import 'dart:io';

import 'package:test/test.dart';
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
String _classVarName;
StringBuffer _gen_sb_imports = new StringBuffer();
StringBuffer _gen_sb_methodCalls = new StringBuffer();
String _testFilePath = 'unknown_test.dart';

Iterable<TestCase> toTestCases(TestCaseSource testCaseSource, ObjectMirror mirror) {
  var argumentsSource = mirror.getField(testCaseSource.source).reflectee as Iterable;

  if (argumentsSource.isEmpty) return const [];
  var testCases = new List<TestCase>();

  for (var arguments in argumentsSource) {
    if (arguments is TestCaseData) {
      if (arguments.arguments is List) testCases.add(new TestCase(arguments.arguments, arguments.name));
      else testCases.add(new TestCase([arguments.arguments], arguments.name));
    }
    else if (arguments is List) testCases.add(new TestCase(arguments));
    else testCases.add(new TestCase([arguments]));
  }

  return testCases;
}

int _skippedTotal = 0;

Future runTests() async {
  // this doesn't work, but I believe it should
  // var lib = currentMirrorSystem().isolate.rootLibrary.declarations;
  // this works! (but will require more boilerplate than I want)
  // var lib4 = currentMirrorSystem().findLibrary(new Symbol("testFx"));

  var testLibs = currentMirrorSystem()
      .libraries.values.where((lib) => lib.uri.scheme == 'file' && lib.uri.path.endsWith('_test.dart'))
      .toList(growable: false);

  var futures = new List<Future>();

  for (var lib in testLibs) {
    if (testGenTest) _printImport(lib.uri);
    
    for (DeclarationMirror declaration in lib.declarations.values) {
      if (declaration.metadata == null || declaration.metadata.isEmpty) continue;
      var test = declaration.metadata.where((m) => m.reflectee is Test).map((m) => m.reflectee as Test).toList(growable: false);
      if (test.isEmpty) continue;

      // todo: merge with other code
      // should we collate all found test names?
      var testName = test.first.name;
      if (testName == null) {
        var libSimpleName= _stripSymbol(lib.simpleName);
        var sb = new StringBuffer();
        if (libSimpleName?.isNotEmpty ?? false) sb..write(libSimpleName)..write('.');
        sb..write(_stripSymbol(declaration.simpleName));
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
  var sb = new StringBuffer();
  sb.writeln("import 'dart:async';");
  sb.writeln("import 'dart:math' as math;");
  sb.writeln();
  sb.writeln("import 'package:test/test.dart';");
  sb.writeln();
  sb.writeln("import 'package:time_machine/src/time_machine_internal.dart';");
  sb.writeln("import '../time_machine_testing.dart';");
  sb.writeln();
  
  sb.write(_gen_sb_imports);
  sb.writeln();
  
  sb.writeln('Future main() async {');
  sb.writeln('  await TimeMachine.initialize();');
  sb.writeln();
  sb.write(_gen_sb_methodCalls);
  sb.writeln('}');
  
  
  var file = new File(_testFilePath);
  file.writeAsString(sb.toString(), mode: FileMode.WRITE_ONLY);
  
  print("written '$_testFilePath' to drive.");
}

void _printImport(Uri uri) {
  var sb = _gen_sb_imports..write("import '../"); // test/");
  var path = uri.pathSegments;
  
  for (var p in path.skipWhile((p) => p != 'test').skip(1)) {
    sb..write('/')..write(p);
  }
  sb..write("';")..writeln();
  
  _testFilePath = '/' + path.takeWhile((p) => p != 'test').join('/') + '/test/test_gen/' + path.last;
}

void _printTestCall(ObjectMirror mirror, MethodMirror method, String testName, [TestCase testCase]) {
  var sb = _gen_sb_methodCalls..write("  test('$testName', () ");
  
  var isFuture = method.returnType.hasReflectedType && method.returnType.reflectedType == Future;
  if (isFuture) sb.write('async => await '); else sb.write('=> ');

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
      
      if (arg is String) {
        sb..write("'")..write(arg)..write("'");
      }
      sb.write(arg);
    }
  }
  // ${testCase.arguments.join(', ')});
  sb.write ('));');
  
  sb.writeln();
}

Iterable<Future> _runTest(ObjectMirror mirror, MethodMirror method, String testName) {
  var futures = new List<Future>();

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
          var returnMirror = mirror.invoke(method.simpleName, testCase.arguments);
          await returnMirror.reflectee;
        });
      }
      else {
        test(name, () => mirror.invoke(method.simpleName, testCase.arguments));
      }
    }
  }

  return futures;
}

Iterable<Future> _runTestsInClass(LibraryMirror lib, ClassMirror classMirror, String testGroupName) {
  var futures = new List<Future>();

  var instance = classMirror.newInstance(new Symbol(''), []);
  if (testGenTest) 
  {
    _classVarName = _stripSymbol(classMirror.simpleName).toLowerCase();
    print('var ${_classVarName} = new ${_stripSymbol(classMirror.simpleName)}();');
  }
  var declarations = new List<DeclarationMirror>()..addAll(classMirror.declarations.values);
  while (classMirror.superclass != null) {
    classMirror = classMirror.superclass;
    declarations.addAll(classMirror.declarations.values);
  }

  for(DeclarationMirror declaration in declarations) {
    if (declaration is MethodMirror && declaration.metadata.any((m) => m.reflectee is Test)) {
      if (declaration.metadata == null || declaration.metadata.isEmpty) continue;
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