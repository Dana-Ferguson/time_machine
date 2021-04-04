// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/fields/time_machine_fields.dart';

/// Period field which uses a [YearMonthDayCalculator] to add/subtract years.
@internal class YearsPeriodField implements IDatePeriodField {
  const YearsPeriodField();

  @override
  LocalDate add(LocalDate localDate, int value) {
    if (value == 0) {
      return localDate;
    }
    YearMonthDay yearMonthDay = ILocalDate.yearMonthDay(localDate);
    var calendar = localDate.calendar;
    var calculator = ICalendarSystem.yearMonthDayCalculator(calendar);
    int currentYear = yearMonthDay.year;
    // Adjust argument range based on current year
    Preconditions.checkArgumentRange('value', value, calculator.minYear - currentYear, calculator.maxYear - currentYear);
    return ILocalDate.trusted(calculator.setYear(yearMonthDay, currentYear + value).withCalendarOrdinal(ICalendarSystem.ordinal(calendar)));
  }

  @override
  int unitsBetween(LocalDate start, LocalDate end) {
    int diff = end.year - start.year;

    // If we just add the difference in years to subtrahendInstant, what do we get?
    LocalDate simpleAddition = add(start, diff);

    if (start <= end) {
      // Moving forward: if the result of the simple addition is before or equal to the end,
      // we're done. Otherwise, rewind a year because we've overshot.
      return simpleAddition <= end ? diff : diff - 1;
    }
    else {
      // Moving backward: if the result of the simple addition (of a non-positive number)
      // is after or equal to the end, we're done. Otherwise, increment by a year because
      // we've overshot backwards.
      return simpleAddition >= end ? diff : diff + 1;
    }
  }
}
