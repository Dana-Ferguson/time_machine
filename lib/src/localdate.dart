// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

@internal
abstract class ILocalDate {
  static LocalDate trusted(YearMonthDayCalendar yearMonthDayCalendar) => LocalDate._trusted(yearMonthDayCalendar);
  // static LocalDate fromDaysSinceEpoch(int daysSinceEpoch, [CalendarSystem calendar]) => new LocalDate.fromEpochDay(daysSinceEpoch, calendar);
  // static int daysSinceEpoch(LocalDate localDate) => localDate.epochDay;
  static YearMonthDay yearMonthDay(LocalDate localDate) => localDate._yearMonthDay;
  static YearMonthDayCalendar yearMonthDayCalendar(LocalDate localDate) => localDate._yearMonthDayCalendar;
}

@immutable
class LocalDate implements Comparable<LocalDate> {
  final YearMonthDayCalendar _yearMonthDayCalendar;

  /// The maximum (latest) date representable in the ISO calendar system.
  static LocalDate get maxIsoValue => LocalDate._trusted(YearMonthDayCalendar(GregorianYearMonthDayCalculator.maxGregorianYear, 12, 31, CalendarOrdinal.iso));

  /// The minimum (earliest) date representable in the ISO calendar system.
  static LocalDate get minIsoValue => LocalDate._trusted(YearMonthDayCalendar(GregorianYearMonthDayCalculator.minGregorianYear, 1, 1, CalendarOrdinal.iso));

  /// Constructs an instance from values which are assumed to already have been validated.
  const LocalDate._trusted(this._yearMonthDayCalendar);

  /// Constructs an instance from the number of days since the unix epoch, in the specified
  /// or ISO calendar system.
  factory LocalDate.fromEpochDay(int epochDay, [CalendarSystem? calendar])
  {
    if (calendar == null) {
      assert(Preconditions.debugCheckArgumentRange('daysSinceEpoch', epochDay, ICalendarSystem.minDays(CalendarSystem.iso), ICalendarSystem.maxDays(CalendarSystem.iso)));
      return LocalDate._trusted(GregorianYearMonthDayCalculator.getGregorianYearMonthDayCalendarFromDaysSinceEpoch(epochDay));
    } else {
      return LocalDate._trusted(ICalendarSystem.getYearMonthDayCalendarFromDaysSinceEpoch(calendar, epochDay));
    }
  }

  /// Constructs an instance for the given year, month and day in the specified or ISO calendar.
  ///
  /// * [year]: The year. This is the 'absolute year', so a value of 0 means 1 BC, for example.
  /// * [month]: The month of year.
  /// * [day]: The day of month.
  /// * [calendar]: Calendar system in which to create the date, which defaults to the ISO calendar.
  /// * [era]: The era within which to create a date. Must be a valid era within the specified calendar.
  ///
  /// Returns: The resulting date.
  ///
  /// * [RangeError]: The parameters do not form a valid date.
  factory LocalDate(int year, int month, int day, [CalendarSystem? calendar, Era? era])
  {
    CalendarOrdinal ordinal;
    if (calendar == null) {
      if (era != null) year = CalendarSystem.iso.getAbsoluteYear(year, era);
      GregorianYearMonthDayCalculator.validateGregorianYearMonthDay(year, month, day);
      ordinal = CalendarOrdinal.iso;
    } else {
      if (era != null) year = calendar.getAbsoluteYear(year, era);
      ICalendarSystem.validateYearMonthDay(calendar, year, month, day);
      ordinal = ICalendarSystem.ordinal(calendar);
    }

    return LocalDate._trusted(YearMonthDayCalendar(year, month, day, ordinal));
  }

  // todo: this could probably be cheaper with a DateTime based method ~ but would still need to be based on [Clock.current] to be useful

  /// Produces a [LocalDate] based on your [Clock.current] and your [DateTimeZone.local].
  ///
  /// * [calendar]: The calendar system to convert into, defaults to ISO calendar
  ///
  /// Returns: A new [LocalDate] with the same values as the local clock.
  factory LocalDate.today([CalendarSystem? calendar]) =>
      Instant.now().inLocalZone(calendar).calendarDate;

