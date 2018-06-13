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

import 'testing/timezones/single_transition_datetimezone.dart';
import 'testing/timezones/multi_transition_datetimezone.dart';
import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

// Tests for DateTimeZoneTest.GetZoneIntervals. The calls to toList()
// in the assertions are to make the actual values get dumped on failure, instead of
// just <NodaTime.DateTimeZone+<GetZoneIntervalsImpl>d__0>

final SingleTransitionDateTimeZone TestZone = new SingleTransitionDateTimeZone.around(new Instant.fromUtc(2000, 1, 1, 0, 0), -3, 4);

@Test()
void GetZoneIntervals_EndBeforeStart()
{
  // Assert.Throws<ArgumentOutOfRangeException>(() => DateTimeZone.Utc.GetZoneIntervals(new Instant.fromUnixTimeTicks(100L), new Instant.fromUnixTimeTicks(99L)));
  expect(() => DateTimeZone.utc.getZoneIntervalsFromTo(new Instant.fromUnixTimeTicks(100), new Instant.fromUnixTimeTicks(99)), throwsArgumentError);
}

@Test()
void GetZoneIntervals_EndEqualToStart()
{
  expect(DateTimeZone.utc.getZoneIntervalsFromTo(new Instant.fromUnixTimeTicks(100), new Instant.fromUnixTimeTicks(100)), isEmpty);
}

@Test()
void GetZoneIntervals_InvalidOptions()
{
  var zone = DateTimeZone.utc;
  var interval = new Interval(new Instant.fromUtc(2000, 1, 1, 0, 0), new Instant.fromUtc(2001, 1, 1, 0, 0));
  // Assert.Throws<ArgumentOutOfRangeException>(() => zone.GetZoneIntervals(interval, (ZoneEqualityComparer.Options) 1234567));
  expect(() => zone.getZoneIntervalsOptions(interval, new ZoneEqualityComparerOptions(1234567)), throwsArgumentError);
}

@Test()
void GetZoneIntervals_FixedZone()
{
  var zone = new DateTimeZone.forOffset(new Offset.fromHours(3));
  var expected = [ zone.getZoneInterval(Instant.minValue) ];
  // Give a reasonably wide interval...
  var actual = zone.getZoneIntervalsFromTo(new Instant.fromUtc(1900, 1, 1, 0, 0), new Instant.fromUtc(2100, 1, 1, 0, 0));
  // CollectionAssert.AreEqual(expected, actual.toList());
  expect(expected, actual.toList());
}

@Test()
void GetZoneIntervals_SingleTransitionZone_IntervalCoversTransition()
{
  Instant start = TestZone.Transition - new Span(days: 5);
  Instant end = TestZone.Transition + new Span(days: 5);
  var expected = [ TestZone.EarlyInterval, TestZone.LateInterval ];
  var actual = TestZone.getZoneIntervalsFromTo(start, end);
  // CollectionAssert.AreEqual(expected, actual.toList());
  expect(expected, actual.toList());
}

@Test()
void GetZoneIntervals_SingleTransitionZone_IntervalDoesNotCoverTransition()
{
  Instant start = TestZone.Transition - new Span(days: 10);
  Instant end = TestZone.Transition - new Span(days: 5);
  var expected = [ TestZone.EarlyInterval ];
  var actual = TestZone.getZoneIntervalsFromTo(start, end);
  // CollectionAssert.AreEqual(expected, actual.toList());
  expect(expected, actual.toList());
}

@Test()
void GetZoneIntervals_IncludesStart()
{
  Instant start = TestZone.Transition - Span.epsilon;
  Instant end = TestZone.Transition + new Span(days: 5);
  var expected = [TestZone.EarlyInterval, TestZone.LateInterval ];
  var actual = TestZone.getZoneIntervalsFromTo(start, end);
  // CollectionAssert.AreEqual(expected, actual.toList());
  expect(expected, actual.toList());
}

@Test()
void GetZoneIntervals_ExcludesEnd()
{
  Instant start = TestZone.Transition - new Span(days: 10);
  Instant end = TestZone.Transition;
  var expected = [ TestZone.EarlyInterval ];
  var actual = TestZone.getZoneIntervalsFromTo(start, end);
  // CollectionAssert.AreEqual(expected, actual.toList());
  expect(expected, actual.toList());
}

