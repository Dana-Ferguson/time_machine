import 'dart:async';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import 'testing/timezones/single_transition_datetimezone.dart';
import 'testing/timezones/multi_transition_datetimezone.dart';
import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

/// <summary>
/// Tests for code in DateTimeZone and code which will be moving out
/// of DateTimeZones into DateTimeZone over time.
/// </summary>
@Test()
void UtcIsNotNull()
{
  expect(DateTimeZone.Utc, isNotNull);
}
