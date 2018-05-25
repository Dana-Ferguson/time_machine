// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/Calendars/JulianCalendarSystemTest.era.cs
// 7208243  on Mar 18, 2015


import 'dart:async';
import 'dart:math' as math;

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import '../time_machine_testing.dart';

Future main() async {
  await runTests();
}

CalendarSystem Julian = CalendarSystem.Julian;

@Test()
void GetMaxYearOfEra()
{
  LocalDate date = new LocalDate.forCalendar(Julian.maxYear, 1, 1, Julian);
  expect(date.YearOfEra, Julian.GetMaxYearOfEra(Era.Common));
  expect(Era.Common, date.era);
  date = new LocalDate.forCalendar(Julian.minYear, 1, 1, Julian);
  expect(Julian.minYear, date.Year);
  expect(date.YearOfEra, Julian.GetMaxYearOfEra(Era.BeforeCommon));
  expect(Era.BeforeCommon, date.era);
}

@Test()
void GetMinYearOfEra()
{
  LocalDate date = new LocalDate.forCalendar(1, 1, 1, Julian);
  expect(date.YearOfEra, Julian.GetMinYearOfEra(Era.Common));
  expect(Era.Common, date.era);
  date = new LocalDate.forCalendar(0, 1, 1, Julian);
  expect(date.YearOfEra, Julian.GetMinYearOfEra(Era.BeforeCommon));
  expect(Era.BeforeCommon, date.era);
}

@Test()
void GetAbsoluteYear()
{
  expect(1, Julian.GetAbsoluteYear(1, Era.Common));
  expect(0, Julian.GetAbsoluteYear(1, Era.BeforeCommon));
  expect(-1, Julian.GetAbsoluteYear(2, Era.BeforeCommon));
  expect(Julian.maxYear, Julian.GetAbsoluteYear(Julian.GetMaxYearOfEra(Era.Common), Era.Common));
  expect(Julian.minYear, Julian.GetAbsoluteYear(Julian.GetMaxYearOfEra(Era.BeforeCommon), Era.BeforeCommon));
}

@Test()
void EraProperty()
{
  CalendarSystem calendar = CalendarSystem.Julian;
  LocalDateTime startOfEra = new LocalDateTime.fromYMDHMSC(1, 1, 1, 0, 0, 0, calendar);
  expect(Era.Common, startOfEra.era);
  expect(Era.BeforeCommon, startOfEra.PlusTicks(-1).era);
}
