// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

// Todo: all tests fail because Coptic is not yet implemented
final CalendarSystem CopticCalendar = CalendarSystem.Coptic;

// Tests using CopticCalendar as a simple example which doesn't override anything.
@Test() @SkipMe.unimplemented()
void GetAbsoluteYear()
{
  expect(5, CopticCalendar.GetAbsoluteYear(5, Era.AnnoMartyrum));
  // Prove it's right...
  LocalDate localDate = new LocalDate(5, 1, 1, CopticCalendar);
  expect(5, localDate.year);
  expect(5, localDate.yearOfEra);
  expect(Era.AnnoMartyrum, localDate.era);
}

@Test() @SkipMe.unimplemented()
void GetMinYearOfEra()
{
  expect(1, CopticCalendar.GetMinYearOfEra(Era.AnnoMartyrum));
}

@Test() @SkipMe.unimplemented()
void GetMaxYearOfEra()
{
  expect(CopticCalendar.maxYear, CopticCalendar.GetMaxYearOfEra(Era.AnnoMartyrum));
}


