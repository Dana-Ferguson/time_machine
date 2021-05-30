// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

// June 19th 2010, 2:30:15am
final LocalDateTime TestDateTime1 = LocalDateTime(2010, 6, 19, 2, 30, 15);
// June 19th 2010, 4:45:10am
final LocalDateTime TestDateTime2 = LocalDateTime(2010, 6, 19, 4, 45, 10);
// June 19th 2010
final LocalDate TestDate1 = LocalDate(2010, 6, 19);
// March 1st 2011
final LocalDate TestDate2 = LocalDate(2011, 3, 1);
// March 1st 2012
final LocalDate TestDate3 = LocalDate(2012, 3, 1);

final PeriodUnits HoursMinutesPeriodType = PeriodUnits.hours | PeriodUnits.minutes;

final List<PeriodUnits> AllPeriodUnits = PeriodUnits.values;

@Test()
void BetweenLocalDateTimes_WithoutSpecifyingUnits_OmitsWeeks()
{
  Period actual = Period.differenceBetweenDateTime(LocalDateTime(2012, 2, 21, 0, 0, 0), LocalDateTime(2012, 2, 28, 0, 0, 0));
  Period expected = const Period(days: 7);
  expect(expected, actual);
}

@Test()
void BetweenLocalDateTimes_MovingForwardWithAllFields_GivesExactResult()
{
  Period actual = Period.differenceBetweenDateTime(TestDateTime1, TestDateTime2);
  Period expected = const Period(hours: 2) + const Period(minutes: 14) + const Period(seconds: 55);
  expect(expected, actual);
}

@Test()
void BetweenLocalDateTimes_MovingBackwardWithAllFields_GivesExactResult()
{
  Period actual = Period.differenceBetweenDateTime(TestDateTime2, TestDateTime1);
  Period expected = const Period(hours: -2) + const Period(minutes: -14) + const Period(seconds: -55);
  expect(expected, actual);
}

@Test()
void BetweenLocalDateTimes_MovingForwardWithHoursAndMinutes_RoundsTowardsStart()
{
  Period actual = Period.differenceBetweenDateTime(TestDateTime1, TestDateTime2, HoursMinutesPeriodType);
  Period expected = const Period(hours: 2) + const Period(minutes: 14);
  expect(expected, actual);
}

@Test()
void BetweenLocalDateTimes_MovingBackwardWithHoursAndMinutes_RoundsTowardsStart()
{
  Period actual = Period.differenceBetweenDateTime(TestDateTime2, TestDateTime1, HoursMinutesPeriodType);
  Period expected = const Period(hours: -2) + const Period(minutes: -14);
  expect(expected, actual);
}

@Test()
void BetweenLocalDateTimes_AcrossDays()
{
  Period expected = const Period(hours: 23) + const Period(minutes: 59);
  Period actual = Period.differenceBetweenDateTime(TestDateTime1, TestDateTime1.addDays(1).addMinutes(-1));
  expect(expected, actual);
}

@Test()
void BetweenLocalDateTimes_AcrossDays_MinutesAndSeconds()
{
  Period expected = const Period(minutes: 24 * 60 - 1) + const Period(seconds: 59);
  Period actual = Period.differenceBetweenDateTime(TestDateTime1, TestDateTime1.addDays(1).addSeconds(-1), PeriodUnits.minutes | PeriodUnits.seconds);
  expect(expected, actual);
}

@Test()
void BetweenLocalDateTimes_NotInt64Representable() {
  LocalDateTime start = LocalDateTime(-5000, 1, 1, 0, 1, 2, ms: 123);
  LocalDateTime end = LocalDateTime(9000, 1, 1, 1, 2, 3, ms: 456);
  expect((ILocalDateTime.toLocalInstant(end).timeSinceLocalEpoch
          - ILocalDateTime.toLocalInstant(start).timeSinceLocalEpoch).canNanosecondsBeInteger, isFalse);

  Period expected = (PeriodBuilder()
    // 365.2425 * 14000 = 5113395
    ..hours = 5113395 * 24 + 1
    ..minutes = 1
    ..seconds = 1
    ..milliseconds = 333
  ).build();

  Period actual = Period.differenceBetweenDateTime(start, end, PeriodUnits.allTimeUnits);
  expect(actual, expected);
}

@Test()
void BetweenLocalDates_InvalidUnits()
{
  expect(() => Period.differenceBetweenDates(TestDate1, TestDate2, const PeriodUnits(0)), throwsArgumentError);
  expect(() => Period.differenceBetweenDates(TestDate1, TestDate2, const PeriodUnits(-1)), throwsArgumentError);
  expect(() => Period.differenceBetweenDates(TestDate1, TestDate2, PeriodUnits.allTimeUnits), throwsArgumentError);
  expect(() => Period.differenceBetweenDates(TestDate1, TestDate2, PeriodUnits.years | PeriodUnits.hours), throwsArgumentError);
}

