// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/OffsetDateTimeTest.cs
// 27cf251  on Nov 11, 2017

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

@Test()
void LocalDateTimeProperties()
{
  // todo: find equivalence
  /*
  LocalDateTime local = new LocalDateTime.fromYMDHMSC(2012, 6, 19, 1, 2, 3, CalendarSystem.Julian).PlusNanoseconds(123456789);
  Offset offset = new Offset.fromHours(5);

  OffsetDateTime odt = new OffsetDateTime(local, offset);

  var localDateTimePropertyNames = typeof(LocalDateTime).GetTypeInfo()
      .DeclaredProperties
      .Select(p => p.Name)
      .ToList();
  var commonProperties = typeof(OffsetDateTime).GetTypeInfo()
      .DeclaredProperties
      .Where(p => localDateTimePropertyNames.Contains(p.Name));
  for (var property in commonProperties)
  {
    expect(typeof(LocalDateTime).GetProperty(property.Name).GetValue(local, null),
    property.GetValue(odt, null));
  }*/
}

@Test()
void OffsetProperty()
{
  Offset offset = new Offset.fromHours(5);

  OffsetDateTime odt = new OffsetDateTime(new LocalDateTime.fromYMDHM(2012, 1, 2, 3, 4), offset);
  expect(offset, odt.offset);
}

@Test()
void LocalDateTimeProperty()
{
  LocalDateTime local = new LocalDateTime.fromYMDHMSC(2012, 6, 19, 1, 2, 3, CalendarSystem.Julian).PlusNanoseconds(123456789);
  Offset offset = new Offset.fromHours(5);

  OffsetDateTime odt = new OffsetDateTime(local, offset);
  expect(local, odt.localDateTime);
}

@Test()
void ToInstant()
{
  Instant instant = new Instant.fromUtc(2012, 6, 25, 16, 5, 20);
  LocalDateTime local = new LocalDateTime.fromYMDHMS(2012, 6, 25, 21, 35, 20);
  Offset offset = new Offset.fromHoursAndMinutes(5, 30);

  OffsetDateTime odt = new OffsetDateTime(local, offset);
  expect(instant, odt.ToInstant());
}

@Test()
void Equality()
{
  LocalDateTime local1 = new LocalDateTime.fromYMDHMS(2012, 10, 6, 1, 2, 3);
  LocalDateTime local2 = new LocalDateTime.fromYMDHMS(2012, 9, 5, 1, 2, 3);
  Offset offset1 = new Offset.fromHours(1);
  Offset offset2 = new Offset.fromHours(2);

  OffsetDateTime equal1 = new OffsetDateTime(local1, offset1);
  OffsetDateTime equal2 = new OffsetDateTime(local1, offset1);
  OffsetDateTime unequalByOffset = new OffsetDateTime(local1, offset2);
  OffsetDateTime unequalByLocal = new OffsetDateTime(local2, offset1);

  TestHelper.TestEqualsStruct(equal1, equal2, [unequalByOffset]);
  TestHelper.TestEqualsStruct(equal1, equal2, [unequalByLocal]);

  TestHelper.TestOperatorEquality(equal1, equal2, unequalByOffset);
  TestHelper.TestOperatorEquality(equal1, equal2, unequalByLocal);
}

// No dart:core equivalent
//@Test()
//void ToDateTimeOffset()
//{
//  LocalDateTime local = new LocalDateTime.fromYMDHMS(2012, 10, 6, 1, 2, 3);
//  Offset offset = new Offset.fromHours(1);
//  OffsetDateTime odt = new OffsetDateTime(local, offset);
//
//  DateTimeOffset expected = new DateTimeOffset(DateTime.SpecifyKind(new DateTime(2012, 10, 6, 1, 2, 3), DateTimeKind.Unspecified),
//      TimeSpan.FromHours(1));
//  DateTimeOffset actual = odt.ToDateTimeOffset();
//  expect(expected, actual);
//}

