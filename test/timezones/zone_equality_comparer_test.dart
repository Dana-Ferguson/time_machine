// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

import '../time_machine_testing.dart';

Future main() async {
  await TimeMachine.initialize();
  await runTests();
}

// Sample instants for use in tests. They're on January 1st 2000...2009, midnight UTC.
List<Instant> Instants = (Iterable.generate(10, (i) => (i+2000)))
    .map((year) => Instant.utc(year, 1, 1, 0, 0))
    .toList(growable: false);

// Various tests using a pair of zones which can demonstrate a number of
// different features.
@Test()
void Various()
{
  // Names, some offsets, and first transition are all different.
  var zone1 = (MtdtzBuilder()
    ..Add(Instants[0], 1, 0, 'xx')
    ..Add(Instants[2], 3, 0, '1b')
    ..Add(Instants[4], 2, 1, '1c')
    ..Add(Instants[6], 4, 0, '1d')
  ).Build();

  var zone2 = (MtdtzBuilder()
    ..Add(Instants[1], 1, 0, 'xx')
    ..Add(Instants[2], 3, 0, '2b')
    ..Add(Instants[4], 1, 2, '2c')
    ..Add(Instants[6], 5, 0, '2d')
  ).Build();

  // Even though the first transition point is different, by default that's fine if
  // the start point is 'inside' both.
  AssertEqual(zone1, zone2, Instants[1], Instants[5], ZoneEqualityComparerOptions.onlyMatchWallOffset);
  // When we extend backwards a bit, we can see the difference between the two.
  AssertNotEqual(zone1, zone2, Instants[1] - Time.epsilon, Instants[5], ZoneEqualityComparerOptions.onlyMatchWallOffset);
  // Or if we force the start and end transitions to be exact...
  AssertNotEqual(zone1, zone2, Instants[1], Instants[5], ZoneEqualityComparerOptions.matchStartAndEndTransitions);

  // The first two transitions have the same split between standard and saving...
  AssertEqual(zone1, zone2, Instants[1], Instants[4], ZoneEqualityComparerOptions.matchOffsetComponents);
  // The third one (at Instants[4]) doesn't...
  AssertNotEqual(zone1, zone2, Instants[1], Instants[5], ZoneEqualityComparerOptions.matchOffsetComponents);

  // The first transition has the same name for the zone interval...
  AssertEqual(zone1, zone2, Instants[1], Instants[2], ZoneEqualityComparerOptions.matchNames);
  // The second transition (at Instants[2]) doesn't...
  AssertNotEqual(zone1, zone2, Instants[1], Instants[3], ZoneEqualityComparerOptions.matchNames);
}

@Test()
void ElidedTransitions() {
  var zone1 = (MtdtzBuilder()
    ..Add(Instants[3], 0, 0, 'a')
    ..Add(Instants[4], 1, 2, 'b')
    ..Add(Instants[5], 2, 1, 'b')
    ..Add(Instants[6], 1, 0, 'd')
    ..Add(Instants[7], 1, 0, 'e')
    ..Add(Instants[8], 0, 0, 'x')
  ).Build();

  var zone2 = (MtdtzBuilder()
    ..Add(Instants[3], 0, 0, 'a')
    ..Add(Instants[4], 3, 0, 'b')
    // Instants[5] isn't included here: wall offset is the same; components change in zone1
    ..Add(Instants[6], 1, 0, 'd')
    // Instants[7] isn't included here: offset components are the same; names change in zone1
    ..Add(Instants[8], 0, 0, 'x')
  ).Build();

  AssertEqual(zone1, zone2, Instant.minValue, Instant.maxValue, ZoneEqualityComparerOptions.onlyMatchWallOffset);
  // BOT-Instants[6] will elide transitions when ignoring components, even if we match names
  AssertEqual(zone1, zone2, Instant.minValue, Instants[6], ZoneEqualityComparerOptions.matchNames);
  AssertNotEqual(zone1, zone2, Instant.minValue, Instants[6], ZoneEqualityComparerOptions.matchOffsetComponents);
  // Instants[6]-EOT will elide transitions when ignoring names, even if we match components
  AssertEqual(zone1, zone2, Instants[6], Instant.maxValue, ZoneEqualityComparerOptions.matchOffsetComponents);
  AssertNotEqual(zone1, zone2, Instants[6], Instant.maxValue, ZoneEqualityComparerOptions.matchNames);

  // But if we require the exact transitions, both fail
  AssertNotEqual(zone1, zone2, Instant.minValue, Instants[6], ZoneEqualityComparerOptions.matchAllTransitions);
  AssertNotEqual(zone1, zone2, Instants[6], Instant.maxValue, ZoneEqualityComparerOptions.matchAllTransitions);
}