@Test()
void BetweenLocalDates_DifferentCalendarSystems_Throws()
{
  LocalDate start = LocalDate(2017, 11, 1, CalendarSystem.coptic);
  LocalDate end = LocalDate(2017, 11, 5, CalendarSystem.gregorian);
  expect(() => Period.differenceBetweenDates(start, end), throwsArgumentError);
}

@Test()
@TestCase(['2016-05-16', "2019-03-13", PeriodUnits.years, 2])
@TestCase(['2016-05-16', "2017-07-13", PeriodUnits.months, 13])
@TestCase(['2016-05-16', "2016-07-13", PeriodUnits.weeks, 8])
@TestCase(['2016-05-16', "2016-07-13", PeriodUnits.days, 58])
void BetweenLocalDates_SingleUnit(String startText, String endText, PeriodUnits units, int expectedValue)
{
  var start = LocalDatePattern.iso.parse(startText).value;
  var end = LocalDatePattern.iso.parse(endText).value;
  var actual = Period.differenceBetweenDates(start, end, units);
  var expected = (PeriodBuilder()..[units] = expectedValue).build();
expect(expected, actual);
}

@Test()
void BetweenLocalDates_MovingForwardNoLeapYears_WithExactResults()
{
  Period actual = Period.differenceBetweenDates(TestDate1, TestDate2);
  Period expected = const Period(months: 8) + const Period(days: 10);
  expect(expected, actual);
}

@Test()
void BetweenLocalDates_MovingForwardInLeapYear_WithExactResults()
{
  Period actual = Period.differenceBetweenDates(TestDate1, TestDate3);
  Period expected = const Period(years: 1) + const Period(months: 8) + const Period(days: 11);
  expect(expected, actual);
}

@Test()
void BetweenLocalDates_MovingBackwardNoLeapYears_WithExactResults()
{
  Period actual = Period.differenceBetweenDates(TestDate2, TestDate1);
  Period expected = const Period(months: -8) + const Period(days: -12);
  expect(expected, actual);
}

@Test()
void BetweenLocalDates_MovingBackwardInLeapYear_WithExactResults()
{
  // This is asymmetric with moving forward, because we first take off a whole year, which
  // takes us to March 1st 2011, then 8 months to take us to July 1st 2010, then 12 days
  // to take us back to June 19th. In this case, the fact that our start date is in a leap
  // year had no effect.
  Period actual = Period.differenceBetweenDates(TestDate3, TestDate1);
  Period expected = const Period(years: -1) + const Period(months: -8) + const Period(days: -12);
  expect(expected, actual);
}

@Test()
void BetweenLocalDates_MovingForward_WithJustMonths()
{
  Period actual = Period.differenceBetweenDates(TestDate1, TestDate3, PeriodUnits.months);
  Period expected = const Period(months: 20);
  expect(expected, actual);
}

@Test()
void BetweenLocalDates_MovingBackward_WithJustMonths()
{
  Period actual = Period.differenceBetweenDates(TestDate3, TestDate1, PeriodUnits.months);
  Period expected = const Period(months: -20);
  expect(expected, actual);
}

@Test()
void BetweenLocalDates_AssymetricForwardAndBackward()
{
  // February 10th 2010
  LocalDate d1 = LocalDate(2010, 2, 10);
  // March 30th 2010
  LocalDate d2 = LocalDate(2010, 3, 30);
  // Going forward, we go to March 10th (1 month) then March 30th (20 days)
  expect(const Period(months: 1) + const Period(days: 20), Period.differenceBetweenDates(d1, d2));
  // Going backward, we go to February 28th (-1 month, day is rounded) then February 10th (-18 days)
  expect(const Period(months: -1) + const Period(days: -18), Period.differenceBetweenDates(d2, d1));
}

@Test()
void BetweenLocalDates_EndOfMonth()
{
  LocalDate d1 = LocalDate(2013, 3, 31);
  LocalDate d2 = LocalDate(2013, 4, 30);
  expect(const Period(months: 1), Period.differenceBetweenDates(d1, d2));
  expect(const Period(days: -30), Period.differenceBetweenDates(d2, d1));
}

@Test()
void BetweenLocalDates_OnLeapYear()
{
  LocalDate d1 = LocalDate(2012, 2, 29);
  LocalDate d2 = LocalDate(2013, 2, 28);
  expect(const Period(years: 1), Period.differenceBetweenDates(d1, d2));
  // Go back from February 28th 2013 to March 28th 2012, then back 28 days to February 29th 2012
  expect(const Period(months: -11) + const Period(days: -28), Period.differenceBetweenDates(d2, d1));
}

