// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/LocalDateTimeTest.cs
// 69dedbc  9 days ago

import 'dart:async';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import 'time_machine_testing.dart';

DateTimeZone Pacific; // = DateTimeZoneProviders.Tzdb["America/Los_Angeles"];

Future main() async {
  Pacific = await (await DateTimeZoneProviders.Tzdb)["America/Los_Angeles"];
  await runTests();
}

@Test()
void ToDateTimeUnspecified()
{
  LocalDateTime zoned = new LocalDateTime.fromYMDHMS(2011, 3, 5, 1, 0, 0);
  DateTime expected = new DateTime(2011, 3, 5, 1, 0, 0); //, DateTimeKind.Unspecified);
  DateTime actual = zoned.ToDateTimeUnspecified();
  expect(expected, actual);
  // Kind isn't checked by Equals...
  // expect(DateTimeKind.Unspecified, actual.Kind);
  expect(expected.isUtc, actual.isUtc);
  expect(expected.isUtc, isFalse);
}

@Test()
@TestCase(const [100])
@TestCase(const [1900])
@TestCase(const [2900])
void ToDateTimeUnspecified_TruncatesTowardsStartOfTime(int year)
{
  var ldt = new LocalDateTime.fromYMDHMS(year, 1, 1, 13, 15, 55).PlusNanoseconds(TimeConstants.nanosecondsPerSecond - 1);
  var expected = new DateTime(year, 1, 1, 13, 15, 55/*, DateTimeKind.Unspecified*/)
      .add(new Duration(microseconds: TimeConstants.microsecondsPerSecond - 1));
  var actual = ldt.ToDateTimeUnspecified();
  expect(expected, actual);
}

@Test()
void ToDateTimeUnspecified_OutOfRange()
{
  // One day before 1st January, 1AD (which is DateTime.MinValue)
  var ldt = new LocalDate(1, 1, 1).PlusDays(-1).AtMidnight;
  expect(() => ldt.ToDateTimeUnspecified(), throwsStateError);
}

@Test()
void FromDateTime()
{
  LocalDateTime expected = new LocalDateTime.fromYMDHM(2011, 08, 18, 20, 53);
  // for (DateTimeKind kind in Enum.GetValues(typeof(DateTimeKind)))
  DateTime x = new DateTime(2011, 08, 18, 20, 53, 0); //, kind);
  LocalDateTime actual = LocalDateTime.FromDateTime(x);
  expect(actual, expected);
}

@Test()
void FromDateTime_WithCalendar()
{
  // Julian calendar is 13 days behind Gregorian calendar in the 21st century
  LocalDateTime expected = new LocalDateTime.fromYMDHMC(2011, 08, 05, 20, 53, CalendarSystem.Julian);
  //for (DateTimeKind kind in Enum.GetValues(typeof(DateTimeKind)))
  {
  DateTime x = new DateTime(2011, 08, 18, 20, 53, 0); //, kind);
  LocalDateTime actual = LocalDateTime.FromDateTime(x, CalendarSystem.Julian);
  expect(actual, expected);
  }
}

@Test()
void TimeProperties_AfterEpoch()
{
  // Use the largest valid year as part of validating against overflow
  LocalDateTime ldt = new LocalDateTime.fromYMDHMS(GregorianYearMonthDayCalculator.maxGregorianYear, 1, 2, 15, 48, 25).PlusNanoseconds(123456789);
  expect(15, ldt.Hour);
  expect(3, ldt.ClockHourOfHalfDay);
  expect(48, ldt.Minute);
  expect(25, ldt.Second);
  expect(123, ldt.Millisecond);
  expect(1234567, ldt.TickOfSecond);
  expect(15 * TimeConstants.ticksPerHour +
      48 * TimeConstants.ticksPerMinute +
      25 * TimeConstants.ticksPerSecond +
      1234567, ldt.TickOfDay);
  expect(15 * TimeConstants.nanosecondsPerHour +
      48 * TimeConstants.nanosecondsPerMinute +
      25 * TimeConstants.nanosecondsPerSecond +
      123456789, ldt.NanosecondOfDay);
  expect(123456789, ldt.NanosecondOfSecond);
}

