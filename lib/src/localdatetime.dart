// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
// import 'package:quiver_hashcode/hashcode.dart';
import 'package:time_machine/src/time_machine_internal.dart';

// TODO(feature): Calendar-neutral comparer.

@internal
abstract class ILocalDateTime {
  static LocalInstant toLocalInstant(LocalDateTime localDateTime) => localDateTime._toLocalInstant();
  static LocalDateTime fromInstant(LocalInstant localInstant) => LocalDateTime._localInstant(localInstant);
}

/// A date and time in a particular calendar system. A LocalDateTime value does not represent an
/// instant on the global time line, because it has no associated time zone: 'November 12th 2009 7pm, ISO calendar'
/// occurred at different instants for different people around the world.
///
/// This type defaults to using the ISO calendar system unless a different calendar system is
/// specified.
///
/// Values can freely be compared for equality: a value in a different calendar system is not equal to
/// a value in a different calendar system. However, ordering comparisons (either via the [CompareTo] method
/// or via operators) fail with [ArgumentError]; attempting to compare values in different calendars
/// almost always indicates a bug in the calling code.
@immutable
class LocalDateTime implements Comparable<LocalDateTime> {
  /// Gets the date portion of this local date and time as a [LocalDate] in the same calendar system as this value.
  final LocalDate calendarDate;
  /// Gets the time portion of this local date and time as a [LocalTime].
  final LocalTime clockTime;

  /// Initializes a new instance of the [LocalDateTime] struct using the ISO
  /// calendar system.
  ///
  /// * [localInstant]: The local instant.
  ///
  /// Returns: The resulting date/time.
  LocalDateTime._localInstant(LocalInstant localInstant)
      : calendarDate = LocalDate.fromEpochDay(localInstant.daysSinceEpoch),
        clockTime = ILocalTime.trustedNanoseconds(localInstant.nanosecondOfDay);

  /// Initializes a new instance of [LocalDateTime].
  ///
  /// * [year]: The year. This is the 'absolute year', so, for
  /// the ISO calendar, a value of 0 means 1 BC, for example.
  /// * [month]: The month of year.
  /// * [day]: The day of month.
  /// * [hour]: The hour.
  /// * [minute]: The minute.
  /// * [second]: The second.
  /// * [ms][us][ns]: The millisecond or microsecond or nanosecond of the second.
  /// * [calendar]: The calendar. ISO calendar default.
  ///
  /// Returns: The resulting date/time.
  ///
  /// * [ArgumentOutOfRangeException]: The parameters do not form a valid date/time.
  ///
  /// see: [LocalTime] for potential future API change
  LocalDateTime(int year, int month, int day, int hour, int minute, int second, {int? ms, int? us, int? ns, CalendarSystem? calendar})
      : this.localDateAtTime(LocalDate(year, month, day, calendar), LocalTime(hour, minute, second, ms:ms, us:us, ns:ns));
  // (year, month day, hour, minute) are basically required, but if we name a few of them, we should probably name them all?

  @wasInternal
  const LocalDateTime.localDateAtTime(this.calendarDate, this.clockTime);

  /// Produces a [LocalDateTime] based on your [Clock.current] and your [DateTimeZone.local].
  ///
  /// * [calendar]: The calendar system to convert into, defaults to ISO calendar
  ///
  /// Returns: A new [LocalDateTime] with the same values as the local clock.
  factory LocalDateTime.now() => Instant.now().inLocalZone().localDateTime;

  /// Converts a [DateTime] of any kind to a [LocalDateTime] in the specified or ISO calendar. This does not perform
  /// any time zone conversions, so a [DateTime] with a [DateTime.isUtc] == `true`
  /// will still have the same day/hour/minute etc - it won't be converted into the local system time.
  ///
  /// * [dateTime]: Value to convert into a Time Machine local date and time
  /// * [calendar]: The calendar system to convert into, defaults to [LocalDateTime] in the ISO calendar.
  ///
  /// Returns: A new [LocalDateTime] with the same values as the specified [DateTime].
  factory LocalDateTime.dateTime(DateTime dateTime, [CalendarSystem? calendar]) {
    int ns;
    int days;

    if (Platform.isWeb) {
      var ms = dateTime.millisecondsSinceEpoch + dateTime.timeZoneOffset.inMilliseconds;
      days = ms ~/ TimeConstants.millisecondsPerDay;
      ms -= days * TimeConstants.millisecondsPerDay;
      if (ms < 0) days--;
      ns = TimeConstants.nanosecondsPerMillisecond *
          (ms % TimeConstants.millisecondsPerDay);
    } else {
      var us = dateTime.microsecondsSinceEpoch + dateTime.timeZoneOffset.inMicroseconds;
      days = us ~/ TimeConstants.microsecondsPerDay;
      us -= days * TimeConstants.microsecondsPerDay;
      if (us < 0) days--;
      ns = TimeConstants.nanosecondsPerMicrosecond *
          (us % TimeConstants.microsecondsPerDay);
    }

    return LocalDateTime.localDateAtTime(
        LocalDate.fromEpochDay(days, calendar),
        ILocalTime.trustedNanoseconds(ns));
  }