@Test()
void BetweenLocalDates_AfterLeapYear()
{
  LocalDate d1 = LocalDate(2012, 3, 5);
  LocalDate d2 = LocalDate(2013, 3, 5);
  expect(const Period(years: 1), Period.differenceBetweenDates(d1, d2));
  expect(const Period(years: -1), Period.differenceBetweenDates(d2, d1));
}

@Test()
void BetweenLocalDateTimes_OnLeapYear()
{
  LocalDateTime dt1 = LocalDateTime(2012, 2, 29, 2, 0, 0);
  LocalDateTime dt2 = LocalDateTime(2012, 2, 29, 4, 0, 0);
  LocalDateTime dt3 = LocalDateTime(2013, 2, 28, 3, 0, 0);
  expect(Parse('P1YT1H'), Period.differenceBetweenDateTime(dt1, dt3));
  expect(Parse('P11M29DT23H'), Period.differenceBetweenDateTime(dt2, dt3));

  expect(Parse('P-11M-28DT-1H'), Period.differenceBetweenDateTime(dt3, dt1));
  expect(Parse('P-11M-27DT-23H'), Period.differenceBetweenDateTime(dt3, dt2));
}

@Test()
void BetweenLocalDateTimes_OnLeapYearIslamic()
{
  var calendar = CalendarSystem.getIslamicCalendar(IslamicLeapYearPattern.base15, IslamicEpoch.civil);
  expect(calendar.isLeapYear(2), isTrue);
  expect(calendar.isLeapYear(3), isFalse);

  LocalDateTime dt1 = LocalDateTime(2, 12, 30, 2, 0, 0, calendar: calendar);
  LocalDateTime dt2 = LocalDateTime(2, 12, 30, 4, 0, 0, calendar: calendar);
  LocalDateTime dt3 = LocalDateTime(3, 12, 29, 3, 0, 0, calendar: calendar);

  // Adding a year truncates to 0003-12-28T02:00:00, then add an hour.
  expect(Parse('P1YT1H'), Period.differenceBetweenDateTime(dt1, dt3));
  // Adding a year would overshoot. Adding 11 months takes us to month 03-11-30T04:00.
  // Adding another 28 days takes us to 03-12-28T04:00, then add another 23 hours to finish.
  expect(Parse('P11M28DT23H'), Period.differenceBetweenDateTime(dt2, dt3));

  // Subtracting 11 months takes us to 03-01-29T03:00. Subtracting another 29 days
  // takes us to 02-12-30T03:00, and another hour to get to the target.
  expect(Parse('P-11M-29DT-1H'), Period.differenceBetweenDateTime(dt3, dt1));
  expect(Parse('P-11M-28DT-23H'), Period.differenceBetweenDateTime(dt3, dt2));
}

@Test()
void BetweenLocalDateTimes_InvalidUnits()
{
  expect(() => Period.differenceBetweenDates(TestDate1, TestDate2, const PeriodUnits(0)), throwsArgumentError);
  expect(() => Period.differenceBetweenDates(TestDate1, TestDate2, const PeriodUnits(-1)), throwsArgumentError);
}

@Test()
void BetweenLocalTimes_InvalidUnits()
{
  LocalTime t1 = LocalTime(10, 0, 0);
  LocalTime t2 = LocalTime(15, 30, 45, ns: 20 * TimeConstants.nanosecondsPerMillisecond + 5 * 100);
  expect(() => Period.differenceBetweenTimes(t1, t2, const PeriodUnits(0)), throwsArgumentError);
  expect(() => Period.differenceBetweenTimes(t1, t2, const PeriodUnits(-1)), throwsArgumentError);
  expect(() => Period.differenceBetweenTimes(t1, t2, PeriodUnits.yearMonthDay), throwsArgumentError);
  expect(() => Period.differenceBetweenTimes(t1, t2, PeriodUnits.years | PeriodUnits.hours), throwsArgumentError);
}

@Test()
@TestCase(['01:02:03', "05:00:00", PeriodUnits.hours, 3])
@TestCase(['01:02:03', "03:00:00", PeriodUnits.minutes, 117])
@TestCase(['01:02:03', "01:05:02", PeriodUnits.seconds, 179])
@TestCase(['01:02:03', "01:02:04.1234", PeriodUnits.milliseconds, 1123])
@TestCase(['01:02:03', "01:02:04.1234", PeriodUnits.microseconds, 1123400])
@TestCase(['01:02:03', "01:02:04.1234", PeriodUnits.nanoseconds,  1123400000])
void BetweenLocalTimes_SingleUnit(String startText, String endText, PeriodUnits units, int expectedValue) {
  var start = LocalTimePattern.extendedIso
      .parse(startText)
      .value;
  var end = LocalTimePattern.extendedIso
      .parse(endText)
      .value;
  var actual = Period.differenceBetweenTimes(start, end, units);
  var expected = (PeriodBuilder()
    ..[units] = expectedValue).build();
  expect(expected, actual);
}