// No dart:core equivalent
//@Test()
//@TestCase(const [0, 30, 20])
//@TestCase(const [-1, -30, -20])
//@TestCase(const [0, 30, 55])
//@TestCase(const [-1, -30, -55])
//void ToDateTimeOffset_TruncatedOffset(int hours, int minutes, int seconds)
//{
//  var ldt = new LocalDateTime.fromYMDHMS(2017, 1, 9, 21, 45, 20);
//  var offset = new Offset.fromHoursAndMinutes(hours, minutes).Plus(Offset.FromSeconds(seconds));
//  var odt = ldt.WithOffset(offset);
//  var dto = odt.ToDateTimeOffset();
//  // We preserve the local date/time, so the instant will move forward as the offset
//  // is truncated.
//  expect(new DateTime(2017, 1, 9, 21, 45, 20, DateTimeKind.Unspecified), dto.DateTime);
//  expect(TimeSpan.FromHours(hours) + TimeSpan.FromMinutes(minutes), dto.Offset);
//}

// No dart:core equivalent
//@Test()
//@TestCase(const [-15])
//@TestCase(const [15])
//void ToDateTimeOffset_OffsetOutOfRange(int hours)
//{
//  var ldt = new LocalDateTime.fromYMDHMS(2017, 1, 9, 21, 45, 20);
//  var offset = new Offset.fromHours(hours);
//  var odt = ldt.WithOffset(offset);
//  expect(() => odt.ToDateTimeOffset(), throwsStateError);
//}

// No dart:core equivalent
//@Test()
//@TestCase(const [-14])
//@TestCase(const [14])
//void ToDateTimeOffset_OffsetEdgeOfRange(int hours)
//{
//  var ldt = new LocalDateTime.fromYMDHMS(2017, 1, 9, 21, 45, 20);
//  var offset = new Offset.fromHours(hours);
//  var odt = ldt.WithOffset(offset);
//  expect(hours, odt.ToDateTimeOffset().Offset.TotalHours);
//}

// No dart:core equivalent
//@Test()
//void ToDateTimeOffset_DateOutOfRange()
//{
//  // One day before 1st January, 1AD (which is DateTime.MinValue)
//  var odt = new LocalDate(1, 1, 1).PlusDays(-1).AtMidnight.WithOffset(new Offset.fromHours(1));
//  expect(() => odt.ToDateTimeOffset(), throwsStateError);
//}

// No dart:core equivalent
//@Test()
//@TestCase(const [100])
//@TestCase(const [1900])
//@TestCase(const [2900])
//void ToDateTimeOffset_TruncateNanosTowardStartOfTime(int year)
//{
//  var odt = new LocalDateTime.fromYMDHMS(year, 1, 1, 13, 15, 55).PlusNanoseconds(TimeConstants.nanosecondsPerSecond - 1)
//      .WithOffset(new Offset.fromHours(1));
//  var expected = new DateTimeOffset(year, 1, 1, 13, 15, 55, TimeSpan.FromHours(1))
//      .AddTicks(TimeConstants.ticksPerSecond - 1);
//  var actual = odt.ToDateTimeOffset();
//  expect(expected, actual);
//}

// No dart:core equivalent
//@Test()
//void FromDateTimeOffset()
//{
//  LocalDateTime local = new LocalDateTime.fromYMDHMS(2012, 10, 6, 1, 2, 3);
//  Offset offset = new Offset.fromHours(1);
//  OffsetDateTime expected = new OffsetDateTime(local, offset);
//
//  // We can build an OffsetDateTime regardless of kind... although if the kind is Local, the offset
//  // has to be valid for the local time zone when building a DateTimeOffset, and if the kind is Utc, the offset has to be zero.
//  DateTimeOffset bcl = new DateTimeOffset(DateTime.SpecifyKind(new DateTime(2012, 10, 6, 1, 2, 3), DateTimeKind.Unspecified),
//      TimeSpan.FromHours(1));
//  OffsetDateTime actual = OffsetDateTime.FromDateTimeOffset(bcl);
//  expect(expected, actual);
//}