@Test()
void ForInterval()
{
  var interval = Interval(Instants[3], Instants[5]);
  var comparer = ZoneEqualityComparer.forInterval(interval);
  expect(ZoneEqualityComparerOptions.onlyMatchWallOffset, IZoneEqualityComparer.optionsForTest(comparer));
  expect(interval, IZoneEqualityComparer.intervalForTest(comparer));
}

@Test()
void WithOptions()
{
  var interval = Interval(Instants[3], Instants[5]);
  var firstComparer = ZoneEqualityComparer.forInterval(interval);
  var secondComparer = firstComparer.withOptions(ZoneEqualityComparerOptions.matchNames);

  expect(ZoneEqualityComparerOptions.matchNames, IZoneEqualityComparer.optionsForTest(secondComparer));
  expect(interval, IZoneEqualityComparer.intervalForTest(secondComparer));

  // Validate that the first comparer hasn't changed
  expect(ZoneEqualityComparerOptions.onlyMatchWallOffset, IZoneEqualityComparer.optionsForTest(firstComparer));
  expect(interval, IZoneEqualityComparer.intervalForTest(firstComparer));
}

@Test()
void ElidedTransitions_Degenerate() {
  // Transitions with *nothing* that we care about. (Normally
  // these wouldn't even be generated, but we could imagine some
  // sort of zone interval in the future which had another property...)
  var zone1 = (MtdtzBuilder()
    ..Add(Instants[3], 1, 0, 'a')
    ..Add(Instants[4], 1, 0, 'a')
    ..Add(Instants[5], 1, 0, 'a')
    ..Add(Instants[6], 0)
  ).Build();
  var zone2 = (MtdtzBuilder()
    ..Add(Instants[3], 1, 0, 'a')
    ..Add(Instants[6], 0)
  ).Build();

  // We can match *everything* except exact transitions...
  var match = ZoneEqualityComparerOptions.matchNames
  | ZoneEqualityComparerOptions.matchOffsetComponents
  | ZoneEqualityComparerOptions.matchStartAndEndTransitions;
  AssertEqual(zone1, zone2, Instant.minValue, Instant.maxValue, match);
  // But not the exact transitions...
  AssertNotEqual(zone1, zone2, Instant.minValue, Instant.maxValue, ZoneEqualityComparerOptions.matchAllTransitions);
}

@Test()
Future ReferenceComparison() async
{
  var comparer = ZoneEqualityComparer.forInterval(Interval(Instants[0], Instants[2]));
  var zone = await (await DateTimeZoneProviders.tzdb)['Europe/London'];
  expect(comparer.equals(zone, zone), isTrue);
}

@Test()
void InvalidOptions()
{
  var comparer = ZoneEqualityComparer.forInterval(Interval(Instants[0], Instants[2]));
  expect(() => comparer.withOptions(const ZoneEqualityComparerOptions(9999)), throwsArgumentError);
}

void AssertEqual(DateTimeZone first, DateTimeZone second,
    Instant start, Instant end, ZoneEqualityComparerOptions options)
{
  var comparer = ZoneEqualityComparer.forInterval(Interval(start, end)).withOptions(options);
  expect(comparer.equals(first, second), isTrue);
  expect(comparer.getHashCode(first), comparer.getHashCode(second));
}

void AssertNotEqual(DateTimeZone first, DateTimeZone second,
    Instant start, Instant end, ZoneEqualityComparerOptions options)
{
  var comparer = ZoneEqualityComparer.forInterval(Interval(start, end)).withOptions(options);
  expect(comparer.equals(first, second), isFalse);
  // If this fails, the code *could* still be correct - but it's unlikely...
  expect(comparer.getHashCode(first), isNot(comparer.getHashCode(second)));
}


