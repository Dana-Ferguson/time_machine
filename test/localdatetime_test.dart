// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_for_vm.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import 'time_machine_testing.dart';

DateTimeZone Pacific; // = DateTimeZoneProviders.Tzdb["America/Los_Angeles"];

Future main() async {
  await TimeMachine.initialize();
  Pacific = await (await DateTimeZoneProviders.tzdb)["America/Los_Angeles"];
  await runTests();
}

@Test()
void ToDateTimeUnspecified()
{
  LocalDateTime zoned = new LocalDateTime.at(2011, 3, 5, 1, 0);
  DateTime expected = new DateTime(2011, 3, 5, 1, 0, 0); //, DateTimeKind.Unspecified);
  DateTime actual = zoned.toDateTimeLocal();
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
  var ldt = new LocalDateTime.at(year, 1, 1, 13, 15, seconds: 55).plusMilliseconds(TimeConstants.millisecondsPerSecond - 1); //.PlusNanoseconds(TimeConstants.nanosecondsPerSecond - 1);
  var expected = new DateTime(year, 1, 1, 13, 15, 55/*, DateTimeKind.Unspecified*/)
      .add(new Duration(milliseconds: TimeConstants.millisecondsPerSecond - 1));
  var actual = ldt.toDateTimeLocal();
  expect(actual, expected);
}

/* This works in dart:core (vs. BCL)
@Test()
void ToDateTimeUnspecified_OutOfRange()
{
  // One day before 1st January, 1AD (which is DateTime.MinValue)
  var ldt = new LocalDate(1, 1, 1).PlusDays(-1).AtMidnight;
  expect(() => ldt.ToDateTimeUnspecified(), throwsStateError);
}*/

@Test()
void FromDateTime()
{
  LocalDateTime expected = new LocalDateTime.at(2011, 08, 18, 20, 53);
  // for (DateTimeKind kind in Enum.GetValues(typeof(DateTimeKind)))
  DateTime x = new DateTime.utc(2011, 08, 18, 20, 53, 0); //, kind);
  LocalDateTime actual = new LocalDateTime.fromDateTime(x);
  expect(actual, expected);
}

@Test()
void FromDateTime_WithCalendar()
{
  // Julian calendar is 13 days behind Gregorian calendar in the 21st century
  LocalDateTime expected = new LocalDateTime.at(2011, 08, 05, 20, 53, calendar: CalendarSystem.julian);
// print('Expected day of year: ${expected.date.DaysSinceEpoch}');

  // todo: I don't understand what the test is doing here, this doesn't work with DateTime() local.
  //for (DateTimeKind kind in Enum.GetValues(typeof(DateTimeKind)))
  {
  DateTime x = new DateTime.utc(2011, 08, 18, 20, 53, 0); //, kind);
  LocalDateTime actual = new LocalDateTime.fromDateTime(x, CalendarSystem.julian);
  expect(actual, expected);
  }
}

@Test()
void TimeProperties_AfterEpoch()
{
  // Use the largest valid year as part of validating against overflow
  LocalDateTime ldt = new LocalDateTime.at(GregorianYearMonthDayCalculator.maxGregorianYear, 1, 2, 15, 48, seconds: 25).plusNanoseconds(123456789);
  expect(15, ldt.hour);
  expect(3, ldt.clockHourOfHalfDay);
  expect(48, ldt.minute);
  expect(25, ldt.second);
  expect(123, ldt.millisecond);
  expect(1234567, ldt.tickOfSecond);
  expect(15 * TimeConstants.ticksPerHour +
      48 * TimeConstants.ticksPerMinute +
      25 * TimeConstants.ticksPerSecond +
      1234567, ldt.tickOfDay);
  expect(15 * TimeConstants.nanosecondsPerHour +
      48 * TimeConstants.nanosecondsPerMinute +
      25 * TimeConstants.nanosecondsPerSecond +
      123456789, ldt.nanosecondOfDay);
  expect(123456789, ldt.nanosecondOfSecond);
}

