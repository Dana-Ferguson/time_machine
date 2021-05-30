// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

/// Abstract implementation of a year/month/day calculator based around months which always have 30 days.
///
/// As the month length is fixed various calculations can be optimised.
/// This implementation assumes any additional days after twelve
/// months fall into a thirteenth month.
@internal
abstract class FixedMonthYearMonthDayCalculator extends RegularYearMonthDayCalculator {
  static const int _daysInMonth = 30;

  static const int _averageDaysPer10Years = 3653; // Ideally 365.25 days per year...

  @protected FixedMonthYearMonthDayCalculator(int minYear, int maxYear, int daysAtStartOfYear1)
      : super(minYear, maxYear, 13, _averageDaysPer10Years, daysAtStartOfYear1);

  @override
  int getDaysSinceEpoch(YearMonthDay yearMonthDay) =>
  // Just inline the arithmetic that would be done via various methods.
  getStartOfYearInDays(yearMonthDay.year)
      + (yearMonthDay.month - 1) * _daysInMonth
      + (yearMonthDay.day - 1);

  @protected
  @override
  int getDaysFromStartOfYearToStartOfMonth(int year, int month) => (month - 1) * _daysInMonth;

  @override
  bool isLeapYear(int year) => (year & 3) == 3;

  @override
  int getDaysInYear(int year) => isLeapYear(year) ? 366 : 365;

  @override
  int getDaysInMonth(int year, int month) => month != 13 ? _daysInMonth : isLeapYear(year) ? 6 : 5;

  @override
  YearMonthDay getYearMonthDay(int year, int dayOfYear) {
    int zeroBasedDayOfYear = dayOfYear - 1;
    int month = zeroBasedDayOfYear ~/ _daysInMonth + 1;
    int day = zeroBasedDayOfYear % _daysInMonth + 1;
    return YearMonthDay(year, month, day);
  }
}
