// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

@internal
class CopticYearMonthDayCalculator extends FixedMonthYearMonthDayCalculator {
  CopticYearMonthDayCalculator()
      : super(1, 9715, -615558);

  @protected
  @override
  int calculateStartOfYearDays(int year) {
    // Unix epoch is 1970-01-01 Gregorian which is 1686-04-23 Coptic.
    // Calculate relative to the nearest leap year and account for the
    // difference later.

    int relativeYear = year - 1687;
    int leapYears;
    if (relativeYear <= 0) {
      // Add 3 before shifting right since /4 and >>2 behave differently
      // on negative numbers.
      leapYears = safeRightShift(relativeYear + 3, 2);
    }
    else {
      leapYears = safeRightShift(relativeYear, 2);
      // For post 1687 an adjustment is needed as jan1st is before leap day
      if (!isLeapYear(year)) {
        leapYears++;
      }
    }

    int ret = relativeYear * 365 + leapYears;

    // Adjust to account for difference between 1687-01-01 and 1686-04-23.
    return ret + (365 - 112);
  }
}