@Test()
void TimeProperties_BeforeEpoch()
{
  // Use the smallest valid year number as part of validating against overflow
  LocalDateTime ldt = new LocalDateTime.at(GregorianYearMonthDayCalculator.minGregorianYear, 1, 2, 15, 48, seconds: 25).plusNanoseconds(123456789);
  expect(15, ldt.hour);
  expect(3, ldt.clockHourOfHalfDay);
  expect(48, ldt.minute);
  expect(25, ldt.second);
  expect(123, ldt.millisecond);
  expect(1234567, ldt.tickOfSecond);
  expect(15 * TimeConstants.ticksPerHour +
      48 * TimeConstants.ticksPerMinute +
      25 * TimeConstants.ticksPerSecond +
      1234567, ldt.tickOfDay);
  expect(15 * TimeConstants.nanosecondsPerHour +
      48 * TimeConstants.nanosecondsPerMinute +
      25 * TimeConstants.nanosecondsPerSecond +
      123456789, ldt.nanosecondOfDay);
  expect(123456789, ldt.nanosecondOfSecond);
}

@Test() @SkipMe.unimplemented()
void DateTime_Roundtrip_OtherCalendarInBcl()
{
  dynamic BclCalendars = null;
  var bcl = BclCalendars.Hijri;
  DateTime original = bcl.ToDateTime(1376, 6, 19, 0, 0, 0, 0);
  LocalDateTime noda = new LocalDateTime.fromDateTime(original);
  // The DateTime only knows about the ISO version...
  expect(1376, isNot(1376));
  expect(CalendarSystem.iso, noda.calendar);
  DateTime _final = noda.toDateTimeLocal();
  expect(original, _final);
}

@Test()
void WithCalendar()
{
  LocalDateTime isoEpoch = new LocalDateTime.at(1970, 1, 1, 0, 0);
  LocalDateTime julianEpoch = isoEpoch.withCalendar(CalendarSystem.julian);
  expect(1969, julianEpoch.year);
  expect(12, julianEpoch.month);
  expect(19, julianEpoch.day);
  expect(isoEpoch.time, julianEpoch.time);
}

// Verifies that negative local instant ticks don't cause a problem with the date
@Test()
void TimeOfDay_Before1970()
{
  LocalDateTime dateTime = new LocalDateTime.at(1965, 11, 8, 12, 5, seconds: 23);
  LocalTime expected = new LocalTime(12, 5, 23);
  expect(expected, dateTime.time);
}

// Verifies that positive local instant ticks don't cause a problem with the date
@Test()
void TimeOfDay_After1970()
{
  LocalDateTime dateTime = new LocalDateTime.at(1975, 11, 8, 12, 5, seconds: 23);
  LocalTime expected = new LocalTime(12, 5, 23);
  expect(expected, dateTime.time);
}

// Verifies that negative local instant ticks don't cause a problem with the date
@Test()
void Date_Before1970()
{
  LocalDateTime dateTime = new LocalDateTime.at(1965, 11, 8, 12, 5, seconds: 23);
  LocalDate expected = new LocalDate(1965, 11, 8);
  expect(expected, dateTime.date);
}

// Verifies that positive local instant ticks don't cause a problem with the date
@Test()
void Date_After1970()
{
  LocalDateTime dateTime = new LocalDateTime.at(1975, 11, 8, 12, 5, seconds: 23);
  LocalDate expected = new LocalDate(1975, 11, 8);
  expect(expected, dateTime.date);
}

@Test()
void DayOfWeek_AroundEpoch()
{
  // Test about couple of months around the Unix epoch. If that works, I'm confident the rest will.
  LocalDateTime dateTime = new LocalDateTime.at(1969, 12, 1, 0, 0);
  for (int i = 0; i < 60; i++)
  {
    // Check once per hour of the day, just in case something's messed up based on the time of day.
    for (int hour = 0; hour < 24; hour++)
    {
      expect(new IsoDayOfWeek(dateTime.toDateTimeLocal().weekday), dateTime.dayOfWeek);
      dateTime = dateTime.plusHours(1);
    }
  }
}

@Test()
void ClockHourOfHalfDay()
{
  expect(12, new LocalDateTime.at(1975, 11, 8, 0, 0).clockHourOfHalfDay);
  expect(1, new LocalDateTime.at(1975, 11, 8, 1, 0).clockHourOfHalfDay);
  expect(12, new LocalDateTime.at(1975, 11, 8, 12, 0).clockHourOfHalfDay);
  expect(1, new LocalDateTime.at(1975, 11, 8, 13, 0).clockHourOfHalfDay);
  expect(11, new LocalDateTime.at(1975, 11, 8, 23, 0).clockHourOfHalfDay);
}

