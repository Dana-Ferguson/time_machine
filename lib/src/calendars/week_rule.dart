// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';

/// A rule determining how 'week years' are arranged, including the weeks within the week year.
/// Implementations provided by Time Machine itself can be obtained via the [WeekYearRules]
/// class.
///
/// Dates are usually identified within a calendar system by a calendar year, a month within that
/// calendar year, and a day within that month. For example, the date of birth of Ada Lovelace can be identified
/// within the Gregorian calendar system as the year 1815, the month December (12), and the day 10. However,
/// dates can also be identified (again within a calendar system) by week-year, week and day-of-week. How
/// that identification occurs depends on which rule you use - but again as an example, within the Gregorian
/// calendar system, using the ISO-8601 week year rule, the date of Ada Lovelace's birth is week-year 1815,
/// week 49, day-of-week Sunday.
///
/// The calendar year of a date and the week-year of a date are the same in most rules for most dates, but aren't
/// always. When they differ, it is usually because a day near the start of the calendar year is deemed to belong
/// to the last week of the previous week-year - or conversely because a day near the end of the calendar year is
/// deemed to belong to the first week of the following week-year. Some rules may be more radical -
/// a UK tax year rule could number weeks from April 6th onwards, such that any date earlier than that in the calendar
/// year would belong to the previous week-year.
///
/// The mapping of dates into week-year, week and day-of-week is always relative to a specific calendar system.
/// For example, years in the Hebrew calendar system vary very significantly in length due to leap months, and this
/// is reflected in the number of weeks within the week-years - as low as 50, and as high as 55.
///
/// This class allows conversions between the two schemes of identifying dates: [GetWeekYear(LocalDate)]
/// and [GetWeekOfWeekYear(LocalDate)] allow the week-year and week to be obtained for a date, and
/// [GetLocalDate(int, int, IsoDayOfWeek, CalendarSystem)] allows the reverse mapping. Note that
/// the calendar system does not need to be specified in the former methods as a [LocalDate] already
/// contains calendar information, and there is no method to obtain the day-of-week as that is not affected by the
/// week year rule being used.
///
/// All implementations within Time Machine are immutable, and it is advised that any external implementations
/// should be immutable too.
@interface
abstract class WeekYearRule {
  /// Creates a [LocalDate] from a given week-year, week within that week-year,
  /// and day-of-week, for the specified calendar system.
  ///
  /// Wherever reasonable, implementations should ensure that all valid dates
  /// can be constructed via this method. In other words, given a [LocalDate] `date`,
  /// [rule.getLocalDate(rule.getWeekYear(date), rule.getWeekOfWeekYear(date), date.isoDayOfWeek, date.calendar)]
  /// should always return `date`. This is true for all rules within Time Machine, but third party
  /// implementations may choose to simplify their implementations by restricting them to appropriate portions
  /// of time.
  ///
  /// Implementations may restrict which calendar systems supplied here, but the implementations provided by
  /// Time Machine work with all available calendar systems.
  ///
  /// * [weekYear]: The week-year of the new date. Implementations provided by Time Machine allow any
  /// year which is a valid calendar year, and sometimes one less than the minimum calendar year
  /// and/or one more than the maximum calendar year, to allow for dates near the start of a calendar
  /// year to fall in the previous week year, and similarly for dates near the end of a calendar year.
  /// * [weekOfWeekYear]: The week of week-year of the new date. Valid values for this parameter
  /// may vary depending on [weekYear], as the length of a year in weeks varies.
  /// * [dayOfWeek]: The day-of-week of the new date. Valid values for this parameter may vary
  /// depending on [weekYear] and [weekOfWeekYear].
  /// * [calendar]: The calendar system for the date.
  ///
  /// Returns: A [LocalDate] corresponding to the specified values.
  ///
  /// * [RangeError]: The parameters do not combine to form a valid date.
  LocalDate getLocalDate(int weekYear, int weekOfWeekYear, DayOfWeek dayOfWeek, CalendarSystem calendar);

  /// Calculates the week-year in which the given date occurs, according to this rule.
  ///
  /// * [date]: The date to compute the week-year of.
  ///
  /// Returns: The week-year of [date], according to this rule.
  int getWeekYear(LocalDate date);

  /// Calculates the week of the week-year in which the given date occurs, according to this rule.
  ///
  /// * [date]: The date to compute the week of.
  ///
  /// Returns: The week of the week-year of [date], according to this rule.
  int getWeekOfWeekYear(LocalDate date);

  /// Returns the number of weeks in the given week-year, within the specified calendar system.
  ///
  /// * [weekYear]: The week-year to find the range of.
  /// * [calendar]: The calendar system the calculation is relative to.
  ///
  /// Returns: The number of weeks in the given week-year within the given calendar.
  int getWeeksInWeekYear(int weekYear, CalendarSystem calendar);
}

// todo: No extension methods in Dart ... look at ergonomics here ... Looks like this are just CalendarSystem.iso defaults
/// Extension methods on [WeekYearRule].
abstract class WeekYearRuleExtensions {
  /// Convenience method to call [WeekYearRule.getLocalDate(int, int, IsoDayOfWeek, CalendarSystem)]
  /// passing in the ISO calendar system.
  ///
  /// * [rule]: The rule to delegate the call to.
  /// * [weekYear]: The week-year of the new date. Implementations provided by Time Machine allow any
  /// year which is a valid calendar year, and sometimes one less than the minimum calendar year
  /// and/or one more than the maximum calendar year, to allow for dates near the start of a calendar
  /// year to fall in the previous week year, and similarly for dates near the end of a calendar year.
  /// * [weekOfWeekYear]: The week of week-year of the new date. Valid values for this parameter
  /// may vary depending on [weekYear], as the length of a year in weeks varies.
  /// * [dayOfWeek]: The day-of-week of the new date. Valid values for this parameter may vary
  /// depending on [weekYear] and [weekOfWeekYear].
  ///
  /// Returns: A [LocalDate] corresponding to the specified values.
  ///
  /// * [RangeError]: The parameters do not combine to form a valid date.
  static LocalDate getLocalDate(WeekYearRule rule, int weekYear, int weekOfWeekYear, DayOfWeek dayOfWeek) =>
      Preconditions.checkNotNull(rule, 'rule').getLocalDate(weekYear, weekOfWeekYear, dayOfWeek, CalendarSystem.iso);

  /// Convenience overload to call [IWeekYearRule.GetWeeksInWeekYear(int, CalendarSystem)] with
  /// the ISO calendar system.
  ///
  /// * [rule]: The rule to delegate the call to.
  /// * [weekYear]: The week year to calculate the number of contained weeks.
  ///
  /// Returns: The number of weeks in the given week year.
  static int getWeeksInWeekYear(WeekYearRule rule, int weekYear) =>
      Preconditions.checkNotNull(rule, 'rule').getWeeksInWeekYear(weekYear, CalendarSystem.iso);
}
