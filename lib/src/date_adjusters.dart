// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

import 'package:time_machine/src/time_machine_internal.dart';

/// Factory class for date adjusters: functions from [LocalDate] to `LocalDate`,
/// which can be applied to [LocalDate], [LocalDateTime], and [OffsetDateTime].
@immutable
class DateAdjusters {

  /// A date adjuster to move to the first day of the current month.
  static final LocalDate Function(LocalDate) startOfMonth =
      (date) => new LocalDate(date.year, date.month, 1, date.calendar);


  /// A date adjuster to move to the last day of the current month.
  static final LocalDate Function(LocalDate) endOfMonth =
      (date) => new LocalDate(date.year, date.month, date.calendar.getDaysInMonth(date.year, date.month), date.calendar);


  /// A date adjuster to move to the specified day of the current month.
  ///
  /// The returned adjuster will throw an exception if it is applied to a date
  /// that would create an invalid result.
  ///
  /// [day]: The day of month to adjust dates to.
  /// An adjuster which changes the day to [day],
  /// retaining the same year and month.
  static LocalDate Function(LocalDate) dayOfMonth(int day) =>
          (date) => new LocalDate(date.year, date.month, day, date.calendar);


  /// A date adjuster to move to the same day of the specified month.
  ///
  /// The returned adjuster will throw an exception if it is applied to a date
  /// that would create an invalid result.
  ///
  /// [month]: The month to adjust dates to.
  /// An adjuster which changes the month to [month],
  /// retaining the same year and day of month.
  static LocalDate Function(LocalDate) month(int month) =>
          (date) => new LocalDate(date.year, month, date.day, date.calendar);


  /// A date adjuster to move to the next specified day-of-week, but return the
  /// original date if the day is already correct.
  ///
  /// [dayOfWeek]: The day-of-week to adjust dates to.
  /// An adjuster which advances a date to the next occurrence of the
  /// specified day-of-week, or the original date if the day is already corret.
  static LocalDate Function(LocalDate) nextOrSame(IsoDayOfWeek dayOfWeek) {
    // Avoids boxing...
    if (dayOfWeek < IsoDayOfWeek.monday || dayOfWeek > IsoDayOfWeek.sunday) {
      throw new RangeError.range(dayOfWeek.value, IsoDayOfWeek.monday.value, IsoDayOfWeek.sunday.value, 'dayOfWeek');
    }
    return (date) => date.dayOfWeek == dayOfWeek ? date : date.next(dayOfWeek);
  }


  /// A date adjuster to move to the previous specified day-of-week, but return the
  /// original date if the day is already correct.
  ///
  /// [dayOfWeek]: The day-of-week to adjust dates to.
  /// An adjuster which advances a date to the previous occurrence of the
  /// specified day-of-week, or the original date if the day is already corret.
  static LocalDate Function(LocalDate) previousOrSame(IsoDayOfWeek dayOfWeek) {
    // Avoids boxing...
    if (dayOfWeek < IsoDayOfWeek.monday || dayOfWeek > IsoDayOfWeek.sunday) {
      throw new RangeError.range(dayOfWeek.value, IsoDayOfWeek.monday.value, IsoDayOfWeek.sunday.value, 'dayOfWeek');
    }
    return (date) => date.dayOfWeek == dayOfWeek ? date : date.previous(dayOfWeek);
  }


  /// A date adjuster to move to the next specified day-of-week, adding
  /// a week if the day is already correct.
  ///
  /// This is the adjuster equivalent of [LocalDate.next].
  ///
  /// [dayOfWeek]: The day-of-week to adjust dates to.
  /// An adjuster which advances a date to the next occurrence of the
  /// specified day-of-week.
  static LocalDate Function(LocalDate) next(IsoDayOfWeek dayOfWeek) {
    // Avoids boxing...
    if (dayOfWeek < IsoDayOfWeek.monday || dayOfWeek > IsoDayOfWeek.sunday) {
      throw new RangeError.range(dayOfWeek.value, IsoDayOfWeek.monday.value, IsoDayOfWeek.sunday.value, 'dayOfWeek');
    }
    return (date) => date.next(dayOfWeek);
  }


  /// A date adjuster to move to the previous specified day-of-week, subtracting
  /// a week if the day is already correct.
  ///
  /// This is the adjuster equivalent of [LocalDate.previous].
  ///
  /// [dayOfWeek]: The day-of-week to adjust dates to.
  /// An adjuster which advances a date to the previous occurrence of the
  /// specified day-of-week.
  static LocalDate Function(LocalDate) previous(IsoDayOfWeek dayOfWeek) {
    // Avoids boxing...
    if (dayOfWeek < IsoDayOfWeek.monday || dayOfWeek > IsoDayOfWeek.sunday) {
      throw new RangeError.range(dayOfWeek.value, IsoDayOfWeek.monday.value, IsoDayOfWeek.sunday.value, 'dayOfWeek');
    }
    return (date) => date.previous(dayOfWeek);
  }
}
