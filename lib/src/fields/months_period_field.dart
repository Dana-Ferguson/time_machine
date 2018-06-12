// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_fields.dart';

/// Period field which uses a [YearMonthDayCalculator] to add/subtract months.
@internal /*sealed*/ class MonthsPeriodField implements IDatePeriodField {
  @internal MonthsPeriodField();

  LocalDate add(LocalDate localDate, int value) {
    var calendar = localDate.calendar;
    var calculator = calendar.yearMonthDayCalculator;
    var yearMonthDay = calculator.addMonths(localDate.yearMonthDay, value);
    return new LocalDate.trusted(yearMonthDay.withCalendar(calendar));
  }

  int unitsBetween(LocalDate start, LocalDate end) =>
      start.calendar.yearMonthDayCalculator.monthsBetween(start.yearMonthDay, end.yearMonthDay);
}

