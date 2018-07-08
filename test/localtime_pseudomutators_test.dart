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
  LocalTime start = new LocalTime(12, 15, 8, ms: 300);
  LocalTime expectedForward = new LocalTime(12, 15, 8, ms: 700);
  LocalTime expectedBackward = new LocalTime(12, 15, 7, ms: 900);
  expect(expectedForward, start.plusMilliseconds(400));
  expect(expectedBackward, start.plusMilliseconds(-400));
}

@Test()
void PlusMicroseconds_Simple()
{
  LocalTime start = new LocalTime(12, 15, 8, us: 300750);
  LocalTime expectedForward = new LocalTime(12, 15, 8, us: 301150);
  LocalTime expectedBackward = new LocalTime(12, 15, 8, us: 300350);
  expect(expectedForward, start.plusMicroseconds(400));
  expect(expectedBackward, start.plusMicroseconds(-400));
}

@Test()
void PlusTicks_Long()
{
  expect(TimeConstants.microsecondsPerDay > Platform.int32MaxValue, isTrue);
  LocalTime start = new LocalTime(12, 15, 8);
  LocalTime expectedForward = new LocalTime(12, 15, 9);
  LocalTime expectedBackward = new LocalTime(12, 15, 7);
  expect(start.plusMicroseconds(TimeConstants.microsecondsPerDay + TimeConstants.microsecondsPerSecond), expectedForward);
  expect(start.plusMicroseconds(-TimeConstants.microsecondsPerDay - TimeConstants.microsecondsPerSecond),  expectedBackward);
}

@Test()
void With()
{
  LocalTime start = new LocalTime(12, 15, 8, ns: 100 * TimeConstants.nanosecondsPerMillisecond + 1234 * 100);
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