  /// Converts a [DateTime] of any kind to a LocalDate in the specified or ISO calendar, ignoring the time of day.
  /// This does not perform any time zone conversions, so a DateTime with a [DateTime.isUtc] of
  /// `true` will still represent the same year/month/day as it does in UTC - it won't be converted into the local system time.
  ///
  /// * [dateTime]: Value to convert into a Time Machine local date
  /// * [calendar]: The calendar system to convert into, defaults to ISO calendar
  ///
  /// Returns: A new [LocalDate] with the same values as the specified `DateTime`.
  factory LocalDate.dateTime(DateTime dateTime, [CalendarSystem? calendar])
  {
    int days = Platform.isWeb
        ? (dateTime.millisecondsSinceEpoch + dateTime.timeZoneOffset.inMilliseconds) ~/ TimeConstants.millisecondsPerDay
        : (dateTime.microsecondsSinceEpoch + dateTime.timeZoneOffset.inMicroseconds) ~/ TimeConstants.microsecondsPerDay;
    return LocalDate.fromEpochDay(days, calendar);
  }

  /// Gets the calendar system associated with this local date.
  CalendarSystem get calendar => ICalendarSystem.forOrdinal(_yearMonthDayCalendar.calendarOrdinal);

  /// Gets the year of this local date.
  /// This returns the 'absolute year', so, for the ISO calendar,
  /// a value of 0 means 1 BC, for example.
  int get year => _yearMonthDayCalendar.year;

  /// Gets the month of this local date within the year.
  int get monthOfYear => _yearMonthDayCalendar.month;

  /// Gets the day of this local date within the month.
  int get dayOfMonth => _yearMonthDayCalendar.day;

  /// Gets the number of days since the Unix epoch for this date.
  int get epochDay => ICalendarSystem.getDaysSinceEpoch(calendar, _yearMonthDayCalendar.toYearMonthDay());

  /// Gets the week day of this local date expressed as an [DayOfWeek] value.
  DayOfWeek get dayOfWeek => ICalendarSystem.getDayOfWeek(calendar, _yearMonthDayCalendar.toYearMonthDay());

  /// Gets the year of this local date within the era.
  int get yearOfEra => ICalendarSystem.getYearOfEra(calendar, _yearMonthDayCalendar.year);

  /// Gets the era of this local date.
  Era get era => ICalendarSystem.getEra(calendar, _yearMonthDayCalendar.year);

  /// Gets the day of this local date within the year.
  int get dayOfYear => ICalendarSystem.getDayOfYear(calendar, _yearMonthDayCalendar.toYearMonthDay());

  YearMonthDay get _yearMonthDay => _yearMonthDayCalendar.toYearMonthDay();

  @internal YearMonthDayCalendar get yearMonthDayCalendar => _yearMonthDayCalendar;

  /// Gets a [LocalDateTime] at midnight on the date represented by this local date.
  LocalDateTime atMidnight() => LocalDateTime.localDateAtTime(this, LocalTime.midnight);

  /// Constructs a [DateTime] with [DateTime.isUtc] == `false`. The result is midnight on the day represented
  /// by this value.
  DateTime toDateTimeUnspecified() => DateTime(year, monthOfYear, dayOfMonth);
  // new DateTime.fromMicrosecondsSinceEpoch(DaysSinceEpoch * TimeConstants.microsecondsPerDay);
  // + TimeConstants.BclTicksAtUnixEpoch ~/ TimeConstants.ticksPerMicrosecond); //, DateTimeKind.Unspecified);

  // Helper method used by both FromDateTime overloads.
  // static int _nonNegativeMicrosecondsToDays(int microseconds) => microseconds ~/ TimeConstants.microsecondsPerDay;
  // ((ticks >> 14) ~/ 52734375);

  /// Returns the local date corresponding to the given 'week year', "week of week year", and "day of week"
  /// in the ISO calendar system, using the ISO week-year rules.
  ///
  /// * [weekYear]: ISO-8601 week year of value to return
  /// * [weekOfWeekYear]: ISO-8601 week of week year of value to return
  /// * [dayOfWeek]: ISO-8601 day of week to return
  ///
  /// Returns: The date corresponding to the given week year / week of week year / day of week.
  ///
  /// see: https://en.wikipedia.org/wiki/ISO_week_date
  factory LocalDate.isoWeekDate(int weekYear, int weekOfWeekYear, DayOfWeek dayOfWeek) =>
      WeekYearRules.iso.getLocalDate(weekYear, weekOfWeekYear, dayOfWeek, CalendarSystem.iso);

