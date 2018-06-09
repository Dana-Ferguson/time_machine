// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

@Test()
void Equality()
{
  LocalInstant equal = new LocalInstant.daysNanos(1, 100);
  LocalInstant equal2 = new LocalInstant.daysNanos(1, 100);
  LocalInstant different1 = new LocalInstant.daysNanos(1, 200);
  LocalInstant different2 = new LocalInstant.daysNanos(2, 100);

  TestHelper.TestEqualsStruct(equal, equal2, [different1]);
  TestHelper.TestOperatorEquality(equal, equal2, different1);

  TestHelper.TestEqualsStruct(equal, equal2, [different2]);
  TestHelper.TestOperatorEquality(equal, equal2, different2);
}

@Test()
void MinusOffset_Zero_IsNeutralElement()
{
  Instant sampleInstant = new Instant.trusted(new Span(days: 1, nanoseconds: 23456));
  LocalInstant sampleLocalInstant = new LocalInstant.daysNanos(1, 23456);
  expect(sampleInstant, sampleLocalInstant.Minus(Offset.zero));
  expect(sampleInstant, sampleLocalInstant.MinusZeroOffset());
}

@Test()
@TestCase(const [0, 0, "1970-01-01T00:00:00 LOC"])
@TestCase(const [0, 1, "1970-01-01T00:00:00.000000001 LOC"])
@TestCase(const [0, 1000, "1970-01-01T00:00:00.000001 LOC"])
@TestCase(const [0, 1000000, "1970-01-01T00:00:00.001 LOC"])
@TestCase(const [-1, TimeConstants.nanosecondsPerDay - 1, "1969-12-31T23:59:59.999999999 LOC"])
void ToString_Valid(int day, int nanoOfDay, String expectedText)
{
  var localInstant = new LocalInstant.daysNanos(day, nanoOfDay);
  expect(localInstant.DaysSinceEpoch, day);
  expect(localInstant.toString(), expectedText);
}

@Test()
void ToString_Extremes()
{
  expect(InstantPatternParser.BeforeMinValueText, LocalInstant.BeforeMinValue.toString());
  expect(InstantPatternParser.AfterMaxValueText, LocalInstant.AfterMaxValue.toString());
}

@Test()
void SafeMinus_NormalTime()
{
  var start = new LocalInstant.daysNanos(0, 0);
  var end = start.SafeMinus(new Offset.fromHours(1));
  expect(new Span(hours: -1), end.timeSinceEpoch);
}

// A null offset indicates "BeforeMinValue". Otherwise, MinValue.Plus(offset)
@Test()
@TestCase(const [null, 0, null])
@TestCase(const [null, 1, null])
@TestCase(const [null, -1, null])
@TestCase(const [1, 1, 0])
@TestCase(const [1, 2, null])
@TestCase(const [2, 1, 1])
void SafeMinus_NearStartOfTime(int initialOffset, int offsetToSubtract, int finalOffset) {
  var start = initialOffset == null
      ? LocalInstant.BeforeMinValue
      : Instant.minValue.plusOffset(new Offset.fromHours(initialOffset));
  var expected = finalOffset == null
      ? Instant.beforeMinValue
      : Instant.minValue + new Span(hours: finalOffset);
  var actual = start.SafeMinus(new Offset.fromHours(offsetToSubtract));
  expect(actual, expected);
}

// A null offset indicates "AfterMaxValue". Otherwise, MaxValue.Plus(offset)
@Test()
@TestCase(const [null, 0, null])
@TestCase(const [null, 1, null])
@TestCase(const [null, -1, null])
@TestCase(const [-1, -1, 0])
@TestCase(const [-1, -2, null])
@TestCase(const [-2, -1, -1])
void SafeMinus_NearEndOfTime(int initialOffset, int offsetToSubtract, int finalOffset) {
  var start = initialOffset == null
      ? LocalInstant.AfterMaxValue
      : Instant.maxValue.plusOffset(new Offset.fromHours(initialOffset));
  var expected = finalOffset == null
      ? Instant.afterMaxValue
      : Instant.maxValue + new Span(hours: finalOffset);
  var actual = start.SafeMinus(new Offset.fromHours(offsetToSubtract));
  expect(expected, actual);
}

