// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
// import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

// Note: documentation that refers to the LocalDateTime type within this class must use the fully-qualified
// reference to avoid being resolved to the LocalDateTime property instead.

@internal
abstract class IZonedDateTime {
  static ZonedDateTime trusted(OffsetDateTime offsetDateTime, DateTimeZone zone) => ZonedDateTime._(offsetDateTime, zone);
}

/// A [LocalDateTime] in a specific time zone and with a particular offset to distinguish
/// between otherwise-ambiguous instants. A [ZonedDateTime] is global, in that it maps to a single
/// [Instant].
///
/// Although [ZonedDateTime] includes both local and global concepts, it only supports
/// duration-based - and not calendar-based - arithmetic. This avoids ambiguities
/// and skipped date/time values becoming a problem within a series of calculations; instead,
/// these can be considered just once, at the point of conversion to a [ZonedDateTime].
///
/// [ZonedDateTime] does not implement ordered comparison operators, as there is no obvious natural ordering that works in all cases.
/// Equality is supported however, requiring equality of zone, calendar and date/time. If you want to sort [ZonedDateTime]
/// values, you should explicitly choose one of the orderings provided via the static properties in the
/// [ZonedDateTimeComparer] class (or implement your own comparison).
@immutable
class ZonedDateTime {
  // todo: why isn't this exposed directly?
  final OffsetDateTime _offsetDateTime;
  /// Gets the time zone associated with this value.
  final DateTimeZone zone;

  /// Internal constructor from pre-validated values.
  const ZonedDateTime._(this._offsetDateTime, this.zone);

  /// Initializes a new instance of [ZonedDateTime] in the specified time zone
  /// and the ISO or specified calendar.
  ///
  /// * [instant]: The instant.
  /// * [zone]: The time zone.
  /// * [calendar]: The calendar system, defaulting to ISO.
  factory ZonedDateTime([Instant instant = Instant.unixEpoch, DateTimeZone? zone, CalendarSystem? calendar]) {
    // zone = Preconditions.checkNotNull(zone, 'zone');
    var _zone = zone ?? DateTimeZone.utc;
    var _offsetDateTime = IOffsetDateTime.fromInstant(instant, _zone.getUtcOffset(instant), calendar);
    return ZonedDateTime._(_offsetDateTime, _zone);
  }

  /// Initializes a new instance of [ZonedDateTime] in the specified time zone
  /// from a given local time and offset. The offset is validated to be correct as part of initialization.
  /// In most cases a local time can only map to a single instant anyway, but the offset is included here for cases
  /// where the local time is ambiguous, usually due to daylight saving transitions.
  ///
  /// * [localDateTime]: The local date and time.
  /// * [zone]: The time zone.
  /// * [offset]: The offset between UTC and local time at the desired instant.
  ///
  /// * [ArgumentError]: [offset] is not a valid offset at the given
  /// local date and time.
  factory ZonedDateTime.atOffset(LocalDateTime localDateTime, DateTimeZone zone, Offset offset)
  {
    zone = Preconditions.checkNotNull(zone, 'zone');
    Instant candidateInstant = ILocalDateTime.toLocalInstant(localDateTime).minus(offset);
    Offset correctOffset = zone.getUtcOffset(candidateInstant);
    // Not using Preconditions, to avoid building the string unnecessarily.
    if (correctOffset != offset) {
      throw ArgumentError('Offset $offset is invalid for local date and time $localDateTime in time zone ${zone.id} offset');
    }
    var offsetDateTime = OffsetDateTime(localDateTime, offset);
    return ZonedDateTime._(offsetDateTime, zone);
  }