  /// Returns the local date corresponding to a particular occurrence of a day-of-week
  /// within a year and month. For example, this method can be used to ask for 'the third Monday in April 2012'.
  ///
  /// The returned date is always in the ISO calendar. This method is unrelated to week-years and any rules for
  /// 'business weeks' and the like - if a month begins on a Friday, then asking for the first Friday will give
  /// that day, for example.
  ///
  /// * [year]: The year of the value to return.
  /// * [month]: The month of the value to return.
  /// * [occurrence]: The occurrence of the value to return, which must be in the range [1, 5]. The value 5 can
  /// be used to always return the last occurrence of the specified day-of-week, even if there are only 4
  /// occurrences of that day-of-week in the month.
  /// * [dayOfWeek]: The day-of-week of the value to return.
  /// The date corresponding to the given year and month, on the given occurrence of the
  /// given day of week.
  factory LocalDate.onDayOfWeekInMonth(int year, int month, int occurrence, DayOfWeek dayOfWeek)
  {
    // This validates year and month as well as getting us a useful date.
    LocalDate startOfMonth = LocalDate(year, month, 1);
    Preconditions.checkArgumentRange('occurrence', occurrence, 1, 5);
    Preconditions.checkArgumentRange('dayOfWeek', dayOfWeek.value, 1, 7);

    // Correct day of week, 1st week of month.
    int week1Day = dayOfWeek - startOfMonth.dayOfWeek + 1;
    if (week1Day <= 0)
    {
      week1Day += 7;
    }
    int targetDay = week1Day + (occurrence - 1) * 7;
    if (targetDay > CalendarSystem.iso.getDaysInMonth(year, month))
    {
      targetDay -= 7;
    }
    return LocalDate(year, month, targetDay);
  }

  /// Adds the specified period to the date. Friendly alternative to `operator+()`.
  ///
  /// * [date]: The date to add the period to
  /// * [period]: The period to add. Must not contain any (non-zero) time units.
  ///
  /// Returns: The sum of the given date and period
  static LocalDate plus(LocalDate date, Period period) => date.add(period);

  /// Subtracts the specified period from the date. Friendly alternative to `operator-()`.
  ///
  /// * [date]: The date to subtract the period from
  /// * [period]: The period to subtract. Must not contain any (non-zero) time units.
  ///
  /// Returns: The result of subtracting the given period from the date.
  static LocalDate minus(LocalDate date, Period period) => date.subtract(period);

  /// Subtracts one date from another, returning the result as a [Period] with units of years, months and days.
  ///
  /// This is simply a convenience method for calling [Period.Between(LocalDate,LocalDate)].
  /// The calendar systems of the two dates must be the same.
  ///
  /// * [end]: The date to subtract from
  /// * [start]: The date to subtract
  ///
  /// Returns: The result of subtracting one date from another.
  static Period difference(LocalDate end, LocalDate start) => Period.differenceBetweenDates(start, end); // rhs.minusDate(lhs);

  /// Adds the specified period to the date.
  ///
  /// * [this]: The date to add the period to
  /// * [period]: The period to add. Must not contain any (non-zero) time units.
  ///
  /// Returns: The sum of the given date and period
  LocalDate operator +(Period period) => add(period);

  /// Subtracts the specified period from the date.
  /// This is a convenience operator over the [Minus(Period)] method.
  ///
  /// * [this]: The date to subtract the period from
  /// * [period]: The period to subtract. Must not contain any (non-zero) time units.
  ///
  /// Returns: The result of subtracting the given period from the date
  LocalDate operator -(Period period) => subtract(period);

  // dynamic operator -(dynamic other) => other is LocalDate ? minusDate(other) : other is Period ? minusPeriod(other) : throw new TypeError();

  /// Compares two [LocalDate] values for equality. This requires
  /// that the dates be the same, within the same calendar.
  ///
  /// * [this]: The first value to compare
  /// * [other]: The second value to compare
  ///
  /// Returns: True if the two dates are the same and in the same calendar; false otherwise
  @override
  bool operator ==(Object other) => other is LocalDate && _yearMonthDayCalendar == other._yearMonthDayCalendar;

  /// Adds the specified period to this date. Fluent alternative to `operator+()`.
  ///
  /// * [period]: The period to add. Must not contain any (non-zero) time units.
  ///
  /// Returns: The sum of this date and the given period
  LocalDate add(Period period) {
    Preconditions.checkNotNull(period, 'period');
    Preconditions.checkArgument(!period.hasTimeComponent, 'period', "Cannot add a period with a time component to a date");
    return IPeriod.addDateTo(period, this, 1);
  }