@Test()
void BetweenLocalTimes_MovingForwards()
{
  // todo: this test and the MovingBackwards() test, originally tested Period.fromTicks() -- rewrite it for .fromMicroseconds()?
  LocalTime t1 = LocalTime(10, 0, 0);
  LocalTime t2 = LocalTime(15, 30, 45, ns: 20 * TimeConstants.nanosecondsPerMillisecond + 5 * 100);
  expect(const Period(hours: 5) + const Period(minutes: 30) + const Period(seconds: 45) +
      const Period(milliseconds: 20) + const Period(nanoseconds: 500),
      Period.differenceBetweenTimes(t1, t2));
}

@Test()
void BetweenLocalTimes_MovingBackwards()
{
  LocalTime t1 = LocalTime(15, 30, 45, ns: 20 * TimeConstants.nanosecondsPerMillisecond + 5 * 100);
  LocalTime t2 = LocalTime(10, 0, 0);
  expect(const Period(hours: -5) + const Period(minutes: -30) + const Period(seconds: -45) +
      const Period(milliseconds: -20) + const Period(nanoseconds: -500),
      Period.differenceBetweenTimes(t1, t2));
}

@Test()
void BetweenLocalTimes_MovingForwards_WithJustHours()
{
  LocalTime t1 = LocalTime(11, 30, 0);
  LocalTime t2 = LocalTime(17, 15, 0);
  expect(const Period(hours: 5), Period.differenceBetweenTimes(t1, t2, PeriodUnits.hours));
}

@Test()
void BetweenLocalTimes_MovingBackwards_WithJustHours()
{
  LocalTime t1 = LocalTime(17, 15, 0);
  LocalTime t2 = LocalTime(11, 30, 0);
  expect(const Period(hours: -5), Period.differenceBetweenTimes(t1, t2, PeriodUnits.hours));
}

@Test()
void Addition_WithDifferent_PeriodTypes()
{
  Period p1 = const Period(hours: 3);
  Period p2 = const Period(minutes: 20);
  Period sum = p1 + p2;
  expect(3, sum.hours);
  expect(20, sum.minutes);
}

@Test()
void Addition_With_IdenticalPeriodTypes()
{
  Period p1 = const Period(hours: 3);
  Period p2 = const Period(hours: 2);
  Period sum = p1 + p2;
  expect(5, sum.hours);
}

@Test()
void Addition_DayCrossingMonthBoundary()
{
  LocalDateTime start = LocalDateTime(2010, 2, 20, 10, 0, 0);
  LocalDateTime result = start + const Period(days: 10);
  expect(LocalDateTime(2010, 3, 2, 10, 0, 0), result);
}

@Test()
void Addition_OneYearOnLeapDay()
{
  LocalDateTime start = LocalDateTime(2012, 2, 29, 10, 0, 0);
  LocalDateTime result = start + const Period(years: 1);
  // Feb 29th becomes Feb 28th
  expect(LocalDateTime(2013, 2, 28, 10, 0, 0), result);
}

@Test()
void Addition_FourYearsOnLeapDay()
{
  LocalDateTime start = LocalDateTime(2012, 2, 29, 10, 0, 0);
  LocalDateTime result = start + const Period(years: 4);
  // Feb 29th is still valid in 2016
  expect(LocalDateTime(2016, 2, 29, 10, 0, 0), result);
}

@Test()
void Addition_YearMonthDay()
{
  // One year, one month, two days
  Period period = const Period(years: 1) + const Period(months: 1) + const Period(days: 2);
  LocalDateTime start = LocalDateTime(2007, 1, 30, 0, 0, 0);
  // Periods are added in order, so this becomes...
  // Add one year: Jan 30th 2008
  // Add one month: Feb 29th 2008
  // Add two days: March 2nd 2008
  // If we added the days first, we'd end up with March 1st instead.
  LocalDateTime result = start + period;
  expect(LocalDateTime(2008, 3, 2, 0, 0, 0), result);
}

@Test()
void Subtraction_WithDifferent_PeriodTypes()
{
  Period p1 = const Period(hours: 3);
  Period p2 = const Period(minutes: 20);
  Period sum = p1 - p2;
  expect(3, sum.hours);
  expect(-20, sum.minutes);
}

@Test()
void Subtraction_With_IdenticalPeriodTypes()
{
  Period p1 = const Period(hours: 3);
  Period p2 = const Period(hours: 2);
  Period sum = p1 - p2;
  expect(1, sum.hours);
}