@Test()
void Operators_SameCalendar()
{
  LocalDateTime value1 = new LocalDateTime.at(2011, 1, 2, 10, 30);
  LocalDateTime value2 = new LocalDateTime.at(2011, 1, 2, 10, 30);
  LocalDateTime value3 = new LocalDateTime.at(2011, 1, 2, 10, 45);
  TestHelper.TestOperatorComparisonEquality(value1, value2, [value3]);
}

@Test()
void Operators_DifferentCalendars_Throws()
{
  LocalDateTime value1 = new LocalDateTime.at(2011, 1, 2, 10, 30);
  LocalDateTime value2 = new LocalDateTime.at(2011, 1, 3, 10, 30, calendar: CalendarSystem.julian);

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
  LocalDateTime value1 = new LocalDateTime.at(2011, 1, 2, 10, 30);
  LocalDateTime value2 = new LocalDateTime.at(2011, 1, 2, 10, 30);
  LocalDateTime value3 = new LocalDateTime.at(2011, 1, 2, 10, 45);

  expect(value1.compareTo(value2), 0);
  expect(value1.compareTo(value3),  lessThan(0));
  expect(value3.compareTo(value2),  greaterThan(0));
}

@Test() @SkipMe.unimplemented()
void CompareTo_DifferentCalendars_Throws()
{
  dynamic IslamicLeapYearPattern = null;
  dynamic IslamicEpoch = null;

  CalendarSystem islamic = CalendarSystem.getIslamicCalendar(IslamicLeapYearPattern.Base15, IslamicEpoch.Astronomical);
  LocalDateTime value1 = new LocalDateTime.at(2011, 1, 2, 10, 30);
  LocalDateTime value2 = new LocalDateTime.at(1500, 1, 1, 10, 30, calendar: islamic);

  expect(() => value1.compareTo(value2), throwsArgumentError);
// expect(() => ((IComparable)value1).CompareTo(value2), throwsArgumentError);
}

/// IComparable.CompareTo works properly for LocalDateTime inputs with different calendars.
@Test()
void IComparableCompareTo_SameCalendar()
{
  LocalDateTime value1 = new LocalDateTime.at(2011, 1, 2, 10, 30);
  LocalDateTime value2 = new LocalDateTime.at(2011, 1, 2, 10, 30);
  LocalDateTime value3 = new LocalDateTime.at(2011, 1, 2, 10, 45);

  Comparable i_value1 = /*(IComparable)*/value1;
  Comparable i_value3 = /*(IComparable)*/value3;

  expect(i_value1.compareTo(value2), 0);
  expect(i_value1.compareTo(value3),  lessThan(0));
  expect(i_value3.compareTo(value2),  greaterThan(0));
}

/// IComparable.CompareTo returns a positive number for a null input.
@Test()
void IComparableCompareTo_Null_Positive()
{
  var instance = new LocalDateTime.at(2012, 3, 5, 10, 45);
  Comparable i_instance = /*(IComparable)*/instance;
  Object arg = null;
  var result = i_instance.compareTo(arg);
  expect(result,  greaterThan(0));
}

/// IComparable.CompareTo throws an ArgumentException for non-null arguments
/// that are not a LocalDateTime.
@Test()
void IComparableCompareTo_WrongType_ArgumentException()
{
  var instance = new LocalDateTime.at(2012, 3, 5, 10, 45);
  Comparable i_instance = /*(IComparable)*/instance;
  var arg = new LocalDate(2012, 3, 6);
  expect(() => i_instance.compareTo(arg), willThrow<TypeError>());
}

@Test()
void WithOffset()
{
  var offset = new Offset.fromHoursAndMinutes(5, 10);
  var localDateTime = new LocalDateTime.at(2009, 12, 22, 21, 39, seconds: 30);
  var offsetDateTime = localDateTime.withOffset(offset);
  expect(localDateTime, offsetDateTime.localDateTime);
  expect(offset, offsetDateTime.offset);
}

@Test()
void InUtc()
{
  var local = new LocalDateTime.at(2009, 12, 22, 21, 39, seconds: 30);
  var zoned = local.inUtc();
  expect(local, zoned.localDateTime);
  expect(Offset.zero, zoned.offset);
  // Assert.AreSame(DateTimeZone.Utc, zoned.Zone);
  expect(identical(DateTimeZone.utc, zoned.zone), isTrue);
}

