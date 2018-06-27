// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'utility/preconditions.dart';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';
import 'package:time_machine/src/fields/time_machine_fields.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';

@internal
abstract class ILocalDate {
  static LocalDate trusted(YearMonthDayCalendar yearMonthDayCalendar) => new LocalDate._trusted(yearMonthDayCalendar);
  static LocalDate fromDaysSinceEpoch(int daysSinceEpoch, [CalendarSystem calendar]) => new LocalDate._fromDaysSinceEpoch(daysSinceEpoch, calendar);
  static int daysSinceEpoch(LocalDate localDate) => localDate._daysSinceEpoch;
  static YearMonthDay yearMonthDay(LocalDate localDate) => localDate._yearMonthDay;
  static YearMonthDayCalendar yearMonthDayCalendar(LocalDate localDate) => localDate._yearMonthDayCalendar;
}

@immutable
class LocalDate implements Comparable<LocalDate> {
  final YearMonthDayCalendar _yearMonthDayCalendar;

  /// The maximum (latest) date representable in the ISO calendar system.
  static LocalDate get maxIsoValue => new LocalDate._trusted(new YearMonthDayCalendar(GregorianYearMonthDayCalculator.maxGregorianYear, 12, 31, CalendarOrdinal.iso));

  /// The minimum (earliest) date representable in the ISO calendar system.
  static LocalDate get minIsoValue => new LocalDate._trusted(new YearMonthDayCalendar(GregorianYearMonthDayCalculator.minGregorianYear, 1, 1, CalendarOrdinal.iso));

  /// Constructs an instance from values which are assumed to already have been validated.
  LocalDate._trusted(this._yearMonthDayCalendar);

  /// Constructs an instance from the number of days since the unix epoch, in the specified
  /// or ISO calendar system.
  factory LocalDate._fromDaysSinceEpoch(int daysSinceEpoch, [CalendarSystem calendar])
  {
    if (calendar == null) {
      Preconditions.debugCheckArgumentRange('daysSinceEpoch', daysSinceEpoch, CalendarSystem.iso.minDays, CalendarSystem.iso.maxDays);
      return new LocalDate._trusted(GregorianYearMonthDayCalculator.getGregorianYearMonthDayCalendarFromDaysSinceEpoch(daysSinceEpoch));
    } else {
      Preconditions.debugCheckNotNull(calendar, 'calendar');
      return new LocalDate._trusted(calendar.getYearMonthDayCalendarFromDaysSinceEpoch(daysSinceEpoch));
    }
  }
  
  /// Constructs an instance for the given year, month and day in the specified or ISO calendar.
  ///
  /// [year]: The year. This is the "absolute year", so a value of 0 means 1 BC, for example.
  /// [month]: The month of year.
  /// [day]: The day of month.
  /// [calendar]: Calendar system in which to create the date, which defaults to the ISO calendar.
  /// Returns: The resulting date.
  /// [RangeError]: The parameters do not form a valid date.
  factory LocalDate(int year, int month, int day, [CalendarSystem calendar])
  {
    GregorianYearMonthDayCalculator.validateGregorianYearMonthDay(year, month, day);
    return new LocalDate._trusted(new YearMonthDayCalendar(year, month, day, calendar?.ordinal ?? CalendarOrdinal.iso));
  }

  /// Constructs an instance for the given era, year of era, month and day in the specified or ISO calendar.
  ///
  /// [era]: The era within which to create a date. Must be a valid era within the specified calendar.
  /// [yearOfEra]: The year of era.
  /// [month]: The month of year.
  /// [day]: The day of month.
  /// [calendar]: Calendar system in which to create the date.
  /// Returns: The resulting date.
  /// [ArgumentOutOfRangeException]: The parameters do not form a valid date.
  factory LocalDate.forEra(Era era, int yearOfEra, int month, int day, [CalendarSystem calendar]) {
    calendar ??= CalendarSystem.iso;
    return new LocalDate(calendar.getAbsoluteYear(yearOfEra, era), month, day, calendar);
  }

  /// Gets the calendar system associated with this local date.
  CalendarSystem get calendar => CalendarSystem.forOrdinal(_yearMonthDayCalendar.calendarOrdinal);

  /// Gets the year of this local date.
  /// This returns the "absolute year", so, for the ISO calendar,
  /// a value of 0 means 1 BC, for example.
  int get year => _yearMonthDayCalendar.year;