  /// Returns the earliest valid [ZonedDateTime] with the given local date.
  ///
  /// If midnight exists unambiguously on the given date, it is returned.
  /// If the given date has an ambiguous start time (e.g. the clocks go back from 1am to midnight)
  /// then the earlier ZonedDateTime is returned. If the given date has no midnight (e.g. the clocks
  /// go forward from midnight to 1am) then the earliest valid value is returned; this will be the instant
  /// of the transition.
  ///
  /// * [date]: The local date to map in this time zone.
  /// * [zone]: The date time zone to map this local date into.
  ///
  /// Returns: The [ZonedDateTime] representing the earliest time in the given date, in this time zone.
  ///
  /// * [SkippedTimeError]: The entire day was skipped due to a very large time zone transition.
  /// (This is extremely rare.)
  factory ZonedDateTime.atStartOfDay(LocalDate date, DateTimeZone zone) {
    LocalDateTime midnight = date.atMidnight();
    var mapping = zone.mapLocal(midnight);
    switch (mapping.count) {
      // Midnight doesn't exist. Maybe we just skip to 1am (or whatever), or maybe the whole day is missed.
      case 0:
        var interval = mapping.lateInterval;
        // Safe to use Start, as it can't extend to the start of time.
        var offsetDateTime = IOffsetDateTime.fromInstant(interval.start, interval.wallOffset, date.calendar);
        // It's possible that the entire day is skipped. For example, Samoa skipped December 30th 2011.
        // We know the two values are in the same calendar here, so we just need to check the YearMonthDay.
        if (ILocalDate.yearMonthDay(offsetDateTime.calendarDate) != ILocalDate.yearMonthDay(date)) {
          throw SkippedTimeError(midnight, zone);
        }
        return IZonedDateTime.trusted(offsetDateTime, zone);
      // Unambiguous or occurs twice, we can just use the offset from the earlier interval.
      case 1:
      case 2:
        return IZonedDateTime.trusted(midnight.withOffset(mapping.earlyInterval.wallOffset), zone);
      default:
        throw StateError("This won't happen.");
    }
  }

  /// Maps the given [LocalDateTime] to the corresponding [ZonedDateTime], following
  /// the given [ZoneLocalMappingResolver] to handle ambiguity and skipped times.
  ///
  /// This is a convenience method for calling [mapLocal] and passing the result to the resolver.
  /// Common options for resolvers are provided in the static [Resolvers] class.
  ///
  /// See [atStrictly] and [atLeniently] for alternative ways to map a local time to a
  /// specific instant.
  ///
  /// * [localDateTime]: The local date and time to map in this time zone.
  /// * [resolver]: The resolver to apply to the mapping.
  ///
  /// Returns: The result of resolving the mapping.
  factory ZonedDateTime.resolve(LocalDateTime localDateTime, DateTimeZone zone, ZoneLocalMappingResolver resolver) {
    Preconditions.checkNotNull(resolver, 'resolver');
    return resolver(zone.mapLocal(localDateTime));
  }

  /// Maps the given [LocalDateTime] to the corresponding [ZonedDateTime], if and only if
  /// that mapping is unambiguous in this time zone.  Otherwise, [SkippedTimeError] or
  /// [AmbiguousTimeException] is thrown, depending on whether the mapping is ambiguous or the local
  /// date/time is skipped entirely.
  ///
  /// See [atLeniently] and [ResolveLocal(LocalDateTime, ZoneLocalMappingResolver)] for alternative ways to map a local time to a
  /// specific instant.
  ///
  /// * [localDateTime]: The local date and time to map into this time zone.
  ///
  /// * [SkippedTimeError]: The given local date/time is skipped in this time zone.
  /// * [AmbiguousTimeError]: The given local date/time is ambiguous in this time zone.
  /// Returns: The unambiguous matching [ZonedDateTime] if it exists.
  factory ZonedDateTime.atStrictly(LocalDateTime localDateTime, DateTimeZone zone) =>
      ZonedDateTime.resolve(localDateTime, zone, Resolvers.strictResolver);

  /// Maps the given [LocalDateTime] to the corresponding [ZonedDateTime] in a lenient
  /// manner: ambiguous values map to the earlier of the alternatives, and 'skipped' values are shifted forward
  /// by the duration of the 'gap'.
  ///
  /// See [atStrictly] and [ResolveLocal(LocalDateTime, ZoneLocalMappingResolver)] for alternative ways to map a local time to a
  /// specific instant.
  ///
  /// Note: The behavior of this method was changed in version 2.0 to fit the most commonly seen real-world
  /// usage pattern.  Previous versions returned the later instance of ambiguous values, and returned the start of
  /// the zone interval after the gap for skipped value.  The previous functionality can still be used if desired,
  /// by using [ResolveLocal(LocalDateTime, ZoneLocalMappingResolver)], passing in a resolver
  /// created from [Resolvers.returnLater] and [Resolvers.returnStartOfIntervalAfter].
  ///
  /// * [localDateTime]: The local date/time to map.
  ///
  /// The unambiguous mapping if there is one, the earlier result if the mapping is ambiguous,
  /// or the forward-shifted value if the given local date/time is skipped.
  factory ZonedDateTime.atLeniently(LocalDateTime localDateTime, DateTimeZone zone) =>
      ZonedDateTime.resolve(localDateTime, zone, Resolvers.lenientResolver);