@Test()
void Equality_WhenEqual()
{
  expect(const Period(hours: 10), const Period(hours: 10));
  expect(const Period(minutes: 15), const Period(minutes: 15));
  expect(const Period(days: 5), const Period(days: 5));
}

@Test()
void Equality_WithDifferentPeriodTypes_OnlyConsidersValues()
{
  Period allFields = const Period(minutes: 1) + const Period(hours: 1) - const Period(minutes: 1);
  Period justHours = const Period(hours: 1);
  expect(allFields, justHours);
}

@Test()
void Equality_WhenUnequal()
{
  expect(const Period(hours: 10).equals(const Period(hours: 20)), isFalse);
  expect(const Period(minutes: 15).equals(const Period(seconds: 15)), isFalse);
  expect(const Period(hours: 1).equals(const Period(minutes: 60)), isFalse);
}

@Test()
@TestCase([PeriodUnits.years, false])
@TestCase([PeriodUnits.weeks, false])
@TestCase([PeriodUnits.months, false])
@TestCase([PeriodUnits.days, false])
@TestCase([PeriodUnits.hours, true])
@TestCase([PeriodUnits.minutes, true])
@TestCase([PeriodUnits.seconds, true])
@TestCase([PeriodUnits.milliseconds, true])
@TestCase([PeriodUnits.microseconds, true])
@TestCase([PeriodUnits.nanoseconds, true])
void HasTimeComponent_SingleValued(PeriodUnits unit, bool hasTimeComponent) {
  var period = (PeriodBuilder()
    ..[unit] = 1).build();
  expect(hasTimeComponent, period.hasTimeComponent);
}

@Test()
@TestCase([PeriodUnits.years, true])
@TestCase([PeriodUnits.weeks, true])
@TestCase([PeriodUnits.months, true])
@TestCase([PeriodUnits.days, true])
@TestCase([PeriodUnits.hours, false])
@TestCase([PeriodUnits.minutes, false])
@TestCase([PeriodUnits.seconds, false])
@TestCase([PeriodUnits.milliseconds, false])
@TestCase([PeriodUnits.microseconds, false])
@TestCase([PeriodUnits.nanoseconds, false])
void HasDateComponent_SingleValued(PeriodUnits unit, bool hasDateComponent)
{
  var period = (PeriodBuilder()..[unit] = 1).build();
expect(hasDateComponent, period.hasDateComponent);
}

@Test()
void HasTimeComponent_Compound()
{
  LocalDateTime dt1 = LocalDateTime(2000, 1, 1, 10, 45, 0);
  LocalDateTime dt2 = LocalDateTime(2000, 2, 4, 11, 50, 0);

  // Case 1: Entire period is date-based (no time units available)
  expect(Period.differenceBetweenDates(dt1.calendarDate, dt2.calendarDate).hasTimeComponent, isFalse);

  // Case 2: Period contains date and time units, but time units are all zero
  expect(Period.differenceBetweenDateTime(dt1.calendarDate.at(LocalTime.midnight), dt2.calendarDate.at(LocalTime.midnight)).hasTimeComponent, isFalse);

  // Case 3: Entire period is time-based, but 0. (Same local time twice here.)
  expect(Period.differenceBetweenTimes(dt1.clockTime, dt1.clockTime).hasTimeComponent, isFalse);

  // Case 4: Period contains date and time units, and some time units are non-zero
  expect(Period.differenceBetweenDateTime(dt1, dt2).hasTimeComponent, isTrue);

  // Case 5: Entire period is time-based, and some time units are non-zero
  expect(Period.differenceBetweenTimes(dt1.clockTime, dt2.clockTime).hasTimeComponent, isTrue);
}

@Test()
void HasDateComponent_Compound()
{
  LocalDateTime dt1 = LocalDateTime(2000, 1, 1, 10, 45, 0);
  LocalDateTime dt2 = LocalDateTime(2000, 2, 4, 11, 50, 0);

  // Case 1: Entire period is time-based (no date units available)
  expect(Period.differenceBetweenTimes(dt1.clockTime, dt2.clockTime).hasDateComponent, isFalse);

  // Case 2: Period contains date and time units, but date units are all zero
  expect(Period.differenceBetweenDateTime(dt1, dt1.calendarDate.at(dt2.clockTime)).hasDateComponent, isFalse);

  // Case 3: Entire period is date-based, but 0. (Same local date twice here.)
  expect(Period.differenceBetweenDates(dt1.calendarDate, dt1.calendarDate).hasDateComponent, isFalse);

  // Case 4: Period contains date and time units, and some date units are non-zero
  expect(Period.differenceBetweenDateTime(dt1, dt2).hasDateComponent, isTrue);

  // Case 5: Entire period is date-based, and some time units are non-zero
  expect(Period.differenceBetweenDates(dt1.calendarDate, dt2.calendarDate).hasDateComponent, isTrue);
}

