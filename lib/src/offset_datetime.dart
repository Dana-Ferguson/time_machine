// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
// import 'package:quiver_hashcode/hashcode.dart';
import 'package:time_machine/src/time_machine_internal.dart';

@internal
abstract class IOffsetDateTime {
  static OffsetDateTime fullTrust(LocalDateTime localDateTime, Offset offset) =>
      OffsetDateTime(localDateTime, offset);

  static OffsetDateTime lessTrust(LocalDate calendarDate, LocalTime clockTime, Offset offset) =>
      OffsetDateTime._lessTrust(calendarDate, clockTime, offset);

  static OffsetDateTime fromInstant(Instant instant, Offset offset, [CalendarSystem? calendar]) =>
      OffsetDateTime._fromInstant(instant, offset, calendar);

  // @deprecated
  // static YearMonthDay yearMonthDay(OffsetDateTime offsetDateTime) => ILocalDate.yearMonthDay(offsetDateTime.calendarDate);
}

/// A local date and time in a particular calendar system, combined with an offset from UTC.
///
/// A value of this type unambiguously represents both a local time and an instant on the timeline,
/// but does not have a well-defined time zone. This means you cannot reliably know what the local
/// time would be five minutes later, for example. While this doesn't sound terribly useful, it's very common
/// in text representations.
///
/// This type is immutable.
@immutable
class OffsetDateTime {
  /// Gets the offset from UTC.
  final Offset offset;

  /// Returns the local date and time represented within this offset date and time.
  final LocalDateTime localDateTime;

  /// Constructs a new offset date/time with the given local date and time, and the given offset from UTC.
  ///
  /// * [localDateTime]: Local date and time to represent
  /// * [offset]: Offset from UTC
  OffsetDateTime(this.localDateTime, this.offset)
  {
    // ICalendarSystem.validateYearMonthDay_(calendar, _yearMonthDay);
  }

  OffsetDateTime._lessTrust(LocalDate calendarDate, LocalTime clockTime, Offset offset)
      : localDateTime = calendarDate.at(clockTime),
        offset = offset
  {
    // ICalendarSystem.validateYearMonthDay_(calendar, _yearMonthDay);
  }

  // todo: why is this internal? ... this looks like it would help develop good mental models ... is that correct?

  /// Optimized conversion from an Instant to an OffsetDateTime in the specified calendar.
  /// This is equivalent to `new OffsetDateTime(new LocalDateTime(instant.Plus(offset), calendar), offset)`
  /// but with less overhead.
  factory OffsetDateTime._fromInstant(Instant instant, Offset offset, [CalendarSystem? calendar])
  {
    int days = instant.epochDay;
    int nanoOfDay = instant.epochDayTime.inNanoseconds + offset.inNanoseconds;
    if (nanoOfDay >= TimeConstants.nanosecondsPerDay) {
      days++;
      nanoOfDay -= TimeConstants.nanosecondsPerDay;
    }
    else if (nanoOfDay < 0) {
      days--;
      nanoOfDay += TimeConstants.nanosecondsPerDay;
    }
    /*
    var yearMonthDayCalendar = calendar != null
        ? ICalendarSystem.getYearMonthDayCalendarFromDaysSinceEpoch(calendar, days)
        // todo: can we grab the correct calculator based on the default culture? (is that appropriate?)
        : GregorianYearMonthDayCalculator.getGregorianYearMonthDayCalendarFromDaysSinceEpoch(days);*/
    // var nanosecondsAndOffset = _combineNanoOfDayAndOffset(nanoOfDay, offset);
    var ldt = LocalDate.fromEpochDay(days, calendar).at(ILocalTime.trustedNanoseconds(nanoOfDay));
    return OffsetDateTime(ldt, offset);
    // return new OffsetDateTime(yearMonthDayCalendar, nanoOfDay, offset); // nanosecondsAndOffset);
  }

  /// Gets the calendar system associated with this offset date and time.
  CalendarSystem get calendar => localDateTime.calendar;

