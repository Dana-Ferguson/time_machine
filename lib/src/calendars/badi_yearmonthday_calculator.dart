// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:convert';
import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

/// See [CalendarSystem.badi] for details about the Badíʿ calendar.
@internal
class BadiYearMonthDayCalculator extends YearMonthDayCalculator {
// named constants to avoid use of raw numbers in the code
  static const int _averageDaysPer10Years = 3652; // Ideally 365.2425 per year...
  static const int _daysInAyyamiHaInLeapYear = 5;
  static const int _daysInAyyamiHaInNormalYear = 4;

  static const int daysInMonth = 19;
  static const int firstYearOfStandardizedCalendar = 172;
  static const int gregorianYearOfFirstBadiYear = 1844;

  /// There are 19 months in a year. Between the 18th and 19th month are the 'days of Ha' (Ayyam-i-Ha).
  /// In order to make everything else in Noda Time work appropriately, Ayyam-i-Ha are counted as
  /// extra days at the end of month 18.
  static const int month18 = 18;
  static const int _month19 = 19;
  static const int _monthsInYear = 19;

  static const int _unixEpochDayAtStartOfYear1 = -45941;
  static const int _badiMaxYear = 1000; // current lookup tables are pre-calculated for a thousand years
  static const int _badiMinYear = 1;

  /// This is the base64 representation of information for years 172 to 1000.
  /// NazRuzDate falls on March 19, 20, 21, or 22.
  /// DaysInAyymiHa can be 4,5.
  /// For each year, the value in the array is (NawRuzDate - 19) + 10 * (DaysInAyyamiHa - 4)
  static final List<int> _yearInfoRaw = base64.decode(
      'AgELAgIBCwICAQsCAgEBCwIBAQsCAQELAgEBCwIBAQsCAQELAgEBCwIBAQELAQEBCwEBAQsBAQELAQEB'
          'CwEBAQsBAQELAQEBCwEBAQEKAQEBCgEBAQsCAgILAgICCwICAgsCAgILAgICCwICAgELAgIBCwICAQsC'
          'AgELAgIBCwICAQsCAgELAgIBCwICAQELAgEBCwIBAQsCAQELAgEBCwIBAQsCAQELAgEBCwIBAQELAQEB'
          'CwEBAQsCAgIMAgICDAICAgwCAgIMAgICDAICAgILAgICCwICAgsCAgILAgICCwICAgsCAgILAgICCwIC'
          'AgELAgIBCwICAQsCAgELAgIBCwICAQsCAgELAgIBCwICAQELAgEBCwIBAQsCAgIMAwICDAMCAgwDAgIM'
          'AwICDAMCAgIMAgICDAICAgwCAgIMAgICDAICAgwCAgIMAgICDAICAgILAgICCwICAgsCAgILAgICCwIC'
          'AgsCAgILAgICAQsCAgELAgIBCwICAQsCAgELAgIBCwICAQsCAgELAgIBCwICAQELAgEBCwIBAQsCAQEL'
          'AgEBCwIBAQsCAQELAgEBCwIBAQELAQEBCwEBAQsBAQELAQEBCwEBAQsBAQELAQEBCwEBAQEKAQEBCgEB'
          'AQoBAQELAgICCwICAgsCAgILAgICAQsCAgELAgIBCwICAQsCAgELAgIBCwICAQsCAgELAgIBAQsCAQEL'
          'AgEBCwIBAQsCAQELAgEBCwIBAQsCAQELAgEBAQsBAQELAQEBCwEBAQsBAQELAgICDAICAgwCAgIMAgIC'
          'AgsCAgILAgICCwICAgsCAgILAgICCwICAgsCAgILAgICAQsCAgELAgIBCwICAQsCAgELAgIBCwICAQsC'
          'AgELAgIBAQsCAQELAgEBCwIBAQsCAQELAgICDAMCAgwDAgIMAwICAgwCAgIMAgICDAICAgwCAgIMAgIC'
          'DAICAgwCAgIMAgICAgsCAgILAgICCwICAgsCAgILAgICCwICAgsCAgILAgICAQsCAgELAgIBCwICAQsC'
          'AgELAgIBCwICAQsCAgELAgIBAQsCAQELAgEBCwIBAQsCAQELAgEBCwIBAQsCAQELAg==');

/*
static BadiYearMonthDayCalculator()
{
  Preconditions.DebugCheckState(
      FirstYearOfStandardizedCalendar + YearInfoRaw.Length == BadiMaxYear + 1,
      'Invalid compressed data. Length: ' + YearInfoRaw.Length);
}*/

