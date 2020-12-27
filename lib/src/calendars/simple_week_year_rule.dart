// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';

/// Implements [WeekYearRule] for a rule where weeks are regular:
/// every week has exactly 7 days, which means that some week years straddle
/// the calendar year boundary. (So the start of a week can occur in one calendar
/// year, and the end of the week in the following calendar year, but the whole
/// week is in the same week-year.)
@immutable
@internal
class SimpleWeekYearRule implements WeekYearRule {
  final int _minDaysInFirstWeek;
  final DayOfWeek _firstDayOfWeek;

  /// If true, the boundary of a calendar year sometimes splits a week in half. The
  /// last day of the calendar year is *always* in the last week of the same week-year, but
  /// the first day of the calendar year *may* be in the last week of the previous week-year.
  /// (Basically, the rule works out when the first day of the week-year would be logically,
  /// and then cuts it off so that it's never in the previous calendar year.)
  ///
  /// If false, all weeks are 7 days long, including across calendar-year boundaries.
  /// This is the state for ISO-like rules.
  final bool _irregularWeeks;

  SimpleWeekYearRule(this._minDaysInFirstWeek, this._firstDayOfWeek, this._irregularWeeks) {
    Preconditions.debugCheckArgumentRange('minDaysInFirstWeek', _minDaysInFirstWeek, 1, 7);
    Preconditions.checkArgumentRange('firstDayOfWeek', _firstDayOfWeek.value, 1, 7);
  }

  /// <inheritdoc />
  @override
  LocalDate getLocalDate(int weekYear, int weekOfWeekYear, DayOfWeek dayOfWeek, CalendarSystem calendar) {
    Preconditions.checkNotNull(calendar, 'calendar');
    _validateWeekYear(weekYear, calendar);

    // The actual message for this won't be ideal, but it's clear enough.
    Preconditions.checkArgumentRange('dayOfWeek', dayOfWeek.value, 1, 7);

    var yearMonthDayCalculator = ICalendarSystem.yearMonthDayCalculator(calendar);
    var maxWeeks = getWeeksInWeekYear(weekYear, calendar);
    if (weekOfWeekYear < 1 || weekOfWeekYear > maxWeeks) {
      throw RangeError.value(weekOfWeekYear, 'weekOfWeekYear');
    }

    int startOfWeekYear = _getWeekYearDaysSinceEpoch(yearMonthDayCalculator, weekYear);
    // 0 for 'already on the first day of the week' up to 6 "it's the last day of the week".
    int daysIntoWeek = ((dayOfWeek - _firstDayOfWeek) + 7) % 7;
    int days = startOfWeekYear + (weekOfWeekYear - 1) * 7 + daysIntoWeek;
    if (days < ICalendarSystem.minDays(calendar) || days > ICalendarSystem.maxDays(calendar)) {
      throw ArgumentError.value(weekYear, 'weekYear', "The combination of weekYear, weekOfWeekYear and dayOfWeek is invalid");
    }
    LocalDate ret = ILocalDate.trusted(yearMonthDayCalculator.getYearMonthDayFromDaysSinceEpoch(days).withCalendar(calendar));

    // For rules with irregular weeks, the calculation so far may end up computing a date which isn't
    // in the right week-year. This will happen if the caller has specified a 'short' week (i.e. one
    // at the start or end of the week-year which is not seven days long due to the week year changing
    // part way through a week) and a day-of-week which corresponds to the 'missing' part of the week.
    // Examples are in SimpleWeekYearRuleTest.GetLocalDate_Invalid.
    // The simplest way to find out is just to check what the week year is, but we only need to do
    // the full check if the requested week-year is different to the calendar year of the result.
    // We don't need to check for this in regular rules, because the computation we've already performed
    // will always be right.
    if (_irregularWeeks && weekYear != ret.year) {
      if (getWeekYear(ret) != weekYear) {
        throw ArgumentError.value(weekYear, 'weekYear',
            'The combination of weekYear, weekOfWeekYear and dayOfWeek is invalid');
      }
    }
    return ret;
  }

  /// <inheritdoc />
  @override
  int getWeekOfWeekYear(LocalDate date) {
    YearMonthDay yearMonthDay = ILocalDate.yearMonthDay(date);
    YearMonthDayCalculator yearMonthDayCalculator = ICalendarSystem.yearMonthDayCalculator(date.calendar);
    // This is a bit inefficient, as we'll be converting forms several times. However, it's
    // understandable... we might want to optimize in the future if it's reported as a bottleneck.
    int weekYear = getWeekYear(date);
    // Even if this is before the *real* start of the week year due to the rule
    // having short weeks, that doesn't change the week-of-week-year, as we've definitely
    // got the right week-year to start with.
    int startOfWeekYear = _getWeekYearDaysSinceEpoch(yearMonthDayCalculator, weekYear);
    int daysSinceEpoch = yearMonthDayCalculator.getDaysSinceEpoch(yearMonthDay);
    int zeroBasedDayOfWeekYear = daysSinceEpoch - startOfWeekYear;
    int zeroBasedWeek = zeroBasedDayOfWeekYear ~/ 7;
    return zeroBasedWeek + 1;
  }

