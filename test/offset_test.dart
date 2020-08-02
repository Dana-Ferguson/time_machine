// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
// import 'package:matcher/matcher.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

@Test()
void Max()
{
  Offset x = Offset(100);
  Offset y = Offset(200);
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
  Offset x = Offset(100);
  Offset y = Offset(200);
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

///   Using the default constructor is equivalent to Offset.Zero
@Test()
void DefaultConstructor()
{
  var actual = Offset();
  expect(Offset.zero, actual);
}

