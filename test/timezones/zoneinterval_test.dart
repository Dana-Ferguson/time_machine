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
  expect(new Offset.fromHours(8), SampleInterval.standardOffset);
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
  LocalDateTime start = new LocalDateTime.at(2011, 6, 3, 19, 15);
  LocalDateTime end = new LocalDateTime.at(2011, 8, 2, 22, 45);
  expect(start, SampleInterval.isoLocalStart);
  expect(end, SampleInterval.isoLocalEnd);
  expect(SampleEnd - SampleStart, SampleInterval.span);
}

@Test()
void Contains_Instant_Normal()
{
  expect(SampleInterval.contains(SampleStart), isTrue);
  expect(SampleInterval.contains(SampleEnd), isFalse);
  expect(SampleInterval.contains(Instant.minValue), isFalse);
  expect(SampleInterval.contains(Instant.maxValue), isFalse);
}

@Test()
void Contains_Instant_WholeOfTime_ViaNullity()
{
  ZoneInterval interval = new ZoneInterval("All Time", null, null,
      new Offset.fromHours(9), new Offset.fromHours(1));
  expect(interval.contains(SampleStart), isTrue);
  expect(interval.contains(Instant.minValue), isTrue);
  expect(interval.contains(Instant.maxValue), isTrue);
}

@Test()
void Contains_Instant_WholeOfTime_ViaSpecialInstants()
{
  ZoneInterval interval = new ZoneInterval("All Time", IInstant.beforeMinValue, IInstant.afterMaxValue,
      new Offset.fromHours(9), new Offset.fromHours(1));
  expect(interval.contains(SampleStart), isTrue);
  expect(interval.contains(Instant.minValue), isTrue);
  expect(interval.contains(Instant.maxValue), isTrue);
}

@Test()
void Contains_LocalInstant_WholeOfTime()
{
  ZoneInterval interval = new ZoneInterval("All Time", IInstant.beforeMinValue, IInstant.afterMaxValue,
      new Offset.fromHours(9), new Offset.fromHours(1));
  expect(interval.containsLocal(IInstant.plusOffset(SampleStart, Offset.zero)), isTrue);
  expect(interval.containsLocal(IInstant.plusOffset(Instant.minValue, Offset.zero)), isTrue);
  expect(interval.containsLocal(IInstant.plusOffset(Instant.maxValue, Offset.zero)), isTrue);
}

@Test()
void Contains_OutsideLocalInstantange()
{
  ZoneInterval veryEarly = new ZoneInterval("Very early", IInstant.beforeMinValue, Instant.minValue + new Span(hours: 8), new Offset.fromHours(-9), Offset.zero);
  ZoneInterval veryLate = new ZoneInterval("Very late", Instant.maxValue - new Span(hours: 8), IInstant.afterMaxValue, new Offset.fromHours(9), Offset.zero);
  // The instants are contained...
  expect(veryEarly.contains(Instant.minValue + new Span(hours: 4)), isTrue);
  expect(veryLate.contains(Instant.maxValue - new Span(hours: 4)), isTrue);
  // But there are no valid local instants
  expect(veryEarly.containsLocal(IInstant.plusOffset(Instant.minValue, Offset.zero)), isFalse);
  expect(veryLate.containsLocal(IInstant.plusOffset(Instant.maxValue, Offset.zero)), isFalse);
}

@Test()
void IsoLocalStartAndEnd_Infinite()
{
  var interval = new ZoneInterval("All time", null, null, Offset.zero, Offset.zero);
  // Assert.Throws<InvalidOperationException>
  expect(() => interval.isoLocalStart.toString(), throwsStateError);
  expect(() => interval.isoLocalEnd.toString(), throwsStateError);
}

@Test()
void IsoLocalStartAndEnd_OutOfRange()
{
  var interval = new ZoneInterval("All time", Instant.minValue, null, new Offset.fromHours(-1), Offset.zero);
  // Assert.Throws<OverflowException>
  expect(() => interval.isoLocalStart.toString(), throwsRangeError);
  interval = new ZoneInterval("All time", null, Instant.maxValue, new Offset.fromHours(11), Offset.zero);
  expect(() => interval.isoLocalEnd.toString(), throwsRangeError);
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
