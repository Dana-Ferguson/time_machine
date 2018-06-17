// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';

import 'test_fx.dart';

// note: this doesn't actually run any tests... todo: maybe do real automated tests
Future main() async {
// await runTests();
}

@Test()
@TestCase(const [1, 2, 3])
@TestCase(const [2, 3, 4])
void thisIsATest(int x, int y, int z) {
  print('hello, testing! $x + $y - $z = ${x+y-z}');
}

@Test()
Future thisIsAsyncTest() async {
  await new Future.delayed(new Duration(seconds: 1));
  print('Hi... FROM THE FUTURE!');
  throw new Exception('yeti in the future');
}

@Test('This is also a test!')
void thisIsAlsoTest() {
  print('hello, SINGLE UNIT TEST');
}

@Test("MyTestClass")
class TestClass {
  int y = 3;

  @Test()
  void mySpecialTest() {
    print('Very special test! y = $y;');
  }

  @Test('yeti must be findable')
  @TestCase(const [4], 'best test')
  @TestCase(const [9], 'worst test')
  void mySpecialTestWithArguments(int x) {
    print('Special x == $x?');
    throw new Exception('yeti');
  }

  @Test()
  Future mySpecialAsyncTest() async {
    await new Future.delayed(new Duration(seconds: 1, milliseconds: 500));
    print('Hi... FROM THE FUTURE2! y*2 = ${y*2}');
  }
}
