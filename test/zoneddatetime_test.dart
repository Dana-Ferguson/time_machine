// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

import 'time_machine_testing.dart';

Future main() async {
  await TimeMachine.initialize();
  await runTests();
}

/// Changes from UTC+3 to UTC+4 at 1am local time on June 13th 2011.
final SingleTransitionDateTimeZone SampleZone = SingleTransitionDateTimeZone.around(Instant.utc(2011, 6, 12, 22, 0), 3, 4);

@Test()
void SimpleProperties()
{
  var value = ZonedDateTime.atStrictly(LocalDateTime(2012, 2, 10, 8, 9, 10).addNanoseconds(123456789), SampleZone);
  expect(LocalDate(2012, 2, 10), value.calendarDate);
  expect(LocalTime(8, 9, 10, ns: 123456789), value.clockTime);
  expect(Era.common, value.era);
  expect(2012, value.year);
  expect(2012, value.yearOfEra);
  expect(2, value.monthOfYear);
  expect(10, value.dayOfMonth);
  expect(DayOfWeek.friday, value.dayOfWeek);
  expect(41, value.dayOfYear);
  expect(8, value.hourOf12HourClock);
  expect(8, value.hourOfDay);
  expect(9, value.minuteOfHour);
  expect(10, value.secondOfMinute);
  expect(123, value.millisecondOfSecond);
  expect(123456/*7*/, value.microsecondOfSecond);
  expect(8 * TimeConstants.microsecondsPerHour +
      9 * TimeConstants.microsecondsPerMinute +
      10 * TimeConstants.microsecondsPerSecond +
      123456/*7*/,
      value.clockTime.timeSinceMidnight.inMicroseconds);
  expect(8 * TimeConstants.nanosecondsPerHour +
      9 * TimeConstants.nanosecondsPerMinute +
      10 * TimeConstants.nanosecondsPerSecond +
      123456789,
      value.clockTime.timeSinceMidnight.inNanoseconds);
}

@Test()
void Add_AroundTimeZoneTransition()
{
  // Before the transition at 3pm...
  ZonedDateTime before = ZonedDateTime.atStrictly(LocalDateTime(2011, 6, 12, 15, 0, 0), SampleZone);
  // 24 hours elapsed, and it's 4pm
  ZonedDateTime afterExpected = ZonedDateTime.atStrictly(LocalDateTime(2011, 6, 13, 16, 0, 0), SampleZone);
  ZonedDateTime afterAdd = ZonedDateTime.plus(before, Time.oneDay);
  ZonedDateTime afterOperator = before + Time.oneDay;

  expect(afterExpected, afterAdd);
  expect(afterExpected, afterOperator);
}

@Test()
void Add_MethodEquivalents()
{
  const int minutes = 23;
  const int hours = 3;
  const int milliseconds = 40000;
  const int seconds = 321;
  const int nanoseconds = 12345;
  const int ticks = 5432112345;

  ZonedDateTime before = ZonedDateTime.atStrictly(LocalDateTime(2011, 6, 12, 15, 0, 0), SampleZone);
  expect(before + Time.oneDay, ZonedDateTime.plus(before, Time.oneDay));
  expect(before + Time.oneDay, before.add(Time.oneDay));

  expect(before + Time(hours: hours), before.add(Time(hours: hours)));
  expect(before + Time(hours: -hours), before.add(Time(hours: -hours)));

  expect(before + Time(minutes: minutes), before.add(Time(minutes: minutes)));
  expect(before + Time(minutes: -minutes), before.add(Time(minutes: -minutes)));

  expect(before + Time(seconds: seconds), before.add(Time(seconds: seconds)));
  expect(before + Time(seconds: -seconds), before.add(Time(seconds: -seconds)));

  expect(before + Time(milliseconds: milliseconds), before.add(Time(milliseconds: milliseconds)));
  expect(before + Time(milliseconds: -milliseconds), before.add(Time(milliseconds: -milliseconds)));

  expect(before + Time(microseconds: ticks), before.add(Time(microseconds: ticks)));
  expect(before + Time(microseconds: -ticks), before.add(Time(microseconds: -ticks)));

  expect(before + Time(nanoseconds: nanoseconds), before.add(Time(nanoseconds: nanoseconds)));
  expect(before + Time(nanoseconds: -nanoseconds), before.add(Time(nanoseconds: -nanoseconds)));
  /*
  expect(before + new Time(hours: hours), before.plusHours(hours));
  expect(before + new Time(hours: -hours), before.plusHours(-hours));

  expect(before + new Time(minutes: minutes), before.plusMinutes(minutes));
  expect(before + new Time(minutes: -minutes), before.plusMinutes(-minutes));

  expect(before + new Time(seconds: seconds), before.plusSeconds(seconds));
  expect(before + new Time(seconds: -seconds), before.plusSeconds(-seconds));

  expect(before + new Time(milliseconds: milliseconds), before.plusMilliseconds(milliseconds));
  expect(before + new Time(milliseconds: -milliseconds), before.plusMilliseconds(-milliseconds));

  expect(before + new Time(microseconds: ticks), before.plusMicroseconds(ticks));
  expect(before + new Time(microseconds: -ticks), before.plusMicroseconds(-ticks));

  expect(before + new Time(nanoseconds: nanoseconds), before.plusNanoseconds(nanoseconds));
  expect(before + new Time(nanoseconds: -nanoseconds), before.plusNanoseconds(-nanoseconds));
  */
}

