// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/PeriodTest.cs
// 048d8db  on Mar 7

import 'dart:async';
import 'dart:math' as math;

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

// June 19th 2010, 2:30:15am
final LocalDateTime TestDateTime1 = new LocalDateTime.fromYMDHMS(2010, 6, 19, 2, 30, 15);
// June 19th 2010, 4:45:10am
final LocalDateTime TestDateTime2 = new LocalDateTime.fromYMDHMS(2010, 6, 19, 4, 45, 10);
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
  Period actual = Period.Between(new LocalDateTime.fromYMDHM(2012, 2, 21, 0, 0), new LocalDateTime.fromYMDHM(2012, 2, 28, 0, 0));
  Period expected = new Period.fromDays(7);
  expect(expected, actual);
}

@Test()
void BetweenLocalDateTimes_MovingForwardWithAllFields_GivesExactResult()
{
  Period actual = Period.Between(TestDateTime1, TestDateTime2);
  Period expected = new Period.fromHours(2) + new Period.fromMinutes(14) + new Period.fromSeconds(55);
  expect(expected, actual);
}

@Test()
void BetweenLocalDateTimes_MovingBackwardWithAllFields_GivesExactResult()
{
  Period actual = Period.Between(TestDateTime2, TestDateTime1);
  Period expected = new Period.fromHours(-2) + new Period.fromMinutes(-14) + new Period.fromSeconds(-55);
  expect(expected, actual);
}

@Test()
void BetweenLocalDateTimes_MovingForwardWithHoursAndMinutes_RoundsTowardsStart()
{
  Period actual = Period.Between(TestDateTime1, TestDateTime2, HoursMinutesPeriodType);
  Period expected = new Period.fromHours(2) + new Period.fromMinutes(14);
  expect(expected, actual);
}

@Test()
void BetweenLocalDateTimes_MovingBackwardWithHoursAndMinutes_RoundsTowardsStart()
{
  Period actual = Period.Between(TestDateTime2, TestDateTime1, HoursMinutesPeriodType);
  Period expected = new Period.fromHours(-2) + new Period.fromMinutes(-14);
  expect(expected, actual);
}

@Test()
void BetweenLocalDateTimes_AcrossDays()
{
  Period expected = new Period.fromHours(23) + new Period.fromMinutes(59);
  Period actual = Period.Between(TestDateTime1, TestDateTime1.PlusDays(1).PlusMinutes(-1));
  expect(expected, actual);
}

@Test()
void BetweenLocalDateTimes_AcrossDays_MinutesAndSeconds()
{
  Period expected = new Period.fromMinutes(24 * 60 - 1) + new Period.fromSeconds(59);
  Period actual = Period.Between(TestDateTime1, TestDateTime1.PlusDays(1).PlusSeconds(-1), PeriodUnits.minutes | PeriodUnits.seconds);
  expect(expected, actual);
}

@Test()
void BetweenLocalDateTimes_NotInt64Representable()
{
  LocalDateTime start = new LocalDateTime.fromYMDHMSM(-5000, 1, 1, 0, 1, 2, 123);
  LocalDateTime end = new LocalDateTime.fromYMDHMSM(9000, 1, 1, 1, 2, 3, 456);
  expect((end.ToLocalInstant().TimeSinceLocalEpoch - start.ToLocalInstant().TimeSinceLocalEpoch).IsInt64Representable, isFalse);

  Period expected = (new PeriodBuilder()
    // 365.2425 * 14000 = 5113395
    ..Hours = 5113395 * 24 + 1
  ..Minutes = 1
  ..Seconds = 1
  ..Milliseconds = 333
  ).Build();
Period actual = Period.Between(start, end, PeriodUnits.allTimeUnits);
expect(expected, actual);
}

@Test()
void BetweenLocalDates_InvalidUnits()
{
  expect(() => Period.BetweenDates(TestDate1, TestDate2, new PeriodUnits(0)), throwsArgumentError);
  expect(() => Period.BetweenDates(TestDate1, TestDate2, new PeriodUnits(-1)), throwsArgumentError);
  expect(() => Period.BetweenDates(TestDate1, TestDate2, PeriodUnits.allTimeUnits), throwsArgumentError);
  expect(() => Period.BetweenDates(TestDate1, TestDate2, PeriodUnits.years | PeriodUnits.hours), throwsArgumentError);
}

