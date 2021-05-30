// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';

/// Conversions between civil and scriptural month numbers in the Hebrew calendar system.
@internal
abstract class HebrewMonthConverter {
  /// Given a civil month number and a year in which it occurs, this method returns
  /// the equivalent scriptural month number.
  ///
  /// No validation is performed in this method: an input month number of 13 in a non-leap-year
  /// will return a result of 7.
  ///
  /// [year]: Year during which the month occurs.  
  /// [month]: Civil month number.  
  /// returns: The scriptural month number.
  static int civilToScriptural(int year, int month)
  {
    if (month < 7)
    {
      return month + 6;
    }
    bool leapYear = HebrewScripturalCalculator.isLeapYear(year);
    if (month == 7) // Adar II (13) or Nisan (1) depending on whether it's a leap year.
        {
      return leapYear ? 13 : 1;
    }
    return leapYear ? month - 7 : month - 6;
  }

  /// Given an scriptural month number and a year in which it occurs, this method returns
  /// the equivalent scriptural month number.
  ///
  /// No validation is performed in this method: an input month number of 13 in a non-leap-year
  /// will return a result of 7.
  ///
  /// [year]: Year during which the month occurs.  
  /// [month]: Scriptural month number.  
  /// returns: The civil month number.
  static int scripturalToCivil(int year, int month)
  {
    if (month >= 7)
    {
      return month - 6;
    }
    return HebrewScripturalCalculator.isLeapYear(year) ? month + 7 : month + 6;
  }
}
