// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:convert';
import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

/// Base class for the three variants of the Persian (Solar Hijri) calendar.
/// Concrete subclasses are nested to allow different start dates and leap year calculations.
///
/// The constructor uses IsLeapYear to precompute lots of data; it is therefore important that
/// the implementation of IsLeapYear in subclasses uses no instance fields.
@internal
abstract class PersianYearMonthDayCalculator extends RegularYearMonthDayCalculator {
  static const int _daysPerNonLeapYear = (31 * 6) + (30 * 5) + 29;
  static const int _daysPerLeapYear = _daysPerNonLeapYear + 1;

  // Approximation; it'll be pretty close in all variants.
  static const int _averageDaysPer10Years = (_daysPerNonLeapYear * 25 + _daysPerLeapYear * 8) * 10 ~/ 33;
  static const int maxPersianYear = 9377;

  static final List<int> _totalDaysByMonth = _generateTotalDaysByMonth();

  // todo: make these `final` again? might be able to at least make this more efficient (make this equal to a function, that permenantly sets it to a value, forgetting the function?)
  // List<int>? __startOfYearInDaysCache;

  late final List<int> _startOfYearInDaysCache = _generateStartOfYearInDaysCache();

  static List<int> _generateTotalDaysByMonth() {
    int days = 0;
    var totalDaysByMonth = List<int>.filled(13, 0);
    for (int i = 1; i <= 12; i++) {
      totalDaysByMonth[i] = days;
      int daysInMonth = i <= 6 ? 31 : 30;
      // This doesn't take account of leap years, but that doesn't matter - because
      // it's not used on the last iteration, and leap years only affect the final month
      // in the Persian calendar.
      days += daysInMonth;
    }

    return totalDaysByMonth;
  }

  List<int> _generateStartOfYearInDaysCache() {
    var startOfYearInDaysCache = List<int>.filled(maxYear + 2, 0);
    int startOfYear = daysAtStartOfYear1 - getDaysInYear(0);
    for (int year = 0; year <= maxYear + 1; year++) {
      startOfYearInDaysCache[year] = startOfYear;
      startOfYear += getDaysInYear(year);
    }

    return startOfYearInDaysCache;
  }

  PersianYearMonthDayCalculator._(int daysAtStartOfYear1)
      : super(1, maxPersianYear, 12, _averageDaysPer10Years, daysAtStartOfYear1);


  @protected
  @override
  int getDaysFromStartOfYearToStartOfMonth(int year, int month) => _totalDaysByMonth[month];
  
  @override
  int getStartOfYearInDays(int year) {
    assert(Preconditions.debugCheckArgumentRange('year', year, minYear - 1, maxYear + 1));
    return _startOfYearInDaysCache[year];
  }

  @protected
  @override
  int calculateStartOfYearDays(int year) {
    // This would only be called from GetStartOfYearInDays, which is overridden.
    throw UnimplementedError();
  }

  @override
  YearMonthDay getYearMonthDay(int year, int dayOfYear) {
    int dayOfYearZeroBased = dayOfYear - 1;
    int month;
    int day;
    if (dayOfYear == _daysPerLeapYear) {
      // Last day of a leap year.
      month = 12;
      day = 30;
    }
    else if (dayOfYearZeroBased < 6 * 31) {
      // In the first 6 months, all of which are 31 days long.
      month = dayOfYearZeroBased ~/ 31 + 1;
      day = (dayOfYearZeroBased % 31) + 1;
    }
    else {
      // Last 6 months (other than last day of leap year).
      // Work out where we are within that 6 month block, then use simple arithmetic.
      int dayOfSecondHalf = dayOfYearZeroBased - 6 * 31;
      month = dayOfSecondHalf ~/ 30 + 7;
      day = (dayOfSecondHalf % 30) + 1;
    }
    return YearMonthDay(year, month, day);
  }

  @override int getDaysInMonth(int year, int month) =>
      month < 7 ? 31
          : month < 12 ? 30
          : isLeapYear(year) ? 30 : 29;

  @override int getDaysInYear(int year) => isLeapYear(year) ? _daysPerLeapYear : _daysPerNonLeapYear;
}


/// Persian calendar using the simple 33-year cycle of 1, 5, 9, 13, 17, 22, 26, or 30.
/// This corresponds to System.Globalization.PersianCalendar before .NET 4.6.
@internal
class PersianSimple extends PersianYearMonthDayCalculator {
  // This is a long because we're notionally handling 33 bits. The top bit is
  // false anyway, but IsLeapYear shifts a long for simplicity, so let's be consistent with that.
  static const int _leapYearPatternBits = (1 << 1) | (1 << 5) | (1 << 9) | (1 << 13)
  | (1 << 17) | (1 << 22) | (1 << 26) | (1 << 30);
  static const int _leapYearCycleLength = 33;
  //static const int _daysPerLeapCycle = PersianYearMonthDayCalculator._daysPerNonLeapYear * 25
  //    + PersianYearMonthDayCalculator._daysPerLeapYear * 8;

  /// The ticks for the epoch of March 21st 622CE.
  static const int _daysAtStartOfYear1Constant = -492268;


  PersianSimple() : super._(_daysAtStartOfYear1Constant);