  /// Gets the year of this offset date and time.
  /// This returns the 'absolute year', so, for the ISO calendar,
  /// a value of 0 means 1 BC, for example.
  int get year => localDateTime.year;

  /// Gets the month of this offset date and time within the year.
  int get monthOfYear => localDateTime.monthOfYear;

  /// Gets the day of this offset date and time within the month.
  int get dayOfMonth => localDateTime.dayOfMonth;

  /// Gets the week day of this offset date and time expressed as an [DayOfWeek] value.
  DayOfWeek get dayOfWeek => localDateTime.dayOfWeek;

  /// Gets the year of this offset date and time within the era.
  int get yearOfEra => localDateTime.yearOfEra;

  /// Gets the era of this offset date and time.
  Era get era => localDateTime.era;

  /// Gets the day of this offset date and time within the year.
  int get dayOfYear => localDateTime.dayOfYear;

  /// Gets the hour of day of this offest date and time, in the range 0 to 23 inclusive.
  int get hourOfDay => localDateTime.hourOfDay;

  /// Gets the hour of the half-day of this offest date and time, in the range 1 to 12 inclusive.
  int get hourOf12HourClock => localDateTime.hourOf12HourClock;

  /// Gets the minute of this offset date and time, in the range 0 to 59 inclusive.
  int get minuteOfHour => localDateTime.minuteOfHour;

  /// Gets the second of this offset date and time within the minute, in the range 0 to 59 inclusive.
  int get secondOfMinute => localDateTime.secondOfMinute;

  /// Gets the millisecond of this offset date and time within the second, in the range 0 to 999 inclusive.
  int get millisecondOfSecond => localDateTime.millisecondOfSecond;

  /// Gets the microsecond of this offset date and time within the second, in the range 0 to 999,999 inclusive.
  int get microsecondOfSecond => localDateTime.microsecondOfSecond;

  //@deprecated
  /// Gets the microsecond of this offset date and time within the day, in the range 0 to 86,399,999,999 inclusive.
  //int get microsecondOfDay => _nanosecondOfDay ~/ TimeConstants.nanosecondsPerMicrosecond;

  /// Gets the nanosecond of this offset date and time within the second, in the range 0 to 999,999,999 inclusive.
  int get nanosecondOfSecond => localDateTime.nanosecondOfSecond;

  //@deprecated
  /// Gets the nanosecond of this offset date and time within the day, in the range 0 to 86,399,999,999,999 inclusive.
  //int get nanosecondOfDay => _nanosecondOfDay;

  /// Gets the local date represented by this offset date and time.
  ///
  /// The returned [LocalDate]
  /// will have the same calendar system and return the same values for each of the date-based calendar
  /// properties (Year, MonthOfYear and so on), but will not have any offset information.
  LocalDate get calendarDate => localDateTime.calendarDate;

  /// Gets the time portion of this offset date and time.
  ///
  /// The returned [LocalTime] will
  /// return the same values for each of the time-based properties (Hour, Minute and so on), but
  /// will not have any offset information.
  LocalTime get clockTime => localDateTime.clockTime;

  // Offset get offset => _offset; // new Offset(nanosecondsAndOffset >> NanosecondsBits);

  /// Returns the number of nanoseconds in the offset, without going via an Offset.
  int get _offsetNanoseconds => offset.inNanoseconds; // (nanosecondsAndOffset >> NanosecondsBits) * TimeConstants.nanosecondsPerSecond;

  /// Converts this offset date and time to an instant in time by subtracting the offset from the local date and time.
  ///
  /// Returns: The instant represented by this offset date and time
  Instant toInstant() => IInstant.untrusted(_toElapsedTimeSinceEpoch());

