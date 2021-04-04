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

final Instant one = IInstant.untrusted(Time(nanoseconds: 1));
final Instant threeMillion = IInstant.untrusted(Time(nanoseconds: 3000000));
final Instant negativeFiftyMillion = IInstant.untrusted(Time(nanoseconds: -50000000));

@Test()
// Gregorian calendar: 1957-10-04
@TestCase([2436116.31, 1957, 9, 21, 19, 26, 24], 'Sample from Astronomical Algorithms 2nd Edition, chapter 7')
// Gregorian calendar: 2013-01-01
@TestCase([2456293.520833, 2012, 12, 19, 0, 30, 0], 'Sample from Wikipedia')
@TestCase([1842713.0, 333, 1, 27, 12, 0, 0], 'Another sample from Astronomical Algorithms 2nd Edition, chapter 7')
@TestCase([0.0, -4712, 1, 1, 12, 0, 0], 'Julian epoch')
void JulianDateConversions(double julianDate, int year, int month, int day, int hour, int minute, int second) {
  // When dealing with floating point binary data, if we're accurate to 50 milliseconds, that's fine...
  // (0.000001 days = ~86ms, as a guide to the scale involved...)
  Instant actual = Instant.julianDate(julianDate);
  var expected = LocalDateTime(year, month, day, hour, minute, second, calendar: CalendarSystem.julian).inUtc().toInstant();

  // var ldt = new LocalDateTime.fromInstant(new LocalInstant(expected.timeSinceEpoch));
  expect(expected.epochMilliseconds, closeTo(actual.epochMilliseconds, 50), reason: 'Expected $expected, was $actual');
  expect(julianDate, closeTo(expected.toJulianDate(), 0.000001));
}

@Test()
void BasicSpanTests() {
  var aSpan = Time(days: 11, nanoseconds: 2 * TimeConstants.nanosecondsPerDay);
// print('aSpan.totalDays = ${aSpan.totalDays}');

  expect(aSpan.totalDays, 11+2);
}

@Test()
void FromUtcNoSeconds()
{
  Instant viaUtc = ZonedDateTime.atStrictly(LocalDateTime(2008, 4, 3, 10, 35, 0), DateTimeZone.utc).toInstant();
  expect(viaUtc, Instant.utc(2008, 4, 3, 10, 35));
}

@Test()
void FromUtcWithSeconds()
{
  Instant viaUtc = ZonedDateTime.atStrictly(LocalDateTime(2008, 4, 3, 10, 35, 23), DateTimeZone.utc).toInstant();
  expect(viaUtc, Instant.utc(2008, 4, 3, 10, 35, 23));
}


@Test()
void InUtc()
{
  ZonedDateTime viaInstant = Instant.utc(2008, 4, 3, 10, 35, 23).inUtc();
  ZonedDateTime expected = ZonedDateTime.atStrictly(LocalDateTime(2008, 4, 3, 10, 35, 23), DateTimeZone.utc);
  expect(expected, viaInstant);
}

@Test()
Future InZone () async
{
  // todo: this is absurd
  DateTimeZone london = await (await DateTimeZoneProviders.tzdb)['Europe/London'];
  ZonedDateTime viaInstant = Instant.utc(2008, 6, 10, 13, 16, 17).inZone(london);

  // London is UTC+1 in the Summer, so the above is 14:16:17 local.
  LocalDateTime local = LocalDateTime(2008, 6, 10, 14, 16, 17);
  ZonedDateTime expected = ZonedDateTime.atStrictly(local, london);

  expect(expected, viaInstant);
}


@Test()
void WithOffset()
{
  // Jon talks about Noda Time at Leetspeak in Sweden on October 12th 2013, at 13:15 UTC+2
  Instant instant = Instant.utc(2013, 10, 12, 11, 15);
  Offset offset = Offset.hours(2);
  OffsetDateTime actual = instant.withOffset(offset);
  OffsetDateTime expected = OffsetDateTime(LocalDateTime(2013, 10, 12, 13, 15, 0), offset);
  expect(expected, actual);
}


@Test()
void WithOffset_NonIsoCalendar()
{
  // October 12th 2013 ISO is 1434-12-07 Islamic
  CalendarSystem calendar = CalendarSystem.getIslamicCalendar(IslamicLeapYearPattern.base15, IslamicEpoch.civil);
  Instant instant = Instant.utc(2013, 10, 12, 11, 15);
  Offset offset = Offset.hours(2);
  OffsetDateTime actual = instant.withOffset(offset, calendar);
  OffsetDateTime expected = OffsetDateTime(LocalDateTime(1434, 12, 7, 13, 15, 0, calendar: calendar), offset);
  expect(expected, actual);
}


