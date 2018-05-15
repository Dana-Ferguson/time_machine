// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/TimeZones/ZoneEqualityComparerTest.cs
// 16aacad  on Aug 26, 2017

import 'dart:async';
import 'dart:math' as math;

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

// Sample instants for use in tests. They're on January 1st 2000...2009, midnight UTC.
List<Instant> Instants = (new Iterable.generate(10, (i) => (i+2000)))
    .map((year) => new Instant.fromUtc(year, 1, 1, 0, 0))
    .toList(growable: false);

// Various tests using a pair of zones which can demonstrate a number of
// different features.
@Test()
void Various()
{
  // Names, some offsets, and first transition are all different.
  var zone1 = (new MtdtzBuilder()
    ..Add(Instants[0], 1, 0, "xx")
    ..Add(Instants[2], 3, 0, "1b")
    ..Add(Instants[4], 2, 1, "1c")
    ..Add(Instants[6], 4, 0, "1d")
  ).Build();

  var zone2 = (new MtdtzBuilder()
    ..Add(Instants[1], 1, 0, "xx")
    ..Add(Instants[2], 3, 0, "2b")
    ..Add(Instants[4], 1, 2, "2c")
    ..Add(Instants[6], 5, 0, "2d")
  ).Build();

  // Even though the first transition point is different, by default that's fine if
  // the start point is "inside" both.
  AssertEqual(zone1, zone2, Instants[1], Instants[5], ZoneEqualityComparerOptions.OnlyMatchWallOffset);
  // When we extend backwards a bit, we can see the difference between the two.
  AssertNotEqual(zone1, zone2, Instants[1] - Span.epsilon, Instants[5], ZoneEqualityComparerOptions.OnlyMatchWallOffset);
  // Or if we force the start and end transitions to be exact...
  AssertNotEqual(zone1, zone2, Instants[1], Instants[5], ZoneEqualityComparerOptions.MatchStartAndEndTransitions);

  // The first two transitions have the same split between standard and saving...
  AssertEqual(zone1, zone2, Instants[1], Instants[4], ZoneEqualityComparerOptions.MatchOffsetComponents);
  // The third one (at Instants[4]) doesn't...
  AssertNotEqual(zone1, zone2, Instants[1], Instants[5], ZoneEqualityComparerOptions.MatchOffsetComponents);

  // The first transition has the same name for the zone interval...
  AssertEqual(zone1, zone2, Instants[1], Instants[2], ZoneEqualityComparerOptions.MatchNames);
  // The second transition (at Instants[2]) doesn't...
  AssertNotEqual(zone1, zone2, Instants[1], Instants[3], ZoneEqualityComparerOptions.MatchNames);
}

@Test()
void ElidedTransitions() {
  var zone1 = (new MtdtzBuilder()
    ..Add(Instants[3], 0, 0, "a")
    ..Add(Instants[4], 1, 2, "b")
    ..Add(Instants[5], 2, 1, "b")
    ..Add(Instants[6], 1, 0, "d")
    ..Add(Instants[7], 1, 0, "e")
    ..Add(Instants[8], 0, 0, "x")
  ).Build();

  var zone2 = (new MtdtzBuilder()
    ..Add(Instants[3], 0, 0, "a")
    ..Add(Instants[4], 3, 0, "b")
    // Instants[5] isn't included here: wall offset is the same; components change in zone1
    ..Add(Instants[6], 1, 0, "d")
    // Instants[7] isn't included here: offset components are the same; names change in zone1
    ..Add(Instants[8], 0, 0, "x")
  ).Build();

  AssertEqual(zone1, zone2, Instant.minValue, Instant.maxValue, ZoneEqualityComparerOptions.OnlyMatchWallOffset);
  // BOT-Instants[6] will elide transitions when ignoring components, even if we match names
  AssertEqual(zone1, zone2, Instant.minValue, Instants[6], ZoneEqualityComparerOptions.MatchNames);
  AssertNotEqual(zone1, zone2, Instant.minValue, Instants[6], ZoneEqualityComparerOptions.MatchOffsetComponents);
  // Instants[6]-EOT will elide transitions when ignoring names, even if we match components
  AssertEqual(zone1, zone2, Instants[6], Instant.maxValue, ZoneEqualityComparerOptions.MatchOffsetComponents);
  AssertNotEqual(zone1, zone2, Instants[6], Instant.maxValue, ZoneEqualityComparerOptions.MatchNames);

  // But if we require the exact transitions, both fail
  AssertNotEqual(zone1, zone2, Instant.minValue, Instants[6], ZoneEqualityComparerOptions.MatchAllTransitions);
  AssertNotEqual(zone1, zone2, Instants[6], Instant.maxValue, ZoneEqualityComparerOptions.MatchAllTransitions);
}

