// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

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

ZoneRecurrence Winter = new ZoneRecurrence("Winter", Offset.zero,
new ZoneYearOffset(TransitionMode.wall, 10, 5, 0, false, new LocalTime(2, 0)), 2000, Utility.int32MaxValue);

ZoneRecurrence Summer = new ZoneRecurrence("Summer", new Offset.fromHours(1),
new ZoneYearOffset(TransitionMode.wall, 3, 10, 0, false, new LocalTime(1, 0)), 2000, Utility.int32MaxValue);

/// Time zone with the following characteristics:
/// - Only valid from March 10th 2000
/// - Standard offset of +5 (so 4am UTC = 9am local)
/// - Summer time (DST = 1 hour) always starts at 1am local time on March 10th (skips to 2am)
/// - Winter time (DST = 0) always starts at 2am local time on October 5th (skips to 1am)
StandardDaylightAlternatingMap TestMap =
new StandardDaylightAlternatingMap(new Offset.fromHours(5), Winter, Summer);

DateTimeZone TestZone = new PrecalculatedDateTimeZone(
  "zone",
  [ new ZoneInterval("Before", Instant.beforeMinValue, new Instant.fromUtc(1999, 12, 1, 0, 0), new Offset.fromHours(5), Summer.savings) ],
  new StandardDaylightAlternatingMap(new Offset.fromHours(5), Winter, Summer));

@Test()
void MinMaxOffsets()
{
  expect(new Offset.fromHours(6), TestMap.maxOffset);
  expect(new Offset.fromHours(5), TestMap.minOffset);
}

@Test()
void GetZoneInterval_Instant_Summer()
{
  var interval = TestMap.GetZoneInterval(new Instant.fromUtc(2010, 6, 1, 0, 0));
  expect("Summer", interval.name);
  expect(new Offset.fromHours(6), interval.wallOffset);
  expect(new Offset.fromHours(5), interval.StandardOffset);
  expect(new Offset.fromHours(1), interval.savings);
  expect(new LocalDateTime.fromYMDHM(2010, 3, 10, 2, 0), interval.IsoLocalStart);
  expect(new LocalDateTime.fromYMDHM(2010, 10, 5, 2, 0), interval.IsoLocalEnd);
}

@Test()
void GetZoneInterval_Instant_Winter()
{
  var interval = TestMap.GetZoneInterval(new Instant.fromUtc(2010, 11, 1, 0, 0));
  expect("Winter", interval.name);
  expect(new Offset.fromHours(5), interval.wallOffset);
  expect(new Offset.fromHours(5), interval.StandardOffset);
  expect(new Offset.fromHours(0), interval.savings);
  expect(new LocalDateTime.fromYMDHM(2010, 10, 5, 1, 0), interval.IsoLocalStart);
  expect(new LocalDateTime.fromYMDHM(2011, 3, 10, 1, 0), interval.IsoLocalEnd);
}

@Test()
void GetZoneInterval_Instant_StartOfFirstSummer()
{
  // This is only just about valid
  var firstSummer = new Instant.fromUtc(2000, 3, 9, 20, 0);
  var interval = TestMap.GetZoneInterval(firstSummer);
  expect("Summer", interval.name);
}

@Test()
void MapLocal_WithinFirstSummer()
{
  var early = new LocalDateTime.fromYMDHM(2000, 6, 1, 0, 0);
  CheckMapping(TestZone.MapLocal(early), "Summer", "Summer", 1);
}

@Test()
void MapLocal_WithinFirstWinter()
{
  var winter = new LocalDateTime.fromYMDHM(2000, 12, 1, 0, 0);
  CheckMapping(TestZone.MapLocal(winter), "Winter", "Winter", 1);
}

@Test()
void MapLocal_AtFirstGapStart()
{
  var startOfFirstGap = new LocalDateTime.fromYMDHM(2000, 3, 10, 1, 0);
  CheckMapping(TestZone.MapLocal(startOfFirstGap), "Winter", "Summer", 0);
}

@Test()
void MapLocal_WithinFirstGap()
{
  var middleOfFirstGap = new LocalDateTime.fromYMDHM(2000, 3, 10, 1, 30);
  CheckMapping(TestZone.MapLocal(middleOfFirstGap), "Winter", "Summer", 0);
}

@Test()
void MapLocal_EndOfFirstGap()
{
  var endOfFirstGap = new LocalDateTime.fromYMDHM(2000, 3, 10, 2, 0);
  CheckMapping(TestZone.MapLocal(endOfFirstGap), "Summer", "Summer", 1);
}

@Test()
void MapLocal_StartOfFirstAmbiguity()
{
  var firstAmbiguity = new LocalDateTime.fromYMDHM(2000, 10, 5, 1, 0);
  CheckMapping(TestZone.MapLocal(firstAmbiguity), "Summer", "Winter", 2);
}

@Test()
void MapLocal_MiddleOfFirstAmbiguity()
{
  var firstAmbiguity = new LocalDateTime.fromYMDHM(2000, 10, 5, 1, 30);
  CheckMapping(TestZone.MapLocal(firstAmbiguity), "Summer", "Winter", 2);
}