  /// Gets the calendar system associated with this local date and time.
  CalendarSystem get calendar => calendarDate.calendar;

  /// Gets the year of this local date and time.
  /// This returns the 'absolute year', so, for the ISO calendar,
  /// a value of 0 means 1 BC, for example.
  int get year => calendarDate.year;

  /// Gets the year of this local date and time within its era.
  int get yearOfEra => calendarDate.yearOfEra;

  /// Gets the era of this local date and time.
  Era get era => calendarDate.era;

  /// Gets the month of this local date and time within the year.
  int get monthOfYear => calendarDate.monthOfYear;

  /// Gets the day of this local date and time within the year.
  int get dayOfYear => calendarDate.dayOfYear;

  /// Gets the day of this local date and time within the month.
  int get dayOfMonth => calendarDate.dayOfMonth;

  /// Gets the week day of this local date and time expressed as an [DayOfWeek] value.
  DayOfWeek get dayOfWeek => calendarDate.dayOfWeek;

  /// Gets the hour of day of this local date and time, in the range 0 to 23 inclusive.
  int get hourOfDay => clockTime.timeSinceMidnight.hourOfDay;

  /// Gets the hour of the half-day of this local date and time, in the range 1 to 12 inclusive.
  int get hourOf12HourClock => clockTime.timeSinceMidnight.hourOf12HourClock;

  /// Gets the minute of this local date and time, in the range 0 to 59 inclusive.
  int get minuteOfHour => clockTime.timeSinceMidnight.minuteOfHour;

  /// Gets the second of this local date and time within the minute, in the range 0 to 59 inclusive.
  int get secondOfMinute => clockTime.timeSinceMidnight.secondOfMinute;

  /// Gets the millisecond of this local date and time within the second, in the range 0 to 999 inclusive.
  int get millisecondOfSecond => clockTime.timeSinceMidnight.millisecondOfSecond;

  /// Gets the nanosecond of this local time within the second, in the range 0 to 999,999,999 inclusive.
  int get nanosecondOfSecond => clockTime.timeSinceMidnight.nanosecondOfSecond;

  /// Gets the nanosecond of this local time within the second, in the range 0 to 999,999,999 inclusive.
  int get microsecondOfSecond => clockTime.timeSinceMidnight.microsecondOfSecond;

  // Time get timeSinceMidnight => localTime.timeSinceMidnight;

  /// Constructs a [DateTime] from this value which has a [DateTime.isUtc] == false;
  ///
  /// If the date and time is not on a millisecond\microsecond boundary (the unit of granularity of DateTime on web\vm),
  /// the value will be truncated towards the start of time.
  ///
  /// Returns: A [DateTime] value for the same date and time as this value.
  DateTime toDateTimeLocal() {
    var isUtc = DateTimeZone.local == DateTimeZone.utc;
    return isUtc ? inUtc().localDateTime._toDateTimeLocalUtc() : _toDateTimeLocal();
  }

  DateTime _toDateTimeLocal() {
    if (Platform.isWeb) {
      return DateTime(
        year,
        monthOfYear,
        dayOfMonth,
        hourOfDay,
        minuteOfHour,
        secondOfMinute,
        millisecondOfSecond,
      );
    } else {
      return DateTime(
        year,
        monthOfYear,
        dayOfMonth,
        hourOfDay,
        minuteOfHour,
        secondOfMinute,
        0,
        microsecondOfSecond,
      );
    }
  }

