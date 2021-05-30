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
    var ymdc = YearMonthDayCalendar(year, 5, 20, const CalendarOrdinal(0));
    expect(year, ymdc.year);
    expect(5, ymdc.month);
    expect(20, ymdc.day);
    expect(CalendarOrdinal.iso, ymdc.calendarOrdinal);
  }
}

@Test()
void AllMonths()
{
  // We'll never actually need 32 months, but we support that many...
  for (int month = 1; month <= 32; month++)
  {
    var ymdc = YearMonthDayCalendar(-123, month, 20, CalendarOrdinal.hebrewCivil);
    expect(-123, ymdc.year);
    expect(month, ymdc.month);
    expect(20, ymdc.day);
    expect(CalendarOrdinal.hebrewCivil, ymdc.calendarOrdinal);
  }
}

@Test()
void AllDays()
{
  // We'll never actually need 64 days, but we support that many...
  for (int day = 1; day <= 64; day++)
  {
    var ymdc = YearMonthDayCalendar(-123, 12, day, CalendarOrdinal.islamicAstronomicalBase15);
    expect(-123, ymdc.year);
    expect(12, ymdc.month);
    expect(day, ymdc.day);
    expect(CalendarOrdinal.islamicAstronomicalBase15, ymdc.calendarOrdinal);
  }
}

@Test()
void AllCalendars()
{
  for (int ordinal = 0; ordinal < 64; ordinal++)
  {
    CalendarOrdinal calendar = CalendarOrdinal(ordinal); //(CalendarOrdinal) ordinal;
    var ymdc = YearMonthDayCalendar(-123, 30, 64, calendar);
    expect(-123, ymdc.year);
    expect(30, ymdc.month);
    expect(64, ymdc.day);
    expect(calendar, ymdc.calendarOrdinal);
  }
}

@Test()
void Equality()
{
  var original = YearMonthDayCalendar(1000, 12, 20, CalendarOrdinal.coptic);
  var original2 = YearMonthDayCalendar(1000, 12, 20, CalendarOrdinal.coptic);
  TestHelper.TestEqualsStruct(original, YearMonthDayCalendar(1000, 12, 20, CalendarOrdinal.coptic),
      [YearMonthDayCalendar(original.year + 1, original.month, original.day, original.calendarOrdinal),
      YearMonthDayCalendar(original.year, original.month + 1, original.day, original.calendarOrdinal),
      YearMonthDayCalendar(original.year, original.month, original.day + 1, original.calendarOrdinal),
      YearMonthDayCalendar(original.year, original.month, original.day, CalendarOrdinal.gregorian)]);
  // Just test the first one again with operators.
  TestHelper.TestOperatorEquality(original, original2, YearMonthDayCalendar(original.year + 1, original.month, original.day, original.calendarOrdinal));
}

@Test()
@TestCase(['2017-08-21-Julian', 2017, 8, 21, CalendarOrdinal.julian])
@TestCase(['-0005-08-21-Iso', -5, 8, 21, CalendarOrdinal.iso])
void Parse(String text, int year, int month, int day, CalendarOrdinal calendar)
{
  var value = YearMonthDayCalendar.Parse(text);
  expect(year, value.year);
  expect(month, value.month);
  expect(day, value.day);
  // expect((CalendarOrdinal) calendar, value.CalendarOrdinal);
  expect(calendar, value.calendarOrdinal);
  expect(text, value.toString());
}

