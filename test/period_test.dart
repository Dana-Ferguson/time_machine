// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:math' as math;

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';
import 'package:time_machine/src/text/time_machine_text.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

// June 19th 2010, 2:30:15am
final LocalDateTime TestDateTime1 = new LocalDateTime.at(2010, 6, 19, 2, 30, seconds: 15);
// June 19th 2010, 4:45:10am
final LocalDateTime TestDateTime2 = new LocalDateTime.at(2010, 6, 19, 4, 45, seconds: 10);
// June 19th 2010
final LocalDate TestDate1 = new LocalDate(2010, 6, 19);
// March 1st 2011
final LocalDate TestDate2 = new LocalDate(2011, 3, 1);
// March 1st 2012
final LocalDate TestDate3 = new LocalDate(2012, 3, 1);

final PeriodUnits HoursMinutesPeriodType = PeriodUnits.hours | PeriodUnits.minutes;

final List<PeriodUnits> AllPeriodUnits = PeriodUnits.values;

@Test()
void BetweenLocalDateTimes_WithoutSpecifyingUnits_OmitsWeeks()
{
  Period actual = Period.between(new LocalDateTime.at(2012, 2, 21, 0, 0), new LocalDateTime.at(2012, 2, 28, 0, 0));
  Period expected = new Period.fromDays(7);
  expect(expected, actual);
}

@Test()
void BetweenLocalDateTimes_MovingForwardWithAllFields_GivesExactResult()
{
  Period actual = Period.between(TestDateTime1, TestDateTime2);
  Period expected = new Period.fromHours(2) + new Period.fromMinutes(14) + new Period.fromSeconds(55);
  expect(expected, actual);
}

@Test()
void BetweenLocalDateTimes_MovingBackwardWithAllFields_GivesExactResult()
{
  Period actual = Period.between(TestDateTime2, TestDateTime1);
  Period expected = new Period.fromHours(-2) + new Period.fromMinutes(-14) + new Period.fromSeconds(-55);
  expect(expected, actual);
}

@Test()
void BetweenLocalDateTimes_MovingForwardWithHoursAndMinutes_RoundsTowardsStart()
{
  Period actual = Period.between(TestDateTime1, TestDateTime2, HoursMinutesPeriodType);
  Period expected = new Period.fromHours(2) + new Period.fromMinutes(14);
  expect(expected, actual);
}

@Test()
void BetweenLocalDateTimes_MovingBackwardWithHoursAndMinutes_RoundsTowardsStart()
{
  Period actual = Period.between(TestDateTime2, TestDateTime1, HoursMinutesPeriodType);
  Period expected = new Period.fromHours(-2) + new Period.fromMinutes(-14);
  expect(expected, actual);
}

@Test()
void BetweenLocalDateTimes_AcrossDays()
{
  Period expected = new Period.fromHours(23) + new Period.fromMinutes(59);
  Period actual = Period.between(TestDateTime1, TestDateTime1.plusDays(1).plusMinutes(-1));
  expect(expected, actual);
}

@Test()
void BetweenLocalDateTimes_AcrossDays_MinutesAndSeconds()
{
  Period expected = new Period.fromMinutes(24 * 60 - 1) + new Period.fromSeconds(59);
  Period actual = Period.between(TestDateTime1, TestDateTime1.plusDays(1).plusSeconds(-1), PeriodUnits.minutes | PeriodUnits.seconds);
  expect(expected, actual);
}

@Test()
void BetweenLocalDateTimes_NotInt64Representable() {
  LocalDateTime start = new LocalDateTime.at(-5000, 1, 1, 0, 1, seconds: 2, milliseconds: 123);
  LocalDateTime end = new LocalDateTime.at(9000, 1, 1, 1, 2, seconds: 3, milliseconds: 456);
  expect(ISpan.isInt64Representable(end
      .toLocalInstant()
      .timeSinceLocalEpoch - start
      .toLocalInstant()
      .timeSinceLocalEpoch), isFalse);

  Period expected = (new PeriodBuilder()
    // 365.2425 * 14000 = 5113395
    ..hours = 5113395 * 24 + 1
    ..minutes = 1
    ..seconds = 1
    ..milliseconds = 333
  ).build();

  Period actual = Period.between(start, end, PeriodUnits.allTimeUnits);
  expect(actual, expected);
}

@Test()
void BetweenLocalDates_InvalidUnits()
{
  expect(() => Period.betweenDates(TestDate1, TestDate2, new PeriodUnits(0)), throwsArgumentError);
  expect(() => Period.betweenDates(TestDate1, TestDate2, new PeriodUnits(-1)), throwsArgumentError);
  expect(() => Period.betweenDates(TestDate1, TestDate2, PeriodUnits.allTimeUnits), throwsArgumentError);
  expect(() => Period.betweenDates(TestDate1, TestDate2, PeriodUnits.years | PeriodUnits.hours), throwsArgumentError);
}

