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

final ZoneInterval firstInterval =
IZoneInterval.newZoneInterval('First', IInstant.beforeMinValue, Instant.utc(2000, 3, 10, 10, 0), Offset.hours(3), Offset.zero);

// Note that this is effectively UTC +3 + 1 hour DST.
final ZoneInterval secondInterval =
IZoneInterval.newZoneInterval('Second', firstInterval.end, Instant.utc(2000, 9, 15, 5, 0), Offset.hours(4), Offset.hours(1));

final ZoneInterval thirdInterval =
IZoneInterval.newZoneInterval('Third', secondInterval.end, Instant.utc(2005, 1, 20, 8, 0), Offset.hours(-5), Offset.zero);

final ZoneRecurrence winter = ZoneRecurrence('Winter', Offset.zero,
ZoneYearOffset(TransitionMode.wall, 10, 5, 0, false, LocalTime(2, 0, 0)), 1960, Platform.int32MaxValue);

final ZoneRecurrence summer = ZoneRecurrence('Summer', Offset.hours(1),
ZoneYearOffset(TransitionMode.wall, 3, 10, 0, false, LocalTime(1, 0, 0)), 1960, Platform.int32MaxValue);

final StandardDaylightAlternatingMap tailZone =
StandardDaylightAlternatingMap(Offset.hours(-6), winter, summer);

// We don't actually want an interval from the beginning of time when we ask our composite time zone for an interval
// - because that could give the wrong idea. So we clamp it at the end of the precalculated interval.
final ZoneInterval clampedTailZoneInterval = IZoneInterval.withStart(tailZone.getZoneInterval(thirdInterval.end), thirdInterval.end)!;

final PrecalculatedDateTimeZone TestZone =
PrecalculatedDateTimeZone('Test', [ firstInterval, secondInterval, thirdInterval ], tailZone);

@Test()
void MinMaxOffsets()
{
  expect(Offset.hours(-6), TestZone.minOffset);
  expect(Offset.hours(4), TestZone.maxOffset);
}

@Test()
void MinMaxOffsetsWithOtherTailZone()
{
  var tailZone = FixedDateTimeZone.forIdOffset('TestFixed', Offset.hours(8));
  var testZone = PrecalculatedDateTimeZone('Test',
      [ firstInterval, secondInterval, thirdInterval ], tailZone);
  expect(Offset.hours(-5), testZone.minOffset);
  expect(Offset.hours(8), testZone.maxOffset);
}

@Test()
void MinMaxOffsetsWithNullTailZone()
{
  var testZone = PrecalculatedDateTimeZone('Test',
      [ firstInterval, secondInterval, thirdInterval,
      IZoneInterval.newZoneInterval('Last', thirdInterval.end, IInstant.afterMaxValue, Offset.zero, Offset.zero) ], null);
  expect(Offset.hours(-5), testZone.minOffset);
  expect(Offset.hours(4), testZone.maxOffset);
}

@Test()
void GetZoneIntervalInstant_End()
{
  expect(secondInterval, TestZone.getZoneInterval(secondInterval.end - Time.epsilon));
}

@Test()
void GetZoneIntervalInstant_Start()
{
  expect(secondInterval, TestZone.getZoneInterval(secondInterval.start));
}

@Test()
void GetZoneIntervalInstant_FinalInterval_End()
{
  expect(thirdInterval, TestZone.getZoneInterval(thirdInterval.end - Time.epsilon));
}

@Test()
void GetZoneIntervalInstant_FinalInterval_Start()
{
  expect(thirdInterval, TestZone.getZoneInterval(thirdInterval.start));
}

@Test()
void GetZoneIntervalInstant_TailZone()
{
  expect(clampedTailZoneInterval, TestZone.getZoneInterval(thirdInterval.end));
}

@Test()
void MapLocal_UnambiguousInPrecalculated()
{
  CheckMapping(LocalDateTime(2000, 6, 1, 0, 0, 0), secondInterval, secondInterval, 1);
}

@Test()
void MapLocal_UnambiguousInTailZone()
{
  CheckMapping(LocalDateTime(2005, 2, 1, 0, 0, 0), clampedTailZoneInterval, clampedTailZoneInterval, 1);
}

@Test()
void MapLocal_AmbiguousWithinPrecalculated()
{
  // Transition from +4 to -5 has a 9 hour ambiguity
  CheckMapping(thirdInterval.isoLocalStart, secondInterval, thirdInterval, 2);
}

@Test()
void MapLocal_AmbiguousAroundTailZoneTransition()
{
  // Transition from -5 to -6 has a 1 hour ambiguity
  // CheckMapping(thirdInterval.IsoLocalEnd.PlusNanoseconds(-1L), thirdInterval, clampedTailZoneInterval, 2);
  CheckMapping(thirdInterval.isoLocalEnd.addNanoseconds(-1), thirdInterval, clampedTailZoneInterval, 2);
}