@Test()
void InFixedZone()
{
  Offset offset = new Offset.fromHours(5);
  LocalDateTime local = new LocalDateTime.fromYMDHM(2012, 1, 2, 3, 4);
  OffsetDateTime odt = new OffsetDateTime(local, offset);

  ZonedDateTime zoned = odt.InFixedZone;
  expect(DateTimeZone.ForOffset(offset).AtStrictly(local), zoned);
}

@Test()
void ToString_WholeHourOffset()
{
  LocalDateTime local = new LocalDateTime.fromYMDHMS(2012, 10, 6, 1, 2, 3);
  Offset offset = new Offset.fromHours(1);
  OffsetDateTime odt = new OffsetDateTime(local, offset);
  expect("2012-10-06T01:02:03+01", odt.toString());
}

@Test()
void ToString_PartHourOffset()
{
  LocalDateTime local = new LocalDateTime.fromYMDHMS(2012, 10, 6, 1, 2, 3);
  Offset offset = new Offset.fromHoursAndMinutes(1, 30);
  OffsetDateTime odt = new OffsetDateTime(local, offset);
  expect("2012-10-06T01:02:03+01:30", odt.toString());
}

@Test()
void ToString_Utc()
{
  LocalDateTime local = new LocalDateTime.fromYMDHMS(2012, 10, 6, 1, 2, 3);
  OffsetDateTime odt = new OffsetDateTime(local, Offset.zero);
  expect("2012-10-06T01:02:03Z", odt.toString());
}

// Todo: String stuffs (after CLDR)
//@Test()
//void ToString_WithFormat()
//{
//  LocalDateTime local = new LocalDateTime.fromYMDHMS(2012, 10, 6, 1, 2, 3);
//  Offset offset = new Offset.fromHours(1);
//  OffsetDateTime odt = new OffsetDateTime(local, offset);
//  expect("2012/10/06 01:02:03 01", odt.toString("yyyy/MM/dd HH:mm:ss o<-HH>", CultureInfo.InvariantCulture));
//}

@Test() @SkipMe.unimplemented()
void LocalComparer()
{
  var localControl = new LocalDateTime.fromYMDHM(2013, 4, 2, 19, 54);
  var control = new OffsetDateTime(localControl, Offset.zero);
  var negativeOffset = control.localDateTime.WithOffset(new Offset.fromHours(-1));
  var positiveOffset = control.localDateTime.WithOffset(new Offset.fromHours(1));
  var differentCalendar = control.localDateTime.WithCalendar(CalendarSystem.Coptic).WithOffset(new Offset.fromHours(5));
  // Later instant, earlier local
  var earlierLocal = control.localDateTime.PlusHours(-2).WithOffset(new Offset.fromHours(-10));
  // Same offset, previous day
  var muchEarlierLocal = control.PlusHours(-24);
  // Earlier instant, later local
  var laterLocal = control.localDateTime.PlusHours(2).WithOffset(new Offset.fromHours(10));
  // Same offset, next day
  var muchLaterLocal = control.PlusHours(24);

  var comparer = OffsetDateTime_LocalComparer.Instance; // OffsetDateTime.comparer.Local;

  expect(0, comparer.compare(control, negativeOffset));
  expect(0, comparer.compare(control, positiveOffset));
  expect(() => comparer.compare(control, differentCalendar), throwsArgumentError);
  expect(1, (comparer.compare(control, earlierLocal)).sign);
  expect(1, (comparer.compare(control, muchEarlierLocal)).sign);
  expect(-1, (comparer.compare(earlierLocal, control)).sign);
  expect(-1, (comparer.compare(muchEarlierLocal, control)).sign);
  expect(-1, (comparer.compare(control, laterLocal)).sign);
  expect(-1, (comparer.compare(control, muchLaterLocal)).sign);
  expect(1, (comparer.compare(laterLocal, control)).sign);
  expect(1, (comparer.compare(muchLaterLocal, control)).sign);

  expect(comparer.equals(control, differentCalendar), isFalse);
  expect(comparer.equals(control, earlierLocal), isFalse);
  expect(comparer.equals(control, muchEarlierLocal), isFalse);
  expect(comparer.equals(control, laterLocal), isFalse);
  expect(comparer.equals(control, muchLaterLocal), isFalse);
  expect(comparer.equals(control, control), isTrue);

  expect(comparer.getHashCode(control), comparer.getHashCode(negativeOffset));
  expect(comparer.getHashCode(control), comparer.getHashCode(positiveOffset));
  expect(comparer.getHashCode(control), isNot(comparer.getHashCode(control)));
  expect(comparer.getHashCode(control), isNot(comparer.getHashCode(control)));
  expect(comparer.getHashCode(control), isNot(comparer.getHashCode(control)));
  expect(comparer.getHashCode(control), isNot(comparer.getHashCode(control)));
  expect(comparer.getHashCode(control), isNot(comparer.getHashCode(control)));
}