  /// Subtracts the specified period from this date. Fluent alternative to `operator-()`.
  ///
  /// * [period]: The period to subtract. Must not contain any (non-zero) time units.
  ///
  /// Returns: The result of subtracting the given period from this date.
  LocalDate subtract(Period period) {
    Preconditions.checkNotNull(period, 'period');
    Preconditions.checkArgument(!period.hasTimeComponent, 'period', "Cannot subtract a period with a time component from a date");
    return IPeriod.addDateTo(period, this, -1);
  }

  /// Subtracts the specified time from this date, returning the result as a [Period].
  /// Cognitively similar to: `this - date`.
  ///
  /// The specified time must be in the same calendar system as this.
  ///
  /// * [date]: The date to subtract from this
  ///
  /// Returns: The difference between the specified date and this one
  Period periodSince(LocalDate date) => Period.differenceBetweenDates(date, this);

  /// Subtracts the specified time from this time, returning the result as a [Period].
  /// Cognitively similar to: `date - this`.
  ///
  /// The specified date must be in the same calendar system as this.
  ///
  /// * [date]: The date to subtract this from
  ///
  /// Returns: The difference between the specified date and this one
  Period periodUntil(LocalDate date) => Period.differenceBetweenDates(this, date);

  // Comparison operators: note that we can't use YearMonthDayCalendar.Compare, as only the calendar knows whether it can use
  // naive comparisons.

  /// Compares two dates to see if the left one is strictly earlier than the right
  /// one.
  ///
  /// Only dates with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  ///
  /// * [this]: First operand of the comparison
  /// * [other]: Second operand of the comparison
  ///
  /// Returns: true if the [this] is strictly earlier than [other], false otherwise.
  ///
  /// * [ArgumentException]: The calendar system of [other] is not the same
  /// as the calendar of [this].
  bool operator <(LocalDate other)
  {
    Preconditions.checkArgument(calendar == other.calendar, 'rhs', "Only values in the same calendar can be compared");
    return compareTo(other) < 0;
  }

  /// Compares two dates to see if the left one is earlier than or equal to the right
  /// one.
  ///
  /// Only dates with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  ///
  /// * [this]: First operand of the comparison
  /// * [rhs]: Second operand of the comparison
  ///
  /// Returns: true if the [this] is earlier than or equal to [other], false otherwise.
  ///
  /// * [ArgumentException]: The calendar system of [other] is not the same
  /// as the calendar of [this].
  bool operator <=(LocalDate other)
  {
    Preconditions.checkArgument(calendar == other.calendar, 'rhs', "Only values in the same calendar can be compared");
    return compareTo(other) <= 0;
  }

  /// Compares two dates to see if the left one is strictly later than the right
  /// one.
  ///
  /// Only dates with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  ///
  /// * [this]: First operand of the comparison
  /// * [other]: Second operand of the comparison
  ///
  /// Returns: true if the [this] is strictly later than [other], false otherwise.
  ///
  /// * [ArgumentException]: The calendar system of [other] is not the same
  /// as the calendar of [this].
  bool operator >(LocalDate other)
  {
    Preconditions.checkArgument(calendar == other.calendar, 'rhs', "Only values in the same calendar can be compared");
    return compareTo(other) > 0;
  }

  /// Compares two dates to see if the left one is later than or equal to the right
  /// one.
  ///
  /// Only dates with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  ///
  /// * [this]: First operand of the comparison
  /// * [other]: Second operand of the comparison
  ///
  /// Returns: true if the [this] is later than or equal to [other], false otherwise.
  ///
  /// * [ArgumentException]: The calendar system of [other] is not the same
  /// as the calendar of [this].
  bool operator >=(LocalDate other)
  {
    Preconditions.checkArgument(calendar == other.calendar, 'rhs', "Only values in the same calendar can be compared");
    return compareTo(other) >= 0;
  }