@Test() @SkipMe.unimplemented()
void BetweenLocalDates_DifferentCalendarSystems_Throws()
{
  LocalDate start = new LocalDate(2017, 11, 1, CalendarSystem.coptic);
  LocalDate end = new LocalDate(2017, 11, 5, CalendarSystem.gregorian);
  expect(() => Period.betweenDates(start, end), throwsArgumentError);
}

@Test()
@TestCase(const ["2016-05-16", "2019-03-13", PeriodUnits.years, 2])
@TestCase(const ["2016-05-16", "2017-07-13", PeriodUnits.months, 13])
@TestCase(const ["2016-05-16", "2016-07-13", PeriodUnits.weeks, 8])
@TestCase(const ["2016-05-16", "2016-07-13", PeriodUnits.days, 58])
void BetweenLocalDates_SingleUnit(String startText, String endText, PeriodUnits units, int expectedValue)
{
  var start = LocalDatePattern.iso.parse(startText).value;
  var end = LocalDatePattern.iso.parse(endText).value;
  var actual = Period.betweenDates(start, end, units);
  var expected = (new PeriodBuilder()..[units] = expectedValue).build();
expect(expected, actual);
}

@Test()
void BetweenLocalDates_MovingForwardNoLeapYears_WithExactResults()
{
  Period actual = Period.betweenDates(TestDate1, TestDate2);
  Period expected = new Period.fromMonths(8) + new Period.fromDays(10);
  expect(expected, actual);
}

@Test()
void BetweenLocalDates_MovingForwardInLeapYear_WithExactResults()
{
  Period actual = Period.betweenDates(TestDate1, TestDate3);
  Period expected = new Period.fromYears(1) + new Period.fromMonths(8) + new Period.fromDays(11);
  expect(expected, actual);
}

@Test()
void BetweenLocalDates_MovingBackwardNoLeapYears_WithExactResults()
{
  Period actual = Period.betweenDates(TestDate2, TestDate1);
  Period expected = new Period.fromMonths(-8) + new Period.fromDays(-12);
  expect(expected, actual);
}

@Test()
void BetweenLocalDates_MovingBackwardInLeapYear_WithExactResults()
{
  // This is asymmetric with moving forward, because we first take off a whole year, which
  // takes us to March 1st 2011, then 8 months to take us to July 1st 2010, then 12 days
  // to take us back to June 19th. In this case, the fact that our start date is in a leap
  // year had no effect.
  Period actual = Period.betweenDates(TestDate3, TestDate1);
  Period expected = new Period.fromYears(-1) + new Period.fromMonths(-8) + new Period.fromDays(-12);
  expect(expected, actual);
}

@Test()
void BetweenLocalDates_MovingForward_WithJustMonths()
{
  Period actual = Period.betweenDates(TestDate1, TestDate3, PeriodUnits.months);
  Period expected = new Period.fromMonths(20);
  expect(expected, actual);
}

@Test()
void BetweenLocalDates_MovingBackward_WithJustMonths()
{
  Period actual = Period.betweenDates(TestDate3, TestDate1, PeriodUnits.months);
  Period expected = new Period.fromMonths(-20);
  expect(expected, actual);
}

@Test()
void BetweenLocalDates_AssymetricForwardAndBackward()
{
  // February 10th 2010
  LocalDate d1 = new LocalDate(2010, 2, 10);
  // March 30th 2010
  LocalDate d2 = new LocalDate(2010, 3, 30);
  // Going forward, we go to March 10th (1 month) then March 30th (20 days)
  expect(new Period.fromMonths(1) + new Period.fromDays(20), Period.betweenDates(d1, d2));
  // Going backward, we go to February 28th (-1 month, day is rounded) then February 10th (-18 days)
  expect(new Period.fromMonths(-1) + new Period.fromDays(-18), Period.betweenDates(d2, d1));
}

@Test()
void BetweenLocalDates_EndOfMonth()
{
  LocalDate d1 = new LocalDate(2013, 3, 31);
  LocalDate d2 = new LocalDate(2013, 4, 30);
  expect(new Period.fromMonths(1), Period.betweenDates(d1, d2));
  expect(new Period.fromDays(-30), Period.betweenDates(d2, d1));
}

@Test()
void BetweenLocalDates_OnLeapYear()
{
  LocalDate d1 = new LocalDate(2012, 2, 29);
  LocalDate d2 = new LocalDate(2013, 2, 28);
  expect(new Period.fromYears(1), Period.betweenDates(d1, d2));
  // Go back from February 28th 2013 to March 28th 2012, then back 28 days to February 29th 2012
  expect(new Period.fromMonths(-11) + new Period.fromDays(-28), Period.betweenDates(d2, d1));
}

@Test()
void BetweenLocalDates_AfterLeapYear()
{
  LocalDate d1 = new LocalDate(2012, 3, 5);
  LocalDate d2 = new LocalDate(2013, 3, 5);
  expect(new Period.fromYears(1), Period.betweenDates(d1, d2));
  expect(new Period.fromYears(-1), Period.betweenDates(d2, d1));
}

