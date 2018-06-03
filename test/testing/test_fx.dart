import 'dart:async';
import 'dart:mirrors';
import 'dart:io';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

// todo: should this be a separate test_package?
// todo: it seems the test runner is synchronous, I guess that's okay
//  --> before I integrated test.dart, we were asynchronous
//      (async tests ran in parallel, but I can see that doing weird things to the tests)
// todo: can we had the stack_trace portions from here?

// Note: this won't work for Dart4Web applications
// I was going to use Reflectable, but it's 2.0 version adds too much boiler (in a viral fashion --> fixable via build.yaml???)
// Transformers are dead in 2.0, long live build.yaml???

class SkipMe {
  final String reason;

  const SkipMe([this.reason]);
  const SkipMe.unimplemented() : reason = 'unimplemented';
  const SkipMe.parseIds() : reason = 'cannot parse dtz ids';
  const SkipMe.text() : reason = 'text';
}

class Test {
  final String name;
  const Test([this.name]);
}

class TestCase {
  final Iterable arguments;
  final String description;

  const TestCase(this.arguments, [this.description]);
}

class TestCaseSource {
  // List of Lists (n-arguments), or just a List (single argument)
  final Symbol source;
  final String description;

  const TestCaseSource(this.source, [this.description]);

  Iterable<TestCase> toTestCases(ObjectMirror mirror) {
    var argumentsSource = mirror.getField(source).reflectee as Iterable;

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
}

class TestCaseData {
  String name;
  Object arguments;
  TestCaseData(this.arguments);
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

  await Future.wait(futures);
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
      .map((m) => (m.reflectee as TestCaseSource).toTestCases(mirror))
      .fold(null, (p, e) => testCases.addAll(e));

  if (testCases.isEmpty) {
    var name = testName; // '${method.simpleName}';

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

  return futures;
}

String _stripSymbol(Symbol symbol) {
  var text = symbol.toString();
  return text.substring(8, text.toString().length-2);
}