// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

@Test()
void PlusYear_Simple()
{
  LocalDateTime start = new LocalDateTime.at(2011, 6, 26, 12, 15, seconds: 8);
  LocalDateTime expected = new LocalDateTime.at(2016, 6, 26, 12, 15, seconds: 8);
  expect(expected, start.plusYears(5));

  expected = new LocalDateTime.at(2006, 6, 26, 12, 15, seconds: 8);
  expect(expected, start.plusYears(-5));
}

@Test()
void PlusYear_LeapToNonLeap()
{
  LocalDateTime start = new LocalDateTime.at(2012, 2, 29, 12, 15, seconds: 8);
  LocalDateTime expected = new LocalDateTime.at(2013, 2, 28, 12, 15, seconds: 8);
  expect(expected, start.plusYears(1));

  expected = new LocalDateTime.at(2011, 2, 28, 12, 15, seconds: 8);
  expect(expected, start.plusYears(-1));
}

@Test()
void PlusYear_LeapToLeap()
{
  LocalDateTime start = new LocalDateTime.at(2012, 2, 29, 12, 15, seconds: 8);
  LocalDateTime expected = new LocalDateTime.at(2016, 2, 29, 12, 15, seconds: 8);
  expect(expected, start.plusYears(4));
}

@Test()
void PlusMonth_Simple()
{
  LocalDateTime start = new LocalDateTime.at(2012, 4, 15, 12, 15, seconds: 8);
  LocalDateTime expected = new LocalDateTime.at(2012, 8, 15, 12, 15, seconds: 8);
  expect(expected, start.plusMonths(4));
}

@Test()
void PlusMonth_ChangingYear()
{
  LocalDateTime start = new LocalDateTime.at(2012, 10, 15, 12, 15, seconds: 8);
  LocalDateTime expected = new LocalDateTime.at(2013, 2, 15, 12, 15, seconds: 8);
  expect(expected, start.plusMonths(4));
}

@Test()
void PlusMonth_WithTruncation()
{
  LocalDateTime start = new LocalDateTime.at(2011, 1, 30, 12, 15, seconds: 8);
  LocalDateTime expected = new LocalDateTime.at(2011, 2, 28, 12, 15, seconds: 8);
  expect(expected, start.plusMonths(1));
}

@Test()
void PlusDays_Simple()
{
  LocalDateTime start = new LocalDateTime.at(2011, 1, 15, 12, 15, seconds: 8);
  LocalDateTime expected = new LocalDateTime.at(2011, 1, 23, 12, 15, seconds: 8);
  expect(expected, start.plusDays(8));

  expected = new LocalDateTime.at(2011, 1, 7, 12, 15, seconds: 8);
  expect(expected, start.plusDays(-8));
}

@Test()
void PlusDays_MonthBoundary()
{
  LocalDateTime start = new LocalDateTime.at(2011, 1, 26, 12, 15, seconds: 8);
  LocalDateTime expected = new LocalDateTime.at(2011, 2, 3, 12, 15, seconds: 8);
  expect(expected, start.plusDays(8));

  // Round-trip back across the boundary
  expect(start, start.plusDays(8).plusDays(-8));
}

@Test()
void PlusDays_YearBoundary()
{
  LocalDateTime start = new LocalDateTime.at(2011, 12, 26, 12, 15, seconds: 8);
  LocalDateTime expected = new LocalDateTime.at(2012, 1, 3, 12, 15, seconds: 8);
  expect(expected, start.plusDays(8));

  // Round-trip back across the boundary
  expect(start, start.plusDays(8).plusDays(-8));
}

@Test()
void PlusDays_EndOfFebruary_InLeapYear()
{
  LocalDateTime start = new LocalDateTime.at(2012, 2, 26, 12, 15, seconds: 8);
  LocalDateTime expected = new LocalDateTime.at(2012, 3, 5, 12, 15, seconds: 8);
  expect(expected, start.plusDays(8));
  // Round-trip back across the boundary
  expect(start, start.plusDays(8).plusDays(-8));
}

@Test()
void PlusDays_EndOfFebruary_NotInLeapYear()
{
  LocalDateTime start = new LocalDateTime.at(2011, 2, 26, 12, 15, seconds: 8);
  LocalDateTime expected = new LocalDateTime.at(2011, 3, 6, 12, 15, seconds: 8);
  expect(expected, start.plusDays(8));

  // Round-trip back across the boundary
  expect(start, start.plusDays(8).plusDays(-8));
}