@Test()
void BetweenLocalDateTimes_OnLeapYear()
{
  LocalDateTime dt1 = new LocalDateTime.at(2012, 2, 29, 2, 0);
  LocalDateTime dt2 = new LocalDateTime.at(2012, 2, 29, 4, 0);
  LocalDateTime dt3 = new LocalDateTime.at(2013, 2, 28, 3, 0);
  expect(Parse("P1YT1H"), Period.between(dt1, dt3));
  expect(Parse("P11M29DT23H"), Period.between(dt2, dt3));

  expect(Parse("P-11M-28DT-1H"), Period.between(dt3, dt1));
  expect(Parse("P-11M-27DT-23H"), Period.between(dt3, dt2));
}

@Test() @SkipMe.unimplemented()
void BetweenLocalDateTimes_OnLeapYearIslamic()
{
  var calendar = CalendarSystem.getIslamicCalendar(null, null/*IslamicLeapYearPattern.Base15, IslamicEpoch.Civil*/);
  expect(calendar.isLeapYear(2), isTrue);
  expect(calendar.isLeapYear(3), isFalse);

  LocalDateTime dt1 = new LocalDateTime.at(2, 12, 30, 2, 0, calendar: calendar);
  LocalDateTime dt2 = new LocalDateTime.at(2, 12, 30, 4, 0, calendar: calendar);
  LocalDateTime dt3 = new LocalDateTime.at(3, 12, 29, 3, 0, calendar: calendar);

  // Adding a year truncates to 0003-12-28T02:00:00, then add an hour.
  expect(Parse("P1YT1H"), Period.between(dt1, dt3));
  // Adding a year would overshoot. Adding 11 months takes us to month 03-11-30T04:00.
  // Adding another 28 days takes us to 03-12-28T04:00, then add another 23 hours to finish.
  expect(Parse("P11M28DT23H"), Period.between(dt2, dt3));

  // Subtracting 11 months takes us to 03-01-29T03:00. Subtracting another 29 days
  // takes us to 02-12-30T03:00, and another hour to get to the target.
  expect(Parse("P-11M-29DT-1H"), Period.between(dt3, dt1));
  expect(Parse("P-11M-28DT-23H"), Period.between(dt3, dt2));
}

@Test()
void BetweenLocalDateTimes_InvalidUnits()
{
  expect(() => Period.betweenDates(TestDate1, TestDate2, new PeriodUnits(0)), throwsArgumentError);
  expect(() => Period.betweenDates(TestDate1, TestDate2, new PeriodUnits(-1)), throwsArgumentError);
}

@Test()
void BetweenLocalTimes_InvalidUnits()
{
  LocalTime t1 = new LocalTime(10, 0);
  LocalTime t2 = new LocalTime.fromHourMinuteSecondMillisecondTick(15, 30, 45, 20, 5);
  expect(() => Period.betweenTimes(t1, t2, new PeriodUnits(0)), throwsArgumentError);
  expect(() => Period.betweenTimes(t1, t2, new PeriodUnits(-1)), throwsArgumentError);
  expect(() => Period.betweenTimes(t1, t2, PeriodUnits.yearMonthDay), throwsArgumentError);
  expect(() => Period.betweenTimes(t1, t2, PeriodUnits.years | PeriodUnits.hours), throwsArgumentError);
}

@Test()
@TestCase(const ["01:02:03", "05:00:00", PeriodUnits.hours, 3])
@TestCase(const ["01:02:03", "03:00:00", PeriodUnits.minutes, 117])
@TestCase(const ["01:02:03", "01:05:02", PeriodUnits.seconds, 179])
@TestCase(const ["01:02:03", "01:02:04.1234", PeriodUnits.milliseconds, 1123])
@TestCase(const ["01:02:03", "01:02:04.1234", PeriodUnits.ticks, 11234000])
@TestCase(const ["01:02:03", "01:02:04.1234", PeriodUnits.nanoseconds, 1123400000])
void BetweenLocalTimes_SingleUnit(String startText, String endText, PeriodUnits units, int expectedValue) {
  var start = LocalTimePattern.extendedIso
      .parse(startText)
      .value;
  var end = LocalTimePattern.extendedIso
      .parse(endText)
      .value;
  var actual = Period.betweenTimes(start, end, units);
  var expected = (new PeriodBuilder()
    ..[units] = expectedValue).build();
  expect(expected, actual);
}

@Test()
void BetweenLocalTimes_MovingForwards()
{
  LocalTime t1 = new LocalTime(10, 0);
  LocalTime t2 = new LocalTime.fromHourMinuteSecondMillisecondTick(15, 30, 45, 20, 5);
  expect(new Period.fromHours(5) + new Period.fromMinutes(30) + new Period.fromSeconds(45) +
      new Period.fromMilliseconds(20) + new Period.fromTicks(5),
      Period.betweenTimes(t1, t2));
}

