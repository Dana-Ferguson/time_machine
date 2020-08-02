// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:math' as math;
import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

/// See [CalendarSystem.getHebrewCalendar] for details. This is effectively
/// an adapter around [HebrewScripturalCalculator].
@internal
class HebrewYearMonthDayCalculator extends YearMonthDayCalculator {
  static const int _unixEpochDayAtStartOfYear1 = -2092590;
  static const int _monthsPerLeapCycle = 235;
  static const int _yearsPerLeapCycle = 19;
  final HebrewMonthNumbering _monthNumbering;

  HebrewYearMonthDayCalculator(this._monthNumbering)
      : super(HebrewScripturalCalculator.minYear, HebrewScripturalCalculator.maxYear,
      3654, // Average length of 10 years
      _unixEpochDayAtStartOfYear1);

  int _calendarToCivilMonth(int year, int month) =>
      _monthNumbering == HebrewMonthNumbering.civil ? month : HebrewMonthConverter.scripturalToCivil(year, month);

  int _calendarToScripturalMonth(int year, int month) =>
      _monthNumbering == HebrewMonthNumbering.scriptural ? month : HebrewMonthConverter.civilToScriptural(year, month);

  int _civilToCalendarMonth(int year, int month) =>
      _monthNumbering == HebrewMonthNumbering.civil ? month : HebrewMonthConverter.civilToScriptural(year, month);

  int _scripturalToCalendarMonth(int year, int month) =>
      _monthNumbering == HebrewMonthNumbering.scriptural ? month : HebrewMonthConverter.scripturalToCivil(year, month);

  /// Returns whether or not the given year is a leap year - that is, one with 13 months. This is
  /// not quite the same as a leap year in (say) the Gregorian calendar system...
  @override bool isLeapYear(int year) => HebrewScripturalCalculator.isLeapYear(year);

  @protected
  @override
  int getDaysFromStartOfYearToStartOfMonth(int year, int month) {
    int scripturalMonth = _calendarToScripturalMonth(year, month);
    return HebrewScripturalCalculator.getDaysFromStartOfYearToStartOfMonth(year, scripturalMonth);
  }

  @protected
  @override
  int calculateStartOfYearDays(int year) {
    // Note that we might get called with a year of 0 here. I think that will still be okay,
    // given how HebrewScripturalCalculator works.
    int daysSinceHebrewEpoch = HebrewScripturalCalculator.elapsedDays(year) - 1; // ElapsedDays returns 1 for year 1.
    return daysSinceHebrewEpoch + _unixEpochDayAtStartOfYear1;
  }

  @override YearMonthDay getYearMonthDay(int year, int dayOfYear) {
    YearMonthDay scriptural = HebrewScripturalCalculator.getYearMonthDay(year, dayOfYear);
    return _monthNumbering == HebrewMonthNumbering.scriptural ? scriptural : YearMonthDay(
        year, HebrewMonthConverter.scripturalToCivil(year, scriptural.month), scriptural.day);
  }

  @override int getDaysInYear(int year) => HebrewScripturalCalculator.daysInYear(year);

  @override int getMonthsInYear(int year) => isLeapYear(year) ? 13 : 12;

  /// Change the year, maintaining month and day as well as possible. This doesn't
  /// work in the same way as other calendars; see http://judaism.stackexchange.com/questions/39053
  /// for the reasoning behind the rules.
  @override YearMonthDay setYear(YearMonthDay yearMonthDay, int year) {
    int currentYear = yearMonthDay.year;
    int currentMonth = yearMonthDay.month;
    int targetDay = yearMonthDay.day;
    int targetScripturalMonth = _calendarToScripturalMonth(currentYear, currentMonth);
    if (targetScripturalMonth == 13 && !isLeapYear(year)) {
      // If we were in Adar II and the target year is not a leap year, map to Adar.
      targetScripturalMonth = 12;
    }
    else if (targetScripturalMonth == 12 && isLeapYear(year) && !isLeapYear(currentYear)) {
      // If we were in Adar (non-leap year), go to Adar II rather than Adar I in a leap year.
      targetScripturalMonth = 13;
    }
    // If we're aiming for the 30th day of Heshvan, Kislev or an Adar, it's possible that the change in year
    // has meant the day becomes invalid. In that case, roll over to the 1st of the subsequent month.
    if (targetDay == 30 && (targetScripturalMonth == 8 || targetScripturalMonth == 9 || targetScripturalMonth == 12)) {
      if (HebrewScripturalCalculator.daysInMonth(year, targetScripturalMonth) != 30) {
        targetDay = 1;
        targetScripturalMonth++;
        // From Adar, roll to Nisan.
        if (targetScripturalMonth == 13) {
          targetScripturalMonth = 1;
        }
      }
    }
    int targetCalendarMonth = _scripturalToCalendarMonth(year, targetScripturalMonth);
    return YearMonthDay(year, targetCalendarMonth, targetDay);
  }

