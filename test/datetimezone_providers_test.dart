import 'dart:async';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

@Test()
Future TzdbProviderUsesTzdbSource () async
{
  expect((await DateTimeZoneProviders.Tzdb).VersionId.startsWith("TZDB: "), isTrue);
}

@Test()
Future AllTzdbTimeZonesLoad() async
{
  var tzdb = await DateTimeZoneProviders.Tzdb;
  var allZones = tzdb.Ids.map((id) => tzdb[id]).toList();
  // Just to stop the variable from being lonely. In reality, it's likely there'll be a breakpoint here to inspect a particular zone...
  expect(allZones.length > 50, isTrue);
}