// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.


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

CalendarSystem Julian = CalendarSystem.julian;

@Test()
void GetMaxYearOfEra()
{
  LocalDate date = new LocalDate(Julian.maxYear, 1, 1, Julian);
  expect(date.yearOfEra, Julian.getMaxYearOfEra(Era.Common));
  expect(Era.Common, date.era);
  date = new LocalDate(Julian.minYear, 1, 1, Julian);
  expect(Julian.minYear, date.year);
  expect(date.yearOfEra, Julian.getMaxYearOfEra(Era.BeforeCommon));
  expect(Era.BeforeCommon, date.era);
}

@Test()
void GetMinYearOfEra()
{
  LocalDate date = new LocalDate(1, 1, 1, Julian);
  expect(date.yearOfEra, Julian.getMinYearOfEra(Era.Common));
  expect(Era.Common, date.era);
  date = new LocalDate(0, 1, 1, Julian);
  expect(date.yearOfEra, Julian.getMinYearOfEra(Era.BeforeCommon));
  expect(Era.BeforeCommon, date.era);
}

@Test()
void GetAbsoluteYear()
{
  expect(1, Julian.getAbsoluteYear(1, Era.Common));
  expect(0, Julian.getAbsoluteYear(1, Era.BeforeCommon));
  expect(-1, Julian.getAbsoluteYear(2, Era.BeforeCommon));
  expect(Julian.maxYear, Julian.getAbsoluteYear(Julian.getMaxYearOfEra(Era.Common), Era.Common));
  expect(Julian.minYear, Julian.getAbsoluteYear(Julian.getMaxYearOfEra(Era.BeforeCommon), Era.BeforeCommon));
}

@Test()
void EraProperty()
{
  CalendarSystem calendar = CalendarSystem.julian;
  LocalDateTime startOfEra = new LocalDateTime.at(1, 1, 1, 0, 0, calendar: calendar);
  expect(Era.Common, startOfEra.era);
  expect(Era.BeforeCommon, startOfEra.plusTicks(-1).era);
}

