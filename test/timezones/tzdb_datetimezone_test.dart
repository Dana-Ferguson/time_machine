// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.


import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

import '../time_machine_testing.dart';

late Iterable<DateTimeZone> allTzdbZones;

Future main() async {
  await TimeMachine.initialize();
  allTzdbZones = await (await DateTimeZoneProviders.tzdb).getAllZones();

  await runTests();
}

@Test()
@TestCaseSource(#allTzdbZones)
void AllZonesStartAndEndOfTime(DateTimeZone zone)
{
  var firstInterval = zone.getZoneInterval(Instant.minValue);
  expect(firstInterval.hasStart, isFalse);
  var lastInterval = zone.getZoneInterval(Instant.maxValue);
  expect(lastInterval.hasEnd, isFalse);
}

