// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import 'time_machine_testing.dart';

Future main() async {
  await TimeMachine.initialize();
  await runTests();
}

@Test()
void Feb29()
{
  var date = AnnualDate(2, 29);
  expect(29, date.day);
  expect(2, date.month);
  expect(LocalDate(2016, 2, 29), date.inYear(2016));
  expect(date.isValidYear(2016), isTrue);
  expect(LocalDate(2015, 2, 28), date.inYear(2015));
  expect(date.isValidYear(2015), isFalse);
}

@Test()
void June19()
{
  var date = AnnualDate(6, 19);
  expect(19, date.day);
  expect(6, date.month);
  expect(LocalDate(2016, 6, 19), date.inYear(2016));
  expect(date.isValidYear(2016), isTrue);
  expect(LocalDate(2015, 6, 19), date.inYear(2015));
  expect(date.isValidYear(2015), isTrue);
}

@Test()
void Validation()
{
  // Feb 30th is invalid, but January 30th is fine
  expect(() => AnnualDate(2, 30), throwsRangeError);
  // Assert.Throws<ArgumentOutOfRangeException>(() => new AnnualDate(2, 30));
  AnnualDate(1, 30);

  // 13th month is invalid
  expect(() => AnnualDate(13, 1), throwsRangeError);
// Assert.Throws<ArgumentOutOfRangeException>(() => new AnnualDate(13, 1));
}

@Test()
void Equality()
{
  TestHelper.TestEqualsStruct(AnnualDate(3, 15), AnnualDate(3, 15), [AnnualDate(4, 15), AnnualDate(3, 16)]);
}

@Test()
void DefaultValueIsJanuary1st()
{
  // todo: I don't see a default constructor in the original C# code?
  expect(AnnualDate(1, 1), AnnualDate());
}

@Test()
void Comparision()
{
  TestHelper.TestCompareToStruct(AnnualDate(6, 19), AnnualDate(6, 19), [AnnualDate(6, 20), AnnualDate(7, 1)]);
}

@Test()
void Operators()
{
  TestHelper.TestOperatorComparisonEquality(AnnualDate(6, 19), AnnualDate(6, 19), [AnnualDate(6, 20), AnnualDate(7, 1)]);
}

@Test()
void ToStringTest()
{
  expect('02-01', AnnualDate(2, 1).toString());
  expect('02-10', AnnualDate(2, 10).toString());
  expect('12-01', AnnualDate(12, 1).toString());
  expect('12-20', AnnualDate(12, 20).toString());
}
