// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

import '../time_machine_testing.dart';

late DateTimeZoneProvider tzdb;

/// Fixture for miscellaneous bug reports and oddities which don't really fit anywhere else.
/// Quite often the cause of a problem is nowhere near the test code; it's still useful
/// to have the original test which showed up the problem, as a small contribution
/// to regression testing.
Future main() async {
  await TimeMachine.initialize();
  await setup();

  await runTests();
}

Future setup() async {
  tzdb = await DateTimeZoneProviders.tzdb;
}


@Test()
Future Niue() async
{
  DateTimeZone niue = await tzdb['Pacific/Niue'];
  var offset = niue.getUtcOffset(ZonedDateTime.atStrictly(LocalDateTime(2010, 1, 1, 0, 0, 0), niue).toInstant());
  expect(Offset.hours(-11), offset);
}

@Test()
Future Kiritimati() async
{
  DateTimeZone kiritimati = await tzdb['Pacific/Kiritimati'];
  var offset = kiritimati.getUtcOffset(ZonedDateTime.atStrictly(LocalDateTime(2010, 1, 1, 0, 0, 0), kiritimati).toInstant());
  expect(Offset.hours(14), offset);
}

@Test()
Future Pyongyang() async
{
  DateTimeZone pyongyang = await tzdb['Asia/Pyongyang'];
  var offset = pyongyang.getUtcOffset(ZonedDateTime.atStrictly(LocalDateTime(2010, 1, 1, 0, 0, 0), pyongyang).toInstant());
  expect(Offset.hours(9), offset);
}

@Test()
Future Khartoum() async
{
  DateTimeZone khartoum = await tzdb['Africa/Khartoum'];
  expect(khartoum, isNotNull);
  Instant utc = Instant.utc(2000, 1, 1, 0, 0, 0);
  ZonedDateTime inKhartoum = ZonedDateTime(utc, khartoum);
  LocalDateTime expectedLocal = LocalDateTime(2000, 1, 1, 2, 0, 0);
  expect(expectedLocal, inKhartoum.localDateTime);

  // Khartoum changed from +2 to +3 on January 15th 2000
  utc = Instant.utc(2000, 1, 16, 0, 0, 0);
  inKhartoum = ZonedDateTime(utc, khartoum);
  expectedLocal = LocalDateTime(2000, 1, 16, 3, 0, 0);
  expect(expectedLocal, inKhartoum.localDateTime);
}

/// Tbilisi used daylight saving time for winter 1996/1997 too.
@Test()
Future Tbilisi() async
{
  var zone = await tzdb['Asia/Tbilisi'];
  Instant summer1996 = Instant.utc(1996, 6, 1, 0, 0);
  var interval = zone.getZoneInterval(summer1996);
  expect(LocalDateTime(1996, 3, 31, 1, 0, 0), interval.isoLocalStart);
  expect(LocalDateTime(1997, 10, 26, 0, 0, 0), interval.isoLocalEnd);
}

