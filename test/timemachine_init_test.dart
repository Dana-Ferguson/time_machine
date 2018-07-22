// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:test/test.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

Future<String> getTimeZone() async {
  return 'Europe/Paris';
}

@Test()
Future timezoneCanBeOverridden() async
{
  if (Platform.isWeb) return;
  await TimeMachine.initialize({'timeZone': await getTimeZone()});
  expect(DateTimeZone.local.id, 'Europe/Paris');
}

// todo: can I add a test for loading Flutter's rootBundle? (via a mock?)