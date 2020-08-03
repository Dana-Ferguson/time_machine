// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
// import 'package:matcher/matcher.dart';

import '../time_machine_testing.dart';

/// Tests for PersianYearMonthDayCalculator via the Persian CalendarSystem.
Future main() async {
  await runTests();
}

@Test() @SkipMe('Unsure how to implement')
// [Category('Slow')]
void BclThroughHistory()
{
  // Calendar bcl = BclCalendars.Persian;
  // CalendarSystem noda = BclCalendars.CalendarSystemForCalendar(bcl);
  // Note: Noda Time stops in 9377, whereas the BCL goes into the start of 9378. This is because
  // Noda Time ensures that the whole year is valid.
  // BclEquivalenceHelper.AssertEquivalent(bcl, noda);
}

/// <summary>
/// Use the examples in Calendrical Calculations for where the arithmetic calendar differs
/// from the astronomical one.
/// </summary>
@Test()
@TestCase(const [1016, 1637, 21])
@TestCase(const [1049, 1670, 21])
@TestCase(const [1078, 1699, 21])
@TestCase(const [1082, 1703, 22])
@TestCase(const [1111, 1732, 21])
@TestCase(const [1115, 1736, 21])
@TestCase(const [1144, 1765, 21])
@TestCase(const [1177, 1798, 21])
@TestCase(const [1210, 1831, 22])
@TestCase(const [1243, 1864, 21])
@TestCase(const [1404, 2025, 20])
@TestCase(const [1437, 2058, 20])
@TestCase(const [1532, 2153, 20])
@TestCase(const [1565, 2186, 20])
@TestCase(const [1569, 2190, 20])
@TestCase(const [1598, 2219, 21])
@TestCase(const [1631, 2252, 20])
@TestCase(const [1660, 2281, 20])
@TestCase(const [1664, 2285, 20])
@TestCase(const [1693, 2314, 21])
@TestCase(const [1697, 2318, 21])
@TestCase(const [1726, 2347, 21])
@TestCase(const [1730, 2351, 21])
@TestCase(const [1759, 2380, 20])
@TestCase(const [1763, 2384, 20])
@TestCase(const [1788, 2409, 20])
@TestCase(const [1792, 2413, 20])
@TestCase(const [1796, 2417, 20])

void ArithmeticExamples(int persianYear, int gregorianYear, int gregorianDayOfMarch)
{
  var persian = LocalDate(persianYear, 1, 1, CalendarSystem.persianArithmetic);
  var gregorian = persian.withCalendar(CalendarSystem.gregorian);
  expect(gregorianYear, gregorian.year);
  expect(3, gregorian.monthOfYear);
  expect(gregorianDayOfMarch, gregorian.dayOfMonth);
}