@Test()
void BetweenLocalTimes_MovingBackwards()
{
  LocalTime t1 = new LocalTime.fromHourMinuteSecondMillisecondTick(15, 30, 45, 20, 5);
  LocalTime t2 = new LocalTime(10, 0);
  expect(new Period.fromHours(-5) + new Period.fromMinutes(-30) + new Period.fromSeconds(-45) +
      new Period.fromMilliseconds(-20) + new Period.fromTicks(-5),
      Period.betweenTimes(t1, t2));
}

@Test()
void BetweenLocalTimes_MovingForwards_WithJustHours()
{
  LocalTime t1 = new LocalTime(11, 30);
  LocalTime t2 = new LocalTime(17, 15);
  expect(new Period.fromHours(5), Period.betweenTimes(t1, t2, PeriodUnits.hours));
}

@Test()
void BetweenLocalTimes_MovingBackwards_WithJustHours()
{
  LocalTime t1 = new LocalTime(17, 15);
  LocalTime t2 = new LocalTime(11, 30);
  expect(new Period.fromHours(-5), Period.betweenTimes(t1, t2, PeriodUnits.hours));
}

@Test()
void Addition_WithDifferent_PeriodTypes()
{
  Period p1 = new Period.fromHours(3);
  Period p2 = new Period.fromMinutes(20);
  Period sum = p1 + p2;
  expect(3, sum.hours);
  expect(20, sum.minutes);
}

@Test()
void Addition_With_IdenticalPeriodTypes()
{
  Period p1 = new Period.fromHours(3);
  Period p2 = new Period.fromHours(2);
  Period sum = p1 + p2;
  expect(5, sum.hours);
}

@Test()
void Addition_DayCrossingMonthBoundary()
{
  LocalDateTime start = new LocalDateTime.at(2010, 2, 20, 10, 0);
  LocalDateTime result = start + new Period.fromDays(10);
  expect(new LocalDateTime.at(2010, 3, 2, 10, 0), result);
}

@Test()
void Addition_OneYearOnLeapDay()
{
  LocalDateTime start = new LocalDateTime.at(2012, 2, 29, 10, 0);
  LocalDateTime result = start + new Period.fromYears(1);
  // Feb 29th becomes Feb 28th
  expect(new LocalDateTime.at(2013, 2, 28, 10, 0), result);
}

@Test()
void Addition_FourYearsOnLeapDay()
{
  LocalDateTime start = new LocalDateTime.at(2012, 2, 29, 10, 0);
  LocalDateTime result = start + new Period.fromYears(4);
  // Feb 29th is still valid in 2016
  expect(new LocalDateTime.at(2016, 2, 29, 10, 0), result);
}

@Test()
void Addition_YearMonthDay()
{
  // One year, one month, two days
  Period period = new Period.fromYears(1) + new Period.fromMonths(1) + new Period.fromDays(2);
  LocalDateTime start = new LocalDateTime.at(2007, 1, 30, 0, 0);
  // Periods are added in order, so this becomes...
  // Add one year: Jan 30th 2008
  // Add one month: Feb 29th 2008
  // Add two days: March 2nd 2008
  // If we added the days first, we'd end up with March 1st instead.
  LocalDateTime result = start + period;
  expect(new LocalDateTime.at(2008, 3, 2, 0, 0), result);
}

@Test()
void Subtraction_WithDifferent_PeriodTypes()
{
  Period p1 = new Period.fromHours(3);
  Period p2 = new Period.fromMinutes(20);
  Period sum = p1 - p2;
  expect(3, sum.hours);
  expect(-20, sum.minutes);
}

@Test()
void Subtraction_With_IdenticalPeriodTypes()
{
  Period p1 = new Period.fromHours(3);
  Period p2 = new Period.fromHours(2);
  Period sum = p1 - p2;
  expect(1, sum.hours);
}

@Test()
void Equality_WhenEqual()
{
  expect(new Period.fromHours(10), new Period.fromHours(10));
  expect(new Period.fromMinutes(15), new Period.fromMinutes(15));
  expect(new Period.fromDays(5), new Period.fromDays(5));
}

@Test()
void Equality_WithDifferentPeriodTypes_OnlyConsidersValues()
{
  Period allFields = new Period.fromMinutes(1) + new Period.fromHours(1) - new Period.fromMinutes(1);
  Period justHours = new Period.fromHours(1);
  expect(allFields, justHours);
}

@Test()
void Equality_WhenUnequal()
{
  expect(new Period.fromHours(10).equals(new Period.fromHours(20)), isFalse);
  expect(new Period.fromMinutes(15).equals(new Period.fromSeconds(15)), isFalse);
  expect(new Period.fromHours(1).equals(new Period.fromMinutes(60)), isFalse);
  // expect(new Period.fromHours(1).Equals(new Object()), isFalse);
  expect(new Period.fromHours(1).equals(null), isFalse);
// expect(new Period.fromHours(1).Equals(null), isFalse);
}

