// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/TimeZones/TzdbZone1970LocationTest.cs
// cae7975  on Aug 24, 2017

// We do not currently include 1970's time zone location data

import 'dart:async';
import 'dart:math' as math;

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import '../time_machine_testing.dart';

Future main() async {
  await runTests();
}