@Test()
void FromTicksSinceUnixEpoch()
{
  Instant instant = Instant.fromEpochMicroseconds(12345);
  expect(12345, instant.epochMicroseconds);
}


@Test()
void FromUnixTimeMilliseconds_Valid()
{
  Instant actual = Instant.fromEpochMilliseconds(12345);
  Instant expected = Instant.fromEpochMicroseconds(12345 * TimeConstants.microsecondsPerMillisecond);
  expect(expected, instantIsCloseTo(actual));
}


// @Test()
void FromUnixTimeMilliseconds_TooLarge()
{
  expect(() => Instant.fromEpochMilliseconds(Platform.int64MaxValue ~/ 100), throwsException);
}


// @Test()
void FromUnixTimeMilliseconds_TooSmall()
{
  // expect(() => throw new Exception('boom'), throwsException);
  expect(Instant.fromEpochMilliseconds(Platform.int64MinValue ~/ 100), throwsException);
}


@Test()
void FromUnixTimeSeconds_Valid()
{
  Instant actual = Instant.fromEpochSeconds(12345);
  Instant expected = Instant.fromEpochMicroseconds(12345 * TimeConstants.microsecondsPerSecond);
  expect(expected, instantIsCloseTo(actual));
}


//@Test()
void FromUnixTimeSeconds_TooLarge()
{
  expect(() => Instant.fromEpochSeconds(Platform.int64MaxValue ~/ 1000000), throwsException);
}


//@Test()
void FromUnixTimeSeconds_TooSmall()
{
  expect(() => Instant.fromEpochSeconds(Platform.int64MinValue ~/ 1000000), throwsException);
}

@Test()
@TestCase([-1500, -2])
@TestCase([-1001, -2])
@TestCase([-1000, -1])
@TestCase([-999, -1])
@TestCase([-500, -1])
@TestCase([0, 0])
@TestCase([500, 0])
@TestCase([999, 0])
@TestCase([1000, 1])
@TestCase([1001, 1])
@TestCase([1500, 1])
void ToUnixTimeSeconds(int milliseconds, int expectedSeconds)
{
  var instant = Instant.fromEpochMilliseconds(milliseconds);
  expect(instant.epochSeconds, expectedSeconds);
}

@Test()
@TestCase([-15000, -2])
@TestCase([-10001, -2])
@TestCase([-10000, -1])
@TestCase([-9999, -1])
@TestCase([-5000, -1])
@TestCase([0, 0])
@TestCase([5000, 0])
@TestCase([9999, 0])
@TestCase([10000, 1])
@TestCase([10001, 1])
@TestCase([15000, 1])
void ToUnixTimeMilliseconds(int ticks, int expectedMilliseconds)
{
  // todo: rework this test
  var instant = Instant().add(Time(nanoseconds: ticks * 100));
  expect(instant.epochMilliseconds, expectedMilliseconds);
}

@Test()
void UnixConversions_ExtremeValues()
{
  // Round down to a whole second to make round-tripping work.
  // 'max' is 1 second away from from the end of the day, instead of 1 nanosecond away from the end of the day
  var max = Instant.maxValue.subtract(Time(seconds: 1)).add(Time.epsilon);
  expect(max, Instant.fromEpochSeconds(max.epochSeconds));
  expect(max, Instant.fromEpochMilliseconds(max.epochMilliseconds));
  if (Platform.isVM) expect(max, Instant.fromEpochMicroseconds(max.epochMicroseconds));

  var min = Instant.minValue;
  expect(min, Instant.fromEpochSeconds(min.epochSeconds));
  expect(min, Instant.fromEpochMilliseconds(min.epochMilliseconds));
  if (Platform.isVM) expect(min, Instant.fromEpochMicroseconds(min.epochMicroseconds));
}

@Test()
Future InZoneWithCalendar () async
{
  CalendarSystem copticCalendar = CalendarSystem.coptic;
  DateTimeZone london = await (await DateTimeZoneProviders.tzdb)['Europe/London'];
  ZonedDateTime viaInstant = Instant.utc(2004, 6, 9, 11, 10).inZone(london, copticCalendar);

  // Date taken from CopticCalendarSystemTest. Time will be 12:10 (London is UTC+1 in Summer)
  LocalDateTime local = LocalDateTime(1720, 10, 2, 12, 10, 0, calendar: copticCalendar);
  ZonedDateTime expected = ZonedDateTime.atStrictly(local, london);
  expect(viaInstant, expected);
}