@Test()
@TestCase(const [PeriodUnits.years, false])
@TestCase(const [PeriodUnits.weeks, false])
@TestCase(const [PeriodUnits.months, false])
@TestCase(const [PeriodUnits.days, false])
@TestCase(const [PeriodUnits.hours, true])
@TestCase(const [PeriodUnits.minutes, true])
@TestCase(const [PeriodUnits.seconds, true])
@TestCase(const [PeriodUnits.milliseconds, true])
@TestCase(const [PeriodUnits.ticks, true])
@TestCase(const [PeriodUnits.nanoseconds, true])
void HasTimeComponent_SingleValued(PeriodUnits unit, bool hasTimeComponent) {
  var period = (new PeriodBuilder()
    ..[unit] = 1).build();
  expect(hasTimeComponent, period.hasTimeComponent);
}

@Test()
@TestCase(const [PeriodUnits.years, true])
@TestCase(const [PeriodUnits.weeks, true])
@TestCase(const [PeriodUnits.months, true])
@TestCase(const [PeriodUnits.days, true])
@TestCase(const [PeriodUnits.hours, false])
@TestCase(const [PeriodUnits.minutes, false])
@TestCase(const [PeriodUnits.seconds, false])
@TestCase(const [PeriodUnits.milliseconds, false])
@TestCase(const [PeriodUnits.ticks, false])
@TestCase(const [PeriodUnits.nanoseconds, false])
void HasDateComponent_SingleValued(PeriodUnits unit, bool hasDateComponent)
{
  var period = (new PeriodBuilder()..[unit] = 1).build();
expect(hasDateComponent, period.hasDateComponent);
}

@Test()
void HasTimeComponent_Compound()
{
  LocalDateTime dt1 = new LocalDateTime.at(2000, 1, 1, 10, 45);
  LocalDateTime dt2 = new LocalDateTime.at(2000, 2, 4, 11, 50);

  // Case 1: Entire period is date-based (no time units available)
  expect(Period.betweenDates(dt1.date, dt2.date).hasTimeComponent, isFalse);

  // Case 2: Period contains date and time units, but time units are all zero
  expect(Period.between(dt1.date.at(LocalTime.midnight), dt2.date.at(LocalTime.midnight)).hasTimeComponent, isFalse);

  // Case 3: Entire period is time-based, but 0. (Same local time twice here.)
  expect(Period.betweenTimes(dt1.time, dt1.time).hasTimeComponent, isFalse);

  // Case 4: Period contains date and time units, and some time units are non-zero
  expect(Period.between(dt1, dt2).hasTimeComponent, isTrue);

  // Case 5: Entire period is time-based, and some time units are non-zero
  expect(Period.betweenTimes(dt1.time, dt2.time).hasTimeComponent, isTrue);
}

@Test()
void HasDateComponent_Compound()
{
  LocalDateTime dt1 = new LocalDateTime.at(2000, 1, 1, 10, 45);
  LocalDateTime dt2 = new LocalDateTime.at(2000, 2, 4, 11, 50);

  // Case 1: Entire period is time-based (no date units available)
  expect(Period.betweenTimes(dt1.time, dt2.time).hasDateComponent, isFalse);

  // Case 2: Period contains date and time units, but date units are all zero
  expect(Period.between(dt1, dt1.date.at(dt2.time)).hasDateComponent, isFalse);

  // Case 3: Entire period is date-based, but 0. (Same local date twice here.)
  expect(Period.betweenDates(dt1.date, dt1.date).hasDateComponent, isFalse);

  // Case 4: Period contains date and time units, and some date units are non-zero
  expect(Period.between(dt1, dt2).hasDateComponent, isTrue);

  // Case 5: Entire period is date-based, and some time units are non-zero
  expect(Period.betweenDates(dt1.date, dt2.date).hasDateComponent, isTrue);
}

@Test()
void ToString_Positive()
{
  Period period = new Period.fromDays(1) +  new Period.fromHours(2);
  expect("P1DT2H", period.toString());
}

@Test()
void ToString_AllUnits()
{
  // Period({this.Years: 0, this.Months: 0, this.Weeks: 0, this.Days: 0,
  //    this.Hours: 0, this.Minutes: 0, this.Seconds: 0,
  //    this.Milliseconds: 0, this.Ticks: 0, this.Nanoseconds: 0});
  Period period = IPeriod.period(years: 1, months: 2, weeks: 3, days: 4,
      hours: 5, minutes: 6, seconds: 7, milliseconds: 8, ticks: 9, nanoseconds: 10);
  expect("P1Y2M3W4DT5H6M7S8s9t10n", period.toString());
}

@Test()
void ToString_Negative()
{
  Period period = new Period.fromDays(-1) + new Period.fromHours(-2);
  expect("P-1DT-2H", period.toString());
}

@Test()
void ToString_Mixed()
{
  Period period = new Period.fromDays(-1) + new Period.fromHours(2);
  expect("P-1DT2H", period.toString());
}

@Test()
void ToString_Zero()
{
  expect("P", Period.zero.toString());
}

