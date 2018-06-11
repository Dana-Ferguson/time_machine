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

final ZoneInterval FirstInterval =
new ZoneInterval("First", Instant.beforeMinValue, new Instant.fromUtc(2000, 3, 10, 10, 0), new Offset.fromHours(3), Offset.zero);

// Note that this is effectively UTC +3 + 1 hour DST.
final ZoneInterval SecondInterval =
new ZoneInterval("Second", FirstInterval.end, new Instant.fromUtc(2000, 9, 15, 5, 0), new Offset.fromHours(4), new Offset.fromHours(1));

final ZoneInterval ThirdInterval =
new ZoneInterval("Third", SecondInterval.end, new Instant.fromUtc(2005, 1, 20, 8, 0), new Offset.fromHours(-5), Offset.zero);

final ZoneRecurrence Winter = new ZoneRecurrence("Winter", Offset.zero,
new ZoneYearOffset(TransitionMode.wall, 10, 5, 0, false, new LocalTime(2, 0)), 1960, Utility.int32MaxValue);

final ZoneRecurrence Summer = new ZoneRecurrence("Summer", new Offset.fromHours(1),
new ZoneYearOffset(TransitionMode.wall, 3, 10, 0, false, new LocalTime(1, 0)), 1960, Utility.int32MaxValue);

final StandardDaylightAlternatingMap TailZone =
new StandardDaylightAlternatingMap(new Offset.fromHours(-6), Winter, Summer);

// We don't actually want an interval from the beginning of time when we ask our composite time zone for an interval
// - because that could give the wrong idea. So we clamp it at the end of the precalculated interval.
final ZoneInterval ClampedTailZoneInterval = TailZone.getZoneInterval(ThirdInterval.end).WithStart(ThirdInterval.end);

final PrecalculatedDateTimeZone TestZone =
new PrecalculatedDateTimeZone("Test", [ FirstInterval, SecondInterval, ThirdInterval ], TailZone);

@Test()
void MinMaxOffsets()
{
  expect(new Offset.fromHours(-6), TestZone.minOffset);
  expect(new Offset.fromHours(4), TestZone.maxOffset);
}

@Test()
void MinMaxOffsetsWithOtherTailZone()
{
  var tailZone = new FixedDateTimeZone.forIdOffset("TestFixed", new Offset.fromHours(8));
  var testZone = new PrecalculatedDateTimeZone("Test",
      [ FirstInterval, SecondInterval, ThirdInterval ], tailZone);
  expect(new Offset.fromHours(-5), testZone.minOffset);
  expect(new Offset.fromHours(8), testZone.maxOffset);
}

@Test()
void MinMaxOffsetsWithNullTailZone()
{
  var testZone = new PrecalculatedDateTimeZone("Test",
      [ FirstInterval, SecondInterval, ThirdInterval,
      new ZoneInterval("Last", ThirdInterval.end, Instant.afterMaxValue, Offset.zero, Offset.zero) ], null);
  expect(new Offset.fromHours(-5), testZone.minOffset);
  expect(new Offset.fromHours(4), testZone.maxOffset);
}

@Test()
void GetZoneIntervalInstant_End()
{
  expect(SecondInterval, TestZone.getZoneInterval(SecondInterval.end - Span.epsilon));
}

@Test()
void GetZoneIntervalInstant_Start()
{
  expect(SecondInterval, TestZone.getZoneInterval(SecondInterval.start));
}

@Test()
void GetZoneIntervalInstant_FinalInterval_End()
{
  expect(ThirdInterval, TestZone.getZoneInterval(ThirdInterval.end - Span.epsilon));
}

@Test()
void GetZoneIntervalInstant_FinalInterval_Start()
{
  expect(ThirdInterval, TestZone.getZoneInterval(ThirdInterval.start));
}

@Test()
void GetZoneIntervalInstant_TailZone()
{
  expect(ClampedTailZoneInterval, TestZone.getZoneInterval(ThirdInterval.end));
}

@Test()
void MapLocal_UnambiguousInPrecalculated()
{
  CheckMapping(new LocalDateTime.at(2000, 6, 1, 0, 0), SecondInterval, SecondInterval, 1);
}

@Test()
void MapLocal_UnambiguousInTailZone()
{
  CheckMapping(new LocalDateTime.at(2005, 2, 1, 0, 0), ClampedTailZoneInterval, ClampedTailZoneInterval, 1);
}

@Test()
void MapLocal_AmbiguousWithinPrecalculated()
{
  // Transition from +4 to -5 has a 9 hour ambiguity
  CheckMapping(ThirdInterval.IsoLocalStart, SecondInterval, ThirdInterval, 2);
}