  Time _toElapsedTimeSinceEpoch() {
    // Equivalent to LocalDateTime.ToLocalInstant().Minus(offset)
    Time elapsedTime = Time(days: calendarDate.epochDay, nanoseconds: clockTime.timeSinceMidnight.inNanoseconds - _offsetNanoseconds);
    // Duration elapsedTime = new Duration(days, NanosecondOfDay).MinusSmallNanoseconds(OffsetNanoseconds);
    return elapsedTime;
  }

  /// Returns this value as a [ZonedDateTime].
  ///
  /// This method returns a [ZonedDateTime] with the same local date and time as this value, using a
  /// fixed time zone with the same offset as the offset for this value.
  ///
  /// Note that because the resulting `ZonedDateTime` has a fixed time zone, it is generally not useful to
  /// use this result for arithmetic operations, as the zone will not adjust to account for daylight savings.
  ///
  /// Returns: A zoned date/time with the same local time and a fixed time zone using the offset from this value.
  ZonedDateTime get inFixedZone => IZonedDateTime.trusted(this, DateTimeZone.forOffset(offset));

  /// Returns this value in ths specified time zone. This method does not expect
  /// the offset in the zone to be the same as for the current value; it simply converts
  /// this value into an [Instant] and finds the [ZonedDateTime]
  /// for that instant in the specified zone.
  ///
  /// * [zone]: The time zone of the new value.
  ///
  /// Returns: The instant represented by this value, in the specified time zone.
  ZonedDateTime inZone(DateTimeZone zone) {
    Preconditions.checkNotNull(zone, 'zone');
    return toInstant().inZone(zone);
  }

  /// Creates a new [OffsetDateTime] representing the same physical date, time and offset, but in a different calendar.
  /// The returned OffsetDateTime is likely to have different date field values to this one.
  /// For example, January 1st 1970 in the Gregorian calendar was December 19th 1969 in the Julian calendar.
  ///
  /// * [calendar]: The calendar system to convert this offset date and time to.
  ///
  /// Returns: The converted OffsetDateTime.
  OffsetDateTime withCalendar(CalendarSystem calendar) {
    // todo: equivalent?
    // LocalDate newDate = calendarDate.withCalendar(calendar);
    return OffsetDateTime(localDateTime.withCalendar(calendar), offset);
  }

  /// Returns this offset date/time, with the given date adjuster applied to it, maintaining the existing time of day and offset.
  ///
  /// If the adjuster attempts to construct an
  /// invalid date (such as by trying to set a day-of-month of 30 in February), any exception thrown by
  /// that construction attempt will be propagated through this method.
  ///
  /// * [adjuster]: The adjuster to apply.
  ///
  /// Returns: The adjusted offset date/time.
  OffsetDateTime adjustDate(LocalDate Function(LocalDate) adjuster) {
    return OffsetDateTime(localDateTime.adjustDate(adjuster), offset);
  }

  /// Returns this date/time, with the given time adjuster applied to it, maintaining the existing date and offset.
  ///
  /// If the adjuster attempts to construct an invalid time, any exception thrown by
  /// that construction attempt will be propagated through this method.
  ///
  /// * [adjuster]: The adjuster to apply.
  ///
  /// Returns: The adjusted offset date/time.
  OffsetDateTime adjustTime(LocalTime Function(LocalTime) adjuster) {
    return OffsetDateTime(localDateTime.adjustTime(adjuster), offset);
  }

