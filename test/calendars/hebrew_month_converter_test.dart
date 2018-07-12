// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
// import 'package:matcher/matcher.dart';

import '../time_machine_testing.dart';

Future main() async {
  await runTests();
}

const int SampleLeapYear = 5502;
const int SampleNonLeapYear = 5501;

@Test()
@TestCase(const [1, 7]) // Nisan
@TestCase(const [2, 8]) // Iyyar
@TestCase(const [3, 9]) // Sivan
@TestCase(const [4, 10]) // Tammuz
@TestCase(const [5, 11]) // Av
@TestCase(const [6, 12]) // Elul
@TestCase(const [7, 1]) // Tishri
@TestCase(const [8, 2]) // Heshvan
@TestCase(const [9, 3]) // Kislev
@TestCase(const [10, 4]) // Teveth
@TestCase(const [11, 5]) // Shevat
@TestCase(const [12, 6]) // Adar
void NonLeapYear(int scriptural, int civil)
{
  expect(scriptural, HebrewMonthConverter.civilToScriptural(SampleNonLeapYear, civil));
  expect(civil, HebrewMonthConverter.scripturalToCivil(SampleNonLeapYear, scriptural));
}

@Test()
@TestCase(const [1, 8]) // Nisan
@TestCase(const [2, 9]) // Iyyar
@TestCase(const [3, 10]) // Sivan
@TestCase(const [4, 11]) // Tammuz
@TestCase(const [5, 12]) // Av
@TestCase(const [6, 13]) // Elul
@TestCase(const [7, 1]) // Tishri
@TestCase(const [8, 2]) // Heshvan
@TestCase(const [9, 3]) // Kislev
@TestCase(const [10, 4]) // Teveth
@TestCase(const [11, 5]) // Shevat
@TestCase(const [12, 6]) // Adar I
@TestCase(const [13, 7]) // Adar II
void LeapYear(int scriptural, int civil)
{
  expect(scriptural, HebrewMonthConverter.civilToScriptural(SampleLeapYear, civil));
  expect(civil, HebrewMonthConverter.scripturalToCivil(SampleLeapYear, scriptural));
}
