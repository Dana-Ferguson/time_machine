// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

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
@TestCase(const [-1, 0])
@TestCase(const [24, 0])
@TestCase(const [0, -1])
@TestCase(const [0, 60])
void InvalidConstructionToMinute(int hour, int minute)
{
  expect(() => new LocalTime(hour, minute), throwsRangeError);
}

@Test()
@TestCase(const [-1, 0, 0])
@TestCase(const [24, 0, 0])
@TestCase(const [0, -1, 0])
@TestCase(const [0, 60, 0])
@TestCase(const [0, 0, 60])
@TestCase(const [0, 0, -1])
void InvalidConstructionToSecond(int hour, int minute, int second)
{
  expect(() => new LocalTime(hour, minute, second), throwsRangeError);
}

@Test()
@TestCase(const [-1, 0, 0, 0])
@TestCase(const [24, 0, 0, 0])
@TestCase(const [0, -1, 0, 0])
@TestCase(const [0, 60, 0, 0])
@TestCase(const [0, 0, 60, 0])
@TestCase(const [0, 0, -1, 0])
@TestCase(const [0, 0, 0, -1])
@TestCase(const [0, 0, 0, 1000])
void InvalidConstructionToMillisecond(int hour, int minute, int second, int millisecond)
{
  expect(() => new LocalTime(hour, minute, second, millisecond), throwsRangeError);
}

@Test()
@TestCase(const [-1, 0, 0, 0, 0])
@TestCase(const [24, 0, 0, 0, 0])
@TestCase(const [0, -1, 0, 0, 0])
@TestCase(const [0, 60, 0, 0, 0])
@TestCase(const [0, 0, 60, 0, 0])
@TestCase(const [0, 0, -1, 0, 0])
@TestCase(const [0, 0, 0, -1, 0])
@TestCase(const [0, 0, 0, 1000, 0])
@TestCase(const [0, 0, 0, 0, -1])
@TestCase(const [0, 0, 0, 0, TimeConstants.ticksPerMillisecond])
void FromHourMinuteSecondMillisecondTick_Invalid(int hour, int minute, int second, int millisecond, int tick)
{
  expect(() => new LocalTime.fromHourMinuteSecondMillisecondTick(hour, minute, second, millisecond, tick), throwsRangeError);
}

@Test()
@TestCase(const [-1, 0, 0, 0])
@TestCase(const [24, 0, 0, 0])
@TestCase(const [0, -1, 0, 0])
@TestCase(const [0, 60, 0, 0])
@TestCase(const [0, 0, 60, 0])
@TestCase(const [0, 0, -1, 0])
@TestCase(const [0, 0, 0, -1])
@TestCase(const [0, 0, 0, TimeConstants.ticksPerSecond])
void FromHourMinuteSecondTick_Invalid(int hour, int minute, int second, int tick)
{
  expect(() => new LocalTime.fromHourMinuteSecondTick(hour, minute, second, tick), throwsRangeError);
}

@Test()
void FromHourMinuteSecondTick_Valid()
{
  var result = new LocalTime.fromHourMinuteSecondTick(1, 2, 3, (TimeConstants.ticksPerSecond - 1));
  expect(1, result.hour);
  expect(2, result.minute);
  expect(3, result.second);
  expect((TimeConstants.ticksPerSecond - 1), result.tickOfSecond);
}

@Test()
@TestCase(const [-1, 0, 0, 0])
@TestCase(const [24, 0, 0, 0])
@TestCase(const [0, -1, 0, 0])
@TestCase(const [0, 60, 0, 0])
@TestCase(const [0, 0, 60, 0])
@TestCase(const [0, 0, -1, 0])
@TestCase(const [0, 0, 0, -1])
@TestCase(const [0, 0, 0, TimeConstants.nanosecondsPerSecond])
void FromHourMinuteSecondNanosecond_Invalid(int hour, int minute, int second, int nanosecond)
{
  expect(() => new LocalTime.fromHourMinuteSecondNanosecond(hour, minute, second, nanosecond), throwsRangeError);
}

@Test()
void FromNanosecondsSinceMidnight_Valid()
{
  expect(LocalTime.midnight, ILocalTime.fromNanosecondsSinceMidnight(0));
  expect(LocalTime.midnight.plusNanoseconds(-1), ILocalTime.fromNanosecondsSinceMidnight(TimeConstants.nanosecondsPerDay - 1));
}

@Test()
void FromNanosecondsSinceMidnight_RangeChecks()
{
  expect(() => ILocalTime.fromNanosecondsSinceMidnight(-1), throwsRangeError);
  expect(() => ILocalTime.fromNanosecondsSinceMidnight(TimeConstants.nanosecondsPerDay), throwsRangeError);
}

@Test()
void FromTicksSinceMidnight_Valid()
{
  expect(LocalTime.midnight, new LocalTime.fromTicksSinceMidnight(0));
  expect(LocalTime.midnight - new Period.fromTicks(1), new LocalTime.fromTicksSinceMidnight(TimeConstants.ticksPerDay - 1));
}

@Test()
void FromTicksSinceMidnight_RangeChecks()
{
  expect(() => new LocalTime.fromTicksSinceMidnight(-1), throwsRangeError);
  expect(() => new LocalTime.fromTicksSinceMidnight(TimeConstants.ticksPerDay), throwsRangeError);
}

@Test()
void FromMillisecondsSinceMidnight_Valid()
{
  expect(LocalTime.midnight, new LocalTime.fromMillisecondsSinceMidnight(0));
  expect(LocalTime.midnight - new Period.fromMilliseconds(1), new LocalTime.fromMillisecondsSinceMidnight(TimeConstants.millisecondsPerDay - 1));
}

@Test()
void FromMillisecondsSinceMidnight_RangeChecks()
{
  expect(() => new LocalTime.fromMillisecondsSinceMidnight(-1), throwsRangeError);
  expect(() => new LocalTime.fromMillisecondsSinceMidnight(TimeConstants.millisecondsPerDay), throwsRangeError);
}

@Test()
void FromSecondsSinceMidnight_Valid()
{
  expect(LocalTime.midnight, new LocalTime.fromSecondsSinceMidnight(0));
  expect(LocalTime.midnight - new Period.fromSeconds(1), new LocalTime.fromSecondsSinceMidnight(TimeConstants.secondsPerDay - 1));
}

@Test()
void FromSecondsSinceMidnight_RangeChecks()
{
  expect(() => new LocalTime.fromSecondsSinceMidnight(-1), throwsRangeError);
  expect(() => new LocalTime.fromSecondsSinceMidnight(TimeConstants.secondsPerDay), throwsRangeError);
}