@Test()
void MapLocal_AmbiguousAroundTailZoneTransition()
{
  // Transition from -5 to -6 has a 1 hour ambiguity
  // CheckMapping(ThirdInterval.IsoLocalEnd.PlusNanoseconds(-1L), ThirdInterval, ClampedTailZoneInterval, 2);
  CheckMapping(ThirdInterval.IsoLocalEnd.plusNanoseconds(-1), ThirdInterval, ClampedTailZoneInterval, 2);
}

@Test()
void MapLocal_AmbiguousButTooEarlyInTailZoneTransition()
{
  // Tail zone is +10 / +8, with the transition occurring just after
  // the transition *to* the tail zone from the precalculated zone.
  // A local instant of one hour before after the transition from the precalculated zone (which is -5)
  // will therefore be ambiguous, but the resulting instants from the ambiguity occur
  // before our transition into the tail zone, so are ignored.
  var tailZone = new SingleTransitionDateTimeZone.around(ThirdInterval.end + new Span(hours: 1), 10, 8);
  var gapZone = new PrecalculatedDateTimeZone("Test",
      [ FirstInterval, SecondInterval, ThirdInterval ], tailZone);
  var mapping = gapZone.mapLocal(ThirdInterval.IsoLocalEnd.plusHours(-1));
  expect(ThirdInterval, mapping.EarlyInterval);
  expect(ThirdInterval, mapping.LateInterval);
  expect(1, mapping.Count);
}

@Test()
void MapLocal_GapWithinPrecalculated()
{
  // Transition from +3 to +4 has a 1 hour gap
  expect(FirstInterval.IsoLocalEnd < SecondInterval.IsoLocalStart, isTrue);
  CheckMapping(FirstInterval.IsoLocalEnd, FirstInterval, SecondInterval, 0);
}

@Test()
void MapLocal_SingleIntervalAroundTailZoneTransition()
{
  // Tail zone is fixed at +5. A local instant of one hour before the transition
  // from the precalculated zone (which is -5) will therefore give an instant from
  // the tail zone which occurs before the precalculated-to-tail transition,
  // and can therefore be ignored, resulting in an overall unambiguous time.
  var tailZone = new FixedDateTimeZone.forOffset(new Offset.fromHours(5));
  var gapZone = new PrecalculatedDateTimeZone("Test",
      [ FirstInterval, SecondInterval, ThirdInterval ], tailZone);
  var mapping = gapZone.mapLocal(ThirdInterval.IsoLocalEnd.plusHours(-1));
  expect(ThirdInterval, mapping.EarlyInterval);
  expect(ThirdInterval, mapping.LateInterval);
  expect(1, mapping.Count);
}

@Test()
void MapLocal_GapAroundTailZoneTransition()
{
  // Tail zone is fixed at +5. A local time at the transition
  // from the precalculated zone (which is -5) will therefore give an instant from
  // the tail zone which occurs before the precalculated-to-tail transition,
  // and can therefore be ignored, resulting in an overall gap.
  var tailZone = new FixedDateTimeZone.forOffset(new Offset.fromHours(5));
  var gapZone = new PrecalculatedDateTimeZone("Test",
      [ FirstInterval, SecondInterval, ThirdInterval ], tailZone);
  var mapping = gapZone.mapLocal(ThirdInterval.IsoLocalEnd);
  expect(ThirdInterval, mapping.EarlyInterval);
  expect(mapping.LateInterval,
      new ZoneInterval("UTC+05", ThirdInterval.end, Instant.afterMaxValue, new Offset.fromHours(5), Offset.zero));
  expect(0, mapping.Count);
}

@Test()
void MapLocal_GapAroundAndInTailZoneTransition()
{
  // Tail zone is -10 / +5, with the transition occurring just after
  // the transition *to* the tail zone from the precalculated zone.
  // A local time of one hour after the transition from the precalculated zone (which is -5)
  // will therefore be in the gap.
  var tailZone = new SingleTransitionDateTimeZone.around(ThirdInterval.end + new Span(hours: 1), -10, 5);
  var gapZone = new PrecalculatedDateTimeZone("Test",
      [ FirstInterval, SecondInterval, ThirdInterval ], tailZone);
  var mapping = gapZone.mapLocal(ThirdInterval.IsoLocalEnd.plusHours(1));
  expect(ThirdInterval, mapping.EarlyInterval);
  expect(new ZoneInterval("Single-Early", ThirdInterval.end, tailZone.Transition, new Offset.fromHours(-10), Offset.zero),
      mapping.LateInterval);
  expect(0, mapping.Count);
}

