// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

import 'package:time_machine/time_machine_fields.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'utility/preconditions.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';

// Note: documentation that refers to the LocalDateTime type within this class must use the fully-qualified
// reference to avoid being resolved to the LocalDateTime property instead.

@internal
abstract class ILocalTime {
  static LocalTime fromNanoseconds(int nanoseconds) => new LocalTime._fromNanoseconds(nanoseconds);

  static LocalTime fromNanosecondsSinceMidnight(int nanoseconds) => new LocalTime._fromNanosecondsSinceMidnight(nanoseconds);

  static int hourOfHalfDay(LocalTime localTime) => localTime._hourOfHalfDay;
}

/// LocalTime is an immutable class representing a time of day, with no reference
/// to a particular calendar, time zone or date.
@immutable
class LocalTime implements Comparable<LocalTime> {
  /// Local time at midnight, i.e. 0 hours, 0 minutes, 0 seconds.
  static final LocalTime midnight = new LocalTime(0, 0, 0);

  /// The minimum value of this type; equivalent to [midnight].
  static final LocalTime minValue = midnight;

  /// Local time at noon, i.e. 12 hours, 0 minutes, 0 seconds.
  static final LocalTime noon = new LocalTime(12, 0, 0);

  /// The maximum value of this type, one nanosecond before midnight.
  ///
  /// This is useful if you have to use an inclusive upper bound for some reason.
  /// In general, it's better to use an exclusive upper bound, in which case use midnight of
  /// the following day.
  static final LocalTime maxValue = new LocalTime._fromNanoseconds(TimeConstants.nanosecondsPerDay - 1);

  /// Nanoseconds since midnight, in the range [0, 86,400,000,000,000). ~ 46 bits
  final int _nanoseconds;

  /// Creates a local time at the given hour, minute, second and millisecond,
  /// with a tick-of-millisecond value of zero.
  ///
  /// [hour]: The hour of day.
  /// [minute]: The minute of the hour.
  /// [second]: The second of the minute.
  /// [millisecond]: The millisecond of the second.
  /// [ArgumentOutOfRangeException]: The parameters do not form a valid time.
  /// Returns: The resulting time.
  LocalTime(int hour, int minute, [int second = 0, int millisecond = 0]) :
        _nanoseconds = _getNanosecondsFromHourMinuteSecondMillisecond(hour, minute, second, millisecond);

  static int _getNanosecondsFromHourMinuteSecondMillisecond(int hour, int minute, [int second = 0, int millisecond = 0]) {
    // Avoid the method calls which give a decent exception unless we're actually going to fail.
    if (hour < 0 || hour > TimeConstants.hoursPerDay - 1 ||
        minute < 0 || minute > TimeConstants.minutesPerHour - 1 ||
        second < 0 || second > TimeConstants.secondsPerMinute - 1 ||
        millisecond < 0 || millisecond > TimeConstants.millisecondsPerSecond - 1) {
      Preconditions.checkArgumentRange('hour', hour, 0, TimeConstants.hoursPerDay - 1);
      Preconditions.checkArgumentRange('minute', minute, 0, TimeConstants.minutesPerHour - 1);
      Preconditions.checkArgumentRange('second', second, 0, TimeConstants.secondsPerMinute - 1);
      Preconditions.checkArgumentRange('millisecond', millisecond, 0, TimeConstants.millisecondsPerSecond - 1);
    }
    return (
        hour * TimeConstants.nanosecondsPerHour +
            minute * TimeConstants.nanosecondsPerMinute +
            second * TimeConstants.nanosecondsPerSecond +
            millisecond * TimeConstants.nanosecondsPerMillisecond);
  }

  // todo: this is a large amount of factory constructors -- can we condense with named parameters?