@Test()
void Subtract_AroundTimeZoneTransition()
{
  // After the transition at 4pm...
  ZonedDateTime after = ZonedDateTime.atStrictly(LocalDateTime(2011, 6, 13, 16, 0, 0), SampleZone);
  // 24 hours earlier, and it's 3pm
  ZonedDateTime beforeExpected = ZonedDateTime.atStrictly(LocalDateTime(2011, 6, 12, 15, 0, 0), SampleZone);
  ZonedDateTime beforeSubtract = ZonedDateTime.minus(after, Time.oneDay);
  ZonedDateTime beforeOperator = after - Time.oneDay;

  expect(beforeExpected, beforeSubtract);
  expect(beforeExpected, beforeOperator);
}

@Test()
void SubtractDuration_MethodEquivalents()
{
  ZonedDateTime after = ZonedDateTime.atStrictly(LocalDateTime(2011, 6, 13, 16, 0, 0), SampleZone);
  expect(after - Time.oneDay, ZonedDateTime.minus(after, Time.oneDay));
  expect(after - Time.oneDay, after.subtract(Time.oneDay));
}

@Test()
void Subtraction_ZonedDateTime()
{
  // Test all three approaches... not bothering to check a different calendar,
  // but we'll use two different time zones.
  ZonedDateTime start = LocalDateTime(2014, 08, 14, 5, 51, 0).inUtc();
  // Sample zone is UTC+4 at this point, so this is 14:00Z.
  ZonedDateTime end = ZonedDateTime.atStrictly(LocalDateTime(2014, 08, 14, 18, 0, 0), SampleZone);
  Time expected = Time(hours: 8) + Time(minutes: 9);
  // expect(expected, end - start);
  expect(expected, end.timeSince(start));
  expect(expected, ZonedDateTime.difference(end, start));
}

@Test()
void WithZone()
{
  Instant instant = Instant.utc(2012, 2, 4, 12, 35);
  ZonedDateTime zoned = ZonedDateTime(instant, SampleZone);
  expect(LocalDateTime(2012, 2, 4, 16, 35, 0), zoned.localDateTime);

  // Will be UTC-8 for our instant.
  DateTimeZone newZone = SingleTransitionDateTimeZone.around(Instant.utc(2000, 1, 1, 0, 0), -7, -8);
  ZonedDateTime converted = zoned.withZone(newZone);
  expect(LocalDateTime(2012, 2, 4, 4, 35, 0), converted.localDateTime);
  expect(converted.toInstant(), instant);
}