@Test()
void MapLocal_AfterFirstAmbiguity()
{
  var unambiguousWinter = new LocalDateTime.fromYMDHM(2000, 10, 5, 2, 0);
  CheckMapping(TestZone.MapLocal(unambiguousWinter), "Winter", "Winter", 1);
}

@Test()
void MapLocal_WithinArbitrarySummer()
{
  var summer = new LocalDateTime.fromYMDHM(2010, 6, 1, 0, 0);
  CheckMapping(TestZone.MapLocal(summer), "Summer", "Summer", 1);
}

@Test()
void MapLocal_WithinArbitraryWinter()
{
  var winter = new LocalDateTime.fromYMDHM(2010, 12, 1, 0, 0);
  CheckMapping(TestZone.MapLocal(winter), "Winter", "Winter", 1);
}

@Test()
void MapLocal_AtArbitraryGapStart()
{
  var startOfGap = new LocalDateTime.fromYMDHM(2010, 3, 10, 1, 0);
  CheckMapping(TestZone.MapLocal(startOfGap), "Winter", "Summer", 0);
}

@Test()
void MapLocal_WithinArbitraryGap()
{
  var middleOfGap = new LocalDateTime.fromYMDHM(2010, 3, 10, 1, 30);
  CheckMapping(TestZone.MapLocal(middleOfGap), "Winter", "Summer", 0);
}

@Test()
void MapLocal_EndOfArbitraryGap()
{
  var endOfGap = new LocalDateTime.fromYMDHM(2010, 3, 10, 2, 0);
  CheckMapping(TestZone.MapLocal(endOfGap), "Summer", "Summer", 1);
}

@Test()
void MapLocal_StartOfArbitraryAmbiguity()
{
  var ambiguity = new LocalDateTime.fromYMDHM(2010, 10, 5, 1, 0);
  CheckMapping(TestZone.MapLocal(ambiguity), "Summer", "Winter", 2);
}

@Test()
void MapLocal_MiddleOfArbitraryAmbiguity()
{
  var ambiguity = new LocalDateTime.fromYMDHM(2010, 10, 5, 1, 30);
  CheckMapping(TestZone.MapLocal(ambiguity), "Summer", "Winter", 2);
}

@Test()
void MapLocal_AfterArbitraryAmbiguity()
{
  var unambiguousWinter = new LocalDateTime.fromYMDHM(2010, 10, 5, 2, 0);
  CheckMapping(TestZone.MapLocal(unambiguousWinter), "Winter", "Winter", 1);
}

@Test()
void Equality() {
  // Order of recurrences doesn't matter
  var map1 = new StandardDaylightAlternatingMap(new Offset.fromHours(1), Summer, Winter);
  var map2 = new StandardDaylightAlternatingMap(new Offset.fromHours(1), Winter, Summer);
  var map3 = new StandardDaylightAlternatingMap(new Offset.fromHours(1), Winter,
      // Summer, but starting from 1900
      new ZoneRecurrence("Summer", new Offset.fromHours(1),
          new ZoneYearOffset(TransitionMode.wall, 3, 10, 0, false, new LocalTime(1, 0)), 1900, Utility.int32MaxValue));
  // Standard offset does matter
  var map4 = new StandardDaylightAlternatingMap(new Offset.fromHours(0), Summer, Winter);

  TestHelper.TestEqualsClass(map1, map2, [map4]);
  TestHelper.TestEqualsClass(map1, map3, [map4]);

  // Recurrences like Summer, but different in one aspect each, *except* 
  var unequalMaps = [
    new ZoneRecurrence("Different name", new Offset.fromHours(1),
        new ZoneYearOffset(TransitionMode.wall, 3, 10, 0, false, new LocalTime(1, 0)), 2000, Utility.int32MaxValue),
    new ZoneRecurrence("Summer", new Offset.fromHours(2),
        new ZoneYearOffset(TransitionMode.wall, 3, 10, 0, false, new LocalTime(1, 0)), 2000, Utility.int32MaxValue),
    new ZoneRecurrence("Summer", new Offset.fromHours(1),
        new ZoneYearOffset(TransitionMode.standard, 3, 10, 0, false, new LocalTime(1, 0)), 2000, Utility.int32MaxValue),
    new ZoneRecurrence("Summer", new Offset.fromHours(1),
        new ZoneYearOffset(TransitionMode.wall, 4, 10, 0, false, new LocalTime(1, 0)), 2000, Utility.int32MaxValue),
    new ZoneRecurrence("Summer", new Offset.fromHours(1),
        new ZoneYearOffset(TransitionMode.wall, 3, 9, 0, false, new LocalTime(1, 0)), 2000, Utility.int32MaxValue),
    new ZoneRecurrence("Summer", new Offset.fromHours(1),
        new ZoneYearOffset(TransitionMode.wall, 3, 10, 1, false, new LocalTime(1, 0)), 2000, Utility.int32MaxValue),
    // Advance with day-of-week 0 doesn't make any real difference, but they compare non-equal...
    new ZoneRecurrence("Summer", new Offset.fromHours(1),
        new ZoneYearOffset(TransitionMode.wall, 3, 10, 0, true, new LocalTime(1, 0)), 2000, Utility.int32MaxValue),
    new ZoneRecurrence("Summer", new Offset.fromHours(1),
        new ZoneYearOffset(TransitionMode.wall, 3, 10, 0, false, new LocalTime(2, 0)), 2000, Utility.int32MaxValue)
  ].map((recurrence) => new StandardDaylightAlternatingMap(new Offset.fromHours(1), Winter, recurrence)).toList();
  TestHelper.TestEqualsClass(map1, map2, unequalMaps);
}

