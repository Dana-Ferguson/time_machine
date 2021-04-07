// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

import 'time_machine_testing.dart';

Future main() async {
  await TimeMachine.initialize();
  await runTests();
}

@Test()
Future TzdbProviderUsesTzdbSource () async
{
  expect((await DateTimeZoneProviders.tzdb).versionId?.startsWith('TZDB: '), isTrue);
}

@Test()
Future AllTzdbTimeZonesLoad() async
{
  var tzdb = await DateTimeZoneProviders.tzdb;
  var allZones = tzdb.ids.map((id) => tzdb[id]).toList();
  // Just to stop the variable from being lonely. In reality, it's likely there'll be a breakpoint here to inspect a particular zone...
  expect(allZones.length > 50, isTrue);
}
