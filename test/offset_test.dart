// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/OffsetTest.cs
// 74067a7  12 days ago

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
void Max()
{
  Offset x = new Offset.fromSeconds(100);
  Offset y = new Offset.fromSeconds(200);
  expect(y, Offset.max(x, y));
  expect(y, Offset.max(y, x));
  expect(x, Offset.max(x, Offset.minValue));
  expect(x, Offset.max(Offset.minValue, x));
  expect(Offset.maxValue, Offset.max(Offset.maxValue, x));
  expect(Offset.maxValue, Offset.max(x, Offset.maxValue));
}

@Test()
void Min()
{
  Offset x = new Offset.fromSeconds(100);
  Offset y = new Offset.fromSeconds(200);
  expect(x, Offset.min(x, y));
  expect(x, Offset.min(y, x));
  expect(Offset.minValue, Offset.min(x, Offset.minValue));
  expect(Offset.minValue, Offset.min(Offset.minValue, x));
  expect(x, Offset.min(Offset.maxValue, x));
  expect(x, Offset.min(x, Offset.maxValue));
}

/* todo: redo for dart:core Duration
@Test()
void ToTimeSpan()
{
  TimeSpan ts = new Offset.fromSeconds(1234).ToTimeSpan();
  expect(ts, TimeSpan.FromSeconds(1234));
}

@Test()
void FromTimeSpan_OutOfRange([Values(-24, 24)] int hours)
{
TimeSpan ts = TimeSpan.FromHours(hours);
expect(() => Offset.FromTimeSpan(ts), throwsRangeError);
}

@Test()
void FromTimeSpan_Truncation()
{
  TimeSpan ts = TimeSpan.FromMilliseconds(1000 + 200);
  expect(new Offset.fromSeconds(1), Offset.FromTimeSpan(ts));
}

@Test()
void FromTimeSpan_Simple()
{
  TimeSpan ts = TimeSpan.FromHours(2);
  expect(Offset.FromHours(2), Offset.FromTimeSpan(ts));
}*/

/// <summary>
///   Using the default constructor is equivalent to Offset.Zero
/// </summary>
@Test()
void DefaultConstructor()
{
  var actual = new Offset();
  expect(Offset.zero, actual);
}