  /// Factory method to create a local time at the given hour, minute, second, millisecond and tick within millisecond.
  ///
  /// [hour]: The hour of day.
  /// [minute]: The minute of the hour.
  /// [second]: The second of the minute.
  /// [millisecond]: The millisecond of the second.
  /// [tickWithinMillisecond]: The tick within the millisecond.
  /// [ArgumentOutOfRangeException]: The parameters do not form a valid time.
  /// Returns: The resulting time.
  factory LocalTime.fromHourMinuteSecondMillisecondTick(int hour, int minute, int second, int millisecond, int tickWithinMillisecond) {
    // Avoid the method calls which give a decent exception unless we're actually going to fail.
    if (hour < 0 || hour > TimeConstants.hoursPerDay - 1 ||
        minute < 0 || minute > TimeConstants.minutesPerHour - 1 ||
        second < 0 || second > TimeConstants.secondsPerMinute - 1 ||
        millisecond < 0 || millisecond > TimeConstants.millisecondsPerSecond - 1 ||
        tickWithinMillisecond < 0 || tickWithinMillisecond > TimeConstants.ticksPerMillisecond - 1) {
      Preconditions.checkArgumentRange('hour', hour, 0, TimeConstants.hoursPerDay - 1);
      Preconditions.checkArgumentRange('minute', minute, 0, TimeConstants.minutesPerHour - 1);
      Preconditions.checkArgumentRange('second', second, 0, TimeConstants.secondsPerMinute - 1);
      Preconditions.checkArgumentRange('millisecond', millisecond, 0, TimeConstants.millisecondsPerSecond - 1);
      Preconditions.checkArgumentRange('tickWithinMillisecond', tickWithinMillisecond, 0, TimeConstants.ticksPerMillisecond - 1);
    }
    int nanoseconds = (
        hour * TimeConstants.nanosecondsPerHour +
            minute * TimeConstants.nanosecondsPerMinute +
            second * TimeConstants.nanosecondsPerSecond +
            millisecond * TimeConstants.nanosecondsPerMillisecond +
            tickWithinMillisecond * TimeConstants.nanosecondsPerTick);
    return new LocalTime._fromNanoseconds(nanoseconds);
  }


  /// Factory method for creating a local time from the hour of day, minute of hour, second of minute, and tick of second.
  ///
  /// This is not a constructor overload as it would have the same signature as the one taking millisecond of second.
  ///
  /// [hour]: The hour of day in the desired time, in the range [0, 23].
  /// [minute]: The minute of hour in the desired time, in the range [0, 59].
  /// [second]: The second of minute in the desired time, in the range [0, 59].
  /// [tickWithinSecond]: The tick within the second in the desired time, in the range [0, 9999999].
  /// [ArgumentOutOfRangeException]: The parameters do not form a valid time.
  /// Returns: The resulting time.
  factory LocalTime.fromHourMinuteSecondTick(int hour, int minute, int second, int tickWithinSecond) {
    // Avoid the method calls which give a decent exception unless we're actually going to fail.
    if (hour < 0 || hour > TimeConstants.hoursPerDay - 1 ||
        minute < 0 || minute > TimeConstants.minutesPerHour - 1 ||
        second < 0 || second > TimeConstants.secondsPerMinute - 1 ||
        tickWithinSecond < 0 || tickWithinSecond > TimeConstants.ticksPerSecond - 1) {
      Preconditions.checkArgumentRange('hour', hour, 0, TimeConstants.hoursPerDay - 1);
      Preconditions.checkArgumentRange('minute', minute, 0, TimeConstants.minutesPerHour - 1);
      Preconditions.checkArgumentRange('second', second, 0, TimeConstants.secondsPerMinute - 1);
      Preconditions.checkArgumentRange('tickWithinSecond', tickWithinSecond, 0, TimeConstants.ticksPerSecond - 1);
    }
    return new LocalTime._fromNanoseconds((
        hour * TimeConstants.nanosecondsPerHour +
            minute * TimeConstants.nanosecondsPerMinute +
            second * TimeConstants.nanosecondsPerSecond +
            tickWithinSecond * TimeConstants.nanosecondsPerTick));
  }


  /// Factory method for creating a local time from the hour of day, minute of hour, second of minute, and nanosecond of second.
  ///
  /// This is not a constructor overload as it would have the same signature as the one taking millisecond of second.
  ///
  /// [hour]: The hour of day in the desired time, in the range [0, 23].
  /// [minute]: The minute of hour in the desired time, in the range [0, 59].
  /// [second]: The second of minute in the desired time, in the range [0, 59].
  /// [nanosecondWithinSecond]: The nanosecond within the second in the desired time, in the range [0, 999999999].
  /// [ArgumentOutOfRangeException]: The parameters do not form a valid time.
  /// Returns: The resulting time.
  factory LocalTime.fromHourMinuteSecondNanosecond(int hour, int minute, int second, int nanosecondWithinSecond) {
    // Avoid the method calls which give a decent exception unless we're actually going to fail.
    if (hour < 0 || hour > TimeConstants.hoursPerDay - 1 ||
        minute < 0 || minute > TimeConstants.minutesPerHour - 1 ||
        second < 0 || second > TimeConstants.secondsPerMinute - 1 ||
        nanosecondWithinSecond < 0 || nanosecondWithinSecond > TimeConstants.nanosecondsPerSecond - 1) {
      Preconditions.checkArgumentRange('hour', hour, 0, TimeConstants.hoursPerDay - 1);
      Preconditions.checkArgumentRange('minute', minute, 0, TimeConstants.minutesPerHour - 1);
      Preconditions.checkArgumentRange('second', second, 0, TimeConstants.secondsPerMinute - 1);
      Preconditions.checkArgumentRange('nanosecondWithinSecond', nanosecondWithinSecond, 0, TimeConstants.nanosecondsPerSecond - 1);
    }
    return new LocalTime._fromNanoseconds((
        hour * TimeConstants.nanosecondsPerHour +
            minute * TimeConstants.nanosecondsPerMinute +
            second * TimeConstants.nanosecondsPerSecond +
            nanosecondWithinSecond));
  }


