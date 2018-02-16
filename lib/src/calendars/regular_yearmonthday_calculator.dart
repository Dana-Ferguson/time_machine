import 'dart:math' as math;

import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine.dart';


@internal
abstract class RegularYearMonthDayCalculator extends YearMonthDayCalculator {
  final int _monthsInYear;

  @internal
  RegularYearMonthDayCalculator(int minYear, int maxYear, int monthsInYear,
      int averageDaysPer10Years, int daysAtStartOfYear1)
      : _monthsInYear = monthsInYear,
        super(minYear, maxYear, averageDaysPer10Years, daysAtStartOfYear1) {

  }

  @internal
  @override int getMonthsInYear(int year) => _monthsInYear;

  /// Implements a simple year-setting policy, truncating the day
  /// if necessary.
  @internal
  @override YearMonthDay setYear(YearMonthDay yearMonthDay, int year) {
// TODO(2.0): All subclasses have the same logic of "detect leap years,
// and otherwise we're fine". Put it here instead.
    int currentMonth = yearMonthDay.month;
    int currentDay = yearMonthDay.day;
    int newDay = getDaysInMonth(year, currentMonth);
    return new YearMonthDay(year, currentMonth, math.min(currentDay, newDay));
  }

  @internal
  @override YearMonthDay addMonths(YearMonthDay yearMonthDay, int months) {
    if (months == 0) {
      return yearMonthDay;
    }
// Get the year and month
    int thisYear = yearMonthDay.year;
    int thisMonth = yearMonthDay.month;

// Do not refactor without careful consideration.
// Order of calculation is important.

    int yearToUse;
// Initially, monthToUse is zero-based
    int monthToUse = thisMonth - 1 + months;
    if (monthToUse >= 0) {
      yearToUse = thisYear + (monthToUse ~/ _monthsInYear);
      monthToUse = (monthToUse % _monthsInYear) + 1;
    }
    else {
      yearToUse = thisYear + (monthToUse ~/ _monthsInYear) - 1;
      monthToUse = monthToUse.abs();
      int remMonthToUse = monthToUse % _monthsInYear;
// Take care of the boundary condition
      if (remMonthToUse == 0) {
        remMonthToUse = _monthsInYear;
      }
      monthToUse = _monthsInYear - remMonthToUse + 1;
// Take care of the boundary condition
      if (monthToUse == 1) {
        yearToUse++;
      }
    }
// End of do not refactor.

// Quietly force DOM to nearest sane value.
    int dayToUse = yearMonthDay.day;
    int maxDay = getDaysInMonth(yearToUse, monthToUse);
    dayToUse = math.min(dayToUse, maxDay);
    return new YearMonthDay(yearToUse, monthToUse, dayToUse);
  }

  @internal
  @override int monthsBetween(YearMonthDay minuendDate, YearMonthDay subtrahendDate) {
    int minuendYear = minuendDate.year;
    int subtrahendYear = subtrahendDate.year;
    int minuendMonth = minuendDate.month;
    int subtrahendMonth = subtrahendDate.month;

    int diff = (minuendYear - subtrahendYear) * _monthsInYear + minuendMonth - subtrahendMonth;

// If we just add the difference in months to subtrahendDate, what do we get?
    YearMonthDay simpleAddition = addMonths(subtrahendDate, diff);

// Note: this relies on naive comparison of year/month/date values.
    if (subtrahendDate <= minuendDate) {
// Moving forward: if the result of the simple addition is before or equal to the minuend,
// we're done. Otherwise, rewind a month because we've overshot.
      return simpleAddition <= minuendDate ? diff : diff - 1;
    }
    else {
// Moving backward: if the result of the simple addition (of a non-positive number)
// is after or equal to the minuend, we're done. Otherwise, increment by a month because
// we've overshot backwards.
      return simpleAddition >= minuendDate ? diff : diff + 1;
    }
  }
}