@Test() @SkipMe.unimplemented()
void BetweenLocalDates_DifferentCalendarSystems_Throws()
{
  LocalDate start = new LocalDate.forCalendar(2017, 11, 1, CalendarSystem.Coptic);
  LocalDate end = new LocalDate.forCalendar(2017, 11, 5, CalendarSystem.Gregorian);
  expect(() => Period.BetweenDates(start, end), throwsArgumentError);
}

@Test() @SkipMe.text()
@TestCase(const ["2016-05-16", "2019-03-13", PeriodUnits.years, 2])
@TestCase(const ["2016-05-16", "2017-07-13", PeriodUnits.months, 13])
@TestCase(const ["2016-05-16", "2016-07-13", PeriodUnits.weeks, 8])
@TestCase(const ["2016-05-16", "2016-07-13", PeriodUnits.days, 58])
void BetweenLocalDates_SingleUnit(String startText, String endText, PeriodUnits units, int expectedValue)
{
  var start = LocalDatePattern.Iso.Parse(startText).Value;
  var end = LocalDatePattern.Iso.Parse(endText).Value;
  var actual = Period.Between(start, end, units);
  var expected = (new PeriodBuilder()..[units] = expectedValue).Build();
expect(expected, actual);
}

@Test()
void BetweenLocalDates_MovingForwardNoLeapYears_WithExactResults()
{
  Period actual = Period.BetweenDates(TestDate1, TestDate2);
  Period expected = new Period.fromMonths(8) + new Period.fromDays(10);
  expect(expected, actual);
}

@Test()
void BetweenLocalDates_MovingForwardInLeapYear_WithExactResults()
{
  Period actual = Period.BetweenDates(TestDate1, TestDate3);
  Period expected = new Period.fromYears(1) + new Period.fromMonths(8) + new Period.fromDays(11);
  expect(expected, actual);
}

@Test()
void BetweenLocalDates_MovingBackwardNoLeapYears_WithExactResults()
{
  Period actual = Period.BetweenDates(TestDate2, TestDate1);
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
  Period actual = Period.BetweenDates(TestDate3, TestDate1);
  Period expected = new Period.fromYears(-1) + new Period.fromMonths(-8) + new Period.fromDays(-12);
  expect(expected, actual);
}

@Test()
void BetweenLocalDates_MovingForward_WithJustMonths()
{
  Period actual = Period.BetweenDates(TestDate1, TestDate3, PeriodUnits.months);
  Period expected = new Period.fromMonths(20);
  expect(expected, actual);
}

@Test()
void BetweenLocalDates_MovingBackward_WithJustMonths()
{
  Period actual = Period.BetweenDates(TestDate3, TestDate1, PeriodUnits.months);
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
  expect(new Period.fromMonths(1) + new Period.fromDays(20), Period.BetweenDates(d1, d2));
  // Going backward, we go to February 28th (-1 month, day is rounded) then February 10th (-18 days)
  expect(new Period.fromMonths(-1) + new Period.fromDays(-18), Period.BetweenDates(d2, d1));
}

@Test()
void BetweenLocalDates_EndOfMonth()
{
  LocalDate d1 = new LocalDate(2013, 3, 31);
  LocalDate d2 = new LocalDate(2013, 4, 30);
  expect(new Period.fromMonths(1), Period.BetweenDates(d1, d2));
  expect(new Period.fromDays(-30), Period.BetweenDates(d2, d1));
}

@Test()
void BetweenLocalDates_OnLeapYear()
{
  LocalDate d1 = new LocalDate(2012, 2, 29);
  LocalDate d2 = new LocalDate(2013, 2, 28);
  expect(new Period.fromYears(1), Period.BetweenDates(d1, d2));
  // Go back from February 28th 2013 to March 28th 2012, then back 28 days to February 29th 2012
  expect(new Period.fromMonths(-11) + new Period.fromDays(-28), Period.BetweenDates(d2, d1));
}

@Test()
void BetweenLocalDates_AfterLeapYear()
{
  LocalDate d1 = new LocalDate(2012, 3, 5);
  LocalDate d2 = new LocalDate(2013, 3, 5);
  expect(new Period.fromYears(1), Period.BetweenDates(d1, d2));
  expect(new Period.fromYears(-1), Period.BetweenDates(d2, d1));
}