  /// Indicates whether this date is earlier, later or the same as another one.
  ///
  /// Only dates within the same calendar systems can be compared with this method. Attempting to compare
  /// dates within different calendars will fail with an [ArgumentException]. Ideally, comparisons
  /// between values in different calendars would be a compile-time failure, but failing at execution time
  /// is almost always preferable to continuing.
  ///
  /// * [other]: The other date to compare this one with
  ///
  /// Returns: a value less than zero if this date is earlier than [other];
  /// zero if this date is the same as [other]; a value greater than zero if this date is
  /// later than [other].
  ///
  /// * [ArgumentException]: The calendar system of [other] is not the
  /// same as the calendar system of this value.
  @override
  int compareTo(LocalDate? other)
  {
    // todo: is this the best way? Should I add a check like this everywhere?
    if (other == null) return 1;
    Preconditions.checkArgument(calendar == other.calendar, 'other', "Only values with the same calendar system can be compared");
    return ICalendarSystem.compare(calendar, _yearMonthDay, other._yearMonthDay);
  }

  /// Returns the later date of the given two.
  ///
  /// * [x]: The first date to compare.
  /// * [y]: The second date to compare.
  ///
  /// Returns: The later date of [x] or [y].
  ///
  /// * [ArgumentException]: The two dates have different calendar systems.
  static LocalDate max(LocalDate x, LocalDate y)
  {
    Preconditions.checkArgument(x.calendar == y.calendar, 'y', "Only values with the same calendar system can be compared");
    return x > y ? x : y;
  }

  /// Returns the earlier date of the given two.
  ///
  /// * [x]: The first date to compare.
  /// * [y]: The second date to compare.
  ///
  /// Returns: The earlier date of [x] or [y].
  ///
  /// * [ArgumentException]: The two dates have different calendar systems.
  static LocalDate min(LocalDate x, LocalDate y)
  {
    Preconditions.checkArgument(x.calendar == y.calendar, 'y', "Only values with the same calendar system can be compared");
    return x < y ? x : y;
  }

  /// Returns a hash code for this local date.
  @override int get hashCode => _yearMonthDayCalendar.hashCode;

  /// Compares two [LocalDate] values for equality. This requires
  /// that the dates be the same, within the same calendar.
  ///
  /// * [other]: The value to compare this date with.
  ///
  /// Returns: True if the given value is another local date equal to this one; false otherwise.
  bool equals(LocalDate other) => _yearMonthDayCalendar == other._yearMonthDayCalendar;

  /// Resolves this local date into a [ZonedDateTime] in the given time zone representing the
  /// start of this date in the given zone.
  ///
  /// This is a convenience method for calling [ZonedDateTime.atStartOfDay].
  ///
  /// * [zone]: The time zone to map this local date into
  ///
  /// Returns: The [ZonedDateTime] representing the earliest time on this date, in the given time zone.
  ///
  /// * [SkippedTimeException]: The entire day was skipped due to a very large time zone transition.
  /// (This is extremely rare.)
  ZonedDateTime atStartOfDayInZone(DateTimeZone zone)
  {
    Preconditions.checkNotNull(zone, 'zone');
    return ZonedDateTime.atStartOfDay(this, zone);
  }

  /// Creates a new LocalDate representing the same physical date, but in a different calendar.
  /// The returned LocalDate is likely to have different field values to this one.
  /// For example, January 1st 1970 in the Gregorian calendar was December 19th 1969 in the Julian calendar.
  ///
  /// * [calendar]: The calendar system to convert this local date to.
  ///
  /// Returns: The converted LocalDate
  LocalDate withCalendar(CalendarSystem calendar)
  {
    Preconditions.checkNotNull(calendar, 'calendar');
    return LocalDate.fromEpochDay(epochDay, calendar);
  }

  /// Returns a new LocalDate representing the current value with the given number of years added.
  ///
  /// If the resulting date is invalid, lower fields (typically the day of month) are reduced to find a valid value.
  /// For example, adding one year to February 29th 2012 will return February 28th 2013; subtracting one year from
  /// February 29th 2012 will return February 28th 2011.
  ///
  /// * [years]: The number of years to add
  ///
  /// Returns: The current value plus the given number of years.
  LocalDate addYears(int years) => DatePeriodFields.yearsField.add(this, years);

  LocalDate subtractYears(int years) => addYears(-years);

  /// Returns a new LocalDate representing the current value with the given number of months added.
  ///
  /// This method does not try to maintain the year of the current value, so adding four months to a value in
  /// October will result in a value in the following February.
  ///
  /// If the resulting date is invalid, the day of month is reduced to find a valid value.
  /// For example, adding one month to January 30th 2011 will return February 28th 2011; subtracting one month from
  /// March 30th 2011 will return February 28th 2011.
  ///
  /// * [months]: The number of months to add
  ///
  /// Returns: The current date plus the given number of months
  LocalDate addMonths(int months) => DatePeriodFields.monthsField.add(this, months);

