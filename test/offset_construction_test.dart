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

@Test()
void Zero()
{
  Offset test = Offset.zero;
  expect(0, test.milliseconds);
}

@Test()
void FromSeconds_Valid()
{
  var test = new Offset.fromSeconds(12345);
  expect(12345, test.seconds);
}

@Test()
void FromSeconds_Invalid()
{
  int seconds = 18 * TimeConstants.secondsPerHour + 1;
  expect(() => new Offset.fromSeconds(seconds), throwsRangeError);
  expect(() => new Offset.fromSeconds(-seconds), throwsRangeError);
}

@Test()
void FromMilliseconds_Valid()
{
  Offset value = new Offset.fromMilliseconds(-15 * TimeConstants.millisecondsPerMinute);
  expect(-15 * TimeConstants.secondsPerMinute, value.seconds);
  expect(-15 * TimeConstants.millisecondsPerMinute, value.milliseconds);
}

@Test()
void FromMilliseconds_Invalid()
{
  int millis = 18 * TimeConstants.millisecondsPerHour + 1;
  expect(() => new Offset.fromMilliseconds(millis), throwsRangeError);
  expect(() => new Offset.fromMilliseconds(-millis), throwsRangeError);
}

@Test()
void FromTicks_Valid()
{
  Offset value = new Offset.fromTicks(-15 * TimeConstants.ticksPerMinute);
  expect(-15 * TimeConstants.secondsPerMinute, value.seconds);
  expect(-15 * TimeConstants.ticksPerMinute, value.ticks);
}

@Test()
void FromTicks_Invalid()
{
  int ticks = 18 * TimeConstants.ticksPerHour + 1;
  expect(() => new Offset.fromTicks(ticks), throwsRangeError);
  expect(() => new Offset.fromTicks(-ticks), throwsRangeError);
}

@Test()
void FromNanoseconds_Valid()
{
  Offset value = new Offset.fromNanoseconds(-15 * TimeConstants.nanosecondsPerMinute);
  expect(-15 * TimeConstants.secondsPerMinute, value.seconds);
  expect(-15 * TimeConstants.nanosecondsPerMinute, value.nanoseconds);
}

@Test()
void FromNanoseconds_Invalid()
{
  int nanos = 18 * TimeConstants.nanosecondsPerHour + 1;
  expect(() => new Offset.fromNanoseconds(nanos), throwsRangeError);
  expect(() => new Offset.fromNanoseconds(-nanos), throwsRangeError);
}

@Test()
void FromHours_Valid()
{
  Offset value = new Offset.fromHours(-15);
  expect(-15 * TimeConstants.secondsPerHour, value.seconds);
}

@Test()
void FromHours_Invalid()
{
  expect(() => new Offset.fromHours(19), throwsRangeError);
  expect(() => new Offset.fromHours(-19), throwsRangeError);
}

@Test()
void FromHoursAndMinutes_Valid()
{
  Offset value = new Offset.fromHoursAndMinutes(5, 30);
  expect(5 * TimeConstants.secondsPerHour + 30 * TimeConstants.secondsPerMinute, value.seconds);
}


