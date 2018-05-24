// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/TimeZones/EtcTest.cs
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

IDateTimeZoneProvider Tzdb;

/// Tests for fixed "Etc/GMT+x" zones. These just test that the time zones are built
/// appropriately; FixedDateTimeZoneTest takes care of the rest.
Future main() async {
  Tzdb = await DateTimeZoneProviders.Tzdb;

  await runTests();
}

// todo: these don't work at all; I'm guessing these come from Aliases?

@Test() @SkipMe("Aliases not yet available?")
Future FixedEasternZone() async
{
  String id = "Etc/GMT+5";
  var zone = await Tzdb[id];
  expect(id, zone.id);
  expect(zone, new isInstanceOf<FixedDateTimeZone>());
  FixedDateTimeZone fixedZone = zone as FixedDateTimeZone;
  expect(new Offset.fromHours(-5), fixedZone.offset);
}

@Test() @SkipMe("Aliases not yet available?")
Future FixedWesternZone() async
{
  String id = "Etc/GMT-4";
  var zone = await Tzdb[id];
  expect(id, zone.id);
  expect(zone, new isInstanceOf<FixedDateTimeZone>());
  FixedDateTimeZone fixedZone = zone as FixedDateTimeZone;
  expect(new Offset.fromHours(4), fixedZone.offset);
}
