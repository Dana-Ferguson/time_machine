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

// Todo: all tests fail because Coptic is not yet implemented
final CalendarSystem CopticCalendar = CalendarSystem.coptic;

// Tests using CopticCalendar as a simple example which doesn't override anything.
@Test()
void GetAbsoluteYear()
{
  expect(5, CopticCalendar.getAbsoluteYear(5, Era.annoMartyrum));
  // Prove it's right...
  LocalDate localDate = LocalDate(5, 1, 1, CopticCalendar);
  expect(5, localDate.year);
  expect(5, localDate.yearOfEra);
  expect(Era.annoMartyrum, localDate.era);
}

@Test()
void GetMinYearOfEra()
{
  expect(1, CopticCalendar.getMinYearOfEra(Era.annoMartyrum));
}

@Test()
void GetMaxYearOfEra()
{
  expect(CopticCalendar.maxYear, CopticCalendar.getMaxYearOfEra(Era.annoMartyrum));
}