@Test() @SkipMe.text()
void BetweenLocalDateTimes_OnLeapYear()
{
  LocalDateTime dt1 = new LocalDateTime.fromYMDHM(2012, 2, 29, 2, 0);
  LocalDateTime dt2 = new LocalDateTime.fromYMDHM(2012, 2, 29, 4, 0);
  LocalDateTime dt3 = new LocalDateTime.fromYMDHM(2013, 2, 28, 3, 0);
  expect(Parse("P1YT1H"), Period.Between(dt1, dt3));
  expect(Parse("P11M29DT23H"), Period.Between(dt2, dt3));

  expect(Parse("P-11M-28DT-1H"), Period.Between(dt3, dt1));
  expect(Parse("P-11M-27DT-23H"), Period.Between(dt3, dt2));
}

@Test() @SkipMe.unimplemented()
void BetweenLocalDateTimes_OnLeapYearIslamic()
{
  var calendar = CalendarSystem.GetIslamicCalendar(IslamicLeapYearPattern.Base15, IslamicEpoch.Civil);
  expect(calendar.IsLeapYear(2), isTrue);
  expect(calendar.IsLeapYear(3), isFalse);

  LocalDateTime dt1 = new LocalDateTime.fromYMDHMC(2, 12, 30, 2, 0, calendar);
  LocalDateTime dt2 = new LocalDateTime.fromYMDHMC(2, 12, 30, 4, 0, calendar);
  LocalDateTime dt3 = new LocalDateTime.fromYMDHMC(3, 12, 29, 3, 0, calendar);

  // Adding a year truncates to 0003-12-28T02:00:00, then add an hour.
  expect(Parse("P1YT1H"), Period.Between(dt1, dt3));
  // Adding a year would overshoot. Adding 11 months takes us to month 03-11-30T04:00.
  // Adding another 28 days takes us to 03-12-28T04:00, then add another 23 hours to finish.
  expect(Parse("P11M28DT23H"), Period.Between(dt2, dt3));

  // Subtracting 11 months takes us to 03-01-29T03:00. Subtracting another 29 days
  // takes us to 02-12-30T03:00, and another hour to get to the target.
  expect(Parse("P-11M-29DT-1H"), Period.Between(dt3, dt1));
  expect(Parse("P-11M-28DT-23H"), Period.Between(dt3, dt2));
}

@Test()
void BetweenLocalDateTimes_InvalidUnits()
{
  expect(() => Period.BetweenDates(TestDate1, TestDate2, new PeriodUnits(0)), throwsArgumentError);
  expect(() => Period.BetweenDates(TestDate1, TestDate2, new PeriodUnits(-1)), throwsArgumentError);
}

@Test()
void BetweenLocalTimes_InvalidUnits()
{
  LocalTime t1 = new LocalTime(10, 0);
  LocalTime t2 = LocalTime.FromHourMinuteSecondMillisecondTick(15, 30, 45, 20, 5);
  expect(() => Period.BetweenTimes(t1, t2, new PeriodUnits(0)), throwsArgumentError);
  expect(() => Period.BetweenTimes(t1, t2, new PeriodUnits(-1)), throwsArgumentError);
  expect(() => Period.BetweenTimes(t1, t2, PeriodUnits.yearMonthDay), throwsArgumentError);
  expect(() => Period.BetweenTimes(t1, t2, PeriodUnits.years | PeriodUnits.hours), throwsArgumentError);
}

@Test() @SkipMe.text()
@TestCase(const ["01:02:03", "05:00:00", PeriodUnits.hours, 3])
@TestCase(const ["01:02:03", "03:00:00", PeriodUnits.minutes, 117])
@TestCase(const ["01:02:03", "01:05:02", PeriodUnits.seconds, 179])
@TestCase(const ["01:02:03", "01:02:04.1234", PeriodUnits.milliseconds, 1123])
@TestCase(const ["01:02:03", "01:02:04.1234", PeriodUnits.ticks, 11234000])
@TestCase(const ["01:02:03", "01:02:04.1234", PeriodUnits.nanoseconds, 1123400000])
void BetweenLocalTimes_SingleUnit(String startText, String endText, PeriodUnits units, int expectedValue) {
  var start = LocalTimePattern.ExtendedIso
      .Parse(startText)
      .Value;
  var end = LocalTimePattern.ExtendedIso
      .Parse(endText)
      .Value;
  var actual = Period.Between(start, end, units);
  var expected = (new PeriodBuilder()
    ..[units] = expectedValue).Build();
  expect(expected, actual);
}