  /// Gets the month of this local date within the year.
  int get month => _yearMonthDayCalendar.month;

  /// Gets the day of this local date within the month.
  int get day => _yearMonthDayCalendar.day;

  /// Gets the number of days since the Unix epoch for this date.
  int get _daysSinceEpoch => calendar.getDaysSinceEpoch(_yearMonthDayCalendar.toYearMonthDay());

  /// Gets the week day of this local date expressed as an [IsoDayOfWeek] value.
  IsoDayOfWeek get dayOfWeek => calendar.getDayOfWeek(_yearMonthDayCalendar.toYearMonthDay());

  /// Gets the year of this local date within the era.
  int get yearOfEra => calendar.getYearOfEra(_yearMonthDayCalendar.year);

  /// Gets the era of this local date.
  Era get era => calendar.getEra(_yearMonthDayCalendar.year);

  /// Gets the day of this local date within the year.
  int get dayOfYear => calendar.getDayOfYear(_yearMonthDayCalendar.toYearMonthDay());

  YearMonthDay get _yearMonthDay => _yearMonthDayCalendar.toYearMonthDay();

  // @internal YearMonthDayCalendar get yearMonthDayCalendar => _yearMonthDayCalendar;

  /// Gets a [LocalDateTime] at midnight on the date represented by this local date.
  ///
  /// The [LocalDateTime] representing midnight on this local date, in the same calendar
  /// system.
  LocalDateTime atMidnight() => new LocalDateTime(this, LocalTime.midnight);

  /// Constructs a [DateTime] from this value which has a [DateTime.Kind]
  /// of [DateTimeKind.Unspecified]. The result is midnight on the day represented
  /// by this value.
  ///
  /// [DateTimeKind.Unspecified] is slightly odd - it can be treated as UTC if you use [DateTime.ToLocalTime]
  /// or as system local time if you use [DateTime.ToUniversalTime], but it's the only kind which allows
  /// you to construct a [DateTimeOffset] with an arbitrary offset, which makes it as close to
  /// the Time Machine non-system-specific "local" concept as exists in .NET.
  ///
  /// Returns: A [DateTime] value for the same date and time as this value.
  DateTime toDateTimeUnspecified() => new DateTime(year, month, day);
  // new DateTime.fromMicrosecondsSinceEpoch(DaysSinceEpoch * TimeConstants.microsecondsPerDay);
  // + TimeConstants.BclTicksAtUnixEpoch ~/ TimeConstants.ticksPerMicrosecond); //, DateTimeKind.Unspecified);

  // Helper method used by both FromDateTime overloads.
  static int _nonNegativeMicrosecondsToDays(int microseconds) => microseconds ~/ TimeConstants.microsecondsPerDay;
  // ((ticks >> 14) ~/ 52734375);

  /// Converts a [DateTime] of any kind to a LocalDate in the specified or ISO calendar, ignoring the time of day.
  /// This does not perform any time zone conversions, so a DateTime with a [DateTime.Kind] of
  /// [DateTimeKind.utc] will still represent the same year/month/day - it won't be converted into the local system time.
  ///
  /// [dateTime]: Value to convert into a Time Machine local date
  /// [calendar]: The calendar system to convert into, defaults to ISO calendar
  /// Returns: A new [LocalDate] with the same values as the specified `DateTime`.
  factory LocalDate.fromDateTime(DateTime dateTime, [CalendarSystem calendar])
  {
    // todo: we might want to make this so it's microseconds on VM and milliseconds on JS
    int days = _nonNegativeMicrosecondsToDays(dateTime.microsecondsSinceEpoch);
    return new LocalDate._fromDaysSinceEpoch(days, calendar);
  }

  /// Returns the local date corresponding to the given "week year", "week of week year", and "day of week"
  /// in the ISO calendar system, using the ISO week-year rules.
  ///
  /// [weekYear]: ISO-8601 week year of value to return
  /// [weekOfWeekYear]: ISO-8601 week of week year of value to return
  /// [dayOfWeek]: ISO-8601 day of week to return
  /// Returns: The date corresponding to the given week year / week of week year / day of week.
  factory LocalDate.fromWeekYearWeekAndDay(int weekYear, int weekOfWeekYear, IsoDayOfWeek dayOfWeek)
  => WeekYearRules.iso.getLocalDate(weekYear, weekOfWeekYear, dayOfWeek, CalendarSystem.iso);