@Test()
void PlusWeeks_Simple()
{
  LocalDateTime start = new LocalDateTime.at(2011, 4, 2, 12, 15, seconds: 8);
  LocalDateTime expectedForward = new LocalDateTime.at(2011, 4, 23, 12, 15, seconds: 8);
  LocalDateTime expectedBackward = new LocalDateTime.at(2011, 3, 12, 12, 15, seconds: 8);
  expect(expectedForward, start.plusWeeks(3));
  expect(expectedBackward, start.plusWeeks(-3));
}

@Test()
void PlusHours_Simple()
{
  LocalDateTime start = new LocalDateTime.at(2011, 4, 2, 12, 15, seconds: 8);
  LocalDateTime expectedForward = new LocalDateTime.at(2011, 4, 2, 14, 15, seconds: 8);
  LocalDateTime expectedBackward = new LocalDateTime.at(2011, 4, 2, 10, 15, seconds: 8);
  expect(expectedForward, start.plusHours(2));
  expect(expectedBackward, start.plusHours(-2));
}

@Test()
void PlusHours_CrossingDayBoundary()
{
  LocalDateTime start = new LocalDateTime.at(2011, 4, 2, 12, 15, seconds: 8);
  LocalDateTime expected = new LocalDateTime.at(2011, 4, 3, 8, 15, seconds: 8);
  expect(expected, start.plusHours(20));
  expect(start, start.plusHours(20).plusHours(-20));
}

@Test()
void PlusHours_CrossingYearBoundary()
{
  // Christmas day + 10 days and 1 hour
  LocalDateTime start = new LocalDateTime.at(2011, 12, 25, 12, 15, seconds: 8);
  LocalDateTime expected = new LocalDateTime.at(2012, 1, 4, 13, 15, seconds: 8);
  expect(start.plusHours(241), expected);
  expect(start.plusHours(241).plusHours(-241), start);
}

// Having tested that hours cross boundaries correctly, the other time unit
// tests are straightforward
@Test()
void PlusMinutes_Simple()
{
  LocalDateTime start = new LocalDateTime.at(2011, 4, 2, 12, 15, seconds: 8);
  LocalDateTime expectedForward = new LocalDateTime.at(2011, 4, 2, 12, 17, seconds: 8);
  LocalDateTime expectedBackward = new LocalDateTime.at(2011, 4, 2, 12, 13, seconds: 8);
  expect(expectedForward, start.plusMinutes(2));
  expect(expectedBackward, start.plusMinutes(-2));
}

@Test()
void PlusSeconds_Simple()
{
  LocalDateTime start = new LocalDateTime.at(2011, 4, 2, 12, 15, seconds: 8);
  LocalDateTime expectedForward = new LocalDateTime.at(2011, 4, 2, 12, 15, seconds: 18);
  LocalDateTime expectedBackward = new LocalDateTime.at(2011, 4, 2, 12, 14, seconds: 58);
  expect(expectedForward, start.plusSeconds(10));
  expect(expectedBackward, start.plusSeconds(-10));
}

@Test()
void PlusMilliseconds_Simple()
{
  LocalDateTime start = new LocalDateTime.at(2011, 4, 2, 12, 15, seconds: 8, milliseconds: 300);
  LocalDateTime expectedForward = new LocalDateTime.at(2011, 4, 2, 12, 15, seconds: 8, milliseconds: 700);
  LocalDateTime expectedBackward = new LocalDateTime.at(2011, 4, 2, 12, 15, seconds: 7, milliseconds: 900);
  expect(expectedForward, start.plusMilliseconds(400));
  expect(expectedBackward, start.plusMilliseconds(-400));
}

@Test()
void PlusTicks_Simple()
{
  LocalDate date = new LocalDate(2011, 4, 2);
  LocalTime startTime = new LocalTime.fromHourMinuteSecondMillisecondTick(12, 15, 8, 300, 7500);
  LocalTime expectedForwardTime = new LocalTime.fromHourMinuteSecondMillisecondTick(12, 15, 8, 301, 1500);
  LocalTime expectedBackwardTime = new LocalTime.fromHourMinuteSecondMillisecondTick(12, 15, 8, 300, 3500);
  expect(date.at(expectedForwardTime), (date.at(startTime)).plusTicks(4000));
  expect(date.at(expectedBackwardTime), (date.at(startTime)).plusTicks(-4000));
}

