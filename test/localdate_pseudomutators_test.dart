// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

@Test()
void PlusYear_Simple()
{
  LocalDate start = new LocalDate(2011, 6, 26);
  LocalDate expected = new LocalDate(2016, 6, 26);
  expect(expected, start.plusYears(5));

  expected = new LocalDate(2006, 6, 26);
  expect(expected, start.plusYears(-5));
}

@Test()
void PlusYear_LeapToNonLeap()
{
  LocalDate start = new LocalDate(2012, 2, 29);
  LocalDate expected = new LocalDate(2013, 2, 28);
  expect(expected, start.plusYears(1));

  expected = new LocalDate(2011, 2, 28);
  expect(expected, start.plusYears(-1));
}

@Test()
void PlusYear_LeapToLeap()
{
  LocalDate start = new LocalDate(2012, 2, 29);
  LocalDate expected = new LocalDate(2016, 2, 29);
  expect(expected, start.plusYears(4));
}

@Test()
void PlusMonth_Simple()
{
  LocalDate start = new LocalDate(2012, 4, 15);
  LocalDate expected = new LocalDate(2012, 8, 15);
  expect(expected, start.plusMonths(4));
}

@Test()
void PlusMonth_ChangingYear()
{
  LocalDate start = new LocalDate(2012, 10, 15);
  LocalDate expected = new LocalDate(2013, 2, 15);
  expect(expected, start.plusMonths(4));
}

@Test()
void PlusMonth_WithTruncation()
{
  LocalDate start = new LocalDate(2011, 1, 30);
  LocalDate expected = new LocalDate(2011, 2, 28);
  expect(expected, start.plusMonths(1));
}

@Test()
void PlusDays_SameMonth()
{
  LocalDate start = new LocalDate(2011, 1, 15);
  LocalDate expected = new LocalDate(2011, 1, 23);
  expect(expected, start.plusDays(8));

  expected = new LocalDate(2011, 1, 7);
  expect(expected, start.plusDays(-8));
}

@Test()
void PlusDays_MonthBoundary()
{
  LocalDate start = new LocalDate(2011, 1, 26);
  LocalDate expected = new LocalDate(2011, 2, 3);
  expect(expected, start.plusDays(8));

  // Round-trip back across the boundary
  expect(start, start.plusDays(8).plusDays(-8));
}

@Test()
void PlusDays_YearBoundary()
{
  LocalDate start = new LocalDate(2011, 12, 26);
  LocalDate expected = new LocalDate(2012, 1, 3);
  expect(expected, start.plusDays(8));

  // Round-trip back across the boundary
  expect(start, start.plusDays(8).plusDays(-8));
}

@Test()
void PlusDays_EndOfFebruary_InLeapYear()
{
  LocalDate start = new LocalDate(2012, 2, 26);
  LocalDate expected = new LocalDate(2012, 3, 5);
  expect(expected, start.plusDays(8));
  // Round-trip back across the boundary
  expect(start, start.plusDays(8).plusDays(-8));
}

@Test()
void PlusDays_EndOfFebruary_NotInLeapYear()
{
  LocalDate start = new LocalDate(2011, 2, 26);
  LocalDate expected = new LocalDate(2011, 3, 6);
  expect(expected, start.plusDays(8));

  // Round-trip back across the boundary
  expect(start, start.plusDays(8).plusDays(-8));
}

@Test()
void PlusDays_LargeValue()
{
  LocalDate start = new LocalDate(2013, 2, 26);
  LocalDate expected = new LocalDate(2015, 2, 26);
  expect(expected, start.plusDays(365 * 2));
}

@Test()
void PlusWeeks_Simple()
{
  LocalDate start = new LocalDate(2011, 4, 2);
  LocalDate expectedForward = new LocalDate(2011, 4, 23);
  LocalDate expectedBackward = new LocalDate(2011, 3, 12);
  expect(expectedForward, start.plusWeeks(3));
  expect(expectedBackward, start.plusWeeks(-3));
}