@Test()
Future IsDaylightSavings() async
{
  // Use a real time zone rather than a single-transition zone, so that we can get
  // a savings offset.
  var zone = await (await DateTimeZoneProviders.tzdb)['Europe/London'];
  var winterSummerTransition = Instant.utc(2014, 3, 30, 1, 0);
  var winter = (winterSummerTransition - Time.epsilon).inZone(zone);
  var summer = winterSummerTransition.inZone(zone);
  expect(winter.isDaylightSavingTime(), isFalse);
  expect(summer.isDaylightSavingTime(), isTrue);
}
/* -- BCL Types we don't have
@Test()
void FromDateTimeOffset()
{
  DateTimeOffset dateTimeOffset = new DateTimeOffset(2011, 3, 5, 1, 0, 0, TimeSpan.FromHours(3));
  DateTimeZone fixedZone = new FixedDateTimeZone(new Offset.fromHours(3));
  ZonedDateTime expected = fixedZone.AtStrictly(new LocalDateTime.fromYMDHMS(2011, 3, 5, 1, 0, 0));
  ZonedDateTime actual = ZonedDateTime.FromDateTimeOffset(dateTimeOffset);
  expect(expected, actual);
}

@Test()
void ToDateTimeOffset()
{
  ZonedDateTime zoned = SampleZone.AtStrictly(new LocalDateTime.fromYMDHMS(2011, 3, 5, 1, 0, 0));
  DateTimeOffset expected = new DateTimeOffset(2011, 3, 5, 1, 0, 0, TimeSpan.FromHours(3));
  DateTimeOffset actual = zoned.ToDateTimeOffset();
  expect(expected, actual);
}

@Test()
@TestCase(const [0, 30, 20])
@TestCase(const [-1, -30, -20])
@TestCase(const [0, 30, 55])
@TestCase(const [-1, -30, -55])
void ToDateTimeOffset_TruncatedOffset(int hours, int minutes, int seconds)
{
  var ldt = new LocalDateTime.fromYMDHMS(2017, 1, 9, 21, 45, 20);
  var offset = Offset.FromHoursAndMinutes(hours, minutes).Plus(new Offset.fromSeconds(seconds));
  var zone = DateTimeZone.ForOffset(offset);
  var zdt = ldt.InZoneStrictly(zone);
  var dto = zdt.ToDateTimeOffset();
  // We preserve the local date/time, so the instant will move forward as the offset
  // is truncated.
  expect(new DateTime(2017, 1, 9, 21, 45, 20, DateTimeKind.Unspecified), dto.DateTime);
  expect(TimeSpan.FromHours(hours) + TimeSpan.FromMinutes(minutes), dto.offset);
}

@Test()
@TestCase(const [-15])
@TestCase(const [15])
void ToDateTimeOffset_OffsetOutOfRange(int hours)
{
  var ldt = new LocalDateTime.fromYMDHMS(2017, 1, 9, 21, 45, 20);
  var offset = new Offset.fromHours(hours);
  var zone = DateTimeZone.ForOffset(offset);
  var zdt = ldt.InZoneStrictly(zone);
  expect(() => zdt.ToDateTimeOffset(), throwsStateError);
}

@Test()
@TestCase(const [-14])
@TestCase(const [14])
void ToDateTimeOffset_OffsetEdgeOfRange(int hours)
{
  var ldt = new LocalDateTime.fromYMDHMS(2017, 1, 9, 21, 45, 20);
  var offset = new Offset.fromHours(hours);
  var zone = DateTimeZone.ForOffset(offset);
  var zdt = ldt.InZoneStrictly(zone);
  expect(hours, zdt.ToDateTimeOffset().offset.TotalHours);
}

@Test()
void ToBclTypes_DateOutOfRange()
{
  // One day before 1st January, 1AD (which is DateTime.MinValue)
  var offset = new Offset.fromHours(1);
  var zone = DateTimeZone.ForOffset(offset);
  var odt = new LocalDate(1, 1, 1).PlusDays(-1).AtMidnight().InZoneStrictly(zone);
  expect(() => odt.ToDateTimeOffset(), throwsStateError);
  expect(() => odt.ToDateTimeUnspecified(), throwsStateError);
  expect(() => odt.ToDateTimeUtc(), throwsStateError);
}

@Test()
@TestCase(const [100])
@TestCase(const [1900])
@TestCase(const [2900])
void ToBclTypes_TruncateNanosTowardStartOfTime(int year)
{
  var zone = DateTimeZone.ForOffset(new Offset.fromHours(1));
  var zdt = new LocalDateTime(year, 1, 1, 13, 15, 55).PlusNanoseconds(TimeConstants.nanosecondsPerSecond - 1)
      .InZoneStrictly(zone);
  var expectedDateTimeUtc = new DateTime(year, 1, 1, 12, 15, 55, DateTimeKind.Utc)
      .AddTicks(TimeConstants.ticksPerSecond - 1);
  var actualDateTimeUtc = zdt.ToDateTimeUtc();
  expect(expectedDateTimeUtc, actualDateTimeUtc);
  var expectedDateTimeOffset = new DateTimeOffset(year, 1, 1, 13, 15, 55, TimeSpan.FromHours(1))
      .AddTicks(TimeConstants.ticksPerSecond - 1);
  var actualDateTimeOffset = zdt.ToDateTimeOffset();
  expect(expectedDateTimeOffset, actualDateTimeOffset);
}
*/
@Test()
void ToDateTimeUtc()
{
  ZonedDateTime zoned = ZonedDateTime.atStrictly(LocalDateTime(2011, 3, 5, 1, 0, 0), SampleZone);
  // Note that this is 10pm the previous day, UTC - so 1am local time
  DateTime expected = DateTime.utc(2011, 3, 4, 22, 0, 0);
  DateTime actual = zoned.toDateTimeUtc();
  expect(expected, actual);
  // Kind isn't checked by Equals...
  expect(actual.isUtc, isTrue);
}

