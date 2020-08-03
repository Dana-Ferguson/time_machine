// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';

// todo: I.O.U. better API Documentation
// https://msdn.microsoft.com/en-us/library/system.globalization.calendarweekrule(v=vs.110).aspx
enum CalendarWeekRule {
  firstDay,
  firstFullWeek,
  firstFourDayWeek
}

/// Factory methods to construct week-year rules supported by Time Machine.
abstract class WeekYearRules {
  /// Returns an [WeekYearRule] consistent with ISO-8601.
  ///
  /// In the standard ISO-8601 week algorithm, the first week of the year
  /// is that in which at least 4 days are in the year. As a result of this
  /// definition, day 1 of the first week may be in the previous year. In ISO-8601,
  /// weeks always begin on a Monday, so this rule is equivalent to the first Thursday
  /// being in the first Monday-to-Sunday week of the year.
  ///
  /// For example, January 1st 2011 was a Saturday, so only two days of that week
  /// (Saturday and Sunday) were in 2011. Therefore January 1st is part of
  /// week 52 of week-year 2010. Conversely, December 31st 2012 is a Monday,
  /// so is part of week 1 of week-year 2013.
  static final WeekYearRule iso = SimpleWeekYearRule(4, DayOfWeek.monday, false);

  /// Creates a week year rule where the boundary between one week-year and the next
  /// is parameterized in terms of how many days of the first week of the week
  /// year have to be in the new calendar year, and also by which day is deemed
  /// to be the first day of the week. This is Monday by default.
  ///
  /// [minDaysInFirstWeek] determines when the first week of the week-year starts.
  /// For any given calendar year X, consider the week that includes the first day of the
  /// calendar year. Usually, some days of that week are in calendar year X, and some are in calendar year
  /// X-1. If [minDaysInFirstWeek] or more of the days are in year X, then the week is
  /// deemed to be the first week of week-year X. Otherwise, the week is deemed to be the last week of
  /// week-year X-1, and the first week of week-year X starts on the following [firstDayOfWeek].
  ///
  /// * [minDaysInFirstWeek]: The minimum number of days in the first week (starting on
  /// [firstDayOfWeek]) which have to be in the new calendar year for that week
  /// to count as being in that week-year. Must be in the range 1 to 7 inclusive.
  /// * [firstDayOfWeek]: The first day of the week.
  ///
  /// A [SimpleWeekYearRule] with the specified minimum number of days in the first
  /// week and first day of the week.
  static WeekYearRule forMinDaysInFirstWeek(int minDaysInFirstWeek, [DayOfWeek firstDayOfWeek = DayOfWeek.monday])
  => SimpleWeekYearRule(minDaysInFirstWeek, firstDayOfWeek, false);

  // todo: BCL references... investigate?

  /// Creates a rule which behaves the same way as the BCL
  /// [Calendar.getWeekOfYear(DateTime, CalendarWeekRule, DayOfWeek)]
  /// method.
  ///
  /// The BCL week year rules are subtly different to the ISO rules.
  /// In particular, the last few days of the calendar year are always part of the same
  /// week-year in the BCL rules, whereas in the ISO rules they can fall into the next
  /// week-year. (The first few days of the calendar year can be part of the previous
  /// week-year in both kinds of rule.) This means that in the BCL rules, some weeks
  /// are incomplete, whereas ISO weeks are always exactly 7 days long.
  ///
  /// * [calendarWeekRule]: The BCL rule to emulate.
  /// * [firstDayOfWeek]: The first day of the week to use in the rule.
  /// A rule which behaves the same way as the BCL
  /// [Calendar.GetWeekOfYear(DateTime, CalendarWeekRule, DayOfWeek)]
  /// method.
  static WeekYearRule fromCalendarWeekRule(CalendarWeekRule calendarWeekRule, DayOfWeek firstDayOfWeek) {
    int minDaysInFirstWeek;
    switch (calendarWeekRule) {
      case CalendarWeekRule.firstDay:
        minDaysInFirstWeek = 1;
        break;
      case CalendarWeekRule.firstFourDayWeek:
        minDaysInFirstWeek = 4;
        break;
      case CalendarWeekRule.firstFullWeek:
        minDaysInFirstWeek = 7;
        break;
      default:
        throw ArgumentError('Unsupported CalendarWeekRule: $calendarWeekRule');
    }
    return SimpleWeekYearRule(minDaysInFirstWeek, firstDayOfWeek, true);
  }
}


