// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/LocalTimeTest.cs
// ead2fb4  on Nov 11, 2017

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
void MinValueEqualToMidnight()
{
  expect(LocalTime.Midnight, LocalTime.MinValue);
}

@Test()
void MaxValue()
{
  expect(TimeConstants.nanosecondsPerDay - 1, LocalTime.MaxValue.NanosecondOfDay);
}

@Test()
void ClockHourOfHalfDay()
{
  expect(12, new LocalTime(0, 0).ClockHourOfHalfDay);
  expect(1, new LocalTime(1, 0).ClockHourOfHalfDay);
  expect(12, new LocalTime(12, 0).ClockHourOfHalfDay);
  expect(1, new LocalTime(13, 0).ClockHourOfHalfDay);
  expect(11, new LocalTime(23, 0).ClockHourOfHalfDay);
}

/// <summary>
///   Using the default constructor is equivalent to midnight
/// </summary>
@Test()
void DefaultConstructor()
{
  // todo: new LocalTime();
  var actual = new LocalTime(0, 0);
  expect(LocalTime.Midnight, actual);
}

@Test()
void Max()
{
  LocalTime x = new LocalTime(5, 10);
  LocalTime y = new LocalTime(6, 20);
  expect(y, LocalTime.Max(x, y));
  expect(y, LocalTime.Max(y, x));
  expect(x, LocalTime.Max(x, LocalTime.MinValue));
  expect(x, LocalTime.Max(LocalTime.MinValue, x));
  expect(LocalTime.MaxValue, LocalTime.Max(LocalTime.MaxValue, x));
  expect(LocalTime.MaxValue, LocalTime.Max(x, LocalTime.MaxValue));
}

@Test()
void Min()
{
  LocalTime x = new LocalTime(5, 10);
  LocalTime y = new LocalTime(6, 20);
  expect(x, LocalTime.Min(x, y));
  expect(x, LocalTime.Min(y, x));
  expect(LocalTime.MinValue, LocalTime.Min(x, LocalTime.MinValue));
  expect(LocalTime.MinValue, LocalTime.Min(LocalTime.MinValue, x));
  expect(x, LocalTime.Min(LocalTime.MaxValue, x));
  expect(x, LocalTime.Min(x, LocalTime.MaxValue));
}

@Test()
void WithOffset()
{
  var time = new LocalTime(3, 45, 12, 34);
  var offset = new Offset.fromHours(5);
  var expected = new OffsetTime(time, offset);
  expect(expected, time.WithOffset(offset));
}
