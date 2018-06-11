// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

final CalendarSystem Iso = CalendarSystem.iso;

@Test()
@TestCase(const [-9998])
@TestCase(const [9999])
void GetMonthsInYear_Valid(int year)
{
  TestHelper.AssertValid(Iso.getMonthsInYear, year);
}

@Test()
@TestCase(const [-9999])
@TestCase(const [10000])
void GetMonthsInYear_Invalid(int year)
{
  TestHelper.AssertOutOfRange(Iso.getMonthsInYear, year);
}

@Test()
@TestCase(const [-9998, 1])
@TestCase(const [9999, 12])
void GetDaysInMonth_Valid(int year, int month)
{
  TestHelper.AssertValid2(Iso.getDaysInMonth, year, month);
}

@Test()
@TestCase(const [-9999, 1])
@TestCase(const [1, 0])
@TestCase(const [1, 13])
@TestCase(const [10000, 1])
void GetDaysInMonth_Invalid(int year, int month)
{
  TestHelper.AssertOutOfRange2(Iso.getDaysInMonth, year, month);
}

@Test() @SkipMe.unimplemented()
void GetDaysInMonth_Hebrew()
{
  TestHelper.AssertValid2(CalendarSystem.hebrewCivil.getDaysInMonth, 5402, 13); // Leap year
  TestHelper.AssertOutOfRange2(CalendarSystem.hebrewCivil.getDaysInMonth, 5401, 13); // Not a leap year
}

@Test()
@TestCase(const [-9998])
@TestCase(const [9999])
void IsLeapYear_Valid(int year)
{
  TestHelper.AssertValid(Iso.isLeapYear, year);
}

@Test()
@TestCase(const [-9999])
@TestCase(const [10000])
void IsLeapYear_Invalid(int year)
{
  TestHelper.AssertOutOfRange(Iso.isLeapYear, year);
}

@Test()
@TestCase(const [1])
@TestCase(const [9999])
void GetAbsoluteYear_ValidCe(int year)
{
  TestHelper.AssertValid2(Iso.getAbsoluteYear, year, Era.Common);
}

@Test() 
@TestCase(const [1])
@TestCase(const [9999])
void GetAbsoluteYear_ValidBce(int year)
{
  TestHelper.AssertValid2(Iso.getAbsoluteYear, year, Era.BeforeCommon);
}

@Test() 
@TestCase(const [0])
@TestCase(const [10000])
void GetAbsoluteYear_InvalidCe(int year)
{
  TestHelper.AssertOutOfRange2(Iso.getAbsoluteYear, year, Era.Common);
}

@Test()
@TestCase(const [0])
@TestCase(const [10000])
void GetAbsoluteYear_InvalidBce(int year)
{
  TestHelper.AssertOutOfRange2(Iso.getAbsoluteYear, year, Era.BeforeCommon);
}

@Test()
void GetAbsoluteYear_InvalidEra()
{
  TestHelper.AssertInvalid2(Iso.getAbsoluteYear, 1, Era.AnnoPersico);
}

@Test()
void GetAbsoluteYear_NullEra()
{
  Era i = null;
  TestHelper.AssertArgumentNull2(Iso.getAbsoluteYear, 1, i);
}

@Test()
void GetMinYearOfEra_NullEra()
{
  Era i = null;
  TestHelper.AssertArgumentNull(Iso.getMinYearOfEra, i);
}

@Test()
void GetMinYearOfEra_InvalidEra()
{
  TestHelper.AssertInvalid(Iso.getMinYearOfEra, Era.AnnoPersico);
}

@Test()
void GetMaxYearOfEra_NullEra()
{
  Era i = null;
  TestHelper.AssertArgumentNull(Iso.getMaxYearOfEra, i);
}

@Test()
void GetMaxYearOfEra_InvalidEra()
{
  TestHelper.AssertInvalid(Iso.getMaxYearOfEra, Era.AnnoPersico);
}
