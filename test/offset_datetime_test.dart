// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

import 'time_machine_testing.dart';

Future main() async {
  await TimeMachine.initialize();
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
  Offset offset = Offset.hours(5);

  OffsetDateTime odt = OffsetDateTime(LocalDateTime(2012, 1, 2, 3, 4, 0), offset);
  expect(offset, odt.offset);
}

@Test()
void LocalDateTimeProperty()
{
  LocalDateTime local = LocalDateTime(2012, 6, 19, 1, 2, 3, calendar: CalendarSystem.julian).addNanoseconds(123456789);
  Offset offset = Offset.hours(5);

  OffsetDateTime odt = OffsetDateTime(local, offset);
  expect(local, odt.localDateTime);
}

@Test()
void ToInstant()
{
  Instant instant = Instant.utc(2012, 6, 25, 16, 5, 20);
  LocalDateTime local = LocalDateTime(2012, 6, 25, 21, 35, 20);
  Offset offset = Offset.hoursAndMinutes(5, 30);

  OffsetDateTime odt = OffsetDateTime(local, offset);
  expect(instant, odt.toInstant());
}

@Test()
void Equality()
{
  LocalDateTime local1 = LocalDateTime(2012, 10, 6, 1, 2, 3);
  LocalDateTime local2 = LocalDateTime(2012, 9, 5, 1, 2, 3);
  Offset offset1 = Offset.hours(1);
  Offset offset2 = Offset.hours(2);

  OffsetDateTime equal1 = OffsetDateTime(local1, offset1);
  OffsetDateTime equal2 = OffsetDateTime(local1, offset1);
  OffsetDateTime unequalByOffset = OffsetDateTime(local1, offset2);
  OffsetDateTime unequalByLocal = OffsetDateTime(local2, offset1);

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
  Offset offset = Offset.hours(5);
  LocalDateTime local = LocalDateTime(2012, 1, 2, 3, 4, 0);
  OffsetDateTime odt = OffsetDateTime(local, offset);

  ZonedDateTime zoned = odt.inFixedZone;
  expect(ZonedDateTime.atStrictly(local, DateTimeZone.forOffset(offset)), zoned);
}

@Test()
void ToString_WholeHourOffset()
{
  LocalDateTime local = LocalDateTime(2012, 10, 6, 1, 2, 3);
  Offset offset = Offset.hours(1);
  OffsetDateTime odt = OffsetDateTime(local, offset);
  expect('2012-10-06T01:02:03+01', odt.toString());
}

@Test()
void ToString_PartHourOffset()
{
  LocalDateTime local = LocalDateTime(2012, 10, 6, 1, 2, 3);
  Offset offset = Offset.hoursAndMinutes(1, 30);
  OffsetDateTime odt = OffsetDateTime(local, offset);
  expect('2012-10-06T01:02:03+01:30', odt.toString());
}

@Test()
void ToString_Utc()
{
  LocalDateTime local = LocalDateTime(2012, 10, 6, 1, 2, 3);
  OffsetDateTime odt = OffsetDateTime(local, Offset.zero);
  expect('2012-10-06T01:02:03Z', odt.toString());
}

// Todo: String stuffs (after CLDR)
//@Test()
//void ToString_WithFormat()
//{
//  LocalDateTime local = new LocalDateTime.fromYMDHMS(2012, 10, 6, 1, 2, 3);
//  Offset offset = new Offset.fromHours(1);
//  OffsetDateTime odt = new OffsetDateTime(local, offset);
//  expect('2012/10/06 01:02:03 01', odt.toString("yyyy/MM/dd HH:mm:ss o<-HH>", Culture.invariantCulture));
//}

