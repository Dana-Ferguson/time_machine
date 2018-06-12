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

// List<DayOfWeek> BclDaysOfWeek = []; //(DayOfWeek[])Enum.GetValues(typeof(DayOfWeek));
List<CalendarWeekRule> CalendarWeekRules = CalendarWeekRule.values;

@Test()
void RoundtripFirstDay_Iso7()
{
  // In the Gregorian calendar with a minimum of 7 days in the first
  // week, Tuesday January 1st -9998 is in week year -9999. We should be able to
  // round-trip.
  var rule = WeekYearRules.forMinDaysInFirstWeek(7);
  var date = new LocalDate(-9998, 1, 1);
  expect(date, rule.getLocalDate(
      rule.getWeekYear(date),
      rule.getWeekOfWeekYear(date),
      date.dayOfWeek,
      CalendarSystem.iso));
}

@Test()
void RoundtripLastDay_Iso1()
{
  // In the Gregorian calendar with a minimum of 1 day in the first
  // week, Friday December 31st 9999 is in week year 10000. We should be able to
  // round-trip.
  var rule = WeekYearRules.forMinDaysInFirstWeek(1);
  var date = new LocalDate(9999, 12, 31);
  expect(date, rule.getLocalDate(
      rule.getWeekYear(date),
      rule.getWeekOfWeekYear(date),
      date.dayOfWeek,
      CalendarSystem.iso));
}

@Test()
void OutOfRange_ValidWeekYearAndWeek_TooEarly()
{
  // Gregorian 4: Week year 1 starts on Monday December 31st -9999,
  // and is therefore out of range, even though the week-year
  // and week-of-week-year are valid.
  expect(() => WeekYearRules.iso.getLocalDate(-9998, 1, IsoDayOfWeek.monday, CalendarSystem.iso), willThrow<RangeError>());

  // Sanity check: no exception for January 1st
  WeekYearRules.iso.getLocalDate(-9998, 1, IsoDayOfWeek.tuesday, CalendarSystem.iso);
}

@Test()
void OutOfRange_ValidWeekYearAndWeek_TooLate()
{
// Gregorian 4: December 31st 9999 is a Friday, so the Saturday of the
// same week is therefore out of range, even though the week-year
// and week-of-week-year are valid.
//Assert.Throws<ArgumentOutOfRangeException>(
//        () => WeekYearRules.Iso.GetLocalDate(9999, 52, Saturday));

  expect(() => WeekYearRules.iso.getLocalDate(9999, 52, IsoDayOfWeek.saturday, CalendarSystem.iso), willThrow<ArgumentError>());

  // Sanity check: no exception for December 31st
  WeekYearRules.iso.getLocalDate(9999, 52, IsoDayOfWeek.friday, CalendarSystem.iso);
}

// Tests ported from IsoCalendarSystemTest and LocalDateTest.Construction
@Test()
@TestCase(const [2011, 1, 1, 2010, 52, IsoDayOfWeek.saturday])
@TestCase(const [2012, 12, 31, 2013, 1, IsoDayOfWeek.monday])
@TestCase(const [1960, 1, 19, 1960, 3, IsoDayOfWeek.tuesday])
@TestCase(const [2012, 10, 19, 2012, 42, IsoDayOfWeek.friday])
@TestCase(const [2011, 1, 1, 2010, 52, IsoDayOfWeek.saturday])
@TestCase(const [2012, 12, 31, 2013, 1, IsoDayOfWeek.monday])
@TestCase(const [2005, 1, 2, 2004, 53, IsoDayOfWeek.sunday])
void WeekYearDifferentToYear(int year, int month, int day, int weekYear, int weekOfWeekYear, IsoDayOfWeek dayOfWeek)
{
  var date = new LocalDate(year, month, day);
  expect(weekYear, WeekYearRules.iso.getWeekYear(date));
  expect(weekOfWeekYear, WeekYearRules.iso.getWeekOfWeekYear(date));
  expect(dayOfWeek, date.dayOfWeek);
  expect(date, WeekYearRules.iso.getLocalDate(weekYear, weekOfWeekYear, dayOfWeek, CalendarSystem.iso));
}

// Ported from CalendarSystemTest.Validation
@Test()
@TestCase(const [2009, 53])
@TestCase(const [2010, 52])
@TestCase(const [2011, 52])
@TestCase(const [2012, 52])
@TestCase(const [2013, 52])
@TestCase(const [2014, 52])
@TestCase(const [2015, 53])
@TestCase(const [2016, 52])
@TestCase(const [2017, 52])
@TestCase(const [2018, 52])
@TestCase(const [2019, 52])
void GetWeeksInWeekYear(int weekYear, int expectedResult)
{
  expect(expectedResult, WeekYearRules.iso.getWeeksInWeekYear(weekYear, CalendarSystem.iso));
}