@Test()
void MapLocal_AmbiguousButTooEarlyInTailZoneTransition()
{
  // Tail zone is +10 / +8, with the transition occurring just after
  // the transition *to* the tail zone from the precalculated zone.
  // A local instant of one hour before after the transition from the precalculated zone (which is -5)
  // will therefore be ambiguous, but the resulting instants from the ambiguity occur
  // before our transition into the tail zone, so are ignored.
  var tailZone = SingleTransitionDateTimeZone.around(thirdInterval.end + Time(hours: 1), 10, 8);
  var gapZone = PrecalculatedDateTimeZone('Test',
      [ firstInterval, secondInterval, thirdInterval ], tailZone);
  var mapping = gapZone.mapLocal(thirdInterval.isoLocalEnd.addHours(-1));
  expect(thirdInterval, mapping.earlyInterval);
  expect(thirdInterval, mapping.lateInterval);
  expect(1, mapping.count);
}

@Test()
void MapLocal_GapWithinPrecalculated()
{
  // Transition from +3 to +4 has a 1 hour gap
  expect(firstInterval.isoLocalEnd < secondInterval.isoLocalStart, isTrue);
  CheckMapping(firstInterval.isoLocalEnd, firstInterval, secondInterval, 0);
}

@Test()
void MapLocal_SingleIntervalAroundTailZoneTransition()
{
  // Tail zone is fixed at +5. A local instant of one hour before the transition
  // from the precalculated zone (which is -5) will therefore give an instant from
  // the tail zone which occurs before the precalculated-to-tail transition,
  // and can therefore be ignored, resulting in an overall unambiguous time.
  var tailZone = FixedDateTimeZone.forOffset(Offset.hours(5));
  var gapZone = PrecalculatedDateTimeZone('Test',
      [ firstInterval, secondInterval, thirdInterval ], tailZone);
  var mapping = gapZone.mapLocal(thirdInterval.isoLocalEnd.addHours(-1));
  expect(thirdInterval, mapping.earlyInterval);
  expect(thirdInterval, mapping.lateInterval);
  expect(1, mapping.count);
}

@Test()
void MapLocal_GapAroundTailZoneTransition()
{
  // Tail zone is fixed at +5. A local time at the transition
  // from the precalculated zone (which is -5) will therefore give an instant from
  // the tail zone which occurs before the precalculated-to-tail transition,
  // and can therefore be ignored, resulting in an overall gap.
  var tailZone = FixedDateTimeZone.forOffset(Offset.hours(5));
  var gapZone = PrecalculatedDateTimeZone('Test',
      [ firstInterval, secondInterval, thirdInterval ], tailZone);
  var mapping = gapZone.mapLocal(thirdInterval.isoLocalEnd);
  expect(thirdInterval, mapping.earlyInterval);
  expect(mapping.lateInterval,
      IZoneInterval.newZoneInterval('UTC+05', thirdInterval.end, IInstant.afterMaxValue, Offset.hours(5), Offset.zero));
  expect(0, mapping.count);
}

@Test()
void MapLocal_GapAroundAndInTailZoneTransition()
{
  // Tail zone is -10 / +5, with the transition occurring just after
  // the transition *to* the tail zone from the precalculated zone.
  // A local time of one hour after the transition from the precalculated zone (which is -5)
  // will therefore be in the gap.
  var tailZone = SingleTransitionDateTimeZone.around(thirdInterval.end + Time(hours: 1), -10, 5);
  var gapZone = PrecalculatedDateTimeZone('Test',
      [ firstInterval, secondInterval, thirdInterval ], tailZone);
  var mapping = gapZone.mapLocal(thirdInterval.isoLocalEnd.addHours(1));
  expect(thirdInterval, mapping.earlyInterval);
  expect(IZoneInterval.newZoneInterval('Single-Early', thirdInterval.end, tailZone.Transition, Offset.hours(-10), Offset.zero),
      mapping.lateInterval);
  expect(0, mapping.count);
}

@Test()
void GetZoneIntervals_NullTailZone_Eot()
{
  List<ZoneInterval> intervals =
  [
    IZoneInterval.newZoneInterval('foo', IInstant.beforeMinValue, Instant.fromEpochMicroseconds(2), Offset.zero, Offset.zero),
  IZoneInterval.newZoneInterval('foo', Instant.fromEpochMicroseconds(2), IInstant.afterMaxValue, Offset.zero, Offset.zero)
];
var zone = PrecalculatedDateTimeZone('Test', intervals, null);
expect(intervals[1], zone.getZoneInterval(Instant.maxValue));
}

void CheckMapping(LocalDateTime localDateTime, ZoneInterval earlyInterval, ZoneInterval lateInterval, int count)
{
  var mapping = TestZone.mapLocal(localDateTime);
  expect(earlyInterval, mapping.earlyInterval);
  expect(lateInterval, mapping.lateInterval);
  expect(count, mapping.count);
}