  /// Gets the offset of the local representation of this value from UTC.
  Offset get offset => _offsetDateTime.offset;

  /// Gets the time zone associated with this value.
  // DateTimeZone get Zone => zone ?? DateTimeZone.utc;

  /// Gets the local date and time represented by this zoned date and time.
  ///
  /// The returned [LocalDateTime] will have the same calendar system and return the same values for
  /// each of the calendar properties (Year, MonthOfYear and so on), but will not be associated with any
  /// particular time zone.
  LocalDateTime get localDateTime => _offsetDateTime.localDateTime;

  /// Gets the calendar system associated with this zoned date and time.
  CalendarSystem get calendar => _offsetDateTime.calendar;

  /// Gets the local date represented by this zoned date and time.
  ///
  /// The returned [LocalDate]
  /// will have the same calendar system and return the same values for each of the date-based calendar
  /// properties (Year, MonthOfYear and so on), but will not be associated with any particular time zone.
  LocalDate get calendarDate => _offsetDateTime.calendarDate;

  /// Gets the time portion of this zoned date and time.
  ///
  /// The returned [LocalTime] will
  /// return the same values for each of the time-based properties (Hour, Minute and so on), but
  /// will not be associated with any particular time zone.
  LocalTime get clockTime => _offsetDateTime.clockTime;

  /// Gets the era for this zoned date and time.
  Era get era => _offsetDateTime.era;

  /// Gets the year of this zoned date and time.
  /// This returns the 'absolute year', so, for the ISO calendar,
  /// a value of 0 means 1 BC, for example.
  int get year => _offsetDateTime.year;

  /// Gets the year of this zoned date and time within its era.
  int get yearOfEra => _offsetDateTime.yearOfEra;

  /// Gets the month of this zoned date and time within the year.
  int get monthOfYear => _offsetDateTime.monthOfYear;

  /// Gets the day of this zoned date and time within the year.
  int get dayOfYear => _offsetDateTime.dayOfYear;

  /// Gets the day of this zoned date and time within the month.
  int get dayOfMonth => _offsetDateTime.dayOfMonth;

  /// Gets the week day of this zoned date and time expressed as an [DayOfWeek] value.
  DayOfWeek get dayOfWeek => _offsetDateTime.dayOfWeek;

  /// Gets the hour of day of this zoned date and time, in the range 0 to 23 inclusive.
  int get hourOfDay => _offsetDateTime.hourOfDay;

  /// Gets the hour of the half-day of this zoned date and time, in the range 1 to 12 inclusive.
  int get hourOf12HourClock => _offsetDateTime.hourOf12HourClock;

  /// Gets the minute of this zoned date and time, in the range 0 to 59 inclusive.
  int get minuteOfHour => _offsetDateTime.minuteOfHour;

  /// Gets the second of this zoned date and time within the minute, in the range 0 to 59 inclusive.
  int get secondOfMinute => _offsetDateTime.secondOfMinute;

  /// Gets the millisecond of this zoned date and time within the second, in the range 0 to 999 inclusive.
  int get millisecondOfSecond => _offsetDateTime.millisecondOfSecond;

  /// Gets the tick of this zoned date and time within the second, in the range 0 to 9,999,999 inclusive.
  int get microsecondOfSecond => _offsetDateTime.microsecondOfSecond;

  /// Gets the nanosecond of this zoned date and time within the second, in the range 0 to 999,999,999 inclusive.
  int get nanosecondOfSecond => _offsetDateTime.nanosecondOfSecond;

  /// Converts this value to the instant it represents on the time line.
  ///
  /// This is always an unambiguous conversion. Any difficulties due to daylight saving
  /// transitions or other changes in time zone are handled when converting from a
  /// [LocalDateTime] to a [ZonedDateTime]; the `ZonedDateTime` remembers
  /// the actual offset from UTC to local time, so it always knows the exact instant represented.
  ///
  /// Returns: The instant corresponding to this value.
  Instant toInstant() => _offsetDateTime.toInstant();

  /// Creates a new [ZonedDateTime] representing the same instant in time, in the
  /// same calendar but a different time zone.
  ///
  /// * [targetZone]: The target time zone to convert to.
  ///
  /// Returns: A new value in the target time zone.
  ZonedDateTime withZone(DateTimeZone targetZone) {
    Preconditions.checkNotNull(targetZone, 'targetZone');
    return ZonedDateTime(toInstant(), targetZone, calendar);
  }