  @override int getDaysInMonth(int year, int month) =>
      HebrewScripturalCalculator.daysInMonth(year, _calendarToScripturalMonth(year, month));

  @override YearMonthDay addMonths(YearMonthDay yearMonthDay, int months) {
    // Note: this method gives the same result regardless of the month numbering used
    // by the instance. The method works in terms of civil month numbers for most of
    // the time in order to simplify the logic.
    if (months == 0) {
      return yearMonthDay;
    }
    int year = yearMonthDay.year;
    int month = _calendarToCivilMonth(year, yearMonthDay.month);
    // This arithmetic works the same both backwards and forwards.
    year += (months ~/ _monthsPerLeapCycle) * _yearsPerLeapCycle;
    months = arithmeticMod(months, _monthsPerLeapCycle);
    if (months > 0) {
      // Add as many months as we need to in order to act as if we'd begun at the start
      // of the year, for simplicity.
      months += month - 1;
      // Add a year at a time
      while (months >= getMonthsInYear(year)) {
        months -= getMonthsInYear(year);
        year++;
      }
      // However many months we've got left to add tells us the final month.
      month = months + 1;
    }
    else {
      // Pretend we were given the month at the end of the years.
      months -= getMonthsInYear(year) - month;
        // Subtract a year at a time
        while (months + getMonthsInYear(year) <= 0) {
        months += getMonthsInYear(year);
        year--;
      }
      // However many months we've got left to add (which will still be negative...)
      // tells us the final month.
      month = getMonthsInYear(year) + months;
    }

    // Convert back to calendar month
    month = _civilToCalendarMonth(year, month);
    int day = math.min(getDaysInMonth(year, month), yearMonthDay.day);
    return YearMonthDay(year, month, day);
  }

  @override int monthsBetween(YearMonthDay start, YearMonthDay end) {
    // First (quite rough) guess... we could probably be more efficient than this, but it's unlikely to be very far off.
    int startCivilMonth = _calendarToCivilMonth(start.year, start.month);
    double startTotalMonths = startCivilMonth + (start.year * _monthsPerLeapCycle) / _yearsPerLeapCycle;
    int endCivilMonth = _calendarToCivilMonth(end.year, end.month);
    double endTotalMonths = endCivilMonth + (end.year * _monthsPerLeapCycle) / _yearsPerLeapCycle;
    int diff = (endTotalMonths - startTotalMonths).toInt();

    if (compare(start, end) <= 0) {
      // Go backwards until we've got a tight upper bound...
      while (compare(addMonths(start, diff), end) > 0) {
        diff--;
      }
      // Go forwards until we've overshot
      while (compare(addMonths(start, diff), end) <= 0) {
        diff++;
      }
      // Take account of the overshoot
      return diff - 1;
    }
    else {
      // Moving backwards, so we need to end up with a result greater than or equal to end...
      // Go forwards until we've got a tight upper bound...
      while (compare(addMonths(start, diff), end) < 0) {
        diff++;
      }
      // Go backwards until we've overshot
      while (compare(addMonths(start, diff), end) >= 0) {
        diff--;
      }
      // Take account of the overshoot
      return diff + 1;
    }
  }

  @override int compare(YearMonthDay lhs, YearMonthDay rhs) {
    // The civil month numbering system allows a naive comparison.
    if (_monthNumbering == HebrewMonthNumbering.civil) {
      return lhs.compareTo(rhs);
    }
    // Otherwise, try one component at a time. (We could benchmark this
    // against creating a new pair of YearMonthDay values in the civil month numbering,
    // and comparing them...)
    int yearComparison = lhs.year.compareTo(rhs.year);
    if (yearComparison != 0) {
      return yearComparison;
    }
    int lhsCivilMonth = _calendarToCivilMonth(lhs.year, lhs.month);
    int rhsCivilMonth = _calendarToCivilMonth(rhs.year, rhs.month);
    int monthComparison = lhsCivilMonth.compareTo(rhsCivilMonth);
    if (monthComparison != 0) {
      return monthComparison;
    }
    return lhs.day.compareTo(rhs.day);
  }
}