@Test()
void ToString_Positive()
{
  Period period = const Period(days: 1) +  const Period(hours: 2);
  expect('P1DT2H', period.toString());
}

@Test()
void ToString_AllUnits()
{
  // Period({this.Years: 0, this.Months: 0, this.Weeks: 0, this.Days: 0,
  //    this.Hours: 0, this.Minutes: 0, this.Seconds: 0,
  //    this.Milliseconds: 0, this.Ticks: 0, this.Nanoseconds: 0});
  Period period = IPeriod.period(years: 1, months: 2, weeks: 3, days: 4,
      hours: 5, minutes: 6, seconds: 7, milliseconds: 8, microseconds: 9, nanoseconds: 10);
  expect('P1Y2M3W4DT5H6M7S8s9t10n', period.toString());
}

@Test()
void ToString_Negative()
{
  Period period = const Period(days: -1) + const Period(hours: -2);
  expect('P-1DT-2H', period.toString());
}

@Test()
void ToString_Mixed()
{
  Period period = const Period(days: -1) + const Period(hours: 2);
  expect('P-1DT2H', period.toString());
}

@Test()
void ToString_Zero()
{
  expect('P', Period.zero.toString());
}

@Test()
void ToBuilder_SingleUnit()
{
  var builder = const Period(hours: 5).toBuilder();
  var expected = (PeriodBuilder()..hours = 5).build();
  expect(expected, builder.build());
}

@Test()
void ToBuilder_MultipleUnits()
{
  var builder = (const Period(hours: 5) + const Period(weeks: 2)).toBuilder();
  var expected = (PeriodBuilder()..hours = 5..weeks = 2).build();
  expect(expected, builder.build());
}

@Test()
void Normalize_Weeks()
{
  var original = (PeriodBuilder()..weeks = 2..days = 5).build();
  var normalized = original.normalize();
  var expected = (PeriodBuilder()..days = 19).build();
  expect(expected, normalized);
}

@Test()
void Normalize_Hours()
{
  var original = (PeriodBuilder()..hours = 25..days = 1).build();
  var normalized = original.normalize();
  var expected = (PeriodBuilder()..hours = 1..days = 2).build();
  expect(expected, normalized);
}

@Test()
void Normalize_Minutes()
{
  var original = (PeriodBuilder()..hours = 1..minutes = 150).build();
  var normalized = original.normalize();
  var expected = (PeriodBuilder()..hours = 3..minutes = 30).build();
  expect(expected, normalized);
}


@Test()
void Normalize_Seconds()
{
  var original = (PeriodBuilder()..minutes = 1..seconds= 150).build();
  var normalized = original.normalize();
  var expected = (PeriodBuilder()..minutes = 3..seconds= 30).build();
  expect(expected, normalized);
}

@Test()
void Normalize_Milliseconds()
{
  var original = (PeriodBuilder()..seconds = 1..milliseconds = 1500).build();
  var normalized = original.normalize();
  var expected = (PeriodBuilder()..seconds = 2..milliseconds = 500).build();
  expect(expected, normalized);
}

@Test()
void Normalize_Microseconds()
{
  var original = (PeriodBuilder()..milliseconds = 1..microseconds = 1500).build();
  var normalized = original.normalize();
  var expected = (PeriodBuilder()..milliseconds = 2..microseconds = 0..nanoseconds = 500000).build();
  expect(expected, normalized);
}

@Test()
void Normalize_Nanoseconds()
{
  var original = (PeriodBuilder()..microseconds = 1..nanoseconds = 1500).build();
  var normalized = original.normalize();
  var expected = (PeriodBuilder()..nanoseconds = 2500).build();
  expect(expected, normalized);
}

@Test()
void Normalize_MultipleFields()
{
  var original = (PeriodBuilder()..hours = 1..minutes = 119..seconds= 150).build();
  var normalized = original.normalize();
  var expected = (PeriodBuilder()..hours = 3..minutes = 1..seconds= 30).build();
  expect(expected, normalized);
}

@Test()
void Normalize_AllNegative()
{
  var original = (PeriodBuilder()..hours = -1..minutes = -119..seconds= -150).build();
  var normalized = original.normalize();
  var expected = (PeriodBuilder()..hours = -3..minutes = -1..seconds= -30).build();
  expect(expected, normalized);
}

@Test()
void Normalize_MixedSigns_PositiveResult()
{
  var original = (PeriodBuilder()..hours = 3..minutes = -1).build();
  var normalized = original.normalize();
  var expected = (PeriodBuilder()..hours = 2..minutes = 59).build();
expect(expected, normalized);
}