  /// Returns the local date corresponding to a particular occurrence of a day-of-week
  /// within a year and month. For example, this method can be used to ask for "the third Monday in April 2012".
  ///
  /// The returned date is always in the ISO calendar. This method is unrelated to week-years and any rules for
  /// "business weeks" and the like - if a month begins on a Friday, then asking for the first Friday will give
  /// that day, for example.
  ///
  /// [year]: The year of the value to return.
  /// [month]: The month of the value to return.
  /// [occurrence]: The occurrence of the value to return, which must be in the range [1, 5]. The value 5 can
  /// be used to always return the last occurrence of the specified day-of-week, even if there are only 4
  /// occurrences of that day-of-week in the month.
  /// [dayOfWeek]: The day-of-week of the value to return.
  /// The date corresponding to the given year and month, on the given occurrence of the
  /// given day of week.
  factory LocalDate.fromYearMonthWeekAndDay(int year, int month, int occurrence, IsoDayOfWeek dayOfWeek)
  {
    // This validates year and month as well as getting us a useful date.
    LocalDate startOfMonth = new LocalDate(year, month, 1);
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
    return new LocalDate(year, month, targetDay);
  }

  /// Adds the specified period to the date. Friendly alternative to `operator+()`.
  ///
  /// [date]: The date to add the period to
  /// [period]: The period to add. Must not contain any (non-zero) time units.
  /// Returns: The sum of the given date and period
  static LocalDate add(LocalDate date, Period period) => date + period;

  /// Adds the specified period to this date. Fluent alternative to `operator+()`.
  ///
  /// [period]: The period to add. Must not contain any (non-zero) time units.
  /// Returns: The sum of this date and the given period
  LocalDate plus(Period period) => this + period;

  /// Adds the specified period to the date.
  ///
  /// [date]: The date to add the period to
  /// [period]: The period to add. Must not contain any (non-zero) time units.
  /// Returns: The sum of the given date and period
  LocalDate operator +(Period period)
  {
    Preconditions.checkNotNull(period, 'period');
    Preconditions.checkArgument(!period.hasTimeComponent, 'period', "Cannot add a period with a time component to a date");
    return IPeriod.addDateTo(period, this, 1);
  }

  /// Subtracts the specified period from the date. Friendly alternative to `operator-()`.
  ///
  /// [date]: The date to subtract the period from
  /// [period]: The period to subtract. Must not contain any (non-zero) time units.
  /// Returns: The result of subtracting the given period from the date.
  static LocalDate subtract(LocalDate date, Period period) => date - period;

  /// Subtracts one date from another, returning the result as a [Period] with units of years, months and days.
  ///
  /// This is simply a convenience method for calling [Period.Between(LocalDate,LocalDate)].
  /// The calendar systems of the two dates must be the same.
  ///
  /// [lhs]: The date to subtract from
  /// [rhs]: The date to subtract
  /// Returns: The result of subtracting one date from another.
  static Period between(LocalDate lhs, LocalDate rhs) => lhs - rhs;

  /// Subtracts the specified period from this date. Fluent alternative to `operator-()`.
  ///
  /// [period]: The period to subtract. Must not contain any (non-zero) time units.
  /// Returns: The result of subtracting the given period from this date.
  LocalDate minusPeriod(Period period) {
    Preconditions.checkNotNull(period, 'period');
    Preconditions.checkArgument(!period.hasTimeComponent, 'period', "Cannot subtract a period with a time component from a date");
    return IPeriod.addDateTo(period, this, -1);
  }

  /// Subtracts the specified date from this date, returning the result as a [Period] with units of years, months and days.
  /// Fluent alternative to `operator-()`.
  ///
  /// The specified date must be in the same calendar system as this.
  /// [date]: The date to subtract from this
  /// Returns: The difference between the specified date and this one
  Period minusDate(LocalDate date) => Period.betweenDates(date, this); // this - date;