  /// Creates a new OffsetDateTime representing the instant in time in the same calendar,
  /// but with a different offset. The local date and time is adjusted accordingly.
  ///
  /// * [offset]: The new offset to use.
  ///
  /// Returns: The converted OffsetDateTime.
  OffsetDateTime withOffset(Offset offset) {
    // Slight change to the normal operation, as it's *just* about plausible that we change day
    // twice in one direction or the other.
    // todo: pretty sure this isn't going to work out
    /*
    int days = 0;
    int nanos = clockTime.timeSinceMidnight.inNanoseconds + offset.inNanoseconds - _offsetNanoseconds;
    if (nanos >= TimeConstants.nanosecondsPerDay) {
      days++;
      nanos -= TimeConstants.nanosecondsPerDay;
      if (nanos >= TimeConstants.nanosecondsPerDay) {
        days++;
        nanos -= TimeConstants.nanosecondsPerDay;
      }
    }
    else if (nanos < 0) {
      days--;
      nanos += TimeConstants.nanosecondsPerDay;
      if (nanos < 0) {
        days--;
        nanos += TimeConstants.nanosecondsPerDay;
      }
    }

    return new OffsetDateTime(
        days == 0 ? _yearMonthDayCalendar : ILocalDate.yearMonthDayCalendar(calendarDate
            .addDays(days)), nanos, offset);
*/
    // return localDateTime.withOffset(offset);

    return OffsetDateTime._fromInstant(toInstant(), offset, calendar);
  }

  /// Constructs a new [OffsetDate] from the date and offset of this value,
  /// but omitting the time-of-day.
  ///
  /// Returns: A value representing the date and offset aspects of this value.
  OffsetDate toOffsetDate() => OffsetDate(calendarDate, offset);

  /// Constructs a new [OffsetTime] from the time and offset of this value,
  /// but omitting the date.
  ///
  /// Returns: A value representing the time and offset aspects of this value.
  OffsetTime toOffsetTime() => OffsetTime(clockTime, offset);

  /// Returns a hash code for this offset date and time.
  @override int get hashCode => hash2(localDateTime, offset);

  /// Compares two [OffsetDateTime] values for equality. This requires
  /// that the local date/time values be the same (in the same calendar) and the offsets.
  ///
  /// * [other]: The value to compare this offset date/time with.
  ///
  /// Returns: True if the given value is another offset date/time equal to this one; false otherwise.
  bool equals(OffsetDateTime other) =>
      localDateTime.equals(other.localDateTime) && offset.equals(other.offset);

  /// Returns a [String] that represents this instance.
  ///
  /// The value of the current instance in the default format pattern ('G'), using the current isolate's
  /// culture to obtain a format provider.
  @override String toString([String? patternText, Culture? culture]) =>
      OffsetDateTimePatterns.format(this, patternText, culture);

  /// Adds a duration to an offset date and time.
  ///
  /// * [offsetDateTime]: The value to add the duration to.
  /// * [time]: The duration to add
  ///
  /// Returns: A new value with the time advanced by the given duration, in the same calendar system and with the same offset.
  static OffsetDateTime plus(OffsetDateTime offsetDateTime, Time time) => offsetDateTime + time;

  /// Subtracts a duration from an offset date and time.
  ///
  /// * [offsetDateTime]: The value to subtract the duration from.
  /// * [duration]: The duration to subtract.
  ///
  /// Returns: A new value with the time 'rewound' by the given duration, in the same calendar system and with the same offset.
  static OffsetDateTime minus(OffsetDateTime offsetDateTime, Time time) => offsetDateTime - time;

  /// Returns a new [OffsetDateTime] with the time advanced by the given duration.
  ///
  /// The returned value retains the calendar system and offset of [this].
  ///
  /// * [this]: The [OffsetDateTime] to add the duration to.
  /// * [time]: The duration to add.
  ///
  /// Returns: A new value with the time advanced by the given duration, in the same calendar system and with the same offset.
  OffsetDateTime operator +(Time time) => add(time);

  /// Returns a new [OffsetDateTime] with the [time] subtracted.
  ///
  /// The returned value retains the calendar system and offset of the [_offsetDateTime].
  ///
  /// * [offsetDateTime]: The value to subtract the duration from.
  /// * [duration]: The duration to subtract.
  ///
  /// Returns: A new value with the time 'rewound' by the given duration, in the same calendar system and with the same offset.
  OffsetDateTime operator -(Time time) => subtract(time);

  /// Returns the result of adding a duration to this offset date and time.
  ///
  /// * [duration]: The duration to add
  ///
  /// Returns: A new [OffsetDateTime] representing the result of the addition.
  OffsetDateTime add(Time time) => OffsetDateTime._fromInstant(toInstant() + time, offset);

