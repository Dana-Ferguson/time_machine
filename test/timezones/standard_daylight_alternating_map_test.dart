// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:test/test.dart';

import '../time_machine_testing.dart';

Future main() async {
  await runTests();
}

ZoneRecurrence Winter = ZoneRecurrence('Winter', Offset.zero,
ZoneYearOffset(TransitionMode.wall, 10, 5, 0, false, LocalTime(2, 0, 0)), 2000, Platform.int32MaxValue);

ZoneRecurrence Summer = ZoneRecurrence('Summer', Offset.hours(1),
ZoneYearOffset(TransitionMode.wall, 3, 10, 0, false, LocalTime(1, 0, 0)), 2000, Platform.int32MaxValue);

/// Time zone with the following characteristics:
/// - Only valid from March 10th 2000
/// - Standard offset of +5 (so 4am UTC = 9am local)
/// - Summer time (DST = 1 hour) always starts at 1am local time on March 10th (skips to 2am)
/// - Winter time (DST = 0) always starts at 2am local time on October 5th (skips to 1am)
StandardDaylightAlternatingMap TestMap =
StandardDaylightAlternatingMap(Offset.hours(5), Winter, Summer);

DateTimeZone TestZone = PrecalculatedDateTimeZone(
  'zone',
  [ IZoneInterval.newZoneInterval('Before', IInstant.beforeMinValue, Instant.utc(1999, 12, 1, 0, 0), Offset.hours(5), Summer.savings) ],
  StandardDaylightAlternatingMap(Offset.hours(5), Winter, Summer));

@Test()
void MinMaxOffsets()
{
  expect(Offset.hours(6), TestMap.maxOffset);
  expect(Offset.hours(5), TestMap.minOffset);
}

@Test()
void GetZoneInterval_Instant_Summer()
{
  var interval = TestMap.getZoneInterval(Instant.utc(2010, 6, 1, 0, 0));
  expect('Summer', interval.name);
  expect(Offset.hours(6), interval.wallOffset);
  expect(Offset.hours(5), interval.standardOffset);
  expect(Offset.hours(1), interval.savings);
  expect(LocalDateTime(2010, 3, 10, 2, 0, 0), interval.isoLocalStart);
  expect(LocalDateTime(2010, 10, 5, 2, 0, 0), interval.isoLocalEnd);
}

@Test()
void GetZoneInterval_Instant_Winter()
{
  var interval = TestMap.getZoneInterval(Instant.utc(2010, 11, 1, 0, 0));
  expect('Winter', interval.name);
  expect(Offset.hours(5), interval.wallOffset);
  expect(Offset.hours(5), interval.standardOffset);
  expect(Offset.hours(0), interval.savings);
  expect(LocalDateTime(2010, 10, 5, 1, 0, 0), interval.isoLocalStart);
  expect(LocalDateTime(2011, 3, 10, 1, 0, 0), interval.isoLocalEnd);
}

@Test()
void GetZoneInterval_Instant_StartOfFirstSummer()
{
  // This is only just about valid
  var firstSummer = Instant.utc(2000, 3, 9, 20, 0);
  var interval = TestMap.getZoneInterval(firstSummer);
  expect('Summer', interval.name);
}

@Test()
void MapLocal_WithinFirstSummer()
{
  var early = LocalDateTime(2000, 6, 1, 0, 0, 0);
  CheckMapping(TestZone.mapLocal(early), 'Summer', "Summer", 1);
}

@Test()
void MapLocal_WithinFirstWinter()
{
  var winter = LocalDateTime(2000, 12, 1, 0, 0, 0);
  CheckMapping(TestZone.mapLocal(winter), 'Winter', "Winter", 1);
}

@Test()
void MapLocal_AtFirstGapStart()
{
  var startOfFirstGap = LocalDateTime(2000, 3, 10, 1, 0, 0);
  CheckMapping(TestZone.mapLocal(startOfFirstGap), 'Winter', "Summer", 0);
}

@Test()
void MapLocal_WithinFirstGap()
{
  var middleOfFirstGap = LocalDateTime(2000, 3, 10, 1, 30, 0);
  CheckMapping(TestZone.mapLocal(middleOfFirstGap), 'Winter', "Summer", 0);
}

@Test()
void MapLocal_EndOfFirstGap()
{
  var endOfFirstGap = LocalDateTime(2000, 3, 10, 2, 0, 0);
  CheckMapping(TestZone.mapLocal(endOfFirstGap), 'Summer', "Summer", 1);
}

@Test()
void MapLocal_StartOfFirstAmbiguity()
{
  var firstAmbiguity = LocalDateTime(2000, 10, 5, 1, 0, 0);
  CheckMapping(TestZone.mapLocal(firstAmbiguity), 'Summer', "Winter", 2);
}

