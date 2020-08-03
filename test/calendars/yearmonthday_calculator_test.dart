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

// todo: add the rest of the calendars

// Here the term 'Islamic' only refers to whether the implementation is IslamicYearMonthDayCalculator,
// not whether the calendar itself is based on Islamic scripture.
List<TestCaseData> NonIslamicCalculators = [
  TestCaseData(GregorianYearMonthDayCalculator())..name='Gregorian',
  //new TestCaseData(new CopticYearMonthDayCalculator())..name='Coptic',
  TestCaseData(JulianYearMonthDayCalculator())..name='Julian',
//new TestCaseData(new HebrewYearMonthDayCalculator(HebrewMonthNumbering.Civil)).SetName('Hebrew Civil'),
//new TestCaseData(new HebrewYearMonthDayCalculator(HebrewMonthNumbering.Scriptural)).SetName('Hebrew Scriptural'),
//new TestCaseData(new PersianYearMonthDayCalculator.Simple()).SetName('Persian Simple'),
//new TestCaseData(new PersianYearMonthDayCalculator.Arithmetic()).SetName('Persian Arithmetic'),
//new TestCaseData(new PersianYearMonthDayCalculator.Astronomical()).SetName('Persian Astronomoical'),
//new TestCaseData(new UmAlQuraYearMonthDayCalculator()).SetName('Um Al Qura'),
];

List<TestCaseData> IslamicCalculators = [];
/*
(from epoch in Enum.GetValues(typeof(IslamicEpoch)).Cast<IslamicEpoch>()
from leapYearPattern in Enum.GetValues(typeof(IslamicLeapYearPattern)).Cast<IslamicLeapYearPattern>()
let calculator = new IslamicYearMonthDayCalculator(leapYearPattern, epoch)
select new TestCaseData(calculator).SetName($'Islamic: {epoch}, {leapYearPattern}'))
.ToArray();*/

Iterable<TestCaseData> AllCalculators = [NonIslamicCalculators, IslamicCalculators].expand((x) => x);

// Note for tests using TestCaseSource:
// We can't make the parameter of type YearMonthDayCalculator, because that's internal.
// We can't make the method internal, as then it isn't a test. Casting is all we've got.

@Test()
@TestCaseSource(#AllCalculators)
void ValidateStartOfYear1Days(Object calculatorAsObject)
{
  var calculator = calculatorAsObject as YearMonthDayCalculator;
  // Some calendars (e.g. Um Al Qura) don't support year 1, so the DaysAtStartOfYear1
  // is somewhat theoretical. (It's still used in such calendars, but only to get a guess
  // as to a year number given a day number.)
  if (calculator.minYear > 1 || calculator.maxYear < 0)
  {
    return;
  }
  expect(calculator.getStartOfYearInDays(1), calculator.daysAtStartOfYear1);
}

@Test()
@TestCaseSource(#AllCalculators)
void GetYearConsistentWithGetYearDays(Object calculatorAsObject)
{
  var calculator = calculatorAsObject as YearMonthDayCalculator;
  for (int year = calculator.minYear; year <= calculator.maxYear; year++)
  {
    int startOfYearDays = calculator.getStartOfYearInDays(year);

    var tmp = calculator.getYear(startOfYearDays);
    var yearCandidate = tmp[0];
    var dayOfYear = tmp[1];
    expect(yearCandidate, year, reason: 'Start of year $year');
    expect(dayOfYear, 0); // Zero-based...

    tmp = calculator.getYear(startOfYearDays - 1);
    yearCandidate = tmp[0];
    dayOfYear = tmp[1];
    expect(yearCandidate, year - 1, reason: 'End of year ${year - 1}');
    expect(calculator.getDaysInYear(year - 1) - 1, dayOfYear);
  }
}