@Test()
void TimeProperties_BeforeEpoch()
{
  // Use the smallest valid year number as part of validating against overflow
  LocalDateTime ldt = new LocalDateTime.fromYMDHMS(GregorianYearMonthDayCalculator.minGregorianYear, 1, 2, 15, 48, 25).PlusNanoseconds(123456789);
  expect(15, ldt.Hour);
  expect(3, ldt.ClockHourOfHalfDay);
  expect(48, ldt.Minute);
  expect(25, ldt.Second);
  expect(123, ldt.Millisecond);
  expect(1234567, ldt.TickOfSecond);
  expect(15 * TimeConstants.ticksPerHour +
      48 * TimeConstants.ticksPerMinute +
      25 * TimeConstants.ticksPerSecond +
      1234567, ldt.TickOfDay);
  expect(15 * TimeConstants.nanosecondsPerHour +
      48 * TimeConstants.nanosecondsPerMinute +
      25 * TimeConstants.nanosecondsPerSecond +
      123456789, ldt.NanosecondOfDay);
  expect(123456789, ldt.NanosecondOfSecond);
}

@Test()
void DateTime_Roundtrip_OtherCalendarInBcl()
{
  var bcl = BclCalendars.Hijri;
  DateTime original = bcl.ToDateTime(1376, 6, 19, 0, 0, 0, 0);
  LocalDateTime noda = LocalDateTime.FromDateTime(original);
  // The DateTime only knows about the ISO version...
  expect(1376, isNot(1376));
  expect(CalendarSystem.Iso, noda.Calendar);
  DateTime _final = noda.ToDateTimeUnspecified();
  expect(original, _final);
}

@Test()
void WithCalendar()
{
  LocalDateTime isoEpoch = new LocalDateTime.fromYMDHMS(1970, 1, 1, 0, 0, 0);
  LocalDateTime julianEpoch = isoEpoch.WithCalendar(CalendarSystem.Julian);
  expect(1969, julianEpoch.Year);
  expect(12, julianEpoch.Month);
  expect(19, julianEpoch.Day);
  expect(isoEpoch.TimeOfDay, julianEpoch.TimeOfDay);
}

// Verifies that negative local instant ticks don't cause a problem with the date
@Test()
void TimeOfDay_Before1970()
{
  LocalDateTime dateTime = new LocalDateTime.fromYMDHMS(1965, 11, 8, 12, 5, 23);
  LocalTime expected = new LocalTime(12, 5, 23);
  expect(expected, dateTime.TimeOfDay);
}

// Verifies that positive local instant ticks don't cause a problem with the date
@Test()
void TimeOfDay_After1970()
{
  LocalDateTime dateTime = new LocalDateTime.fromYMDHMS(1975, 11, 8, 12, 5, 23);
  LocalTime expected = new LocalTime(12, 5, 23);
  expect(expected, dateTime.TimeOfDay);
}

// Verifies that negative local instant ticks don't cause a problem with the date
@Test()
void Date_Before1970()
{
  LocalDateTime dateTime = new LocalDateTime.fromYMDHMS(1965, 11, 8, 12, 5, 23);
  LocalDate expected = new LocalDate(1965, 11, 8);
  expect(expected, dateTime.Date);
}

// Verifies that positive local instant ticks don't cause a problem with the date
@Test()
void Date_After1970()
{
  LocalDateTime dateTime = new LocalDateTime.fromYMDHMS(1975, 11, 8, 12, 5, 23);
  LocalDate expected = new LocalDate(1975, 11, 8);
  expect(expected, dateTime.Date);
}

@Test()
void DayOfWeek_AroundEpoch()
{
  // Test about couple of months around the Unix epoch. If that works, I'm confident the rest will.
  LocalDateTime dateTime = new LocalDateTime.fromYMDHM(1969, 12, 1, 0, 0);
  for (int i = 0; i < 60; i++)
  {
    // Check once per hour of the day, just in case something's messed up based on the time of day.
    for (int hour = 0; hour < 24; hour++)
    {
      expect(new IsoDayOfWeek(dateTime.ToDateTimeUnspecified().weekday), dateTime.DayOfWeek);
      dateTime = dateTime.PlusHours(1);
    }
  }
}

