// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:test/test.dart';

import '../time_machine_testing.dart';

Future main() async {
  await runTests();
}

CalendarSystem Iso = CalendarSystem.iso;

// These tests assume that if the method doesn't throw, it's doing the right thing - this
// is all tested elsewhere.
@Test()
void ValidateYearMonthDay_AllValues_ValidValuesDoesntThrow()
{
  ICalendarSystem.validateYearMonthDay(Iso, 20, 2, 20);
}

@Test()
void ValidateYearMonthDay_InvalidYear_Throws()
{
  expect(() => ICalendarSystem.validateYearMonthDay(Iso, 50000, 2, 20), throwsRangeError);
}

@Test()
void GetLocalInstant_InvalidMonth_Throws()
{
  expect(() => ICalendarSystem.validateYearMonthDay(Iso, 2010, 13, 20), throwsRangeError);
}

@Test()
void GetLocalInstant_29thOfFebruaryInNonLeapYear_Throws()
{
  expect(() => ICalendarSystem.validateYearMonthDay(Iso, 2010, 2, 29), throwsRangeError);
}

@Test()
void GetLocalInstant_29thOfFebruaryInLeapYear_DoesntThrow()
{
  ICalendarSystem.validateYearMonthDay(Iso, 2012, 2, 29);
}