@Test()
void Normalize_MixedSigns_NegativeResult()
{
  var original = (PeriodBuilder()..hours = 1..minutes = -121).build();
  var normalized = original.normalize();
  var expected = (PeriodBuilder()..hours = -1..minutes = -1).build();
expect(expected, normalized);
}

@Test()
void Normalize_DoesntAffectMonthsAndYears()
{
  var original = (PeriodBuilder()..years = 2..months = 1..days = 400).build();
expect(original, original.normalize());
}

@Test()
void Normalize_ZeroResult()
{
  var original = (PeriodBuilder()..years = 0).build();
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
  var period = const Period(hours: 5);
  expect('PT5H', period.toString());
}

@Test()
void ToString_MultipleUnits()
{
  var period = (PeriodBuilder()..hours = 5..minutes = 30).build();
expect('PT5H30M', period.toString());
}

@Test()
void ToDuration_InvalidWithYears()
{
  Period period = const Period(years: 1);
  expect(() => period.toTime(), throwsStateError);
}

@Test()
void ToDuration_InvalidWithMonths()
{
  Period period = const Period(months: 1);
  expect(() => period.toTime(), throwsStateError);
}

@Test()
void ToDuration_ValidAllAcceptableUnits() {
  Period period = (PeriodBuilder()
    ..weeks = 1
    ..days = 2
    ..hours = 3
    ..minutes = 4
    ..seconds = 5
    ..milliseconds = 6
    ..microseconds = 7
  ).build();
  expect(
      1 * TimeConstants.microsecondsPerWeek +
          2 * TimeConstants.microsecondsPerDay +
          3 * TimeConstants.microsecondsPerHour +
          4 * TimeConstants.microsecondsPerMinute +
          5 * TimeConstants.microsecondsPerSecond +
          6 * TimeConstants.microsecondsPerMillisecond + 7,
      period
          .toTime()
          .totalMicroseconds);
}

@Test()
void ToDuration_ValidWithZeroValuesInMonthYearUnits()
{
  Period period = const Period(months: 1) + const Period(years: 1);
  period = period - period + const Period(days: 1);
  expect(period.hasTimeComponent, isFalse);
  expect(Time.oneDay, period.toTime());
}

/* We don't overflow
@Test()
//[Category('Overflow')]
void ToDuration_Overflow()
{
  Period period = new Period.fromSeconds(Utility.int64MaxValue);
  expect(() => period.ToSpan(), throwsStateError);
}*/

//@Test()
////[Category('Overflow')]
//void ToDuration_Overflow_WhenPossiblyValid()
//{
//  // These two should pretty much cancel each other out - and would, if we had a 128-bit integer
//  // representation to use.
//  Period period = new Period.fromSeconds(Utility.int64MaxValue) + new Period.fromMinutes(Utility.int64MinValue ~/ 60);
//  expect(() => period.ToSpan(), throwsStateError);
//}

@Test()
void NormalizingEqualityComparer_PeriodToItself()
{
  Period period = const Period(years: 1);
  expect(NormalizingPeriodEqualityComparer.instance.equals(period, period), isTrue);
}

@Test()
void NormalizingEqualityComparer_NonEqualAfterNormalization()
{
  Period period1 = const Period(hours: 2);
  Period period2 = const Period(minutes: 150);
  expect(NormalizingPeriodEqualityComparer.instance.equals(period1, period2), isFalse);
}

@Test()
void NormalizingEqualityComparer_EqualAfterNormalization()
{
  Period period1 = const Period(hours: 2);
  Period period2 = const Period(minutes: 120);
  expect(NormalizingPeriodEqualityComparer.instance.equals(period1, period2), isTrue);
}

@Test()
void NormalizingEqualityComparer_GetHashCodeAfterNormalization()
{
  Period period1 = const Period(hours: 2);
  Period period2 = const Period(minutes: 120);
  expect(NormalizingPeriodEqualityComparer.instance.getHashCode(period1),
      NormalizingPeriodEqualityComparer.instance.getHashCode(period2));
}

@Test()
void Comparer_NullWithNull()
{
  var comparer = Period.createComparer(LocalDateTime(2000, 1, 1, 0, 0, 0));
  expect(0, comparer.compare(null, null));
}

@Test()
void Comparer_NullWithNonNull()
{
  var comparer = Period.createComparer(LocalDateTime(2000, 1, 1, 0, 0, 0));
  expect(comparer.compare(null, Period.zero),  lessThan(0));
}

@Test()
void Comparer_NonNullWithNull()
{
  var comparer = Period.createComparer(LocalDateTime(2000, 1, 1, 0, 0, 0));
  expect(comparer.compare(Period.zero, null),  greaterThan(0));
}