  BadiYearMonthDayCalculator()
      : super(_badiMinYear,
      _badiMaxYear - 1,
      _averageDaysPer10Years,
      _unixEpochDayAtStartOfYear1);

  static int getDaysInAyyamiHa(int year) {
    Preconditions.checkArgumentRange('year', year, _badiMinYear, _badiMaxYear);
    if (year < firstYearOfStandardizedCalendar) {
      return ICalendarSystem.yearMonthDayCalculator(CalendarSystem.iso).isLeapYear(year + gregorianYearOfFirstBadiYear)
          ? _daysInAyyamiHaInLeapYear : _daysInAyyamiHaInNormalYear;
    }
    int num = _yearInfoRaw[year - firstYearOfStandardizedCalendar];
    return num > 10 ? _daysInAyyamiHaInLeapYear : _daysInAyyamiHaInNormalYear;
  }

  static int _getNawRuzDayInMarch(int year) {
    Preconditions.checkArgumentRange('year', year, _badiMinYear, _badiMaxYear);
    if (year < firstYearOfStandardizedCalendar) {
      return 21;
    }
    const int dayInMarchForOffsetToNawRuz = 19;
    int num = _yearInfoRaw[year - firstYearOfStandardizedCalendar];
    return dayInMarchForOffsetToNawRuz + (num % 10);
  }

  @protected
  @override
  int calculateStartOfYearDays(int year) {
    Preconditions.checkArgumentRange('year', year, _badiMinYear, _badiMaxYear);

    // The epoch is the same regardless of calendar system, so if we work out when the
    // start of the Badíʿ year is in terms of the Gregorian year, we can just use that
    // date's days-since-epoch value.
    var gregorianYear = year + gregorianYearOfFirstBadiYear - 1;
    var nawRuz = LocalDate(gregorianYear, 3, _getNawRuzDayInMarch(year));
    return nawRuz.epochDay;
  }

  @protected
  @override
  int getDaysFromStartOfYearToStartOfMonth(int year, int month) {
    var daysFromStartOfYearToStartOfMonth = daysInMonth * (month - 1);

    if (month == _month19) {
      daysFromStartOfYearToStartOfMonth += getDaysInAyyamiHa(year);
    }

    return daysFromStartOfYearToStartOfMonth;
  }

  @override YearMonthDay addMonths(YearMonthDay start, int months) {
    if (months == 0) {
      return start;
    }

    var movingBackwards = months < 0;

    var thisMonth = start.month;
    var thisYear = start.year;
    var thisDay = start.day;

    var nextDay = thisDay;

    if (isInAyyamiHa(start)) {
      nextDay = thisDay - daysInMonth;

      if (movingBackwards) {
        thisMonth++;
      }
    }

    var nextYear = thisYear;
    var nextMonthNum = thisMonth + months;

    if (nextMonthNum > _monthsInYear) {
      nextYear = thisYear + nextMonthNum ~/ _monthsInYear;
      nextMonthNum = nextMonthNum % _monthsInYear;
    }
    else if (nextMonthNum < 1) {
      nextMonthNum = _monthsInYear - nextMonthNum;
      nextYear = thisYear - nextMonthNum ~/ _monthsInYear;
      nextMonthNum = _monthsInYear - arithmeticMod(nextMonthNum, _monthsInYear);
    }

    Preconditions.checkArgumentRange('nextYear', nextYear, _badiMinYear, _badiMaxYear);

    var result = YearMonthDay(nextYear, nextMonthNum, nextDay);

    return result;
  }