  /// <inheritdoc />
  @override
  int getWeeksInWeekYear(int weekYear, CalendarSystem calendar) {
    Preconditions.checkNotNull(calendar, 'calendar');
    YearMonthDayCalculator yearMonthDayCalculator = ICalendarSystem.yearMonthDayCalculator(calendar);
    _validateWeekYear(weekYear, calendar);

    int startOfWeekYear = _getWeekYearDaysSinceEpoch(yearMonthDayCalculator, weekYear);
    int startOfCalendarYear = yearMonthDayCalculator.getStartOfYearInDays(weekYear);
    // The number of days gained or lost in the week year compared with the calendar year.
    // So if the week year starts on December 31st of the previous calendar year, this will be +1.
    // If the week year starts on January 2nd of this calendar year, this will be -1.
    int extraDaysAtStart = startOfCalendarYear - startOfWeekYear;

    // At the end of the year, we may have some extra days too.
    // In a non-regular rule, we just round up, so assume we effectively have 6 extra days.
    // In a regular rule, there can be at most minDaysInFirstWeek - 1 days 'borrowed'
    // from the following year - because if there were any more, those days would be in the
    // the following year instead.
    int extraDaysAtEnd = _irregularWeeks ? 6 : _minDaysInFirstWeek - 1;

    int daysInThisYear = yearMonthDayCalculator.getDaysInYear(weekYear);

    // We can have up to 'minDaysInFirstWeek - 1' days of the next year, too.
    return (daysInThisYear + extraDaysAtStart + extraDaysAtEnd) ~/ 7;
  }

  /// <inheritdoc />
  @override
  int getWeekYear(LocalDate date) {
    YearMonthDay yearMonthDay = ILocalDate.yearMonthDay(date);
    YearMonthDayCalculator yearMonthDayCalculator = ICalendarSystem.yearMonthDayCalculator(date.calendar);

    // Let's guess that it's in the same week year as calendar year, and check that.
    int calendarYear = yearMonthDay.year;
    int startOfWeekYear = _getWeekYearDaysSinceEpoch(yearMonthDayCalculator, calendarYear);
    int daysSinceEpoch = yearMonthDayCalculator.getDaysSinceEpoch(yearMonthDay);
    if (daysSinceEpoch < startOfWeekYear) {
      // No, the week-year hadn't started yet. For example, we've been given January 1st 2011...
      // and the first week of week-year 2011 starts on January 3rd 2011. Therefore the date
      // must belong to the last week of the previous week-year.
      return calendarYear - 1;
    }

    // By now, we know it's either calendarYear or calendarYear + 1.

    // In irregular rules, a day can belong to the *previous* week year, but never the *next* week year.
    // So at this point, we're done.
    if (_irregularWeeks) {
      return calendarYear;
    }

    // Otherwise, check using the number of
    // weeks in the year. Note that this will fetch the start of the calendar year and the week year
    // again, so could be optimized by copying some logic here - but only when we find we need to.
    int weeksInWeekYear = getWeeksInWeekYear(calendarYear, date.calendar);

    // We assume that even for the maximum year, we've got just about enough leeway to get to the
    // start of the week year. (If not, we should adjust the maximum.)
    int startOfNextWeekYear = startOfWeekYear + weeksInWeekYear * 7;
    return daysSinceEpoch < startOfNextWeekYear ? calendarYear : calendarYear + 1;
  }

  /// Validate that at least one day in the calendar falls in the given week year.
  void _validateWeekYear(int weekYear, CalendarSystem calendar) {
    if (weekYear > calendar.minYear && weekYear < calendar.maxYear) {
      return;
    }
    int minCalendarYearDays = _getWeekYearDaysSinceEpoch(ICalendarSystem.yearMonthDayCalculator(calendar), calendar.minYear);
    // If week year X started after calendar year X, then the first days of the calendar year are in the
    // previous week year.
    int minWeekYear = minCalendarYearDays > ICalendarSystem.minDays(calendar) ? calendar.minYear - 1 : calendar.minYear;
    int maxCalendarYearDays = _getWeekYearDaysSinceEpoch(ICalendarSystem.yearMonthDayCalculator(calendar), calendar.maxYear + 1);
    // If week year X + 1 started after the last day in the calendar, then everything is within week year X.
    // For irregular rules, we always just use calendar.MaxYear.
    int maxWeekYear = _irregularWeeks || (maxCalendarYearDays > ICalendarSystem.maxDays(calendar)) ? calendar.maxYear : calendar.maxYear + 1;
    Preconditions.checkArgumentRange('weekYear', weekYear, minWeekYear, maxWeekYear);
  }

  /// Returns the days at the start of the given week-year. The week-year may be
  /// 1 higher or lower than the max/min calendar year. For non-regular rules (i.e. where some weeks
  /// can be short) it returns the day when the week-year *would* have started if it were regular.
  /// So this *always* returns a date on firstDayOfWeek.
  int _getWeekYearDaysSinceEpoch(YearMonthDayCalculator yearMonthDayCalculator, int weekYear) {
    // Need to be slightly careful here, as the week-year can reasonably be (just) outside the calendar year range.
    // However, YearMonthDayCalculator.GetStartOfYearInDays already handles min/max -/+ 1.
    int startOfCalendarYear = yearMonthDayCalculator.getStartOfYearInDays(weekYear);
    int startOfYearDayOfWeek = /*unchecked*/(startOfCalendarYear >= -3 ? 1 + ((startOfCalendarYear + 3) % 7)
        : 7 + arithmeticMod((startOfCalendarYear + 4), 7));

    // How many days have there been from the start of the week containing
    // the first day of the year, until the first day of the year? To put it another
    // way, how many days in the week *containing* the start of the calendar year were
    // in the previous calendar year.
    // (For example, if the start of the calendar year is Friday and the first day of the week is Monday,
    // this will be 4.)
    int daysIntoWeek = ((startOfYearDayOfWeek - _firstDayOfWeek.value) + 7) % 7;
    int startOfWeekContainingStartOfCalendarYear = startOfCalendarYear - daysIntoWeek;

    bool startOfYearIsInWeek1 = (7 - daysIntoWeek >= _minDaysInFirstWeek);
    return startOfYearIsInWeek1
        ? startOfWeekContainingStartOfCalendarYear
        : startOfWeekContainingStartOfCalendarYear + 7;
  }
}