  /// Creates a new ZonedDateTime representing the same physical date, time and offset, but in a different calendar.
  /// The returned ZonedDateTime is likely to have different date field values to this one.
  /// For example, January 1st 1970 in the Gregorian calendar was December 19th 1969 in the Julian calendar.
  ///
  /// * [calendar]: The calendar system to convert this zoned date and time to.
  ///
  /// Returns: The converted ZonedDateTime.
  ZonedDateTime withCalendar(CalendarSystem calendar) {
    return ZonedDateTime._(_offsetDateTime.withCalendar(calendar), zone);
  }

  /// Indicates whether the current object is equal to another object of the same type.
  ///
  /// true if the current object is equal to the [other] parameter; otherwise, false.
  ///
  /// * [other]: An object to compare with this object.
  ///
  /// Returns: True if the specified value is the same instant in the same time zone; false otherwise.
  bool equals(ZonedDateTime other) => _offsetDateTime == other._offsetDateTime && zone == other.zone;

  /// Computes the hash code for this instance.
  ///
  /// A 32-bit signed integer that is the hash code for this instance.
  @override int get hashCode => hash2(_offsetDateTime, zone);

  /// Implements the operator ==.
  ///
  /// * [this]: The first value to compare
  /// * [other]: The second value to compare
  ///
  /// Returns: True if the two operands are equal according to [Equals(ZonedDateTime)]; false otherwise
  @override bool operator ==(Object other) => other is ZonedDateTime && equals(other);

  /// Adds a duration to a zoned date and time.
  ///
  /// * [zonedDateTime]: The value to add the duration to.
  /// * [time]: The duration to add
  ///
  /// Returns: A new value with the time advanced by the given duration, in the same calendar system and time zone.
  static ZonedDateTime plus(ZonedDateTime zonedDateTime, Time time) => zonedDateTime.add(time);

  /// Subtracts a duration from a zoned date and time.
  ///
  /// * [zonedDateTime]: The value to subtract the duration from.
  /// * [time]: The duration to subtract.
  ///
  /// Returns: A new value with the time 'rewound' by the given duration, in the same calendar system and time zone.
  static ZonedDateTime minus(ZonedDateTime zonedDateTime, Time time) => zonedDateTime.subtract(time);

  /// Subtracts one zoned date and time from another, returning an elapsed duration.
  ///
  /// This is equivalent to `start.ToInstant().timeUntil(end.ToInstant())`; in particular:
  ///
  ///  * The two values can use different calendar systems
  ///  * The two values can be in different time zones
  ///  * The two values can have different UTC offsets
  ///
  /// * [end]: The zoned date and time value to subtract from; if this is later than [start]
  /// then the result will be positive.
  /// * [start]: The zoned date and time to subtract from [end].
  ///
  /// Returns: The elapsed duration from [start] to [end].
  static Time difference(ZonedDateTime end, ZonedDateTime start) => end.timeSince(start);

  /// Returns a new [ZonedDateTime] with the time advanced by the given duration. Note that
  /// due to daylight saving time changes this may not advance the local time by the same amount.
  ///
  /// The returned value retains the calendar system and time zone of [zonedDateTime].
  ///
  /// * [this]: The [ZonedDateTime] to add the duration to.
  /// * [time]: The duration to add.
  ///
  /// Returns: A new value with the time advanced by the given duration, in the same calendar system and time zone.
  ZonedDateTime operator +(Time time) => add(time);

  /// Returns a new [ZonedDateTime] with the duration subtracted. Note that
  /// due to daylight saving time changes this may not change the local time by the same amount.
  ///
  /// The returned value retains the calendar system and time zone of [zonedDateTime].
  /// This is equivalent to [subtract].
  ///
  /// * [zonedDateTime]: The value to subtract the duration from.
  /// * [time]: The duration to subtract.
  ///
  /// Returns: A new value with the time 'rewound' by the given duration, in the same calendar system and time zone.
  ZonedDateTime operator -(Time time) => subtract(time);

  /// Returns the result of adding a duration to this zoned date and time.
  ///
  /// * [time]: The duration to add
  ///
  /// Returns: A new [ZonedDateTime] representing the result of the addition.
  ZonedDateTime add(Time time) => ZonedDateTime(toInstant() + time, zone, calendar);