@Test()
void Validation_EmptyPeriodArray() {
  // Assert.Throws<ArgumentException>
  expect(() =>
      PrecalculatedDateTimeZone.validatePeriods([] /*new ZoneInterval[0]*/,
          DateTimeZone.utc), throwsArgumentError);
}

@Test()
void Validation_BadFirstStartingPoint() {
  List<ZoneInterval> intervals =
  [
    IZoneInterval.newZoneInterval('foo', Instant.fromEpochMicroseconds(1), Instant.fromEpochMicroseconds(2), Offset.zero, Offset.zero),
    IZoneInterval.newZoneInterval('foo', Instant.fromEpochMicroseconds(2), Instant.fromEpochMicroseconds(3), Offset.zero, Offset.zero)
  ];
  // Assert.Throws<ArgumentException>
  expect(() => PrecalculatedDateTimeZone.validatePeriods(intervals, DateTimeZone.utc), throwsArgumentError);
}

@Test()
void Validation_NonAdjoiningIntervals() {
  List<ZoneInterval> intervals =
  [
    IZoneInterval.newZoneInterval('foo', IInstant.beforeMinValue, Instant.fromEpochMicroseconds(2), Offset.zero, Offset.zero),
    IZoneInterval.newZoneInterval('foo', Instant.fromEpochMicroseconds(2).add(Time(nanoseconds: 500)), Instant.fromEpochMicroseconds(3), Offset.zero, Offset.zero)
  ];
  // Assert.Throws<ArgumentException>
  expect(() => PrecalculatedDateTimeZone.validatePeriods(intervals, DateTimeZone.utc), throwsArgumentError);
}

@Test()
void Validation_Success()
{
  List<ZoneInterval> intervals =
  [
    IZoneInterval.newZoneInterval('foo', IInstant.beforeMinValue, Instant.fromEpochMicroseconds(2), Offset.zero, Offset.zero),
  IZoneInterval.newZoneInterval('foo', Instant.fromEpochMicroseconds(2), Instant.fromEpochMicroseconds(3), Offset.zero, Offset.zero),
  IZoneInterval.newZoneInterval('foo', Instant.fromEpochMicroseconds(3), Instant.fromEpochMicroseconds(10), Offset.zero, Offset.zero),
  IZoneInterval.newZoneInterval('foo', Instant.fromEpochMicroseconds(10), Instant.fromEpochMicroseconds(20), Offset.zero, Offset.zero)
  ];
  PrecalculatedDateTimeZone.validatePeriods(intervals, DateTimeZone.utc);
}

@Test()
void Validation_NullTailZoneWithMiddleOfTimeFinalPeriod() {
  List<ZoneInterval> intervals =
  [
    IZoneInterval.newZoneInterval('foo', IInstant.beforeMinValue, Instant.fromEpochMicroseconds(2), Offset.zero, Offset.zero),
    IZoneInterval.newZoneInterval('foo', Instant.fromEpochMicroseconds(2), Instant.fromEpochMicroseconds(3), Offset.zero, Offset.zero)
  ];
  // Assert.Throws<ArgumentException>
  expect(() => PrecalculatedDateTimeZone.validatePeriods(intervals, null), throwsArgumentError);
}

@Test()
void Validation_NullTailZoneWithEotPeriodEnd()
{
  List<ZoneInterval> intervals =
  [
    IZoneInterval.newZoneInterval('foo', IInstant.beforeMinValue, Instant.fromEpochMicroseconds(2), Offset.zero, Offset.zero),
  IZoneInterval.newZoneInterval('foo', Instant.fromEpochMicroseconds(2), IInstant.afterMaxValue, Offset.zero, Offset.zero)
];
PrecalculatedDateTimeZone.validatePeriods(intervals, null);
}

//@Test()
//void Serialization()
//{
//  var stream = new MemoryStream();
//  var writer = new DateTimeZoneWriter(stream, null);
//  TestZone.Write(writer);
//  stream.Position = 0;
//  var reloaded = PrecalculatedDateTimeZone.Read(new DateTimeZoneReader(stream, null), TestZone.Id);
//
//  // Check equivalence by finding zone intervals
//  var interval = new Interval(new Instant.fromUtc(1990, 1, 1, 0, 0), new Instant.fromUtc(2010, 1, 1, 0, 0));
//  var originalZoneIntervals = TestZone.GetZoneIntervals(interval, ZoneEqualityComparer.Options.StrictestMatch).ToList();
//  var reloadedZoneIntervals = TestZone.GetZoneIntervals(interval, ZoneEqualityComparer.Options.StrictestMatch).ToList();
//  Collectionexpect(originalZoneIntervals, reloadedZoneIntervals);
//}