@Test()
void BetweenLocalTimes_MovingForwards()
{
  LocalTime t1 = new LocalTime(10, 0);
  LocalTime t2 = LocalTime.FromHourMinuteSecondMillisecondTick(15, 30, 45, 20, 5);
  expect(new Period.fromHours(5) + new Period.fromMinutes(30) + new Period.fromSeconds(45) +
      new Period.fromMilliseconds(20) + new Period.fromTicks(5),
      Period.BetweenTimes(t1, t2));
}

@Test()
void BetweenLocalTimes_MovingBackwards()
{
  LocalTime t1 = LocalTime.FromHourMinuteSecondMillisecondTick(15, 30, 45, 20, 5);
  LocalTime t2 = new LocalTime(10, 0);
  expect(new Period.fromHours(-5) + new Period.fromMinutes(-30) + new Period.fromSeconds(-45) +
      new Period.fromMilliseconds(-20) + new Period.fromTicks(-5),
      Period.BetweenTimes(t1, t2));
}

@Test()
void BetweenLocalTimes_MovingForwards_WithJustHours()
{
  LocalTime t1 = new LocalTime(11, 30);
  LocalTime t2 = new LocalTime(17, 15);
  expect(new Period.fromHours(5), Period.BetweenTimes(t1, t2, PeriodUnits.hours));
}

@Test()
void BetweenLocalTimes_MovingBackwards_WithJustHours()
{
  LocalTime t1 = new LocalTime(17, 15);
  LocalTime t2 = new LocalTime(11, 30);
  expect(new Period.fromHours(-5), Period.BetweenTimes(t1, t2, PeriodUnits.hours));
}

@Test()
void Addition_WithDifferent_PeriodTypes()
{
  Period p1 = new Period.fromHours(3);
  Period p2 = new Period.fromMinutes(20);
  Period sum = p1 + p2;
  expect(3, sum.Hours);
  expect(20, sum.Minutes);
}

@Test()
void Addition_With_IdenticalPeriodTypes()
{
  Period p1 = new Period.fromHours(3);
  Period p2 = new Period.fromHours(2);
  Period sum = p1 + p2;
  expect(5, sum.Hours);
}

@Test()
void Addition_DayCrossingMonthBoundary()
{
  LocalDateTime start = new LocalDateTime.fromYMDHM(2010, 2, 20, 10, 0);
  LocalDateTime result = start + new Period.fromDays(10);
  expect(new LocalDateTime.fromYMDHM(2010, 3, 2, 10, 0), result);
}

@Test()
void Addition_OneYearOnLeapDay()
{
  LocalDateTime start = new LocalDateTime.fromYMDHM(2012, 2, 29, 10, 0);
  LocalDateTime result = start + new Period.fromYears(1);
  // Feb 29th becomes Feb 28th
  expect(new LocalDateTime.fromYMDHM(2013, 2, 28, 10, 0), result);
}

@Test()
void Addition_FourYearsOnLeapDay()
{
  LocalDateTime start = new LocalDateTime.fromYMDHM(2012, 2, 29, 10, 0);
  LocalDateTime result = start + new Period.fromYears(4);
  // Feb 29th is still valid in 2016
  expect(new LocalDateTime.fromYMDHM(2016, 2, 29, 10, 0), result);
}

@Test()
void Addition_YearMonthDay()
{
  // One year, one month, two days
  Period period = new Period.fromYears(1) + new Period.fromMonths(1) + new Period.fromDays(2);
  LocalDateTime start = new LocalDateTime.fromYMDHM(2007, 1, 30, 0, 0);
  // Periods are added in order, so this becomes...
  // Add one year: Jan 30th 2008
  // Add one month: Feb 29th 2008
  // Add two days: March 2nd 2008
  // If we added the days first, we'd end up with March 1st instead.
  LocalDateTime result = start + period;
  expect(new LocalDateTime.fromYMDHM(2008, 3, 2, 0, 0), result);
}

