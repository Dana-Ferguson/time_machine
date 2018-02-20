// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Calendars/WeekYearRules.cs
// 9aa4e04  on Apr 14, 2017

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';

// https://msdn.microsoft.com/en-us/library/system.globalization.calendarweekrule(v=vs.110).aspx
// todo: if this has no advanced usage anywhere, we can leave it as this.
enum CalendarWeekRule {
  FirstDay,
  FirstFullWeek,
  FirstFourDayWeek
}

/// Factory methods to construct week-year rules supported by Noda Time.
abstract class WeekYearRules
{
  /// <summary>
  /// Returns an <see cref="IWeekYearRule"/> consistent with ISO-8601.
  /// </summary>
  /// <remarks>
  /// <para>
  /// In the standard ISO-8601 week algorithm, the first week of the year
  /// is that in which at least 4 days are in the year. As a result of this
  /// definition, day 1 of the first week may be in the previous year. In ISO-8601,
  /// weeks always begin on a Monday, so this rule is equivalent to the first Thursday
  /// being in the first Monday-to-Sunday week of the year.
  /// </para>
  /// <para>
  /// For example, January 1st 2011 was a Saturday, so only two days of that week
  /// (Saturday and Sunday) were in 2011. Therefore January 1st is part of
  /// week 52 of week-year 2010. Conversely, December 31st 2012 is a Monday,
  /// so is part of week 1 of week-year 2013.
  /// </para>
  /// </remarks>
  /// <value>A <see cref="IWeekYearRule"/> consistent with ISO-8601.</value>
  static final IWeekYearRule Iso = new SimpleWeekYearRule(4, IsoDayOfWeek.monday, false);

  /// <summary>
  /// Creates a week year rule where the boundary between one week-year and the next
  /// is parameterized in terms of how many days of the first week of the week
  /// year have to be in the new calendar year, and also by which day is deemed
  /// to be the first day of the week. This is Monday by default.
  /// </summary>
  /// <remarks>
  /// <paramref name="minDaysInFirstWeek"/> determines when the first week of the week-year starts.
  /// For any given calendar year X, consider the week that includes the first day of the
  /// calendar year. Usually, some days of that week are in calendar year X, and some are in calendar year
  /// X-1. If <paramref name="minDaysInFirstWeek"/> or more of the days are in year X, then the week is
  /// deemed to be the first week of week-year X. Otherwise, the week is deemed to be the last week of
  /// week-year X-1, and the first week of week-year X starts on the following <paramref name="firstDayOfWeek"/>.
  /// </remarks>
  /// <param name="minDaysInFirstWeek">The minimum number of days in the first week (starting on
  /// <paramref name="firstDayOfWeek" />) which have to be in the new calendar year for that week
  /// to count as being in that week-year. Must be in the range 1 to 7 inclusive.
  /// </param>
  /// <param name="firstDayOfWeek">The first day of the week.</param>
  /// <returns>A <see cref="SimpleWeekYearRule"/> with the specified minimum number of days in the first
  /// week and first day of the week.</returns>
  static IWeekYearRule ForMinDaysInFirstWeek(int minDaysInFirstWeek, [IsoDayOfWeek firstDayOfWeek = IsoDayOfWeek.monday])
  => new SimpleWeekYearRule(minDaysInFirstWeek, firstDayOfWeek, false);

  /// <summary>
  /// Creates a rule which behaves the same way as the BCL
  /// <see cref="Calendar.GetWeekOfYear(DateTime, CalendarWeekRule, DayOfWeek)"/>
  /// method.
  /// </summary>
  /// <remarks>The BCL week year rules are subtly different to the ISO rules.
  /// In particular, the last few days of the calendar year are always part of the same
  /// week-year in the BCL rules, whereas in the ISO rules they can fall into the next
  /// week-year. (The first few days of the calendar year can be part of the previous
  /// week-year in both kinds of rule.) This means that in the BCL rules, some weeks
  /// are incomplete, whereas ISO weeks are always exactly 7 days long.
  /// </remarks>
  /// <param name="calendarWeekRule">The BCL rule to emulate.</param>
  /// <param name="firstDayOfWeek">The first day of the week to use in the rule.</param>
  /// <returns>A rule which behaves the same way as the BCL
  /// <see cref="Calendar.GetWeekOfYear(DateTime, CalendarWeekRule, DayOfWeek)"/>
  /// method.</returns>
  static IWeekYearRule FromCalendarWeekRule(CalendarWeekRule calendarWeekRule, IsoDayOfWeek firstDayOfWeek) {
    int minDaysInFirstWeek;
    switch (calendarWeekRule) {
      case CalendarWeekRule.FirstDay:
        minDaysInFirstWeek = 1;
        break;
      case CalendarWeekRule.FirstFourDayWeek:
        minDaysInFirstWeek = 4;
        break;
      case CalendarWeekRule.FirstFullWeek:
        minDaysInFirstWeek = 7;
        break;
      default:
        throw new ArgumentError("Unsupported CalendarWeekRule: $calendarWeekRule");
    }
    return new SimpleWeekYearRule(minDaysInFirstWeek, firstDayOfWeek, true);
  }
}

