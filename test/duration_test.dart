// --- https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/InstantTest.cs
// --- 0913621  on Aug 26, 2017

import 'dart:async';

import 'package:time_machine/time_machine.dart';
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import 'time_machine_test.dart';

Future main() async {
  await runTests();
}

/// <summary>
/// Using the default constructor is equivalent to Span.Zero.
/// </summary>
@Test()
void DefaultConstructor()
{
  var actual = new Span();
  expect(Span.zero, actual);
}

// Tests copied from Nanoseconds in its brief existence... there may well be some overlap between
// this and older Span tests.

@Test()
@TestCase(const [Utility.int64MinValue])
@TestCase(const [Utility.int64MinValue + 1])
@TestCase(const [-TimeConstants.nanosecondsPerDay - 1])
@TestCase(const [-TimeConstants.nanosecondsPerDay])
@TestCase(const [-TimeConstants.nanosecondsPerDay + 1])
@TestCase(const [-1])
@TestCase(const [0])
@TestCase(const [1])
@TestCase(const [TimeConstants.nanosecondsPerDay - 1])
@TestCase(const [TimeConstants.nanosecondsPerDay])
@TestCase(const [TimeConstants.nanosecondsPerDay + 1])
@TestCase(const [Utility.int64MaxValue - 1])
@TestCase(const [Utility.int64MaxValue])
void Int64Conversions(int int64Nanos)
{
  var nanoseconds = new Span(nanoseconds: int64Nanos);
  expect(int64Nanos, nanoseconds.totalNanoseconds); // .toInt64Nanoseconds());
}

@Test()
@TestCase(const [Utility.int64MinValue])
@TestCase(const [Utility.int64MinValue + 1])
@TestCase(const [-TimeConstants.nanosecondsPerDay - 1])
@TestCase(const [-TimeConstants.nanosecondsPerDay])
@TestCase(const [-TimeConstants.nanosecondsPerDay + 1])
@TestCase(const [-1])
@TestCase(const [0])
@TestCase(const [1])
@TestCase(const [TimeConstants.nanosecondsPerDay - 1])
@TestCase(const [TimeConstants.nanosecondsPerDay])
@TestCase(const [TimeConstants.nanosecondsPerDay + 1])
@TestCase(const [Utility.int64MaxValue - 1])
@TestCase(const [Utility.int64MaxValue])
void BigIntegerConversions(int int64Nanos)
{
  // todo: BigInteger is a separate class in Dart2.0
  /*BigInteger*/ int bigIntegerNanos = int64Nanos;
  var nanoseconds = new Span(nanoseconds: bigIntegerNanos);
  expect(bigIntegerNanos, nanoseconds.totalNanoseconds); // .ToBigIntegerNanoseconds());

  // And multiply it by 100, which proves we still work for values out of the range of Int64
  bigIntegerNanos *= 100;
  nanoseconds = new Span(nanoseconds: bigIntegerNanos);
  expect(bigIntegerNanos, nanoseconds.totalNanoseconds); // .ToBigIntegerNanoseconds());
}

@Test()
void ConstituentParts_Positive()
{
  var nanos = new Span(nanoseconds: TimeConstants.nanosecondsPerDay * 5 + 100);
  expect(5, nanos.floorDays);
  expect(100, nanos.nanosecondOfFloorDay);
}

@Test()
void ConstituentParts_Negative()
{
  var nanos = new Span(nanoseconds: TimeConstants.nanosecondsPerDay * -5 + 100);
  expect(-5, nanos.floorDays);
  expect(100, nanos.nanosecondOfFloorDay);
}

@Test()
void ConstituentParts_Large() {
  // And outside the normal range of long...
  var nanos = new Span(nanoseconds: TimeConstants.nanosecondsPerDay * /*(BigInteger)*/ 365000 + /*(BigInteger)*/ 500);
  expect(365000, nanos.floorDays);
  expect(500, nanos.nanosecondOfFloorDay);
}

@Test()
@TestCase(const [1, 100, 2, 200, 3, 300])
@TestCase(const [1, TimeConstants.nanosecondsPerDay - 5, 3, 100, 5, 95], "Overflow")
@TestCase(const [1, 10, -1, TimeConstants.nanosecondsPerDay - 100, 0, TimeConstants.nanosecondsPerDay - 90], "Underflow")
void Addition_Subtraction(int leftDays, int leftNanos,
    int rightDays, int rightNanos,
    int resultDays, int resultNanos)
{
  var left = new Span(days: leftDays, nanoseconds: leftNanos);
  var right = new Span(days: rightDays, nanoseconds: rightNanos);
  var result = new Span(days: resultDays, nanoseconds: resultNanos);

  expect(result, left + right);
  expect(result, left.plus(right));
  // expect(result, Span.add(left, right));

  expect(left, result - right);
  expect(left, result.minus(right));
  // expect(left, Span.subtract(result, right));
}