@Test()
void Subtraction_WithDifferent_PeriodTypes()
{
  Period p1 = new Period.fromHours(3);
  Period p2 = new Period.fromMinutes(20);
  Period sum = p1 - p2;
  expect(3, sum.Hours);
  expect(-20, sum.Minutes);
}

@Test()
void Subtraction_With_IdenticalPeriodTypes()
{
  Period p1 = new Period.fromHours(3);
  Period p2 = new Period.fromHours(2);
  Period sum = p1 - p2;
  expect(1, sum.Hours);
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
  expect(new Period.fromHours(10).Equals(new Period.fromHours(20)), isFalse);
  expect(new Period.fromMinutes(15).Equals(new Period.fromSeconds(15)), isFalse);
  expect(new Period.fromHours(1).Equals(new Period.fromMinutes(60)), isFalse);
  // expect(new Period.fromHours(1).Equals(new Object()), isFalse);
  expect(new Period.fromHours(1).Equals(null), isFalse);
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
    ..[unit] = 1).Build();
  expect(hasTimeComponent, period.HasTimeComponent);
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
  var period = (new PeriodBuilder()..[unit] = 1).Build();
expect(hasDateComponent, period.HasDateComponent);
}

@Test()
void HasTimeComponent_Compound()
{
  LocalDateTime dt1 = new LocalDateTime.fromYMDHMS(2000, 1, 1, 10, 45, 00);
  LocalDateTime dt2 = new LocalDateTime.fromYMDHMS(2000, 2, 4, 11, 50, 00);

  // Case 1: Entire period is date-based (no time units available)
  expect(Period.BetweenDates(dt1.Date, dt2.Date).HasTimeComponent, isFalse);

  // Case 2: Period contains date and time units, but time units are all zero
  expect(Period.Between(dt1.Date.At(LocalTime.Midnight), dt2.Date.At(LocalTime.Midnight)).HasTimeComponent, isFalse);

  // Case 3: Entire period is time-based, but 0. (Same local time twice here.)
  expect(Period.BetweenTimes(dt1.TimeOfDay, dt1.TimeOfDay).HasTimeComponent, isFalse);

  // Case 4: Period contains date and time units, and some time units are non-zero
  expect(Period.Between(dt1, dt2).HasTimeComponent, isTrue);

  // Case 5: Entire period is time-based, and some time units are non-zero
  expect(Period.BetweenTimes(dt1.TimeOfDay, dt2.TimeOfDay).HasTimeComponent, isTrue);
}

@Test()
void HasDateComponent_Compound()
{
  LocalDateTime dt1 = new LocalDateTime.fromYMDHMS(2000, 1, 1, 10, 45, 00);
  LocalDateTime dt2 = new LocalDateTime.fromYMDHMS(2000, 2, 4, 11, 50, 00);

  // Case 1: Entire period is time-based (no date units available)
  expect(Period.BetweenTimes(dt1.TimeOfDay, dt2.TimeOfDay).HasDateComponent, isFalse);

  // Case 2: Period contains date and time units, but date units are all zero
  expect(Period.Between(dt1, dt1.Date.At(dt2.TimeOfDay)).HasDateComponent, isFalse);

  // Case 3: Entire period is date-based, but 0. (Same local date twice here.)
  expect(Period.BetweenDates(dt1.Date, dt1.Date).HasDateComponent, isFalse);

  // Case 4: Period contains date and time units, and some date units are non-zero
  expect(Period.Between(dt1, dt2).HasDateComponent, isTrue);

  // Case 5: Entire period is date-based, and some time units are non-zero
  expect(Period.BetweenDates(dt1.Date, dt2.Date).HasDateComponent, isTrue);
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
  Period period = new Period(Years: 1, Months: 2, Weeks: 3, Days: 4,
      Hours: 5, Minutes: 6, Seconds: 7, Milliseconds: 8, Ticks: 9, Nanoseconds: 10);
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
  expect("P", Period.Zero.toString());
}

@Test()
void ToBuilder_SingleUnit()
{
  var builder = new Period.fromHours(5).ToBuilder();
  var expected = (new PeriodBuilder()..Hours = 5).Build();
expect(expected, builder.Build());
}