// Ported from LocalDateTest.BasicProperties
// See http://stackoverflow.com/questions/8010125
@Test()
@TestCase(const [2007, 12, 31, 1])
@TestCase(const [2008, 1, 6, 1])
@TestCase(const [2008, 1, 7, 2])
@TestCase(const [2008, 12, 28, 52])
@TestCase(const [2008, 12, 29, 1])
@TestCase(const [2009, 1, 4, 1])
@TestCase(const [2009, 1, 5, 2])
@TestCase(const [2009, 12, 27, 52])
@TestCase(const [2009, 12, 28, 53])
@TestCase(const [2010, 1, 3, 53])
@TestCase(const [2010, 1, 4, 1])
void WeekOfWeekYear_ComparisonWithOracle(int year, int month, int day, int weekOfWeekYear)
{
  var date = new LocalDate(year, month, day);
  expect(weekOfWeekYear, WeekYearRules.iso.getWeekOfWeekYear(date));
}

@Test()
@TestCase(const [2000, IsoDayOfWeek.saturday, 2])
@TestCase(const [2001, IsoDayOfWeek.monday, 7])
@TestCase(const [2002, IsoDayOfWeek.tuesday, 6])
@TestCase(const [2003, IsoDayOfWeek.wednesday, 5])
@TestCase(const [2004, IsoDayOfWeek.thursday, 4])
@TestCase(const [2005, IsoDayOfWeek.saturday, 2])
@TestCase(const [2006, IsoDayOfWeek.sunday, 1])
void Gregorian(int year, IsoDayOfWeek firstDayOfYear, int maxMinDaysInFirstWeekForSameWeekYear)
{
  var startOfCalendarYear = new LocalDate(year, 1, 1);
  expect(firstDayOfYear, startOfCalendarYear.dayOfWeek);

  // Rules which put the first day of the calendar year into the same week year
  for (int i = 1; i <= maxMinDaysInFirstWeekForSameWeekYear; i++)
  {
    var rule = WeekYearRules.forMinDaysInFirstWeek(i);
    expect(year, rule.getWeekYear(startOfCalendarYear));
    expect(1, rule.getWeekOfWeekYear(startOfCalendarYear));
  }
  // Rules which put the first day of the calendar year into the previous week year
  for (int i = maxMinDaysInFirstWeekForSameWeekYear + 1; i <= 7; i++)
  {
    var rule = WeekYearRules.forMinDaysInFirstWeek(i);
    expect(year - 1, rule.getWeekYear(startOfCalendarYear));
    expect(rule.getWeeksInWeekYear(year - 1, CalendarSystem.iso), rule.getWeekOfWeekYear(startOfCalendarYear));
  }
}

// Test cases from https://blogs.msdn.microsoft.com/shawnste/2006/01/24/iso-8601-week-of-year-format-in-microsoft-net/
// which distinguish our ISO option from the BCL. When we implement the BCL equivalents, we should have similar
// tests there...
@Test()
@TestCase(const [2000, 12, 31, 2000, 52, IsoDayOfWeek.sunday])
@TestCase(const [2001, 1, 1, 2001, 1, IsoDayOfWeek.monday])
@TestCase(const [2005, 1, 1, 2004, 53, IsoDayOfWeek.saturday])
@TestCase(const [2007, 12, 31, 2008, 1, IsoDayOfWeek.monday])
void Iso(int year, int month, int day, int weekYear, int weekOfWeekYear, IsoDayOfWeek dayOfWeek)
{
  var viaCalendar = new LocalDate(year, month, day);
  var rule = WeekYearRules.iso;
  expect(weekYear, rule.getWeekYear(viaCalendar));
  expect(weekOfWeekYear, rule.getWeekOfWeekYear(viaCalendar));
  expect(dayOfWeek, viaCalendar.dayOfWeek);
  var viaRule = rule.getLocalDate(weekYear, weekOfWeekYear, dayOfWeek, CalendarSystem.iso);
  expect(viaCalendar, viaRule);
}

