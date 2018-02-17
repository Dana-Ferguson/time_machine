// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/DateAdjusters.cs
// 24fdeef  on Apr 10, 2017

import 'package:meta/meta.dart';

import 'package:time_machine/time_machine.dart';

/// Factory class for date adjusters: functions from <see cref="LocalDate"/> to <c>LocalDate</c>,
/// which can be applied to <see cref="LocalDate"/>, <see cref="LocalDateTime"/>, and <see cref="OffsetDateTime"/>.
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
  /// <remarks>
  /// The returned adjuster will throw an exception if it is applied to a date
  /// that would create an invalid result.
  /// </remarks>
  /// <param name="day">The day of month to adjust dates to.</param>
  /// <returns>An adjuster which changes the day to <paramref name="day"/>,
  /// retaining the same year and month.</returns>
  static LocalDate Function(LocalDate) DayOfMonth(int day) =>
          (date) => new LocalDate.forCalendar(date.Year, date.Month, day, date.Calendar);


  /// A date adjuster to move to the same day of the specified month.
  /// 
  /// <remarks>
  /// The returned adjuster will throw an exception if it is applied to a date
  /// that would create an invalid result.
  /// </remarks>
  /// <param name="month">The month to adjust dates to.</param>
  /// <returns>An adjuster which changes the month to <paramref name="month"/>,
  /// retaining the same year and day of month.</returns>
  static LocalDate Function(LocalDate) Month(int month) =>
          (date) => new LocalDate.forCalendar(date.Year, month, date.Day, date.Calendar);


  /// A date adjuster to move to the next specified day-of-week, but return the
  /// original date if the day is already correct.
  /// 
  /// <param name="dayOfWeek">The day-of-week to adjust dates to.</param>
  /// <returns>An adjuster which advances a date to the next occurrence of the
  /// specified day-of-week, or the original date if the day is already corret.</returns>
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
  /// <param name="dayOfWeek">The day-of-week to adjust dates to.</param>
  /// <returns>An adjuster which advances a date to the previous occurrence of the
  /// specified day-of-week, or the original date if the day is already corret.</returns>
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
  /// <remarks>
  /// This is the adjuster equivalent of <see cref="LocalDate.Next"/>.
  /// </remarks>
  /// <param name="dayOfWeek">The day-of-week to adjust dates to.</param>
  /// <returns>An adjuster which advances a date to the next occurrence of the
  /// specified day-of-week.</returns>
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
  /// <remarks>
  /// This is the adjuster equivalent of <see cref="LocalDate.Previous"/>.
  /// </remarks>
  /// <param name="dayOfWeek">The day-of-week to adjust dates to.</param>
  /// <returns>An adjuster which advances a date to the previous occurrence of the
  /// specified day-of-week.</returns>
  static LocalDate Function(LocalDate) Previous(IsoDayOfWeek dayOfWeek) {
    // Avoids boxing...
    if (dayOfWeek < IsoDayOfWeek.monday || dayOfWeek > IsoDayOfWeek.sunday) {
      throw new RangeError.range(dayOfWeek.value, IsoDayOfWeek.monday.value, IsoDayOfWeek.sunday.value, 'dayOfWeek');
    }
    return (date) => date.Previous(dayOfWeek);
  }
}