  LocalDate subtractMonths(int months) => addMonths(-months);

  /// Returns a new LocalDate representing the current value with the given number of days added.
  ///
  /// This method does not try to maintain the month or year of the current value, so adding 3 days to a value of January 30th
  /// will result in a value of February 2nd.
  ///
  /// * [days]: The number of days to add
  ///
  /// Returns: The current value plus the given number of days.
  LocalDate addDays(int days) => DatePeriodFields.daysField.add(this, days);

  LocalDate subtractDays(int days) => addDays(-days);

  /// Returns a new LocalDate representing the current value with the given number of weeks added.
  ///
  /// * [weeks]: The number of weeks to add
  ///
  /// Returns: The current value plus the given number of weeks.
  LocalDate addWeeks(int weeks) => DatePeriodFields.weeksField.add(this, weeks);

  LocalDate subtractWeeks(int weeks) => addWeeks(-weeks);

  /// Returns the next [LocalDate] falling on the specified [DayOfWeek].
  /// This is a strict 'next' - if this date on already falls on the target
  /// day of the week, the returned value will be a week later.
  ///
  /// * [targetDayOfWeek]: The ISO day of the week to return the next date of.
  ///
  /// Returns: The next [LocalDate] falling on the specified day of the week.
  ///
  /// * [InvalidOperationException]: The underlying calendar doesn't use ISO days of the week.
  /// * [ArgumentOutOfRangeException]: [targetDayOfWeek] is not a valid day of the
  /// week (Monday to Sunday).
  LocalDate next(DayOfWeek targetDayOfWeek)
  {
    // Avoids boxing...
    if (targetDayOfWeek < DayOfWeek.monday || targetDayOfWeek > DayOfWeek.sunday)
    {
      throw RangeError('targetDayOfWeek');
    }
    // This will throw the desired exception for calendars with different week systems.
    DayOfWeek thisDay = dayOfWeek;
    int difference = targetDayOfWeek - thisDay;
    if (difference <= 0)
    {
      difference += 7;
    }
    return addDays(difference);
  }

  /// Returns the previous [LocalDate] falling on the specified [DayOfWeek].
  /// This is a strict 'previous' - if this date on already falls on the target
  /// day of the week, the returned value will be a week earlier.
  ///
  /// * [targetDayOfWeek]: The ISO day of the week to return the previous date of.
  ///
  /// Returns: The previous [LocalDate] falling on the specified day of the week.
  ///
  /// * [InvalidOperationException]: The underlying calendar doesn't use ISO days of the week.
  /// * [ArgumentOutOfRangeException]: [targetDayOfWeek] is not a valid day of the
  /// week (Monday to Sunday).
  LocalDate previous(DayOfWeek targetDayOfWeek)
  {
    // Avoids boxing...
    if (targetDayOfWeek < DayOfWeek.monday || targetDayOfWeek > DayOfWeek.sunday)
    {
      throw RangeError('targetDayOfWeek');
    }
    // This will throw the desired exception for calendars with different week systems.
    DayOfWeek thisDay = dayOfWeek;
    int difference = targetDayOfWeek - thisDay;
    if (difference >= 0)
    {
      difference -= 7;
    }
    return addDays(difference);
  }

  /// Returns an [OffsetDate] for this local date with the given offset.
  ///
  /// This method is purely a convenient alternative to calling the [OffsetDate] constructor directly.
  ///
  /// * [offset]: The offset to apply.
  ///
  /// Returns: The result of this date offset by the given amount.
  OffsetDate withOffset(Offset offset) => OffsetDate(this, offset);

  /// Combines this [LocalDate] with the given [LocalTime]
  /// into a single [LocalDateTime].
  /// Fluent alternative to `operator+()`.
  ///
  /// * [time]: The time to combine with this date.
  ///
  /// Returns: The [LocalDateTime] representation of the given time on this date
  LocalDateTime at(LocalTime time) => LocalDateTime.localDateAtTime(this, time);

  LocalDate adjust(LocalDate Function(LocalDate) adjuster) => adjuster(this);

  /// Returns a [String] that represents this instance.
  ///
  /// The value of the current instance in the default format pattern ('D'), using the current isolates's
  /// culture to obtain a format provider.
  @override String toString([String? patternText, Culture? culture]) =>
      LocalDatePatterns.format(this, patternText, culture);
}