@Test() @SkipMe.unimplemented()
void InstantComparer()
{
  var localControl = new LocalDateTime.fromYMDHM(2013, 4, 2, 19, 54);
  var control = new OffsetDateTime(localControl, Offset.zero);
  var equalAndOppositeChanges = control.localDateTime.PlusHours(1).WithOffset(new Offset.fromHours(1));
  var differentCalendar = control.localDateTime.WithCalendar(CalendarSystem.Coptic).WithOffset(Offset.zero);

  // Negative offset means later instant
  var negativeOffset = control.localDateTime.WithOffset(new Offset.fromHours(-1));
  // Positive offset means earlier instant
  var positiveOffset = control.localDateTime.WithOffset(new Offset.fromHours(1));

  // Later instant, earlier local
  var earlierLocal = control.localDateTime.PlusHours(-2).WithOffset(new Offset.fromHours(-10));
  // Earlier instant, later local
  var laterLocal = control.localDateTime.PlusHours(2).WithOffset(new Offset.fromHours(10));

  var comparer = OffsetDateTime_InstantComparer.Instance; // OffsetDateTime.comparer.Instant;

  expect(0, comparer.compare(control, differentCalendar));
  expect(0, comparer.compare(control, equalAndOppositeChanges));

  expect(-1, (comparer.compare(control, negativeOffset)).sign);
  expect(1, (comparer.compare(negativeOffset, control)).sign);
  expect(1, comparer.compare(control, positiveOffset));
  expect(-1, (comparer.compare(positiveOffset, control)).sign);

  expect(-1, (comparer.compare(control, earlierLocal)).sign);
  expect(1, (comparer.compare(earlierLocal, control)).sign);
  expect(1, (comparer.compare(control, laterLocal)).sign);
  expect(-1, (comparer.compare(laterLocal, control)).sign);

  expect(comparer.equals(control, differentCalendar), isTrue);
  expect(comparer.equals(control, earlierLocal), isFalse);
  expect(comparer.equals(control, equalAndOppositeChanges), isTrue);

  expect(comparer.getHashCode(control), comparer.getHashCode(differentCalendar));
  expect(comparer.getHashCode(control), comparer.getHashCode(equalAndOppositeChanges));
  expect(comparer.getHashCode(control), isNot(comparer.getHashCode(control)));
}

/// <summary>
/// Using the default constructor is equivalent to January 1st 1970, midnight, UTC, ISO calendar
/// </summary>
@Test()
void DefaultConstructor()
{
  // todo: I owe you a default constructor
  var actual = new OffsetDateTime(new LocalDateTime(new LocalDate(1, 1, 1), new LocalTime(0, 0)), new Offset(0));
  expect(new LocalDateTime.fromYMDHM(1, 1, 1, 0, 0), actual.localDateTime);
  expect(Offset.zero, actual.offset);
}

@Test()
void Subtraction_Duration()
{
  // Test all three approaches... not bothering to check a different calendar,
  // but we'll use two different offsets.
  OffsetDateTime end = new LocalDateTime.fromYMDHM(2014, 08, 14, 15, 0).WithOffset(new Offset.fromHours(1));
  Span duration = new Span(hours: 8) + new Span(minutes: 9);
  OffsetDateTime expected = new LocalDateTime.fromYMDHM(2014, 08, 14, 6, 51).WithOffset(new Offset.fromHours(1));
  expect(expected, end - duration);
  expect(expected, end.MinusSpan(duration));
  expect(expected, OffsetDateTime.Subtract(end, duration));
}