  @override int getDaysInMonth(int year, int month) {
    Preconditions.checkArgumentRange('year', year, _badiMinYear, _badiMaxYear);
    return month == month18 ? daysInMonth + getDaysInAyyamiHa(year) : daysInMonth;
  }

  @override int getDaysInYear(int year) => 361 + getDaysInAyyamiHa(year);

  @override int getDaysSinceEpoch(YearMonthDay target) {
    var month = target.month;
    var year = target.year;

    var firstDay0OfYear = calculateStartOfYearDays(year) - 1;

    var daysSinceEpoch = firstDay0OfYear
        + (month - 1) * daysInMonth
        + target.day;

    if (month == _month19) {
      daysSinceEpoch += getDaysInAyyamiHa(year);
    }

    return daysSinceEpoch;
  }

  @override int getMonthsInYear(int year) => _monthsInYear;

  @override YearMonthDay getYearMonthDay(int year, int dayOfYear) {
    Preconditions.checkArgumentRange('dayOfYear', dayOfYear, 1, getDaysInYear(year));

    var firstOfLoftiness = 1 + daysInMonth * month18 + getDaysInAyyamiHa(year);

    if (dayOfYear >= firstOfLoftiness) {
      return YearMonthDay(year, _month19, dayOfYear - firstOfLoftiness + 1);
    }

    var month = math.min(1 + (dayOfYear - 1) ~/ daysInMonth, month18);
    var day = dayOfYear - (month - 1) * daysInMonth;

    return YearMonthDay(year, month, day);
  }

  bool isInAyyamiHa(YearMonthDay ymd) => ymd.month == month18 && ymd.day > daysInMonth;

  @override bool isLeapYear(int year) => getDaysInAyyamiHa(year) != _daysInAyyamiHaInNormalYear;

  @override int monthsBetween(YearMonthDay start, YearMonthDay end) {
    int startMonth = start.month;
    int startYear = start.year;

    int endMonth = end.month;
    int endYear = end.year;

    int diff = (endYear - startYear) * _monthsInYear + endMonth - startMonth;

    // If we just add the difference in months to start, what do we get?
    YearMonthDay simpleAddition = addMonths(start, diff);

    // Note: this relies on naive comparison of year/month/date values.
    if (start <= end) {
      // Moving forward: if the result of the simple addition is before or equal to the end,
      // we're done. Otherwise, rewind a month because we've overshot.
      return simpleAddition <= end ? diff : diff - 1;
    }
    else {
      // Moving backward: if the result of the simple addition (of a non-positive number)
      // is after or equal to the end, we're done. Otherwise, increment by a month because
      // we've overshot backwards.
      return simpleAddition >= end ? diff : diff + 1;
    }
  }

  @override YearMonthDay setYear(YearMonthDay start, int newYear) {
    Preconditions.checkArgumentRange('newYear', newYear, _badiMinYear, _badiMaxYear);

    var month = start.month;
    var day = start.day;

    if (isInAyyamiHa(start)) {
      // Moving a year while within Ayyam-i-Ha is not well defined.
      // In this implementation, if starting on day 5, end on day 4 (stay in Ayyam-i-Ha)
      var daysInThisAyyamiHa = getDaysInAyyamiHa(newYear);
      return YearMonthDay(newYear, month, math.min(day, daysInMonth + daysInThisAyyamiHa));
    }

    return YearMonthDay(newYear, month, day);
  }

  @override void validateYearMonthDay(int year, int month, int day) {
    Preconditions.checkArgumentRange('year', year, _badiMinYear, _badiMaxYear);
    Preconditions.checkArgumentRange('month', month, 1, _monthsInYear);

    int daysInMonth = month == month18 ? BadiYearMonthDayCalculator.daysInMonth + getDaysInAyyamiHa(year) : BadiYearMonthDayCalculator.daysInMonth;
    Preconditions.checkArgumentRange('day', day, 1, daysInMonth);
  }
}
