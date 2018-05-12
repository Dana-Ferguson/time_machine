// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/TimeZones/PartialZoneIntervalMapTest.cs
// 8d5399d  on Feb 26, 2016

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
  ExpectedZone = (new MtdtzBuilder.withName(-2, "Start")
    ..Add(Instants['C'], 2, 1, "Middle")
    ..Add(Instants['G'], 1, 0, "End")
  ).Build();

  await runTests();
}

// Arbitrary instants which are useful for the tests. They happen to be a year
// apart, but nothing in these tests actually cares.
// Various tests use a time zone with transitions at C and G.
// Using letter is (IMO) slightly more readable than just having an array and using indexes.
Map<String /*char*/, Instant> Instants =
{
  'A': new Instant.fromUtc(2000, 1, 1, 0, 0),
  'B': new Instant.fromUtc(2001, 1, 1, 0, 0),
  'C': new Instant.fromUtc(2002, 1, 1, 0, 0),
  'D': new Instant.fromUtc(2003, 1, 1, 0, 0),
  'E': new Instant.fromUtc(2004, 1, 1, 0, 0),
  'F': new Instant.fromUtc(2005, 1, 1, 0, 0),
  'G': new Instant.fromUtc(2006, 1, 1, 0, 0),
  'H': new Instant.fromUtc(2007, 1, 1, 0, 0),
  'I': new Instant.fromUtc(2008, 1, 1, 0, 0),
};

DateTimeZone ExpectedZone;

// This is just a variety of interesting tests, hopefully covering everything we need. Imagine a time line,
// and the letters in the string break it up into partial maps (all based on the original zone). We should
// be able to break it up anywhere and still get back to something equivalent to the original zone.
@Test()
@TestCase(const [""])
@TestCase(const ["A"])
@TestCase(const ["C"])
@TestCase(const ["E"])
@TestCase(const ["G"])
@TestCase(const ["H"])
@TestCase(const ["AB"])
@TestCase(const ["AC"])
@TestCase(const ["AD"])
@TestCase(const ["AG"])
@TestCase(const ["AH"])
@TestCase(const ["CG"])
@TestCase(const ["CH"])
@TestCase(const ["ACD"])
@TestCase(const ["ACG"])
@TestCase(const ["ACH"])
@TestCase(const ["DEF"])
@TestCase(const ["ABCDEFGHI"])
void ConvertToFullMap(String intervalBreaks) {
  var maps = new List<PartialZoneIntervalMap>();
  // We just reuse ExpectedZone as the IZoneIntervalMap; PartialZoneIntervalMap itself will clamp the ends.
  var current = Instant.beforeMinValue;
  for (var instant in intervalBreaks.codeUnits.map((c) => Instants[new String.fromCharCode(c)])) {
    maps.add(new PartialZoneIntervalMap(current, instant, ExpectedZone));
    current = instant;
  }
  maps.add(new PartialZoneIntervalMap(current, Instant.afterMaxValue, ExpectedZone));

  var converted = PartialZoneIntervalMap.ConvertToFullMap(maps);
  // CollectionAssert.AreEqual(
  expect(GetZoneIntervals(ExpectedZone), GetZoneIntervals(converted));
}

// TODO: Consider making this part of the NodaTime assembly.
// It's just a copy from DateTimeZone, with the interval taken out.
// It could be an extension method on IZoneIntervalMap, with optional interval.
// On the other hand, IZoneIntervalMap is internal, so it would only be used by us.
Iterable<ZoneInterval> GetZoneIntervals(IZoneIntervalMap map) sync*
{
  var current = Instant.minValue;
  while (current < Instant.afterMaxValue)
  {
    var zoneInterval = map.GetZoneInterval(current);
    yield zoneInterval;
    // If this is the end of time, this will just fail on the next comparison.
    current = zoneInterval.RawEnd;
  }
}
