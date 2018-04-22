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
@Test()
void GetAbsoluteYear()
{
  expect(5, CopticCalendar.GetAbsoluteYear(5, Era.AnnoMartyrum));
  // Prove it's right...
  LocalDate localDate = new LocalDate.forCalendar(5, 1, 1, CopticCalendar);
  expect(5, localDate.Year);
  expect(5, localDate.YearOfEra);
  expect(Era.AnnoMartyrum, localDate.era);
}

@Test()
void GetMinYearOfEra()
{
  expect(1, CopticCalendar.GetMinYearOfEra(Era.AnnoMartyrum));
}

@Test()
void GetMaxYearOfEra()
{
  expect(CopticCalendar.maxYear, CopticCalendar.GetMaxYearOfEra(Era.AnnoMartyrum));
}

