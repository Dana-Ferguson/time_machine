// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
// --- https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/InstantTest.cs
// --- 0913621  on Aug 26, 2017

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import 'time_machine_testing.dart';

Future main() async {
  await TimeMachine.initialize();
  await runTests();
}

/// Using the default constructor is equivalent to Span.Zero.
@Test()
void DefaultConstructor()
{
  var actual = Time();
  expect(Time.zero, actual);
}

// Tests copied from Nanoseconds in its brief existence... there may well be some overlap between
// this and older Time tests.

@Test()
// todo: this doesn't work so well, because the `%` operation fails here, see Duration.Dart#L128 :: nanoseconds = nanoseconds % TimeConstants.nanosecondsPerMillisecond;
// @TestCase(const [Platform.int64MinValue])
@TestCase([Platform.int64MinValue + 1])
@TestCase([-TimeConstants.nanosecondsPerDay - 1])
@TestCase([-TimeConstants.nanosecondsPerDay])
@TestCase([-TimeConstants.nanosecondsPerDay + 1])
@TestCase([-1])
@TestCase([0])
@TestCase([1])
@TestCase([TimeConstants.nanosecondsPerDay - 1])
@TestCase([TimeConstants.nanosecondsPerDay])
@TestCase([TimeConstants.nanosecondsPerDay + 1])
@TestCase([Platform.int64MaxValue - 1])
@TestCase([Platform.int64MaxValue])
void Int64Conversions(int int64Nanos)
{
  if (Platform.isVM) {
    var nanoseconds = Time(nanoseconds: int64Nanos);
    expect(int64Nanos, nanoseconds.totalNanoseconds); // .toInt64Nanoseconds());
  }
}

@Test()
@TestCase([Platform.int64MinValue])
@TestCase([Platform.int64MinValue + 1])
@TestCase([-TimeConstants.nanosecondsPerDay - 1])
@TestCase([-TimeConstants.nanosecondsPerDay])
@TestCase([-TimeConstants.nanosecondsPerDay + 1])
@TestCase([-1])
@TestCase([0])
@TestCase([1])
@TestCase([TimeConstants.nanosecondsPerDay - 1])
@TestCase([TimeConstants.nanosecondsPerDay])
@TestCase([TimeConstants.nanosecondsPerDay + 1])
@TestCase([Platform.int64MaxValue - 1])
@TestCase([Platform.int64MaxValue])
void BigIntegerConversions(int int64Nanos)
{
  var bigIntegerNanos = BigInt.from(int64Nanos);
  var nanoseconds = Time.bigIntNanoseconds(bigIntegerNanos);
  expect(bigIntegerNanos, nanoseconds.inNanosecondsAsBigInt);

  // And multiply it by 100, which proves we still work for values out of the range of Int64
  bigIntegerNanos *= BigInt.from(100);
  nanoseconds = Time.bigIntNanoseconds(bigIntegerNanos);
  expect(bigIntegerNanos, nanoseconds.inNanosecondsAsBigInt);
}

@Test()
void ConstituentParts_Positive()
{
  var nanos = Time(nanoseconds: TimeConstants.nanosecondsPerDay * 5 + 100);
  expect(5, Instant.epochTime(nanos).epochDay);
  expect(5, ITime.epochDay(nanos));
  expect(100, ITime.nanosecondOfEpochDay(nanos));
  expect(100, Instant.epochTime(nanos).epochDayTime.inNanoseconds);
}

@Test()
void ConstituentParts_Negative()
{
  var nanos = Time(nanoseconds: TimeConstants.nanosecondsPerDay * -5 + 100);
  expect(-5, Instant.epochTime(nanos).epochDay);
  expect(-5, ITime.epochDay(nanos));
  expect(100, Instant.epochTime(nanos).epochDayTime.inNanoseconds);
  expect(100, ITime.nanosecondOfEpochDay(nanos));
}

@Test()
void ConstituentParts_Large() {
  // And outside the normal range of long...
  var nanos = Time.bigIntNanoseconds(BigInt.from(TimeConstants.nanosecondsPerDay) * BigInt.from(365000) + BigInt.from(500));
  expect(365000, Instant.epochTime(nanos).epochDay);

  if (Platform.isVM) {
    expect(500, ITime.nanosecondOfEpochDay(nanos));
    expect(500, Instant.epochTime(nanos).epochDayTime.inNanoseconds);
  }
}