@Test()
void ToDateTimeUtc_InRangeAfterUtcAdjustment()
{
  var zone = DateTimeZone.forOffset(Offset.hours(-1));
  var zdt = LocalDateTime(0, 12, 31, 23, 30, 0).inZoneStrictly(zone);
  // Sanity check: without reversing the offset, we're out of range
  // ToDateTimeUnspecified() works in dart:core
  // expect(() => zdt.ToDateTimeUnspecified(), throwsStateError);
  // expect(() => zdt.ToDateTimeOffset(), throwsStateError);
  var expected = DateTime.utc(1, 1, 1, 0, 30, 0);
  var actual = zdt.toDateTimeUtc();
  expect(expected, actual);
}

@Test()
void ToDateTimeUnspecified()
{
  ZonedDateTime zoned = ZonedDateTime.atStrictly(LocalDateTime(2011, 3, 5, 1, 0, 0), SampleZone);
  DateTime expected = DateTime(2011, 3, 5, 1, 0, 0);
  DateTime actual = zoned.toDateTimeLocal();
  expect(actual, expected);
  // Kind isn't checked by Equals...
  expect(actual.isUtc, isFalse); // DateTimeKind.Unspecified, actual.Kind);
}

@Test()
void ToOffsetDateTime()
{
  var local = LocalDateTime(1911, 3, 5, 1, 0, 0); // Early interval
  var zoned = ZonedDateTime.atStrictly(local, SampleZone);
  var offsetDateTime = zoned.toOffsetDateTime();
  expect(local, offsetDateTime.localDateTime);
  expect(SampleZone.EarlyInterval.wallOffset, offsetDateTime.offset);
}