@Test()
@TestCase(const [-9998, 1, 1, -1])
@TestCase(const [-9996, 1, 1, -1000])
@TestCase(const [9999, 12, 31, 1])
@TestCase(const [9997, 12, 31, 1000])
@TestCase(const [2000, 1, 1, Platform.int32MaxValue])
@TestCase(const [1, 1, 1, Platform.int32MinValue])
void PlusDays_OutOfRange(int year, int month, int day, int days)
{
  var start = new LocalDate(year, month, day);
  TestHelper.AssertOverflow<int, LocalDate>(start.plusDays, days);
}

// Each test case gives a day-of-month in November 2011 and a target "next day of week";
// the result is the next day-of-month in November 2011 with that target day.
// The tests are picked somewhat arbitrarily...
@TestCase(const [10, DayOfWeek.wednesday, 16])
@TestCase(const [10, DayOfWeek.friday, 11])
@TestCase(const [10, DayOfWeek.thursday, 17])
@TestCase(const [11, DayOfWeek.wednesday, 16])
@TestCase(const [11, DayOfWeek.thursday, 17])
@TestCase(const [11, DayOfWeek.friday, 18])
@TestCase(const [11, DayOfWeek.saturday, 12])
@TestCase(const [11, DayOfWeek.sunday, 13])
@TestCase(const [12, DayOfWeek.friday, 18])
@TestCase(const [13, DayOfWeek.friday, 18])
void Next(int dayOfMonth, DayOfWeek targetDayOfWeek, int expectedResult)
{
  LocalDate start = new LocalDate(2011, 11, dayOfMonth);
  LocalDate target = start.next(targetDayOfWeek);
  expect(2011, target.year);
  expect(11, target.month);
  expect(target.day, expectedResult);
}

@TestCase(const [0])
@TestCase(const [-1])
@TestCase(const [8])
void Next_InvalidArgument(DayOfWeek targetDayOfWeek)
{
  LocalDate start = new LocalDate(2011, 1, 1);
  expect(() => start.next(targetDayOfWeek), throwsRangeError);
}

// Each test case gives a day-of-month in November 2011 and a target "next day of week";
// the result is the next day-of-month in November 2011 with that target day.
@TestCase(const [10, DayOfWeek.wednesday, 9])
@TestCase(const [10, DayOfWeek.friday, 4])
@TestCase(const [10, DayOfWeek.thursday, 3])
@TestCase(const [11, DayOfWeek.wednesday, 9])
@TestCase(const [11, DayOfWeek.thursday, 10])
@TestCase(const [11, DayOfWeek.friday, 4])
@TestCase(const [11, DayOfWeek.saturday, 5])
@TestCase(const [11, DayOfWeek.sunday, 6])
@TestCase(const [12, DayOfWeek.friday, 11])
@TestCase(const [13, DayOfWeek.friday, 11])
void Previous(int dayOfMonth, DayOfWeek targetDayOfWeek, int expectedResult)
{
  LocalDate start = new LocalDate(2011, 11, dayOfMonth);
  LocalDate target = start.previous(targetDayOfWeek);
  expect(2011, target.year);
  expect(11, target.month);
  expect(target.day, expectedResult);
}

@TestCase(const [0])
@TestCase(const [-1])
@TestCase(const [8])
void Previous_InvalidArgument(DayOfWeek targetDayOfWeek)
{
  LocalDate start = new LocalDate(2011, 1, 1);
  expect(() => start.previous(targetDayOfWeek), throwsRangeError);
}

// No tests for non-ISO-day-of-week calendars as we don't have any yet.

@Test()
void With()
{
  LocalDate start = new LocalDate(2014, 6, 27);
  LocalDate expected = new LocalDate(2014, 6, 30);
  expect(expected, start.adjust(DateAdjusters.endOfMonth));
}
