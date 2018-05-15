

import 'dart:async';
import 'dart:math' as math;

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import '../time_machine_testing.dart';

Iterable<DateTimeZone> AllTzdbZones;

Future main() async {
  AllTzdbZones = await (await DateTimeZoneProviders.Tzdb).GetAllZones();

  await runTests();
}

@Test()
@TestCaseSource(#AllTzdbZones)
void AllZonesStartAndEndOfTime(DateTimeZone zone)
{
  var firstInterval = zone.GetZoneInterval(Instant.minValue);
  expect(firstInterval.HasStart, isFalse);
  var lastInterval = zone.GetZoneInterval(Instant.maxValue);
  expect(lastInterval.HasEnd, isFalse);
}
