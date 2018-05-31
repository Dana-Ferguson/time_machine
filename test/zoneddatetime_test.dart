// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/ZonedDateTimeTest.cs
// 69dedbc  15 days ago

import 'dart:async';
import 'dart:math' as math;

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

/// <summary>
/// Changes from UTC+3 to UTC+4 at 1am local time on June 13th 2011.
/// </summary>
final SingleTransitionDateTimeZone SampleZone = new SingleTransitionDateTimeZone.around(new Instant.fromUtc(2011, 6, 12, 22, 0), 3, 4);

@Test()
void SimpleProperties()
{
  var value = SampleZone.AtStrictly(new LocalDateTime.fromYMDHMS(2012, 2, 10, 8, 9, 10).PlusNanoseconds(123456789));
  expect(new LocalDate(2012, 2, 10), value.Date);
  expect(LocalTime.FromHourMinuteSecondNanosecond(8, 9, 10, 123456789), value.TimeOfDay);
  expect(Era.Common, value.era);
  expect(2012, value.Year);
  expect(2012, value.YearOfEra);
  expect(2, value.Month);
  expect(10, value.Day);
  expect(IsoDayOfWeek.friday, value.DayOfWeek);
  expect(41, value.DayOfYear);
  expect(8, value.ClockHourOfHalfDay);
  expect(8, value.Hour);
  expect(9, value.Minute);
  expect(10, value.Second);
  expect(123, value.Millisecond);
  expect(1234567, value.TickOfSecond);
  expect(8 * TimeConstants.ticksPerHour +
      9 * TimeConstants.ticksPerMinute +
      10 * TimeConstants.ticksPerSecond +
      1234567,
      value.TickOfDay);
  expect(8 * TimeConstants.nanosecondsPerHour +
      9 * TimeConstants.nanosecondsPerMinute +
      10 * TimeConstants.nanosecondsPerSecond +
      123456789,
      value.NanosecondOfDay);
}

@Test()
void Add_AroundTimeZoneTransition()
{
  // Before the transition at 3pm...
  ZonedDateTime before = SampleZone.AtStrictly(new LocalDateTime.fromYMDHM(2011, 6, 12, 15, 0));
  // 24 hours elapsed, and it's 4pm
  ZonedDateTime afterExpected = SampleZone.AtStrictly(new LocalDateTime.fromYMDHM(2011, 6, 13, 16, 0));
  ZonedDateTime afterAdd = ZonedDateTime.AddSpan(before, Span.oneDay);
  ZonedDateTime afterOperator = before + Span.oneDay;

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

  ZonedDateTime before = SampleZone.AtStrictly(new LocalDateTime.fromYMDHM(2011, 6, 12, 15, 0));
  expect(before + Span.oneDay, ZonedDateTime.AddSpan(before, Span.oneDay));
  expect(before + Span.oneDay, before.PlusSpan(Span.oneDay));

  expect(before + new Span(hours: hours), before.PlusHours(hours));
  expect(before + new Span(hours: -hours), before.PlusHours(-hours));

  expect(before + new Span(minutes: minutes), before.PlusMinutes(minutes));
  expect(before + new Span(minutes: -minutes), before.PlusMinutes(-minutes));

  expect(before + new Span(seconds: seconds), before.PlusSeconds(seconds));
  expect(before + new Span(seconds: -seconds), before.PlusSeconds(-seconds));

  expect(before + new Span(milliseconds: milliseconds), before.PlusMilliseconds(milliseconds));
  expect(before + new Span(milliseconds: -milliseconds), before.PlusMilliseconds(-milliseconds));

  expect(before + new Span(ticks: ticks), before.PlusTicks(ticks));
  expect(before + new Span(ticks: -ticks), before.PlusTicks(-ticks));

  expect(before + new Span(nanoseconds: nanoseconds), before.PlusNanoseconds(nanoseconds));
  expect(before + new Span(nanoseconds: -nanoseconds), before.PlusNanoseconds(-nanoseconds));
}

@Test()
void Subtract_AroundTimeZoneTransition()
{
  // After the transition at 4pm...
  ZonedDateTime after = SampleZone.AtStrictly(new LocalDateTime.fromYMDHM(2011, 6, 13, 16, 0));
  // 24 hours earlier, and it's 3pm
  ZonedDateTime beforeExpected = SampleZone.AtStrictly(new LocalDateTime.fromYMDHM(2011, 6, 12, 15, 0));
  ZonedDateTime beforeSubtract = ZonedDateTime.SubtractSpan(after, Span.oneDay);
  ZonedDateTime beforeOperator = after - Span.oneDay;

  expect(beforeExpected, beforeSubtract);
  expect(beforeExpected, beforeOperator);
}

