// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:math' as math;

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import '../time_machine_testing.dart';

Future main() async {
  await runTests();
}

class DayOfWeek {
  static const int Sunday = 0;
  static const int Monday = 1;
  static const int Tuesday = 2;
  static const int Wednesday = 3;
  static const int Thursday = 4;
  static const int Friday = 5;
  static const int Saturday = 6;
}

@Test()
void Construct_InvalidMonth_Exception()
{
  expect(() => new ZoneYearOffset(TransitionMode.standard, 0, 1, 1, true, LocalTime.midnight), throwsArgumentError, reason: "Month 0");
  expect(() => new ZoneYearOffset(TransitionMode.standard, 34, 1, 1, true, LocalTime.midnight), throwsArgumentError, reason: "Month 34");
  expect(() => new ZoneYearOffset(TransitionMode.standard, -3, 1, 1, true, LocalTime.midnight), throwsArgumentError, reason: "Month -3");
}

@Test()
void Construct_InvalidDayOfMonth_Exception()
{
  expect(() => new ZoneYearOffset(TransitionMode.standard, 2, 0, 1, true, LocalTime.midnight), throwsArgumentError, reason: "Day of Month 0");
  expect(() => new ZoneYearOffset(TransitionMode.standard, 2, 32, 1, true, LocalTime.midnight), throwsArgumentError, reason: "Day of Month 32");
  expect(() => new ZoneYearOffset(TransitionMode.standard, 2, 475, 1, true, LocalTime.midnight), throwsArgumentError,
      reason: "Day of Month 475");
  expect(() => new ZoneYearOffset(TransitionMode.standard, 2, -32, 1, true, LocalTime.midnight), throwsArgumentError,
      reason: "Day of Month -32");
}

@Test()
void Construct_InvalidDayOfWeek_Exception()
{
  expect(() => new ZoneYearOffset(TransitionMode.standard, 2, 3, -1, true, LocalTime.midnight), throwsArgumentError, reason: "Day of Week -1");
  expect(() => new ZoneYearOffset(TransitionMode.standard, 2, 3, 8, true, LocalTime.midnight), throwsArgumentError, reason: "Day of Week 8");
  expect(() => new ZoneYearOffset(TransitionMode.standard, 2, 3, 5756, true, LocalTime.midnight), throwsArgumentError,
      reason: "Day of Week 5856");
  expect(() => new ZoneYearOffset(TransitionMode.standard, 2, 3, -347, true, LocalTime.midnight), throwsArgumentError,
      reason: "Day of Week -347");
}

@Test()
void Construct_ValidMonths()
{
  for (int month = 1; month <= 12; month++)
  {
    expect(new ZoneYearOffset(TransitionMode.standard, month, 1, 1, true, LocalTime.midnight), isNotNull, reason: "Month $month");
  }
}

@Test()
void Construct_ValidDays()
{
  for (int day = 1; day <= 31; day++)
  {
    expect(new ZoneYearOffset(TransitionMode.standard, 1, day, 1, true, LocalTime.midnight), isNotNull, reason: "Day $day");
  }
  for (int day = -1; day >= -31; day--)
  {
    expect(new ZoneYearOffset(TransitionMode.standard, 1, day, 1, true, LocalTime.midnight), isNotNull, reason: "Day $day");
  }
}

@Test()
void Construct_ValidDaysOfWeek()
{
  for (int dayOfWeek = 0; dayOfWeek <= 7; dayOfWeek++)
  {
    expect(new ZoneYearOffset(TransitionMode.standard, 1, 1, dayOfWeek, true, LocalTime.midnight), isNotNull, reason: "Day of week $dayOfWeek");
  }
}

@Test()
void GetOccurrenceForYear_Defaults_Epoch()
{
  var offset = new ZoneYearOffset(TransitionMode.utc, 1, 1, 0, true, LocalTime.midnight);
  var actual = offset.GetOccurrenceForYear(1970);
  var expected = new LocalDateTime.at(1970, 1, 1, 0, 0).toLocalInstant();
  expect(expected, actual);
}