@Test() @SkipMe()
void LocalComparer()
{
  var localControl = LocalDateTime(2013, 4, 2, 19, 54, 0);
  var control = OffsetDateTime(localControl, Offset.zero);
  var negativeOffset = control.localDateTime.withOffset(Offset.hours(-1));
  var positiveOffset = control.localDateTime.withOffset(Offset.hours(1));
  var differentCalendar = control.localDateTime.withCalendar(CalendarSystem.coptic).withOffset(Offset.hours(5));
  // Later instant, earlier local
  var earlierLocal = control.localDateTime.addHours(-2).withOffset(Offset.hours(-10));
  // Same offset, previous day
  var muchEarlierLocal = control.add(Time(hours: -24));
  // Earlier instant, later local
  var laterLocal = control.localDateTime.addHours(2).withOffset(Offset.hours(10));
  // Same offset, next day
  var muchLaterLocal = control.add(Time(hours: 24));

  var comparer = OffsetDateTimeComparer.local;

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

@Test() @SkipMe()
void InstantComparer()
{
  var localControl = LocalDateTime(2013, 4, 2, 19, 54, 0);
  var control = OffsetDateTime(localControl, Offset.zero);
  var equalAndOppositeChanges = control.localDateTime.addHours(1).withOffset(Offset.hours(1));
  var differentCalendar = control.localDateTime.withCalendar(CalendarSystem.coptic).withOffset(Offset.zero);

  // Negative offset means later instant
  var negativeOffset = control.localDateTime.withOffset(Offset.hours(-1));
  // Positive offset means earlier instant
  var positiveOffset = control.localDateTime.withOffset(Offset.hours(1));

  // Later instant, earlier local
  var earlierLocal = control.localDateTime.addHours(-2).withOffset(Offset.hours(-10));
  // Earlier instant, later local
  var laterLocal = control.localDateTime.addHours(2).withOffset(Offset.hours(10));

  var comparer = OffsetDateTimeComparer.instant;

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

/// Using the default constructor is equivalent to January 1st 1970, midnight, UTC, ISO calendar
@Test()
void DefaultConstructor()
{
  // todo: I owe you a default constructor
  var actual = OffsetDateTime(LocalDateTime.localDateAtTime(LocalDate(1, 1, 1), LocalTime(0, 0, 0)), Offset(0));
  expect(LocalDateTime(1, 1, 1, 0, 0, 0), actual.localDateTime);
  expect(Offset.zero, actual.offset);
}

@Test()
void Subtraction_Duration()
{
  // Test all three approaches... not bothering to check a different calendar,
  // but we'll use two different offsets.
  OffsetDateTime end = LocalDateTime(2014, 08, 14, 15, 0, 0).withOffset(Offset.hours(1));
  Time duration = Time(hours: 8) + Time(minutes: 9);
  OffsetDateTime expected = LocalDateTime(2014, 08, 14, 6, 51, 0).withOffset(Offset.hours(1));
  expect(expected, end - duration);
  expect(expected, end.subtract(duration));
  expect(expected, OffsetDateTime.minus(end, duration));
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
  OffsetDateTime start = LocalDateTime(2014, 08, 14, 6, 51, 0).withOffset(Offset.hours(1));
  Time duration = Time(hours: 8) + Time(minutes: 9);
  OffsetDateTime expected = LocalDateTime(2014, 08, 14, 15, 0, 0).withOffset(Offset.hours(1));
  expect(expected, start + duration);
  expect(expected, start.add(duration));
  expect(expected, OffsetDateTime.plus(start, duration));

  expect(start + Time(hours: hours), start.add(Time(hours: hours)));
  expect(start + Time(hours: -hours), start.add(Time(hours: -hours)));

  expect(start + Time(minutes: minutes), start.add(Time(minutes: minutes)));
  expect(start + Time(minutes: -minutes), start.add(Time(minutes: -minutes)));

  expect(start + Time(seconds: seconds), start.add(Time(seconds: seconds)));
  expect(start + Time(seconds: -seconds), start.add(Time(seconds: -seconds)));

  expect(start + Time(milliseconds: milliseconds), start.add(Time(milliseconds: milliseconds)));
  expect(start + Time(milliseconds: -milliseconds), start.add(Time(milliseconds: -milliseconds)));

  expect(start + Time(microseconds: ticks), start.add(Time(microseconds: ticks)));
  expect(start + Time(microseconds: -ticks), start.add(Time(microseconds: -ticks)));

  expect(start + Time(nanoseconds: nanoseconds), start.add(Time(nanoseconds: nanoseconds)));
  expect(start + Time(nanoseconds: -nanoseconds), start.add(Time(nanoseconds: -nanoseconds)));
  /*
  expect(start + new Time(hours: hours), start.addHours(hours));
  expect(start + new Time(hours: -hours), start.addHours(-hours));

  expect(start + new Time(minutes: minutes), start.addMinutes(minutes));
  expect(start + new Time(minutes: -minutes), start.addMinutes(-minutes));

  expect(start + new Time(seconds: seconds), start.addSeconds(seconds));
  expect(start + new Time(seconds: -seconds), start.addSeconds(-seconds));

  expect(start + new Time(milliseconds: milliseconds), start.addMilliseconds(milliseconds));
  expect(start + new Time(milliseconds: -milliseconds), start.addMilliseconds(-milliseconds));

  expect(start + new Time(microseconds: ticks), start.addMicroseconds(ticks));
  expect(start + new Time(microseconds: -ticks), start.addMicroseconds(-ticks));

  expect(start + new Time(nanoseconds: nanoseconds), start.addNanoseconds(nanoseconds));
  expect(start + new Time(nanoseconds: -nanoseconds), start.addNanoseconds(-nanoseconds));
  */
}

@Test()
void Subtraction_OffsetDateTime()
{
  // Test all three approaches... not bothering to check a different calendar,
  // but we'll use two different offsets.
  OffsetDateTime start = LocalDateTime(2014, 08, 14, 6, 51, 0).withOffset(Offset.hours(1));
  OffsetDateTime end = LocalDateTime(2014, 08, 14, 18, 0, 0).withOffset(Offset.hours(4));
  Time expected = Time(hours: 8) + Time(minutes: 9);
  // expect(expected, end - start);
  expect(expected, end.timeSince(start));
  expect(expected, start.timeUntil(end));
  expect(expected, OffsetDateTime.difference(end, start));
}

@Test()
void WithOffset()
{
  LocalDateTime morning = LocalDateTime(2014, 1, 31, 9, 30, 0);
  OffsetDateTime original = OffsetDateTime(morning, Offset.hours(-8));
  LocalDateTime evening = LocalDateTime(2014, 1, 31, 19, 30, 0);
  Offset newOffset = Offset.hours(2);
  OffsetDateTime expected = OffsetDateTime(evening, newOffset);
  expect(expected, original.withOffset(newOffset));
}

@Test()
void WithOffset_CrossDates()
{
  OffsetDateTime noon = OffsetDateTime(LocalDateTime(2017, 8, 22, 12, 0, 0), Offset.hours(0));
  OffsetDateTime previousNight = noon.withOffset(Offset.hours(-14));
  OffsetDateTime nextMorning = noon.withOffset(Offset.hours(14));
  expect(LocalDateTime(2017, 8, 21, 22, 0, 0), previousNight.localDateTime);
  expect(LocalDateTime(2017, 8, 23, 2, 0, 0), nextMorning.localDateTime);
}

@Test()
void WithOffset_TwoDaysForwardAndBack()
{
  // Go from UTC-18 to UTC+18
  OffsetDateTime night = OffsetDateTime(LocalDateTime(2017, 8, 21, 18, 0, 0), Offset.hours(-18));
  OffsetDateTime morning = night.withOffset(Offset.hours(18));
  expect(LocalDateTime(2017, 8, 23, 6, 0, 0), morning.localDateTime);
  OffsetDateTime backAgain = morning.withOffset(Offset.hours(-18));
  expect(night, backAgain);
}

@Test()
void WithCalendar()
{
  CalendarSystem julianCalendar = CalendarSystem.julian;
  OffsetDateTime gregorianEpoch = TimeConstants.unixEpoch.withOffset(Offset.zero);

  OffsetDateTime expected = LocalDate(1969, 12, 19, julianCalendar).atMidnight().withOffset(Offset.hours(0));
  OffsetDateTime actual = gregorianEpoch.withCalendar(CalendarSystem.julian);
  expect(expected, actual);
}

@Test()
void With_TimeAdjuster()
{
  Offset offset = Offset.hoursAndMinutes(2, 30);
  OffsetDateTime start = LocalDateTime(2014, 6, 27, 12, 15, 8).addNanoseconds(123456789).withOffset(offset);
  OffsetDateTime expected = LocalDateTime(2014, 6, 27, 12, 15, 8).withOffset(offset);
  expect(expected, start.adjustTime(TimeAdjusters.truncateToSecond));
}

@Test()
void With_DateAdjuster()
{
  Offset offset = Offset.hoursAndMinutes(2, 30);
  OffsetDateTime start = LocalDateTime(2014, 6, 27, 12, 5, 8).addNanoseconds(123456789).withOffset(offset);
  OffsetDateTime expected = LocalDateTime(2014, 6, 30, 12, 5, 8).addNanoseconds(123456789).withOffset(offset);
  expect(expected, start.adjustDate(DateAdjusters.endOfMonth));
}

@Test()
Future InZone() async
{
  Offset offset = Offset.hours(-7);
  OffsetDateTime start = LocalDateTime(2017, 10, 31, 18, 12, 0).withOffset(offset);
  var zone = await (await DateTimeZoneProviders.tzdb)['Europe/London'];
  var zoned = start.inZone(zone);

  // On October 31st, the UK had already gone back, so the offset is 0.
  // Importantly, it's not the offset of the original OffsetDateTime: we're testing
  // that InZone *doesn't* require that.
  var expected = IZonedDateTime.trusted(LocalDateTime(2017, 11, 1, 1, 12, 0).withOffset(Offset.zero), zone);
  expect(expected, zoned);
}

@Test()
void ToOffsetDate()
{
  var offset = Offset.hoursAndMinutes(2, 30);
  var odt = LocalDateTime(2014, 6, 27, 12, 15, 8).addNanoseconds(123456789).withOffset(offset);
  var expected = OffsetDate(LocalDate(2014, 6, 27), offset);
  expect(expected, odt.toOffsetDate());
}

@Test()
void ToOffsetTime()
{
  var offset = Offset.hoursAndMinutes(2, 30);
  var odt = LocalDateTime(2014, 6, 27, 12, 15, 8).addNanoseconds(123456789).withOffset(offset);
  var expected = OffsetTime(LocalTime(12, 15, 8).addNanoseconds(123456789), offset);
  expect(expected, odt.toOffsetTime());
}

