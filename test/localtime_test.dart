// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
//import 'package:matcher/matcher.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

@Test()
void MinValueEqualToMidnight()
{
  expect(LocalTime.midnight, LocalTime.minValue);
}

@Test()
void MaxValue()
{
  expect(TimeConstants.nanosecondsPerDay - 1, LocalTime.maxValue.timeSinceMidnight.inNanoseconds);
}

@Test()
void ClockHourOfHalfDay()
{
  expect(12, LocalTime(0, 0, 0).hourOf12HourClock);
  expect(1, LocalTime(1, 0, 0).hourOf12HourClock);
  expect(12, LocalTime(12, 0, 0).hourOf12HourClock);
  expect(1, LocalTime(13, 0, 0).hourOf12HourClock);
  expect(11, LocalTime(23, 0, 0).hourOf12HourClock);
}

///   Using the default constructor is equivalent to midnight
@Test()
void DefaultConstructor()
{
  // todo: new LocalTime();
  var actual = LocalTime(0, 0, 0);
  expect(LocalTime.midnight, actual);
}

@Test()
void Max()
{
  LocalTime x = LocalTime(5, 10, 0);
  LocalTime y = LocalTime(6, 20, 0);
  expect(y, LocalTime.max(x, y));
  expect(y, LocalTime.max(y, x));
  expect(x, LocalTime.max(x, LocalTime.minValue));
  expect(x, LocalTime.max(LocalTime.minValue, x));
  expect(LocalTime.maxValue, LocalTime.max(LocalTime.maxValue, x));
  expect(LocalTime.maxValue, LocalTime.max(x, LocalTime.maxValue));
}

@Test()
void Min()
{
  LocalTime x = LocalTime(5, 10, 0);
  LocalTime y = LocalTime(6, 20, 0);
  expect(x, LocalTime.min(x, y));
  expect(x, LocalTime.min(y, x));
  expect(LocalTime.minValue, LocalTime.min(x, LocalTime.minValue));
  expect(LocalTime.minValue, LocalTime.min(LocalTime.minValue, x));
  expect(x, LocalTime.min(LocalTime.maxValue, x));
  expect(x, LocalTime.min(x, LocalTime.maxValue));
}

@Test()
void WithOffset()
{
  var time = LocalTime(3, 45, 12, ms: 34);
  var offset = Offset.hours(5);
  var expected = OffsetTime(time, offset);
  expect(expected, time.withOffset(offset));
}