  // todo: is this something we can cut? .. e.g. is this only for .NET compatibility?
  /// Leap year condition using the simple 33-year cycle of 1, 5, 9, 13, 17, 22, 26, or 30.
  /// This corresponds to System.Globalization.PersianCalendar before .NET 4.6.
  @override bool isLeapYear(int year) {
    // Handle negative years in order to make calculations near the start of the calendar work cleanly.
    int yearOfCycle = year >= 0 ? year % _leapYearCycleLength
        : arithmeticMod(year, _leapYearCycleLength) + _leapYearCycleLength;
    // Note the shift of 1L rather than 1, to avoid issues where shifting by 32
    // would get us back to 1.
    // long key = 1L << yearOfCycle;
    // int key = math.pow(2, yearOfCycle);
    int key = yearOfCycle < 32 ? 1 << yearOfCycle : yearOfCycle == 32 ? 4294967296 : yearOfCycle == 33 ? 8589934592 : throw StateError(
        'isLeapYear($year).yearOfCycle = $yearOfCycle failed');
    return (_leapYearPatternBits & key) > 0;
  }
}

/// Persian calendar based on Birashk's subcycle/cycle/grand cycle scheme.
@internal
class PersianArithmetic extends PersianYearMonthDayCalculator {
  PersianArithmetic() : super._(-492267);

  @override bool isLeapYear(int year) {
    // Offset the cycles for easier arithmetic.
    int offsetYear = year > 0 ? year - 474 : year - 473;
    int cycleYear = (offsetYear % 2820) + 474;
    return ((cycleYear + 38) * 31) % 128 < 31;
  }
}

// todo: what?
/// Persian calendar based on stored BCL 4.6 information (avoids complex arithmetic for
/// midday in Tehran).
@internal
class PersianAstronomical extends PersianYearMonthDayCalculator {
  // Ugly, but the simplest way of embedding a big chunk of binary data...
  static final List<int> _astronomicalLeapYearBits = base64.decode(
      'ICIiIkJERESEiIiICBEREREiIiJCREREhIiIiAgRERERIiIiIkRERISIiIiIEBERESEiIiJEREREiIiI'
          'iBAREREhIiIiQkRERISIiIgIERERESIiIkJERESEiIiICBEREREiIiIiRERERIiIiIgQERERISIiIkJE'
          'RESEiIiICBEREREiIiIiREREhIiIiAgRERERISIiIkRERESIiIiIEBERESEiIiJCREREhIiIiAgRERER'
          'IiIiIkRERISIiIgIERERESEiIiJEREREiIiIiBAREREhIiIiQkRERISIiIgIERERESIiIiJEREREiIiI'
          'iBAREREhIiIiQkRERIiIiIgQERERISIiIiJERESEiIiICBEREREiIiIiRERERIiIiIgQERERISIiIkJE'
          'RESEiIiICBEREREiIiIiRERERIiIiAgRERERIiIiIkJERESEiIiIEBERESEiIiJCRERERIiIiAgRERER'
          'IiIiIkRERESIiIiIEBERESEiIiJCREREhIiIiAgREREhIiIiIkRERESIiIiIEBERESIiIiJEREREiIiI'
          'iBAREREhIiIiQkRERISIiIgIERERESIiIiJEREREiIiIiBAREREiIiIiRERERIiIiIgQERERISIiIkJE'
          'RESEiIiICBERESEiIiJCREREhIiIiAgRERERIiIiIkRERESIiIiIEBERESIiIiJEREREiIiIiBAREREh'
          'IiIiQkRERISIiIgIERERISIiIkJERESEiIiICBEREREiIiIiRERERIiIiAgRERERIiIiIkRERESIiIgI'
          'ERERESIiIiJEREREiIiIiBAREREhIiIiQkRERIiIiIgQERERISIiIkJERESIiIiIEBERESEiIiJCRERE'
          'iIiIiBAREREhIiIiQkRERIiIiIgQERERISIiIkRERESIiIiIEBERESIiIiJEREREiIiIiBAREREiIiIi'
          'RERERIiIiAgRERERIiIiIkRERISIiIgIERERESIiIkJERESEiIiIEBERESEiIiJEREREiIiIiBAREREi'
          'IiIiRERERIiIiAgRERERIiIiIkRERISIiIgQERERISIiIkJERESIiIiIEBERESEiIiJERESEiIiICBER'
          'ESEiIiJCREREhIiIiBAREREhIiIiREREhIiIiAgRERERIiIiQkRERIiIiIgQERERIiIiIkRERISIiIgQ'
          'ERERISIiIkRERESIiIgIERERISIiIkJERESIiIiIEBERESIiIkJERESIiIiIEBERESIiIiJERESEiIiI'
          'EBERESEiIiJERESEiIiICBERESEiIiJEREREiIiICBERESEiIiJERESEiIiICBERESEiIiJEREREiIiI'
          'CBERESEiIiJERESEiIiICBERESEiIiJERESEiIiICBERESEiIiJERESEiIiIEBERESIiIiJERESEiIiI'
          'EBERESIiIkJERESIiIgIERERISIiIkRERESIiIgIERERISIiIkRERISIiIgQERERIiIiQkRERIiIiAgR'
          'EREhIiIiREREhIiIiBAREREiIiJCREREiIiICBERESEC'
  );

  PersianAstronomical() : super._(-492267);

  // 8 years per byte.
  @override
  bool isLeapYear(int year) => (_astronomicalLeapYearBits[year >> 3] & (1 << (year & 7))) != 0;
}
