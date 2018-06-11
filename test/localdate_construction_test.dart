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
@TestCase(const [1620], 'Leap year in non-optimized period')
@TestCase(const [1621], 'Non-leap year in non-optimized period')
@TestCase(const [1980], 'Leap year in optimized period')
@TestCase(const [1981], 'Non-leap year in optimized period')
void Constructor_WithDays(int year)
{
  LocalDate start = new LocalDate(year, 1, 1);
  int startDays = start.daysSinceEpoch;
  for (int i = 0; i < 366; i++)
  {
    expect(start.plusDays(i), new LocalDate.fromDaysSinceEpoch(startDays + i));
  }
}

@Test()
@TestCase(const [1620], 'Leap year in non-optimized period')
@TestCase(const [1621], 'Non-leap year in non-optimized period')
@TestCase(const [1980], 'Leap year in optimized period')
@TestCase(const [1981], 'Non-leap year in optimized period')
void Constructor_WithDaysAndCalendar(int year)
{
  LocalDate start = new LocalDate(year, 1, 1);
  int startDays = start.daysSinceEpoch;
  for (int i = 0; i < 366; i++)
  {
    expect(start.plusDays(i), new LocalDate.fromDaysSinceEpoch(startDays + i, CalendarSystem.Iso));
  }
}

@Test()
void Constructor_CalendarDefaultsToIso()
{
  LocalDate date = new LocalDate(2000, 1, 1);
  expect(CalendarSystem.Iso, date.calendar);
}

@Test()
void Constructor_PropertiesRoundTrip()
{
  LocalDate date = new LocalDate(2023, 7, 27);
  expect(2023, date.year);
  expect(7, date.month);
  expect(27, date.day);
}

@Test()
void Constructor_PropertiesRoundTrip_CustomCalendar()
{
  LocalDate date = new LocalDate(2023, 7, 27, CalendarSystem.Julian);
  expect(2023, date.year);
  expect(7, date.month);
  expect(27, date.day);
}

@Test()
@TestCase(const [GregorianYearMonthDayCalculator.maxGregorianYear + 1, 1, 1])
@TestCase(const [GregorianYearMonthDayCalculator.minGregorianYear - 1, 1, 1])
@TestCase(const [2010, 13, 1])
@TestCase(const [2010, 0, 1])
@TestCase(const [2010, 1, 100])
@TestCase(const [2010, 2, 30])
@TestCase(const [2010, 1, 0])
void Constructor_Invalid(int year, int month, int day)
{
  // Assert.Throws<ArgumentOutOfRangeException>
  expect(() => new LocalDate(year, month, day), throwsRangeError);
}

@Test()
@TestCase(const [GregorianYearMonthDayCalculator.maxGregorianYear + 1, 1, 1])
@TestCase(const [GregorianYearMonthDayCalculator.minGregorianYear - 1, 1, 1])
@TestCase(const [2010, 13, 1])
@TestCase(const [2010, 0, 1])
@TestCase(const [2010, 1, 100])
@TestCase(const [2010, 2, 30])
@TestCase(const [2010, 1, 0])
void Constructor_Invalid_WithCalendar(int year, int month, int day)
{
  // Assert.Throws<ArgumentOutOfRangeException>
  expect(() => new LocalDate(year, month, day, CalendarSystem.Iso), throwsRangeError);
}

@Test()
void Constructor_InvalidYearOfEra()
{
  // Assert.Throws<ArgumentOutOfRangeException>
  expect(() => new LocalDate.forEra(Era.Common, 0, 1, 1), throwsRangeError);
  expect(() => new LocalDate.forEra(Era.BeforeCommon, 0, 1, 1), throwsRangeError);
  expect(() => new LocalDate.forEra(Era.Common, 10000, 1, 1), throwsRangeError);
  // Although our minimum year is -9998, that's 9999 BC.
  expect(() => new LocalDate.forEra(Era.BeforeCommon, 10000, 1, 1), throwsRangeError);
}

@Test()
void Constructor_WithYearOfEra_BC()
{
  LocalDate absolute = new LocalDate(-10, 1, 1);
  LocalDate withEra = new LocalDate.forEra(Era.BeforeCommon, 11, 1, 1);
  expect(absolute, withEra);
}

@Test()
void Constructor_WithYearOfEra_AD()
{
  LocalDate absolute = new LocalDate(50, 6, 19);
  LocalDate withEra = new LocalDate.forEra(Era.Common, 50, 6, 19);
  expect(absolute, withEra);
}

@Test() @SkipMe.unimplemented()
void Constructor_WithYearOfEra_NonIsoCalendar()
{
  var calendar = CalendarSystem.Coptic;
  LocalDate absolute = new LocalDate(50, 6, 19, calendar);
  LocalDate withEra = new LocalDate.forEra(Era.AnnoMartyrum, 50, 6, 19, calendar);
  expect(absolute, withEra);
}

// Most tests are in IsoBasedWeekYearRuleTest.
@Test()
void FromWeekYearWeekAndDay_InvalidWeek53()
{
  // Week year 2005 only has 52 weeks
  // Assert.Throws<ArgumentOutOfRangeException>
  expect(() => new LocalDate.fromWeekYearWeekAndDay(2005, 53, IsoDayOfWeek.sunday), throwsRangeError);
}

@Test()
@TestCase(const [2014, 8, 3, IsoDayOfWeek.sunday, 17])
@TestCase(const [2014, 8, 3, IsoDayOfWeek.friday, 15])
// Needs "rewind" logic as August 1st 2014 is a Friday
@TestCase(const [2014, 8, 3, IsoDayOfWeek.thursday, 21])
@TestCase(const [2014, 8, 5, IsoDayOfWeek.sunday, 31])
// Only 4 Mondays in August in 2014.
@TestCase(const [2014, 8, 5, IsoDayOfWeek.monday, 25])
void FromYearMonthWeekAndDay(int year, int month, int occurrence, IsoDayOfWeek dayOfWeek, int expectedDay)
{
  var date = new LocalDate.fromYearMonthWeekAndDay(year, month, occurrence, dayOfWeek);
  expect(year, date.year);
  expect(month, date.month);
  expect(expectedDay, date.day);
}