@Test()
void SubtractDuration_MethodEquivalents()
{
  ZonedDateTime after = SampleZone.AtStrictly(new LocalDateTime.fromYMDHM(2011, 6, 13, 16, 0));
  expect(after - Span.oneDay, ZonedDateTime.SubtractSpan(after, Span.oneDay));
  expect(after - Span.oneDay, after.MinusSpan(Span.oneDay));
}

@Test()
void Subtraction_ZonedDateTime()
{
  // Test all three approaches... not bothering to check a different calendar,
  // but we'll use two different time zones.
  ZonedDateTime start = new LocalDateTime.fromYMDHM(2014, 08, 14, 5, 51).InUtc();
  // Sample zone is UTC+4 at this point, so this is 14:00Z.
  ZonedDateTime end = SampleZone.AtStrictly(new LocalDateTime.fromYMDHM(2014, 08, 14, 18, 0));
  Span expected = new Span(hours: 8) + new Span(minutes: 9);
  expect(expected, end - start);
  expect(expected, end.Minus(start));
  expect(expected, ZonedDateTime.Subtract(end, start));
}

@Test()
void WithZone()
{
  Instant instant = new Instant.fromUtc(2012, 2, 4, 12, 35);
  ZonedDateTime zoned = new ZonedDateTime(instant, SampleZone);
  expect(new LocalDateTime.fromYMDHMS(2012, 2, 4, 16, 35, 0), zoned.localDateTime);

  // Will be UTC-8 for our instant.
  DateTimeZone newZone = new SingleTransitionDateTimeZone.around(new Instant.fromUtc(2000, 1, 1, 0, 0), -7, -8);
  ZonedDateTime converted = zoned.WithZone(newZone);
  expect(new LocalDateTime.fromYMDHMS(2012, 2, 4, 4, 35, 0), converted.localDateTime);
  expect(converted.ToInstant(), instant);
}

@Test()
Future IsDaylightSavings() async
{
  // Use a real time zone rather than a single-transition zone, so that we can get
  // a savings offset.
  var zone = await (await DateTimeZoneProviders.Tzdb)["Europe/London"];
  var winterSummerTransition = new Instant.fromUtc(2014, 3, 30, 1, 0);
  var winter = (winterSummerTransition - Span.epsilon).InZone(zone);
  var summer = winterSummerTransition.InZone(zone);
  expect(winter.IsDaylightSavingTime(), isFalse);
  expect(summer.IsDaylightSavingTime(), isTrue);
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
  ZonedDateTime zoned = SampleZone.AtStrictly(new LocalDateTime.fromYMDHMS(2011, 3, 5, 1, 0, 0));
  // Note that this is 10pm the previous day, UTC - so 1am local time
  DateTime expected = new DateTime.utc(2011, 3, 4, 22, 0, 0);
  DateTime actual = zoned.ToDateTimeUtc();
  expect(expected, actual);
  // Kind isn't checked by Equals...
  expect(actual.isUtc, isTrue);
}

@Test()
void ToDateTimeUtc_InRangeAfterUtcAdjustment()
{
  var zone = DateTimeZone.ForOffset(new Offset.fromHours(-1));
  var zdt = new LocalDateTime.fromYMDHM(0, 12, 31, 23, 30).InZoneStrictly(zone);
  // Sanity check: without reversing the offset, we're out of range
  // ToDateTimeUnspecified() works in dart:core
  // expect(() => zdt.ToDateTimeUnspecified(), throwsStateError);
  // expect(() => zdt.ToDateTimeOffset(), throwsStateError);
  var expected = new DateTime.utc(1, 1, 1, 0, 30, 0);
  var actual = zdt.ToDateTimeUtc();
  expect(expected, actual);
}

@Test()
void ToDateTimeUnspecified()
{
  ZonedDateTime zoned = SampleZone.AtStrictly(new LocalDateTime.fromYMDHMS(2011, 3, 5, 1, 0, 0));
  DateTime expected = new DateTime(2011, 3, 5, 1, 0, 0);
  DateTime actual = zoned.ToDateTimeUnspecified();
  expect(actual, expected);
  // Kind isn't checked by Equals...
  expect(actual.isUtc, isFalse); // DateTimeKind.Unspecified, actual.Kind);
}

