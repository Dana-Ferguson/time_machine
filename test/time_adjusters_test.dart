// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:math' as math;

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

@Test()
void TruncateToSecond()
{
  var start = new LocalTime.fromHourMinuteSecondMillisecondTick(7, 4, 30, 123, 4567);
  var end = new LocalTime(7, 4, 30);
  expect(end, TimeAdjusters.truncateToSecond(start));
}

@Test()
void TruncateToMinute()
{
  var start = new LocalTime.fromHourMinuteSecondMillisecondTick(7, 4, 30, 123, 4567);
  var end = new LocalTime(7, 4, 0);
  expect(end, TimeAdjusters.truncateToMinute(start));
}

@Test()
void TruncateToHour()
{
  var start = new LocalTime.fromHourMinuteSecondMillisecondTick(7, 4, 30, 123, 4567);
  var end = new LocalTime(7, 0, 0);
  expect(end, TimeAdjusters.truncateToHour(start));
}

