// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/fields/time_machine_fields.dart';

/// Period field which uses a [YearMonthDayCalculator] to add/subtract months.
@internal
class MonthsPeriodField implements IDatePeriodField {
  const MonthsPeriodField();

  @override
  LocalDate add(LocalDate localDate, int value) {
    var calendar = localDate.calendar;
    var calculator = ICalendarSystem.yearMonthDayCalculator(calendar);
    var yearMonthDay = calculator.addMonths(ILocalDate.yearMonthDay(localDate), value);
    return ILocalDate.trusted(yearMonthDay.withCalendar(calendar));
  }

  @override
  int unitsBetween(LocalDate start, LocalDate end) =>
      ICalendarSystem.yearMonthDayCalculator(start.calendar).monthsBetween(ILocalDate.yearMonthDay(start), ILocalDate.yearMonthDay(end));
}

