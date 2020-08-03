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
  ExpectedZone = (MtdtzBuilder.withName(-2, 'Start')
    ..Add(Instants['C'], 2, 1, "Middle")
    ..Add(Instants['G'], 1, 0, "End")
  ).Build();
}

// Arbitrary instants which are useful for the tests. They happen to be a year
// apart, but nothing in these tests actually cares.
// Various tests use a time zone with transitions at C and G.
// Using letter is (IMO) slightly more readable than just having an array and using indexes.
Map<String /*char*/, Instant> Instants =
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

DateTimeZone ExpectedZone;

// This is just a variety of interesting tests, hopefully covering everything we need. Imagine a time line,
// and the letters in the string break it up into partial maps (all based on the original zone). We should
// be able to break it up anywhere and still get back to something equivalent to the original zone.
@Test()
@TestCase(const [''])
@TestCase(const ['A'])
@TestCase(const ['C'])
@TestCase(const ['E'])
@TestCase(const ['G'])
@TestCase(const ['H'])
@TestCase(const ['AB'])
@TestCase(const ['AC'])
@TestCase(const ['AD'])
@TestCase(const ['AG'])
@TestCase(const ['AH'])
@TestCase(const ['CG'])
@TestCase(const ['CH'])
@TestCase(const ['ACD'])
@TestCase(const ['ACG'])
@TestCase(const ['ACH'])
@TestCase(const ['DEF'])
@TestCase(const ['ABCDEFGHI'])
void ConvertToFullMap(String intervalBreaks) {
  var maps = List<PartialZoneIntervalMap>();
  // We just reuse ExpectedZone as the IZoneIntervalMap; PartialZoneIntervalMap itself will clamp the ends.
  var current = IInstant.beforeMinValue;
  for (var instant in intervalBreaks.codeUnits.map((c) => Instants[String.fromCharCode(c)])) {
    maps.add(PartialZoneIntervalMap(current, instant, ExpectedZone));
    current = instant;
  }
  maps.add(PartialZoneIntervalMap(current, IInstant.afterMaxValue, ExpectedZone));

  var converted = PartialZoneIntervalMap.convertToFullMap(maps);
  // CollectionAssert.AreEqual(
  expect(GetZoneIntervals(ExpectedZone), GetZoneIntervals(converted));
}

// TODO: Consider making this part of the NodaTime assembly.
// It's just a copy from DateTimeZone, with the interval taken out.
// It could be an extension method on IZoneIntervalMap, with optional interval.
// On the other hand, IZoneIntervalMap is internal, so it would only be used by us.
Iterable<ZoneInterval> GetZoneIntervals(ZoneIntervalMap map) sync*
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