  DateTime _toDateTimeLocalUtc() {
    if (Platform.isWeb) {
      return DateTime.utc(
        year,
        monthOfYear,
        dayOfMonth,
        hourOfDay,
        minuteOfHour,
        secondOfMinute,
        millisecondOfSecond,
      );
    } else {
      return DateTime.utc(
        year,
        monthOfYear,
        dayOfMonth,
        hourOfDay,
        minuteOfHour,
        secondOfMinute,
        0,
        microsecondOfSecond,
      );
    }
  }

  LocalInstant _toLocalInstant() => LocalInstant.daysNanos(calendarDate.epochDay, clockTime.timeSinceMidnight.inNanoseconds);

  /// Indicates whether the current object is equal to another object of the same type.
  ///
  /// * [other]: An object to compare with this object.
  ///
  /// Returns: true if the current object is equal to the [other] parameter; otherwise, false.
  bool equals(LocalDateTime other) => calendarDate == other.calendarDate && clockTime == other.clockTime;

  /// Implements the operator == (equality).
  ///
  /// * [this]: The left hand side of the operator.
  /// * [other]: The right hand side of the operator.
  ///
  /// Returns: `true` if values are equal to each other, otherwise `false`.
  @override
  bool operator ==(Object other) => other is LocalDateTime && equals(other);

  /// Compares two LocalDateTime values to see if the left one is strictly earlier than the right
  /// one.
  ///
  /// Only values with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  ///
  /// * [this]: First operand of the comparison
  /// * [other]: Second operand of the comparison
  ///
  /// Returns: true if the [this] is strictly earlier than [other], false otherwise.
  ///
  /// * [ArgumentError]: The calendar system of [other] is not the same
  /// as the calendar of [this].
  bool operator <(LocalDateTime other) {
    Preconditions.checkArgument(calendar == other.calendar, 'rhs', "Only values in the same calendar can be compared");
    return compareTo(other) < 0;
  }

  /// Compares two LocalDateTime values to see if the left one is earlier than or equal to the right
  /// one.
  ///
  /// Only values with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  ///
  /// * [this]: First operand of the comparison
  /// * [other]: Second operand of the comparison
  ///
  /// Returns: true if the [this] is earlier than or equal to [other], false otherwise.
  ///
  /// * [ArgumentError]: The calendar system of [other] is not the same
  /// as the calendar of [this].
  bool operator <=(LocalDateTime other) {
    Preconditions.checkArgument(calendar == other.calendar, 'rhs', "Only values in the same calendar can be compared");
    return compareTo(other) <= 0;
  }

  /// Compares two LocalDateTime values to see if the left one is strictly later than the right
  /// one.
  ///
  /// Only values with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  ///
  /// * [this]: First operand of the comparison
  /// * [other]: Second operand of the comparison
  ///
  /// Returns: true if the [this] is strictly later than [other], false otherwise.
  ///
  /// * [ArgumentError]: The calendar system of [other] is not the same
  /// as the calendar of [this].
  bool operator >(LocalDateTime other) {
    Preconditions.checkArgument(calendar == other.calendar, 'rhs', "Only values in the same calendar can be compared");
    return compareTo(other) > 0;
  }

  /// Compares two LocalDateTime values to see if the left one is later than or equal to the right
  /// one.
  ///
  /// Only values with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  ///
  /// * [this]: First operand of the comparison
  /// * [other]: Second operand of the comparison
  ///
  /// Returns: true if the [this] is later than or equal to [other], false otherwise.
  ///
  /// * [ArgumentError]: The calendar system of [other] is not the same
  /// as the calendar of [this].
  bool operator >=(LocalDateTime other) {
    // todo: what variable should these checkArgument's give?
    Preconditions.checkArgument(calendar == other.calendar, 'rhs', "Only values in the same calendar can be compared");
    return compareTo(other) >= 0;
  }

  /// Indicates whether this date/time is earlier, later or the same as another one.
  ///
  /// Only date/time values within the same calendar systems can be compared with this method. Attempting to compare
  /// values within different calendars will fail with an [ArgumentError]. Ideally, comparisons
  /// is almost always preferable to continuing.
  ///
  /// * [other]: The other local date/time to compare with this value.
  ///
  /// Returns: A value less than zero if this date/time is earlier than [other];
  /// zero if this date/time is the same as [other]; a value greater than zero if this date/time is
  /// later than [other].
  ///
  /// * [ArgumentError]: The calendar system of [other] is not the
  /// same as the calendar system of this value.
  @override
  int compareTo(LocalDateTime? other) {
    // This will check calendars...
    if (other == null) return 1;
    int dateComparison = calendarDate.compareTo(other.calendarDate);
    if (dateComparison != 0) {
      return dateComparison;
    }
    return clockTime.compareTo(other.clockTime);
  }

