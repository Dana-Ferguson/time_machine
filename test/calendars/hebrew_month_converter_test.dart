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
@TestCase([1, 7]) // Nisan
@TestCase([2, 8]) // Iyyar
@TestCase([3, 9]) // Sivan
@TestCase([4, 10]) // Tammuz
@TestCase([5, 11]) // Av
@TestCase([6, 12]) // Elul
@TestCase([7, 1]) // Tishri
@TestCase([8, 2]) // Heshvan
@TestCase([9, 3]) // Kislev
@TestCase([10, 4]) // Teveth
@TestCase([11, 5]) // Shevat
@TestCase([12, 6]) // Adar
void NonLeapYear(int scriptural, int civil)
{
  expect(scriptural, HebrewMonthConverter.civilToScriptural(SampleNonLeapYear, civil));
  expect(civil, HebrewMonthConverter.scripturalToCivil(SampleNonLeapYear, scriptural));
}

@Test()
@TestCase([1, 8]) // Nisan
@TestCase([2, 9]) // Iyyar
@TestCase([3, 10]) // Sivan
@TestCase([4, 11]) // Tammuz
@TestCase([5, 12]) // Av
@TestCase([6, 13]) // Elul
@TestCase([7, 1]) // Tishri
@TestCase([8, 2]) // Heshvan
@TestCase([9, 3]) // Kislev
@TestCase([10, 4]) // Teveth
@TestCase([11, 5]) // Shevat
@TestCase([12, 6]) // Adar I
@TestCase([13, 7]) // Adar II
void LeapYear(int scriptural, int civil)
{
  expect(scriptural, HebrewMonthConverter.civilToScriptural(SampleLeapYear, civil));
  expect(civil, HebrewMonthConverter.scripturalToCivil(SampleLeapYear, scriptural));
}
