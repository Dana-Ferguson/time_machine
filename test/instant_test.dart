// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/InstantTest.cs
// 0913621  on Aug 26, 2017

import 'dart:async';

import 'package:time_machine/time_machine.dart';
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import 'test_fx.dart';
import 'time_matchers.dart';

Future main() async {
  await runTests();
}

final Instant one = new Instant.untrusted(new Span(nanoseconds: 1));
final Instant threeMillion = new Instant.untrusted(new Span(nanoseconds: 3000000));
final Instant negativeFiftyMillion = new Instant.untrusted(new Span(nanoseconds: -50000000));

@Test()
// Gregorian calendar: 1957-10-04
@TestCase(const [2436116.31, 1957, 9, 21, 19, 26, 24], "Sample from Astronomical Algorithms 2nd Edition, chapter 7")
// Gregorian calendar: 2013-01-01
@TestCase(const [2456293.520833, 2012, 12, 19, 0, 30, 0], "Sample from Wikipedia")
@TestCase(const [1842713.0, 333, 1, 27, 12, 0, 0], "Another sample from Astronomical Algorithms 2nd Edition, chapter 7")
@TestCase(const [0.0, -4712, 1, 1, 12, 0, 0], "Julian epoch")
void JulianDateConversions(double julianDate, int year, int month, int day, int hour, int minute, int second) {
  // When dealing with floating point binary data, if we're accurate to 50 milliseconds, that's fine...
  // (0.000001 days = ~86ms, as a guide to the scale involved...)
  Instant actual = new Instant.fromJulianDate(julianDate);
  var expected = new LocalDateTime.fromYMDHMSC(year, month, day, hour, minute, second, CalendarSystem.Julian).InUtc().ToInstant();

  // expect(expected.toUnixTimeMilliseconds(), actual.toUnixTimeMilliseconds(), 50, "Expected $expected, was $actual");
  // expect(julianDate, expected.toJulianDate(), 0.000001);
  print('${expected.toUnixTimeMilliseconds()} =?? ${actual.toUnixTimeMilliseconds()}');
  print('${julianDate} =?? ${expected.toJulianDate()}');

  expect(expected.toUnixTimeMilliseconds(), closeTo(actual.toUnixTimeMilliseconds(), 50), reason: "Expected $expected, was $actual");
  expect(julianDate, closeTo(expected.toJulianDate(), 0.000001));
}

@Test()
void BasicSpanTests() {
  var aSpan = new Span.complex(days: 11, nanoseconds: 2 * TimeConstants.nanosecondsPerDay);
  // print('aSpan.totalDays = ${aSpan.totalDays}');

  expect(aSpan.totalDays, 11+2);
}

@Test()
void FromUtcNoSeconds()
{
  Instant viaUtc = DateTimeZone.Utc.AtStrictly(new LocalDateTime.fromYMDHMS(2008, 4, 3, 10, 35, 0)).ToInstant();
  expect(viaUtc, new Instant.fromUtc(2008, 4, 3, 10, 35));
}

@Test()
void FromUtcWithSeconds()
{
  Instant viaUtc = DateTimeZone.Utc.AtStrictly(new LocalDateTime.fromYMDHMS(2008, 4, 3, 10, 35, 23)).ToInstant();
  expect(viaUtc, new Instant.fromUtc(2008, 4, 3, 10, 35, 23));
}


@Test()
void InUtc()
{
  ZonedDateTime viaInstant = new Instant.fromUtc(2008, 4, 3, 10, 35, 23).inUtc();
  ZonedDateTime expected = DateTimeZone.Utc.AtStrictly(new LocalDateTime.fromYMDHMS(2008, 4, 3, 10, 35, 23));
  expect(expected, viaInstant);
}

@Test()
Future InZone () async
{
  // todo: this is absurd
  DateTimeZone london = await (await DateTimeZoneProviders.Tzdb)["Europe/London"];
  ZonedDateTime viaInstant = new Instant.fromUtc(2008, 6, 10, 13, 16, 17).InZone(london);

  // London is UTC+1 in the Summer, so the above is 14:16:17 local.
  LocalDateTime local = new LocalDateTime.fromYMDHMS(2008, 6, 10, 14, 16, 17);
  ZonedDateTime expected = london.AtStrictly(local);

  expect(expected, viaInstant);
}