@Test()
void MapLocal_MiddleOfFirstAmbiguity()
{
  var firstAmbiguity = LocalDateTime(2000, 10, 5, 1, 30, 0);
  CheckMapping(TestZone.mapLocal(firstAmbiguity), 'Summer', "Winter", 2);
}

@Test()
void MapLocal_AfterFirstAmbiguity()
{
  var unambiguousWinter = LocalDateTime(2000, 10, 5, 2, 0, 0);
  CheckMapping(TestZone.mapLocal(unambiguousWinter), 'Winter', "Winter", 1);
}

@Test()
void MapLocal_WithinArbitrarySummer()
{
  var summer = LocalDateTime(2010, 6, 1, 0, 0, 0);
  CheckMapping(TestZone.mapLocal(summer), 'Summer', "Summer", 1);
}

@Test()
void MapLocal_WithinArbitraryWinter()
{
  var winter = LocalDateTime(2010, 12, 1, 0, 0, 0);
  CheckMapping(TestZone.mapLocal(winter), 'Winter', "Winter", 1);
}

@Test()
void MapLocal_AtArbitraryGapStart()
{
  var startOfGap = LocalDateTime(2010, 3, 10, 1, 0, 0);
  CheckMapping(TestZone.mapLocal(startOfGap), 'Winter', "Summer", 0);
}

@Test()
void MapLocal_WithinArbitraryGap()
{
  var middleOfGap = LocalDateTime(2010, 3, 10, 1, 30, 0);
  CheckMapping(TestZone.mapLocal(middleOfGap), 'Winter', "Summer", 0);
}

@Test()
void MapLocal_EndOfArbitraryGap()
{
  var endOfGap = LocalDateTime(2010, 3, 10, 2, 0, 0);
  CheckMapping(TestZone.mapLocal(endOfGap), 'Summer', "Summer", 1);
}

@Test()
void MapLocal_StartOfArbitraryAmbiguity()
{
  var ambiguity = LocalDateTime(2010, 10, 5, 1, 0, 0);
  CheckMapping(TestZone.mapLocal(ambiguity), 'Summer', "Winter", 2);
}

@Test()
void MapLocal_MiddleOfArbitraryAmbiguity()
{
  var ambiguity = LocalDateTime(2010, 10, 5, 1, 30, 0);
  CheckMapping(TestZone.mapLocal(ambiguity), 'Summer', "Winter", 2);
}

@Test()
void MapLocal_AfterArbitraryAmbiguity()
{
  var unambiguousWinter = LocalDateTime(2010, 10, 5, 2, 0, 0);
  CheckMapping(TestZone.mapLocal(unambiguousWinter), 'Winter', "Winter", 1);
}

