// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:math' as math;

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

import '../time_machine_testing.dart';

/// Algiers had DST until May 1st 1981, after which time it didn't have any - so
/// we use that to test a time zone whose transitions run out. (When Algiers
/// decided to stop using DST, it changed its standard offset to be what had previously
/// been its DST offset, i.e. +1.)
Future main() async {
  await TimeMachine.initialize();
  await setup();

  await runTests();
}

Future setup() async {
  Algiers = await (await DateTimeZoneProviders.tzdb)["Africa/Algiers"];
}

DateTimeZone Algiers;

@Test()
void GetPeriod_BeforeLast()
{
  Instant april1981 = new Instant.fromUtc(1981, 4, 1, 0, 0);
  var actual = Algiers.getZoneInterval(april1981);
  var expected = IZoneInterval.newZoneInterval("WET", new Instant.fromUnixTimeMicroseconds(341802000000000), new Instant.fromUnixTimeMicroseconds(357523200000000), Offset.zero, Offset.zero);
  expect(expected, actual);
}

@Test()
void GetPeriod_AfterLastTransition()
{
  var may1981 = new ZonedDateTime.atStrictly(new LocalDateTime.at(1981, 5, 1, 0, 0, 1), DateTimeZone.utc).toInstant();
  var actual = Algiers.getZoneInterval(may1981);
  var expected = IZoneInterval.newZoneInterval("CET", new Instant.fromUnixTimeMicroseconds(357523200000000), null, new Offset(TimeConstants.secondsPerHour), Offset.zero);
  expect(expected, actual);
}


