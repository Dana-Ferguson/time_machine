// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
// import 'package:matcher/matcher.dart';

import 'time_machine_testing.dart';

Future main() async {
  await TimeMachine.initialize();
  await runTests();
}

@Test()
void Equality()
{
  LocalInstant equal = LocalInstant.daysNanos(1, 100);
  LocalInstant equal2 = LocalInstant.daysNanos(1, 100);
  LocalInstant different1 = LocalInstant.daysNanos(1, 200);
  LocalInstant different2 = LocalInstant.daysNanos(2, 100);

  TestHelper.TestEqualsStruct(equal, equal2, [different1]);
  TestHelper.TestOperatorEquality(equal, equal2, different1);

  TestHelper.TestEqualsStruct(equal, equal2, [different2]);
  TestHelper.TestOperatorEquality(equal, equal2, different2);
}

@Test()
void MinusOffset_Zero_IsNeutralElement()
{
  Instant sampleInstant = IInstant.trusted(Time(days: 1, nanoseconds: 23456));
  LocalInstant sampleLocalInstant = LocalInstant.daysNanos(1, 23456);
  expect(sampleInstant, sampleLocalInstant.minus(Offset.zero));
  expect(sampleInstant, sampleLocalInstant.minusZeroOffset());
}

@Test()
@TestCase([0, 0, '1970-01-01T00:00:00 LOC'])
@TestCase([0, 1, '1970-01-01T00:00:00.000000001 LOC'])
@TestCase([0, 1000, '1970-01-01T00:00:00.000001 LOC'])
@TestCase([0, 1000000, '1970-01-01T00:00:00.001 LOC'])
@TestCase([-1, TimeConstants.nanosecondsPerDay - 1, '1969-12-31T23:59:59.999999999 LOC'])
void ToString_Valid(int day, int nanoOfDay, String expectedText)
{
  var localInstant = LocalInstant.daysNanos(day, nanoOfDay);
  expect(localInstant.daysSinceEpoch, day);
  expect(localInstant.toString(), expectedText);
}

@Test()
void ToString_Extremes()
{
  expect(InstantPatternParser.beforeMinValueText, LocalInstant.beforeMinValue.toString());
  expect(InstantPatternParser.afterMaxValueText, LocalInstant.afterMaxValue.toString());
}

@Test()
void SafeMinus_NormalTime()
{
  var start = LocalInstant.daysNanos(0, 0);
  var end = start.safeMinus(Offset.hours(1));
  expect(Time(hours: -1), end.timeSinceEpoch);
}

// A null offset indicates 'BeforeMinValue'. Otherwise, MinValue.Plus(offset)
@Test()
@TestCase([null, 0, null])
@TestCase([null, 1, null])
@TestCase([null, -1, null])
@TestCase([1, 1, 0])
@TestCase([1, 2, null])
@TestCase([2, 1, 1])
void SafeMinus_NearStartOfTime(int? initialOffset, int offsetToSubtract, int? finalOffset) {
  var start = initialOffset == null
      ? LocalInstant.beforeMinValue
      : IInstant.plusOffset(Instant.minValue, Offset.hours(initialOffset));
  var expected = finalOffset == null
      ? IInstant.beforeMinValue
      : Instant.minValue + Time(hours: finalOffset);
  var actual = start.safeMinus(Offset.hours(offsetToSubtract));
  expect(actual, expected);
}

// A null offset indicates 'AfterMaxValue'. Otherwise, MaxValue.Plus(offset)
@Test()
@TestCase([null, 0, null])
@TestCase([null, 1, null])
@TestCase([null, -1, null])
@TestCase([-1, -1, 0])
@TestCase([-1, -2, null])
@TestCase([-2, -1, -1])
void SafeMinus_NearEndOfTime(int? initialOffset, int offsetToSubtract, int? finalOffset) {
  var start = initialOffset == null
      ? LocalInstant.afterMaxValue
      : IInstant.plusOffset(Instant.maxValue, Offset.hours(initialOffset));
  var expected = finalOffset == null
      ? IInstant.afterMaxValue
      : Instant.maxValue + Time(hours: finalOffset);
  var actual = start.safeMinus(Offset.hours(offsetToSubtract));
  expect(expected, actual);
}