@Test()
void ToOffsetDateTime()
{
  var local = new LocalDateTime.fromYMDHMS(1911, 3, 5, 1, 0, 0); // Early interval
  var zoned = SampleZone.AtStrictly(local);
  var offsetDateTime = zoned.ToOffsetDateTime();
  expect(local, offsetDateTime.localDateTime);
  expect(SampleZone.EarlyInterval.wallOffset, offsetDateTime.offset);
}

@Test()
void Equality()
{
  // Goes back from 2am to 1am on June 13th
  SingleTransitionDateTimeZone zone = new SingleTransitionDateTimeZone.around(new Instant.fromUtc(2011, 6, 12, 22, 0), 4, 3);
  var sample = zone.MapLocal(new LocalDateTime.fromYMDHM(2011, 6, 13, 1, 30)).First();
  var fromUtc = new Instant.fromUtc(2011, 6, 12, 21, 30).InZone(zone);

  // Checks all the overloads etc: first check is that the zone matters
  TestHelper.TestEqualsStruct(sample, fromUtc, [new Instant.fromUtc(2011, 6, 12, 21, 30).inUtc()]);
  TestHelper.TestOperatorEquality(sample, fromUtc, [new Instant.fromUtc(2011, 6, 12, 21, 30).inUtc()]);

  // Now just use a simple inequality check for other aspects...

  // Different offset
  var later = zone.MapLocal(new LocalDateTime.fromYMDHM(2011, 6, 13, 1, 30)).Last();
  expect(sample.localDateTime, later.localDateTime);
  expect(sample.offset, isNot(later.offset));
  expect(sample, isNot(later));

  // Different local time
  expect(sample, isNot(zone.MapLocal(new LocalDateTime.fromYMDHM(2011, 6, 13, 1, 19)).First()));

  // Different calendar
  var withOtherCalendar = zone.MapLocal(new LocalDateTime.fromYMDHMC(2011, 6, 13, 1, 30, CalendarSystem.Gregorian)).First();
  expect(sample, isNot(withOtherCalendar));
}

@Test()
void Constructor_ArgumentValidation()
{
  // This first one passes b/c of how we implemented the default constructor, now defaults to CalendarSystem.Iso
  // expect(() => new ZonedDateTime(new Instant.fromUnixTimeTicks(1000), null), throwsArgumentError);
  expect(() => new ZonedDateTime.withCalendar(new Instant.fromUnixTimeTicks(1000), null, CalendarSystem.Iso), throwsArgumentError);
  expect(() => new ZonedDateTime.withCalendar(new Instant.fromUnixTimeTicks(1000), SampleZone, null), throwsArgumentError);
}

@Test()
void Construct_FromLocal_ValidUnambiguousOffset()
{
  SingleTransitionDateTimeZone zone = new SingleTransitionDateTimeZone.around(new Instant.fromUtc(2011, 6, 12, 22, 0), 4, 3);

  LocalDateTime local = new LocalDateTime.fromYMDHMS(2000, 1, 2, 3, 4, 5);
  ZonedDateTime zoned = new ZonedDateTime.fromLocal(local, zone, zone.EarlyInterval.wallOffset);
  expect(zoned, local.InZoneStrictly(zone));
}

@Test()
void Construct_FromLocal_ValidEarlierOffset()
{
  SingleTransitionDateTimeZone zone = new SingleTransitionDateTimeZone.around(new Instant.fromUtc(2011, 6, 12, 22, 0), 4, 3);

  LocalDateTime local = new LocalDateTime.fromYMDHM(2011, 6, 13, 1, 30);
  ZonedDateTime zoned = new ZonedDateTime.fromLocal(local, zone, zone.EarlyInterval.wallOffset);

  // Map the local time to the earlier of the offsets in a way which is tested elsewhere.
  var resolver = Resolvers.CreateMappingResolver(Resolvers.ReturnEarlier, Resolvers.ThrowWhenSkipped);
  expect(zoned, local.InZone(zone, resolver));
}

@Test()
void Construct_FromLocal_ValidLaterOffset()
{
  SingleTransitionDateTimeZone zone = new SingleTransitionDateTimeZone.around(new Instant.fromUtc(2011, 6, 12, 22, 0), 4, 3);

  LocalDateTime local = new LocalDateTime.fromYMDHM(2011, 6, 13, 1, 30);
  ZonedDateTime zoned = new ZonedDateTime.fromLocal(local, zone, zone.LateInterval.wallOffset);

  // Map the local time to the later of the offsets in a way which is tested elsewhere.
  var resolver = Resolvers.CreateMappingResolver(Resolvers.ReturnLater, Resolvers.ThrowWhenSkipped);
  expect(zoned, local.InZone(zone, resolver));
}