@Test()
void WithOffset()
{
  // Jon talks about Noda Time at Leetspeak in Sweden on October 12th 2013, at 13:15 UTC+2
  Instant instant = new Instant.fromUtc(2013, 10, 12, 11, 15);
  Offset offset = new Offset.fromHours(2);
  OffsetDateTime actual = instant.WithOffset(offset);
  OffsetDateTime expected = new OffsetDateTime(new LocalDateTime.fromYMDHM(2013, 10, 12, 13, 15), offset);
  expect(expected, actual);
}


@Test()
void WithOffset_NonIsoCalendar()
{
  // October 12th 2013 ISO is 1434-12-07 Islamic
  CalendarSystem calendar = CalendarSystem.GetIslamicCalendar(IslamicLeapYearPattern.Base15, IslamicEpoch.Civil);
  Instant instant = new Instant.fromUtc(2013, 10, 12, 11, 15);
  Offset offset = new Offset.fromHours(2);
  OffsetDateTime actual = instant.WithOffset(offset, calendar);
  OffsetDateTime expected = new OffsetDateTime(new LocalDateTime.fromYMDHMC(1434, 12, 7, 13, 15, calendar), offset);
  expect(expected, actual);
}


@Test()
void FromTicksSinceUnixEpoch()
{
  Instant instant = new Instant.fromUnixTimeTicks(12345);
  expect(12345, instant.toUnixTimeTicks());
}


@Test()
void FromUnixTimeMilliseconds_Valid()
{
  Instant actual = new Instant.fromUnixTimeMilliseconds(12345);
  Instant expected = new Instant.fromUnixTimeTicks(12345 * TimeConstants.ticksPerMillisecond);
  expect(expected, instantIsCloseTo(actual));
}


// @Test()
void FromUnixTimeMilliseconds_TooLarge()
{
  expect(() => new Instant.fromUnixTimeMilliseconds(Utility.int64MaxValue ~/ 100), throwsException);
}


// @Test()
void FromUnixTimeMilliseconds_TooSmall()
{
  // expect(() => throw new Exception('boom'), throwsException);
  expect(new Instant.fromUnixTimeMilliseconds(Utility.int64MinValue ~/ 100), throwsException);
}


@Test()
void FromUnixTimeSeconds_Valid()
{
  Instant actual = new Instant.fromUnixTimeSeconds(12345);
  Instant expected = new Instant.fromUnixTimeTicks(12345 * TimeConstants.ticksPerSecond);
  expect(expected, instantIsCloseTo(actual));
}


//@Test()
void FromUnixTimeSeconds_TooLarge()
{
  expect(() => new Instant.fromUnixTimeSeconds(Utility.int64MaxValue ~/ 1000000), throwsException);
}


//@Test()
void FromUnixTimeSeconds_TooSmall()
{
  expect(() => new Instant.fromUnixTimeSeconds(Utility.int64MinValue ~/ 1000000), throwsException);
}

@Test()
@TestCase(const [-1500, -2])
@TestCase(const [-1001, -2])
@TestCase(const [-1000, -1])
@TestCase(const [-999, -1])
@TestCase(const [-500, -1])
@TestCase(const [0, 0])
@TestCase(const [500, 0])
@TestCase(const [999, 0])
@TestCase(const [1000, 1])
@TestCase(const [1001, 1])
@TestCase(const [1500, 1])
void ToUnixTimeSeconds(int milliseconds, int expectedSeconds)
{
  var instant = new Instant.fromUnixTimeMilliseconds(milliseconds);
  expect(instant.toUnixTimeSeconds(), expectedSeconds);
}

@Test()
@TestCase(const [-15000, -2])
@TestCase(const [-10001, -2])
@TestCase(const [-10000, -1])
@TestCase(const [-9999, -1])
@TestCase(const [-5000, -1])
@TestCase(const [0, 0])
@TestCase(const [5000, 0])
@TestCase(const [9999, 0])
@TestCase(const [10000, 1])
@TestCase(const [10001, 1])
@TestCase(const [15000, 1])
void ToUnixTimeMilliseconds(int ticks, int expectedMilliseconds)
{
  var instant = new Instant.fromUnixTimeTicks(ticks);
  expect(instant.toUnixTimeMilliseconds(), expectedMilliseconds);
}