  /// Returns the result of subtracting a duration from this zoned date and time, for a fluent alternative to
  /// [-].
  ///
  /// * [time]: The duration to subtract
  ///
  /// Returns: A new [ZonedDateTime] representing the result of the subtraction.
  ZonedDateTime subtract(Time time) => ZonedDateTime(toInstant() - time, zone, calendar);

  /// Returns the result of subtracting another zoned date and time from this one, resulting in the elapsed duration
  /// between the two instants represented by the values.
  ///
  /// * [other]: The zoned date and time to subtract from [this] one.
  ///
  /// Returns: The elapsed duration from [other] to this value.
  Time timeSince(ZonedDateTime other) => other.toInstant().timeUntil(toInstant());

  /// Returns the result of subtracting [this] from a zoned date and time, resulting in the elapsed duration
  /// between the two instants represented by the values.
  ///
  /// * [other]: The zoned date and time to subtract [this] from.
  ///
  /// Returns: The elapsed duration from [other] to this value.
  Time timeUntil(ZonedDateTime other) => toInstant().timeUntil(other.toInstant());

  // If we ever get compile-time dispatch, re-enable this use-case
  // Time operator -(ZonedDateTime start) => minus(start); // Subtraction_ZonedDateTime() contains a commented out unit test
  // dynamic operator -(dynamic start) => start is Time ? minusTime(start) : start is ZonedDateTime ? minus(start) : throw new TypeError();

  /// Returns the [ZoneInterval] containing this value, in the time zone this
  /// value refers to.
  ///
  /// This is simply a convenience method - it is logically equivalent to converting this
  /// value to an [Instant] and then asking the appropriate [DateTimeZone]
  /// for the [ZoneInterval] containing that instant.
  ///
  /// Returns: The [ZoneInterval] containing this value.
  ZoneInterval getZoneInterval() => zone.getZoneInterval(toInstant());

  /// Indicates whether or not this [ZonedDateTime] is in daylight saving time
  /// for its time zone. This is determined by checking the [ZoneInterval.savings] property
  /// of the zone interval containing this value.
  ///
  /// see: [getZoneInterval]
  ///
  /// `true` if the zone interval containing this value has a non-zero savings
  /// component; `false` otherwise.
  bool isDaylightSavingTime() => getZoneInterval().savings != Offset.zero;

  /// Formats the value of the current instance using the specified pattern.
  ///
  /// A [String] containing the value of the current instance in the specified format.
  ///
  /// * [patternText]: The [String] specifying the pattern to use,
  /// or null to use the default format pattern ('G').
  /// * [culture]: The [Culture] to use when formatting the value,
  /// or null to use the current isolate's culture to obtain a format provider.
  @override String toString([String? patternText, Culture? culture]) =>
      ZonedDateTimePatterns.format(this, patternText, culture);

  @ddcSupportHack
  String toStringDDC([String? patternText, Culture? culture]) =>
      ZonedDateTimePatterns.format(this, patternText, culture);

  /// Constructs a [DateTime] from this [ZonedDateTime] which has a
  /// [DateTime.isUtc] set to `true` and represents the same instant of time as
  /// this value rather than the same local time.
  ///
  /// If the date and time is not on a millisecond (Web) or microsecond (VM) boundary (the unit of granularity of DateTime) the value will be truncated
  /// towards the start of time.
  ///
  /// A [DateTime] representation of this value with a 'universal' kind, with the same
  /// instant of time as this value.
  DateTime toDateTimeUtc() => toInstant().toDateTimeUtc();

  /// Constructs a [DateTime] from this [ZonedDateTime] which has a
  /// [DateTime.isUtc] set to `false` and represents the same local time as
  /// this value rather than the same instant in time.
  ///
  /// If the date and time is not on a millisecond (Web) or microsecond (VM) boundary (the unit of granularity of DateTime) the value will be truncated
  /// towards the start of time.
  ///
  /// A [DateTime] representation of this value with an 'unspecified' kind, with the same
  /// local date and time as this value.
  DateTime toDateTimeLocal() => localDateTime.toDateTimeLocal();

  /// Constructs an [OffsetDateTime] with the same local date and time, and the same offset
  /// as this zoned date and time, effectively just 'removing' the time zone itself.
  ///
  /// Returns: An OffsetDateTime with the same local date/time and offset as this value.
  OffsetDateTime toOffsetDateTime() => _offsetDateTime;
}

