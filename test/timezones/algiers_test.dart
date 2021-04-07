// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:test/test.dart';

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
  algiers = await (await DateTimeZoneProviders.tzdb)['Africa/Algiers'];
}

late DateTimeZone algiers;

@Test()
void GetPeriod_BeforeLast()
{
  Instant april1981 = Instant.utc(1981, 4, 1, 0, 0);
  var actual = algiers.getZoneInterval(april1981);
  var expected = IZoneInterval.newZoneInterval('WET', Instant.fromEpochMicroseconds(341802000000000), Instant.fromEpochMicroseconds(357523200000000), Offset.zero, Offset.zero);
  expect(expected, actual);
}

@Test()
void GetPeriod_AfterLastTransition()
{
  var may1981 = ZonedDateTime.atStrictly(LocalDateTime(1981, 5, 1, 0, 0, 1), DateTimeZone.utc).toInstant();
  var actual = algiers.getZoneInterval(may1981);
  var expected = IZoneInterval.newZoneInterval('CET', Instant.fromEpochMicroseconds(357523200000000), null, Offset(TimeConstants.secondsPerHour), Offset.zero);
  expect(expected, actual);
}