  /// Returns the result of subtracting a duration from this offset date and time.
  ///
  /// * [time]: The duration to subtract
  ///
  /// Returns: A new [OffsetDateTime] representing the result of the subtraction.
  OffsetDateTime subtract(Time time) => OffsetDateTime._fromInstant(toInstant() - time, offset); // new Instant.trusted(ToElapsedTimeSinceEpoch()

  // dynamic operator -(dynamic value) => value is Time ? minusSpan(value) : value is OffsetDateTime ? minusOffsetDateTime(value) : throw new TypeError();
  // static Duration operator -(OffsetDateTime end, OffsetDateTime start) => end.ToInstant() - start.ToInstant();

  /// Subtracts one offset date and time from another, returning an elapsed duration. Equivalent to: `end - start`.
  ///
  /// * [end]: The offset date and time value to subtract from; if this is later than [start]
  /// then the result will be positive.
  /// * [start]: The offset date and time to subtract from [end].
  ///
  /// Returns: The elapsed duration from [start] to [end].
  static Time difference(OffsetDateTime end, OffsetDateTime start) => end.timeSince(start);

  /// Returns the result of subtracting another offset date and time from this one, resulting in the elapsed duration
  /// between the two instants represented in the values.
  ///
  /// * [other]: The offset date and time to subtract from this one.
  ///
  /// Returns: The elapsed duration from [other] to this value.
  Time timeUntil(OffsetDateTime other) => toInstant().timeUntil(other.toInstant());

  /// Returns the result of subtracting this offset date and time from another one, resulting in the elapsed duration
  /// between the two instants represented in the values.
  ///
  /// * [other]: The offset date and time to subtract this one from.
  ///
  /// Returns: The elapsed duration from [other] to this value.
  Time timeSince(OffsetDateTime other) => toInstant().timeSince(other.toInstant());

  /// Implements the operator == (equality).
  ///
  /// * [left]: The left hand side of the operator.
  /// * [right]: The right hand side of the operator.
  ///
  /// Returns: `true` if values are equal to each other, otherwise `false`.
  @override
  bool operator ==(Object right) => right is OffsetDateTime && equals(right);
}

// todo: very unsure about what to do with these

/// Implementation for [Comparer.Local]
class _OffsetDateTimeLocalComparer extends OffsetDateTimeComparer {
  static const OffsetDateTimeComparer _instance = _OffsetDateTimeLocalComparer._();

  const _OffsetDateTimeLocalComparer._() : super._();

  /// <inheritdoc />
  @override int compare(OffsetDateTime x, OffsetDateTime y) {
    Preconditions.checkArgument(x.calendar == y.calendar, 'y',
        'Only values with the same calendar system can be compared');
    int dateComparison = ICalendarSystem.compare(x.calendar, ILocalDate.yearMonthDay(x.calendarDate), ILocalDate.yearMonthDay(y.calendarDate));
    if (dateComparison != 0) {
      return dateComparison;
    }
    return x.clockTime.compareTo(y.clockTime);
  }

  /// <inheritdoc />
  @override bool equals(OffsetDateTime x, OffsetDateTime y) =>
      x.localDateTime.equals(y.localDateTime); // && x.offset.equals(y.offset);

  /// <inheritdoc />
  @override int getHashCode(OffsetDateTime obj) => obj.localDateTime.hashCode; // hash2(obj.localDateTime, obj.offset);
}


