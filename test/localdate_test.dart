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

/// Using the default constructor is equivalent to January 1st 1970, UTC, ISO calendar
@Test()
void DefaultConstructor()
{
  // todo: new LocalDate()
  var actual = LocalDate(1, 1, 1);
  expect(LocalDate(1, 1, 1), actual);
}

@Test()
void CombinationWithTime()
{
  // Test all three approaches in the same test - they're logically equivalent.
  var calendar = CalendarSystem.julian;
  LocalDate date = LocalDate(2014, 3, 28, calendar);
  LocalTime time = LocalTime(20, 17, 30);
  LocalDateTime expected = LocalDateTime(2014, 3, 28, 20, 17, 30, calendar: calendar);
  // expect(expected, date + time);
  expect(expected, date.at(time));
  expect(expected, time.atDate(date));
}

/* null is the default calendar argument (so we can have less constructors) and defaults to an iso calendar
@Test()
void Construction_NullCalendar_Throws()
{
  expect(() => new LocalDate(2017, 11, 7, null), throwsArgumentError, reason: 'Basic construction.');
  expect(() => new LocalDate.forEra(Era.common, 2017, 11, 7, null), throwsArgumentError, reason: 'Construction including era.');
}*/

@Test()
void MaxIsoValue()
{
  var value = LocalDate.maxIsoValue;
  expect(CalendarSystem.iso, value.calendar);
  expect(() => value.addDays(1), throwsRangeError);
}

@Test()
void MinIsoValue()
{
  var value = LocalDate.minIsoValue;
  expect(CalendarSystem.iso, value.calendar);
  expect(() => value.addDays(-1), throwsRangeError);
}
