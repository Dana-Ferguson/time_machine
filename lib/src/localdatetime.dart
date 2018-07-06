// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:quiver_hashcode/hashcode.dart';
import 'package:meta/meta.dart';
import 'package:time_machine/src/fields/time_machine_fields.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';
import 'utility/preconditions.dart';
import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';

// TODO(feature): Calendar-neutral comparer.

@internal
abstract class ILocalDateTime {
  static LocalInstant toLocalInstant(LocalDateTime localDateTime) => localDateTime._toLocalInstant();
  static LocalDateTime fromInstant(LocalInstant localInstant) => new LocalDateTime._fromLocalInstant(localInstant);
}

/// A date and time in a particular calendar system. A LocalDateTime value does not represent an
/// instant on the global time line, because it has no associated time zone: "November 12th 2009 7pm, ISO calendar"
/// occurred at different instants for different people around the world.
///
/// This type defaults to using the ISO calendar system unless a different calendar system is
/// specified.
///
/// Values can freely be compared for equality: a value in a different calendar system is not equal to
/// a value in a different calendar system. However, ordering comparisons (either via the [CompareTo] method
/// or via operators) fail with [ArgumentException]; attempting to compare values in different calendars
/// almost always indicates a bug in the calling code.
@immutable
class LocalDateTime implements Comparable<LocalDateTime> {
  /// Gets the date portion of this local date and time as a [LocalDate] in the same calendar system as this value.
  final LocalDate date;
  /// Gets the time portion of this local date and time as a [LocalTime].
  final LocalTime time;

  /// Initializes a new instance of the [LocalDateTime] struct using the ISO
  /// calendar system.
  ///
  /// * [localInstant]: The local instant.
  /// Returns: The resulting date/time.
  LocalDateTime._fromLocalInstant(LocalInstant localInstant)
      : date = ILocalDate.fromDaysSinceEpoch(localInstant.daysSinceEpoch),
        time = ILocalTime.fromNanoseconds(localInstant.nanosecondOfDay);

  /// Initializes a new instance of [LocalDateTime].
  ///
  /// * [year]: The year. This is the "absolute year", so, for
  /// the ISO calendar, a value of 0 means 1 BC, for example.
  /// * [month]: The month of year.
  /// * [day]: The day of month.
  /// * [hour]: The hour.
  /// * [minute]: The minute.
  /// * [second]: The second.
  /// * [millisecond]: The millisecond.
  /// * [calendar]: The calendar. ISO calendar default.
  /// Returns: The resulting date/time.
  /// * [ArgumentOutOfRangeException]: The parameters do not form a valid date/time.
  LocalDateTime.at(int year, int month, int day, int hour, int minute, {int seconds = 0, int milliseconds = 0, CalendarSystem calendar})
      : this(new LocalDate(year, month, day, calendar), new LocalTime(hour, minute, seconds, milliseconds));
  // (year, month day, hour, minute) are basically required, but if we name a few of them, we should probably name them all?
  // todo: I really don't like this one at all: LocalDateTime.at

  @wasInternal LocalDateTime(this.date, this.time);

  /// Gets the calendar system associated with this local date and time.
  CalendarSystem get calendar => date.calendar;

  /// Gets the year of this local date and time.
  /// This returns the "absolute year", so, for the ISO calendar,
  /// a value of 0 means 1 BC, for example.
  int get year => date.year;

  /// Gets the year of this local date and time within its era.
  int get yearOfEra => date.yearOfEra;

  /// Gets the era of this local date and time.
  Era get era => date.era;

  /// Gets the month of this local date and time within the year.
  int get month => date.month;

  /// Gets the day of this local date and time within the year.
  int get dayOfYear => date.dayOfYear;

  /// Gets the day of this local date and time within the month.
  int get day => date.day;

  /// Gets the week day of this local date and time expressed as an [DayOfWeek] value.
  DayOfWeek get dayOfWeek => date.dayOfWeek;

  /// Gets the hour of day of this local date and time, in the range 0 to 23 inclusive.
  int get hour => time.hour;

