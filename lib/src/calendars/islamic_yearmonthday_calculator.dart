// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

@internal
class IslamicYearMonthDayCalculator extends RegularYearMonthDayCalculator {
  /// Days in a pair of months, in days.
  static const int _monthPairLength = 59;

  /// The length of a long month, in days.
  static const int _longMonthLength = 30;

  /// The length of a short month, in days.
  static const int _shortMonthLength = 29;

  /// The typical number of days in 10 years.
  static const int _averageDaysPer10Years = 3544; // Ideally 354.36667 per year

  /// The number of days in a non-leap year.
  static const int _daysPerNonLeapYear = 354;

  /// The number of days in a leap year.
  static const int _daysPerLeapYear = 355;

  /// The days for the civil (Friday) epoch of July 16th 622CE.
  static const int _daysAtCivilEpoch = -492148;

  /// The days for the civil (Thursday) epoch of July 15th 622CE.
  static const int _daysAtAstronomicalEpoch = _daysAtCivilEpoch - 1;

  /// The length of the cycle of leap years.
  static const int _leapYearCycleLength = 30;

  /// The number of days in leap cycle.
  static const int _daysPerLeapCycle = 19 * _daysPerNonLeapYear + 11 * _daysPerLeapYear;

  /// The pattern of leap years within a cycle, one bit per year, for this calendar.
  final int _leapYearPatternBits;

  static const List<int> _totalDaysByMonth = [0, 30, 59, 89, 118, 148, 177, 207, 236, 266, 295, 325];

  // This generates _totalDaysByMonth, but I'd rather this code get tree-shaken out.
  // ignore: unused_element
  static List<int> _genTotalDaysByMonth() {
    int days = 0;
    var totalDaysByMonth = <int>[];
    for (int i = 0; i < 12; i++) {
      // _totalDaysByMonth[i] = days;
      totalDaysByMonth.add(days);

      // Here, the month number is 0-based, so even months are long
      int daysInMonth = (i & 1) == 0 ? _longMonthLength : _shortMonthLength;
      // This doesn't take account of leap years, but that doesn't matter - because
      // it's not used on the last iteration, and leap years only affect the final month
      // in the Islamic calendar.
      days += daysInMonth;
    }

    return totalDaysByMonth;
  }

  factory IslamicYearMonthDayCalculator(IslamicLeapYearPattern leapYearPattern, IslamicEpoch epoch) {
    return IslamicYearMonthDayCalculator._(_getLeapYearPatternBits(leapYearPattern), epoch);
  }

  IslamicYearMonthDayCalculator._(this._leapYearPatternBits, IslamicEpoch epoch)
      : super(1, 9665, 12, _averageDaysPer10Years, _getYear1Days(epoch));

  @protected
  @override
  int getDaysFromStartOfYearToStartOfMonth(int year, int month) {
    // The number of days at the *start* of a month isn't affected by
    // the year as the only month length which varies by year is the last one.
    return _totalDaysByMonth[month - 1];
  }

  @override YearMonthDay getYearMonthDay(int year, int dayOfYear) {
    int month, day;
    // Special case the last day in a leap year
    if (dayOfYear == _daysPerLeapYear) {
      month = 12;
      day = 30;
    }
    else {
      int dayOfYearZeroBased = dayOfYear - 1;
      month = ((dayOfYearZeroBased * 2) ~/ _monthPairLength) + 1;
      day = ((dayOfYearZeroBased % _monthPairLength) % _longMonthLength) + 1;
    }
    return YearMonthDay(year, month, day);
  }

  @override bool isLeapYear(int year) {
    // Handle negative years in order to make calculations near the start of the calendar work cleanly.
    int yearOfCycle = year >= 0 ? year % _leapYearCycleLength
        : arithmeticMod(year, _leapYearCycleLength) + _leapYearCycleLength;
    int key = 1 << yearOfCycle;
    return (_leapYearPatternBits & key) > 0;
  }

  @override int getDaysInYear(int year) => isLeapYear(year) ? _daysPerLeapYear : _daysPerNonLeapYear;

  @override int getDaysInMonth(int year, int month) {
    if (month == 12 && isLeapYear(year)) {
      return _longMonthLength;
    }
    // Note: month is 1-based here, so even months are the short ones
    return (month & 1) == 0 ? _shortMonthLength : _longMonthLength;
  }

  @protected
  @override
  int calculateStartOfYearDays(int year) {
    // The first cycle starts in year 1, not year 0.
    // We try to cope with years outside the normal range, in order to allow arithmetic at the boundaries.
    int cycle = year > 0 ? (year - 1) ~/ _leapYearCycleLength
        : (year - _leapYearCycleLength) ~/ _leapYearCycleLength;
    int yearAtStartOfCycle = (cycle * _leapYearCycleLength) + 1;

    int days = daysAtStartOfYear1 + cycle * _daysPerLeapCycle;

    // We've got the days at the start of the cycle (e.g. at the start of year 1, 31, 61 etc).
    // Now go from that year to (but not including) the year we're looking for, adding the right
    // number of days in each year. So if we're trying to find the start of year 34, we would
    // find the days at the start of year 31, then add the days *in* year 31, the days in year 32,
    // and the days in year 33.
    // If this ever proves to be a bottleneck, we could create an array for each IslamicLeapYearPattern
    // with 'the number of days for the first n years in a cycle'.
    for (int i = yearAtStartOfCycle; i < year; i++) {
      days += getDaysInYear(i);
    }
    return days;
  }

  /// Returns the pattern of leap years within a cycle, one bit per year, for the specified pattern.
  /// Note that although cycle years are usually numbered 1-30, the bit pattern is for 0-29; cycle year
  /// 30 is represented by bit 0.
  static int _getLeapYearPatternBits(IslamicLeapYearPattern leapYearPattern) {
    switch (leapYearPattern) {
      // When reading bit patterns, don't forget to read right to left...
      case IslamicLeapYearPattern.base15:
        return 623158436; // 0b100101001001001010010010100100
      case IslamicLeapYearPattern.base16:
        return 623191204; // 0b100101001001010010010010100100
      case IslamicLeapYearPattern.indian:
        return 690562340; // 0b101001001010010010010100100100
      case IslamicLeapYearPattern.habashAlHasib:
        return 153692453; // 0b001001001010010010100100100101
      default:
        throw ArgumentError.value(leapYearPattern.index, 'leapYearPattern');
    }
  }

  /// Returns the days since the Unix epoch at the specified epoch.
  static int _getYear1Days(IslamicEpoch epoch) {
    switch (epoch) {
      // Epoch 1970-01-01 ISO = 1389-10-22 Islamic (civil) or 1389-10-23 Islamic (astronomical)
      case IslamicEpoch.astronomical:
        return _daysAtAstronomicalEpoch;
      case IslamicEpoch.civil:
        return _daysAtCivilEpoch;
      default:
        throw ArgumentError.value(epoch.index, 'epoch');
    }
  }
}