@Test()
void Equality()
{
  var equal1 = new Span(days: 1, nanoseconds: TimeConstants.nanosecondsPerHour);
  var equal2 = new Span(ticks: TimeConstants.ticksPerHour * 25);
  var different1 = new Span(days: 1, nanoseconds: 200);
  var different2 = new Span(days: 2, nanoseconds: TimeConstants.ticksPerHour);

  TestHelper.TestEqualsStruct(equal1, equal2, [different1]);
  TestHelper.TestOperatorEquality(equal1, equal2, different1);

  TestHelper.TestEqualsStruct(equal1, equal2, [different2]);
  TestHelper.TestOperatorEquality(equal1, equal2, different2);
}

@Test()
void Comparison()
{
  var equal1 = new Span(days: 1, nanoseconds: TimeConstants.nanosecondsPerHour);
  var equal2 = new Span(ticks: TimeConstants.ticksPerHour * 25);
  var greater1 = new Span(days: 1, nanoseconds: TimeConstants.nanosecondsPerHour + 1);
  var greater2 = new Span(days: 2, nanoseconds: 0);

  TestHelper.TestCompareToStruct<Span>(equal1, equal2, [greater1]);
  // TestHelper.TestNonGenericCompareTo(equal1, equal2, [greater1]);
  TestHelper.TestOperatorComparisonEquality<Span>(equal1, equal2, [greater1, greater2]);
}

@Test()
@TestCase(const [1, 5, 2, 2, 10], "Small, positive")
@TestCase(const [-1, TimeConstants.nanosecondsPerDay - 10, 2, -1, TimeConstants.nanosecondsPerDay - 20], "Small, negative")
@TestCase(const [365000, 1, 2, 365000 * 2, 2], "More than 2^63 nanos before multiplication")
@TestCase(const [1000, 1, 365, 365000, 365], "More than 2^63 nanos after multiplication")
@TestCase(const [1000, 1, -365, -365001, TimeConstants.nanosecondsPerDay - 365], "Less than -2^63 nanos after multiplication")
@TestCase(const [0, 1, TimeConstants.nanosecondsPerDay, 1, 0], "Large scalar")
void Multiplication(int startDays, int startNanoOfDay, int scalar, int expectedDays, int expectedNanoOfDay)
{
  var start = new Span(days: startDays, nanoseconds: startNanoOfDay);
  var expected = new Span(days: expectedDays, nanoseconds: expectedNanoOfDay);
  expect(expected, start * scalar);
}

@Test()
@TestCase(const [0, 0, 0, 0])
@TestCase(const [1, 0, -1, 0])
@TestCase(const [0, 500, -1, TimeConstants.nanosecondsPerDay - 500])
@TestCase(const [365000, 500, -365001, TimeConstants.nanosecondsPerDay - 500])
void UnaryNegation(int startDays, int startNanoOfDay, int expectedDays, int expectedNanoOfDay)
{
  var start = new Span(days: startDays, nanoseconds: startNanoOfDay);
  var expected = new Span(days: expectedDays, nanoseconds: expectedNanoOfDay);
  expect(expected, -start);
  // Test it the other way round as well...
  expect(start, -expected);
}

@Test()
// Test cases around 0
@TestCase(const [-1, TimeConstants.nanosecondsPerDay - 1, TimeConstants.nanosecondsPerDay, 0, 0])
@TestCase(const [0, 0, TimeConstants.nanosecondsPerDay, 0, 0])
@TestCase(const [0, 1, TimeConstants.nanosecondsPerDay, 0, 0])

// Test cases around dividing -1 day by "nanos per day"
@TestCase(const [-2, TimeConstants.nanosecondsPerDay - 1, TimeConstants.nanosecondsPerDay, -1, TimeConstants.nanosecondsPerDay - 1]) // -1ns
@TestCase(const [-1, 0, TimeConstants.nanosecondsPerDay, -1, TimeConstants.nanosecondsPerDay - 1]) // -1ns
@TestCase(const [-1, 1, TimeConstants.nanosecondsPerDay, 0, 0])

// Test cases around dividing 1 day by "nanos per day"
@TestCase(const [0, TimeConstants.nanosecondsPerDay - 1, TimeConstants.nanosecondsPerDay, 0, 0])
@TestCase(const [1, 0, TimeConstants.nanosecondsPerDay, 0, 1])
@TestCase(const [1, TimeConstants.nanosecondsPerDay - 1, TimeConstants.nanosecondsPerDay, 0, 1])
@TestCase(const [10, 20, 5, 2, 4])