/// Just a sample test of not using the Gregorian/ISO calendar system.
@Test() @SkipMe.unimplemented()
@TestCase(const [5400, IsoDayOfWeek.thursday, 1639, 9, 29, 51, 5400, 1])
@TestCase(const [5401, IsoDayOfWeek.monday, 1640, 9, 17, 50, 5401, 1])
@TestCase(const [5402, IsoDayOfWeek.thursday, 1641, 9, 5, 55, 5402, 1])
@TestCase(const [5403, IsoDayOfWeek.thursday, 1642, 9, 25, 51, 5403, 1])
@TestCase(const [5404, IsoDayOfWeek.monday, 1643, 9, 14, 55, 5404, 1])
@TestCase(const [5405, IsoDayOfWeek.saturday, 1644, 10, 1, 50, 5404, 55])
@TestCase(const [5406, IsoDayOfWeek.thursday, 1645, 9, 21, 51, 5406, 1])
@TestCase(const [5407, IsoDayOfWeek.monday, 1646, 9, 10, 55, 5407, 1])
@TestCase(const [5408, IsoDayOfWeek.monday, 1647, 9, 30, 50, 5408, 1])
@TestCase(const [5409, IsoDayOfWeek.thursday, 1648, 9, 17, 51, 5409, 1])
@TestCase(const [5410, IsoDayOfWeek.tuesday, 1649, 9, 7, 55, 5410, 1])
void HebrewCalendar(int year, IsoDayOfWeek expectedFirstDay,
    int isoYear, int isoMonth, int isoDay, // Mostly for documentation
    int expectedWeeks, int expectedWeekYearOfFirstDay, int expectedWeekOfWeekYearOfFirstDay)
{
  var civilDate = new LocalDate(year, 1, 1, CalendarSystem.hebrewCivil);
  var rule = WeekYearRules.iso;
  expect(expectedFirstDay, civilDate.dayOfWeek);
  expect(civilDate.withCalendar(CalendarSystem.iso), new LocalDate(isoYear, isoMonth, isoDay));
  expect(expectedWeeks, rule.getWeeksInWeekYear(year, CalendarSystem.hebrewCivil));
  expect(expectedWeekYearOfFirstDay, rule.getWeekYear(civilDate));
  expect(expectedWeekOfWeekYearOfFirstDay, rule.getWeekOfWeekYear(civilDate));
  expect(civilDate,
      rule.getLocalDate(expectedWeekYearOfFirstDay, expectedWeekOfWeekYearOfFirstDay, expectedFirstDay, CalendarSystem.hebrewCivil));

  // The scriptural month numbering system should have the same week-year and week-of-week-year.
  var scripturalDate = civilDate.withCalendar(CalendarSystem.hebrewScriptural);
  expect(expectedWeeks, rule.getWeeksInWeekYear(year, CalendarSystem.hebrewScriptural));
  expect(expectedWeekYearOfFirstDay, rule.getWeekYear(scripturalDate));
  expect(expectedWeekOfWeekYearOfFirstDay, rule.getWeekOfWeekYear(scripturalDate));
  expect(scripturalDate,
      rule.getLocalDate(expectedWeekYearOfFirstDay, expectedWeekOfWeekYearOfFirstDay, expectedFirstDay, CalendarSystem.hebrewScriptural));
}

// Jan 1st 2015 = Thursday
// Jan 1st 2016 = IsoDayOfWeek.friday
// Jan 1st 2017 = Sunday
@Test()
@TestCase(const [1, IsoDayOfWeek.wednesday, 2015, 2, IsoDayOfWeek.friday, 2015, 1, 9])
@TestCase(const [7, IsoDayOfWeek.wednesday, 2015, 2, IsoDayOfWeek.friday, 2015, 1, 16])
@TestCase(const [1, IsoDayOfWeek.wednesday, 2015, 1, IsoDayOfWeek.wednesday, 2014, 12, 31])
@TestCase(const [3, IsoDayOfWeek.friday, 2016, 1, IsoDayOfWeek.friday, 2016, 1, 1])
@TestCase(const [3, IsoDayOfWeek.friday, 2017, 1, IsoDayOfWeek.friday, 2016, 12, 30])
// We might want to add more tests here...
void NonMondayFirstDayOfWeek(int minDaysInFirstWeek, IsoDayOfWeek firstDayOfWeek,
    int weekYear, int week, IsoDayOfWeek dayOfWeek,
    int expectedYear, int expectedMonth, int expectedDay)
{
  var rule = WeekYearRules.forMinDaysInFirstWeek(minDaysInFirstWeek, firstDayOfWeek);
  var actual = rule.getLocalDate(weekYear, week, dayOfWeek, CalendarSystem.iso);
  var expected = new LocalDate(expectedYear, expectedMonth, expectedDay);
  expect(expected, actual);
  expect(weekYear, rule.getWeekYear(actual));
  expect(week, rule.getWeekOfWeekYear(actual));
}

