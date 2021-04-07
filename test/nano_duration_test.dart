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
@TestCase([-TimeConstants.nanosecondsPerDay - 1])
@TestCase([-TimeConstants.nanosecondsPerDay])
@TestCase([-TimeConstants.nanosecondsPerDay + 1])
@TestCase([-1])
@TestCase([0])
@TestCase([1])
@TestCase([TimeConstants.nanosecondsPerDay - 1])
@TestCase([TimeConstants.nanosecondsPerDay])
@TestCase([TimeConstants.nanosecondsPerDay + 1])
void Int64Conversions(int int64Nanos)
{
  var nanoseconds = NanosecondTime(int64Nanos);
  expect(int64Nanos, nanoseconds.inNanoseconds); // .toInt64Nanoseconds());
}

@Test()
void ConstituentParts_Positive()
{
  var nanos = NanosecondTime(TimeConstants.nanosecondsPerDay * 5 + 100);
  expect(5, Instant.epochTime(nanos).epochDay);
  expect(5, ITime.epochDay(nanos));
  expect(100, ITime.nanosecondOfEpochDay(nanos));
  expect(100, Instant.epochTime(nanos).epochDayTime.inNanoseconds);
}

@Test()
void ConstituentParts_Negative()
{
  var nanos = NanosecondTime(TimeConstants.nanosecondsPerDay * -5 + 100);
  expect(-5, Instant.epochTime(nanos).epochDay);
  expect(-5, ITime.epochDay(nanos));
  expect(100, ITime.nanosecondOfEpochDay(nanos));
  expect(100, Instant.epochTime(nanos).epochDayTime.inNanoseconds);
}

@Test()
@TestCase([1, 100, 2, 200, 3, 300])
@TestCase([1, TimeConstants.nanosecondsPerDay - 5, 3, 100, 5, 95], 'Overflow')
@TestCase([1, 10, -1, TimeConstants.nanosecondsPerDay - 100, 0, TimeConstants.nanosecondsPerDay - 90], 'Underflow')
void Addition_Subtraction(int leftDays, int leftNanos,
    int rightDays, int rightNanos,
    int resultDays, int resultNanos)
{
  var left = NanosecondTime(Time(days: leftDays, nanoseconds: leftNanos).inNanoseconds);
  var right = NanosecondTime(Time(days: rightDays, nanoseconds: rightNanos).inNanoseconds);
  var result = NanosecondTime(Time(days: resultDays, nanoseconds: resultNanos).inNanoseconds);

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
  var equal1 = NanosecondTime(Time(days: 1, nanoseconds: TimeConstants.nanosecondsPerHour).inNanoseconds);
  var equal2 = NanosecondTime(Time(microseconds: TimeConstants.microsecondsPerHour * 25).inNanoseconds);
  var different1 = NanosecondTime(Time(days: 1, nanoseconds: 200).inNanoseconds);
  var different2 = NanosecondTime(Time(days: 2, nanoseconds: TimeConstants.microsecondsPerHour).inNanoseconds);

  TestHelper.TestEqualsStruct(equal1, equal2, [different1]);
  TestHelper.TestOperatorEquality(equal1, equal2, different1);

  TestHelper.TestEqualsStruct(equal1, equal2, [different2]);
  TestHelper.TestOperatorEquality(equal1, equal2, different2);
}

@Test()
void Comparison()
{
  var equal1 = NanosecondTime(Time(days: 1, nanoseconds: TimeConstants.nanosecondsPerHour).inNanoseconds);
  var equal2 = NanosecondTime(Time(microseconds: TimeConstants.microsecondsPerHour * 25).inNanoseconds);
  var greater1 = NanosecondTime(Time(days: 1, nanoseconds: TimeConstants.nanosecondsPerHour + 1).inNanoseconds);
  var greater2 = NanosecondTime(Time(days: 2, nanoseconds: 0).inNanoseconds);

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
  var _start = Time(days: startDays, nanoseconds: startNanoOfDay);
  if (_start.canNanosecondsBeInteger) {
    var start = NanosecondTime(_start.inNanoseconds);
    var expected = Time(days: expectedDays, nanoseconds: expectedNanoOfDay);
    expect(expected, start * scalar);
  }
}

@Test()
@TestCase([0, 0, 0, 0])
@TestCase([1, 0, -1, 0])
@TestCase([0, 500, -1, TimeConstants.nanosecondsPerDay - 500])
void UnaryNegation(int startDays, int startNanoOfDay, int expectedDays, int expectedNanoOfDay)
{
  var start = NanosecondTime(Time(days: startDays, nanoseconds: startNanoOfDay).inNanoseconds);
  var expected = NanosecondTime(Time(days: expectedDays, nanoseconds: expectedNanoOfDay).inNanoseconds);
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
// On VM (max: 106751 days) this will be NanosecondTime; on JS (max:52 days) this will be Time
@TestCase([365000, 3000, 1000, 365, 3])
void Division(int startDays, int startNanoOfDay, int divisor, int expectedDays, int expectedNanoOfDay)
{
  var _start = Time(days: startDays, nanoseconds: startNanoOfDay);
  var _expected = Time(days: expectedDays, nanoseconds: expectedNanoOfDay);
  var start = _start.canNanosecondsBeInteger ? NanosecondTime(_start.inNanoseconds) : _start;
  var expected = _expected.canNanosecondsBeInteger ? NanosecondTime(_expected.inNanoseconds) : _expected;
  if (Platform.isVM) {
    expect(start / divisor, expected);
  } else {
    expect((expected - (start / divisor)).totalNanoseconds.abs(), lessThan(5));
  }
}

@Test()
void PositiveComponents()
{
  // Worked out with a calculator :)
  Time duration = NanosecondTime(1234567890123456);
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
  Time duration = NanosecondTime(-1234567890123456);
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
      + NanosecondTime(123456789);
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
      + NanosecondTime(-123456789);
  expect(-4.1264, closeTo(duration.totalDays, 0.0001));
  expect(-99.0336, closeTo(duration.totalHours, 0.0001));
  expect(-5942.0187, closeTo(duration.totalMinutes, 0.0001));
  expect(-356521.123456789, closeTo(duration.totalSeconds, 0.000000001));
  expect(-356521123.456789, closeTo(duration.totalMilliseconds, 0.000001));
  expect(-356521123456789/*d*/, closeTo(duration.totalNanoseconds, 1));
}

@Test()
void Max()
{
  Time x = NanosecondTime(100);
  Time y = NanosecondTime(200);
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
  Time x = NanosecondTime(100);
  Time y = NanosecondTime(200);
  expect(x, Time.min(x, y));
  expect(x, Time.min(y, x));
  expect(Time.minValue, Time.min(x, Time.minValue));
  expect(Time.minValue, Time.min(Time.minValue, x));
  expect(x, Time.min(Time.maxValue, x));
  expect(x, Time.min(x, Time.maxValue));
}