  /// Adds a period to a local date/time. Fields are added in the order provided by the period.
  /// This is a convenience operator over the [add] method.
  ///
  /// * [localDateTime]: Initial local date and time
  /// * [period]: Period to add
  ///
  /// Returns: The resulting local date and time
  LocalDateTime operator +(Period period) => add(period);

  /// Subtracts a period from a local date/time. Fields are subtracted in the order provided by the period.
  /// This is a convenience operator over the [Minus(Period)] method.
  ///
  /// * [this]: Initial local date and time
  /// * [period]: Period to subtract
  ///
  /// Returns: The resulting local date and time
  LocalDateTime operator -(Period period) => subtract(period);

  /// Add the specified period to the date and time. Friendly alternative to `operator+()`.
  ///
  /// * [localDateTime]: Initial local date and time
  /// * [period]: Period to add
  ///
  /// Returns: The resulting local date and time
  static LocalDateTime plus(LocalDateTime localDateTime, Period period) => localDateTime.add(period);

  /// Subtracts the specified period from the date and time. Friendly alternative to `operator-()`.
  ///
  /// * [localDateTime]: Initial local date and time
  /// * [period]: Period to subtract
  ///
  /// Returns: The resulting local date and time
  static LocalDateTime minus(LocalDateTime localDateTime, Period period) => localDateTime.subtract(period);

  /// Subtracts one date/time from another, returning the result as a [Period].
  ///
  /// This is simply a convenience method for calling [Period.Between(LocalDateTime,LocalDateTime)].
  /// The calendar systems of the two date/times must be the same.
  ///
  /// * [end]: The date/time to subtract from
  /// * [start]: The date/time to subtract
  ///
  /// Returns: The result of subtracting one date/time from another.
  static Period difference(LocalDateTime end, LocalDateTime start) => end.periodSince(start);

  /// Adds a period to this local date/time. Fields are added in the order provided by the period.
  ///
  /// * [period]: Period to add
  ///
  /// Returns: The resulting local date and time
  LocalDateTime add(Period period) {
    Preconditions.checkNotNull(period, 'period');
    return IPeriod.addDateTimeTo(period, calendarDate, clockTime, 1);
  }

  // dynamic operator -(dynamic other) => other is Period ? minusPeriod(other) : other is LocalDateTime ? minusLocalDateTime(other) : throw new TypeError();
  // Period operator -(LocalDateTime rhs) => Period.Between(rhs, this);

  /// Subtracts a period from a local date/time. Fields are subtracted in the order provided by the period.
  ///
  /// * [period]: Period to subtract
  ///
  /// Returns: The resulting local date and time
  LocalDateTime subtract(Period period) {
    Preconditions.checkNotNull(period, 'period');
    return IPeriod.addDateTimeTo(period, calendarDate, clockTime, -1);
  }

  /// Subtracts the specified date/time from this date/time, returning the result as a [Period].
  /// Cognitively similar to: `this - localDateTime`.
  ///
  /// The specified date/time must be in the same calendar system as this.
  ///
  /// * [localDateTime]: The date/time to subtract from this
  ///
  /// Returns: The difference between the specified date/time and this one
  Period periodSince(LocalDateTime localDateTime) => Period.differenceBetweenDateTime(localDateTime, this);

  /// Subtracts the specified date/time from this date/time, returning the result as a [Period].
  /// Cognitively similar to: `localDateTime - this`.
  ///
  /// The specified date/time must be in the same calendar system as this.
  ///
  /// * [localDateTime]: The date/time to subtract this from
  ///
  /// Returns: The difference between the specified date/time and this one
  Period periodUntil(LocalDateTime localDateTime) => Period.differenceBetweenDateTime(this, localDateTime);

  /// Returns a hash code for this instance.
  @override int get hashCode => hash3(calendarDate, clockTime, calendar);

