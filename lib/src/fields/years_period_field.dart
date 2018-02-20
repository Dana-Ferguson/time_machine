// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Fields/YearsPeriodField.cs
// ce257e4  on May 24, 2017

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_fields.dart';

/// Period field which uses a <see cref="YearMonthDayCalculator" /> to add/subtract years.
@internal /*sealed*/ class YearsPeriodField implements IDatePeriodField {
  @internal YearsPeriodField();

  LocalDate Add(LocalDate localDate, int value) {
    if (value == 0) {
      return localDate;
    }
    YearMonthDay yearMonthDay = localDate.yearMonthDay;
    var calendar = localDate.Calendar;
    var calculator = calendar.yearMonthDayCalculator;
    int currentYear = yearMonthDay.year;
    // Adjust argument range based on current year
    Preconditions.checkArgumentRange('value', value, calculator.minYear - currentYear, calculator.maxYear - currentYear);
    return new LocalDate.trusted(calculator.setYear(yearMonthDay, currentYear + value).WithCalendarOrdinal(calendar.ordinal));
  }

  int UnitsBetween(LocalDate start, LocalDate end) {
    int diff = end.Year - start.Year;

    // If we just add the difference in years to subtrahendInstant, what do we get?
    LocalDate simpleAddition = Add(start, diff);

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