/*
// Tests for BCL rules...

/// For each calendar and rule combination, check everything we can about every date
/// from mid December to mid January around each year between 2016 and 2046.
/// (For non-Gregorian calendars, the rough equivalent is used...)
/// That should give us plenty of coverage.
@Test()
[Combinatorial]
void BclEquivalence(
[ValueSource(typeof(BclCalendars), nameof(BclCalendars.MappedCalendars))] Calendar calendar,
[ValueSource(#CalendarWeekRules)] CalendarWeekRule bclRule,
[ValueSource(#BclDaysOfWeek)] DayOfWeek firstDayOfWeek)
{
var nodaCalendar = BclCalendars.CalendarSystemForCalendar(calendar);
var nodaRule = WeekYearRules.FromCalendarWeekRule(bclRule, firstDayOfWeek);
var startYear = new LocalDate(2016, 1, 1).WithCalendar(nodaCalendar).Year;

for (int year = startYear; year < startYear + 30; year++)
{
var startDate = new LocalDate(year, 1, 1, nodaCalendar).PlusDays(-15);
for (int day = 0; day < 30; day++)
{
var date = startDate.PlusDays(day);
var bclDate = date.ToDateTimeUnspecified();
var bclWeek = calendar.GetWeekOfYear(bclDate, bclRule, firstDayOfWeek);
// Weird... the BCL doesn't have a way of finding out which week-year we're in.
// We're starting at "start of year - 15 days", so a "small" week-of-year
// value means we're in "year", whereas a "large" week-of-year value means
// we're in the "year-1".
var bclWeekYear = bclWeek < 10 ? year : year - 1;

expect(bclWeek, nodaRule.GetWeekOfWeekYear(date), "Date: {0}", date);
expect(bclWeekYear, nodaRule.GetWeekYear(date), "Date: {0}", date);
expect(date, nodaRule.GetLocalDate(bclWeekYear, bclWeek, date.DayOfWeek, nodaCalendar),
"Week-year:{0}; Week: {1}; Day: {2}", bclWeekYear, bclWeek, date.DayOfWeek);
}
}
}

/// The number of weeks in the year is equal to the week-of-week-year for the last
/// day of the year.
@Test()
[Combinatorial]
void GetWeeksInWeekYear(
[ValueSource(typeof(BclCalendars), nameof(BclCalendars.MappedCalendars))] Calendar calendar,
[ValueSource(#CalendarWeekRules)] CalendarWeekRule bclRule,
[ValueSource(#BclDaysOfWeek)] DayOfWeek firstDayOfWeek)
{
var nodaCalendar = BclCalendars.CalendarSystemForCalendar(calendar);
var nodaRule = WeekYearRules.FromCalendarWeekRule(bclRule, firstDayOfWeek);
var startYear = new LocalDate(2016, 1, 1).WithCalendar(nodaCalendar).Year;

for (int year = startYear; year < startYear + 30; year++)
{
var bclDate = new LocalDate(year + 1, 1, 1, nodaCalendar).PlusDays(-1).ToDateTimeUnspecified();
expect(calendar.GetWeekOfYear(bclDate, bclRule, firstDayOfWeek),
nodaRule.GetWeeksInWeekYear(year, nodaCalendar), "Year {0}", year);
}
}


// Tests where we ask for an invalid combination of week-year/week/day-of-week due to a week being "short"
// in BCL rules.
// Jan 1st 2016 = Friday
@Test()
@TestCase(const [FirstDay, DayOfWeek.Monday, 2015, 53, IsoDayOfWeek.saturday])
@TestCase(const [FirstDay, DayOfWeek.Monday, 2016, 1, IsoDayOfWeek.thursday])
void GetLocalDate_Invalid(
    CalendarWeekRule bclRule, DayOfWeek firstDayOfWeek,
    int weekYear, int week, IsoDayOfWeek dayOfWeek)
{
  var nodaRule = WeekYearRules.FromCalendarWeekRule(bclRule, firstDayOfWeek);
  expect(() => nodaRule.GetLocalDate(weekYear, week, dayOfWeek), throwsRangeError);
}

@Test()
[Combinatorial]
void RoundtripFirstDayBcl(
[ValueSource(#CalendarWeekRules)] CalendarWeekRule bclRule,
[ValueSource(#BclDaysOfWeek)] DayOfWeek firstDayOfWeek)
{
var rule = WeekYearRules.FromCalendarWeekRule(bclRule, firstDayOfWeek);
var date = new LocalDate(-9998, 1, 1);
expect(date, rule.GetLocalDate(
rule.GetWeekYear(date),
rule.GetWeekOfWeekYear(date),
date.DayOfWeek));
}

@Test()
[Combinatorial]
void RoundtripLastDayBcl(
[ValueSource(#CalendarWeekRules)] CalendarWeekRule bclRule,
[ValueSource(#BclDaysOfWeek)] DayOfWeek firstDayOfWeek)
{
var rule = WeekYearRules.FromCalendarWeekRule(bclRule, firstDayOfWeek);
var date = new LocalDate(9999, 12, 31);
expect(date, rule.GetLocalDate(
rule.GetWeekYear(date),
rule.GetWeekOfWeekYear(date),
date.DayOfWeek));
}
*/

// TODO: Test the difference in ValidateWeekYear for 9999 between regular and non-regular rules.