@Test()
void PlusTicks_Long()
{
  expect(TimeConstants.ticksPerDay > Utility.int32MaxValue, isTrue);
  LocalDateTime start = new LocalDateTime.at(2011, 4, 2, 12, 15, seconds: 8);
  LocalDateTime expectedForward = new LocalDateTime.at(2011, 4, 3, 12, 15, seconds: 8);
  LocalDateTime expectedBackward = new LocalDateTime.at(2011, 4, 1, 12, 15, seconds: 8);
  expect(expectedForward, start.plusTicks(TimeConstants.ticksPerDay));
  expect(expectedBackward, start.plusTicks(-TimeConstants.ticksPerDay));
}

@Test()
void PlusNanoseconds_Simple()
{
  // Just use the ticks values
  LocalDate date = new LocalDate(2011, 4, 2);
  LocalTime startTime = new LocalTime.fromHourMinuteSecondMillisecondTick(12, 15, 8, 300, 7500);
  LocalTime expectedForwardTime = new LocalTime.fromHourMinuteSecondMillisecondTick(12, 15, 8, 300, 7540);
  LocalTime expectedBackwardTime = new LocalTime.fromHourMinuteSecondMillisecondTick(12, 15, 8, 300, 7460);
  expect(date.at(expectedForwardTime), (date.at(startTime)).plusNanoseconds(4000));
  expect(date.at(expectedBackwardTime), (date.at(startTime)).plusNanoseconds(-4000));
}

@Test()
void PlusTicks_CrossingDay()
{
  LocalDateTime start = new LocalDateTime.at(2011, 4, 2, 12, 15, seconds: 8);
  LocalDateTime expectedForward = new LocalDateTime.at(2011, 4, 3, 12, 15, seconds: 8);
  LocalDateTime expectedBackward = new LocalDateTime.at(2011, 4, 1, 12, 15, seconds: 8);
  expect(expectedForward, start.plusNanoseconds(TimeConstants.nanosecondsPerDay));
  expect(expectedBackward, start.plusNanoseconds(-TimeConstants.nanosecondsPerDay));
}

@Test()
void Plus_FullPeriod() {
  LocalDateTime start = new LocalDateTime.at(2011, 4, 2, 12, 15, seconds: 8);
  var builder = new PeriodBuilder()
    ..Years = 1
    ..Months = 2
    ..Weeks = 3
    ..Days = 4
    ..Hours = 5
    ..Minutes = 6
    ..Seconds = 7
    ..Milliseconds = 8
    ..Ticks = 9
    ..Nanoseconds = 11;

  var period = builder.Build();
  var actual = start.plus(period);
  var expected = new LocalDateTime.at(2012, 6, 27, 17, 21, seconds: 15).plusNanoseconds(8000911);

  expect(expected, actual, reason: "{expected:yyyy-MM-dd HH:mm:ss.fffffffff} != {actual:yyyy-MM-dd HH:mm:ss.fffffffff}");
}

// Each test case gives a day-of-month in November 2011 and a target "next day of week";
// the result is the next day-of-month in November 2011 with that target day.
// The tests are picked somewhat arbitrarily...
@TestCase(const [10, IsoDayOfWeek.wednesday, 16])
@TestCase(const [10, IsoDayOfWeek.friday, 11])
@TestCase(const [10, IsoDayOfWeek.thursday, 17])
@TestCase(const [11, IsoDayOfWeek.wednesday, 16])
@TestCase(const [11, IsoDayOfWeek.thursday, 17])
@TestCase(const [11, IsoDayOfWeek.friday, 18])
@TestCase(const [11, IsoDayOfWeek.saturday, 12])
@TestCase(const [11, IsoDayOfWeek.sunday, 13])
@TestCase(const [12, IsoDayOfWeek.friday, 18])
@TestCase(const [13, IsoDayOfWeek.friday, 18])
void Next(int dayOfMonth, IsoDayOfWeek targetDayOfWeek, int expectedResult)
{
  LocalDateTime start = new LocalDateTime.at(2011, 11, dayOfMonth, 15, 25, seconds: 30).plusNanoseconds(123456789);
  LocalDateTime target = start.next(targetDayOfWeek);
  expect(2011, target.year);
  expect(11, target.month);
  expect(start.time, target.time);
  expect(target.day, expectedResult);
}