  /// Subtracts one date from another, returning the result as a [Period] with units of years, months and days.
  ///
  /// This is simply a convenience operator for calling [Period.Between(LocalDate,LocalDate)].
  /// The calendar systems of the two dates must be the same; an exception will be thrown otherwise.
  ///
  /// [lhs]: The date to subtract from
  /// [rhs]: The date to subtract
  /// Returns: The result of subtracting one date from another.
  /// [ArgumentException]: 
  /// [lhs] and [rhs] are not in the same calendar system.
  ///
  /// Subtracts the specified period from the date.
  /// This is a convenience operator over the [Minus(Period)] method.
  ///
  /// [date]: The date to subtract the period from
  /// [period]: The period to subtract. Must not contain any (non-zero) time units.
  /// Returns: The result of subtracting the given period from the date
  // todo: still hate dynamic dispatch
  dynamic operator -(dynamic rhs) => rhs is LocalDate ? minusDate(rhs) : rhs is Period ? minusPeriod(rhs) : throw new TypeError();

  /// Compares two [LocalDate] values for equality. This requires
  /// that the dates be the same, within the same calendar.
  ///
  /// [lhs]: The first value to compare
  /// [rhs]: The second value to compare
  /// Returns: True if the two dates are the same and in the same calendar; false otherwise
  bool operator ==(dynamic rhs) => rhs is LocalDate && this._yearMonthDayCalendar == rhs._yearMonthDayCalendar;

// Comparison operators: note that we can't use YearMonthDayCalendar.Compare, as only the calendar knows whether it can use
// naive comparisons.

  /// Compares two dates to see if the left one is strictly earlier than the right
  /// one.
  ///
  /// Only dates with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  ///
  /// [lhs]: First operand of the comparison
  /// [rhs]: Second operand of the comparison
  /// [ArgumentException]: The calendar system of [rhs] is not the same
  /// as the calendar of [lhs].
  /// Returns: true if the [lhs] is strictly earlier than [rhs], false otherwise.
  bool operator <(LocalDate rhs)
  {
    Preconditions.checkArgument(this.calendar == rhs.calendar, 'rhs', "Only values in the same calendar can be compared");
    return this.compareTo(rhs) < 0;
  }

  /// Compares two dates to see if the left one is earlier than or equal to the right
  /// one.
  ///
  /// Only dates with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  ///
  /// [lhs]: First operand of the comparison
  /// [rhs]: Second operand of the comparison
  /// [ArgumentException]: The calendar system of [rhs] is not the same
  /// as the calendar of [lhs].
  /// Returns: true if the [lhs] is earlier than or equal to [rhs], false otherwise.
  bool operator <=(LocalDate rhs)
  {
    Preconditions.checkArgument(this.calendar== rhs.calendar, 'rhs', "Only values in the same calendar can be compared");
    return this.compareTo(rhs) <= 0;
  }

  /// Compares two dates to see if the left one is strictly later than the right
  /// one.
  ///
  /// Only dates with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  ///
  /// [lhs]: First operand of the comparison
  /// [rhs]: Second operand of the comparison
  /// [ArgumentException]: The calendar system of [rhs] is not the same
  /// as the calendar of [lhs].
  /// Returns: true if the [lhs] is strictly later than [rhs], false otherwise.
  bool operator >(LocalDate rhs)
  {
    Preconditions.checkArgument(this.calendar == rhs.calendar, 'rhs', "Only values in the same calendar can be compared");
    return this.compareTo(rhs) > 0;
  }

  /// Compares two dates to see if the left one is later than or equal to the right
  /// one.
  ///
  /// Only dates with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  ///
  /// [lhs]: First operand of the comparison
  /// [rhs]: Second operand of the comparison
  /// [ArgumentException]: The calendar system of [rhs] is not the same
  /// as the calendar of [lhs].
  /// Returns: true if the [lhs] is later than or equal to [rhs], false otherwise.
  bool operator >=(LocalDate rhs)
  {
    Preconditions.checkArgument(calendar == rhs.calendar, 'rhs', "Only values in the same calendar can be compared");
    return compareTo(rhs) >= 0;
  }

