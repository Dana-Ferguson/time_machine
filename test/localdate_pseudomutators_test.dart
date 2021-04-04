// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:test/test.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

@Test()
void PlusYear_Simple()
{
  LocalDate start = LocalDate(2011, 6, 26);
  LocalDate expected = LocalDate(2016, 6, 26);
  expect(expected, start.addYears(5));

  expected = LocalDate(2006, 6, 26);
  expect(expected, start.addYears(-5));
}

@Test()
void PlusYear_LeapToNonLeap()
{
  LocalDate start = LocalDate(2012, 2, 29);
  LocalDate expected = LocalDate(2013, 2, 28);
  expect(expected, start.addYears(1));

  expected = LocalDate(2011, 2, 28);
  expect(expected, start.addYears(-1));
}

@Test()
void PlusYear_LeapToLeap()
{
  LocalDate start = LocalDate(2012, 2, 29);
  LocalDate expected = LocalDate(2016, 2, 29);
  expect(expected, start.addYears(4));
}

@Test()
void PlusMonth_Simple()
{
  LocalDate start = LocalDate(2012, 4, 15);
  LocalDate expected = LocalDate(2012, 8, 15);
  expect(expected, start.addMonths(4));
}

@Test()
void PlusMonth_ChangingYear()
{
  LocalDate start = LocalDate(2012, 10, 15);
  LocalDate expected = LocalDate(2013, 2, 15);
  expect(expected, start.addMonths(4));
}

@Test()
void PlusMonth_WithTruncation()
{
  LocalDate start = LocalDate(2011, 1, 30);
  LocalDate expected = LocalDate(2011, 2, 28);
  expect(expected, start.addMonths(1));
}

@Test()
void PlusDays_SameMonth()
{
  LocalDate start = LocalDate(2011, 1, 15);
  LocalDate expected = LocalDate(2011, 1, 23);
  expect(expected, start.addDays(8));

  expected = LocalDate(2011, 1, 7);
  expect(expected, start.addDays(-8));
}

@Test()
void PlusDays_MonthBoundary()
{
  LocalDate start = LocalDate(2011, 1, 26);
  LocalDate expected = LocalDate(2011, 2, 3);
  expect(expected, start.addDays(8));

  // Round-trip back across the boundary
  expect(start, start.addDays(8).addDays(-8));
}

@Test()
void PlusDays_YearBoundary()
{
  LocalDate start = LocalDate(2011, 12, 26);
  LocalDate expected = LocalDate(2012, 1, 3);
  expect(expected, start.addDays(8));

  // Round-trip back across the boundary
  expect(start, start.addDays(8).addDays(-8));
}

@Test()
void PlusDays_EndOfFebruary_InLeapYear()
{
  LocalDate start = LocalDate(2012, 2, 26);
  LocalDate expected = LocalDate(2012, 3, 5);
  expect(expected, start.addDays(8));
  // Round-trip back across the boundary
  expect(start, start.addDays(8).addDays(-8));
}

@Test()
void PlusDays_EndOfFebruary_NotInLeapYear()
{
  LocalDate start = LocalDate(2011, 2, 26);
  LocalDate expected = LocalDate(2011, 3, 6);
  expect(expected, start.addDays(8));

  // Round-trip back across the boundary
  expect(start, start.addDays(8).addDays(-8));
}

@Test()
void PlusDays_LargeValue()
{
  LocalDate start = LocalDate(2013, 2, 26);
  LocalDate expected = LocalDate(2015, 2, 26);
  expect(expected, start.addDays(365 * 2));
}

@Test()
void PlusWeeks_Simple()
{
  LocalDate start = LocalDate(2011, 4, 2);
  LocalDate expectedForward = LocalDate(2011, 4, 23);
  LocalDate expectedBackward = LocalDate(2011, 3, 12);
  expect(expectedForward, start.addWeeks(3));
  expect(expectedBackward, start.addWeeks(-3));
}

@Test()
@TestCase([-9998, 1, 1, -1])
@TestCase([-9996, 1, 1, -1000])
@TestCase([9999, 12, 31, 1])
@TestCase([9997, 12, 31, 1000])
@TestCase([2000, 1, 1, Platform.int32MaxValue])
@TestCase([1, 1, 1, Platform.int32MinValue])
void PlusDays_OutOfRange(int year, int month, int day, int days)
{
  var start = LocalDate(year, month, day);
  TestHelper.AssertOverflow<int, LocalDate>(start.addDays, days);
}

// Each test case gives a day-of-month in November 2011 and a target 'next day of week';
// the result is the next day-of-month in November 2011 with that target day.
// The tests are picked somewhat arbitrarily...
@TestCase([10, DayOfWeek.wednesday, 16])
@TestCase([10, DayOfWeek.friday, 11])
@TestCase([10, DayOfWeek.thursday, 17])
@TestCase([11, DayOfWeek.wednesday, 16])
@TestCase([11, DayOfWeek.thursday, 17])
@TestCase([11, DayOfWeek.friday, 18])
@TestCase([11, DayOfWeek.saturday, 12])
@TestCase([11, DayOfWeek.sunday, 13])
@TestCase([12, DayOfWeek.friday, 18])
@TestCase([13, DayOfWeek.friday, 18])
void Next(int dayOfMonth, DayOfWeek targetDayOfWeek, int expectedResult)
{
  LocalDate start = LocalDate(2011, 11, dayOfMonth);
  LocalDate target = start.next(targetDayOfWeek);
  expect(2011, target.year);
  expect(11, target.monthOfYear);
  expect(target.dayOfMonth, expectedResult);
}

@TestCase([0])
@TestCase([-1])
@TestCase([8])
void Next_InvalidArgument(DayOfWeek targetDayOfWeek)
{
  LocalDate start = LocalDate(2011, 1, 1);
  expect(() => start.next(targetDayOfWeek), throwsRangeError);
}

// Each test case gives a day-of-month in November 2011 and a target 'next day of week';
// the result is the next day-of-month in November 2011 with that target day.
@TestCase([10, DayOfWeek.wednesday, 9])
@TestCase([10, DayOfWeek.friday, 4])
@TestCase([10, DayOfWeek.thursday, 3])
@TestCase([11, DayOfWeek.wednesday, 9])
@TestCase([11, DayOfWeek.thursday, 10])
@TestCase([11, DayOfWeek.friday, 4])
@TestCase([11, DayOfWeek.saturday, 5])
@TestCase([11, DayOfWeek.sunday, 6])
@TestCase([12, DayOfWeek.friday, 11])
@TestCase([13, DayOfWeek.friday, 11])
void Previous(int dayOfMonth, DayOfWeek targetDayOfWeek, int expectedResult)
{
  LocalDate start = LocalDate(2011, 11, dayOfMonth);
  LocalDate target = start.previous(targetDayOfWeek);
  expect(2011, target.year);
  expect(11, target.monthOfYear);
  expect(target.dayOfMonth, expectedResult);
}

@TestCase([0])
@TestCase([-1])
@TestCase([8])
void Previous_InvalidArgument(DayOfWeek targetDayOfWeek)
{
  LocalDate start = LocalDate(2011, 1, 1);
  expect(() => start.previous(targetDayOfWeek), throwsRangeError);
}

// No tests for non-ISO-day-of-week calendars as we don't have any yet.

@Test()
void With()
{
  LocalDate start = LocalDate(2014, 6, 27);
  LocalDate expected = LocalDate(2014, 6, 30);
  expect(expected, start.adjust(DateAdjusters.endOfMonth));
}
