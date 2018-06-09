// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

import 'package:time_machine/time_machine.dart';

/// Factory class for date adjusters: functions from [LocalDate] to `LocalDate`,
/// which can be applied to [LocalDate], [LocalDateTime], and [OffsetDateTime].
@immutable
class DateAdjusters {

  /// A date adjuster to move to the first day of the current month.
  ///
  /// <value>
  /// A date adjuster to move to the first day of the current month.
  /// </value>
  static final LocalDate Function(LocalDate) StartOfMonth =
      (date) => new LocalDate.forCalendar(date.Year, date.Month, 1, date.Calendar);


  /// A date adjuster to move to the last day of the current month.
  ///
  /// <value>
  /// A date adjuster to move to the last day of the current month.
  /// </value>
  static final LocalDate Function(LocalDate) EndOfMonth =
      (date) => new LocalDate.forCalendar(date.Year, date.Month, date.Calendar.GetDaysInMonth(date.Year, date.Month), date.Calendar);


  /// A date adjuster to move to the specified day of the current month.
  ///
  /// The returned adjuster will throw an exception if it is applied to a date
  /// that would create an invalid result.
  ///
  /// [day]: The day of month to adjust dates to.
  /// An adjuster which changes the day to [day],
  /// retaining the same year and month.
  static LocalDate Function(LocalDate) DayOfMonth(int day) =>
          (date) => new LocalDate.forCalendar(date.Year, date.Month, day, date.Calendar);


  /// A date adjuster to move to the same day of the specified month.
  ///
  /// The returned adjuster will throw an exception if it is applied to a date
  /// that would create an invalid result.
  ///
  /// [month]: The month to adjust dates to.
  /// An adjuster which changes the month to [month],
  /// retaining the same year and day of month.
  static LocalDate Function(LocalDate) Month(int month) =>
          (date) => new LocalDate.forCalendar(date.Year, month, date.Day, date.Calendar);


  /// A date adjuster to move to the next specified day-of-week, but return the
  /// original date if the day is already correct.
  ///
  /// [dayOfWeek]: The day-of-week to adjust dates to.
  /// An adjuster which advances a date to the next occurrence of the
  /// specified day-of-week, or the original date if the day is already corret.
  static LocalDate Function(LocalDate) NextOrSame(IsoDayOfWeek dayOfWeek) {
    // Avoids boxing...
    if (dayOfWeek < IsoDayOfWeek.monday || dayOfWeek > IsoDayOfWeek.sunday) {
      throw new RangeError.range(dayOfWeek.value, IsoDayOfWeek.monday.value, IsoDayOfWeek.sunday.value, 'dayOfWeek');
    }
    return (date) => date.DayOfWeek == dayOfWeek ? date : date.Next(dayOfWeek);
  }


  /// A date adjuster to move to the previous specified day-of-week, but return the
  /// original date if the day is already correct.
  ///
  /// [dayOfWeek]: The day-of-week to adjust dates to.
  /// An adjuster which advances a date to the previous occurrence of the
  /// specified day-of-week, or the original date if the day is already corret.
  static LocalDate Function(LocalDate) PreviousOrSame(IsoDayOfWeek dayOfWeek) {
    // Avoids boxing...
    if (dayOfWeek < IsoDayOfWeek.monday || dayOfWeek > IsoDayOfWeek.sunday) {
      throw new RangeError.range(dayOfWeek.value, IsoDayOfWeek.monday.value, IsoDayOfWeek.sunday.value, 'dayOfWeek');
    }
    return (date) => date.DayOfWeek == dayOfWeek ? date : date.Previous(dayOfWeek);
  }


  /// A date adjuster to move to the next specified day-of-week, adding
  /// a week if the day is already correct.
  ///
  /// This is the adjuster equivalent of [LocalDate.Next].
  ///
  /// [dayOfWeek]: The day-of-week to adjust dates to.
  /// An adjuster which advances a date to the next occurrence of the
  /// specified day-of-week.
  static LocalDate Function(LocalDate) Next(IsoDayOfWeek dayOfWeek) {
    // Avoids boxing...
    if (dayOfWeek < IsoDayOfWeek.monday || dayOfWeek > IsoDayOfWeek.sunday) {
      throw new RangeError.range(dayOfWeek.value, IsoDayOfWeek.monday.value, IsoDayOfWeek.sunday.value, 'dayOfWeek');
    }
    return (date) => date.Next(dayOfWeek);
  }


  /// A date adjuster to move to the previous specified day-of-week, subtracting
  /// a week if the day is already correct.
  ///
  /// This is the adjuster equivalent of [LocalDate.Previous].
  ///
  /// [dayOfWeek]: The day-of-week to adjust dates to.
  /// An adjuster which advances a date to the previous occurrence of the
  /// specified day-of-week.
  static LocalDate Function(LocalDate) Previous(IsoDayOfWeek dayOfWeek) {
    // Avoids boxing...
    if (dayOfWeek < IsoDayOfWeek.monday || dayOfWeek > IsoDayOfWeek.sunday) {
      throw new RangeError.range(dayOfWeek.value, IsoDayOfWeek.monday.value, IsoDayOfWeek.sunday.value, 'dayOfWeek');
    }
    return (date) => date.Previous(dayOfWeek);
  }
}
