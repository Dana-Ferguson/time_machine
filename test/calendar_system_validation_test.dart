// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

final CalendarSystem Iso = CalendarSystem.iso;

@Test()
@TestCase([-9998])
@TestCase([9999])
void GetMonthsInYear_Valid(int year)
{
  TestHelper.AssertValid<int, int>(Iso.getMonthsInYear, year);
}

@Test()
@TestCase([-9999])
@TestCase([10000])
void GetMonthsInYear_Invalid(int year)
{
  TestHelper.AssertOutOfRange<int, int>(Iso.getMonthsInYear, year);
}

@Test()
@TestCase([-9998, 1])
@TestCase([9999, 12])
void GetDaysInMonth_Valid(int year, int month)
{
  TestHelper.AssertValid2(Iso.getDaysInMonth, year, month);
}

@Test()
@TestCase([-9999, 1])
@TestCase([1, 0])
@TestCase([1, 13])
@TestCase([10000, 1])
void GetDaysInMonth_Invalid(int year, int month)
{
  TestHelper.AssertOutOfRange2<int, int, int>(Iso.getDaysInMonth, year, month);
}

@Test()
void GetDaysInMonth_Hebrew()
{
  TestHelper.AssertValid2<int, int, int>(CalendarSystem.hebrewCivil.getDaysInMonth, 5402, 13); // Leap year
  TestHelper.AssertOutOfRange2<int, int, int>(CalendarSystem.hebrewCivil.getDaysInMonth, 5401, 13); // Not a leap year
}

@Test()
@TestCase([-9998])
@TestCase([9999])
void IsLeapYear_Valid(int year)
{
  TestHelper.AssertValid<int, bool>(Iso.isLeapYear, year);
}

@Test()
@TestCase([-9999])
@TestCase([10000])
void IsLeapYear_Invalid(int year)
{
  TestHelper.AssertOutOfRange<int, bool>(Iso.isLeapYear, year);
}

@Test()
@TestCase([1])
@TestCase([9999])
void GetAbsoluteYear_ValidCe(int year)
{
  TestHelper.AssertValid2<int, Era, int>(Iso.getAbsoluteYear, year, Era.common);
}

@Test() 
@TestCase([1])
@TestCase([9999])
void GetAbsoluteYear_ValidBce(int year)
{
  TestHelper.AssertValid2<int, Era, int>(Iso.getAbsoluteYear, year, Era.beforeCommon);
}

@Test() 
@TestCase([0])
@TestCase([10000])
void GetAbsoluteYear_InvalidCe(int year)
{
  TestHelper.AssertOutOfRange2<int, Era, int>(Iso.getAbsoluteYear, year, Era.common);
}

@Test()
@TestCase([0])
@TestCase([10000])
void GetAbsoluteYear_InvalidBce(int year)
{
  TestHelper.AssertOutOfRange2<int, Era, int>(Iso.getAbsoluteYear, year, Era.beforeCommon);
}

@Test()
void GetAbsoluteYear_InvalidEra()
{
  TestHelper.AssertInvalid2<int, Era, int>(Iso.getAbsoluteYear, 1, Era.annoPersico);
}

// @Test()
// void GetAbsoluteYear_NullEra()
// {
//   Era i;
//   TestHelper.AssertArgumentNull2<int, Era, int>(Iso.getAbsoluteYear, 1, i);
// }

// @Test()
// void GetMinYearOfEra_NullEra()
// {
//   Era i;
//   TestHelper.AssertArgumentNull<Era, int>(Iso.getMinYearOfEra, i);
// }

@Test()
void GetMinYearOfEra_InvalidEra()
{
  TestHelper.AssertInvalid<Era, int>(Iso.getMinYearOfEra, Era.annoPersico);
}

// @Test()
// void GetMaxYearOfEra_NullEra()
// {
//   Era i;
//   TestHelper.AssertArgumentNull<Era, int>(Iso.getMaxYearOfEra, i);
// }

@Test()
void GetMaxYearOfEra_InvalidEra()
{
  TestHelper.AssertInvalid<Era, int>(Iso.getMaxYearOfEra, Era.annoPersico);
}
