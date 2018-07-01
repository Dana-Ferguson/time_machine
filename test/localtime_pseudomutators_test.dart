// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

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
void PlusHours_Simple()
{
  LocalTime start = new LocalTime(12, 15, 8);
  LocalTime expectedForward = new LocalTime(14, 15, 8);
  LocalTime expectedBackward = new LocalTime(10, 15, 8);
  expect(expectedForward, start.plusHours(2));
  expect(expectedBackward, start.plusHours(-2));
}

@Test()
void PlusHours_CrossingDayBoundary()
{
  LocalTime start = new LocalTime(12, 15, 8);
  LocalTime expected = new LocalTime(8, 15, 8);
  expect(expected, start.plusHours(20));
  expect(start, start.plusHours(20).plusHours(-20));
}

@Test()
void PlusHours_CrossingSeveralDaysBoundary()
{
  // Christmas day + 10 days and 1 hour
  LocalTime start = new LocalTime(12, 15, 8);
  LocalTime expected = new LocalTime(13, 15, 8);
  expect(expected, start.plusHours(241));
  expect(start, start.plusHours(241).plusHours(-241));
}

// Having tested that hours cross boundaries correctly, the other time unit
// tests are straightforward
@Test()
void PlusMinutes_Simple()
{
  LocalTime start = new LocalTime(12, 15, 8);
  LocalTime expectedForward = new LocalTime(12, 17, 8);
  LocalTime expectedBackward = new LocalTime(12, 13, 8);
  expect(expectedForward, start.plusMinutes(2));
  expect(expectedBackward, start.plusMinutes(-2));
}

@Test()
void PlusSeconds_Simple()
{
  LocalTime start = new LocalTime(12, 15, 8);
  LocalTime expectedForward = new LocalTime(12, 15, 18);
  LocalTime expectedBackward = new LocalTime(12, 14, 58);
  expect(expectedForward, start.plusSeconds(10));
  expect(expectedBackward, start.plusSeconds(-10));
}

@Test()
void PlusMilliseconds_Simple()
{
  LocalTime start = new LocalTime(12, 15, 8, 300);
  LocalTime expectedForward = new LocalTime(12, 15, 8, 700);
  LocalTime expectedBackward = new LocalTime(12, 15, 7, 900);
  expect(expectedForward, start.plusMilliseconds(400));
  expect(expectedBackward, start.plusMilliseconds(-400));
}

@Test()
void PlusTicks_Simple()
{
  LocalTime start = new LocalTime.fromHourMinuteSecondMillisecondTick(12, 15, 8, 300, 7500);
  LocalTime expectedForward = new LocalTime.fromHourMinuteSecondMillisecondTick(12, 15, 8, 301, 1500);
  LocalTime expectedBackward = new LocalTime.fromHourMinuteSecondMillisecondTick(12, 15, 8, 300, 3500);
  expect(expectedForward, start.plusTicks(4000));
  expect(expectedBackward, start.plusTicks(-4000));
}

@Test()
void PlusTicks_Long()
{
  expect(TimeConstants.ticksPerDay > Platform.int32MaxValue, isTrue);
  LocalTime start = new LocalTime(12, 15, 8);
  LocalTime expectedForward = new LocalTime(12, 15, 9);
  LocalTime expectedBackward = new LocalTime(12, 15, 7);
  expect(start.plusTicks(TimeConstants.ticksPerDay + TimeConstants.ticksPerSecond), expectedForward);
  expect(start.plusTicks(-TimeConstants.ticksPerDay - TimeConstants.ticksPerSecond),  expectedBackward);
}

@Test()
void With()
{
  LocalTime start = new LocalTime.fromHourMinuteSecondMillisecondTick(12, 15, 8, 100, 1234);
  LocalTime expected = new LocalTime(12, 15, 8);
  expect(expected, start.adjust(TimeAdjusters.truncateToSecond));
}

@Test()
void PlusMinutes_WouldOverflowNaively()
{
  LocalTime start = new LocalTime(12, 34, 56);
  // Very big value, which just wraps round a *lot* and adds one minute.
  // There's no way we could compute that many nanoseconds.
  // note: left-shifting on Web caps at 32 bit and doesn't work here, and the max-int-value is much lower
  int value = Platform.isVM ? (TimeConstants.nanosecondsPerDay << 15) + 1 : (TimeConstants.nanosecondsPerDay * 100) + 1;
  LocalTime expected = new LocalTime(12, 35, 56);
  LocalTime actual = start.plusMinutes(value);
  expect(actual, expected);
}