  /// Gets the hour of the half-day of this local date and time, in the range 1 to 12 inclusive.
  int get clockHourOfHalfDay => time.clockHourOfHalfDay;

  /// Gets the minute of this local date and time, in the range 0 to 59 inclusive.
  int get minute => time.minute;

  /// Gets the second of this local date and time within the minute, in the range 0 to 59 inclusive.
  int get second => time.second;

  /// Gets the millisecond of this local date and time within the second, in the range 0 to 999 inclusive.
  int get millisecond => time.millisecond;

  /// Gets the tick of this local time within the second, in the range 0 to 9,999,999 inclusive.
  int get tickOfSecond => time.tickOfSecond;

  /// Gets the tick of this local date and time within the day, in the range 0 to 863,999,999,999 inclusive.
  int get tickOfDay => time.tickOfDay;

  /// Gets the nanosecond of this local time within the second, in the range 0 to 999,999,999 inclusive.
  int get nanosecondOfSecond => time.nanosecondOfSecond;

  /// Gets the nanosecond of this local date and time within the day, in the range 0 to 86,399,999,999,999 inclusive.
  int get nanosecondOfDay => time.nanosecondOfDay;

  /// Constructs a [DateTime] from this value which has a [DateTime.Kind]
  /// of [DateTimeKind.Unspecified].
  ///
  /// * [DateTimeKind.Unspecified] is slightly odd - it can be treated as UTC if you use [DateTime.ToLocalTime]
  /// or as system local time if you use [DateTime.ToUniversalTime], but it's the only kind which allows
  /// you to construct a [DateTimeOffset] with an arbitrary offset, which makes it as close to
  /// the Time Machine non-system-specific "local" concept as exists in .NET.
  ///
  /// If the date and time is not on a tick boundary (the unit of granularity of DateTime) the value will be truncated
  /// towards the start of time.
  ///
  /// * [InvalidOperationException]: The date/time is outside the range of `DateTime`.
  /// Returns: A [DateTime] value for the same date and time as this value.
  DateTime toDateTimeLocal() {
    //int ticks = TickArithmetic.BoundedDaysAndTickOfDayToTicks(date.DaysSinceEpoch, time.TickOfDay) + TimeConstants.BclTicksAtUnixEpoch;
    //if (ticks < 0)
    //{
    //throw new StateError("LocalDateTime out of range of DateTime");
    //}
    // todo: on VM we should supply the microsecond
    return new DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
        time.second,
        time.millisecond);
  }


  LocalInstant _toLocalInstant() => new LocalInstant.daysNanos(ILocalDate.daysSinceEpoch(date), time.nanosecondOfDay);

  /// Converts a [DateTime] of any kind to a LocalDateTime in the specified or ISO calendar. This does not perform
  /// any time zone conversions, so a DateTime with a [DateTime.Kind] of [DateTimeKind.utc]
  /// will still have the same day/hour/minute etc - it won't be converted into the local system time.
  ///
  /// * [dateTime]: Value to convert into a Time Machine local date and time
  /// * [calendar]: The calendar system to convert into, defaults to [LocalDateTime] in the ISO calendar.
  /// Returns: A new [LocalDateTime] with the same values as the specified `DateTime`.
  factory LocalDateTime.fromDateTime(DateTime dateTime, [CalendarSystem calendar = null]) {
    var ms = dateTime.millisecondsSinceEpoch;
    var days = ms ~/ TimeConstants.millisecondsPerDay; // - 1;
    ms -= days * TimeConstants.millisecondsPerDay;

    if (calendar == null) return new LocalDateTime(
        ILocalDate.fromDaysSinceEpoch(days), ILocalTime.fromNanoseconds(ms * TimeConstants.nanosecondsPerMillisecond));
    return new LocalDateTime(ILocalDate.fromDaysSinceEpoch(days, calendar),
        ILocalTime.fromNanoseconds(ms * TimeConstants.nanosecondsPerMillisecond));
  }

  /// Indicates whether the current object is equal to another object of the same type.
  ///
  /// * [other]: An object to compare with this object.
  ///
  /// true if the current object is equal to the [other] parameter; otherwise, false.
  bool equals(LocalDateTime other) => date == other.date && time == other.time;

  /// Implements the operator == (equality).
  ///
  /// * [left]: The left hand side of the operator.
  /// * [right]: The right hand side of the operator.
  /// Returns: `true` if values are equal to each other, otherwise `false`.
  bool operator ==(dynamic right) => right is LocalDateTime && equals(right);


  /// Compares two LocalDateTime values to see if the left one is strictly earlier than the right
  /// one.
  ///
  /// Only values with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  ///
  /// * [lhs]: First operand of the comparison
  /// * [rhs]: Second operand of the comparison
  /// * [ArgumentException]: The calendar system of [rhs] is not the same
  /// as the calendar of [lhs].
  /// Returns: true if the [lhs] is strictly earlier than [rhs], false otherwise.
  bool operator <(LocalDateTime rhs) {
    if (rhs == null) return false;
    Preconditions.checkArgument(calendar == rhs.calendar, 'rhs', "Only values in the same calendar can be compared");
    return compareTo(rhs) < 0;
  }


  /// Compares two LocalDateTime values to see if the left one is earlier than or equal to the right
  /// one.
  ///
  /// Only values with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  ///
  /// * [lhs]: First operand of the comparison
  /// * [rhs]: Second operand of the comparison
  /// * [ArgumentException]: The calendar system of [rhs] is not the same
  /// as the calendar of [lhs].
  /// Returns: true if the [lhs] is earlier than or equal to [rhs], false otherwise.
  bool operator <=(LocalDateTime rhs) {
    if (rhs == null) return false;
    Preconditions.checkArgument(calendar == rhs.calendar, 'rhs', "Only values in the same calendar can be compared");
    return compareTo(rhs) <= 0;
  }


  /// Compares two LocalDateTime values to see if the left one is strictly later than the right
  /// one.
  ///
  /// Only values with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  ///
  /// * [lhs]: First operand of the comparison
  /// * [rhs]: Second operand of the comparison
  /// * [ArgumentException]: The calendar system of [rhs] is not the same
  /// as the calendar of [lhs].
  /// Returns: true if the [lhs] is strictly later than [rhs], false otherwise.
  bool operator >(LocalDateTime rhs) {
    if (rhs == null) return true;
    Preconditions.checkArgument(calendar == rhs.calendar, 'rhs', "Only values in the same calendar can be compared");
    return compareTo(rhs) > 0;
  }


  /// Compares two LocalDateTime values to see if the left one is later than or equal to the right
  /// one.
  ///
  /// Only values with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  ///
  /// * [lhs]: First operand of the comparison
  /// * [rhs]: Second operand of the comparison
  /// * [ArgumentException]: The calendar system of [rhs] is not the same
  /// as the calendar of [lhs].
  /// Returns: true if the [lhs] is later than or equal to [rhs], false otherwise.
  bool operator >=(LocalDateTime rhs) {
    if (rhs == null) return true;
    Preconditions.checkArgument(calendar == rhs.calendar, 'rhs', "Only values in the same calendar can be compared");
    return compareTo(rhs) >= 0;
  }


  /// Indicates whether this date/time is earlier, later or the same as another one.
  ///
  /// Only date/time values within the same calendar systems can be compared with this method. Attempting to compare
  /// values within different calendars will fail with an [ArgumentException]. Ideally, comparisons
  /// is almost always preferable to continuing.
  ///
  /// * [other]: The other local date/time to compare with this value.
  /// * [ArgumentException]: The calendar system of [other] is not the
  /// same as the calendar system of this value.
  /// A value less than zero if this date/time is earlier than [other];
  /// zero if this date/time is the same as [other]; a value greater than zero if this date/time is
  /// later than [other].
  int compareTo(LocalDateTime other) {
    // This will check calendars...
    if (other == null) return 1;
    int dateComparison = date.compareTo(other.date);
    if (dateComparison != 0) {
      return dateComparison;
    }
    return time.compareTo(other.time);
  }

  /// Adds a period to a local date/time. Fields are added in the order provided by the period.
  /// This is a convenience operator over the [plus] method.
  ///
  /// * [localDateTime]: Initial local date and time
  /// * [period]: Period to add
  /// Returns: The resulting local date and time
  LocalDateTime operator +(Period period) => plus(period);


  /// Add the specified period to the date and time. Friendly alternative to `operator+()`.
  ///
  /// * [localDateTime]: Initial local date and time
  /// * [period]: Period to add
  /// Returns: The resulting local date and time
  static LocalDateTime add(LocalDateTime localDateTime, Period period) => localDateTime.plus(period);


  /// Adds a period to this local date/time. Fields are added in the order provided by the period.
  ///
  /// * [period]: Period to add
  /// Returns: The resulting local date and time
  LocalDateTime plus(Period period) {
    Preconditions.checkNotNull(period, 'period');
    return IPeriod.addDateTimeTo(period, date, time, 1);
  }


  /// Subtracts a period from a local date/time. Fields are subtracted in the order provided by the period.
  /// This is a convenience operator over the [Minus(Period)] method.
  ///
  /// * [localDateTime]: Initial local date and time
  /// * [period]: Period to subtract
  /// Returns: The resulting local date and time
  /// Subtracts one date/time from another, returning the result as a [Period].
  ///
  /// This is simply a convenience operator for calling [Period.Between(LocalDateTime,LocalDateTime)].
  /// The calendar systems of the two date/times must be the same.
  ///
  /// * [lhs]: The date/time to subtract from
  /// * [rhs]: The date/time to subtract
  /// Returns: The result of subtracting one date/time from another.
  // LocalDateTime operator -(Period period) => MinusPeriod(period);
  // Period operator -(LocalDateTime rhs) => Period.Between(rhs, this);
  // todo: still hate dynamic dispatch
  dynamic operator -(dynamic value) => value is Period ? minusPeriod(value) : value is LocalDateTime ? MinusLocalDateTime(value) : throw new TypeError();

  /// Subtracts the specified period from the date and time. Friendly alternative to `operator-()`.
  ///
  /// * [localDateTime]: Initial local date and time
  /// * [period]: Period to subtract
  /// Returns: The resulting local date and time
  static LocalDateTime subtractPeriod(LocalDateTime localDateTime, Period period) => localDateTime.minusPeriod(period);


  /// Subtracts a period from a local date/time. Fields are subtracted in the order provided by the period.
  ///
  /// * [period]: Period to subtract
  /// Returns: The resulting local date and time
  LocalDateTime minusPeriod(Period period) {
    Preconditions.checkNotNull(period, 'period');
    return IPeriod.addDateTimeTo(period, date, time, -1);
  }


  /// Subtracts one date/time from another, returning the result as a [Period].
  ///
  /// This is simply a convenience method for calling [Period.Between(LocalDateTime,LocalDateTime)].
  /// The calendar systems of the two date/times must be the same.
  ///
  /// * [lhs]: The date/time to subtract from
  /// * [rhs]: The date/time to subtract
  /// Returns: The result of subtracting one date/time from another.
  static Period subtractLocalDateTime(LocalDateTime lhs, LocalDateTime rhs) => lhs.MinusLocalDateTime(rhs);


  /// Subtracts the specified date/time from this date/time, returning the result as a [Period].
  /// Fluent alternative to `operator-()`.
  ///
  /// The specified date/time must be in the same calendar system as this.
  /// * [localDateTime]: The date/time to subtract from this
  /// Returns: The difference between the specified date/time and this one
  Period MinusLocalDateTime(LocalDateTime localDateTime) => Period.between(localDateTime, this);
  
  /// Returns a hash code for this instance.
  ///
  /// A hash code for this instance, suitable for use in hashing algorithms and data
  /// structures like a hash table.
  @override int get hashCode => hash3(date, time, calendar);

  /// Returns this date/time, with the given date adjuster applied to it, maintaining the existing time of day.
  ///
  /// If the adjuster attempts to construct an
  /// invalid date (such as by trying to set a day-of-month of 30 in February), any exception thrown by
  /// that construction attempt will be propagated through this method.
  ///
  /// * [adjuster]: The adjuster to apply.
  /// Returns: The adjusted date/time.
  LocalDateTime adjustDate(LocalDate Function(LocalDate) adjuster) => date.adjust(adjuster).at(time);


  /// Returns this date/time, with the given time adjuster applied to it, maintaining the existing date.
  ///
  /// If the adjuster attempts to construct an invalid time, any exception thrown by
  /// that construction attempt will be propagated through this method.
  ///
  /// * [adjuster]: The adjuster to apply.
  /// Returns: The adjusted date/time.
  LocalDateTime adjustTime(LocalTime Function(LocalTime) adjuster) => date.at(time.adjust(adjuster));


  /// Creates a new LocalDateTime representing the same physical date and time, but in a different calendar.
  /// The returned LocalDateTime is likely to have different date field values to this one.
  /// For example, January 1st 1970 in the Gregorian calendar was December 19th 1969 in the Julian calendar.
  ///
  /// * [calendar]: The calendar system to convert this local date to.
  /// Returns: The converted LocalDateTime.
  LocalDateTime withCalendar(CalendarSystem calendar) {
    Preconditions.checkNotNull(calendar, 'calendar');
    return new LocalDateTime(date.withCalendar(calendar), time);
  }


  /// Returns a new LocalDateTime representing the current value with the given number of years added.
  ///
  /// If the resulting date is invalid, lower fields (typically the day of month) are reduced to find a valid value.
  /// For example, adding one year to February 29th 2012 will return February 28th 2013; subtracting one year from
  /// February 29th 2012 will return February 28th 2011.
  ///
  /// * [years]: The number of years to add
  /// Returns: The current value plus the given number of years.
  LocalDateTime plusYears(int years) => new LocalDateTime(date.plusYears(years), time);


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
  /// Returns: The current value plus the given number of months.
  LocalDateTime plusMonths(int months) => new LocalDateTime(date.plusMonths(months), time);


  /// Returns a new LocalDateTime representing the current value with the given number of days added.
  ///
  /// This method does not try to maintain the month or year of the current value, so adding 3 days to a value on January 30th
  /// will result in a value on February 2nd.
  ///
  /// * [days]: The number of days to add
  /// Returns: The current value plus the given number of days.
  LocalDateTime plusDays(int days) => new LocalDateTime(date.plusDays(days), time);


  /// Returns a new LocalDateTime representing the current value with the given number of weeks added.
  ///
  /// * [weeks]: The number of weeks to add
  /// Returns: The current value plus the given number of weeks.
  LocalDateTime plusWeeks(int weeks) => new LocalDateTime(date.plusWeeks(weeks), time);


  /// Returns a new LocalDateTime representing the current value with the given number of hours added.
  ///
  /// * [hours]: The number of hours to add
  /// Returns: The current value plus the given number of hours.
  LocalDateTime plusHours(int hours) => TimePeriodField.hours.addDateTime(this, hours);


  /// Returns a new LocalDateTime representing the current value with the given number of minutes added.
  ///
  /// * [minutes]: The number of minutes to add
  /// Returns: The current value plus the given number of minutes.
  LocalDateTime plusMinutes(int minutes) => TimePeriodField.minutes.addDateTime(this, minutes);


  /// Returns a new LocalDateTime representing the current value with the given number of seconds added.
  ///
  /// * [seconds]: The number of seconds to add
  /// Returns: The current value plus the given number of seconds.
  LocalDateTime plusSeconds(int seconds) => TimePeriodField.seconds.addDateTime(this, seconds);


  /// Returns a new LocalDateTime representing the current value with the given number of milliseconds added.
  ///
  /// * [milliseconds]: The number of milliseconds to add
  /// Returns: The current value plus the given number of milliseconds.
  LocalDateTime plusMilliseconds(int milliseconds) =>
      TimePeriodField.milliseconds.addDateTime(this, milliseconds);


  /// Returns a new LocalDateTime representing the current value with the given number of ticks added.
  ///
  /// * [ticks]: The number of ticks to add
  /// Returns: The current value plus the given number of ticks.
  LocalDateTime plusTicks(int ticks) => TimePeriodField.ticks.addDateTime(this, ticks);


  /// Returns a new LocalDateTime representing the current value with the given number of nanoseconds added.
  ///
  /// * [nanoseconds]: The number of nanoseconds to add
  /// Returns: The current value plus the given number of nanoseconds.
  LocalDateTime plusNanoseconds(int nanoseconds) => TimePeriodField.nanoseconds.addDateTime(this, nanoseconds);


  /// Returns the next [LocalDateTime] falling on the specified [DayOfWeek],
  /// at the same time of day as this value.
  /// This is a strict "next" - if this value on already falls on the target
  /// day of the week, the returned value will be a week later.
  ///
  /// * [targetDayOfWeek]: The ISO day of the week to return the next date of.
  /// Returns: The next [LocalDateTime] falling on the specified day of the week.
  /// * [InvalidOperationException]: The underlying calendar doesn't use ISO days of the week.
  /// * [ArgumentOutOfRangeException]: [targetDayOfWeek] is not a valid day of the
  /// week (Monday to Sunday).
  LocalDateTime next(DayOfWeek targetDayOfWeek) => new LocalDateTime(date.next(targetDayOfWeek), time);


  /// Returns the previous [LocalDateTime] falling on the specified [DayOfWeek],
  /// at the same time of day as this value.
  /// This is a strict "previous" - if this value on already falls on the target
  /// day of the week, the returned value will be a week earlier.
  ///
  /// * [targetDayOfWeek]: The ISO day of the week to return the previous date of.
  /// Returns: The previous [LocalDateTime] falling on the specified day of the week.
  /// * [InvalidOperationException]: The underlying calendar doesn't use ISO days of the week.
  /// * [ArgumentOutOfRangeException]: [targetDayOfWeek] is not a valid day of the
  /// week (Monday to Sunday).
  LocalDateTime previous(DayOfWeek targetDayOfWeek) => new LocalDateTime(date.previous(targetDayOfWeek), time);


  /// Returns an [OffsetDateTime] for this local date/time with the given offset.
  ///
  /// This method is purely a convenient alternative to calling the [OffsetDateTime] constructor directly.
  /// * [offset]: The offset to apply.
  /// Returns: The result of this local date/time offset by the given amount.
  OffsetDateTime withOffset(Offset offset) => IOffsetDateTime.lessTrust(ILocalDate.yearMonthDayCalendar(date), time, offset);


  /// Returns the mapping of this local date/time within [DateTimeZone.utc].
  ///
  /// As UTC is a fixed time zone, there is no chance that this local date/time is ambiguous or skipped.
  /// Returns: The result of mapping this local date/time in UTC.
  ZonedDateTime inUtc() =>
  // Use the internal constructors to avoid validation. We know it will be fine.
  IZonedDateTime.trusted(IOffsetDateTime.fullTrust(ILocalDate.yearMonthDayCalendar(date), time.nanosecondOfDay, Offset.zero), DateTimeZone.utc);


  // todo: are these convenience functions still needed? (since we made the DateTimeZone ZonedDateTime constructors, constructors on ZonedDateTime?) 
  /// Returns the mapping of this local date/time within the given [DateTimeZone],
  /// with "strict" rules applied such that an exception is thrown if either the mapping is
  /// ambiguous or the time is skipped.
  ///
  /// See [inZoneLeniently] and [inZone] for alternative ways to map a local time to a
  /// specific instant.
  /// This is solely a convenience method for calling [DateTimeZone.atStrictly].
  ///
  /// * [zone]: The time zone in which to map this local date/time.
  /// * [SkippedTimeException]: This local date/time is skipped in the given time zone.
  /// * [AmbiguousTimeException]: This local date/time is ambiguous in the given time zone.
  /// Returns: The result of mapping this local date/time in the given time zone.
  ZonedDateTime inZoneStrictly(DateTimeZone zone) {
    Preconditions.checkNotNull(zone, 'zone');
    return new ZonedDateTime.atStrictly(this, zone);
  }


  /// Returns the mapping of this local date/time within the given [DateTimeZone],
  /// with "lenient" rules applied such that ambiguous values map to the earlier of the alternatives, and
  /// "skipped" values are shifted forward by the duration of the "gap".
  ///
  /// See [inZoneStrictly] and [inZone] for alternative ways to map a local time to a
  /// specific instant.
  /// This is solely a convenience method for calling [DateTimeZone.atLeniently].
  /// Note: The behavior of this method was changed in version 2.0 to fit the most commonly seen real-world
  /// usage pattern.  Previous versions returned the later instance of ambiguous values, and returned the start of
  /// the zone interval after the gap for skipped value.  The previous functionality can still be used if desired,
  /// by using [InZone(DateTimeZone, ZoneLocalMappingResolver)] and passing a resolver that combines the
  /// * [Resolvers.returnLater] and [Resolvers.returnStartOfIntervalAfter] resolvers.
  ///
  /// * [zone]: The time zone in which to map this local date/time.
  /// Returns: The result of mapping this local date/time in the given time zone.
  ZonedDateTime inZoneLeniently(DateTimeZone zone) {
    Preconditions.checkNotNull(zone, 'zone');
    return new ZonedDateTime.atLeniently(this, zone);
  }


  /// Resolves this local date and time into a [ZonedDateTime] in the given time zone, following
  /// the given [ZoneLocalMappingResolver] to handle ambiguity and skipped times.
  ///
  /// See [inZoneStrictly] and [inZoneLeniently] for alternative ways to map a local time
  /// to a specific instant.
  /// This is a convenience method for calling [DateTimeZone.ResolveLocal(LocalDateTime, ZoneLocalMappingResolver)].
  ///
  /// * [zone]: The time zone to map this local date and time into
  /// * [resolver]: The resolver to apply to the mapping.
  /// Returns: The result of resolving the mapping.
  ZonedDateTime inZone(DateTimeZone zone, ZoneLocalMappingResolver resolver) {
    Preconditions.checkNotNull(zone, 'zone');
    Preconditions.checkNotNull(resolver, 'resolver');
    return new ZonedDateTime.resolveLocal(this, zone, resolver);
  }


  /// Returns the later date/time of the given two.
  ///
  /// * [x]: The first date/time to compare.
  /// * [y]: The second date/time to compare.
  /// * [ArgumentException]: The two date/times have different calendar systems.
  /// Returns: The later date/time of [x] or [y].
  static LocalDateTime max(LocalDateTime x, LocalDateTime y) {
    Preconditions.checkArgument(x.calendar == y.calendar, 'y', "Only values with the same calendar system can be compared");
    return x > y ? x : y;
  }


  /// Returns the earlier date/time of the given two.
  ///
  /// * [x]: The first date/time to compare.
  /// * [y]: The second date/time to compare.
  /// * [ArgumentException]: The two date/times have different calendar systems.
  /// Returns: The earlier date/time of [x] or [y].
  static LocalDateTime min(LocalDateTime x, LocalDateTime y) {
    Preconditions.checkArgument(x.calendar == y.calendar, 'y', "Only values with the same calendar system can be compared");
    return x < y ? x : y;
  }

  /// Returns a [String] that represents this instance.
  ///
  /// The value of the current instance in the default format pattern ("G"), using the current thread's
  /// culture to obtain a format provider.
  // @override String toString() => TextShim.toStringLocalDateTime(this);
  @override String toString([String patternText, Culture culture]) =>
      LocalDateTimePatterns.format(this, patternText, culture);
}