@TestCase(const [0])
@TestCase(const [-1])
@TestCase(const [8])
void Next_InvalidArgument(IsoDayOfWeek targetDayOfWeek)
{
  LocalDateTime start = new LocalDateTime.at(2011, 1, 1, 15, 25, seconds: 30).plusNanoseconds(123456789);
  expect(() => start.next(targetDayOfWeek), throwsRangeError);
}

// Each test case gives a day-of-month in November 2011 and a target "next day of week";
// the result is the next day-of-month in November 2011 with that target day.
@TestCase(const [10, IsoDayOfWeek.wednesday, 9])
@TestCase(const [10, IsoDayOfWeek.friday, 4])
@TestCase(const [10, IsoDayOfWeek.thursday, 3])
@TestCase(const [11, IsoDayOfWeek.wednesday, 9])
@TestCase(const [11, IsoDayOfWeek.thursday, 10])
@TestCase(const [11, IsoDayOfWeek.friday, 4])
@TestCase(const [11, IsoDayOfWeek.saturday, 5])
@TestCase(const [11, IsoDayOfWeek.sunday, 6])
@TestCase(const [12, IsoDayOfWeek.friday, 11])
@TestCase(const [13, IsoDayOfWeek.friday, 11])
void Previous(int dayOfMonth, IsoDayOfWeek targetDayOfWeek, int expectedResult)
{
  LocalDateTime start = new LocalDateTime.at(2011, 11, dayOfMonth, 15, 25, seconds: 30).plusNanoseconds(123456789);
  LocalDateTime target = start.previous(targetDayOfWeek);
  expect(2011, target.year);
  expect(11, target.month);
  expect(target.day, expectedResult);
}

@TestCase(const [0])
@TestCase(const [-1])
@TestCase(const [8])
void Previous_InvalidArgument(IsoDayOfWeek targetDayOfWeek)
{
  LocalDateTime start = new LocalDateTime.at(2011, 1, 1, 15, 25, seconds: 30).plusNanoseconds(123456789);
  expect(() => start.previous(targetDayOfWeek), throwsRangeError);
}

// No tests for non-ISO-day-of-week calendars as we don't have any yet.

@Test()
void Operator_MethodEquivalents()
{
  LocalDateTime start = new LocalDateTime.at(2011, 1, 1, 15, 25, seconds: 30).plusNanoseconds(123456789);
  Period period = new Period.fromHours(1) + new Period.fromDays(1);
  LocalDateTime end = start + period;
  expect(start + period, LocalDateTime.add(start, period));
  expect(start + period, start.plus(period));
  expect(start - period, LocalDateTime.subtractPeriod(start, period));
  expect(start - period, start.minusPeriod(period));
  expect(period, end - start);
  expect(period, LocalDateTime.subtractLocalDateTime(end, start));
  expect(period, end.MinusLocalDateTime(start));
}

@Test()
void With_TimeAdjuster()
{
  LocalDateTime start = new LocalDateTime.at(2014, 6, 27, 12, 15, seconds: 8).plusNanoseconds(123456789);
  LocalDateTime expected = new LocalDateTime.at(2014, 6, 27, 12, 15, seconds: 8);
  expect(expected, start.adjustTime(TimeAdjusters.TruncateToSecond));
}

@Test()
void With_DateAdjuster()
{
  LocalDateTime start = new LocalDateTime.at(2014, 6, 27, 12, 5, seconds: 8).plusNanoseconds(123456789);
  LocalDateTime expected = new LocalDateTime.at(2014, 6, 30, 12, 5, seconds: 8).plusNanoseconds(123456789);
  expect(expected, start.adjustDate(DateAdjusters.endOfMonth));
}

@Test()
@TestCase(const [-9998, 1, 1, -1])
@TestCase(const [9999, 12, 31, 24])
@TestCase(const [1970, 1, 1, Utility.int64MaxValue])
@TestCase(const [1970, 1, 1, Utility.int64MinValue])
void PlusHours_Overflow(int year, int month, int day, int hours)
{
  TestHelper.AssertOverflow(new LocalDateTime.at(year, month, day, 0, 0).plusHours, hours);
}