  /// Returns this date/time, with the given date adjuster applied to it, maintaining the existing time of day.
  ///
  /// If the adjuster attempts to construct an
  /// invalid date (such as by trying to set a day-of-month of 30 in February), any exception thrown by
  /// that construction attempt will be propagated through this method.
  ///
  /// * [adjuster]: The adjuster to apply.
  ///
  /// Returns: The adjusted date/time.
  LocalDateTime adjustDate(LocalDate Function(LocalDate) adjuster) => calendarDate.adjust(adjuster).at(clockTime);

  /// Returns this date/time, with the given time adjuster applied to it, maintaining the existing date.
  ///
  /// If the adjuster attempts to construct an invalid time, any exception thrown by
  /// that construction attempt will be propagated through this method.
  ///
  /// * [adjuster]: The adjuster to apply.
  ///
  /// Returns: The adjusted date/time.
  LocalDateTime adjustTime(LocalTime Function(LocalTime) adjuster) => calendarDate.at(clockTime.adjust(adjuster));

  /// Creates a new LocalDateTime representing the same physical date and time, but in a different calendar.
  /// The returned LocalDateTime is likely to have different date field values to this one.
  /// For example, January 1st 1970 in the Gregorian calendar was December 19th 1969 in the Julian calendar.
  ///
  /// * [calendar]: The calendar system to convert this local date to.
  ///
  /// Returns: The converted LocalDateTime.
  LocalDateTime withCalendar(CalendarSystem calendar) {
    Preconditions.checkNotNull(calendar, 'calendar');
    return LocalDateTime.localDateAtTime(calendarDate.withCalendar(calendar), clockTime);
  }

  /// Returns a new LocalDateTime representing the current value with the given number of years added.
  ///
  /// If the resulting date is invalid, lower fields (typically the day of month) are reduced to find a valid value.
  /// For example, adding one year to February 29th 2012 will return February 28th 2013; subtracting one year from
  /// February 29th 2012 will return February 28th 2011.
  ///
  /// * [years]: The number of years to add
  ///
  /// Returns: The current value plus the given number of years.
  LocalDateTime addYears(int years) => LocalDateTime.localDateAtTime(calendarDate.addYears(years), clockTime);
  LocalDateTime subtractYears(int years) => addYears(-years);

  /// Returns a new LocalDateTime representing the current value with the given number of months added.
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
  /// Returns: The current value plus the given number of months.
  LocalDateTime addMonths(int months) => LocalDateTime.localDateAtTime(calendarDate.addMonths(months), clockTime);
  LocalDateTime subtractMonths(int months) => addMonths(-months);

  /// Returns a new LocalDateTime representing the current value with the given number of days added.
  ///
  /// This method does not try to maintain the month or year of the current value, so adding 3 days to a value on January 30th
  /// will result in a value on February 2nd.
  ///
  /// * [days]: The number of days to add
  ///
  /// Returns: The current value plus the given number of days.
  LocalDateTime addDays(int days) => LocalDateTime.localDateAtTime(calendarDate.addDays(days), clockTime);
  LocalDateTime subtractDays(int days) => addDays(-days);

  /// Returns a new LocalDateTime representing the current value with the given number of weeks added.
  ///
  /// * [weeks]: The number of weeks to add
  ///
  /// Returns: The current value plus the given number of weeks.
  LocalDateTime addWeeks(int weeks) => LocalDateTime.localDateAtTime(calendarDate.addWeeks(weeks), clockTime);
  LocalDateTime subtractWeeks(int weeks) => addWeeks(-weeks);

  /// Returns a new LocalDateTime representing the current value with the given number of hours added.
  ///
  /// * [hours]: The number of hours to add
  ///
  /// Returns: The current value plus the given number of hours.
  LocalDateTime addHours(int hours) => TimePeriodField.hours.addDateTime(this, hours);
  LocalDateTime subtractHours(int hours) => addHours(-hours);

  /// Returns a new LocalDateTime representing the current value with the given number of minutes added.
  ///
  /// * [minutes]: The number of minutes to add
  ///
  /// Returns: The current value plus the given number of minutes.
  LocalDateTime addMinutes(int minutes) => TimePeriodField.minutes.addDateTime(this, minutes);
  LocalDateTime subtractMinutes(int minutes) => addMinutes(-minutes);

  /// Returns a new LocalDateTime representing the current value with the given number of seconds added.
  ///
  /// * [seconds]: The number of seconds to add
  ///
  /// Returns: The current value plus the given number of seconds.
  LocalDateTime addSeconds(int seconds) => TimePeriodField.seconds.addDateTime(this, seconds);
  LocalDateTime subtractSeconds(int seconds) => addSeconds(-seconds);