@Test()
@TestCase([1, 100, 2, 200, 3, 300])
@TestCase([1, TimeConstants.nanosecondsPerDay - 5, 3, 100, 5, 95], 'Overflow')
@TestCase([1, 10, -1, TimeConstants.nanosecondsPerDay - 100, 0, TimeConstants.nanosecondsPerDay - 90], 'Underflow')
void Addition_Subtraction(int leftDays, int leftNanos,
    int rightDays, int rightNanos,
    int resultDays, int resultNanos)
{
  var left = Time(days: leftDays, nanoseconds: leftNanos);
  var right = Time(days: rightDays, nanoseconds: rightNanos);
  var result = Time(days: resultDays, nanoseconds: resultNanos);

  expect(result, left + right);
  expect(result, left.add(right));
// expect(result, Span.add(left, right));

  expect(left, result - right);
  expect(left, result.subtract(right));
// expect(left, Span.subtract(result, right));
}

@Test()
void Equality()
{
  var equal1 = Time(days: 1, nanoseconds: TimeConstants.nanosecondsPerHour);
  var equal2 = Time(microseconds: TimeConstants.microsecondsPerHour * 25);
  var different1 = Time(days: 1, nanoseconds: 200);
  var different2 = Time(days: 2, nanoseconds: TimeConstants.microsecondsPerHour);

  TestHelper.TestEqualsStruct(equal1, equal2, [different1]);
  TestHelper.TestOperatorEquality(equal1, equal2, different1);

  TestHelper.TestEqualsStruct(equal1, equal2, [different2]);
  TestHelper.TestOperatorEquality(equal1, equal2, different2);
}

@Test()
void Comparison()
{
  var equal1 = Time(days: 1, nanoseconds: TimeConstants.nanosecondsPerHour);
  var equal2 = Time(microseconds: TimeConstants.microsecondsPerHour * 25);
  var greater1 = Time(days: 1, nanoseconds: TimeConstants.nanosecondsPerHour + 1);
  var greater2 = Time(days: 2, nanoseconds: 0);

  TestHelper.TestCompareToStruct<Time>(equal1, equal2, [greater1]);
  // TestHelper.TestNonGenericCompareTo(equal1, equal2, [greater1]);
  TestHelper.TestOperatorComparisonEquality<Time>(equal1, equal2, [greater1, greater2]);
}

@Test()
@TestCase([1, 5, 2, 2, 10], 'Small, positive')
@TestCase([-1, TimeConstants.nanosecondsPerDay - 10, 2, -1, TimeConstants.nanosecondsPerDay - 20], 'Small, negative')
@TestCase([365000, 1, 2, 365000 * 2, 2], 'More than 2^63 nanos before multiplication')
@TestCase([1000, 1, 365, 365000, 365], 'More than 2^63 nanos after multiplication')
@TestCase([1000, 1, -365, -365001, TimeConstants.nanosecondsPerDay - 365], 'Less than -2^63 nanos after multiplication')
@TestCase([0, 1, TimeConstants.nanosecondsPerDay, 1, 0], 'Large scalar')
void Multiplication(int startDays, int startNanoOfDay, int scalar, int expectedDays, int expectedNanoOfDay)
{
  var start = Time(days: startDays, nanoseconds: startNanoOfDay);
  var expected = Time(days: expectedDays, nanoseconds: expectedNanoOfDay);
  expect(expected, start * scalar);
}

@Test()
@TestCase([0, 0, 0, 0])
@TestCase([1, 0, -1, 0])
@TestCase([0, 500, -1, TimeConstants.nanosecondsPerDay - 500])
@TestCase([365000, 500, -365001, TimeConstants.nanosecondsPerDay - 500])
void UnaryNegation(int startDays, int startNanoOfDay, int expectedDays, int expectedNanoOfDay)
{
  var start = Time(days: startDays, nanoseconds: startNanoOfDay);
  var expected = Time(days: expectedDays, nanoseconds: expectedNanoOfDay);
  expect(expected, -start);
  // Test it the other way round as well...
  expect(start, -expected);
}

@Test()
// Test cases around 0
@TestCase([-1, TimeConstants.nanosecondsPerDay - 1, TimeConstants.nanosecondsPerDay, 0, 0])
@TestCase([0, 0, TimeConstants.nanosecondsPerDay, 0, 0])
@TestCase([0, 1, TimeConstants.nanosecondsPerDay, 0, 0])