@Test()
void ClockHourOfHalfDay()
{
  expect(12, new LocalDateTime.fromYMDHMS(1975, 11, 8, 0, 0, 0).ClockHourOfHalfDay);
  expect(1, new LocalDateTime.fromYMDHMS(1975, 11, 8, 1, 0, 0).ClockHourOfHalfDay);
  expect(12, new LocalDateTime.fromYMDHMS(1975, 11, 8, 12, 0, 0).ClockHourOfHalfDay);
  expect(1, new LocalDateTime.fromYMDHMS(1975, 11, 8, 13, 0, 0).ClockHourOfHalfDay);
  expect(11, new LocalDateTime.fromYMDHMS(1975, 11, 8, 23, 0, 0).ClockHourOfHalfDay);
}

@Test()
void Operators_SameCalendar()
{
  LocalDateTime value1 = new LocalDateTime.fromYMDHMS(2011, 1, 2, 10, 30, 0);
  LocalDateTime value2 = new LocalDateTime.fromYMDHMS(2011, 1, 2, 10, 30, 0);
  LocalDateTime value3 = new LocalDateTime.fromYMDHMS(2011, 1, 2, 10, 45, 0);
  TestHelper.TestOperatorComparisonEquality(value1, value2, [value3]);
}

@Test()
void Operators_DifferentCalendars_Throws()
{
  LocalDateTime value1 = new LocalDateTime.fromYMDHM(2011, 1, 2, 10, 30);
  LocalDateTime value2 = new LocalDateTime.fromYMDHMC(2011, 1, 3, 10, 30, CalendarSystem.Julian);

  expect(value1 == value2, isFalse);
  expect(value1 != value2, isTrue);

  expect(() => (value1 < value2).toString(), throwsArgumentError);
  expect(() => (value1 <= value2).toString(), throwsArgumentError);
  expect(() => (value1 > value2).toString(), throwsArgumentError);
  expect(() => (value1 >= value2).toString(), throwsArgumentError);
}

@Test()
void CompareTo_SameCalendar()
{
  LocalDateTime value1 = new LocalDateTime.fromYMDHM(2011, 1, 2, 10, 30);
  LocalDateTime value2 = new LocalDateTime.fromYMDHM(2011, 1, 2, 10, 30);
  LocalDateTime value3 = new LocalDateTime.fromYMDHM(2011, 1, 2, 10, 45);

  expect(value1.compareTo(value2), 0);
  expect(value1.compareTo(value3),  lessThan(0));
  expect(value3.compareTo(value2),  greaterThan(0));
}

@Test()
void CompareTo_DifferentCalendars_Throws()
{
  CalendarSystem islamic = CalendarSystem.GetIslamicCalendar(IslamicLeapYearPattern.Base15, IslamicEpoch.Astronomical);
  LocalDateTime value1 = new LocalDateTime.fromYMDHM(2011, 1, 2, 10, 30);
  LocalDateTime value2 = new LocalDateTime.fromYMDHMC(1500, 1, 1, 10, 30, islamic);

  expect(() => value1.compareTo(value2), throwsArgumentError);
  // expect(() => ((IComparable)value1).CompareTo(value2), throwsArgumentError);
}

/// <summary>
/// IComparable.CompareTo works properly for LocalDateTime inputs with different calendars.
/// </summary>
@Test()
void IComparableCompareTo_SameCalendar()
{
  LocalDateTime value1 = new LocalDateTime.fromYMDHM(2011, 1, 2, 10, 30);
  LocalDateTime value2 = new LocalDateTime.fromYMDHM(2011, 1, 2, 10, 30);
  LocalDateTime value3 = new LocalDateTime.fromYMDHM(2011, 1, 2, 10, 45);

  Comparable i_value1 = /*(IComparable)*/value1;
  Comparable i_value3 = /*(IComparable)*/value3;

  expect(i_value1.compareTo(value2), 0);
  expect(i_value1.compareTo(value3),  lessThan(0));
  expect(i_value3.compareTo(value2),  greaterThan(0));
}

/// <summary>
/// IComparable.CompareTo returns a positive number for a null input.
/// </summary>
@Test()
void IComparableCompareTo_Null_Positive()
{
  var instance = new LocalDateTime.fromYMDHM(2012, 3, 5, 10, 45);
  Comparable i_instance = /*(IComparable)*/instance;
  Object arg = null;
  var result = i_instance.compareTo(arg);
  expect(result,  greaterThan(0));
}