@Test()
void ToBuilder_SingleUnit()
{
  var builder = new Period.fromHours(5).toBuilder();
  var expected = (new PeriodBuilder()..hours = 5).build();
expect(expected, builder.build());
}

@Test()
void ToBuilder_MultipleUnits()
{
  var builder = (new Period.fromHours(5) + new Period.fromWeeks(2)).toBuilder();
  var expected = (new PeriodBuilder()..hours = 5..weeks = 2).build();
expect(expected, builder.build());
}

@Test()
void Normalize_Weeks()
{
  var original = (new PeriodBuilder()..weeks = 2..days = 5).build();
var normalized = original.normalize();
var expected = (new PeriodBuilder()..days = 19).build();
expect(expected, normalized);
}

@Test()
void Normalize_Hours()
{
  var original = (new PeriodBuilder()..hours = 25..days = 1).build();
var normalized = original.normalize();
var expected = (new PeriodBuilder()..hours = 1..days = 2).build();
expect(expected, normalized);
}

@Test()
void Normalize_Minutes()
{
  var original = (new PeriodBuilder()..hours = 1..minutes = 150).build();
var normalized = original.normalize();
var expected = (new PeriodBuilder()..hours = 3..minutes = 30).build();
expect(expected, normalized);
}


@Test()
void Normalize_Seconds()
{
  var original = (new PeriodBuilder()..minutes = 1..seconds= 150).build();
var normalized = original.normalize();
var expected = (new PeriodBuilder()..minutes = 3..seconds= 30).build();
expect(expected, normalized);
}

@Test()
void Normalize_Milliseconds()
{
  var original = (new PeriodBuilder()..seconds = 1..milliseconds = 1500).build();
var normalized = original.normalize();
var expected = (new PeriodBuilder()..seconds = 2..milliseconds = 500).build();
expect(expected, normalized);
}

@Test()
void Normalize_Ticks()
{
  var original = (new PeriodBuilder()..milliseconds = 1..ticks = 15000).build();
var normalized = original.normalize();
var expected = (new PeriodBuilder()..milliseconds = 2..ticks = 0..nanoseconds = 500000).build();
expect(expected, normalized);
}

@Test()
void Normalize_Nanoseconds()
{
  var original = (new PeriodBuilder()..ticks = 1..nanoseconds = 150).build();
var normalized = original.normalize();
var expected = (new PeriodBuilder()..nanoseconds = 250).build();
expect(expected, normalized);
}

@Test()
void Normalize_MultipleFields()
{
  var original = (new PeriodBuilder()..hours = 1..minutes = 119..seconds= 150).build();
var normalized = original.normalize();
var expected = (new PeriodBuilder()..hours = 3..minutes = 1..seconds= 30).build();
expect(expected, normalized);
}

@Test()
void Normalize_AllNegative()
{
  var original = (new PeriodBuilder()..hours = -1..minutes = -119..seconds= -150).build();
var normalized = original.normalize();
var expected = (new PeriodBuilder()..hours = -3..minutes = -1..seconds= -30).build();
expect(expected, normalized);
}

@Test()
void Normalize_MixedSigns_PositiveResult()
{
  var original = (new PeriodBuilder()..hours = 3..minutes = -1).build();
  var normalized = original.normalize();
  var expected = (new PeriodBuilder()..hours = 2..minutes = 59).build();
expect(expected, normalized);
}

@Test()
void Normalize_MixedSigns_NegativeResult()
{
  var original = (new PeriodBuilder()..hours = 1..minutes = -121).build();
  var normalized = original.normalize();
  var expected = (new PeriodBuilder()..hours = -1..minutes = -1).build();
expect(expected, normalized);
}

@Test()
void Normalize_DoesntAffectMonthsAndYears()
{
  var original = (new PeriodBuilder()..years = 2..months = 1..days = 400).build();
expect(original, original.normalize());
}

@Test()
void Normalize_ZeroResult()
{
  var original = (new PeriodBuilder()..years = 0).build();
expect(Period.zero, original.normalize());
}

/* We don't overflow
@Test()
void Normalize_Overflow()
{
  Period period = new Period.fromHours(Utility.int64MaxValue);
  expect(() => period.Normalize(), throwsStateError);
}*/

@Test()
void ToString_SingleUnit()
{
  var period = new Period.fromHours(5);
  expect("PT5H", period.toString());
}

@Test()
void ToString_MultipleUnits()
{
  var period = (new PeriodBuilder()..hours = 5..minutes = 30).build();
expect("PT5H30M", period.toString());
}

@Test()
void ToDuration_InvalidWithYears()
{
  Period period = new Period.fromYears(1);
  expect(() => period.toSpan(), throwsStateError);
}

@Test()
void ToDuration_InvalidWithMonths()
{
  Period period = new Period.fromMonths(1);
  expect(() => period.toSpan(), throwsStateError);
}