  /// Constructor only called from other parts of Time Machine - trusted to be the range [0, TimeConstants.nanosecondsPerDay).
  LocalTime._fromNanoseconds(this._nanoseconds)
  {
    // todo: look at farming debug 
    // Preconditions.debugCheckArgumentRange('nanoseconds', _nanoseconds, 0, TimeConstants.nanosecondsPerDay - 1);
    assert(_nanoseconds >= 0 && _nanoseconds < TimeConstants.nanosecondsPerDay, 'nanoseconds ($_nanoseconds) must be >= 0 and < ${TimeConstants.nanosecondsPerDay}.');
  }


  /// Factory method for creating a local time from the number of ticks which have elapsed since midnight.
  ///
  /// [nanoseconds]: The number of ticks, in the range [0, 863,999,999,999]
  /// Returns: The resulting time.
  factory LocalTime._fromNanosecondsSinceMidnight(int nanoseconds) {
    // Avoid the method calls which give a decent exception unless we're actually going to fail.
    if (nanoseconds < 0 || nanoseconds > TimeConstants.nanosecondsPerDay - 1) {
      Preconditions.checkArgumentRange('nanoseconds', nanoseconds, 0, TimeConstants.nanosecondsPerDay - 1);
    }
    return new LocalTime._fromNanoseconds(nanoseconds);
  }


  /// Factory method for creating a local time from the number of ticks which have elapsed since midnight.
  ///
  /// [ticks]: The number of ticks, in the range [0, 863,999,999,999]
  /// Returns: The resulting time.
  factory LocalTime.fromTicksSinceMidnight(int ticks) {
    // Avoid the method calls which give a decent exception unless we're actually going to fail.
    if (ticks < 0 || ticks > TimeConstants.ticksPerDay - 1) {
      Preconditions.checkArgumentRange('ticks', ticks, 0, TimeConstants.ticksPerDay - 1);
    }
    return new LocalTime._fromNanoseconds((ticks * TimeConstants.nanosecondsPerTick));
  }


  /// Factory method for creating a local time from the number of milliseconds which have elapsed since midnight.
  ///
  /// [milliseconds]: The number of milliseconds, in the range [0, 86,399,999]
  /// Returns: The resulting time.
  factory LocalTime.fromMillisecondsSinceMidnight(int milliseconds) {
    // Avoid the method calls which give a decent exception unless we're actually going to fail.
    if (milliseconds < 0 || milliseconds > TimeConstants.millisecondsPerDay - 1) {
      Preconditions.checkArgumentRange('milliseconds', milliseconds, 0, TimeConstants.millisecondsPerDay - 1);
    }
    return new LocalTime._fromNanoseconds((milliseconds * TimeConstants.nanosecondsPerMillisecond));
  }
  
  /// Factory method for creating a local time from the number of seconds which have elapsed since midnight.
  ///
  /// [seconds]: The number of seconds, in the range [0, 86,399]
  /// Returns: The resulting time.
  factory LocalTime.fromSecondsSinceMidnight(int seconds) {
    // Avoid the method calls which give a decent exception unless we're actually going to fail.
    if (seconds < 0 || seconds > TimeConstants.secondsPerDay - 1) {
      Preconditions.checkArgumentRange('seconds', seconds, 0, TimeConstants.secondsPerDay - 1);
    }
    return new LocalTime._fromNanoseconds((seconds * TimeConstants.nanosecondsPerSecond));
  }
  
  /// Gets the hour of day of this local time, in the range 0 to 23 inclusive.
  int get hour => _nanoseconds ~/ TimeConstants.nanosecondsPerHour;