@Test()
void Addition_Duration()
{
  const int minutes = 23;
  const int hours = 3;
  const int milliseconds = 40000;
  const int seconds = 321;
  const int nanoseconds = 12345;
  const int ticks = 5432112345;

  // Test all three approaches... not bothering to check a different calendar,
  // but we'll use two different offsets.
  OffsetDateTime start = new LocalDateTime.fromYMDHM(2014, 08, 14, 6, 51).WithOffset(new Offset.fromHours(1));
  Span duration = new Span(hours: 8) + new Span(minutes: 9);
  OffsetDateTime expected = new LocalDateTime.fromYMDHM(2014, 08, 14, 15, 0).WithOffset(new Offset.fromHours(1));
  expect(expected, start + duration);
  expect(expected, start.Plus(duration));
  expect(expected, OffsetDateTime.Add(start, duration));

  expect(start + new Span(hours: hours), start.PlusHours(hours));
  expect(start + new Span(hours: -hours), start.PlusHours(-hours));

  expect(start + new Span(minutes: minutes), start.PlusMinutes(minutes));
  expect(start + new Span(minutes: -minutes), start.PlusMinutes(-minutes));

  expect(start + new Span(seconds: seconds), start.PlusSeconds(seconds));
  expect(start + new Span(seconds: -seconds), start.PlusSeconds(-seconds));

  expect(start + new Span(milliseconds: milliseconds), start.PlusMilliseconds(milliseconds));
  expect(start + new Span(milliseconds: -milliseconds), start.PlusMilliseconds(-milliseconds));

  expect(start + new Span(ticks: ticks), start.PlusTicks(ticks));
  expect(start + new Span(ticks: -ticks), start.PlusTicks(-ticks));

  expect(start + new Span(nanoseconds: nanoseconds), start.PlusNanoseconds(nanoseconds));
  expect(start + new Span(nanoseconds: -nanoseconds), start.PlusNanoseconds(-nanoseconds));
}

@Test()
void Subtraction_OffsetDateTime()
{
  // Test all three approaches... not bothering to check a different calendar,
  // but we'll use two different offsets.
  OffsetDateTime start = new LocalDateTime.fromYMDHM(2014, 08, 14, 6, 51).WithOffset(new Offset.fromHours(1));
  OffsetDateTime end = new LocalDateTime.fromYMDHM(2014, 08, 14, 18, 0).WithOffset(new Offset.fromHours(4));
  Span expected = new Span(hours: 8) + new Span(minutes: 9);
  expect(expected, end - start);
  expect(expected, end.MinusOffsetDateTime(start));
  expect(expected, OffsetDateTime.SubtractOffsetDateTimes(end, start));
}

@Test()
void WithOffset()
{
  LocalDateTime morning = new LocalDateTime.fromYMDHM(2014, 1, 31, 9, 30);
  OffsetDateTime original = new OffsetDateTime(morning, new Offset.fromHours(-8));
  LocalDateTime evening = new LocalDateTime.fromYMDHM(2014, 1, 31, 19, 30);
  Offset newOffset = new Offset.fromHours(2);
  OffsetDateTime expected = new OffsetDateTime(evening, newOffset);
  expect(expected, original.WithOffset(newOffset));
}

@Test()
void WithOffset_CrossDates()
{
  OffsetDateTime noon = new OffsetDateTime(new LocalDateTime.fromYMDHMS(2017, 8, 22, 12, 0, 0), new Offset.fromHours(0));
  OffsetDateTime previousNight = noon.WithOffset(new Offset.fromHours(-14));
  OffsetDateTime nextMorning = noon.WithOffset(new Offset.fromHours(14));
  expect(new LocalDateTime.fromYMDHMS(2017, 8, 21, 22, 0, 0), previousNight.localDateTime);
  expect(new LocalDateTime.fromYMDHMS(2017, 8, 23, 2, 0, 0), nextMorning.localDateTime);
}