// Test cases around dividing -1 day by 'nanos per day'
@TestCase([-2, TimeConstants.nanosecondsPerDay - 1, TimeConstants.nanosecondsPerDay, -1, TimeConstants.nanosecondsPerDay - 1]) // -1ns
@TestCase([-1, 0, TimeConstants.nanosecondsPerDay, -1, TimeConstants.nanosecondsPerDay - 1]) // -1ns
@TestCase([-1, 1, TimeConstants.nanosecondsPerDay, 0, 0])

// Test cases around dividing 1 day by 'nanos per day'
@TestCase([0, TimeConstants.nanosecondsPerDay - 1, TimeConstants.nanosecondsPerDay, 0, 0])
@TestCase([1, 0, TimeConstants.nanosecondsPerDay, 0, 1])
@TestCase([1, TimeConstants.nanosecondsPerDay - 1, TimeConstants.nanosecondsPerDay, 0, 1])
@TestCase([10, 20, 5, 2, 4])

// Large value, which will use decimal arithmetic
@TestCase([365000, 3000, 1000, 365, 3])
void Division(int startDays, int startNanoOfDay, int divisor, int expectedDays, int expectedNanoOfDay)
{
  var start = Time(days: startDays, nanoseconds: startNanoOfDay);
  var expected = Time(days: expectedDays, nanoseconds: expectedNanoOfDay);
  if (Platform.isVM) {
    expect(expected, start / divisor);
  } else {
    expect((expected - (start / divisor)).totalNanoseconds.abs(), lessThan(5));
  }
}

//@Test()
//void BclCompatibleTick_Zero()
//{
//  expect(0, new Span(ticks: 0).BclCompatibleTicks);
//  expect(0, new Span(nanoseconds: 99).BclCompatibleTicks);
//  expect(0, new Span(nanoseconds: -99).BclCompatibleTicks);
//}

//@Test()
//@TestCase(const [5])
//@TestCase(const [TimeConstants.ticksPerDay * 2])
//@TestCase(const [TimeConstants.ticksPerDay * 365000])
//void BclCompatibleTick_Positive(int ticks)
//{
//  expect(ticks > 0, isTrue);
//  Span start = new Span(ticks: ticks);
//  expect(ticks, start.BclCompatibleTicks);
//
//  // We truncate towards zero... so subtracting 1 nanosecond should
//  // reduce the number of ticks, and adding 99 nanoseconds should not change it
//  expect(ticks - 1, start.MinusSmallNanoseconds(1L).BclCompatibleTicks);
//  expect(ticks, start.PlusSmallNanoseconds(99L).BclCompatibleTicks);
//}

//@Test()
//@TestCase(const [-5])
//@TestCase(const [-TimeConstants.ticksPerDay * 2])
//@TestCase(const [-TimeConstants.ticksPerDay * 365000])
//void BclCompatibleTicks_Negative(int ticks)
//{
//  Assert.IsTrue(ticks < 0);
//  Span start = Span.FromTicks(ticks);
//  expect(ticks, start.BclCompatibleTicks);
//
//  // We truncate towards zero... so subtracting 99 nanoseconds should
//  // have no effect, and adding 1 should increase the number of ticks
//  expect(ticks, start.MinusSmallNanoseconds(99L).BclCompatibleTicks);
//  expect(ticks + 1, start.PlusSmallNanoseconds(1L).BclCompatibleTicks);
//}

//@Test()
//void BclCompatibleTicks_MinValue()
//{
//  Assert.Throws<OverflowException>(() => Span.MinValue.BclCompatibleTicks.ToString());
//}

@Test()
void Validation()
{
//TestHelper.AssertValid(Span.FromDays, (1 << 24) - 1);
//TestHelper.AssertOutOfRange(Span.FromDays, 1 << 24);
//TestHelper.AssertValid(Span.FromDays, -(1 << 24));
//TestHelper.AssertOutOfRange(Span.FromDays, -(1 << 24) - 1);

  // todo: I owe you out of range behavior
  expect(Time(days: (1 << 24) - 1), isNot(throwsException));
  //expect(new Span(days: (1 << 24)), throwsException);
  expect(Time(days: -(1 << 24)), isNot(throwsException));
//expect(new Span(days: -(1 << 24) - 1), throwsException);
}

//@Test('Overflow')
//// [Category('Overflow'])
//void BclCompatibleTicks_Overflow()
//{
//  Span maxTicks = Span.FromTicks(int.MaxValue) + Span.FromTicks(1);
//  Assert.Throws<OverflowException>(() => maxTicks.BclCompatibleTicks.ToString());
//}