  /// Gets the hour of the half-day of this local time, in the range 1 to 12 inclusive.
  int get clockHourOfHalfDay {
    int _hourOfHalfDay = this._hourOfHalfDay;
    return _hourOfHalfDay == 0 ? 12 : _hourOfHalfDay;
  }

  // TODO(feature): Consider exposing this.
  /// Gets the hour of the half-day of this local time, in the range 0 to 11 inclusive.
  int get _hourOfHalfDay => (hour % 12);


  /// Gets the minute of this local time, in the range 0 to 59 inclusive.
  int get minute {
    // Effectively nanoseconds / TimeConstants.nanosecondsPerMinute, but apparently rather more efficient.
    int minuteOfDay = _nanoseconds ~/ TimeConstants.nanosecondsPerMinute;
    return minuteOfDay % TimeConstants.minutesPerHour;
  }


  /// Gets the second of this local time within the minute, in the range 0 to 59 inclusive.
  int get second {
    int secondOfDay = (_nanoseconds ~/ TimeConstants.nanosecondsPerSecond);
    return secondOfDay % TimeConstants.secondsPerMinute;
  }


  /// Gets the millisecond of this local time within the second, in the range 0 to 999 inclusive.
  int get millisecond {
    int milliSecondOfDay = (_nanoseconds ~/ TimeConstants.nanosecondsPerMillisecond);
    return (milliSecondOfDay % TimeConstants.millisecondsPerSecond);
  }

// TODO(optimization): Rewrite for performance?

  /// Gets the tick of this local time within the second, in the range 0 to 9,999,999 inclusive.
  int get tickOfSecond => ((tickOfDay % TimeConstants.ticksPerSecond));


  /// Gets the tick of this local time within the day, in the range 0 to 863,999,999,999 inclusive.
  ///
  /// If the value does not fall on a tick boundary, it will be truncated towards zero.
  int get tickOfDay => _nanoseconds ~/ TimeConstants.nanosecondsPerTick;


  /// Gets the nanosecond of this local time within the second, in the range 0 to 999,999,999 inclusive.
  int get nanosecondOfSecond => ((_nanoseconds % TimeConstants.nanosecondsPerSecond));


  /// Gets the nanosecond of this local time within the day, in the range 0 to 86,399,999,999,999 inclusive.
  int get nanosecondOfDay => _nanoseconds;


  /// Creates a new local time by adding a period to an existing time. The period must not contain
  /// any date-related units (days etc) with non-zero values.
  ///
  /// [time]: The time to add the period to
  /// [period]: The period to add
  /// Returns: The result of adding the period to the time, wrapping via midnight if necessary
  LocalTime operator +(Period period) {
    Preconditions.checkNotNull(period, 'period');
    Preconditions.checkArgument(!period.hasDateComponent, 'period', "Cannot add a period with a date component to a time");
    return IPeriod.addTimeTo(period, this, 1);
  }


  /// Adds the specified period to the time. Friendly alternative to `operator+()`.
  ///
  /// [time]: The time to add the period to
  /// [period]: The period to add. Must not contain any (non-zero) date units.
  /// Returns: The sum of the given time and period
  static LocalTime add(LocalTime time, Period period) => time + period;


  /// Adds the specified period to this time. Fluent alternative to `operator+()`.
  ///
  /// [period]: The period to add. Must not contain any (non-zero) date units.
  /// Returns: The sum of this time and the given period
  LocalTime plus(Period period) => this + period;


  /// Creates a new local time by subtracting a period from an existing time. The period must not contain
  /// any date-related units (days etc) with non-zero values.
  /// This is a convenience operator over the [Minus(Period)] method.
  ///
  /// [time]: The time to subtract the period from
  /// [period]: The period to subtract
  /// Returns: The result of subtract the period from the time, wrapping via midnight if necessary
  ///
  /// Subtracts one time from another, returning the result as a [Period].
  ///
  /// This is simply a convenience operator for calling [Period.Between(LocalTime,LocalTime)].
  ///
  /// [lhs]: The time to subtract from
  /// [rhs]: The time to subtract
  /// Returns: The result of subtracting one time from another.
  // todo: still hate dynamic dispatch
  dynamic operator -(dynamic rhs) => rhs is Period ? minusPeriod(rhs) : rhs is LocalTime ? between(rhs) : throw new ArgumentError();
  //Period operator -(LocalTime rhs) => Period.BetweenTimes(rhs, this);