@Test()
void ToDuration_ValidAllAcceptableUnits() {
  Period period = (new PeriodBuilder()

    ..weeks = 1
    ..days = 2
    ..hours = 3
    ..minutes = 4
    ..seconds = 5
    ..milliseconds = 6
    ..ticks = 7
  ).build();
  expect(
      1 * TimeConstants.ticksPerWeek +
          2 * TimeConstants.ticksPerDay +
          3 * TimeConstants.ticksPerHour +
          4 * TimeConstants.ticksPerMinute +
          5 * TimeConstants.ticksPerSecond +
          6 * TimeConstants.ticksPerMillisecond + 7,
      period
          .toSpan()
          .totalTicks); //.BclCompatibleTicks);
}

@Test()
void ToDuration_ValidWithZeroValuesInMonthYearUnits()
{
  Period period = new Period.fromMonths(1) + new Period.fromYears(1);
  period = period - period + new Period.fromDays(1);
  expect(period.hasTimeComponent, isFalse);
  expect(Span.oneDay, period.toSpan());
}

/* We don't overflow
@Test()
//[Category("Overflow")]
void ToDuration_Overflow()
{
  Period period = new Period.fromSeconds(Utility.int64MaxValue);
  expect(() => period.ToSpan(), throwsStateError);
}*/

//@Test()
////[Category("Overflow")]
//void ToDuration_Overflow_WhenPossiblyValid()
//{
//  // These two should pretty much cancel each other out - and would, if we had a 128-bit integer
//  // representation to use.
//  Period period = new Period.fromSeconds(Utility.int64MaxValue) + new Period.fromMinutes(Utility.int64MinValue ~/ 60);
//  expect(() => period.ToSpan(), throwsStateError);
//}

@Test()
void NormalizingEqualityComparer_NullToNonNull()
{
  Period period = new Period.fromYears(1);
  //expect(Period.NormalizingEqualityComparer.Instance.Equals(period, null), isFalse);
  //expect(Period.NormalizingEqualityComparer.Instance.Equals(null, period), isFalse);
  expect(NormalizingPeriodEqualityComparer.instance.equals(period, null), isFalse);
  expect(NormalizingPeriodEqualityComparer.instance.equals(null, period), isFalse);
}

@Test()
void NormalizingEqualityComparer_NullToNull()
{
  expect(NormalizingPeriodEqualityComparer.instance.equals(null, null), isTrue);
}

@Test()
void NormalizingEqualityComparer_PeriodToItself()
{
  Period period = new Period.fromYears(1);
  expect(NormalizingPeriodEqualityComparer.instance.equals(period, period), isTrue);
}

@Test()
void NormalizingEqualityComparer_NonEqualAfterNormalization()
{
  Period period1 = new Period.fromHours(2);
  Period period2 = new Period.fromMinutes(150);
  expect(NormalizingPeriodEqualityComparer.instance.equals(period1, period2), isFalse);
}

@Test()
void NormalizingEqualityComparer_EqualAfterNormalization()
{
  Period period1 = new Period.fromHours(2);
  Period period2 = new Period.fromMinutes(120);
  expect(NormalizingPeriodEqualityComparer.instance.equals(period1, period2), isTrue);
}

@Test()
void NormalizingEqualityComparer_GetHashCodeAfterNormalization()
{
  Period period1 = new Period.fromHours(2);
  Period period2 = new Period.fromMinutes(120);
  expect(NormalizingPeriodEqualityComparer.instance.getHashCode(period1),
      NormalizingPeriodEqualityComparer.instance.getHashCode(period2));
}

@Test()
void Comparer_NullWithNull()
{
  var comparer = Period.createComparer(new LocalDateTime.at(2000, 1, 1, 0, 0));
  expect(0, comparer.compare(null, null));
}

@Test()
void Comparer_NullWithNonNull()
{
  var comparer = Period.createComparer(new LocalDateTime.at(2000, 1, 1, 0, 0));
  expect(comparer.compare(null, Period.zero),  lessThan(0));
}

@Test()
void Comparer_NonNullWithNull()
{
  var comparer = Period.createComparer(new LocalDateTime.at(2000, 1, 1, 0, 0));
  expect(comparer.compare(Period.zero, null),  greaterThan(0));
}

@Test()
void Comparer_DurationablePeriods()
{
  var bigger = new Period.fromHours(25);
  var smaller = new Period.fromDays(1);
  var comparer = Period.createComparer(new LocalDateTime.at(2000, 1, 1, 0, 0));
  expect(comparer.compare(bigger, smaller),  greaterThan(0));
  expect(comparer.compare(smaller, bigger),  lessThan(0));
  expect(0, comparer.compare(bigger, bigger));
}