/// Base class for [ZonedDateTime] comparers.
///
/// Use the static properties of this class to obtain instances. This type is exposed so that the
/// same value can be used for both equality and ordering comparisons.
@immutable
abstract class ZonedDateTimeComparer // : todo: IComparer<ZonedDateTime>, IEqualityComparer<ZonedDateTime>
    {
  // TODO(feature): A comparer which compares instants, but in a calendar-sensitive manner?

  /// Gets a comparer which compares [ZonedDateTime] values by their local date/time, without reference to
  /// the time zone or offset. Comparisons between two values of different calendar systems will fail with [ArgumentError].
  ///
  /// For example, this comparer considers 2013-03-04T20:21:00 (Europe/London) to be later than
  /// 2013-03-04T19:21:00 (America/Los_Angeles) even though the second value represents a later instant in time.
  /// This property will return a reference to the same instance every time it is called.
  static ZonedDateTimeComparer get local => _ZonedDateTimeLocalComparer.instance;

  /// Gets a comparer which compares [ZonedDateTime] values by the instants obtained by applying the offset to
  /// the local date/time, ignoring the calendar system.
  ///
  /// For example, this comparer considers 2013-03-04T20:21:00 (Europe/London) to be earlier than
  /// 2013-03-04T19:21:00 (America/Los_Angeles) even though the second value has a local time which is earlier; the time zones
  /// mean that the first value occurred earlier in the universal time line.
  /// This property will return a reference to the same instance every time it is called.
  static ZonedDateTimeComparer get instant => _ZonedDateTimeInstantComparer.instance;

  /// Internal constructor to prevent external classes from deriving from this.
  /// (That means we can add more abstract members in the future.)
  const ZonedDateTimeComparer._();

  /// Compares two [ZonedDateTime] values and returns a value indicating whether one is less than, equal to, or greater than the other.
  ///
  /// * [x]: The first value to compare.
  /// * [y]: The second value to compare.
  ///
  /// A signed integer that indicates the relative values of [x] and [y], as shown in the following table.
  ///
  /// Value | Meaning
  /// --|--
  /// Less than zero | [x] is less than [y].
  /// Zero | [x] is equals to [y]
  /// Greater than zero | [x] is greater than [y].
  int compare(ZonedDateTime x, ZonedDateTime y);

  /// Determines whether the specified [ZonedDateTime] values are equal.
  ///
  /// * [x]: The first [ZonedDateTime] to compare.
  /// * [y]: The second [ZonedDateTime] to compare.
  ///
  /// Returns: `true` if the specified objects are equal; otherwise, `false`.
  bool equals(ZonedDateTime x, ZonedDateTime y);

  /// Returns a hash code for the specified [ZonedDateTime].
  ///
  /// * [zonedDateTime]: The [ZonedDateTime] for which a hash code is to be returned.
  int getHashCode(ZonedDateTime zonedDateTime);
}

/// Implementation for [Comparer.Local].
class _ZonedDateTimeLocalComparer extends ZonedDateTimeComparer {
  static const ZonedDateTimeComparer instance = _ZonedDateTimeLocalComparer._();

  const _ZonedDateTimeLocalComparer._() : super._();

  /// <inheritdoc />
  @override int compare(ZonedDateTime x, ZonedDateTime y) =>
      OffsetDateTimeComparer.local.compare(x._offsetDateTime, y._offsetDateTime);

  /// <inheritdoc />
  @override bool equals(ZonedDateTime x, ZonedDateTime y) =>
      OffsetDateTimeComparer.local.equals(x._offsetDateTime, y._offsetDateTime);

  /// <inheritdoc />
  @override int getHashCode(ZonedDateTime obj) =>
      OffsetDateTimeComparer.local.getHashCode(obj._offsetDateTime);
}

/// Implementation for [Comparer.Instant].
class _ZonedDateTimeInstantComparer extends ZonedDateTimeComparer {
  static const ZonedDateTimeComparer instance = _ZonedDateTimeInstantComparer._();

  const _ZonedDateTimeInstantComparer._() : super._();

  /// <inheritdoc />
  @override int compare(ZonedDateTime x, ZonedDateTime y) =>
      OffsetDateTimeComparer.instant.compare(x._offsetDateTime, y._offsetDateTime);

  /// <inheritdoc />
  @override bool equals(ZonedDateTime x, ZonedDateTime y) =>
      OffsetDateTimeComparer.instant.equals(x._offsetDateTime, y._offsetDateTime);

  /// <inheritdoc />
  @override int getHashCode(ZonedDateTime obj) =>
      OffsetDateTimeComparer.instant.getHashCode(obj._offsetDateTime);
}