@Test()
void Max()
{
  Instant x = Instant.fromEpochMicroseconds(100);
  Instant y = Instant.fromEpochMicroseconds(200);
  expect(y, Instant.max(x, y));
  expect(y, Instant.max(y, x));
  expect(x, Instant.max(x, Instant.minValue));
  expect(x, Instant.max(Instant.minValue, x));
  expect(Instant.maxValue, Instant.max(Instant.maxValue, x));
  expect(Instant.maxValue, Instant.max(x, Instant.maxValue));
}

@Test()
void Min()
{
  Instant x = Instant.fromEpochMicroseconds(100);
  Instant y = Instant.fromEpochMicroseconds(200);
  expect(x, Instant.min(x, y));
  expect(x, Instant.min(y, x));
  expect(Instant.minValue, Instant.min(x, Instant.minValue));
  expect(Instant.minValue, Instant.min(Instant.minValue, x));
  expect(x, Instant.min(Instant.maxValue, x));
  expect(x, Instant.min(x, Instant.maxValue));
}

@Test()
void ToDateTimeUtc()
{
  Instant x = Instant.utc(2011, 08, 18, 20, 53);
  DateTime expected = DateTime.utc(2011, 08, 18, 20, 53, 0);
  DateTime actual = x.toDateTimeUtc();
  expect(expected, actual);

  // Kind isn't checked by Equals...
  expect(true, actual.isUtc);
}

@Test()
void ToDateTimeLocal()
{
  Instant x = Instant.utc(2011, 08, 18, 20, 53);
  DateTime expected = x.inLocalZone().toDateTimeLocal(); //new DateTime.utc(2011, 08, 18, 20, 53, 0);
  DateTime actual = x.toDateTimeLocal();
  expect(expected, actual);

  // Kind isn't checked by Equals...
  expect(false, actual.isUtc);
}
// See issue 269, but now we throw a nicer exception.
//@Test()
//void ToBclTypes_DateOutOfRange()
//{
//  var instant = Instant.FromUtc(1, 1, 1, 0, 0).PlusNanoseconds(-1);
//  Assert.Throws<InvalidOperationException>(() => instant.ToDateTimeUtc());
//  Assert.Throws<InvalidOperationException>(() => instant.ToDateTimeOffset());
//}

//@Test()
//@TestCase(const [100])
//@TestCase(const [1900])
//@TestCase(const [2900])
//void ToBclTypes_TruncateNanosTowardStartOfTime(int year)
//{
//  var instant = new Instant.fromUtc(year, 1, 1, 13, 15, 55).plus(new Span(nanoseconds: TimeConstants.nanosecondsPerSecond - 1)); //.PlusNanoseconds(NodaConstants.NanosecondsPerSecond - 1);
//  var expectedDateTimeUtc = new DateTime(year, 1, 1, 13, 15, 55) //, DateTimeKind.Unspecified)
//      .AddTicks(NodaConstants.TicksPerSecond - 1);
//  var actualDateTimeUtc = instant.ToDateTimeUtc();
//  Assert.AreEqual(expectedDateTimeUtc, actualDateTimeUtc);
//  var expectedDateTimeOffset = new DateTimeOffset(expectedDateTimeUtc, TimeSpan.Zero);
//  var actualDateTimeOffset = instant.ToDateTimeOffset();
//  Assert.AreEqual(expectedDateTimeOffset, actualDateTimeOffset);
//}


//@Test()
//void ToDateTimeOffset()
//{
//  Instant x = new Instant.fromUtc(2011, 08, 18, 20, 53);
//  DateTimeOffset expected = new DateTimeOffset(2011, 08, 18, 20, 53, 0, TimeSpan.Zero);
//  Assert.AreEqual(expected, x.ToDateTimeOffset());
//}

//@Test()
//void FromDateTimeOffset()
//{
//  DateTimeOffset dateTimeOffset = new DateTimeOffset(2011, 08, 18, 20, 53, 0, TimeSpan.FromHours(5));
//  Instant expected = Instant.FromUtc(2011, 08, 18, 15, 53);
//  Assert.AreEqual(expected, Instant.FromDateTimeOffset(dateTimeOffset));
//}

