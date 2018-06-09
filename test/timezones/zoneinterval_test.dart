// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import '../time_machine_testing.dart';

Future main() async {
  await runTests();
}

final Instant SampleStart = new Instant.fromUtc(2011, 6, 3, 10, 15);
final Instant SampleEnd = new Instant.fromUtc(2011, 8, 2, 13, 45);

final ZoneInterval SampleInterval =
new ZoneInterval("TestTime", SampleStart, SampleEnd,
new Offset.fromHours(9), new Offset.fromHours(1));

@Test()
void PassthroughProperties()
{
  expect("TestTime", SampleInterval.name);
  expect(new Offset.fromHours(8), SampleInterval.StandardOffset);
  expect(new Offset.fromHours(1), SampleInterval.savings);
  expect(new Offset.fromHours(9), SampleInterval.wallOffset);
  expect(SampleStart, SampleInterval.start);
  expect(SampleEnd, SampleInterval.end);
}

// Having one test per property feels like a waste of time to me (Jon)...
// If any of them fail, I'm going to be looking here anyway, and they're
// fairly interrelated anyway.
@Test()
void ComputedProperties()
{
  LocalDateTime start = new LocalDateTime.fromYMDHM(2011, 6, 3, 19, 15);
  LocalDateTime end = new LocalDateTime.fromYMDHM(2011, 8, 2, 22, 45);
  expect(start, SampleInterval.IsoLocalStart);
  expect(end, SampleInterval.IsoLocalEnd);
  expect(SampleEnd - SampleStart, SampleInterval.span);
}

@Test()
void Contains_Instant_Normal()
{
  expect(SampleInterval.Contains(SampleStart), isTrue);
  expect(SampleInterval.Contains(SampleEnd), isFalse);
  expect(SampleInterval.Contains(Instant.minValue), isFalse);
  expect(SampleInterval.Contains(Instant.maxValue), isFalse);
}

@Test()
void Contains_Instant_WholeOfTime_ViaNullity()
{
  ZoneInterval interval = new ZoneInterval("All Time", null, null,
      new Offset.fromHours(9), new Offset.fromHours(1));
  expect(interval.Contains(SampleStart), isTrue);
  expect(interval.Contains(Instant.minValue), isTrue);
  expect(interval.Contains(Instant.maxValue), isTrue);
}

@Test()
void Contains_Instant_WholeOfTime_ViaSpecialInstants()
{
  ZoneInterval interval = new ZoneInterval("All Time", Instant.beforeMinValue, Instant.afterMaxValue,
      new Offset.fromHours(9), new Offset.fromHours(1));
  expect(interval.Contains(SampleStart), isTrue);
  expect(interval.Contains(Instant.minValue), isTrue);
  expect(interval.Contains(Instant.maxValue), isTrue);
}

@Test()
void Contains_LocalInstant_WholeOfTime()
{
  ZoneInterval interval = new ZoneInterval("All Time", Instant.beforeMinValue, Instant.afterMaxValue,
      new Offset.fromHours(9), new Offset.fromHours(1));
  expect(interval.ContainsLocal(SampleStart.plusOffset(Offset.zero)), isTrue);
  expect(interval.ContainsLocal(Instant.minValue.plusOffset(Offset.zero)), isTrue);
  expect(interval.ContainsLocal(Instant.maxValue.plusOffset(Offset.zero)), isTrue);
}

@Test()
void Contains_OutsideLocalInstantange()
{
  ZoneInterval veryEarly = new ZoneInterval("Very early", Instant.beforeMinValue, Instant.minValue + new Span(hours: 8), new Offset.fromHours(-9), Offset.zero);
  ZoneInterval veryLate = new ZoneInterval("Very late", Instant.maxValue - new Span(hours: 8), Instant.afterMaxValue, new Offset.fromHours(9), Offset.zero);
  // The instants are contained...
  expect(veryEarly.Contains(Instant.minValue + new Span(hours: 4)), isTrue);
  expect(veryLate.Contains(Instant.maxValue - new Span(hours: 4)), isTrue);
  // But there are no valid local instants
  expect(veryEarly.ContainsLocal(Instant.minValue.plusOffset(Offset.zero)), isFalse);
  expect(veryLate.ContainsLocal(Instant.maxValue.plusOffset(Offset.zero)), isFalse);
}

@Test()
void IsoLocalStartAndEnd_Infinite()
{
  var interval = new ZoneInterval("All time", null, null, Offset.zero, Offset.zero);
  // Assert.Throws<InvalidOperationException>
  expect(() => interval.IsoLocalStart.toString(), throwsStateError);
  expect(() => interval.IsoLocalEnd.toString(), throwsStateError);
}

@Test()
void IsoLocalStartAndEnd_OutOfRange()
{
  var interval = new ZoneInterval("All time", Instant.minValue, null, new Offset.fromHours(-1), Offset.zero);
  // Assert.Throws<OverflowException>
  expect(() => interval.IsoLocalStart.toString(), throwsRangeError);
  interval = new ZoneInterval("All time", null, Instant.maxValue, new Offset.fromHours(11), Offset.zero);
  expect(() => interval.IsoLocalEnd.toString(), throwsRangeError);
}

@Test()
void Equality()
{
  TestHelper.TestEqualsClass(
      // Equal values
      new ZoneInterval("name", SampleStart, SampleEnd, new Offset.fromHours(1), new Offset.fromHours(2)),
      new ZoneInterval("name", SampleStart, SampleEnd, new Offset.fromHours(1), new Offset.fromHours(2)),
      // Unequal values
      [new ZoneInterval("name2", SampleStart, SampleEnd, new Offset.fromHours(1), new Offset.fromHours(2)),
      new ZoneInterval("name", SampleStart.plus(Span.epsilon), SampleEnd, new Offset.fromHours(1), new Offset.fromHours(2)),
      new ZoneInterval("name", SampleStart, SampleEnd.plus(Span.epsilon), new Offset.fromHours(1), new Offset.fromHours(2)),
      new ZoneInterval("name", SampleStart, SampleEnd, new Offset.fromHours(2), new Offset.fromHours(2)),
      new ZoneInterval("name", SampleStart, SampleEnd, new Offset.fromHours(1), new Offset.fromHours(3))]);
}