@Test()
void Equality()
{
  // Goes back from 2am to 1am on June 13th
  SingleTransitionDateTimeZone zone = SingleTransitionDateTimeZone.around(Instant.utc(2011, 6, 12, 22, 0), 4, 3);
  var sample = zone.mapLocal(LocalDateTime(2011, 6, 13, 1, 30, 0)).first();
  var fromUtc = Instant.utc(2011, 6, 12, 21, 30).inZone(zone);

  // Checks all the overloads etc: first check is that the zone matters
  TestHelper.TestEqualsStruct(sample, fromUtc, [Instant.utc(2011, 6, 12, 21, 30).inUtc()]);
  TestHelper.TestOperatorEquality(sample, fromUtc, [Instant.utc(2011, 6, 12, 21, 30).inUtc()]);

// Now just use a simple inequality check for other aspects...

  // Different offset
  var later = zone.mapLocal(LocalDateTime(2011, 6, 13, 1, 30, 0)).last();
  expect(sample.localDateTime, later.localDateTime);
  expect(sample.offset, isNot(later.offset));
  expect(sample, isNot(later));

  // Different local time
  expect(sample, isNot(zone.mapLocal(LocalDateTime(2011, 6, 13, 1, 19, 0)).first()));

  // Different calendar
  var withOtherCalendar = zone.mapLocal(LocalDateTime(2011, 6, 13, 1, 30, 0, calendar: CalendarSystem.gregorian)).first();
  expect(sample, isNot(withOtherCalendar));
}

/* These no longer throw argument errors, since we combined constructors and nulls have default
@Test()
void Constructor_ArgumentValidation()
{
  // This first one passes b/c of how we implemented the default constructor, now defaults to CalendarSystem.Iso
  // expect(() => new ZonedDateTime(new Instant.fromUnixTimeTicks(1000), null), throwsArgumentError);
  expect(() => new ZonedDateTime(new Instant.fromUnixTimeTicks(1000), null, CalendarSystem.iso), throwsArgumentError);
  expect(() => new ZonedDateTime(new Instant.fromUnixTimeTicks(1000), SampleZone, null), throwsArgumentError);
}*/

@Test()
void Construct_FromLocal_ValidUnambiguousOffset()
{
  SingleTransitionDateTimeZone zone = SingleTransitionDateTimeZone.around(Instant.utc(2011, 6, 12, 22, 0), 4, 3);

  LocalDateTime local = LocalDateTime(2000, 1, 2, 3, 4, 5);
  ZonedDateTime zoned = ZonedDateTime.atOffset(local, zone, zone.EarlyInterval.wallOffset);
  expect(zoned, local.inZoneStrictly(zone));
}

@Test()
void Construct_FromLocal_ValidEarlierOffset()
{
  SingleTransitionDateTimeZone zone = SingleTransitionDateTimeZone.around(Instant.utc(2011, 6, 12, 22, 0), 4, 3);

  LocalDateTime local = LocalDateTime(2011, 6, 13, 1, 30, 0);
  ZonedDateTime zoned = ZonedDateTime.atOffset(local, zone, zone.EarlyInterval.wallOffset);

  // Map the local time to the earlier of the offsets in a way which is tested elsewhere.
  var resolver = Resolvers.createMappingResolver(Resolvers.returnEarlier, Resolvers.throwWhenSkipped);
  expect(zoned, local.inZone(zone, resolver));
}

@Test()
void Construct_FromLocal_ValidLaterOffset()
{
  SingleTransitionDateTimeZone zone = SingleTransitionDateTimeZone.around(Instant.utc(2011, 6, 12, 22, 0), 4, 3);

  LocalDateTime local = LocalDateTime(2011, 6, 13, 1, 30, 0);
  ZonedDateTime zoned = ZonedDateTime.atOffset(local, zone, zone.LateInterval.wallOffset);

  // Map the local time to the later of the offsets in a way which is tested elsewhere.
  var resolver = Resolvers.createMappingResolver(Resolvers.returnLater, Resolvers.throwWhenSkipped);
  expect(zoned, local.inZone(zone, resolver));
}

@Test()
void Construct_FromLocal_InvalidOffset()
{
  SingleTransitionDateTimeZone zone = SingleTransitionDateTimeZone.around(Instant.utc(2011, 6, 12, 22, 0), 4, 3);

  // Attempt to ask for the later offset in the earlier interval
  LocalDateTime local = LocalDateTime(2000, 1, 1, 0, 0, 0);
  expect(() => ZonedDateTime.atOffset(local, zone, zone.LateInterval.wallOffset), throwsArgumentError);
}