  /// Subtracts the specified period from the time. Friendly alternative to `operator-()`.
  ///
  /// [time]: The time to subtract the period from
  /// [period]: The period to subtract. Must not contain any (non-zero) date units.
  /// Returns: The result of subtracting the given period from the time.
  static LocalTime subtract(LocalTime time, Period period) => time.minusPeriod(period);

/// Subtracts the specified period from this time. Fluent alternative to `operator-()`.
///
/// [period]: The period to subtract. Must not contain any (non-zero) date units.
/// Returns: The result of subtracting the given period from this time.

  LocalTime minusPeriod(Period period) {
    Preconditions.checkNotNull(period, 'period');
    Preconditions.checkArgument(!period.hasDateComponent, 'period', "Cannot subtract a period with a date component from a time");
    return IPeriod.addTimeTo(period, this, -1);
  }

// todo: this is a mess here ~ I feel like I didn't get the operators and collaries correct here

//  /// Subtracts one time from another, returning the result as a <see cref="Period"/> with units of years, months and days.
//  ///
//  /// <remarks>
//  /// This is simply a convenience method for calling <see cref="Period.Between(LocalTime,LocalTime)"/>.
//  /// </remarks>
//  /// <param name="lhs">The time to subtract from</param>
//  /// <param name="rhs">The time to subtract</param>
//  /// <returns>The result of subtracting one time from another.</returns>
//  Period Subtract(LocalTime rhs) => this - rhs;


  /// Subtracts the specified time from this time, returning the result as a [Period].
  /// Fluent alternative to `operator-()`.
  ///
  /// [time]: The time to subtract from this
  /// Returns: The difference between the specified time and this one
  Period between(LocalTime time) => Period.betweenTimes(time, this);


  /// Compares two local times for equality, by checking whether they represent
  /// the exact same local time, down to the tick.
  ///
  /// [lhs]: The first value to compare
  /// [rhs]: The second value to compare
  /// Returns: True if the two times are the same; false otherwise
  @override bool operator ==(dynamic rhs) => rhs is LocalTime && this._nanoseconds == rhs._nanoseconds;

  /// Compares two LocalTime values to see if the left one is strictly earlier than the right
  /// one.
  ///
  /// [lhs]: First operand of the comparison
  /// [rhs]: Second operand of the comparison
  /// Returns: true if the [lhs] is strictly earlier than [rhs], false otherwise.
  bool operator <(LocalTime rhs) => this._nanoseconds < rhs._nanoseconds;


  /// Compares two LocalTime values to see if the left one is earlier than or equal to the right
  /// one.
  ///
  /// [lhs]: First operand of the comparison
  /// [rhs]: Second operand of the comparison
  /// Returns: true if the [lhs] is earlier than or equal to [rhs], false otherwise.
  bool operator <=(LocalTime rhs) => this._nanoseconds <= rhs._nanoseconds;


  /// Compares two LocalTime values to see if the left one is strictly later than the right
  /// one.
  ///
  /// [lhs]: First operand of the comparison
  /// [rhs]: Second operand of the comparison
  /// Returns: true if the [lhs] is strictly later than [rhs], false otherwise.
  bool operator >(LocalTime rhs) => this._nanoseconds > rhs._nanoseconds;


  /// Compares two LocalTime values to see if the left one is later than or equal to the right
  /// one.
  ///
  /// [lhs]: First operand of the comparison
  /// [rhs]: Second operand of the comparison
  /// Returns: true if the [lhs] is later than or equal to [rhs], false otherwise.
  bool operator >=(LocalTime rhs) => this._nanoseconds >= rhs._nanoseconds;


  /// Indicates whether this time is earlier, later or the same as another one.
  ///
  /// [other]: The other date/time to compare this one with
  /// A value less than zero if this time is earlier than [other];
  /// zero if this time is the same as [other]; a value greater than zero if this time is
  /// later than [other].
  int compareTo(LocalTime other) => _nanoseconds.compareTo(other?._nanoseconds ?? 0);


  /// Returns a hash code for this local time.
  ///
  /// Returns: A hash code for this local time.
  @override int get hashCode => _nanoseconds.hashCode;


  /// Compares this local time with the specified one for equality,
  /// by checking whether the two values represent the exact same local time, down to the tick.
  ///
  /// [other]: The other local time to compare this one with
  /// Returns: True if the specified time is equal to this one; false otherwise
  bool equals(LocalTime other) => this == other;