/// <summary>
/// IComparable.CompareTo throws an ArgumentException for non-null arguments
/// that are not a LocalDateTime.
/// </summary>
@Test()
void IComparableCompareTo_WrongType_ArgumentException()
{
  var instance = new LocalDateTime.fromYMDHM(2012, 3, 5, 10, 45);
  Comparable i_instance = /*(IComparable)*/instance;
  var arg = new LocalDate(2012, 3, 6);
  expect(() => i_instance.compareTo(arg), throwsArgumentError);
}

@Test()
void WithOffset()
{
  var offset = new Offset.fromHoursAndMinutes(5, 10);
  var localDateTime = new LocalDateTime.fromYMDHMS(2009, 12, 22, 21, 39, 30);
  var offsetDateTime = localDateTime.WithOffset(offset);
  expect(localDateTime, offsetDateTime.localDateTime);
  expect(offset, offsetDateTime.offset);
}

@Test()
void InUtc()
{
  var local = new LocalDateTime.fromYMDHMS(2009, 12, 22, 21, 39, 30);
  var zoned = local.InUtc();
  expect(local, zoned.localDateTime);
  expect(Offset.zero, zoned.offset);
  // Assert.AreSame(DateTimeZone.Utc, zoned.Zone);
  expect(identical(DateTimeZone.Utc, zoned.Zone), isTrue);
}

@Test()
void InZoneStrictly_InWinter()
{
  var local = new LocalDateTime.fromYMDHMS(2009, 12, 22, 21, 39, 30);
  var zoned = local.InZoneStrictly(Pacific);
  expect(local, zoned.localDateTime);
  expect(new Offset.fromHours(-8), zoned.offset);
}

@Test()
void InZoneStrictly_InSummer()
{
  var local = new LocalDateTime.fromYMDHMS(2009, 6, 22, 21, 39, 30);
  var zoned = local.InZoneStrictly(Pacific);
  expect(local, zoned.localDateTime);
  expect(new Offset.fromHours(-7), zoned.offset);
}

/// <summary>
/// Pacific time changed from -7 to -8 at 2am wall time on November 2nd 2009,
/// so 2am became 1am.
/// </summary>
@Test()
void InZoneStrictly_ThrowsWhenAmbiguous()
{
  var local = new LocalDateTime.fromYMDHMS(2009, 11, 1, 1, 30, 0);
  expect(() => local.InZoneStrictly(Pacific), throwsA(AmbiguousTimeError));
}

/// <summary>
/// Pacific time changed from -8 to -7 at 2am wall time on March 8th 2009,
/// so 2am became 3am. This means that 2.30am doesn't exist on that day.
/// </summary>
@Test()
void InZoneStrictly_ThrowsWhenSkipped()
{
  var local = new LocalDateTime.fromYMDHMS(2009, 3, 8, 2, 30, 0);
  expect(() => local.InZoneStrictly(Pacific), throwsA(SkippedTimeError));
}

/// <summary>
/// Pacific time changed from -7 to -8 at 2am wall time on November 2nd 2009,
/// so 2am became 1am. We'll return the earlier result, i.e. with the offset of -7
/// </summary>
@Test()
void InZoneLeniently_AmbiguousTime_ReturnsEarlierMapping()
{
  var local = new LocalDateTime.fromYMDHMS(2009, 11, 1, 1, 30, 0);
  var zoned = local.InZoneLeniently(Pacific);
  expect(local, zoned.localDateTime);
  expect(new Offset.fromHours(-7), zoned.offset);
}

/// <summary>
/// Pacific time changed from -8 to -7 at 2am wall time on March 8th 2009,
/// so 2am became 3am. This means that 2:30am doesn't exist on that day.
/// We'll return 3:30am, the forward-shifted value.
/// </summary>
@Test()
void InZoneLeniently_ReturnsStartOfSecondInterval()
{
  var local = new LocalDateTime.fromYMDHMS(2009, 3, 8, 2, 30, 0);
  var zoned = local.InZoneLeniently(Pacific);
  expect(new LocalDateTime.fromYMDHMS(2009, 3, 8, 3, 30, 0), zoned.localDateTime);
  expect(new Offset.fromHours(-7), zoned.offset);
}