///   Using the default constructor is equivalent to January 1st 1970, midnight, UTC, ISO calendar
@Test()
void DefaultConstructor()
{
  // Note: The test documentation says this should be January 1st 1970, but the actual test
  // checks for '0001-01-01T00:00:00 UTC (+00)' -- we're going to differ from NodaTime's implementation here
  // and go with the test documentation.
  var actual = ZonedDateTime();
  expect(LocalDateTime(1970, 1, 1, 0, 0, 0), actual.localDateTime);
  expect(Offset.zero, actual.offset);
  expect(DateTimeZone.utc, actual.zone);
}

/*
@Test()
void BinarySerialization_Iso()
{
  DateTimeZoneProviders.Serialization = DateTimeZoneProviders.Tzdb;
  var zone = DateTimeZoneProviders.Tzdb['America/New_York'];
  var value = new ZonedDateTime(new LocalDateTime.fromYMDHMS(2013, 4, 12, 17, 53, 23).WithOffset(new Offset.fromHours(-4)), zone);
  TestHelper.AssertBinaryRoundtrip(value);
}

@Test()
void XmlSerialization_Iso()
{
  DateTimeZoneProviders.Serialization = DateTimeZoneProviders.Tzdb;
  var zone = DateTimeZoneProviders.Tzdb['America/New_York'];
  var value = new ZonedDateTime(new LocalDateTime.fromYMDHMS(2013, 4, 12, 17, 53, 23).WithOffset(new Offset.fromHours(-4)), zone);
  TestHelper.AssertXmlRoundtrip(value, "<value zone=\"America/New_York\">2013-04-12T17:53:23-04</value>");
}

#if !NETCORE
@Test()
void XmlSerialization_Bcl()
{
  // Skip this on Mono, which will have different BCL time zones. We can't easily
  // guess which will be available :(
  if (!TestHelper.IsRunningOnMono)
  {
    DateTimeZoneProviders.Serialization = DateTimeZoneProviders.Bcl;
    var zone = DateTimeZoneProviders.Bcl['Eastern Standard Time'];
    var value = new ZonedDateTime(new LocalDateTime.fromYMDHMS(2013, 4, 12, 17, 53, 23).WithOffset(new Offset.fromHours(-4)), zone);
    TestHelper.AssertXmlRoundtrip(value, "<value zone=\"Eastern Standard Time\">2013-04-12T17:53:23-04</value>");
  }
}

@Test()
void BinarySerialization_Bcl()
{
  // Skip this on Mono, which will have different BCL time zones. We can't easily
  // guess which will be available :(
  if (!TestHelper.IsRunningOnMono)
  {
    DateTimeZoneProviders.Serialization = DateTimeZoneProviders.Bcl;
    var zone = DateTimeZoneProviders.Bcl['Eastern Standard Time'];
    var value = new ZonedDateTime(new LocalDateTime.fromYMDHMS(2013, 4, 12, 17, 53, 23).WithOffset(new Offset.fromHours(-4)), zone);
    TestHelper.AssertBinaryRoundtrip(value);
  }
}
#endif

@Test()
void XmlSerialization_NonIso()
{
  DateTimeZoneProviders.Serialization = DateTimeZoneProviders.Tzdb;
  var zone = DateTimeZoneProviders.Tzdb['America/New_York'];
  var localDateTime = new LocalDateTime.fromYMDHMSC(2013, 6, 12, 17, 53, 23, CalendarSystem.Julian);
  var value = new ZonedDateTime(localDateTime.WithOffset(new Offset.fromHours(-4)), zone);
  TestHelper.AssertXmlRoundtrip(value,
      "<value zone=\"America/New_York\" calendar=\"Julian\">2013-06-12T17:53:23-04</value>");
}

@Test()
void BinarySerialization_NonIso()
{
  DateTimeZoneProviders.Serialization = DateTimeZoneProviders.Tzdb;
  var zone = DateTimeZoneProviders.Tzdb['America/New_York'];
  var localDateTime = new LocalDateTime.fromYMDHMSC(2013, 6, 12, 17, 53, 23, CalendarSystem.Julian);
  var value = new ZonedDateTime(localDateTime.WithOffset(new Offset.fromHours(-4)), zone);
  TestHelper.AssertBinaryRoundtrip(value);
}

#if !NETCORE

@Test()
@TestCase(const [typeof(ArgumentException), 10000, 8, 25, 0L, 0, 60, 'Europe/London'])
@TestCase(const [typeof(ArgumentException), 2017, 8, 25, 0L, 0, 60, 'Europe/London'])
@TestCase(const [typeof(ArgumentException), 2017, 13, 25, 0L, 0, 60, 'Europe/London'])
@TestCase(const [typeof(ArgumentException), 2017, 8, 32, 0L, 0, 60, 'Europe/London'])
@TestCase(const [typeof(ArgumentException), 2017, 8, 25, -1L, 0, 60, 'Europe/London'])
@TestCase(const [typeof(ArgumentException), 2017, 8, 25, 0L, -1, 60, 'Europe/London', Description = "Invalid calendar ordinal"])
@TestCase(const [typeof(ArgumentException), 2017, 8, 25, 0L, 0, 120, 'Europe/London', Description = "Wrong offset"])
@TestCase(const [typeof(TimeZoneNotFoundException), 2017, 8, 25, 0L, 0, 120, 'Europe/NotLondon', Description = "Unknown zone ID"])
void InvalidBinaryData(Type expectedExceptionType, int year, int month, int day, int nanosecondOfDay, int calendarOrdinal, int offsetSeconds, string zoneId)
{
  DateTimeZoneProviders.Serialization = DateTimeZoneProviders.Tzdb;
  TestHelper.AssertBinaryDeserializationFailure<ZonedDateTime>(expectedExceptionType, info =>
      {
      info.AddValue(BinaryFormattingConstants.YearSerializationName, year);
      info.AddValue(BinaryFormattingConstants.MonthSerializationName, month);
      info.AddValue(BinaryFormattingConstants.DaySerializationName, day);
      info.AddValue(BinaryFormattingConstants.NanoOfDaySerializationName, nanosecondOfDay);
      info.AddValue(BinaryFormattingConstants.CalendarSerializationName, calendarOrdinal);
      info.AddValue(BinaryFormattingConstants.offsetSecondsSerializationName, offsetSeconds);
      info.AddValue(BinaryFormattingConstants.ZoneIdSerializationName, zoneId);
      });
}
#endif

@Test()
@TestCase(const ["<value zone=\"America/New_York\" calendar=\"Rubbish\">2013-06-12T17:53:23-04</value>", typeof(KeyNotFoundException), Description = "Unknown calendar system"])
@TestCase(const ['<value>2013-04-12T17:53:23-04</value>', typeof(ArgumentException), Description = "No zone"])
@TestCase(const ["<value zone=\"Unknown\">2013-04-12T17:53:23-04</value>", typeof(DateTimeZoneNotFoundException), Description = "Unknown zone"])
@TestCase(const ["<value zone=\"Europe/London\">2013-04-12T17:53:23-04</value>", typeof(UnparsableValueException), Description = "Incorrect offset"])
void XmlSerialization_Invalid(string xml, Type expectedExceptionType)
{
  DateTimeZoneProviders.Serialization = DateTimeZoneProviders.Tzdb;
  TestHelper.AssertXmlInvalid<ZonedDateTime>(xml, expectedExceptionType);
}
*/