  /// Returns a new LocalDateTime representing the current value with the given number of milliseconds added.
  ///
  /// * [milliseconds]: The number of milliseconds to add
  ///
  /// Returns: The current value plus the given number of milliseconds.
  LocalDateTime addMilliseconds(int milliseconds) => TimePeriodField.milliseconds.addDateTime(this, milliseconds);
  LocalDateTime subtractMilliseconds(int milliseconds) => addMilliseconds(-milliseconds);

  /// Returns a new LocalDateTime representing the current value with the given number of ticks added.
  ///
  /// * [microseconds]: The number of ticks to add
  ///
  /// Returns: The current value plus the given number of ticks.
  LocalDateTime addMicroseconds(int microseconds) => TimePeriodField.microseconds.addDateTime(this, microseconds);
  LocalDateTime subtractMicroseconds(int microseconds) => addMicroseconds(-microseconds);

  /// Returns a new LocalDateTime representing the current value with the given number of nanoseconds added.
  ///
  /// * [nanoseconds]: The number of nanoseconds to add
  ///
  /// Returns: The current value plus the given number of nanoseconds.
  LocalDateTime addNanoseconds(int nanoseconds) => TimePeriodField.nanoseconds.addDateTime(this, nanoseconds);
  LocalDateTime subtractNanoseconds(int nanoseconds) => addNanoseconds(-nanoseconds);

  /// Returns the next [LocalDateTime] falling on the specified [DayOfWeek],
  /// at the same time of day as this value.
  /// This is a strict 'next' - if this value on already falls on the target
  /// day of the week, the returned value will be a week later.
  ///
  /// * [targetDayOfWeek]: The ISO day of the week to return the next date of.
  ///
  /// Returns: The next [LocalDateTime] falling on the specified day of the week.
  ///
  /// * [InvalidOperationException]: The underlying calendar doesn't use ISO days of the week.
  /// * [ArgumentOutOfRangeException]: [targetDayOfWeek] is not a valid day of the
  /// week (Monday to Sunday).
  LocalDateTime next(DayOfWeek targetDayOfWeek) => LocalDateTime.localDateAtTime(calendarDate.next(targetDayOfWeek), clockTime);

  /// Returns the previous [LocalDateTime] falling on the specified [DayOfWeek],
  /// at the same time of day as this value.
  /// This is a strict 'previous' - if this value on already falls on the target
  /// day of the week, the returned value will be a week earlier.
  ///
  /// * [targetDayOfWeek]: The ISO day of the week to return the previous date of.
  ///
  /// Returns: The previous [LocalDateTime] falling on the specified day of the week.
  ///
  /// * [InvalidOperationException]: The underlying calendar doesn't use ISO days of the week.
  /// * [ArgumentOutOfRangeException]: [targetDayOfWeek] is not a valid day of the
  /// week (Monday to Sunday).
  LocalDateTime previous(DayOfWeek targetDayOfWeek) => LocalDateTime.localDateAtTime(calendarDate.previous(targetDayOfWeek), clockTime);

  /// Returns an [OffsetDateTime] for this local date/time with the given offset.
  ///
  /// This method is purely a convenient alternative to calling the [OffsetDateTime] constructor directly.
  ///
  /// * [offset]: The offset to apply.
  ///
  /// Returns: The result of this local date/time offset by the given amount.
  OffsetDateTime withOffset(Offset offset) => IOffsetDateTime.lessTrust(calendarDate, clockTime, offset);

  /// Returns the mapping of this local date/time within [DateTimeZone.utc].
  ///
  /// As UTC is a fixed time zone, there is no chance that this local date/time is ambiguous or skipped.
  ///
  /// Returns: The result of mapping this local date/time in UTC.
  ZonedDateTime inUtc() =>
  // Use the internal constructors to avoid validation. We know it will be fine.
  IZonedDateTime.trusted(IOffsetDateTime.fullTrust(this, Offset.zero), DateTimeZone.utc);