@Test()
void ToBuilder_MultipleUnits()
{
  var builder = (new Period.fromHours(5) + new Period.fromWeeks(2)).ToBuilder();
  var expected = (new PeriodBuilder()..Hours = 5..Weeks = 2).Build();
expect(expected, builder.Build());
}

@Test()
void Normalize_Weeks()
{
  var original = (new PeriodBuilder()..Weeks = 2..Days = 5).Build();
var normalized = original.Normalize();
var expected = (new PeriodBuilder()..Days = 19).Build();
expect(expected, normalized);
}

@Test()
void Normalize_Hours()
{
  var original = (new PeriodBuilder()..Hours = 25..Days = 1).Build();
var normalized = original.Normalize();
var expected = (new PeriodBuilder()..Hours = 1..Days = 2).Build();
expect(expected, normalized);
}

@Test()
void Normalize_Minutes()
{
  var original = (new PeriodBuilder()..Hours = 1..Minutes = 150).Build();
var normalized = original.Normalize();
var expected = (new PeriodBuilder()..Hours = 3..Minutes = 30).Build();
expect(expected, normalized);
}


@Test()
void Normalize_Seconds()
{
  var original = (new PeriodBuilder()..Minutes = 1..Seconds= 150).Build();
var normalized = original.Normalize();
var expected = (new PeriodBuilder()..Minutes = 3..Seconds= 30).Build();
expect(expected, normalized);
}

@Test()
void Normalize_Milliseconds()
{
  var original = (new PeriodBuilder()..Seconds = 1..Milliseconds = 1500).Build();
var normalized = original.Normalize();
var expected = (new PeriodBuilder()..Seconds = 2..Milliseconds = 500).Build();
expect(expected, normalized);
}

@Test()
void Normalize_Ticks()
{
  var original = (new PeriodBuilder()..Milliseconds = 1..Ticks = 15000).Build();
var normalized = original.Normalize();
var expected = (new PeriodBuilder()..Milliseconds = 2..Ticks = 0..Nanoseconds = 500000).Build();
expect(expected, normalized);
}

@Test()
void Normalize_Nanoseconds()
{
  var original = (new PeriodBuilder()..Ticks = 1..Nanoseconds = 150).Build();
var normalized = original.Normalize();
var expected = (new PeriodBuilder()..Nanoseconds = 250).Build();
expect(expected, normalized);
}

@Test()
void Normalize_MultipleFields()
{
  var original = (new PeriodBuilder()..Hours = 1..Minutes = 119..Seconds= 150).Build();
var normalized = original.Normalize();
var expected = (new PeriodBuilder()..Hours = 3..Minutes = 1..Seconds= 30).Build();
expect(expected, normalized);
}

@Test()
void Normalize_AllNegative()
{
  var original = (new PeriodBuilder()..Hours = -1..Minutes = -119..Seconds= -150).Build();
var normalized = original.Normalize();
var expected = (new PeriodBuilder()..Hours = -3..Minutes = -1..Seconds= -30).Build();
expect(expected, normalized);
}

@Test()
void Normalize_MixedSigns_PositiveResult()
{
  var original = (new PeriodBuilder()..Hours = 3..Minutes = -1).Build();
  var normalized = original.Normalize();
  var expected = (new PeriodBuilder()..Hours = 2..Minutes = 59).Build();
expect(expected, normalized);
}

@Test()
void Normalize_MixedSigns_NegativeResult()
{
  var original = (new PeriodBuilder()..Hours = 1..Minutes = -121).Build();
  var normalized = original.Normalize();
  var expected = (new PeriodBuilder()..Hours = -1..Minutes = -1).Build();
expect(expected, normalized);
}

@Test()
void Normalize_DoesntAffectMonthsAndYears()
{
  var original = (new PeriodBuilder()..Years = 2..Months = 1..Days = 400).Build();
expect(original, original.Normalize());
}

@Test()
void Normalize_ZeroResult()
{
  var original = (new PeriodBuilder()..Years = 0).Build();
expect(Period.Zero, original.Normalize());
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
  var period = (new PeriodBuilder()..Hours = 5..Minutes = 30).Build();
expect("PT5H30M", period.toString());
}

@Test()
void ToDuration_InvalidWithYears()
{
  Period period = new Period.fromYears(1);
  expect(() => period.ToSpan(), throwsStateError);
}

