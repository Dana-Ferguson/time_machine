// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Fields/MonthsPeriodField.cs
// ce257e4  on May 24, 2017

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_fields.dart';

/// Period field which uses a <see cref="YearMonthDayCalculator" /> to add/subtract months.
@internal /*sealed*/ class MonthsPeriodField implements IDatePeriodField {
  @internal MonthsPeriodField();

  LocalDate Add(LocalDate localDate, int value) {
    var calendar = localDate.Calendar;
    var calculator = calendar.yearMonthDayCalculator;
    var yearMonthDay = calculator.addMonths(localDate.yearMonthDay, value);
    return new LocalDate.trusted(yearMonthDay.WithCalendar(calendar));
  }

  int UnitsBetween(LocalDate start, LocalDate end) =>
      start.Calendar.yearMonthDayCalculator.monthsBetween(start.yearMonthDay, end.yearMonthDay);
}