@Test()
void ZonedDateTime_ToString()
{
  var local = LocalDateTime(2013, 7, 23, 13, 05, 20);
  ZonedDateTime zoned = local.inZoneStrictly(SampleZone);
  expect('2013-07-23T13:05:20 Single (+04)', zoned.toString());
}

@Test()
void ZonedDateTime_ToString_WithFormat()
{
  var local = LocalDateTime(2013, 7, 23, 13, 05, 20);
  ZonedDateTime zoned = local.inZoneStrictly(SampleZone);
  expect('2013/07/23 13:05:20 Single', zoned.toString("yyyy/MM/dd HH:mm:ss z", Culture.invariant));
}

@Test()
Future LocalComparer() async
{
  var london = await (await DateTimeZoneProviders.tzdb)['Europe/London'];
  var losAngeles = await (await DateTimeZoneProviders.tzdb)['America/Los_Angeles'];

  // LA is 8 hours behind London. So the London evening occurs before the LA afternoon.
  var londonEvening = LocalDateTime(2014, 7, 9, 20, 32, 0).inZoneStrictly(london);
  var losAngelesAfternoon = LocalDateTime(2014, 7, 9, 14, 0, 0).inZoneStrictly(losAngeles);

  // Same local time as losAngelesAfternoon
  var londonAfternoon = losAngelesAfternoon.localDateTime.inZoneStrictly(london);

  var londonPersian = londonEvening.localDateTime
      .withCalendar(CalendarSystem.persianSimple)
      .inZoneStrictly(london);

  var comparer = ZonedDateTimeComparer.local;
  TestHelper.TestComparerStruct(comparer.compare, losAngelesAfternoon, londonAfternoon, londonEvening);
  expect(() => comparer.compare(londonPersian, londonEvening), throwsArgumentError);
  expect(comparer.equals(londonPersian, londonEvening), isFalse);
  expect(comparer.getHashCode(londonPersian), isNot(comparer.getHashCode(londonEvening)));
  expect(comparer.equals(londonAfternoon, londonEvening), isFalse);
  expect(comparer.getHashCode(londonAfternoon), isNot(comparer.getHashCode(londonEvening)));
  expect(comparer.equals(londonAfternoon, losAngelesAfternoon), isTrue);
  expect(comparer.getHashCode(londonAfternoon), comparer.getHashCode(losAngelesAfternoon));
}