@Test()
void ForInterval()
{
  var interval = new Interval(Instants[3], Instants[5]);
  var comparer = ZoneEqualityComparer.ForInterval(interval);
  expect(ZoneEqualityComparerOptions.OnlyMatchWallOffset, comparer.OptionsForTest);
  expect(interval, comparer.IntervalForTest);
}

@Test()
void WithOptions()
{
  var interval = new Interval(Instants[3], Instants[5]);
  var firstComparer = ZoneEqualityComparer.ForInterval(interval);
  var secondComparer = firstComparer.WithOptions(ZoneEqualityComparerOptions.MatchNames);

  expect(ZoneEqualityComparerOptions.MatchNames, secondComparer.OptionsForTest);
  expect(interval, secondComparer.IntervalForTest);

  // Validate that the first comparer hasn't changed
  expect(ZoneEqualityComparerOptions.OnlyMatchWallOffset, firstComparer.OptionsForTest);
  expect(interval, firstComparer.IntervalForTest);
}

@Test()
void ElidedTransitions_Degenerate() {
  // Transitions with *nothing* that we care about. (Normally
  // these wouldn't even be generated, but we could imagine some
  // sort of zone interval in the future which had another property...)
  var zone1 = (new MtdtzBuilder()
    ..Add(Instants[3], 1, 0, "a")
    ..Add(Instants[4], 1, 0, "a")
    ..Add(Instants[5], 1, 0, "a")
    ..Add(Instants[6], 0)
  ).Build();
  var zone2 = (new MtdtzBuilder()
    ..Add(Instants[3], 1, 0, "a")
    ..Add(Instants[6], 0)
  ).Build();

  // We can match *everything* except exact transitions...
  var match = ZoneEqualityComparerOptions.MatchNames
  | ZoneEqualityComparerOptions.MatchOffsetComponents
  | ZoneEqualityComparerOptions.MatchStartAndEndTransitions;
  AssertEqual(zone1, zone2, Instant.minValue, Instant.maxValue, match);
  // But not the exact transitions...
  AssertNotEqual(zone1, zone2, Instant.minValue, Instant.maxValue, ZoneEqualityComparerOptions.MatchAllTransitions);
}

@Test()
Future ReferenceComparison() async
{
  var comparer = ZoneEqualityComparer.ForInterval(new Interval(Instants[0], Instants[2]));
  var zone = await (await DateTimeZoneProviders.Tzdb)["Europe/London"];
  expect(comparer.Equals(zone, zone), isTrue);
}

@Test()
Future NullComparison() async
{
  var comparer = ZoneEqualityComparer.ForInterval(new Interval(Instants[0], Instants[2]));
  var zone = await (await DateTimeZoneProviders.Tzdb)["Europe/London"];
  expect(comparer.Equals(zone, null), isFalse);
  expect(comparer.Equals(null, zone), isFalse);
}

@Test()
void InvalidOptions()
{
  var comparer = ZoneEqualityComparer.ForInterval(new Interval(Instants[0], Instants[2]));
  expect(() => comparer.WithOptions(new ZoneEqualityComparerOptions(9999)), throwsArgumentError);
}

void AssertEqual(DateTimeZone first, DateTimeZone second,
    Instant start, Instant end, ZoneEqualityComparerOptions options)
{
  var comparer = ZoneEqualityComparer.ForInterval(new Interval(start, end)).WithOptions(options);
  expect(comparer.Equals(first, second), isTrue);
  expect(comparer.GetHashCode(first), comparer.GetHashCode(second));
}

void AssertNotEqual(DateTimeZone first, DateTimeZone second,
    Instant start, Instant end, ZoneEqualityComparerOptions options)
{
  var comparer = ZoneEqualityComparer.ForInterval(new Interval(start, end)).WithOptions(options);
  expect(comparer.Equals(first, second), isFalse);
  // If this fails, the code *could* still be correct - but it's unlikely...
  expect(comparer.GetHashCode(first), isNot(comparer.GetHashCode(second)));
}