@Test()
void GetZoneIntervals_NullTailZone_Eot()
{
  List<ZoneInterval> intervals =
  [
    new ZoneInterval("foo", Instant.beforeMinValue, new Instant.fromUnixTimeTicks(20), Offset.zero, Offset.zero),
  new ZoneInterval("foo", new Instant.fromUnixTimeTicks(20), Instant.afterMaxValue, Offset.zero, Offset.zero)
];
var zone = new PrecalculatedDateTimeZone("Test", intervals, null);
expect(intervals[1], zone.getZoneInterval(Instant.maxValue));
}

void CheckMapping(LocalDateTime localDateTime, ZoneInterval earlyInterval, ZoneInterval lateInterval, int count)
{
  var mapping = TestZone.mapLocal(localDateTime);
  expect(earlyInterval, mapping.EarlyInterval);
  expect(lateInterval, mapping.LateInterval);
  expect(count, mapping.Count);
}

@Test()
void Validation_EmptyPeriodArray() {
  // Assert.Throws<ArgumentException>
  expect(() =>
      PrecalculatedDateTimeZone.ValidatePeriods([] /*new ZoneInterval[0]*/,
          DateTimeZone.utc), throwsArgumentError);
}

@Test()
void Validation_BadFirstStartingPoint() {
  List<ZoneInterval> intervals =
  [
    new ZoneInterval("foo", new Instant.fromUnixTimeTicks(10), new Instant.fromUnixTimeTicks(20), Offset.zero, Offset.zero),
    new ZoneInterval("foo", new Instant.fromUnixTimeTicks(20), new Instant.fromUnixTimeTicks(30), Offset.zero, Offset.zero)
  ];
  // Assert.Throws<ArgumentException>
  expect(() => PrecalculatedDateTimeZone.ValidatePeriods(intervals, DateTimeZone.utc), throwsArgumentError);
}

@Test()
void Validation_NonAdjoiningIntervals() {
  List<ZoneInterval> intervals =
  [
    new ZoneInterval("foo", Instant.beforeMinValue, new Instant.fromUnixTimeTicks(20), Offset.zero, Offset.zero),
    new ZoneInterval("foo", new Instant.fromUnixTimeTicks(25), new Instant.fromUnixTimeTicks(30), Offset.zero, Offset.zero)
  ];
  // Assert.Throws<ArgumentException>
  expect(() => PrecalculatedDateTimeZone.ValidatePeriods(intervals, DateTimeZone.utc), throwsArgumentError);
}

@Test()
void Validation_Success()
{
  List<ZoneInterval> intervals =
  [
    new ZoneInterval("foo", Instant.beforeMinValue, new Instant.fromUnixTimeTicks(20), Offset.zero, Offset.zero),
  new ZoneInterval("foo", new Instant.fromUnixTimeTicks(20), new Instant.fromUnixTimeTicks(30), Offset.zero, Offset.zero),
  new ZoneInterval("foo", new Instant.fromUnixTimeTicks(30), new Instant.fromUnixTimeTicks(100), Offset.zero, Offset.zero),
  new ZoneInterval("foo", new Instant.fromUnixTimeTicks(100), new Instant.fromUnixTimeTicks(200), Offset.zero, Offset.zero)
  ];
  PrecalculatedDateTimeZone.ValidatePeriods(intervals, DateTimeZone.utc);
}

@Test()
void Validation_NullTailZoneWithMiddleOfTimeFinalPeriod() {
  List<ZoneInterval> intervals =
  [
    new ZoneInterval("foo", Instant.beforeMinValue, new Instant.fromUnixTimeTicks(20), Offset.zero, Offset.zero),
    new ZoneInterval("foo", new Instant.fromUnixTimeTicks(20), new Instant.fromUnixTimeTicks(30), Offset.zero, Offset.zero)
  ];
  // Assert.Throws<ArgumentException>
  expect(() => PrecalculatedDateTimeZone.ValidatePeriods(intervals, null), throwsArgumentError);
}

@Test()
void Validation_NullTailZoneWithEotPeriodEnd()
{
  List<ZoneInterval> intervals =
  [
    new ZoneInterval("foo", Instant.beforeMinValue, new Instant.fromUnixTimeTicks(20), Offset.zero, Offset.zero),
  new ZoneInterval("foo", new Instant.fromUnixTimeTicks(20), Instant.afterMaxValue, Offset.zero, Offset.zero)
];
PrecalculatedDateTimeZone.ValidatePeriods(intervals, null);
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