@Test()
Future InstantComparer() async
{
  var london = await (await DateTimeZoneProviders.tzdb)['Europe/London'];
  var losAngeles = await (await DateTimeZoneProviders.tzdb)['America/Los_Angeles'];

  // LA is 8 hours behind London. So the London evening occurs before the LA afternoon.
  var londonEvening = LocalDateTime(2014, 7, 9, 20, 32, 0).inZoneStrictly(london);
  var losAngelesAfternoon = LocalDateTime(2014, 7, 9, 14, 0, 0).inZoneStrictly(losAngeles);

  // Same instant as londonEvening
  var losAngelesLunchtime = LocalDateTime(2014, 7, 9, 12, 32, 0).inZoneStrictly(losAngeles);

  var londonPersian = londonEvening.localDateTime
      .withCalendar(CalendarSystem.persianSimple)
      .inZoneStrictly(london);

  var comparer = ZonedDateTimeComparer.instant;
  TestHelper.TestComparerStruct(comparer.compare, londonEvening, losAngelesLunchtime, losAngelesAfternoon);
  expect(0, comparer.compare(londonPersian, londonEvening));
  expect(comparer.equals(londonPersian, londonEvening), isTrue);
  expect(comparer.getHashCode(londonPersian), comparer.getHashCode(londonEvening));
  expect(comparer.equals(losAngelesLunchtime, londonEvening), isTrue);
  expect(comparer.getHashCode(losAngelesLunchtime), comparer.getHashCode(londonEvening));
  expect(comparer.equals(losAngelesAfternoon, londonEvening), isFalse);
  expect(comparer.getHashCode(losAngelesAfternoon), isNot(comparer.getHashCode(londonEvening)));
}

/*
@Test()
void Deconstruction()
{
  var saoPaulo = DateTimeZoneProviders.Tzdb['America/Sao_Paulo'];
  ZonedDateTime value = new LocalDateTime.fromYMDHMS(2017, 10, 15, 21, 30, 15).InZoneStrictly(saoPaulo);
  var expectedDateTime = new LocalDateTime.fromYMDHMS(2017, 10, 15, 21, 30, 15);
  var expectedZone = saoPaulo;
  var expectedOffset = new Offset.fromHours(-2);

  var (actualDateTime, actualZone, actualOffset) = value;

  Assert.Multiple(() =>
  {
  expect(expectedDateTime, actualDateTime);
  expect(expectedZone, actualZone);
  expect(expectedOffset, actualOffset);
  });
}
*/