//@Test()
//void FromDateTimeUtc_Invalid()
//{
//  Assert.Throws<ArgumentException>(() => Instant.FromDateTimeUtc(new DateTime(2011, 08, 18, 20, 53, 0, DateTimeKind.Local)));
//  Assert.Throws<ArgumentException>(() => Instant.FromDateTimeUtc(new DateTime(2011, 08, 18, 20, 53, 0, DateTimeKind.Unspecified)));
//}

//@Test()
//void FromDateTimeUtc_Valid()
//{
//  DateTime x = new DateTime(2011, 08, 18, 20, 53, 0, DateTimeKind.Utc);
//  Instant expected = Instant.FromUtc(2011, 08, 18, 20, 53);
//  Assert.AreEqual(expected, Instant.FromDateTimeUtc(x));
//}

/// Using the default constructor is equivalent to January 1st 1970, midnight, UTC, ISO Calendar
@Test()
void DefaultConstructor()
{
  var actual = Instant();
  expect(TimeConstants.unixEpoch, actual);
}

@Test()
@TestCase([-101, -2])
@TestCase([-100, -1])
@TestCase([-99, -1])
@TestCase([-1, -1])
@TestCase([0, 0])
@TestCase([99, 0])
@TestCase([100, 1])
@TestCase([101, 1])
void TicksTruncatesDown(int nanoseconds, int expectedTicks)
{
  Time nanos = Time(nanoseconds: nanoseconds);
  Instant instant = IInstant.untrusted(nanos); //.FromUntrustedDuration(nanos);
  // todo: maybe change this test up a bit?
  expect((instant.timeSinceEpoch.totalNanoseconds / 100).floor() /*.toUnixTimeTicks()*/, expectedTicks);
}

@Test()
void IsValid()
{
  expect(IInstant.beforeMinValue.isValid, isFalse);
  expect(Instant.minValue.isValid, isTrue);
  expect(Instant.maxValue.isValid, isTrue);
  expect(IInstant.afterMaxValue.isValid, isFalse);
}

@Test()
void InvalidValues()
{
  expect(IInstant.afterMaxValue, greaterThan(Instant.maxValue));
  expect(IInstant.beforeMinValue, lessThan(Instant.minValue));
}

@Test()
void PlusDuration_Overflow()
{
// todo: I owe you, overflow behavior
// TestHelper.AssertOverflow(Instant.minValue.plus, -Duration.Epsilon);
// TestHelper.AssertOverflow(Instant.maxValue.plus, Duration.Epsilon);
}

@Test()
void ExtremeArithmetic()
{
  Time hugeAndPositive = Instant.minValue.timeUntil(Instant.maxValue);
  Time hugeAndNegative = Instant.maxValue.timeUntil(Instant.minValue);
  expect(hugeAndNegative, -hugeAndPositive);
  expect(Instant.maxValue, Instant.minValue - hugeAndNegative);
  expect(Instant.maxValue, Instant.minValue + hugeAndPositive);
  expect(Instant.minValue, Instant.maxValue + hugeAndNegative);
  expect(Instant.minValue, Instant.maxValue - hugeAndPositive);
}

@Test()
void PlusOffset_Overflow()
{
// todo: I owe you, overflow behavior
// TestHelper.AssertOverflow(Instant.MinValue.Plus, Offset.FromSeconds(-1));
// TestHelper.AssertOverflow(Instant.MaxValue.Plus, Offset.FromSeconds(1));
}

@Test()
void FromUnixTimeMilliseconds_Range()
{
  // todo: I owe you, exception behavior
  //int smallestValid = Instant.minValue.toUnixTimeMicroseconds() ~/ TimeConstants.microsecondsPerMillisecond;
  //int largestValid = Instant.maxValue.toUnixTimeMicroseconds() ~/ TimeConstants.microsecondsPerMillisecond;
  //expect(() => Instant.fromEpochMilliseconds(smallestValid), isNot(throwsException));
  //expect(() => Instant.fromEpochMilliseconds(smallestValid - 1), throwsException);
  //expect(() => Instant.fromEpochMilliseconds(largestValid), isNot(throwsException));
  //expect(() => Instant.fromEpochMilliseconds(largestValid + 1), throwsException);

  //TestHelper.AssertValid(Instant.fromUnixTimeMilliseconds, smallestValid);
  //TestHelper.AssertOutOfRange(Instant.fromUnixTimeMilliseconds, smallestValid - 1);
  //TestHelper.AssertValid(Instant.FromUnixTimeMilliseconds, largestValid);
  //TestHelper.AssertOutOfRange(Instant.FromUnixTimeMilliseconds, largestValid + 1);
}