/* todo: ReadWrite compatible
@Test()
void ReadWrite()
{
  var map1 = new StandardDaylightAlternatingMap(new Offset.fromHours(1), Summer, Winter);
  var stream = new MemoryStream();
  var writer = new DateTimeZoneWriter(stream, null);
  map1.Write(writer);
  stream.Position = 0;

  var reader = new DateTimeZoneReader(stream, null);
  var map2 = StandardDaylightAlternatingMap.Read(reader);
  expect(map1, map2);
}*/

@Test()
void Extremes()
{
  ZoneRecurrence winter = new ZoneRecurrence("Winter", Offset.zero,
      new ZoneYearOffset(TransitionMode.wall, 10, 5, 0, false, new LocalTime(2, 0)), Utility.int32MinValue, Utility.int32MaxValue);

  ZoneRecurrence summer = new ZoneRecurrence("Summer", new Offset.fromHours(1),
      new ZoneYearOffset(TransitionMode.wall, 3, 10, 0, false, new LocalTime(1, 0)), Utility.int32MinValue, Utility.int32MaxValue);

  var zone = new StandardDaylightAlternatingMap(Offset.zero, winter, summer);

  var firstSpring = new Instant.fromUtc(-9998, 3, 10, 1, 0);
  var firstAutumn = new Instant.fromUtc(-9998, 10, 5, 1, 0); // 1am UTC = 2am wall

  var lastSpring = new Instant.fromUtc(9999, 3, 10, 1, 0);
  var lastAutumn = new Instant.fromUtc(9999, 10, 5, 1, 0); // 1am UTC = 2am wall

  var dstOffset = new Offset.fromHours(1);

  // Check both year -9998 and 9999, both the infinite interval and the next one in
  var firstWinter = new ZoneInterval("Winter", Instant.beforeMinValue, firstSpring, Offset.zero, Offset.zero);
  var firstSummer = new ZoneInterval("Summer", firstSpring, firstAutumn, dstOffset, dstOffset);
  var lastSummer = new ZoneInterval("Summer", lastSpring, lastAutumn, dstOffset, dstOffset);
  var lastWinter = new ZoneInterval("Winter", lastAutumn, Instant.afterMaxValue, Offset.zero, Offset.zero);

  expect(firstWinter, zone.GetZoneInterval(Instant.minValue));
  expect(firstWinter, zone.GetZoneInterval(new Instant.fromUtc(-9998, 2, 1, 0, 0)));
  expect(firstSummer, zone.GetZoneInterval(firstSpring));
  expect(firstSummer, zone.GetZoneInterval(new Instant.fromUtc(-9998, 5, 1, 0, 0)));

  expect(lastSummer, zone.GetZoneInterval(lastSpring));
  expect(lastSummer, zone.GetZoneInterval(new Instant.fromUtc(9999, 5, 1, 0, 0)));
  expect(lastWinter, zone.GetZoneInterval(lastAutumn));
  expect(lastWinter, zone.GetZoneInterval(new Instant.fromUtc(9999, 11, 1, 0, 0)));
  expect(lastWinter, zone.GetZoneInterval(Instant.maxValue));
}

@Test()
void InvalidMap_SimultaneousTransition()
{
  // Two recurrences with different savings, but which occur at the same instant in time every year.
  ZoneRecurrence r1 = new ZoneRecurrence("Recurrence1", Offset.zero,
      new ZoneYearOffset(TransitionMode.utc, 10, 5, 0, false, new LocalTime(2, 0)), Utility.int32MinValue, Utility.int32MaxValue);

  ZoneRecurrence r2 = new ZoneRecurrence("Recurrence2", new Offset.fromHours(1),
      new ZoneYearOffset(TransitionMode.utc, 10, 5, 0, false, new LocalTime(2, 0)), Utility.int32MinValue, Utility.int32MaxValue);

  var map = new StandardDaylightAlternatingMap(Offset.zero, r1, r2);

  expect(() => map.GetZoneInterval(new Instant.fromUtc(2017, 8, 25, 0, 0, 0)), throwsStateError);
}

void CheckMapping(ZoneLocalMapping mapping, String earlyIntervalName, String lateIntervalName, int count)
{
  expect(earlyIntervalName, mapping.EarlyInterval.name);
  expect(lateIntervalName, mapping.LateInterval.name);
  expect(count, mapping.Count);
}