@Test()
void UnixConversions_ExtremeValues()
{
  // Round down to a whole second to make round-tripping work.
  // 'max' is 1 second away from from the end of the day, instead of 1 nanosecond away from the end of the day
  var max = Instant.maxValue - new Span(seconds: 1) + Span.epsilon;
  var x = max.toUnixTimeTicks();
  var t = new Instant.fromUnixTimeTicks(x);
  expect(max, new Instant.fromUnixTimeSeconds(max.toUnixTimeSeconds()));
  expect(max, new Instant.fromUnixTimeMilliseconds(max.toUnixTimeMilliseconds()));
  expect(max, new Instant.fromUnixTimeTicks(max.toUnixTimeTicks()));

  var min = Instant.minValue;
  expect(min, new Instant.fromUnixTimeSeconds(min.toUnixTimeSeconds()));
  expect(min, new Instant.fromUnixTimeMilliseconds(min.toUnixTimeMilliseconds()));
  expect(min, new Instant.fromUnixTimeTicks(min.toUnixTimeTicks()));
}

@Test()
Future InZoneWithCalendar () async
{
  CalendarSystem copticCalendar = CalendarSystem.Coptic;
  DateTimeZone london = await (await DateTimeZoneProviders.Tzdb)["Europe/London"];
  ZonedDateTime viaInstant = new Instant.fromUtc(2004, 6, 9, 11, 10).InZone_Calendar(london, copticCalendar);

  // Date taken from CopticCalendarSystemTest. Time will be 12:10 (London is UTC+1 in Summer)
  LocalDateTime local = new LocalDateTime.fromYMDHMSC(1720, 10, 2, 12, 10, 0, copticCalendar);
  ZonedDateTime expected = london.AtStrictly(local);
  expect(viaInstant, expected);
}

