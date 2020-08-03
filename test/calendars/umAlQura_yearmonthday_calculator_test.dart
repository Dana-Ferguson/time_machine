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

@Test() @SkipMe('Need Dart Equivalent Test')
void BclEquivalence()
{
  // BclEquivalenceHelper.AssertEquivalent(BclCalendars.UmAlQura, CalendarSystem.UmAlQura);
}

@Test()
void GetStartOfYearInDays()
{
  var daysSinceEpoch = [-25448, -25094, -24739, -24384, -24030, -23676, -23322, -22968, -22613, -22258, -21904,
  -21550, -21196, -20842, -20487, -20133, -19778, -19424, -19069, -18715, -18361, -18007, -17652, -17298, -16943,
  -16589, -16235, -15881, -15526, -15172, -14817, -14462, -14108, -13754, -13400, -13046, -12691, -12336, -11982,
  -11627, -11273, -10919, -10565, -10211, -9856, -9501, -9147, -8793, -8439, -8085, -7730, -7376, -7021, -6666,
  -6312, -5958, -5604, -5250, -4895, -4540, -4186, -3831, -3477, -3123, -2769, -2414, -2060, -1705, -1351, -997,
  -643, -288, 66, 421, 776, 1130, 1484, 1838, 2192, 2547, 2901, 3256, 3610, 3964, 4318, 4673, 5027, 5382, 5736,
  6091, 6445, 6799, 7153, 7508, 7862, 8217, 8572, 8926, 9280, 9634, 9988, 10343, 10698, 11053, 11407, 11761, 12115,
  12469, 12824, 13179, 13533, 13888, 14242, 14596, 14950, 15304, 15659, 16013, 16368, 16722, 17076, 17430, 17785,
  18139, 18494, 18848, 19203, 19557, 19911, 20265, 20620, 20975, 21329, 21683, 22037, 22392, 22746, 23101, 23455,
  23810, 24164, 24518, 24872, 25227, 25581, 25936, 26290, 26645, 26999, 27353, 27707, 28062, 28416, 28771, 29125,
  29479, 29833, 30188, 30542, 30897, 31251, 31606, 31960, 32314, 32668, 33023, 33377, 33732, 34087, 34441, 34795,
  35149, 35503, 35858, 36213, 36567, 36921, 37275, 37629, 37984, 38338, 38693, 39047];

  // This exercises CalculateStartOfYearInDays too.
  var calculator = UmAlQuraYearMonthDayCalculator();
  for (int year = calculator.minYear; year <= calculator.maxYear; year++)
  {
    // var bcl = BclCalendars.UmAlQura.ToDateTime(year, 1, 1, 0, 0, 0, 0);
    // var days = (bcl - new DateTime(1970, 1, 1)).Days;
    var days = daysSinceEpoch[year - calculator.minYear];
    expect(days, calculator.getStartOfYearInDays(year), reason: 'year=$year');
  }
}

@Test()
void GetYearMonthDay_DaysSinceEpoch()
{
  var calculator = UmAlQuraYearMonthDayCalculator();
  int daysSinceEpoch = calculator.getStartOfYearInDays(calculator.minYear);
  for (int year = calculator.minYear; year <= calculator.maxYear; year++)
  {
    for (int month = 1; month <= 12; month++)
    {
      for (int day = 1; day <= calculator.getDaysInMonth(year, month); day++)
      {
        var actual = calculator.getYearMonthDayFromDaysSinceEpoch(daysSinceEpoch);
        var expected = YearMonthDay(year, month, day);
        expect(expected, actual, reason: 'daysSinceEpoch=$daysSinceEpoch');
        daysSinceEpoch++;
      }
    }
  }
}

@Test()
void GetYearMonthDay_YearAndDayOfYear()
{
  var calculator = UmAlQuraYearMonthDayCalculator();
  for (int year = calculator.minYear; year <= calculator.maxYear; year++)
  {
    int dayOfYear = 1;
    for (int month = 1; month <= 12; month++)
    {
      for (int day = 1; day <= calculator.getDaysInMonth(year, month); day++)
      {
        var actual = calculator.getYearMonthDay(year, dayOfYear);
        var expected = YearMonthDay(year, month, day);
        expect(expected, actual, reason: 'year=$year; dayOfYear=$dayOfYear');
        dayOfYear++;
      }
    }
  }
}

@Test()
void GetDaysFromStartOfYearToStartOfMonth()
{
  var calculator = UmAlQuraYearMonthDayCalculator();
  for (int year = calculator.minYear; year <= calculator.maxYear; year++)
  {
    int dayOfYear = 1;
    for (int month = 1; month <= 12; month++)
    {
      // This delegates to GetDaysFromStartOfYearToStartOfMonth (which is protected).
      expect(dayOfYear, calculator.getDayOfYear(YearMonthDay(year, month, 1)), reason: 'year=$year; month=$month');
      dayOfYear += calculator.getDaysInMonth(year, month);
    }
  }
}


@Test()
void GetYearMonthDay_InvalidValueForCoverage()
{
  var calculator = UmAlQuraYearMonthDayCalculator();
  expect(() => calculator.getYearMonthDay(calculator.minYear, 1000), throwsRangeError);
}