/// Base class for [OffsetDateTime] comparers.
///
/// Use the static properties of this class to obtain instances. This type is exposed so that the
/// same value can be used for both equality and ordering comparisons.
@immutable
abstract class OffsetDateTimeComparer // implements Comparable<OffsetDateTime> // : IComparer<OffsetDateTime>, IEqualityComparer<OffsetDateTime>
    {
  // TODO(feature): Should we have a comparer which is calendar-sensitive (so will fail if the calendars are different)
  // but still uses the offset?

  /// Gets a comparer which compares [OffsetDateTime] values by their local date/time, without reference to
  /// the offset. Comparisons between two values of different calendar systems will fail with [ArgumentException].
  ///
  /// For example, this comparer considers 2013-03-04T20:21:00+0100 to be later than 2013-03-04T19:21:00-0700 even though
  /// the second value represents a later instant in time.
  /// This property will return a reference to the same instance every time it is called.
  static OffsetDateTimeComparer get local => _OffsetDateTimeLocalComparer._instance;

  /// Returns a comparer which compares [OffsetDateTime] values by the instant values obtained by applying the offset to
  /// the local date/time, ignoring the calendar system.
  ///
  /// For example, this comparer considers 2013-03-04T20:21:00+0100 to be earlier than 2013-03-04T19:21:00-0700 even though
  /// the second value has a local time which is earlier.
  /// This property will return a reference to the same instance every time it is called.
  ///
  /// <value>A comparer which compares values by the instant values obtained by applying the offset to
  /// the local date/time, ignoring the calendar system.</value>
  static OffsetDateTimeComparer get instant => _OffsetDateTimeInstantComparer._instance;

  /// internal constructor to prevent external classes from deriving from this.
  /// (That means we can add more abstract members in the future.)
  const OffsetDateTimeComparer._();

  /// Compares two [OffsetDateTime] values and returns a value indicating whether one is less than, equal to, or greater than the other.
  ///
  /// [x]: The first value to compare.
  /// [y]: The second value to compare.
  /// A signed integer that indicates the relative values of [x] and [y], as shown in the following table.
  ///   <list type = 'table'>
  ///     <listheader>
  ///       <term>Value</term>
  ///       <description>Meaning</description>
  ///     </listheader>
  ///     <item>
  ///       <term>Less than zero</term>
  ///       <description>[x] is less than [y].</description>
  ///     </item>
  ///     <item>
  ///       <term>Zero</term>
  ///       <description>[x] is equals to [y].</description>
  ///     </item>
  ///     <item>
  ///       <term>Greater than zero</term>
  ///       <description>[x] is greater than [y].</description>
  ///     </item>
  ///   </list>
  int compare(OffsetDateTime x, OffsetDateTime y);

  /// Determines whether the specified `OffsetDateTime` values are equal.
  ///
  /// [x]: The first `OffsetDateTime` to compare.
  /// [y]: The second `OffsetDateTime` to compare.
  /// Returns: `true` if the specified objects are equal; otherwise, `false`.
  bool equals(OffsetDateTime x, OffsetDateTime y);

  /// Returns a hash code for the specified `OffsetDateTime`.
  ///
  /// [obj]: The `OffsetDateTime` for which a hash code is to be returned.
  /// Returns: A hash code for the specified value.
  int getHashCode(OffsetDateTime obj);
}

/// Implementation for [Comparer.Instant].
class _OffsetDateTimeInstantComparer extends OffsetDateTimeComparer {
  static const OffsetDateTimeComparer _instance = _OffsetDateTimeInstantComparer._();

  const _OffsetDateTimeInstantComparer._() : super._();

  /// <inheritdoc />
  @override int compare(OffsetDateTime x, OffsetDateTime y) =>
  // TODO(optimization): Optimize cases which are more than 2 days apart, by avoiding the arithmetic?
  x._toElapsedTimeSinceEpoch().compareTo(y._toElapsedTimeSinceEpoch());

  /// <inheritdoc />
  @override bool equals(OffsetDateTime x, OffsetDateTime y) =>
      x._toElapsedTimeSinceEpoch() == y._toElapsedTimeSinceEpoch();

  /// <inheritdoc />
  @override int getHashCode(OffsetDateTime obj) =>
      obj
          ._toElapsedTimeSinceEpoch()
          .hashCode;
}