@Test()
Future GetZoneIntervals_Complex() async
{
  var london = await (await DateTimeZoneProviders.Tzdb)["Europe/London"];
  // Transitions are always Spring/Autumn, so June and January should be clear.
  var expected = [
    london.getZoneInterval(new Instant.fromUtc(1999, 6, 1, 0, 0)),
    london.getZoneInterval(new Instant.fromUtc(2000, 1, 1, 0, 0)),
    london.getZoneInterval(new Instant.fromUtc(2000, 6, 1, 0, 0)),
    london.getZoneInterval(new Instant.fromUtc(2001, 1, 1, 0, 0)),
    london.getZoneInterval(new Instant.fromUtc(2001, 6, 1, 0, 0)),
    london.getZoneInterval(new Instant.fromUtc(2002, 1, 1, 0, 0)),
  ];
  // After the instant we used to fetch the expected zone interval, but that's fine:
  // it'll be the same one, as there's no transition within June.
  var start = new Instant.fromUtc(1999, 6, 19, 0, 0);
  var end = new Instant.fromUtc(2002, 2, 4, 0, 0);
  var actual = london.getZoneIntervalsFromTo(start, end);
  // CollectionAssert.AreEqual(expected, actual.toList());
  actual = actual.toList();
  expect(expected, actual.toList());
  // Just to exercise the other overload
  actual = london.getZoneIntervals(new Interval(start, end));
  // CollectionAssert.AreEqual(expected, actual.toList());
  expect(expected, actual.toList());
}

@Test()
void GetZoneIntervals_WithOptions_NoCoalescing() {
  // We'll ask for 1999-2003, so there are three transitions within that.
  var transition1 = new Instant.fromUtc(2000, 1, 1, 0, 0);
  var transition2 = new Instant.fromUtc(2001, 1, 1, 0, 0);
  var transition3 = new Instant.fromUtc(2002, 1, 1, 0, 0);
  // And one transition afterwards.
  var transition4 = new Instant.fromUtc(2004, 1, 1, 0, 0);
  var builder = new MtdtzBuilder.withName(0, "0+0")
    ..Add(transition1, 1, 1, "1+1")
    ..Add(transition2, 0, 2, "0+2")
    ..Add(transition3, 0, 1, "0+1")
    ..Add(transition4, 0, 0, "0+0");
  var zone = builder.Build();

  var interval = new Interval(
      new Instant.fromUtc(1999, 1, 1, 0, 0),
      new Instant.fromUtc(2003, 1, 1, 0, 0));
  // No coalescing required, as the names are different.
  var zoneIntervals = zone.getZoneIntervalsOptions(interval, ZoneEqualityComparerOptions.MatchNames).toList();
  expect(4, zoneIntervals.length);
  // CollectionAssert.AreEqual([ transition1, transition2, transition3, transition4 ], zoneIntervals.map((zi) => zi.end));
  expect([ transition1, transition2, transition3, transition4 ], zoneIntervals.map((zi) => zi.end));
}

@Test()
void GetZoneIntervals_WithOptions_Coalescing() {
  // We'll ask for 1999-2003, so there are three transitions within that.
  var transition1 = new Instant.fromUtc(2000, 1, 1, 0, 0);
  var transition2 = new Instant.fromUtc(2001, 1, 1, 0, 0);
  var transition3 = new Instant.fromUtc(2002, 1, 1, 0, 0);
  // And one transition afterwards.
  var transition4 = new Instant.fromUtc(2004, 1, 1, 0, 0);
  var builder = new MtdtzBuilder.withName(0, "0+0")
    ..Add(transition1, 1, 1, "1+1")..Add(transition2, 0, 2, "0+2")..Add(transition3, 0, 1, "0+1")..Add(transition4, 0, 0, "0+0");
  var zone = builder.Build();

  var interval = new Interval(
      new Instant.fromUtc(1999, 1, 1, 0, 0),
      new Instant.fromUtc(2003, 1, 1, 0, 0));
  // The zone intervals abutting at transition2 are coalesced,
  // because that only changes the name and standard/daylight split.
  var zoneIntervals = zone.getZoneIntervalsOptions(interval, ZoneEqualityComparerOptions.OnlyMatchWallOffset).toList();
  expect(3, zoneIntervals.length);
  // CollectionAssert.AreEqual
  expect([ transition1, transition3, transition4], zoneIntervals.map((zi) => zi.end));
  expect([ Instant.beforeMinValue, transition1, transition3], zoneIntervals.map((zi) => zi.rawStart));
  expect([ "0+0", "1+1", "0+1"], zoneIntervals.map((zi) => zi.name));
}