@Test()
void Comparer_NonDurationablePeriods()
{
  var month = new Period.fromMonths(1);
  var days = new Period.fromDays(30);
  // At the start of January, a month is longer than 30 days
  var januaryComparer = Period.createComparer(new LocalDateTime.at(2000, 1, 1, 0, 0));
  expect(januaryComparer.compare(month, days),  greaterThan(0));
  expect(januaryComparer.compare(days, month),  lessThan(0));
  expect(0, januaryComparer.compare(month, month));

  // At the start of February, a month is shorter than 30 days
  var februaryComparer = Period.createComparer(new LocalDateTime.at(2000, 2, 1, 0, 0));
  expect(februaryComparer.compare(month, days),  lessThan(0));
  expect(februaryComparer.compare(days, month),  greaterThan(0));
  expect(0, februaryComparer.compare(month, month));
}

@Test()
// [TestCaseSource(nameof(AllPeriodUnits))]
@TestCaseSource(const Symbol('AllPeriodUnits'))
void Between_ExtremeValues(PeriodUnits units)
{
  // We can't use None, and Nanoseconds will *correctly* overflow.
  if (units == PeriodUnits.none || units == PeriodUnits.nanoseconds)
  {
    return;
  }
  var minValue = LocalDate.minIsoValue.at(LocalTime.minValue);
  var maxValue = LocalDate.maxIsoValue.at(LocalTime.maxValue);
  Period.between(minValue, maxValue, units);
}

@Test()
void Between_ExtremeValues_Overflow()
{
  var minValue = LocalDate.minIsoValue.at(LocalTime.minValue);
  var maxValue = LocalDate.maxIsoValue.at(LocalTime.maxValue);
  expect(() => Period.between(minValue, maxValue, PeriodUnits.nanoseconds), throwsRangeError); // throwsStateError);
}

@Test()
@TestCase(const ["2015-02-28T16:00:00", "2016-02-29T08:00:00", PeriodUnits.years, 1, 0])
@TestCase(const ["2015-02-28T16:00:00", "2016-02-29T08:00:00", PeriodUnits.months, 12, -11])
@TestCase(const ["2014-01-01T16:00:00", "2014-01-03T08:00:00", PeriodUnits.days, 1, -1])
@TestCase(const ["2014-01-01T16:00:00", "2014-01-03T08:00:00", PeriodUnits.hours, 40, -40])
void Between_LocalDateTime_AwkwardTimeOfDayWithSingleUnit(String startText, String endText, PeriodUnits units, int expectedForward, int expectedBackward)
{
  LocalDateTime start = LocalDateTimePattern.extendedIso.parse(startText).value;
  LocalDateTime end = LocalDateTimePattern.extendedIso.parse(endText).value;
  Period forward = Period.between(start, end, units);
  expect(expectedForward, forward.toBuilder()[units]);
  Period backward = Period.between(end, start, units);
  expect(expectedBackward, backward.toBuilder()[units]);
}

@Test()
void Between_LocalDateTime_SameValue()
{
  LocalDateTime start = new LocalDateTime.at(2014, 1, 1, 16, 0);
  expect(Period.zero, Period.between(start, start));
}

@Test()
void Between_LocalDateTime_AwkwardTimeOfDayWithMultipleUnits()
{
  LocalDateTime start = new LocalDateTime.at(2014, 1, 1, 16, 0);
  LocalDateTime end = new LocalDateTime.at(2015, 2, 3, 8, 0);
  Period actual = Period.between(start, end, PeriodUnits.yearMonthDay | PeriodUnits.allTimeUnits);
  Period expected = (new PeriodBuilder()..years = 1..months = 1..days = 1..hours = 16).build();
expect(expected, actual);
}

/*
@Test()
void BinaryRoundTrip()
{
  TestHelper.AssertBinaryRoundtrip(Period.Zero);
  // Check each field is distinct
  TestHelper.AssertBinaryRoundtrip(new Period(1, 2, 3, 4, 5L, 6L, 7L, 8L, 9L, 10L));
  // Check we're not truncating to Int32... (except for date values)
  TestHelper.AssertBinaryRoundtrip(new Period(Utility.int32MaxValue, Utility.int32MaxValue, Utility.int32MinValue, Utility.int32MinValue, Utility.int64MaxValue,
      Utility.int64MinValue, Utility.int64MinValue, Utility.int64MinValue, Utility.int64MinValue,
      Utility.int64MinValue));
}
*/

@Test()
void FromNanoseconds()
{
  var period = new Period.fromNanoseconds(1234567890);
  expect(1234567890, period.nanoseconds);
}

@Test()
void AddPeriodToPeriod_NoOverflow()
{
  Period p1 = new Period.fromHours(Platform.int64MaxValue);
  Period p2 = new Period.fromMinutes(60);
  expect((new PeriodBuilder()..hours = Platform.int64MaxValue..minutes = 60).build(), p1 + p2);
}

/* We don't overflow
@Test()
void AddPeriodToPeriod_Overflow()
{
  Period p1 = new Period.fromHours(Utility.int64MaxValue);
  Period p2 = new Period.fromHours(1);
  expect(() => (p1 + p2).hashCode, throwsStateError);
}*/

/// Just a simple way of parsing a period string. It's a more compact period representation.
Period Parse(String text)
{
  return PeriodPattern.roundtrip.parse(text).value;
}

