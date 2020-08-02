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

@Test()
void GetMaxYearOfEra()
{
  LocalDate date = LocalDate(Iso.maxYear, 1, 1);
  expect(date.yearOfEra, Iso.getMaxYearOfEra(Era.common));
  expect(Era.common, date.era);
  date = LocalDate(Iso.minYear, 1, 1);
  expect(Iso.minYear, date.year);
  expect(date.yearOfEra, Iso.getMaxYearOfEra(Era.beforeCommon));
  expect(Era.beforeCommon, date.era);
}

@Test()
void GetMinYearOfEra()
{
  LocalDate date = LocalDate(1, 1, 1);
  expect(date.yearOfEra, Iso.getMinYearOfEra(Era.common));
  expect(Era.common, date.era);
  date = LocalDate(0, 1, 1);
  expect(date.yearOfEra, Iso.getMinYearOfEra(Era.beforeCommon));
  expect(Era.beforeCommon, date.era);
}

@Test()
void GetAbsoluteYear()
{
  expect(1, Iso.getAbsoluteYear(1, Era.common));
  expect(0, Iso.getAbsoluteYear(1, Era.beforeCommon));
  expect(-1, Iso.getAbsoluteYear(2, Era.beforeCommon));
  expect(Iso.maxYear, Iso.getAbsoluteYear(Iso.getMaxYearOfEra(Era.common), Era.common));
  expect(Iso.minYear, Iso.getAbsoluteYear(Iso.getMaxYearOfEra(Era.beforeCommon), Era.beforeCommon));
}