@Test()
void Equality() {
  // Order of recurrences doesn't matter
  var map1 = StandardDaylightAlternatingMap(Offset.hours(1), Summer, Winter);
  var map2 = StandardDaylightAlternatingMap(Offset.hours(1), Winter, Summer);
  var map3 = StandardDaylightAlternatingMap(Offset.hours(1), Winter,
      // Summer, but starting from 1900
      ZoneRecurrence('Summer', Offset.hours(1),
          ZoneYearOffset(TransitionMode.wall, 3, 10, 0, false, LocalTime(1, 0, 0)), 1900, Platform.int32MaxValue));
  // Standard offset does matter
  var map4 = StandardDaylightAlternatingMap(Offset.hours(0), Summer, Winter);

  TestHelper.TestEqualsClass(map1, map2, [map4]);
  TestHelper.TestEqualsClass(map1, map3, [map4]);

  // Recurrences like Summer, but different in one aspect each, *except* 
  var unequalMaps = [
    ZoneRecurrence('Different name', Offset.hours(1),
        ZoneYearOffset(TransitionMode.wall, 3, 10, 0, false, LocalTime(1, 0, 0)), 2000, Platform.int32MaxValue),
    ZoneRecurrence('Summer', Offset.hours(2),
        ZoneYearOffset(TransitionMode.wall, 3, 10, 0, false, LocalTime(1, 0, 0)), 2000, Platform.int32MaxValue),
    ZoneRecurrence('Summer', Offset.hours(1),
        ZoneYearOffset(TransitionMode.standard, 3, 10, 0, false, LocalTime(1, 0, 0)), 2000, Platform.int32MaxValue),
    ZoneRecurrence('Summer', Offset.hours(1),
        ZoneYearOffset(TransitionMode.wall, 4, 10, 0, false, LocalTime(1, 0, 0)), 2000, Platform.int32MaxValue),
    ZoneRecurrence('Summer', Offset.hours(1),
        ZoneYearOffset(TransitionMode.wall, 3, 9, 0, false, LocalTime(1, 0, 0)), 2000, Platform.int32MaxValue),
    ZoneRecurrence('Summer', Offset.hours(1),
        ZoneYearOffset(TransitionMode.wall, 3, 10, 1, false, LocalTime(1, 0, 0)), 2000, Platform.int32MaxValue),
    // Advance with day-of-week 0 doesn't make any real difference, but they compare non-equal...
    ZoneRecurrence('Summer', Offset.hours(1),
        ZoneYearOffset(TransitionMode.wall, 3, 10, 0, true, LocalTime(1, 0, 0)), 2000, Platform.int32MaxValue),
    ZoneRecurrence('Summer', Offset.hours(1),
        ZoneYearOffset(TransitionMode.wall, 3, 10, 0, false, LocalTime(2, 0, 0)), 2000, Platform.int32MaxValue)
  ].map((recurrence) => StandardDaylightAlternatingMap(Offset.hours(1), Winter, recurrence)).toList();
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
  ZoneRecurrence winter = ZoneRecurrence('Winter', Offset.zero,
      ZoneYearOffset(TransitionMode.wall, 10, 5, 0, false, LocalTime(2, 0, 0)), Platform.int32MinValue, Platform.int32MaxValue);

  ZoneRecurrence summer = ZoneRecurrence('Summer', Offset.hours(1),
      ZoneYearOffset(TransitionMode.wall, 3, 10, 0, false, LocalTime(1, 0, 0)), Platform.int32MinValue, Platform.int32MaxValue);

  var zone = StandardDaylightAlternatingMap(Offset.zero, winter, summer);

  var firstSpring = Instant.utc(-9998, 3, 10, 1, 0);
  var firstAutumn = Instant.utc(-9998, 10, 5, 1, 0); // 1am UTC = 2am wall

  var lastSpring = Instant.utc(9999, 3, 10, 1, 0);
  var lastAutumn = Instant.utc(9999, 10, 5, 1, 0); // 1am UTC = 2am wall

  var dstOffset = Offset.hours(1);

  // Check both year -9998 and 9999, both the infinite interval and the next one in
  var firstWinter = IZoneInterval.newZoneInterval('Winter', IInstant.beforeMinValue, firstSpring, Offset.zero, Offset.zero);
  var firstSummer = IZoneInterval.newZoneInterval('Summer', firstSpring, firstAutumn, dstOffset, dstOffset);
  var lastSummer = IZoneInterval.newZoneInterval('Summer', lastSpring, lastAutumn, dstOffset, dstOffset);
  var lastWinter = IZoneInterval.newZoneInterval('Winter', lastAutumn, IInstant.afterMaxValue, Offset.zero, Offset.zero);

  expect(firstWinter, zone.getZoneInterval(Instant.minValue));
  expect(firstWinter, zone.getZoneInterval(Instant.utc(-9998, 2, 1, 0, 0)));
  expect(firstSummer, zone.getZoneInterval(firstSpring));
  expect(firstSummer, zone.getZoneInterval(Instant.utc(-9998, 5, 1, 0, 0)));

  expect(lastSummer, zone.getZoneInterval(lastSpring));
  expect(lastSummer, zone.getZoneInterval(Instant.utc(9999, 5, 1, 0, 0)));
  expect(lastWinter, zone.getZoneInterval(lastAutumn));
  expect(lastWinter, zone.getZoneInterval(Instant.utc(9999, 11, 1, 0, 0)));
  expect(lastWinter, zone.getZoneInterval(Instant.maxValue));
}

@Test()
void InvalidMap_SimultaneousTransition()
{
  // Two recurrences with different savings, but which occur at the same instant in time every year.
  ZoneRecurrence r1 = ZoneRecurrence('Recurrence1', Offset.zero,
      ZoneYearOffset(TransitionMode.utc, 10, 5, 0, false, LocalTime(2, 0, 0)), Platform.int32MinValue, Platform.int32MaxValue);

  ZoneRecurrence r2 = ZoneRecurrence('Recurrence2', Offset.hours(1),
      ZoneYearOffset(TransitionMode.utc, 10, 5, 0, false, LocalTime(2, 0, 0)), Platform.int32MinValue, Platform.int32MaxValue);

  var map = StandardDaylightAlternatingMap(Offset.zero, r1, r2);

  expect(() => map.getZoneInterval(Instant.utc(2017, 8, 25, 0, 0, 0)), throwsStateError);
}

void CheckMapping(ZoneLocalMapping mapping, String earlyIntervalName, String lateIntervalName, int count)
{
  expect(earlyIntervalName, mapping.earlyInterval.name);
  expect(lateIntervalName, mapping.lateInterval.name);
  expect(count, mapping.count);
}