  /// Returns a new LocalTime representing the current value with the given number of hours added.
  ///
  /// If the value goes past the start or end of the day, it wraps - so 11pm plus two hours is 1am, for example.
  ///
  /// [hours]: The number of hours to add
  /// Returns: The current value plus the given number of hours.
  LocalTime plusHours(int hours) => TimePeriodField.hours.addTimeSimple(this, hours);

  /// Returns a new LocalTime representing the current value with the given number of minutes added.
  ///
  /// If the value goes past the start or end of the day, it wraps - so 11pm plus 120 minutes is 1am, for example.
  ///
  /// [minutes]: The number of minutes to add
  /// Returns: The current value plus the given number of minutes.
  LocalTime plusMinutes(int minutes) => TimePeriodField.minutes.addTimeSimple(this, minutes);


  /// Returns a new LocalTime representing the current value with the given number of seconds added.
  ///
  /// If the value goes past the start or end of the day, it wraps - so 11:59pm plus 120 seconds is 12:01am, for example.
  ///
  /// [seconds]: The number of seconds to add
  /// Returns: The current value plus the given number of seconds.
  LocalTime plusSeconds(int seconds) => TimePeriodField.seconds.addTimeSimple(this, seconds);


  /// Returns a new LocalTime representing the current value with the given number of milliseconds added.
  ///
  /// [milliseconds]: The number of milliseconds to add
  /// Returns: The current value plus the given number of milliseconds.
  LocalTime plusMilliseconds(int milliseconds) => TimePeriodField.milliseconds.addTimeSimple(this, milliseconds);


  /// Returns a new LocalTime representing the current value with the given number of ticks added.
  ///
  /// [ticks]: The number of ticks to add
  /// Returns: The current value plus the given number of ticks.
  LocalTime plusTicks(int ticks) => TimePeriodField.ticks.addTimeSimple(this, ticks);


  /// Returns a new LocalTime representing the current value with the given number of nanoseconds added.
  ///
  /// [nanoseconds]: The number of nanoseconds to add
  /// Returns: The current value plus the given number of ticks.
  LocalTime plusNanoseconds(int nanoseconds) => TimePeriodField.nanoseconds.addTimeSimple(this, nanoseconds);


  /// Returns this time, with the given adjuster applied to it.
  ///
  /// If the adjuster attempts to construct an invalid time, any exception thrown by
  /// that construction attempt will be propagated through this method.
  ///
  /// [adjuster]: The adjuster to apply.
  /// Returns: The adjusted time.
  LocalTime adjust(LocalTime Function(LocalTime) adjuster) =>
      Preconditions.checkNotNull(adjuster, 'adjuster')(this);


  /// Returns an [OffsetTime] for this time-of-day with the given offset.
  ///
  /// This method is purely a convenient alternative to calling the [OffsetTime] constructor directly.
  /// [offset]: The offset to apply.
  /// Returns: The result of this time-of-day offset by the given amount.
  OffsetTime withOffset(Offset offset) => new OffsetTime(this, offset);


  // todo: reference style guide
  /// Combines this [LocalTime] with the given [LocalDate]
  /// into a single [LocalDateTime].
  /// Fluent alternative to `operator+()`.
  ///
  /// [date]: The date to combine with this time
  /// Returns: The [LocalDateTime] representation of the given time on this date
  LocalDateTime atDate(LocalDate date) => new LocalDateTime(date, this);


  /// Returns the later time of the given two.
  ///
  /// [x]: The first time to compare.
  /// [y]: The second time to compare.
  /// Returns: The later instant of [x] or [y].
  static LocalTime max(LocalTime x, LocalTime y) {
    return x > y ? x : y;
  }


  /// Returns the earlier time of the given two.
  ///
  /// [x]: The first time to compare.
  /// [y]: The second time to compare.
  /// Returns: The earlier time of [x] or [y].
  static LocalTime min(LocalTime x, LocalTime y) => x < y ? x : y;
  
  /// Formats the value of the current instance using the specified pattern.
  ///
  /// A [String] containing the value of the current instance in the specified format.
  ///
  /// [patternText]: The [String] specifying the pattern to use,
  /// or null to use the default format pattern ("T").
  ///
  /// [formatProvider]: The [IIFormatProvider] to use when formatting the value,
  /// or null to use the current thread's culture to obtain a format provider.
  @override String toString([String patternText = null, /*IFormatProvider*/ dynamic formatProvider = null]) =>
      LocalTimePattern.bclSupport.format(this, patternText, formatProvider ?? CultureInfo.currentCulture);
}
