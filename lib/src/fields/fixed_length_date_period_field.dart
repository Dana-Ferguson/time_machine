// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';
import 'package:time_machine/src/fields/time_machine_fields.dart';

/// Date period field for fixed-length periods (weeks and days).
@immutable
@internal
class FixedLengthDatePeriodField implements IDatePeriodField {
  final int _unitDays;

  const FixedLengthDatePeriodField(this._unitDays);
  
  @override
  LocalDate add(LocalDate localDate, int value) {
    if (value == 0) {
      return localDate;
    }
    int daysToAdd = value * _unitDays;
    var calendar = localDate.calendar;
    // If we know it will be in this year, next year, or the previous year...
    if (daysToAdd < 300 && daysToAdd > -300) {
      YearMonthDayCalculator calculator = ICalendarSystem.yearMonthDayCalculator(calendar);
      YearMonthDay yearMonthDay = ILocalDate.yearMonthDay(localDate);
      int year = yearMonthDay.year;
      int month = yearMonthDay.month;
      int day = yearMonthDay.day;
      int newDayOfMonth = day + daysToAdd;
      if (1 <= newDayOfMonth && newDayOfMonth <= calculator.getDaysInMonth(year, month)) {
        return ILocalDate.trusted(YearMonthDayCalendar(year, month, newDayOfMonth, ICalendarSystem.ordinal(calendar)));
      }
      int dayOfYear = calculator.getDayOfYear(yearMonthDay);
      int newDayOfYear = dayOfYear + daysToAdd;

      if (newDayOfYear < 1) {
        newDayOfYear += calculator.getDaysInYear(year - 1);
        year--;
        if (year < calculator.minYear) {
          throw RangeError('Date computation would underflow the minimum year of the calendar');
        }
      }
      else {
        int daysInYear = calculator.getDaysInYear(year);
        if (newDayOfYear > daysInYear) {
          newDayOfYear -= daysInYear;
          year++;
          if (year > calculator.maxYear) {
            throw RangeError('Date computation would overflow the maximum year of the calendar');
          }
        }
      }
      return ILocalDate.trusted(calculator.getYearMonthDay(year, newDayOfYear).withCalendarOrdinal(ICalendarSystem.ordinal(calendar)));
    }
    // LocalDate constructor will validate.
    int days = localDate.epochDay + daysToAdd;
    return LocalDate.fromEpochDay(days, calendar);
  }

  @override
  int unitsBetween(LocalDate start, LocalDate end) =>
      IPeriod.daysBetween(start, end) ~/ _unitDays;
}
