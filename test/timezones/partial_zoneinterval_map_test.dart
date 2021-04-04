// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:test/test.dart';

import '../time_machine_testing.dart';

Future main() async {
  await setup();

  await runTests();
}

Future setup() async {
  expectedZone = (MtdtzBuilder.withName(-2, 'Start')
    ..Add(instants['C']!, 2, 1, "Middle")
    ..Add(instants['G']!, 1, 0, "End")
  ).Build();
}

// Arbitrary instants which are useful for the tests. They happen to be a year
// apart, but nothing in these tests actually cares.
// Various tests use a time zone with transitions at C and G.
// Using letter is (IMO) slightly more readable than just having an array and using indexes.
Map<String /*char*/, Instant> instants =
{
  'A': Instant.utc(2000, 1, 1, 0, 0),
  'B': Instant.utc(2001, 1, 1, 0, 0),
  'C': Instant.utc(2002, 1, 1, 0, 0),
  'D': Instant.utc(2003, 1, 1, 0, 0),
  'E': Instant.utc(2004, 1, 1, 0, 0),
  'F': Instant.utc(2005, 1, 1, 0, 0),
  'G': Instant.utc(2006, 1, 1, 0, 0),
  'H': Instant.utc(2007, 1, 1, 0, 0),
  'I': Instant.utc(2008, 1, 1, 0, 0),
};

late DateTimeZone expectedZone;

// This is just a variety of interesting tests, hopefully covering everything we need. Imagine a time line,
// and the letters in the string break it up into partial maps (all based on the original zone). We should
// be able to break it up anywhere and still get back to something equivalent to the original zone.
@Test()
@TestCase([''])
@TestCase(['A'])
@TestCase(['C'])
@TestCase(['E'])
@TestCase(['G'])
@TestCase(['H'])
@TestCase(['AB'])
@TestCase(['AC'])
@TestCase(['AD'])
@TestCase(['AG'])
@TestCase(['AH'])
@TestCase(['CG'])
@TestCase(['CH'])
@TestCase(['ACD'])
@TestCase(['ACG'])
@TestCase(['ACH'])
@TestCase(['DEF'])
@TestCase(['ABCDEFGHI'])
void ConvertToFullMap(String intervalBreaks) {
  var maps = <PartialZoneIntervalMap>[];
  // We just reuse ExpectedZone as the IZoneIntervalMap; PartialZoneIntervalMap itself will clamp the ends.
  var current = IInstant.beforeMinValue;
  for (var instant in intervalBreaks.codeUnits.map((c) => instants[String.fromCharCode(c)]!)) {
    maps.add(PartialZoneIntervalMap(current, instant, expectedZone));
    current = instant;
  }
  maps.add(PartialZoneIntervalMap(current, IInstant.afterMaxValue, expectedZone));

  var converted = PartialZoneIntervalMap.convertToFullMap(maps);
  // CollectionAssert.AreEqual(
  expect(getZoneIntervals(expectedZone), getZoneIntervals(converted));
}

// TODO: Consider making this part of the NodaTime assembly.
// It's just a copy from DateTimeZone, with the interval taken out.
// It could be an extension method on IZoneIntervalMap, with optional interval.
// On the other hand, IZoneIntervalMap is internal, so it would only be used by us.
Iterable<ZoneInterval> getZoneIntervals(ZoneIntervalMap map) sync*
{
  var current = Instant.minValue;
  while (current < IInstant.afterMaxValue)
  {
    var zoneInterval = map.getZoneInterval(current);
    yield zoneInterval;
    // If this is the end of time, this will just fail on the next comparison.
    current = IZoneInterval.rawEnd(zoneInterval);
  }
}