@Test()
void Max()
{
  Instant x = new Instant.fromUnixTimeTicks(100);
  Instant y = new Instant.fromUnixTimeTicks(200);
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
  Instant x = new Instant.fromUnixTimeTicks(100);
  Instant y = new Instant.fromUnixTimeTicks(200);
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
  Instant x = new Instant.fromUtc(2011, 08, 18, 20, 53);
  DateTime expected = new DateTime.utc(2011, 08, 18, 20, 53, 0);
  DateTime actual = x.toDateTimeUtc();
  expect(expected, actual);

  // Kind isn't checked by Equals...
  expect(true, actual.isUtc);
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

/// <summary>
/// Using the default constructor is equivalent to January 1st 1970, midnight, UTC, ISO Calendar
/// </summary>
@Test()
void DefaultConstructor()
{
  var actual = new Instant();
  expect(TimeConstants.unixEpoch, actual);
}

@Test()
@TestCase(const [-101, -2])
@TestCase(const [-100, -1])
@TestCase(const [-99, -1])
@TestCase(const [-1, -1])
@TestCase(const [0, 0])
@TestCase(const [99, 0])
@TestCase(const [100, 1])
@TestCase(const [101, 1])
void TicksTruncatesDown(int nanoseconds, int expectedTicks)
{
  Span nanos = new Span(nanoseconds: nanoseconds);
  Instant instant = new Instant.untrusted(nanos); //.FromUntrustedDuration(nanos);
  expect(instant.toUnixTimeTicks(), expectedTicks);
}

@Test()
void IsValid()
{
  expect(Instant.beforeMinValue.IsValid, isFalse);
  expect(Instant.minValue.IsValid, isTrue);
  expect(Instant.maxValue.IsValid, isTrue);
  expect(Instant.afterMaxValue.IsValid, isFalse);
}

@Test()
void InvalidValues()
{
  expect(Instant.afterMaxValue, greaterThan(Instant.maxValue));
  expect(Instant.beforeMinValue, lessThan(Instant.minValue));
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
  Span hugeAndPositive = Instant.maxValue - Instant.minValue;
  Span hugeAndNegative = Instant.minValue - Instant.maxValue;
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
  int smallestValid = Instant.minValue.toUnixTimeTicks() ~/ TimeConstants.ticksPerMillisecond;
  int largestValid = Instant.maxValue.toUnixTimeTicks() ~/ TimeConstants.ticksPerMillisecond;
  //expect(() => new Instant.fromUnixTimeMilliseconds(smallestValid), isNot(throwsException));
  //expect(() => new Instant.fromUnixTimeMilliseconds(smallestValid - 1), throwsException);
  //expect(() => new Instant.fromUnixTimeMilliseconds(largestValid), isNot(throwsException));
  //expect(() => new Instant.fromUnixTimeMilliseconds(largestValid + 1), throwsException);

  //TestHelper.AssertValid(Instant.fromUnixTimeMilliseconds, smallestValid);
  //TestHelper.AssertOutOfRange(Instant.fromUnixTimeMilliseconds, smallestValid - 1);
  //TestHelper.AssertValid(Instant.FromUnixTimeMilliseconds, largestValid);
  //TestHelper.AssertOutOfRange(Instant.FromUnixTimeMilliseconds, largestValid + 1);
}

@Test()
void FromUnixTimeSeconds_Range()
{
  // todo: I owe you, out of range behavior
  int smallestValid = Instant.minValue.toUnixTimeTicks() ~/ TimeConstants.ticksPerSecond;
  int largestValid = Instant.maxValue.toUnixTimeTicks() ~/ TimeConstants.ticksPerSecond;
  //TestHelper.AssertValid(Instant.FromUnixTimeSeconds, smallestValid);
  //TestHelper.AssertOutOfRange(Instant.FromUnixTimeSeconds, smallestValid - 1);
  //TestHelper.AssertValid(Instant.FromUnixTimeSeconds, largestValid);
  //TestHelper.AssertOutOfRange(Instant.FromUnixTimeSeconds, largestValid + 1);
}

@Test()
void FromTicksSinceUnixEpoch_Range()
{
  // todo: I owe you, out of range behavior
  int smallestValid = Instant.minValue.toUnixTimeTicks();
  int largestValid = Instant.maxValue.toUnixTimeTicks();
  //TestHelper.AssertValid(Instant.FromUnixTimeTicks, smallestValid);
  //TestHelper.AssertOutOfRange(Instant.FromUnixTimeTicks, smallestValid - 1);
  //TestHelper.AssertValid(Instant.FromUnixTimeTicks, largestValid);
  //TestHelper.AssertOutOfRange(Instant.FromUnixTimeTicks, largestValid + 1);
}

@Test()
void PlusOffset()
{
  var localInstant = TimeConstants.unixEpoch.plusOffset(new Offset.fromHours(1));
  expect(new Span(hours: 1), localInstant.TimeSinceLocalEpoch);
}

@Test()
void SafePlus_NormalTime()
{
  var localInstant = TimeConstants.unixEpoch.SafePlus(new Offset.fromHours(1));
  expect(new Span(hours: 1), localInstant.TimeSinceLocalEpoch);
}

@Test()
@TestCase(const [null, 0, null])
@TestCase(const [null, 1, null])
@TestCase(const [null, -1, null])
@TestCase(const [1, -1, 0])
@TestCase(const [1, -2, null])
@TestCase(const [2, 1, 3])
void SafePlus_NearStartOfTime(int initialOffset, int offsetToAdd, int finalOffset) {
  // This unit test fails... on some of the case..
  // todo: what is this unit test doing?

  var start = initialOffset == null
      ? Instant.beforeMinValue
      : Instant.minValue + new Span(hours: initialOffset);
  var expected = finalOffset == null
      ? LocalInstant.BeforeMinValue
      : Instant.minValue.plusOffset(new Offset.fromHours(finalOffset));
  var actual = start.SafePlus(new Offset.fromHours(offsetToAdd));
  expect(actual, expected);
}

// A null offset indicates "AfterMaxValue". Otherwise, MaxValue.Plus(offset)
@Test()
@TestCase(const [null, 0, null])
@TestCase(const [null, 1, null])
@TestCase(const [null, -1, null])
@TestCase(const [-1, 1, 0])
@TestCase(const [-1, 2, null])
@TestCase(const [-2, -1, -3])
void SafePlus_NearEndOfTime(int initialOffset, int offsetToAdd, int finalOffset) {
  // Has the same issues as above
  // todo: what is this unit test doing?

  var start = initialOffset == null
      ? Instant.afterMaxValue
      : Instant.maxValue + new Span(hours: initialOffset);
  var expected = finalOffset == null
      ? LocalInstant.AfterMaxValue
      : Instant.maxValue.plusOffset(new Offset.fromHours(finalOffset));
  var actual = start.SafePlus(new Offset.fromHours(offsetToAdd));
  expect(actual, expected);
}