@Test()
void InZone()
{
  // Don't need much for this - it only delegates.
  var ambiguous = new LocalDateTime.fromYMDHMS(2009, 11, 1, 1, 30, 0);
  var skipped = new LocalDateTime.fromYMDHMS(2009, 3, 8, 2, 30, 0);
  expect(Pacific.AtLeniently(ambiguous), ambiguous.InZone(Pacific, Resolvers.LenientResolver));
  expect(Pacific.AtLeniently(skipped), skipped.InZone(Pacific, Resolvers.LenientResolver));
}

/// <summary>
///   Using the default constructor is equivalent to January 1st 1970, midnight, UTC, ISO calendar
/// </summary>
@Test()
void DefaultConstructor()
{
  // todo: LocalDateTime()
  var actual = new LocalDateTime(new LocalDate(1, 1, 1), new LocalTime(0, 0));
  expect(new LocalDateTime.fromYMDHM(1, 1, 1, 0, 0), actual);
}

//@Test()
//void XmlSerialization_Iso()
//{
//  var value = new LocalDateTime.fromYMDHMS(2013, 4, 12, 17, 53, 23).PlusNanoseconds(123456789);
//  TestHelper.AssertXmlRoundtrip(value, "<value>2013-04-12T17:53:23.123456789</value>");
//}
//
//@Test()
//void BinarySerialization()
//{
//  TestHelper.AssertBinaryRoundtrip(new LocalDateTime.fromYMDHMSC(2013, 4, 12, 17, 53, 23, CalendarSystem.Julian));
//  TestHelper.AssertBinaryRoundtrip(new LocalDateTime.fromYMDHMS(2013, 4, 12, 17, 53, 23).PlusNanoseconds(123456789));
//}
//
//@Test()
//void XmlSerialization_NonIso()
//{
//  var value = new LocalDateTime.fromYMDHMSC(2013, 4, 12, 17, 53, 23, CalendarSystem.Julian);
//  TestHelper.AssertXmlRoundtrip(value, "<value calendar=\"Julian\">2013-04-12T17:53:23</value>");
//}
//
//@Test()
//@TestCase(const ["<value calendar=\"Rubbish\">2013-06-12T17:53:23</value>", typeof(KeyNotFoundException), Description = "Unknown calendar system"])
//@TestCase(const ["<value>2013-15-12T17:53:23</value>", typeof(UnparsableValueException), Description = "Invalid month"])
//void XmlSerialization_Invalid(string xml, Type expectedExceptionType)
//{
//  TestHelper.AssertXmlInvalid<LocalDateTime>(xml, expectedExceptionType);
//}

@Test()
void MinMax_DifferentCalendars_Throws()
{
  LocalDateTime ldt1 = new LocalDateTime.fromYMDHM(2011, 1, 2, 2, 20);
  LocalDateTime ldt2 = new LocalDateTime.fromYMDHMC(1500, 1, 1, 5, 10, CalendarSystem.Julian);

  expect(() => LocalDateTime.Max(ldt1, ldt2), throwsArgumentError);
  expect(() => LocalDateTime.Min(ldt1, ldt2), throwsArgumentError);
}

@Test()
void MinMax_SameCalendar()
{
  LocalDateTime ldt1 = new LocalDateTime.fromYMDHMC(1500, 1, 1, 7, 20, CalendarSystem.Julian);
  LocalDateTime ldt2 = new LocalDateTime.fromYMDHMC(1500, 1, 1, 5, 10, CalendarSystem.Julian);

  expect(ldt1, LocalDateTime.Max(ldt1, ldt2));
  expect(ldt1, LocalDateTime.Max(ldt2, ldt1));
  expect(ldt2, LocalDateTime.Min(ldt1, ldt2));
  expect(ldt2, LocalDateTime.Min(ldt2, ldt1));
}

//@Test()
//void Deconstruction()
//{
//  var value = new LocalDateTime.fromYMDHMS(2017, 10, 15, 21, 30, 0);
//  var expectedDate = new LocalDate(2017, 10, 15);
//  var expectedTime = new LocalTime(21, 30, 0);
//
//  var (actualDate, actualTime) = value;
//
//Assert.Multiple(() =>
//  {
//  expect(expectedDate, actualDate);
//  expect(expectedTime, actualTime);
//  });
//}