// Large value, which will use decimal arithmetic
@TestCase(const [365000, 3000, 1000, 365, 3])
void Division(int startDays, int startNanoOfDay, int divisor, int expectedDays, int expectedNanoOfDay)
{
  var start = new Span(days: startDays, nanoseconds: startNanoOfDay);
  var expected = new Span(days: expectedDays, nanoseconds: expectedNanoOfDay);
  //print('expected = $expected');
  //print('actual = ${start / divisor};');
  //print('start = $start;');
  //print('divisor = $divisor;');
  expect(expected, start / divisor);
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
  expect(new Span(days: (1 << 24) - 1), isNot(throwsException));
  //expect(new Span(days: (1 << 24)), throwsException);
  expect(new Span(days: -(1 << 24)), isNot(throwsException));
  //expect(new Span(days: -(1 << 24) - 1), throwsException);
}

//@Test("Overflow")
//// [Category("Overflow"])
//void BclCompatibleTicks_Overflow()
//{
//  Span maxTicks = Span.FromTicks(int.MaxValue) + Span.FromTicks(1);
//  Assert.Throws<OverflowException>(() => maxTicks.BclCompatibleTicks.ToString());
//}

@Test()
void PositiveComponents()
{
  // Worked out with a calculator :)
  Span duration = new Span(nanoseconds: 1234567890123456);
  expect(14, duration.days);
  expect(24967890123456, duration.nanosecondOfDay);
  expect(6, duration.hours);
  expect(56, duration.minutes);
  expect(7, duration.seconds);
  expect(890, duration.milliseconds);
  expect(8901234, duration.subsecondTicks);
  expect(890123456, duration.subsecondNanoseconds);
}

@Test()
void NegativeComponents()
{
  // Worked out with a calculator :)
  Span duration = new Span(nanoseconds: -1234567890123456);
  expect(-14, duration.days);
  // todo: our implementation won't go 'negative' for the subcomponents -- should we change it?
  expect(-24967890123456 + TimeConstants.nanosecondsPerDay, duration.nanosecondOfDay);
  expect(-6 + TimeConstants.hoursPerDay, duration.hours);
  expect(-56 + TimeConstants.minutesPerHour, duration.minutes);
  expect(-7 + TimeConstants.secondsPerMinute, duration.seconds);
  // todo: '- 1' maybe shouldn't be there, floor implementation?
  expect(-890 + TimeConstants.millisecondsPerSecond - 1, duration.milliseconds);
  expect(-8901234 + TimeConstants.ticksPerSecond - 1, duration.subsecondTicks);
  expect(-890123456 + TimeConstants.nanosecondsPerSecond, duration.subsecondNanoseconds);
}

@Test()
void PositiveTotals()
{
  Span duration = new Span(days: 4) + new Span(hours: 3) + new Span(minutes: 2) + new Span(seconds: 1)
      + new Span(nanoseconds: 123456789);
  expect(4.1264, closeTo(duration.totalDays, 0.0001));
  expect(99.0336, closeTo(duration.totalHours, 0.0001));
  expect(5942.0187, closeTo(duration.totalMinutes, 0.0001));
  expect(356521.123456789, closeTo(duration.totalSeconds, 0.000000001));
  expect(356521123.456789, closeTo(duration.totalMilliseconds, 0.000001));
  expect(3565211234567.89/*d*/, closeTo(duration.totalTicks, 0.01));
  expect(356521123456789/*d*/, closeTo(duration.totalNanoseconds, 1));
}

@Test()
void NegativeTotals()
{
  Span duration = new Span(days: -4) + new Span(hours: -3) + new Span(minutes: -2) + new Span(seconds: -1)
      + new Span(nanoseconds: -123456789);
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
  expect(Span.minValue, -Span.maxValue - Span.epsilon);
}

@Test()
void Max()
{
  Span x = new Span(nanoseconds: 100);
  Span y = new Span(nanoseconds: 200);
  expect(y, Span.max(x, y));
  expect(y, Span.max(y, x));
  expect(x, Span.max(x, Span.minValue));
  expect(x, Span.max(Span.minValue, x));
  expect(Span.maxValue, Span.max(Span.maxValue, x));
  expect(Span.maxValue, Span.max(x, Span.maxValue));
}

@Test()
void Min()
{
  Span x = new Span(nanoseconds: 100);
  Span y = new Span(nanoseconds: 200);
  expect(x, Span.min(x, y));
  expect(x, Span.min(y, x));
  expect(Span.minValue, Span.min(x, Span.minValue));
  expect(Span.minValue, Span.min(Span.minValue, x));
  expect(x, Span.min(Span.maxValue, x));
  expect(x, Span.min(x, Span.maxValue));
}