  /// Indicates whether this date is earlier, later or the same as another one.
  ///
  /// Only dates within the same calendar systems can be compared with this method. Attempting to compare
  /// dates within different calendars will fail with an [ArgumentException]. Ideally, comparisons
  /// between values in different calendars would be a compile-time failure, but failing at execution time
  /// is almost always preferable to continuing.
  ///
  /// [other]: The other date to compare this one with
  /// [ArgumentException]: The calendar system of [other] is not the
  /// same as the calendar system of this value.
  /// A value less than zero if this date is earlier than [other];
  /// zero if this date is the same as [other]; a value greater than zero if this date is
  /// later than [other].
  int compareTo(LocalDate other)
  {
    Preconditions.checkArgument(calendar == other?.calendar, 'other', "Only values with the same calendar system can be compared");
    return calendar.compare(_yearMonthDay, other._yearMonthDay);
  }

  /// Returns the later date of the given two.
  ///
  /// [x]: The first date to compare.
  /// [y]: The second date to compare.
  /// [ArgumentException]: The two dates have different calendar systems.
  /// Returns: The later date of [x] or [y].
  static LocalDate max(LocalDate x, LocalDate y)
  {
    Preconditions.checkArgument(x.calendar == y.calendar, 'y', "Only values with the same calendar system can be compared");
    return x > y ? x : y;
  }

  /// Returns the earlier date of the given two.
  ///
  /// [x]: The first date to compare.
  /// [y]: The second date to compare.
  /// [ArgumentException]: The two dates have different calendar systems.
  /// Returns: The earlier date of [x] or [y].
  static LocalDate min(LocalDate x, LocalDate y)
  {
    Preconditions.checkArgument(x.calendar == y.calendar, 'y', "Only values with the same calendar system can be compared");
    return x < y ? x : y;
  }

  /// Returns a hash code for this local date.
  ///
  /// Returns: A hash code for this local date.
  @override int get hashCode => _yearMonthDayCalendar.hashCode;

  // todo: consider removing -- does this make since in Dart?
  /// Compares two [LocalDate] values for equality. This requires
  /// that the dates be the same, within the same calendar.
  ///
  /// [other]: The value to compare this date with.
  /// Returns: True if the given value is another local date equal to this one; false otherwise.
  bool equals(LocalDate other) => this == other;

  /// Resolves this local date into a [ZonedDateTime] in the given time zone representing the
  /// start of this date in the given zone.
  ///
  /// This is a convenience method for calling [DateTimeZone.AtStartOfDay(LocalDate)].
  ///
  /// [zone]: The time zone to map this local date into
  /// [SkippedTimeException]: The entire day was skipped due to a very large time zone transition.
  /// (This is extremely rare.)
  /// Returns: The [ZonedDateTime] representing the earliest time on this date, in the given time zone.
  ZonedDateTime atStartOfDayInZone(DateTimeZone zone)
  {
    Preconditions.checkNotNull(zone, 'zone');
    return zone.atStartOfDay(this);
  }

  /// Creates a new LocalDate representing the same physical date, but in a different calendar.
  /// The returned LocalDate is likely to have different field values to this one.
  /// For example, January 1st 1970 in the Gregorian calendar was December 19th 1969 in the Julian calendar.
  ///
  /// [calendar]: The calendar system to convert this local date to.
  /// Returns: The converted LocalDate
  LocalDate withCalendar(CalendarSystem calendar)
  {
    Preconditions.checkNotNull(calendar, 'calendar');
    return new LocalDate._fromDaysSinceEpoch(_daysSinceEpoch, calendar);
  }

  /// Returns a new LocalDate representing the current value with the given number of years added.
  ///
  /// If the resulting date is invalid, lower fields (typically the day of month) are reduced to find a valid value.
  /// For example, adding one year to February 29th 2012 will return February 28th 2013; subtracting one year from
  /// February 29th 2012 will return February 28th 2011.
  ///
  /// [years]: The number of years to add
  /// Returns: The current value plus the given number of years.
  LocalDate plusYears(int years) => DatePeriodFields.yearsField.add(this, years);

  /// Returns a new LocalDate representing the current value with the given number of months added.
  ///
  /// This method does not try to maintain the year of the current value, so adding four months to a value in 
  /// October will result in a value in the following February.
  ///
  /// If the resulting date is invalid, the day of month is reduced to find a valid value.
  /// For example, adding one month to January 30th 2011 will return February 28th 2011; subtracting one month from
  /// March 30th 2011 will return February 28th 2011.
  ///
  /// [months]: The number of months to add
  /// Returns: The current date plus the given number of months
  LocalDate plusMonths(int months) => DatePeriodFields.monthsField.add(this, months);