@Test()
void FromUnixTimeSeconds_Range()
{
  // todo: I owe you, out of range behavior
  //int smallestValid = Instant.minValue.toUnixTimeMicroseconds() ~/ TimeConstants.microsecondsPerSecond;
  //int largestValid = Instant.maxValue.toUnixTimeMicroseconds() ~/ TimeConstants.microsecondsPerSecond;
  //TestHelper.AssertValid(Instant.FromUnixTimeSeconds, smallestValid);
  //TestHelper.AssertOutOfRange(Instant.FromUnixTimeSeconds, smallestValid - 1);
  //TestHelper.AssertValid(Instant.FromUnixTimeSeconds, largestValid);
  //TestHelper.AssertOutOfRange(Instant.FromUnixTimeSeconds, largestValid + 1);
}

@Test()
void FromTicksSinceUnixEpoch_Range()
{
  // todo: I owe you, out of range behavior
  //int smallestValid = Instant.minValue.toUnixTimeMicroseconds();
  //int largestValid = Instant.maxValue.toUnixTimeMicroseconds();
  //TestHelper.AssertValid(Instant.FromUnixTimeTicks, smallestValid);
  //TestHelper.AssertOutOfRange(Instant.FromUnixTimeTicks, smallestValid - 1);
  //TestHelper.AssertValid(Instant.FromUnixTimeTicks, largestValid);
  //TestHelper.AssertOutOfRange(Instant.FromUnixTimeTicks, largestValid + 1);
}

@Test()
void PlusOffset()
{
  var localInstant = IInstant.plusOffset(TimeConstants.unixEpoch, Offset.hours(1));
  expect(Time(hours: 1), localInstant.timeSinceLocalEpoch);
}

@Test()
void SafePlus_NormalTime()
{
  var localInstant = IInstant.safePlus(TimeConstants.unixEpoch, Offset.hours(1));
  expect(Time(hours: 1), localInstant.timeSinceLocalEpoch);
}

@Test()
@TestCase([null, 0, null])
@TestCase([null, 1, null])
@TestCase([null, -1, null])
@TestCase([1, -1, 0])
@TestCase([1, -2, null])
@TestCase([2, 1, 3])
void SafePlus_NearStartOfTime(int? initialOffset, int offsetToAdd, int? finalOffset) {
  var start = initialOffset == null
      ? IInstant.beforeMinValue
      : Instant.minValue + Time(hours: initialOffset);
  var expected = finalOffset == null
      ? LocalInstant.beforeMinValue
      : IInstant.plusOffset(Instant.minValue, Offset.hours(finalOffset));
  var actual = IInstant.safePlus(start, Offset.hours(offsetToAdd));
  expect(actual, expected);
}

// A null offset indicates 'AfterMaxValue'. Otherwise, MaxValue.Plus(offset)
@Test()
@TestCase([null, 0, null])
@TestCase([null, 1, null])
@TestCase([null, -1, null])
@TestCase([-1, 1, 0])
@TestCase([-1, 2, null])
@TestCase([-2, -1, -3])
void SafePlus_NearEndOfTime(int? initialOffset, int offsetToAdd, int? finalOffset) {
  var start = initialOffset == null
      ? IInstant.afterMaxValue
      : Instant.maxValue + Time(hours: initialOffset);
  var expected = finalOffset == null
      ? LocalInstant.afterMaxValue
      : IInstant.plusOffset( Instant.maxValue, Offset.hours(finalOffset));
  var actual = IInstant.safePlus(start,Offset.hours(offsetToAdd));

  expect(actual, expected);
}

@Test()
@TestCase([0])
@TestCase([-1])
@TestCase([1])
@TestCase([123456789])
@TestCase([-123456789])
void InstantEpochConstructors(int value) {
  expect(Instant.fromEpochSeconds(value).epochSeconds, value);
  expect(Instant.fromEpochMilliseconds(value).epochMilliseconds, value);
  expect(Instant.fromEpochMicroseconds(value).epochMicroseconds, value);
  expect(Instant.fromEpochNanoseconds(value).epochNanoseconds, value);
  expect(Instant.fromEpochBigIntNanoseconds(BigInt.from(value)).epochNanosecondsAsBigInt.toInt(), value);
}