@Test()
void InZoneStrictly_InWinter()
{
  var local = new LocalDateTime.at(2009, 12, 22, 21, 39, seconds: 30);
  var zoned = local.inZoneStrictly(Pacific);
  expect(local, zoned.localDateTime);
  expect(new Offset.fromHours(-8), zoned.offset);
}

@Test()
void InZoneStrictly_InSummer()
{
  var local = new LocalDateTime.at(2009, 6, 22, 21, 39, seconds: 30);
  var zoned = local.inZoneStrictly(Pacific);
  expect(local, zoned.localDateTime);
  expect(new Offset.fromHours(-7), zoned.offset);
}

/// Pacific time changed from -7 to -8 at 2am wall time on November 2nd 2009,
/// so 2am became 1am.
@Test()
void InZoneStrictly_ThrowsWhenAmbiguous()
{
  var local = new LocalDateTime.at(2009, 11, 1, 1, 30);
  expect(() => local.inZoneStrictly(Pacific), willThrow<AmbiguousTimeError>());
}

/// Pacific time changed from -8 to -7 at 2am wall time on March 8th 2009,
/// so 2am became 3am. This means that 2.30am doesn't exist on that day.
@Test()
void InZoneStrictly_ThrowsWhenSkipped()
{
  var local = new LocalDateTime.at(2009, 3, 8, 2, 30);
  expect(() => local.inZoneStrictly(Pacific), willThrow<SkippedTimeError>());
}

/// Pacific time changed from -7 to -8 at 2am wall time on November 2nd 2009,
/// so 2am became 1am. We'll return the earlier result, i.e. with the offset of -7
@Test()
void InZoneLeniently_AmbiguousTime_ReturnsEarlierMapping()
{
  var local = new LocalDateTime.at(2009, 11, 1, 1, 30);
  var zoned = local.inZoneLeniently(Pacific);
  expect(local, zoned.localDateTime);
  expect(new Offset.fromHours(-7), zoned.offset);
}

/// Pacific time changed from -8 to -7 at 2am wall time on March 8th 2009,
/// so 2am became 3am. This means that 2:30am doesn't exist on that day.
/// We'll return 3:30am, the forward-shifted value.
@Test()
void InZoneLeniently_ReturnsStartOfSecondInterval()
{
  var local = new LocalDateTime.at(2009, 3, 8, 2, 30);
  var zoned = local.inZoneLeniently(Pacific);
  expect(new LocalDateTime.at(2009, 3, 8, 3, 30), zoned.localDateTime);
  expect(new Offset.fromHours(-7), zoned.offset);
}

@Test()
void InZone()
{
  // Don't need much for this - it only delegates.
  var ambiguous = new LocalDateTime.at(2009, 11, 1, 1, 30);
  var skipped = new LocalDateTime.at(2009, 3, 8, 2, 30);
  expect(Pacific.atLeniently(ambiguous), ambiguous.inZone(Pacific, Resolvers.lenientResolver));
  expect(Pacific.atLeniently(skipped), skipped.inZone(Pacific, Resolvers.lenientResolver));
}

///   Using the default constructor is equivalent to January 1st 1970, midnight, UTC, ISO calendar
@Test()
void DefaultConstructor()
{
  // todo: LocalDateTime()
  var actual = new LocalDateTime(new LocalDate(1, 1, 1), new LocalTime(0, 0));
  expect(new LocalDateTime.at(1, 1, 1, 0, 0), actual);
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
  LocalDateTime ldt1 = new LocalDateTime.at(2011, 1, 2, 2, 20);
  LocalDateTime ldt2 = new LocalDateTime.at(1500, 1, 1, 5, 10, calendar: CalendarSystem.julian);

  expect(() => LocalDateTime.max(ldt1, ldt2), throwsArgumentError);
  expect(() => LocalDateTime.min(ldt1, ldt2), throwsArgumentError);
}

@Test()
void MinMax_SameCalendar()
{
  LocalDateTime ldt1 = new LocalDateTime.at(1500, 1, 1, 7, 20, calendar: CalendarSystem.julian);
  LocalDateTime ldt2 = new LocalDateTime.at(1500, 1, 1, 5, 10, calendar: CalendarSystem.julian);

  expect(ldt1, LocalDateTime.max(ldt1, ldt2));
  expect(ldt1, LocalDateTime.max(ldt2, ldt1));
  expect(ldt2, LocalDateTime.min(ldt1, ldt2));
  expect(ldt2, LocalDateTime.min(ldt2, ldt1));
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