@Test()
void GetOccurrenceForYear_Year_1971()
{
  var offset = new ZoneYearOffset(TransitionMode.utc, 1, 1, 0, true, LocalTime.midnight);
  var actual = offset.GetOccurrenceForYear(1971);
  var expected = new LocalDateTime.at(1971, 1, 1, 0, 0).toLocalInstant();
  expect(expected, actual);
}

@Test()
void GetOccurrenceForYear_Milliseconds()
{
  var offset = new ZoneYearOffset(TransitionMode.utc, 1, 1, 0, true, new LocalTime(0, 0, 0, 1));
  var actual = offset.GetOccurrenceForYear(1970);
  var expected = new LocalDateTime.at(1970, 1, 1, 0, 0, seconds: 0, milliseconds: 1).toLocalInstant();
  expect(expected, actual);
}

@Test()
void GetOccurrenceForYear_WednesdayForward()
{
  var offset = new ZoneYearOffset(TransitionMode.utc, 1, 1, DayOfWeek.Wednesday, true, LocalTime.midnight);
  var actual = offset.GetOccurrenceForYear(1970);
  var expected = new LocalDateTime.at(1970, 1, 7, 0, 0).toLocalInstant(); // 1970-01-01 was a Thursday
  expect(expected, actual);
}

@Test()
void GetOccurrenceForYear_WednesdayBackward()
{
  var offset = new ZoneYearOffset(TransitionMode.utc, 1, 15, DayOfWeek.Wednesday, false, LocalTime.midnight);
  var actual = offset.GetOccurrenceForYear(1970);
  var expected = new LocalDateTime.at(1970, 1, 14, 0, 0).toLocalInstant(); // 1970-01-15 was a Thursday
  expect(expected, actual);
}

@Test()
void GetOccurrenceForYear_JanMinusTwo()
{
  var offset = new ZoneYearOffset(TransitionMode.utc, 1, -2, 0, true, LocalTime.midnight);
  var actual = offset.GetOccurrenceForYear(1970);
  var expected = new LocalDateTime.at(1970, 1, 30, 0, 0).toLocalInstant();
  expect(expected, actual);
}

@Test()
void GetOccurrenceForYear_JanFive()
{
  var offset = new ZoneYearOffset(TransitionMode.utc, 1, 5, 0, true, LocalTime.midnight);
  var actual = offset.GetOccurrenceForYear(1970);
  var expected = new LocalDateTime.at(1970, 1, 5, 0, 0).toLocalInstant();
  expect(expected, actual);
}

@Test()
void GetOccurrenceForYear_Feb()
{
  var offset = new ZoneYearOffset(TransitionMode.utc, 2, 1, 0, true, LocalTime.midnight);
  var actual = offset.GetOccurrenceForYear(1970);
  var expected = new LocalDateTime.at(1970, 2, 1, 0, 0).toLocalInstant();
  expect(expected, actual);
}

@Test()
void GetOccurrenceForYear_LastSundayInOctober()
{
  ZoneYearOffset offset = new ZoneYearOffset(TransitionMode.utc, 10, -1, IsoDayOfWeek.sunday.value,  false, LocalTime.midnight);
  var actual = offset.GetOccurrenceForYear(1996);
  var expected = new LocalDateTime.at(1996, 10, 27, 0, 0).toLocalInstant();
  expect(expected, actual);
}

@Test()
void GetOccurrenceForYear_ExactlyFeb29th_LeapYear()
{
  ZoneYearOffset offset = new ZoneYearOffset(TransitionMode.utc, 2, 29, 0, false, LocalTime.midnight);
  var actual = offset.GetOccurrenceForYear(2012);
  var expected = new LocalDateTime.at(2012, 2, 29, 0, 0).toLocalInstant();
  expect(expected, actual);
}

@Test()
void GetOccurrenceForYear_ExactlyFeb29th_NotLeapYear()
{
  ZoneYearOffset offset = new ZoneYearOffset(TransitionMode.utc, 2, 29, 0, false, LocalTime.midnight);
  var actual = offset.GetOccurrenceForYear(2013);
  var expected = new LocalDateTime.at(2013, 2, 28, 0, 0).toLocalInstant(); // For "exact", go to Feb 28th
  expect(expected, actual);
}

