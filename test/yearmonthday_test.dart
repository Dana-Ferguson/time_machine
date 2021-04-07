// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:test/test.dart';

import 'time_machine_testing.dart';

Future main() async {
  await TimeMachine.initialize();
  await runTests();
}

@Test()
void AllYears()
{
  // Range of years we actually care about. We support more, but that's okay.
  for (int year = -9999; year <= 9999; year++)
  {
    var ymd = YearMonthDay(year, 5, 20);
    expect(year, ymd.year);
    expect(5, ymd.month);
    expect(20, ymd.day);
  }
}

@Test()
void AllMonths()
{
  // We'll never actually need 32 months, but we support that many...
  for (int month = 1; month < 32; month++)
  {
    var ymd = YearMonthDay(-123, month, 20);
    expect(-123, ymd.year);
    expect(month, ymd.month);
    expect(20, ymd.day);
  }
}

@Test()
void AllDays()
{
  // We'll never actually need 64 days, but we support that many...
  for (int day = 1; day < 64; day++)
  {
    var ymd = YearMonthDay(-123, 30, day);
    expect(-123, ymd.year);
    expect(30, ymd.month);
    expect(day, ymd.day);
  }
}

@Test()
@TestCase(['1000-01-01', "1000-01-02"])
@TestCase(['1000-01-01', "1000-02-01"])
@TestCase(['999-16-64', "1000-01-01"])
@TestCase(['-1-01-01', "-1-01-02"])
@TestCase(['-1-01-01', "-1-02-01"])
@TestCase(['-2-16-64', "-1-01-01"])
@TestCase(['-1-16-64', "0-01-01"])
@TestCase(['-1-16-64', "1-01-01"])
void Comparisons(String smallerText, String greaterText)
{
  var smaller = YearMonthDay.parse(smallerText);
  var smaller2 = YearMonthDay.parse(smallerText);
  var greater = YearMonthDay.parse(greaterText);
  TestHelper.TestCompareToStruct(smaller, smaller2, [greater]);
  TestHelper.TestOperatorComparisonEquality(smaller2, smaller, [greater]);
  TestHelper.TestEqualsStruct(smaller, smaller2, [greater]);
}

@Test()
void YearMonthDayToString()
{
  var ymd = const YearMonthDay(2017, 8, 25);
  expect('2017-08-25', ymd.toString());
}

