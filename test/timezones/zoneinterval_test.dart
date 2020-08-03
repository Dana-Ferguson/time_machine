// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import '../time_machine_testing.dart';

Future main() async {
  await runTests();
}

final Instant SampleStart = Instant.utc(2011, 6, 3, 10, 15);
final Instant SampleEnd = Instant.utc(2011, 8, 2, 13, 45);

final ZoneInterval SampleInterval =
IZoneInterval.newZoneInterval('TestTime', SampleStart, SampleEnd,
Offset.hours(9), Offset.hours(1));

@Test()
void PassthroughProperties()
{
  expect('TestTime', SampleInterval.name);
  expect(Offset.hours(8), SampleInterval.standardOffset);
  expect(Offset.hours(1), SampleInterval.savings);
  expect(Offset.hours(9), SampleInterval.wallOffset);
  expect(SampleStart, SampleInterval.start);
  expect(SampleEnd, SampleInterval.end);
}

// Having one test per property feels like a waste of time to me (Jon)...
// If any of them fail, I'm going to be looking here anyway, and they're
// fairly interrelated anyway.
@Test()
void ComputedProperties()
{
  LocalDateTime start = LocalDateTime(2011, 6, 3, 19, 15, 0);
  LocalDateTime end = LocalDateTime(2011, 8, 2, 22, 45, 0);
  expect(start, SampleInterval.isoLocalStart);
  expect(end, SampleInterval.isoLocalEnd);
  expect(SampleStart.timeUntil(SampleEnd), SampleInterval.totalTime);
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
  ZoneInterval interval = IZoneInterval.newZoneInterval('All Time', null, null,
      Offset.hours(9), Offset.hours(1));
  expect(interval.contains(SampleStart), isTrue);
  expect(interval.contains(Instant.minValue), isTrue);
  expect(interval.contains(Instant.maxValue), isTrue);
}

@Test()
void Contains_Instant_WholeOfTime_ViaSpecialInstants()
{
  ZoneInterval interval = IZoneInterval.newZoneInterval('All Time', IInstant.beforeMinValue, IInstant.afterMaxValue,
      Offset.hours(9), Offset.hours(1));
  expect(interval.contains(SampleStart), isTrue);
  expect(interval.contains(Instant.minValue), isTrue);
  expect(interval.contains(Instant.maxValue), isTrue);
}

@Test()
void Contains_LocalInstant_WholeOfTime()
{
  ZoneInterval interval = IZoneInterval.newZoneInterval('All Time', IInstant.beforeMinValue, IInstant.afterMaxValue,
      Offset.hours(9), Offset.hours(1));
  expect(IZoneInterval.containsLocal(interval, IInstant.plusOffset(SampleStart, Offset.zero)), isTrue);
  expect(IZoneInterval.containsLocal(interval, IInstant.plusOffset(Instant.minValue, Offset.zero)), isTrue);
  expect(IZoneInterval.containsLocal(interval, IInstant.plusOffset(Instant.maxValue, Offset.zero)), isTrue);
}

@Test()
void Contains_OutsideLocalInstantange()
{
  ZoneInterval veryEarly = IZoneInterval.newZoneInterval('Very early', IInstant.beforeMinValue, Instant.minValue + Time(hours: 8), Offset.hours(-9), Offset.zero);
  ZoneInterval veryLate = IZoneInterval.newZoneInterval('Very late', Instant.maxValue - Time(hours: 8), IInstant.afterMaxValue, Offset.hours(9), Offset.zero);
  // The instants are contained...
  expect(veryEarly.contains(Instant.minValue + Time(hours: 4)), isTrue);
  expect(veryLate.contains(Instant.maxValue - Time(hours: 4)), isTrue);
  // But there are no valid local instants
  expect(IZoneInterval.containsLocal(veryEarly, IInstant.plusOffset(Instant.minValue, Offset.zero)), isFalse);
  expect(IZoneInterval.containsLocal(veryLate, IInstant.plusOffset(Instant.maxValue, Offset.zero)), isFalse);
}

@Test()
void IsoLocalStartAndEnd_Infinite()
{
  var interval = IZoneInterval.newZoneInterval('All time', null, null, Offset.zero, Offset.zero);
  // Assert.Throws<InvalidOperationException>
  expect(() => interval.isoLocalStart.toString(), throwsStateError);
  expect(() => interval.isoLocalEnd.toString(), throwsStateError);
}

@Test()
void IsoLocalStartAndEnd_OutOfRange()
{
  var interval = IZoneInterval.newZoneInterval('All time', Instant.minValue, null, Offset.hours(-1), Offset.zero);
  // Assert.Throws<OverflowException>
  expect(() => interval.isoLocalStart.toString(), throwsRangeError);
  interval = IZoneInterval.newZoneInterval('All time', null, Instant.maxValue, Offset.hours(11), Offset.zero);
  expect(() => interval.isoLocalEnd.toString(), throwsRangeError);
}

@Test()
void Equality()
{
  TestHelper.TestEqualsClass(
      // Equal values
      IZoneInterval.newZoneInterval('name', SampleStart, SampleEnd, Offset.hours(1), Offset.hours(2)),
      IZoneInterval.newZoneInterval('name', SampleStart, SampleEnd, Offset.hours(1), Offset.hours(2)),
      // Unequal values
      [IZoneInterval.newZoneInterval('name2', SampleStart, SampleEnd, Offset.hours(1), Offset.hours(2)),
      IZoneInterval.newZoneInterval('name', SampleStart.add(Time.epsilon), SampleEnd, Offset.hours(1), Offset.hours(2)),
      IZoneInterval.newZoneInterval('name', SampleStart, SampleEnd.add(Time.epsilon), Offset.hours(1), Offset.hours(2)),
      IZoneInterval.newZoneInterval('name', SampleStart, SampleEnd, Offset.hours(2), Offset.hours(2)),
      IZoneInterval.newZoneInterval('name', SampleStart, SampleEnd, Offset.hours(1), Offset.hours(3))]);
}