@Test()
void GetOccurrenceForYear_AtLeastFeb29th_LeapYear()
{
  ZoneYearOffset offset = new ZoneYearOffset(TransitionMode.utc, 2, 29, IsoDayOfWeek.sunday.value,  true, LocalTime.midnight);
  var actual = offset.GetOccurrenceForYear(2012);
  var expected = new LocalDateTime.at(2012, 3, 4, 0, 0).toLocalInstant(); // March 4th is the first Sunday after 2012-02-29
  expect(expected, actual);
}

@Test()
void GetOccurrenceForYear_AtLeastFeb29th_NotLeapYear()
{
  ZoneYearOffset offset = new ZoneYearOffset(TransitionMode.utc, 2, 29, IsoDayOfWeek.sunday.value,  true, LocalTime.midnight);
  var actual = offset.GetOccurrenceForYear(2013);
  var expected = new LocalDateTime.at(2013, 3, 3, 0, 0).toLocalInstant(); // March 3rd is the first Sunday after the non-existent 2013-02-29
  expect(expected, actual);
}

@Test()
void GetOccurrenceForYear_AtMostFeb29th_LeapYear()
{
  ZoneYearOffset offset = new ZoneYearOffset(TransitionMode.utc, 2, 29, IsoDayOfWeek.sunday.value,  false, LocalTime.midnight);
  var actual = offset.GetOccurrenceForYear(2012);
  var expected = new LocalDateTime.at(2012, 2, 26, 0, 0).toLocalInstant(); // Feb 26th is the last Sunday before 2012-02-29
  expect(expected, actual);
}

@Test()
void GetOccurrenceForYear_AtMostFeb29th_NotLeapYear()
{
  ZoneYearOffset offset = new ZoneYearOffset(TransitionMode.utc, 2, 29, IsoDayOfWeek.sunday.value,  false, LocalTime.midnight);
  var actual = offset.GetOccurrenceForYear(2013);
  var expected = new LocalDateTime.at(2013, 2, 24, 0, 0).toLocalInstant(); // Feb 24th is the last Sunday is February 2013
  expect(expected, actual);
}

@Test()
void GetOccurrenceForYear_WithAddDay()
{
  // Last Thursday in October, then add 24 hours. The last Thursday in October 2013 is the 31st, so
  // we should get the start of November 1st.
  var offset = new ZoneYearOffset(TransitionMode.utc, 10, -1, IsoDayOfWeek.thursday.value, false, LocalTime.midnight, true);
  var actual = offset.GetOccurrenceForYear(2013);
  var expected = new LocalDateTime.at(2013, 11, 1, 0, 0).toLocalInstant();
  expect(expected, actual);
}

@Test()
void GetOccurrenceForYear_WithAddDay_December31st9999()
{
  var offset = new ZoneYearOffset(TransitionMode.utc, 12, 31, 0, false, LocalTime.midnight, true);
  var actual = offset.GetOccurrenceForYear(9999);
  var expected = LocalInstant.AfterMaxValue;
  expect(expected, actual);
}

/* todo: seralization equivalent
@Test()
void Serialization()
{
  var dio = DtzIoHelper.CreateNoStringPool();
  var expected = new ZoneYearOffset(TransitionMode.utc, 10, 31, IsoDayOfWeek.wednesday.value, true,
      new LocalTime(12, 34, 45, 678));
  dio.TestZoneYearOffset(expected);

  dio.Reset();
  expected = new ZoneYearOffset(TransitionMode.utc, 10, -31, IsoDayOfWeek.wednesday.value, true, LocalTime.Midnight);
  dio.TestZoneYearOffset(expected);
}*/

@Test()
void IEquatable_Tests()
{
  var value = new ZoneYearOffset(TransitionMode.utc, 10, 31, IsoDayOfWeek.wednesday.value, true, LocalTime.midnight);
  var equalValue = new ZoneYearOffset(TransitionMode.utc, 10, 31, IsoDayOfWeek.wednesday.value, true, LocalTime.midnight);
  var unequalValue = new ZoneYearOffset(TransitionMode.utc, 9, 31, IsoDayOfWeek.wednesday.value, true, LocalTime.midnight);

  TestHelper.TestEqualsClass(value, equalValue, [unequalValue]);
}

