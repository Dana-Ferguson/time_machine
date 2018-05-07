// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/TimeAdjustersTest.cs
// de133ae  on Dec 31, 2016

import 'dart:async';
import 'dart:math' as math;

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
void TruncateToSecond()
{
  var start = LocalTime.FromHourMinuteSecondMillisecondTick(7, 4, 30, 123, 4567);
  var end = new LocalTime(7, 4, 30);
  expect(end, TimeAdjusters.TruncateToSecond(start));
}

@Test()
void TruncateToMinute()
{
  var start = LocalTime.FromHourMinuteSecondMillisecondTick(7, 4, 30, 123, 4567);
  var end = new LocalTime(7, 4, 0);
  expect(end, TimeAdjusters.TruncateToMinute(start));
}

@Test()
void TruncateToHour()
{
  var start = LocalTime.FromHourMinuteSecondMillisecondTick(7, 4, 30, 123, 4567);
  var end = new LocalTime(7, 0, 0);
  expect(end, TimeAdjusters.TruncateToHour(start));
}