@Test()
void ToDuration_InvalidWithMonths()
{
  Period period = new Period.fromMonths(1);
  expect(() => period.ToSpan(), throwsStateError);
}

@Test()
void ToDuration_ValidAllAcceptableUnits() {
  Period period = (new PeriodBuilder()

    ..Weeks = 1
    ..Days = 2
    ..Hours = 3
    ..Minutes = 4
    ..Seconds = 5
    ..Milliseconds = 6
    ..Ticks = 7
  ).Build();
  expect(
      1 * TimeConstants.ticksPerWeek +
          2 * TimeConstants.ticksPerDay +
          3 * TimeConstants.ticksPerHour +
          4 * TimeConstants.ticksPerMinute +
          5 * TimeConstants.ticksPerSecond +
          6 * TimeConstants.ticksPerMillisecond + 7,
      period
          .ToSpan()
          .totalTicks); //.BclCompatibleTicks);
}

@Test()
void ToDuration_ValidWithZeroValuesInMonthYearUnits()
{
  Period period = new Period.fromMonths(1) + new Period.fromYears(1);
  period = period - period + new Period.fromDays(1);
  expect(period.HasTimeComponent, isFalse);
  expect(Span.oneDay, period.ToSpan());
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
  expect(NormalizingPeriodEqualityComparer.Instance.Equals(period, null), isFalse);
  expect(NormalizingPeriodEqualityComparer.Instance.Equals(null, period), isFalse);
}

@Test()
void NormalizingEqualityComparer_NullToNull()
{
  expect(NormalizingPeriodEqualityComparer.Instance.Equals(null, null), isTrue);
}

@Test()
void NormalizingEqualityComparer_PeriodToItself()
{
  Period period = new Period.fromYears(1);
  expect(NormalizingPeriodEqualityComparer.Instance.Equals(period, period), isTrue);
}

@Test()
void NormalizingEqualityComparer_NonEqualAfterNormalization()
{
  Period period1 = new Period.fromHours(2);
  Period period2 = new Period.fromMinutes(150);
  expect(NormalizingPeriodEqualityComparer.Instance.Equals(period1, period2), isFalse);
}

@Test()
void NormalizingEqualityComparer_EqualAfterNormalization()
{
  Period period1 = new Period.fromHours(2);
  Period period2 = new Period.fromMinutes(120);
  expect(NormalizingPeriodEqualityComparer.Instance.Equals(period1, period2), isTrue);
}

@Test()
void NormalizingEqualityComparer_GetHashCodeAfterNormalization()
{
  Period period1 = new Period.fromHours(2);
  Period period2 = new Period.fromMinutes(120);
  expect(NormalizingPeriodEqualityComparer.Instance.getHashCode(period1),
      NormalizingPeriodEqualityComparer.Instance.getHashCode(period2));
}

@Test()
void Comparer_NullWithNull()
{
  var comparer = Period.CreateComparer(new LocalDateTime.fromYMDHM(2000, 1, 1, 0, 0));
  expect(0, comparer.Compare(null, null));
}

@Test()
void Comparer_NullWithNonNull()
{
  var comparer = Period.CreateComparer(new LocalDateTime.fromYMDHM(2000, 1, 1, 0, 0));
  expect(comparer.Compare(null, Period.Zero),  lessThan(0));
}

@Test()
void Comparer_NonNullWithNull()
{
  var comparer = Period.CreateComparer(new LocalDateTime.fromYMDHM(2000, 1, 1, 0, 0));
  expect(comparer.Compare(Period.Zero, null),  greaterThan(0));
}

@Test()
void Comparer_DurationablePeriods()
{
  var bigger = new Period.fromHours(25);
  var smaller = new Period.fromDays(1);
  var comparer = Period.CreateComparer(new LocalDateTime.fromYMDHM(2000, 1, 1, 0, 0));
  expect(comparer.Compare(bigger, smaller),  greaterThan(0));
  expect(comparer.Compare(smaller, bigger),  lessThan(0));
  expect(0, comparer.Compare(bigger, bigger));
}

