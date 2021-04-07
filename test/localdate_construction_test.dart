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
@TestCase([1620], 'Leap year in non-optimized period')
@TestCase([1621], 'Non-leap year in non-optimized period')
@TestCase([1980], 'Leap year in optimized period')
@TestCase([1981], 'Non-leap year in optimized period')
void Constructor_WithDays(int year)
{
  LocalDate start = LocalDate(year, 1, 1);
  int startDays = start.epochDay;
  for (int i = 0; i < 366; i++)
  {
    expect(start.addDays(i), LocalDate.fromEpochDay(startDays + i));
  }
}

@Test()
@TestCase([1620], 'Leap year in non-optimized period')
@TestCase([1621], 'Non-leap year in non-optimized period')
@TestCase([1980], 'Leap year in optimized period')
@TestCase([1981], 'Non-leap year in optimized period')
void Constructor_WithDaysAndCalendar(int year)
{
  LocalDate start = LocalDate(year, 1, 1);
  int startDays = start.epochDay;
  for (int i = 0; i < 366; i++)
  {
    expect(start.addDays(i), LocalDate.fromEpochDay(startDays + i, CalendarSystem.iso));
  }
}

@Test()
void Constructor_CalendarDefaultsToIso()
{
  LocalDate date = LocalDate(2000, 1, 1);
  expect(CalendarSystem.iso, date.calendar);
}

@Test()
void Constructor_PropertiesRoundTrip()
{
  LocalDate date = LocalDate(2023, 7, 27);
  expect(2023, date.year);
  expect(7, date.monthOfYear);
  expect(27, date.dayOfMonth);
}

@Test()
void Constructor_PropertiesRoundTrip_CustomCalendar()
{
  LocalDate date = LocalDate(2023, 7, 27, CalendarSystem.julian);
  expect(2023, date.year);
  expect(7, date.monthOfYear);
  expect(27, date.dayOfMonth);
}

@Test()
@TestCase([GregorianYearMonthDayCalculator.maxGregorianYear + 1, 1, 1])
@TestCase([GregorianYearMonthDayCalculator.minGregorianYear - 1, 1, 1])
@TestCase([2010, 13, 1])
@TestCase([2010, 0, 1])
@TestCase([2010, 1, 100])
@TestCase([2010, 2, 30])
@TestCase([2010, 1, 0])
void Constructor_Invalid(int year, int month, int day)
{
  // Assert.Throws<ArgumentOutOfRangeException>
  expect(() => LocalDate(year, month, day), throwsRangeError);
}

@Test()
@TestCase([GregorianYearMonthDayCalculator.maxGregorianYear + 1, 1, 1])
@TestCase([GregorianYearMonthDayCalculator.minGregorianYear - 1, 1, 1])
@TestCase([2010, 13, 1])
@TestCase([2010, 0, 1])
@TestCase([2010, 1, 100])
@TestCase([2010, 2, 30])
@TestCase([2010, 1, 0])
void Constructor_Invalid_WithCalendar(int year, int month, int day)
{
  // Assert.Throws<ArgumentOutOfRangeException>
  expect(() => LocalDate(year, month, day, CalendarSystem.iso), throwsRangeError);
}

@Test()
void Constructor_InvalidYearOfEra()
{
  // Assert.Throws<ArgumentOutOfRangeException>
  expect(() => LocalDate(0, 1, 1, null, Era.common), throwsRangeError);
  expect(() => LocalDate(0, 1, 1, null, Era.beforeCommon), throwsRangeError);
  expect(() => LocalDate(10000, 1, 1, CalendarSystem.iso, Era.common), throwsRangeError);
  // Although our minimum year is -9998, that's 9999 BC.
  expect(() => LocalDate(10000, 1, 1, CalendarSystem.iso, Era.beforeCommon), throwsRangeError);
}

@Test()
void Constructor_WithYearOfEra_BC()
{
  LocalDate absolute = LocalDate(-10, 1, 1);
  LocalDate withEra = LocalDate(11, 1, 1, CalendarSystem.iso, Era.beforeCommon);
  expect(absolute, withEra);
}

@Test()
void Constructor_WithYearOfEra_AD()
{
  LocalDate absolute = LocalDate(50, 6, 19);
  LocalDate withEra = LocalDate(50, 6, 19, CalendarSystem.iso, Era.common);
  expect(absolute, withEra);
}

@Test()
void Constructor_WithYearOfEra_NonIsoCalendar()
{
  var calendar = CalendarSystem.coptic;
  LocalDate absolute = LocalDate(50, 6, 19, calendar);
  LocalDate withEra = LocalDate(50, 6, 19, calendar, Era.annoMartyrum);
  expect(absolute, withEra);
}

// Most tests are in IsoBasedWeekYearRuleTest.
@Test()
void FromWeekYearWeekAndDay_InvalidWeek53()
{
  // Week year 2005 only has 52 weeks
  // Assert.Throws<ArgumentOutOfRangeException>
  expect(() => LocalDate.isoWeekDate(2005, 53, DayOfWeek.sunday), throwsRangeError);
}

@Test()
@TestCase([2014, 8, 3, DayOfWeek.sunday, 17])
@TestCase([2014, 8, 3, DayOfWeek.friday, 15])
// Needs 'rewind' logic as August 1st 2014 is a Friday
@TestCase([2014, 8, 3, DayOfWeek.thursday, 21])
@TestCase([2014, 8, 5, DayOfWeek.sunday, 31])
// Only 4 Mondays in August in 2014.
@TestCase([2014, 8, 5, DayOfWeek.monday, 25])
void FromYearMonthWeekAndDay(int year, int month, int occurrence, DayOfWeek dayOfWeek, int expectedDay)
{
  var date = LocalDate.onDayOfWeekInMonth(year, month, occurrence, dayOfWeek);
  expect(year, date.year);
  expect(month, date.monthOfYear);
  expect(expectedDay, date.dayOfMonth);
}
