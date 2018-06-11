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

CalendarSystem Iso = CalendarSystem.Iso;

@Test()
void GetMaxYearOfEra()
{
  LocalDate date = new LocalDate(Iso.maxYear, 1, 1);
  expect(date.yearOfEra, Iso.GetMaxYearOfEra(Era.Common));
  expect(Era.Common, date.era);
  date = new LocalDate(Iso.minYear, 1, 1);
  expect(Iso.minYear, date.year);
  expect(date.yearOfEra, Iso.GetMaxYearOfEra(Era.BeforeCommon));
  expect(Era.BeforeCommon, date.era);
}

@Test()
void GetMinYearOfEra()
{
  LocalDate date = new LocalDate(1, 1, 1);
  expect(date.yearOfEra, Iso.GetMinYearOfEra(Era.Common));
  expect(Era.Common, date.era);
  date = new LocalDate(0, 1, 1);
  expect(date.yearOfEra, Iso.GetMinYearOfEra(Era.BeforeCommon));
  expect(Era.BeforeCommon, date.era);
}

@Test()
void GetAbsoluteYear()
{
  expect(1, Iso.GetAbsoluteYear(1, Era.Common));
  expect(0, Iso.GetAbsoluteYear(1, Era.BeforeCommon));
  expect(-1, Iso.GetAbsoluteYear(2, Era.BeforeCommon));
  expect(Iso.maxYear, Iso.GetAbsoluteYear(Iso.GetMaxYearOfEra(Era.Common), Era.Common));
  expect(Iso.minYear, Iso.GetAbsoluteYear(Iso.GetMaxYearOfEra(Era.BeforeCommon), Era.BeforeCommon));
}