@Test()
void PositiveComponents()
{
  // Worked out with a calculator :)
  Time duration = Time(nanoseconds: 1234567890123456);
  expect(14, duration.inDays);
  expect(24967890123456, ITime.nanosecondOfDurationDay(duration));
  expect(6, duration.hourOfDay);
  expect(56, duration.minuteOfHour);
  expect(7, duration.secondOfMinute);
  expect(890, duration.millisecondOfSecond);
  expect(890123, duration.microsecondOfSecond);
  expect(890123456, duration.nanosecondOfSecond);
}

@Test()
void NegativeComponents()
{
  // Worked out with a calculator :) // -1234567 890123456
  Time duration = Time(nanoseconds: -1234567890123456);
  expect(-14, duration.inDays);
  expect(-24967890123456, ITime.nanosecondOfDurationDay(duration));
  expect(-6, duration.hourOfDay);
  expect(-56, duration.minuteOfHour);
  expect(-7, duration.secondOfMinute);
  expect(-890, duration.millisecondOfSecond);
  expect(-890123, duration.microsecondOfSecond);
  expect(-890123456, duration.nanosecondOfSecond);
}

@Test()
void PositiveTotals()
{
  Time duration = Time(days: 4) + Time(hours: 3) + Time(minutes: 2) + Time(seconds: 1)
      + Time(nanoseconds: 123456789);
  expect(4.1264, closeTo(duration.totalDays, 0.0001));
  expect(99.0336, closeTo(duration.totalHours, 0.0001));
  expect(5942.0187, closeTo(duration.totalMinutes, 0.0001));
  expect(356521.123456789, closeTo(duration.totalSeconds, 0.000000001));
  expect(356521123.456789, closeTo(duration.totalMilliseconds, 0.000001));
  expect(356521123456.789/*d*/, closeTo(duration.totalMicroseconds, 0.01));
  expect(356521123456789/*d*/, closeTo(duration.totalNanoseconds, 1));
}

@Test()
void NegativeTotals()
{
  Time duration = Time(days: -4) + Time(hours: -3) + Time(minutes: -2) + Time(seconds: -1)
      + Time(nanoseconds: -123456789);
  expect(-4.1264, closeTo(duration.totalDays, 0.0001));
  expect(-99.0336, closeTo(duration.totalHours, 0.0001));
  expect(-5942.0187, closeTo(duration.totalMinutes, 0.0001));
  expect(-356521.123456789, closeTo(duration.totalSeconds, 0.000000001));
  expect(-356521123.456789, closeTo(duration.totalMilliseconds, 0.000001));
  expect(-356521123456789/*d*/, closeTo(duration.totalNanoseconds, 1));
}

@Test()
void MaxMinRelationship()
{
  // Max and Min work like they do for other signed types - basically the max value is one less than the absolute
  // of the min value.
  expect(Time.minValue, -Time.maxValue - Time.epsilon);
}

@Test()
void Max()
{
  Time x = Time(nanoseconds: 100);
  Time y = Time(nanoseconds: 200);
  expect(y, Time.max(x, y));
  expect(y, Time.max(y, x));
  expect(x, Time.max(x, Time.minValue));
  expect(x, Time.max(Time.minValue, x));
  expect(Time.maxValue, Time.max(Time.maxValue, x));
  expect(Time.maxValue, Time.max(x, Time.maxValue));
}

@Test()
void Min()
{
  Time x = Time(nanoseconds: 100);
  Time y = Time(nanoseconds: 200);
  expect(x, Time.min(x, y));
  expect(x, Time.min(y, x));
  expect(Time.minValue, Time.min(x, Time.minValue));
  expect(Time.minValue, Time.min(Time.minValue, x));
  expect(x, Time.min(Time.maxValue, x));
  expect(x, Time.min(x, Time.maxValue));
}

@Test()
void ComplexConstructor() {
  expect(Time(days: 1.5).totalDays, 1.5);
  expect(Time(hours: 1.5).totalHours, 1.5);
  expect(Time(minutes: 1.5).totalMinutes, 1.5);
  expect(Time(seconds: 1.5).totalSeconds, 1.5);
  expect(Time(milliseconds: 1.5).totalMilliseconds, 1.5);
  expect(Time(microseconds: 1.5).totalMicroseconds, 1.5);
  expect(Time(nanoseconds: 1.5).totalNanoseconds, 1);
}