  // todo: are these convenience functions still needed? (since we made the DateTimeZone ZonedDateTime constructors, constructors on ZonedDateTime?)
  /// Returns the mapping of this local date/time within the given [DateTimeZone],
  /// with 'strict' rules applied such that an exception is thrown if either the mapping is
  /// ambiguous or the time is skipped.
  ///
  /// See [inZoneLeniently] and [inZone] for alternative ways to map a local time to a
  /// specific instant.
  /// This is solely a convenience method for calling [ZonedDateTime.atStrictly].
  ///
  /// * [zone]: The time zone in which to map this local date/time.
  ///
  /// Returns: The result of mapping this local date/time in the given time zone.
  ///
  /// * [SkippedTimeException]: This local date/time is skipped in the given time zone.
  /// * [AmbiguousTimeException]: This local date/time is ambiguous in the given time zone.
  ZonedDateTime inZoneStrictly(DateTimeZone zone) {
    Preconditions.checkNotNull(zone, 'zone');
    return ZonedDateTime.atStrictly(this, zone);
  }

  /// Returns the mapping of this local date/time within the given [DateTimeZone],
  /// with 'lenient' rules applied such that ambiguous values map to the earlier of the alternatives, and
  /// 'skipped' values are shifted forward by the duration of the "gap".
  ///
  /// See [inZoneStrictly] and [inZone] for alternative ways to map a local time to a
  /// specific instant.
  ///
  /// This is solely a convenience method for calling [ZonedDateTime.atLeniently].
  ///
  /// Note: The behavior of this method was changed in version 2.0 to fit the most commonly seen real-world
  /// usage pattern.  Previous versions returned the later instance of ambiguous values, and returned the start of
  /// the zone interval after the gap for skipped value.  The previous functionality can still be used if desired,
  /// by using [InZone(DateTimeZone, ZoneLocalMappingResolver)] and passing a resolver that combines the
  /// * [Resolvers.returnLater] and [Resolvers.returnStartOfIntervalAfter] resolvers.
  ///
  /// * [zone]: The time zone in which to map this local date/time.
  ///
  /// Returns: The result of mapping this local date/time in the given time zone.
  ZonedDateTime inZoneLeniently(DateTimeZone zone) {
    Preconditions.checkNotNull(zone, 'zone');
    return ZonedDateTime.atLeniently(this, zone);
  }

  /// Resolves this local date and time into a [ZonedDateTime] in the given time zone, following
  /// the given [ZoneLocalMappingResolver] to handle ambiguity and skipped times.
  ///
  /// See [inZoneStrictly] and [inZoneLeniently] for alternative ways to map a local time
  /// to a specific instant.
  ///
  /// This is a convenience method for calling [ZonedDateTime.resolve].
  ///
  /// * [zone]: The time zone to map this local date and time into
  /// * [resolver]: The resolver to apply to the mapping.
  ///
  /// Returns: The result of resolving the mapping.
  ZonedDateTime inZone(DateTimeZone zone, ZoneLocalMappingResolver resolver) {
    Preconditions.checkNotNull(zone, 'zone');
    Preconditions.checkNotNull(resolver, 'resolver');
    return ZonedDateTime.resolve(this, zone, resolver);
  }

  /// Returns the later date/time of the given two.
  ///
  /// * [x]: The first date/time to compare.
  /// * [y]: The second date/time to compare.
  ///
  /// Returns: The later date/time of [x] or [y].
  ///
  /// * [ArgumentError]: The two date/times have different calendar systems.
  static LocalDateTime max(LocalDateTime x, LocalDateTime y) {
    Preconditions.checkArgument(x.calendar == y.calendar, 'y', "Only values with the same calendar system can be compared");
    return x > y ? x : y;
  }

  /// Returns the earlier date/time of the given two.
  ///
  /// * [x]: The first date/time to compare.
  /// * [y]: The second date/time to compare.
  ///
  /// Returns: The earlier date/time of [x] or [y].
  ///
  /// * [ArgumentError]: The two date/times have different calendar systems.
  static LocalDateTime min(LocalDateTime x, LocalDateTime y) {
    Preconditions.checkArgument(x.calendar == y.calendar, 'y', "Only values with the same calendar system can be compared");
    return x < y ? x : y;
  }

  // todo: verify default format pattern ('G'), using the current isolate
  /// Returns a [String] that represents this instance.
  ///
  /// The value of the current instance in the default format pattern ('G'), using the current isolate's
  /// culture to obtain a format provider.
  @override String toString([String? patternText, Culture? culture]) =>
      LocalDateTimePatterns.format(this, patternText, culture);
}