  /// Returns a new LocalDate representing the current value with the given number of days added.
  ///
  /// This method does not try to maintain the month or year of the current value, so adding 3 days to a value of January 30th
  /// will result in a value of February 2nd.
  ///
  /// [days]: The number of days to add
  /// Returns: The current value plus the given number of days.
  LocalDate plusDays(int days) => DatePeriodFields.daysField.add(this, days);

  /// Returns a new LocalDate representing the current value with the given number of weeks added.
  ///
  /// [weeks]: The number of weeks to add
  /// Returns: The current value plus the given number of weeks.
  LocalDate plusWeeks(int weeks) => DatePeriodFields.weeksField.add(this, weeks);

  /// Returns the next [LocalDate] falling on the specified [IsoDayOfWeek].
  /// This is a strict "next" - if this date on already falls on the target
  /// day of the week, the returned value will be a week later.
  ///
  /// [targetDayOfWeek]: The ISO day of the week to return the next date of.
  /// Returns: The next [LocalDate] falling on the specified day of the week.
  /// [InvalidOperationException]: The underlying calendar doesn't use ISO days of the week.
  /// [ArgumentOutOfRangeException]: [targetDayOfWeek] is not a valid day of the
  /// week (Monday to Sunday).
  LocalDate next(IsoDayOfWeek targetDayOfWeek)
  {
    // Avoids boxing...
    if (targetDayOfWeek < IsoDayOfWeek.monday || targetDayOfWeek > IsoDayOfWeek.sunday)
    {
      throw new RangeError('targetDayOfWeek');
    }
    // This will throw the desired exception for calendars with different week systems.
    IsoDayOfWeek thisDay = dayOfWeek;
    int difference = targetDayOfWeek - thisDay;
    if (difference <= 0)
    {
      difference += 7;
    }
    return plusDays(difference);
  }

  /// Returns the previous [LocalDate] falling on the specified [IsoDayOfWeek].
  /// This is a strict "previous" - if this date on already falls on the target
  /// day of the week, the returned value will be a week earlier.
  ///
  /// [targetDayOfWeek]: The ISO day of the week to return the previous date of.
  /// Returns: The previous [LocalDate] falling on the specified day of the week.
  /// [InvalidOperationException]: The underlying calendar doesn't use ISO days of the week.
  /// [ArgumentOutOfRangeException]: [targetDayOfWeek] is not a valid day of the
  /// week (Monday to Sunday).
  LocalDate previous(IsoDayOfWeek targetDayOfWeek)
  {
    // Avoids boxing...
    if (targetDayOfWeek < IsoDayOfWeek.monday || targetDayOfWeek > IsoDayOfWeek.sunday)
    {
      throw new RangeError('targetDayOfWeek');
    }
    // This will throw the desired exception for calendars with different week systems.
    IsoDayOfWeek thisDay = dayOfWeek;
    int difference = targetDayOfWeek - thisDay;
    if (difference >= 0)
    {
      difference -= 7;
    }
    return plusDays(difference);
  }

  /// Returns an [OffsetDate] for this local date with the given offset.
  ///
  /// This method is purely a convenient alternative to calling the [OffsetDate] constructor directly.
  /// [offset]: The offset to apply.
  /// Returns: The result of this date offset by the given amount.
  OffsetDate withOffset(Offset offset) => new OffsetDate(this, offset);

  /// Combines this [LocalDate] with the given [LocalTime]
  /// into a single [LocalDateTime].
  /// Fluent alternative to `operator+()`.
  ///
  /// [time]: The time to combine with this date.
  /// Returns: The [LocalDateTime] representation of the given time on this date
  LocalDateTime at(LocalTime time) => new LocalDateTime(this, time);

  LocalDate adjust(LocalDate Function(LocalDate) adjuster) => adjuster(this);

  /// Returns a [String] that represents this instance.
  ///
  /// The value of the current instance in the default format pattern ("D"), using the current thread's
  /// culture to obtain a format provider.
  // @override String toString() => TextShim.toStringLocalDate(this); // LocalDatePattern.BclSupport.Format(this, null, CultureInfo.CurrentCulture);
  @override String toString([String patternText = null, /*IFormatProvider*/ dynamic formatProvider = null]) =>
      ILocalDatePattern.bclSupport.format(this, patternText, formatProvider ?? CultureInfo.currentCulture);
}

