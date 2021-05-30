// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'package:meta/meta.dart';

import 'package:time_machine/src/calendars/time_machine_calendars.dart';
import 'package:time_machine/src/time_machine_internal.dart';

@internal
abstract class GJYearMonthDayCalculator extends RegularYearMonthDayCalculator {
  // These arrays are NOT public. We trust ourselves not to alter the array.
  // They use zero-based array indexes so the that valid range of months is
  // automatically checked. They are protected so that GregorianYearMonthDayCalculator can
  // read them.
  @protected
  static const List<int> minDaysPerMonth = [ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  @protected
  static const List<int> maxDaysPerMonth = [ 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  /*
    void main() {
      var _minTotalDaysByMonth = new List<int>(12)..[0] = 0;
      var _maxTotalDaysByMonth = new List<int>(12)..[0] = 0;
      int minSum = 0;
      int maxSum = 0;
      for (int i = 0; i < 11; i++)
      {
        minSum += _minDaysPerMonth[i];
        maxSum += _maxDaysPerMonth[i];
        _minTotalDaysByMonth[i + 1] = minSum;
        _maxTotalDaysByMonth[i + 1] = maxSum;
      }

      print(_minTotalDaysByMonth);
      print(_maxTotalDaysByMonth);
    }
 */
  // In the source material this was produced in a static constructor -- you can find the code above to reproduce this
  static const List<int> _minTotalDaysByMonth = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  static const List<int> _maxTotalDaysByMonth = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335];

  GJYearMonthDayCalculator(int minYear, int maxYear, int averageDaysPer10Years, int daysAtStartOfYear1)
      : super(minYear, maxYear, 12, averageDaysPer10Years, daysAtStartOfYear1);

  // Note: parameter is renamed to d for brevity. It's still the 1-based day-of-year
  @override
  YearMonthDay getYearMonthDay(int year, int d) {
    bool isLeap = isLeapYear(year);

    int startOfMonth;
    // Perform a hard-coded binary search to get the 0-based start day of the month. We can
    // then use that to work out the month... without ever hitting the heap. The values
    // are still MinTotalDaysPerMonth and MaxTotalDaysPerMonth (-1 for convenience), just hard-coded.
    if (isLeap) {
      startOfMonth = ((d < 183)
          ? ((d < 92) ? ((d < 32) ? 0 : (d < 61) ? 31 : 60) : ((d < 122) ? 91 : (d < 153) ? 121 : 152))
          : ((d < 275)
          ? ((d < 214) ? 182 : (d < 245) ? 213 : 244)
          : ((d < 306) ? 274 : (d < 336) ? 305 : 335)));
    }
    else {
      startOfMonth = ((d < 182)
          ? ((d < 91) ? ((d < 32) ? 0 : (d < 60) ? 31 : 59) : ((d < 121) ? 90 : (d < 152) ? 120 : 151))
          : ((d < 274)
          ? ((d < 213) ? 181 : (d < 244) ? 212 : 243)
          : ((d < 305) ? 273 : (d < 335) ? 304 : 334)));
    }

    int dayOfMonth = d - startOfMonth;
    return YearMonthDay(year, (startOfMonth ~/ 29) + 1, dayOfMonth);
  }

  @override
  int getDaysInYear(int year) => isLeapYear(year) ? 366 : 365;

  @override
  int getDaysInMonth(int year, int month) =>
  // We know that only February differs, so avoid the virtual call for other months.
  month == 2 && isLeapYear(year) ? maxDaysPerMonth[month - 1] : minDaysPerMonth[month - 1];

  @protected @override
  int getDaysFromStartOfYearToStartOfMonth(int year, int month) =>
      isLeapYear(year) ? _maxTotalDaysByMonth[month - 1] : _minTotalDaysByMonth[month - 1];

  @override
  YearMonthDay setYear(YearMonthDay yearMonthDay, int year) {
    int month = yearMonthDay.month;
    int day = yearMonthDay.day;
    // The only value which might change day is Feb 29th.
    if (month == 2 && day == 29 && !isLeapYear(year)) {
      day = 28;
    }
    return YearMonthDay(year, month, day);
  }
}