@Test()
void Comparer_DurationablePeriods()
{
  var bigger = const Period(hours: 25);
  var smaller = const Period(days: 1);
  var comparer = Period.createComparer(LocalDateTime(2000, 1, 1, 0, 0, 0));
  expect(comparer.compare(bigger, smaller),  greaterThan(0));
  expect(comparer.compare(smaller, bigger),  lessThan(0));
  expect(0, comparer.compare(bigger, bigger));
}

@Test()
void Comparer_NonDurationablePeriods()
{
  var month = const Period(months: 1);
  var days = const Period(days: 30);
  // At the start of January, a month is longer than 30 days
  var januaryComparer = Period.createComparer(LocalDateTime(2000, 1, 1, 0, 0, 0));
  expect(januaryComparer.compare(month, days),  greaterThan(0));
  expect(januaryComparer.compare(days, month),  lessThan(0));
  expect(0, januaryComparer.compare(month, month));

  // At the start of February, a month is shorter than 30 days
  var februaryComparer = Period.createComparer(LocalDateTime(2000, 2, 1, 0, 0, 0));
  expect(februaryComparer.compare(month, days),  lessThan(0));
  expect(februaryComparer.compare(days, month),  greaterThan(0));
  expect(0, februaryComparer.compare(month, month));
}

@Test()
// [TestCaseSource(nameof(AllPeriodUnits))]
@TestCaseSource(Symbol('AllPeriodUnits'))
void Between_ExtremeValues(PeriodUnits units)
{
  // We can't use None, and Nanoseconds will *correctly* overflow.
  if (units == PeriodUnits.none || units == PeriodUnits.nanoseconds)
  {
    return;
  }
  var minValue = LocalDate.minIsoValue.at(LocalTime.minValue);
  var maxValue = LocalDate.maxIsoValue.at(LocalTime.maxValue);
  Period.differenceBetweenDateTime(minValue, maxValue, units);
}

@Test()
void Between_ExtremeValues_Overflow()
{
  var minValue = LocalDate.minIsoValue.at(LocalTime.minValue);
  var maxValue = LocalDate.maxIsoValue.at(LocalTime.maxValue);
  expect(() => Period.differenceBetweenDateTime(minValue, maxValue, PeriodUnits.nanoseconds), throwsRangeError); // throwsStateError);
}

@Test()
@TestCase(['2015-02-28T16:00:00', "2016-02-29T08:00:00", PeriodUnits.years, 1, 0])
@TestCase(['2015-02-28T16:00:00', "2016-02-29T08:00:00", PeriodUnits.months, 12, -11])
@TestCase(['2014-01-01T16:00:00', "2014-01-03T08:00:00", PeriodUnits.days, 1, -1])
@TestCase(['2014-01-01T16:00:00', "2014-01-03T08:00:00", PeriodUnits.hours, 40, -40])
void Between_LocalDateTime_AwkwardTimeOfDayWithSingleUnit(String startText, String endText, PeriodUnits units, int expectedForward, int expectedBackward)
{
  LocalDateTime start = LocalDateTimePattern.extendedIso.parse(startText).value;
  LocalDateTime end = LocalDateTimePattern.extendedIso.parse(endText).value;
  Period forward = Period.differenceBetweenDateTime(start, end, units);
  expect(expectedForward, forward.toBuilder()[units]);
  Period backward = Period.differenceBetweenDateTime(end, start, units);
  expect(expectedBackward, backward.toBuilder()[units]);
}

@Test()
void Between_LocalDateTime_SameValue()
{
  LocalDateTime start = LocalDateTime(2014, 1, 1, 16, 0, 0);
  expect(Period.zero, Period.differenceBetweenDateTime(start, start));
}

@Test()
void Between_LocalDateTime_AwkwardTimeOfDayWithMultipleUnits()
{
  LocalDateTime start = LocalDateTime(2014, 1, 1, 16, 0, 0);
  LocalDateTime end = LocalDateTime(2015, 2, 3, 8, 0, 0);
  Period actual = Period.differenceBetweenDateTime(start, end, PeriodUnits.yearMonthDay | PeriodUnits.allTimeUnits);
  Period expected = (PeriodBuilder()..years = 1..months = 1..days = 1..hours = 16).build();
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
  var period = const Period(nanoseconds: 1234567890);
  expect(1234567890, period.nanoseconds);
}

@Test()
void AddPeriodToPeriod_NoOverflow()
{
  Period p1 = const Period(hours: Platform.int64MaxValue);
  Period p2 = const Period(minutes: 60);
  expect((PeriodBuilder()..hours = Platform.int64MaxValue..minutes = 60).build(), p1 + p2);
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