@Test()
void Construct_FromLocal_InvalidOffset()
{
  SingleTransitionDateTimeZone zone = new SingleTransitionDateTimeZone.around(new Instant.fromUtc(2011, 6, 12, 22, 0), 4, 3);

  // Attempt to ask for the later offset in the earlier interval
  LocalDateTime local = new LocalDateTime.fromYMDHMS(2000, 1, 1, 0, 0, 0);
  expect(() => new ZonedDateTime.fromLocal(local, zone, zone.LateInterval.wallOffset), throwsArgumentError);
}

/// <summary>
///   Using the default constructor is equivalent to January 1st 1970, midnight, UTC, ISO calendar
/// </summary>
@Test()
void DefaultConstructor()
{
  // Note: The test documentation says this should be January 1st 1970, but the actual test
  // checks for '0001-01-01T00:00:00 UTC (+00)' -- we're going to differ from NodaTime's implementation here
  // and go with the test documentation.
  var actual = new ZonedDateTime();
  expect(new LocalDateTime.fromYMDHM(1970, 1, 1, 0, 0), actual.localDateTime);
  expect(Offset.zero, actual.offset);
  expect(DateTimeZone.Utc, actual.Zone);
}

/*
@Test()
void BinarySerialization_Iso()
{
  DateTimeZoneProviders.Serialization = DateTimeZoneProviders.Tzdb;
  var zone = DateTimeZoneProviders.Tzdb["America/New_York"];
  var value = new ZonedDateTime(new LocalDateTime.fromYMDHMS(2013, 4, 12, 17, 53, 23).WithOffset(new Offset.fromHours(-4)), zone);
  TestHelper.AssertBinaryRoundtrip(value);
}

@Test()
void XmlSerialization_Iso()
{
  DateTimeZoneProviders.Serialization = DateTimeZoneProviders.Tzdb;
  var zone = DateTimeZoneProviders.Tzdb["America/New_York"];
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
    var zone = DateTimeZoneProviders.Bcl["Eastern Standard Time"];
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
    var zone = DateTimeZoneProviders.Bcl["Eastern Standard Time"];
    var value = new ZonedDateTime(new LocalDateTime.fromYMDHMS(2013, 4, 12, 17, 53, 23).WithOffset(new Offset.fromHours(-4)), zone);
    TestHelper.AssertBinaryRoundtrip(value);
  }
}
#endif

@Test()
void XmlSerialization_NonIso()
{
  DateTimeZoneProviders.Serialization = DateTimeZoneProviders.Tzdb;
  var zone = DateTimeZoneProviders.Tzdb["America/New_York"];
  var localDateTime = new LocalDateTime.fromYMDHMSC(2013, 6, 12, 17, 53, 23, CalendarSystem.Julian);
  var value = new ZonedDateTime(localDateTime.WithOffset(new Offset.fromHours(-4)), zone);
  TestHelper.AssertXmlRoundtrip(value,
      "<value zone=\"America/New_York\" calendar=\"Julian\">2013-06-12T17:53:23-04</value>");
}

@Test()
void BinarySerialization_NonIso()
{
  DateTimeZoneProviders.Serialization = DateTimeZoneProviders.Tzdb;
  var zone = DateTimeZoneProviders.Tzdb["America/New_York"];
  var localDateTime = new LocalDateTime.fromYMDHMSC(2013, 6, 12, 17, 53, 23, CalendarSystem.Julian);
  var value = new ZonedDateTime(localDateTime.WithOffset(new Offset.fromHours(-4)), zone);
  TestHelper.AssertBinaryRoundtrip(value);
}

#if !NETCORE

@Test()
@TestCase(const [typeof(ArgumentException), 10000, 8, 25, 0L, 0, 60, "Europe/London"])
@TestCase(const [typeof(ArgumentException), 2017, 8, 25, 0L, 0, 60, "Europe/London"])
@TestCase(const [typeof(ArgumentException), 2017, 13, 25, 0L, 0, 60, "Europe/London"])
@TestCase(const [typeof(ArgumentException), 2017, 8, 32, 0L, 0, 60, "Europe/London"])
@TestCase(const [typeof(ArgumentException), 2017, 8, 25, -1L, 0, 60, "Europe/London"])
@TestCase(const [typeof(ArgumentException), 2017, 8, 25, 0L, -1, 60, "Europe/London", Description = "Invalid calendar ordinal"])
@TestCase(const [typeof(ArgumentException), 2017, 8, 25, 0L, 0, 120, "Europe/London", Description = "Wrong offset"])
@TestCase(const [typeof(TimeZoneNotFoundException), 2017, 8, 25, 0L, 0, 120, "Europe/NotLondon", Description = "Unknown zone ID"])
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
@TestCase(const ["<value>2013-04-12T17:53:23-04</value>", typeof(ArgumentException), Description = "No zone"])
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
  var local = new LocalDateTime.fromYMDHMS(2013, 7, 23, 13, 05, 20);
  ZonedDateTime zoned = local.InZoneStrictly(SampleZone);
  expect("2013-07-23T13:05:20 Single (+04)", zoned.toString());
}

@Test()
void ZonedDateTime_ToString_WithFormat()
{
  var local = new LocalDateTime.fromYMDHMS(2013, 7, 23, 13, 05, 20);
  ZonedDateTime zoned = local.InZoneStrictly(SampleZone);
  expect("2013/07/23 13:05:20 Single", zoned.toString("yyyy/MM/dd HH:mm:ss z", CultureInfo.invariantCulture));
}

@Test() @SkipMe.unimplemented()
Future LocalComparer() async
{
  var london = await (await DateTimeZoneProviders.Tzdb)["Europe/London"];
  var losAngeles = await (await DateTimeZoneProviders.Tzdb)["America/Los_Angeles"];

  // LA is 8 hours behind London. So the London evening occurs before the LA afternoon.
  var londonEvening = new LocalDateTime.fromYMDHM(2014, 7, 9, 20, 32).InZoneStrictly(london);
  var losAngelesAfternoon = new LocalDateTime.fromYMDHM(2014, 7, 9, 14, 0).InZoneStrictly(losAngeles);

  // Same local time as losAngelesAfternoon
  var londonAfternoon = losAngelesAfternoon.localDateTime.InZoneStrictly(london);

  var londonPersian = londonEvening.localDateTime
      .WithCalendar(CalendarSystem.PersianSimple)
      .InZoneStrictly(london);

  var comparer = ZonedDateTime_LocalComparer.Instance; // ZonedDateTime.Comparer.Local;
  TestHelper.TestComparerStruct(comparer.compare, losAngelesAfternoon, londonAfternoon, londonEvening);
  expect(() => comparer.compare(londonPersian, londonEvening), throwsArgumentError);
  expect(comparer.equals(londonPersian, londonEvening), isFalse);
  expect(comparer.getHashCode(londonPersian), isNot(comparer.getHashCode(londonEvening)));
  expect(comparer.equals(londonAfternoon, londonEvening), isFalse);
  expect(comparer.getHashCode(londonAfternoon), isNot(comparer.getHashCode(londonEvening)));
  expect(comparer.equals(londonAfternoon, losAngelesAfternoon), isTrue);
  expect(comparer.getHashCode(londonAfternoon), comparer.getHashCode(losAngelesAfternoon));
}

@Test() @SkipMe.unimplemented()
Future InstantComparer() async
{
  var london = await (await DateTimeZoneProviders.Tzdb)["Europe/London"];
  var losAngeles = await (await DateTimeZoneProviders.Tzdb)["America/Los_Angeles"];

  // LA is 8 hours behind London. So the London evening occurs before the LA afternoon.
  var londonEvening = new LocalDateTime.fromYMDHM(2014, 7, 9, 20, 32).InZoneStrictly(london);
  var losAngelesAfternoon = new LocalDateTime.fromYMDHM(2014, 7, 9, 14, 0).InZoneStrictly(losAngeles);

  // Same instant as londonEvening
  var losAngelesLunchtime = new LocalDateTime.fromYMDHM(2014, 7, 9, 12, 32).InZoneStrictly(losAngeles);

  var londonPersian = londonEvening.localDateTime
      .WithCalendar(CalendarSystem.PersianSimple)
      .InZoneStrictly(london);

  var comparer = ZonedDateTime_InstantComparer.Instance; // ZonedDateTime.Comparer.Instant;
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
  var saoPaulo = DateTimeZoneProviders.Tzdb["America/Sao_Paulo"];
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