@Test()
void WithOffset_TwoDaysForwardAndBack()
{
  // Go from UTC-18 to UTC+18
  OffsetDateTime night = new OffsetDateTime(new LocalDateTime.fromYMDHMS(2017, 8, 21, 18, 0, 0), new Offset.fromHours(-18));
  OffsetDateTime morning = night.WithOffset(new Offset.fromHours(18));
  expect(new LocalDateTime.fromYMDHMS(2017, 8, 23, 6, 0, 0), morning.localDateTime);
  OffsetDateTime backAgain = morning.WithOffset(new Offset.fromHours(-18));
  expect(night, backAgain);
}

@Test()
void WithCalendar()
{
  CalendarSystem julianCalendar = CalendarSystem.Julian;
  OffsetDateTime gregorianEpoch = TimeConstants.unixEpoch.WithOffset(Offset.zero);

  OffsetDateTime expected = new LocalDate.forCalendar(1969, 12, 19, julianCalendar).AtMidnight.WithOffset(new Offset.fromHours(0));
  OffsetDateTime actual = gregorianEpoch.WithCalendar(CalendarSystem.Julian);
  expect(expected, actual);
}

@Test()
void With_TimeAdjuster()
{
  Offset offset = new Offset.fromHoursAndMinutes(2, 30);
  OffsetDateTime start = new LocalDateTime.fromYMDHMS(2014, 6, 27, 12, 15, 8).PlusNanoseconds(123456789).WithOffset(offset);
  OffsetDateTime expected = new LocalDateTime.fromYMDHMS(2014, 6, 27, 12, 15, 8).WithOffset(offset);
  expect(expected, start.WithTime(TimeAdjusters.TruncateToSecond));
}

@Test()
void With_DateAdjuster()
{
  Offset offset = new Offset.fromHoursAndMinutes(2, 30);
  OffsetDateTime start = new LocalDateTime.fromYMDHMS(2014, 6, 27, 12, 5, 8).PlusNanoseconds(123456789).WithOffset(offset);
  OffsetDateTime expected = new LocalDateTime.fromYMDHMS(2014, 6, 30, 12, 5, 8).PlusNanoseconds(123456789).WithOffset(offset);
  expect(expected, start.WithDate(DateAdjusters.EndOfMonth));
}

@Test()
Future InZone() async
{
  Offset offset = new Offset.fromHours(-7);
  OffsetDateTime start = new LocalDateTime.fromYMDHMS(2017, 10, 31, 18, 12, 0).WithOffset(offset);
  var zone = await (await DateTimeZoneProviders.Tzdb)["Europe/London"];
  var zoned = start.InZone(zone);

  // On October 31st, the UK had already gone back, so the offset is 0.
  // Importantly, it's not the offset of the original OffsetDateTime: we're testing
  // that InZone *doesn't* require that.
  var expected = new ZonedDateTime.trusted(new LocalDateTime.fromYMDHMS(2017, 11, 1, 1, 12, 0).WithOffset(Offset.zero), zone);
  expect(expected, zoned);
}

@Test()
void ToOffsetDate()
{
  var offset = new Offset.fromHoursAndMinutes(2, 30);
  var odt = new LocalDateTime.fromYMDHMS(2014, 6, 27, 12, 15, 8).PlusNanoseconds(123456789).WithOffset(offset);
  var expected = new OffsetDate(new LocalDate(2014, 6, 27), offset);
  expect(expected, odt.ToOffsetDate());
}

@Test()
void ToOffsetTime()
{
  var offset = new Offset.fromHoursAndMinutes(2, 30);
  var odt = new LocalDateTime.fromYMDHMS(2014, 6, 27, 12, 15, 8).PlusNanoseconds(123456789).WithOffset(offset);
  var expected = new OffsetTime(new LocalTime(12, 15, 8).PlusNanoseconds(123456789), offset);
  expect(expected, odt.ToOffsetTime());
}