@Test()
void Comparer_NonDurationablePeriods()
{
  var month = new Period.fromMonths(1);
  var days = new Period.fromDays(30);
  // At the start of January, a month is longer than 30 days
  var januaryComparer = Period.CreateComparer(new LocalDateTime.fromYMDHM(2000, 1, 1, 0, 0));
  expect(januaryComparer.Compare(month, days),  greaterThan(0));
  expect(januaryComparer.Compare(days, month),  lessThan(0));
  expect(0, januaryComparer.Compare(month, month));

  // At the start of February, a month is shorter than 30 days
  var februaryComparer = Period.CreateComparer(new LocalDateTime.fromYMDHM(2000, 2, 1, 0, 0));
  expect(februaryComparer.Compare(month, days),  lessThan(0));
  expect(februaryComparer.Compare(days, month),  greaterThan(0));
  expect(0, februaryComparer.Compare(month, month));
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
  var minValue = LocalDate.MinIsoValue.At(LocalTime.MinValue);
  var maxValue = LocalDate.MaxIsoValue.At(LocalTime.MaxValue);
  Period.Between(minValue, maxValue, units);
}

@Test()
void Between_ExtremeValues_Overflow()
{
  var minValue = LocalDate.MinIsoValue.At(LocalTime.MinValue);
  var maxValue = LocalDate.MaxIsoValue.At(LocalTime.MaxValue);
  expect(() => Period.Between(minValue, maxValue, PeriodUnits.nanoseconds), throwsRangeError); // throwsStateError);
}

@Test() @SkipMe.text()
@TestCase(const ["2015-02-28T16:00:00", "2016-02-29T08:00:00", PeriodUnits.years, 1, 0])
@TestCase(const ["2015-02-28T16:00:00", "2016-02-29T08:00:00", PeriodUnits.months, 12, -11])
@TestCase(const ["2014-01-01T16:00:00", "2014-01-03T08:00:00", PeriodUnits.days, 1, -1])
@TestCase(const ["2014-01-01T16:00:00", "2014-01-03T08:00:00", PeriodUnits.hours, 40, -40])
void Between_LocalDateTime_AwkwardTimeOfDayWithSingleUnit(String startText, String endText, PeriodUnits units, int expectedForward, int expectedBackward)
{
  LocalDateTime start = LocalDateTimePattern.ExtendedIso.Parse(startText).Value;
  LocalDateTime end = LocalDateTimePattern.ExtendedIso.Parse(endText).Value;
  Period forward = Period.Between(start, end, units);
  expect(expectedForward, forward.ToBuilder()[units]);
  Period backward = Period.Between(end, start, units);
  expect(expectedBackward, backward.ToBuilder()[units]);
}

@Test()
void Between_LocalDateTime_SameValue()
{
  LocalDateTime start = new LocalDateTime.fromYMDHMS(2014, 1, 1, 16, 0, 0);
  expect(Period.Zero, Period.Between(start, start));
}

@Test()
void Between_LocalDateTime_AwkwardTimeOfDayWithMultipleUnits()
{
  LocalDateTime start = new LocalDateTime.fromYMDHMS(2014, 1, 1, 16, 0, 0);
  LocalDateTime end = new LocalDateTime.fromYMDHMS(2015, 2, 3, 8, 0, 0);
  Period actual = Period.Between(start, end, PeriodUnits.yearMonthDay | PeriodUnits.allTimeUnits);
  Period expected = (new PeriodBuilder()..Years = 1..Months = 1..Days = 1..Hours = 16).Build();
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
  expect(1234567890, period.Nanoseconds);
}

@Test()
void AddPeriodToPeriod_NoOverflow()
{
  Period p1 = new Period.fromHours(Utility.int64MaxValue);
  Period p2 = new Period.fromMinutes(60);
  expect((new PeriodBuilder()..Hours = Utility.int64MaxValue..Minutes = 60).Build(), p1 + p2);
}

/* We don't overflow
@Test()
void AddPeriodToPeriod_Overflow()
{
  Period p1 = new Period.fromHours(Utility.int64MaxValue);
  Period p2 = new Period.fromHours(1);
  expect(() => (p1 + p2).hashCode, throwsStateError);
}*/

/// <summary>
/// Just a simple way of parsing a period string. It's a more compact period representation.
/// </summary>
Period Parse(String text)
{
  return PeriodPattern.Roundtrip.Parse(text).Value;
}
