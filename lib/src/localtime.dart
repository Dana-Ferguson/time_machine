// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/LocalTime.cs
// 12c338e  on Nov 11, 2017

import 'package:meta/meta.dart';

import 'package:time_machine/time_machine_fields.dart';
import 'utility/preconditions.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';

// Note: documentation that refers to the LocalDateTime type within this class must use the fully-qualified
// reference to avoid being resolved to the LocalDateTime property instead.

/// LocalTime is an immutable struct representing a time of day, with no reference
/// to a particular calendar, time zone or date.
/// 
/// <threadsafety>This type is an immutable value type. See the thread safety section of the user guide for more information.</threadsafety>
@immutable
class LocalTime // : IEquatable<LocalTime>, IComparable<LocalTime>, IFormattable, IComparable, IXmlSerializable
    {

  /// Local time at midnight, i.e. 0 hours, 0 minutes, 0 seconds.
  static final LocalTime Midnight = new LocalTime(0, 0, 0);


  /// The minimum value of this type; equivalent to <see cref="Midnight"/>.
  static final LocalTime MinValue = Midnight;


  /// Local time at noon, i.e. 12 hours, 0 minutes, 0 seconds.
  static final LocalTime Noon = new LocalTime(12, 0, 0);


  /// The maximum value of this type, one nanosecond before midnight.
  ///
  /// <remarks>This is useful if you have to use an inclusive upper bound for some reason.
  /// In general, it's better to use an exclusive upper bound, in which case use midnight of
  /// the following day.</remarks>
  static final LocalTime MaxValue = new LocalTime.fromNanoseconds(TimeConstants.nanosecondsPerDay - 1);


  /// Nanoseconds since midnight, in the range [0, 86,400,000,000,000). ~ 46 bits
  final int _nanoseconds;

  /// Creates a local time at the given hour, minute, second and millisecond,
  /// with a tick-of-millisecond value of zero.
  ///
  /// <param name="hour">The hour of day.</param>
  /// <param name="minute">The minute of the hour.</param>
  /// <param name="second">The second of the minute.</param>
  /// <param name="millisecond">The millisecond of the second.</param>
  /// <exception cref="ArgumentOutOfRangeException">The parameters do not form a valid time.</exception>
  /// <returns>The resulting time.</returns>
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


  /// Factory method to create a local time at the given hour, minute, second, millisecond and tick within millisecond.
  ///
  /// <param name="hour">The hour of day.</param>
  /// <param name="minute">The minute of the hour.</param>
  /// <param name="second">The second of the minute.</param>
  /// <param name="millisecond">The millisecond of the second.</param>
  /// <param name="tickWithinMillisecond">The tick within the millisecond.</param>
  /// <exception cref="ArgumentOutOfRangeException">The parameters do not form a valid time.</exception>
  /// <returns>The resulting time.</returns>
  static LocalTime FromHourMinuteSecondMillisecondTick(int hour, int minute, int second, int millisecond, int tickWithinMillisecond) {
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
    return new LocalTime.fromNanoseconds(nanoseconds);
  }


  /// Factory method for creating a local time from the hour of day, minute of hour, second of minute, and tick of second.
  ///
  /// <remarks>
  /// This is not a constructor overload as it would have the same signature as the one taking millisecond of second.
  /// </remarks>
  /// <param name="hour">The hour of day in the desired time, in the range [0, 23].</param>
  /// <param name="minute">The minute of hour in the desired time, in the range [0, 59].</param>
  /// <param name="second">The second of minute in the desired time, in the range [0, 59].</param>
  /// <param name="tickWithinSecond">The tick within the second in the desired time, in the range [0, 9999999].</param>
  /// <exception cref="ArgumentOutOfRangeException">The parameters do not form a valid time.</exception>
  /// <returns>The resulting time.</returns>
  static LocalTime FromHourMinuteSecondTick(int hour, int minute, int second, int tickWithinSecond) {
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
    return new LocalTime.fromNanoseconds((
        hour * TimeConstants.nanosecondsPerHour +
            minute * TimeConstants.nanosecondsPerMinute +
            second * TimeConstants.nanosecondsPerSecond +
            tickWithinSecond * TimeConstants.nanosecondsPerTick));
  }


  /// Factory method for creating a local time from the hour of day, minute of hour, second of minute, and nanosecond of second.
  ///
  /// <remarks>
  /// This is not a constructor overload as it would have the same signature as the one taking millisecond of second.
  /// </remarks>
  /// <param name="hour">The hour of day in the desired time, in the range [0, 23].</param>
  /// <param name="minute">The minute of hour in the desired time, in the range [0, 59].</param>
  /// <param name="second">The second of minute in the desired time, in the range [0, 59].</param>
  /// <param name="nanosecondWithinSecond">The nanosecond within the second in the desired time, in the range [0, 999999999].</param>
  /// <exception cref="ArgumentOutOfRangeException">The parameters do not form a valid time.</exception>
  /// <returns>The resulting time.</returns>
  static LocalTime FromHourMinuteSecondNanosecond(int hour, int minute, int second, int nanosecondWithinSecond) {
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
    return new LocalTime.fromNanoseconds((
        hour * TimeConstants.nanosecondsPerHour +
            minute * TimeConstants.nanosecondsPerMinute +
            second * TimeConstants.nanosecondsPerSecond +
            nanosecondWithinSecond));
  }


  /// Constructor only called from other parts of Noda Time - trusted to be the range [0, TimeConstants.nanosecondsPerDay).
  ///
  @internal LocalTime.fromNanoseconds(this._nanoseconds);
//  {
// Preconditions.debugcheckArgumentRange('nanoseconds', nanoseconds, 0, TimeConstants.nanosecondsPerDay - 1);
//  }


  /// Factory method for creating a local time from the number of ticks which have elapsed since midnight.
  ///
  /// <param name="nanoseconds">The number of ticks, in the range [0, 863,999,999,999]</param>
  /// <returns>The resulting time.</returns>
  @internal static LocalTime FromNanosecondsSinceMidnight(int nanoseconds) {
    // Avoid the method calls which give a decent exception unless we're actually going to fail.
    if (nanoseconds < 0 || nanoseconds > TimeConstants.nanosecondsPerDay - 1) {
      Preconditions.checkArgumentRange('nanoseconds', nanoseconds, 0, TimeConstants.nanosecondsPerDay - 1);
    }
    return new LocalTime.fromNanoseconds(nanoseconds);
  }


  /// Factory method for creating a local time from the number of ticks which have elapsed since midnight.
  ///
  /// <param name="ticks">The number of ticks, in the range [0, 863,999,999,999]</param>
  /// <returns>The resulting time.</returns>
  static LocalTime FromTicksSinceMidnight(int ticks) {
    // Avoid the method calls which give a decent exception unless we're actually going to fail.
    if (ticks < 0 || ticks > TimeConstants.ticksPerDay - 1) {
      Preconditions.checkArgumentRange('ticks', ticks, 0, TimeConstants.ticksPerDay - 1);
    }
    return new LocalTime.fromNanoseconds((ticks * TimeConstants.nanosecondsPerTick));
  }


  /// Factory method for creating a local time from the number of milliseconds which have elapsed since midnight.
  ///
  /// <param name="milliseconds">The number of milliseconds, in the range [0, 86,399,999]</param>
  /// <returns>The resulting time.</returns>
  static LocalTime FromMillisecondsSinceMidnight(int milliseconds) {
    // Avoid the method calls which give a decent exception unless we're actually going to fail.
    if (milliseconds < 0 || milliseconds > TimeConstants.millisecondsPerDay - 1) {
      Preconditions.checkArgumentRange('milliseconds', milliseconds, 0, TimeConstants.millisecondsPerDay - 1);
    }
    return new LocalTime.fromNanoseconds((milliseconds * TimeConstants.nanosecondsPerMillisecond));
  }


  /// Factory method for creating a local time from the number of seconds which have elapsed since midnight.
  ///
  /// <param name="seconds">The number of seconds, in the range [0, 86,399]</param>
  /// <returns>The resulting time.</returns>
  static LocalTime FromSecondsSinceMidnight(int seconds) {
    // Avoid the method calls which give a decent exception unless we're actually going to fail.
    if (seconds < 0 || seconds > TimeConstants.secondsPerDay - 1) {
      Preconditions.checkArgumentRange('seconds', seconds, 0, TimeConstants.secondsPerDay - 1);
    }
    return new LocalTime.fromNanoseconds((seconds * TimeConstants.nanosecondsPerSecond));
  }


  /// Gets the hour of day of this local time, in the range 0 to 23 inclusive.
  ///
  /// <value>The hour of day of this local time, in the range 0 to 23 inclusive.</value>
  int get Hour => _nanoseconds ~/ TimeConstants.nanosecondsPerHour;


  /// Gets the hour of the half-day of this local time, in the range 1 to 12 inclusive.
  ///
  /// <value>The hour of the half-day of this local time, in the range 1 to 12 inclusive.</value>
  int get ClockHourOfHalfDay {
    int hourOfHalfDay = HourOfHalfDay;
    return hourOfHalfDay == 0 ? 12 : hourOfHalfDay;
  }

// TODO(feature): Consider exposing this.

  /// Gets the hour of the half-day of this local time, in the range 0 to 11 inclusive.
  ///
  /// <value>The hour of the half-day of this local time, in the range 0 to 11 inclusive.</value>
  @internal int get HourOfHalfDay => (Hour % 12);


  /// Gets the minute of this local time, in the range 0 to 59 inclusive.
  ///
  /// <value>The minute of this local time, in the range 0 to 59 inclusive.</value>
  int get Minute {
    // Effectively nanoseconds / TimeConstants.nanosecondsPerMinute, but apparently rather more efficient.
    int minuteOfDay = _nanoseconds ~/ TimeConstants.nanosecondsPerMinute;
    return minuteOfDay % TimeConstants.minutesPerHour;
  }


  /// Gets the second of this local time within the minute, in the range 0 to 59 inclusive.
  ///
  /// <value>The second of this local time within the minute, in the range 0 to 59 inclusive.</value>
  int get Second {
    int secondOfDay = (_nanoseconds ~/ TimeConstants.nanosecondsPerSecond);
    return secondOfDay % TimeConstants.secondsPerMinute;
  }


  /// Gets the millisecond of this local time within the second, in the range 0 to 999 inclusive.
  ///
  /// <value>The millisecond of this local time within the second, in the range 0 to 999 inclusive.</value>
  int get Millisecond {
    int milliSecondOfDay = (_nanoseconds ~/ TimeConstants.nanosecondsPerMillisecond);
    return (milliSecondOfDay % TimeConstants.millisecondsPerSecond);
  }

// TODO(optimization): Rewrite for performance?

  /// Gets the tick of this local time within the second, in the range 0 to 9,999,999 inclusive.
  ///
  /// <value>The tick of this local time within the second, in the range 0 to 9,999,999 inclusive.</value>
  int get TickOfSecond => ((TickOfDay % TimeConstants.ticksPerSecond));


  /// Gets the tick of this local time within the day, in the range 0 to 863,999,999,999 inclusive.
  ///
  /// <remarks>
  /// If the value does not fall on a tick boundary, it will be truncated towards zero.
  /// </remarks>
  /// <value>The tick of this local time within the day, in the range 0 to 863,999,999,999 inclusive.</value>
  int get TickOfDay => _nanoseconds ~/ TimeConstants.nanosecondsPerTick;


  /// Gets the nanosecond of this local time within the second, in the range 0 to 999,999,999 inclusive.
  ///
  /// <value>The nanosecond of this local time within the second, in the range 0 to 999,999,999 inclusive.</value>
  int get NanosecondOfSecond => ((_nanoseconds % TimeConstants.nanosecondsPerSecond));


  /// Gets the nanosecond of this local time within the day, in the range 0 to 86,399,999,999,999 inclusive.
  ///
  /// <value>The nanosecond of this local time within the day, in the range 0 to 86,399,999,999,999 inclusive.</value>
  int get NanosecondOfDay => _nanoseconds;


  /// Creates a new local time by adding a period to an existing time. The period must not contain
  /// any date-related units (days etc) with non-zero values.
  ///
  /// <param name="time">The time to add the period to</param>
  /// <param name="period">The period to add</param>
  /// <returns>The result of adding the period to the time, wrapping via midnight if necessary</returns>
  LocalTime operator +(Period period) {
    Preconditions.checkNotNull(period, 'period');
    Preconditions.checkArgument(!period.HasDateComponent, 'period', "Cannot add a period with a date component to a time");
    return period.AddTimeTo(this, 1);
  }


  /// Adds the specified period to the time. Friendly alternative to <c>operator+()</c>.
  ///
  /// <param name="time">The time to add the period to</param>
  /// <param name="period">The period to add. Must not contain any (non-zero) date units.</param>
  /// <returns>The sum of the given time and period</returns>
  static LocalTime Add(LocalTime time, Period period) => time + period;


  /// Adds the specified period to this time. Fluent alternative to <c>operator+()</c>.
  ///
  /// <param name="period">The period to add. Must not contain any (non-zero) date units.</param>
  /// <returns>The sum of this time and the given period</returns>

  LocalTime Plus(Period period) => this + period;


  /// Creates a new local time by subtracting a period from an existing time. The period must not contain
  /// any date-related units (days etc) with non-zero values.
  /// This is a convenience operator over the <see cref="Minus(Period)"/> method.
  ///
  /// <param name="time">The time to subtract the period from</param>
  /// <param name="period">The period to subtract</param>
  /// <returns>The result of subtract the period from the time, wrapping via midnight if necessary</returns>
  ///
  /// Subtracts one time from another, returning the result as a <see cref="Period"/>.
  ///
  /// <remarks>
  /// This is simply a convenience operator for calling <see cref="Period.Between(NodaTime.LocalTime,NodaTime.LocalTime)"/>.
  /// </remarks>
  /// <param name="lhs">The time to subtract from</param>
  /// <param name="rhs">The time to subtract</param>
  /// <returns>The result of subtracting one time from another.</returns>
  // todo: still hate dynamic dispatch
  dynamic operator -(dynamic rhs) => rhs is Period ? MinusPeriod(rhs) : rhs is LocalTime ? Between(rhs) : throw new TypeError();
  //Period operator -(LocalTime rhs) => Period.BetweenTimes(rhs, this);

  /// Subtracts the specified period from the time. Friendly alternative to <c>operator-()</c>.
  ///
  /// <param name="time">The time to subtract the period from</param>
  /// <param name="period">The period to subtract. Must not contain any (non-zero) date units.</param>
  /// <returns>The result of subtracting the given period from the time.</returns>
  static LocalTime Subtract(LocalTime time, Period period) => time.MinusPeriod(period);

  /// Subtracts the specified period from this time. Fluent alternative to <c>operator-()</c>.
  ///
  /// <param name="period">The period to subtract. Must not contain any (non-zero) date units.</param>
  /// <returns>The result of subtracting the given period from this time.</returns>

  LocalTime MinusPeriod(Period period) {
    Preconditions.checkNotNull(period, 'period');
    Preconditions.checkArgument(!period.HasDateComponent, 'period', "Cannot subtract a period with a date component from a time");
    return period.AddTimeTo(this, -1);
  }

  // todo: this is a mess here ~ I feel like I didn't get the operators and collaries correct here

//  /// Subtracts one time from another, returning the result as a <see cref="Period"/> with units of years, months and days.
//  ///
//  /// <remarks>
//  /// This is simply a convenience method for calling <see cref="Period.Between(NodaTime.LocalTime,NodaTime.LocalTime)"/>.
//  /// </remarks>
//  /// <param name="lhs">The time to subtract from</param>
//  /// <param name="rhs">The time to subtract</param>
//  /// <returns>The result of subtracting one time from another.</returns>
//  Period Subtract(LocalTime rhs) => this - rhs;


  /// Subtracts the specified time from this time, returning the result as a <see cref="Period"/>.
  /// Fluent alternative to <c>operator-()</c>.
  ///
  /// <param name="time">The time to subtract from this</param>
  /// <returns>The difference between the specified time and this one</returns>
  Period Between(LocalTime time) => Period.BetweenTimes(time, this); // this - time;


  /// Compares two local times for equality, by checking whether they represent
  /// the exact same local time, down to the tick.
  ///
  /// <param name="lhs">The first value to compare</param>
  /// <param name="rhs">The second value to compare</param>
  /// <returns>True if the two times are the same; false otherwise</returns>
  @override bool operator ==(dynamic rhs) => rhs is LocalTime ?? this._nanoseconds == rhs._nanoseconds;

// static bool operator !=(LocalTime lhs, LocalTime rhs) => lhs.nanoseconds != rhs.nanoseconds;


  /// Compares two LocalTime values to see if the left one is strictly earlier than the right
  /// one.
  ///
  /// <param name="lhs">First operand of the comparison</param>
  /// <param name="rhs">Second operand of the comparison</param>
  /// <returns>true if the <paramref name="lhs"/> is strictly earlier than <paramref name="rhs"/>, false otherwise.</returns>
  bool operator <(LocalTime rhs) => this._nanoseconds < rhs._nanoseconds;


  /// Compares two LocalTime values to see if the left one is earlier than or equal to the right
  /// one.
  ///
  /// <param name="lhs">First operand of the comparison</param>
  /// <param name="rhs">Second operand of the comparison</param>
  /// <returns>true if the <paramref name="lhs"/> is earlier than or equal to <paramref name="rhs"/>, false otherwise.</returns>
  bool operator <=(LocalTime rhs) => this._nanoseconds <= rhs._nanoseconds;


  /// Compares two LocalTime values to see if the left one is strictly later than the right
  /// one.
  ///
  /// <param name="lhs">First operand of the comparison</param>
  /// <param name="rhs">Second operand of the comparison</param>
  /// <returns>true if the <paramref name="lhs"/> is strictly later than <paramref name="rhs"/>, false otherwise.</returns>
  bool operator >(LocalTime rhs) => this._nanoseconds > rhs._nanoseconds;


  /// Compares two LocalTime values to see if the left one is later than or equal to the right
  /// one.
  ///
  /// <param name="lhs">First operand of the comparison</param>
  /// <param name="rhs">Second operand of the comparison</param>
  /// <returns>true if the <paramref name="lhs"/> is later than or equal to <paramref name="rhs"/>, false otherwise.</returns>
  bool operator >=(LocalTime rhs) => this._nanoseconds >= rhs._nanoseconds;


  /// Indicates whether this time is earlier, later or the same as another one.
  ///
  /// <param name="other">The other date/time to compare this one with</param>
  /// <returns>A value less than zero if this time is earlier than <paramref name="other"/>;
  /// zero if this time is the same as <paramref name="other"/>; a value greater than zero if this time is
  /// later than <paramref name="other"/>.</returns>
  int CompareTo(LocalTime other) => _nanoseconds.compareTo(other._nanoseconds);


  /// Returns a hash code for this local time.
  ///
  /// <returns>A hash code for this local time.</returns>
  @override int get hashCode => _nanoseconds.hashCode;


  /// Compares this local time with the specified one for equality,
  /// by checking whether the two values represent the exact same local time, down to the tick.
  ///
  /// <param name="other">The other local time to compare this one with</param>
  /// <returns>True if the specified time is equal to this one; false otherwise</returns>
  bool Equals(LocalTime other) => this == other;


//  /// Compares this local time with the specified reference. A local time is
//  /// only equal to another local time with the same underlying tick value.
//  ///
//  /// <param name="obj">The object to compare this one with</param>
//  /// <returns>True if the specified value is a local time which is equal to this one; false otherwise</returns>
//  @override bool Equals(dynamic obj) => obj is LocalTime && this == obj;


  /// Returns a new LocalTime representing the current value with the given number of hours added.
  ///
  /// <remarks>
  /// If the value goes past the start or end of the day, it wraps - so 11pm plus two hours is 1am, for example.
  /// </remarks>
  /// <param name="hours">The number of hours to add</param>
  /// <returns>The current value plus the given number of hours.</returns>

  LocalTime PlusHours(int hours) => TimePeriodField.Hours.AddTimeSimple(this, hours);


  /// Returns a new LocalTime representing the current value with the given number of minutes added.
  ///
  /// <remarks>
  /// If the value goes past the start or end of the day, it wraps - so 11pm plus 120 minutes is 1am, for example.
  /// </remarks>
  /// <param name="minutes">The number of minutes to add</param>
  /// <returns>The current value plus the given number of minutes.</returns>

  LocalTime PlusMinutes(int minutes) => TimePeriodField.Minutes.AddTimeSimple(this, minutes);


  /// Returns a new LocalTime representing the current value with the given number of seconds added.
  ///
  /// <remarks>
  /// If the value goes past the start or end of the day, it wraps - so 11:59pm plus 120 seconds is 12:01am, for example.
  /// </remarks>
  /// <param name="seconds">The number of seconds to add</param>
  /// <returns>The current value plus the given number of seconds.</returns>

  LocalTime PlusSeconds(int seconds) => TimePeriodField.Seconds.AddTimeSimple(this, seconds);


  /// Returns a new LocalTime representing the current value with the given number of milliseconds added.
  ///
  /// <param name="milliseconds">The number of milliseconds to add</param>
  /// <returns>The current value plus the given number of milliseconds.</returns>

  LocalTime PlusMilliseconds(int milliseconds) => TimePeriodField.Milliseconds.AddTimeSimple(this, milliseconds);


  /// Returns a new LocalTime representing the current value with the given number of ticks added.
  ///
  /// <param name="ticks">The number of ticks to add</param>
  /// <returns>The current value plus the given number of ticks.</returns>

  LocalTime PlusTicks(int ticks) => TimePeriodField.Ticks.AddTimeSimple(this, ticks);


  /// Returns a new LocalTime representing the current value with the given number of nanoseconds added.
  ///
  /// <param name="nanoseconds">The number of nanoseconds to add</param>
  /// <returns>The current value plus the given number of ticks.</returns>

  LocalTime PlusNanoseconds(int nanoseconds) => TimePeriodField.Nanoseconds.AddTimeSimple(this, nanoseconds);


  /// Returns this time, with the given adjuster applied to it.
  ///
  /// <remarks>
  /// If the adjuster attempts to construct an invalid time, any exception thrown by
  /// that construction attempt will be propagated through this method.
  /// </remarks>
  /// <param name="adjuster">The adjuster to apply.</param>
  /// <returns>The adjusted time.</returns>

  LocalTime With(LocalTime Function(LocalTime) adjuster) =>
      Preconditions.checkNotNull(adjuster, 'adjuster')(this);


  /// Returns an <see cref="OffsetTime"/> for this time-of-day with the given offset.
  ///
  /// <remarks>This method is purely a convenient alternative to calling the <see cref="OffsetTime"/> constructor directly.</remarks>
  /// <param name="offset">The offset to apply.</param>
  /// <returns>The result of this time-of-day offset by the given amount.</returns>

  OffsetTime WithOffset(Offset offset) => new OffsetTime(this, offset);


  /// Combines this <see cref="LocalTime"/> with the given <see cref="LocalDate"/>
  /// into a single <see cref="LocalDateTime"/>.
  /// Fluent alternative to <c>operator+()</c>.
  ///
  /// <param name="date">The date to combine with this time</param>
  /// <returns>The <see cref="LocalDateTime"/> representation of the given time on this date</returns>

  LocalDateTime On(LocalDate date) => new LocalDateTime(date, this);


  /// Returns the later time of the given two.
  ///
  /// <param name="x">The first time to compare.</param>
  /// <param name="y">The second time to compare.</param>
  /// <returns>The later instant of <paramref name="x"/> or <paramref name="y"/>.</returns>
  static LocalTime Max(LocalTime x, LocalTime y) {
    return x > y ? x : y;
  }


  /// Returns the earlier time of the given two.
  ///
  /// <param name="x">The first time to compare.</param>
  /// <param name="y">The second time to compare.</param>
  /// <returns>The earlier time of <paramref name="x"/> or <paramref name="y"/>.</returns>
  static LocalTime Min(LocalTime x, LocalTime y) => x < y ? x : y;


  /// Returns a <see cref="System.String" /> that represents this instance.
  ///
  /// <returns>
  /// The value of the current instance in the default format pattern ("T"), using the current thread's
  /// culture to obtain a format provider.
  /// </returns>
  // @override String toString() => LocalTimePattern.BclSupport.Format(this, null, CultureInfo.CurrentCulture);


  /// Formats the value of the current instance using the specified pattern.
  ///
  /// <returns>
  /// A <see cref="T:System.String" /> containing the value of the current instance in the specified format.
  /// </returns>
  /// <param name="patternText">The <see cref="T:System.String" /> specifying the pattern to use,
  /// or null to use the default format pattern ("T").
  /// </param>
  /// <param name="formatProvider">The <see cref="T:System.IFormatProvider" /> to use when formatting the value,
  /// or null to use the current thread's culture to obtain a format provider.
  /// </param>
  /// <filterpriority>2</filterpriority>
  @override String toString() => TextShim.toStringLocalTime(this);
// @override String toString(String patternText, IFormatProvider formatProvider) =>
//    LocalTimePattern.BclSupport.Format(this, patternText, formatProvider);

  /// <summary>
  /// Formats the value of the current instance using the specified pattern.
  /// </summary>
  /// <returns>
  /// A <see cref="T:System.String" /> containing the value of the current instance in the specified format.
  /// </returns>
  /// <param name="patternText">The <see cref="T:System.String" /> specifying the pattern to use,
  /// or null to use the default format pattern ("T").
  /// </param>
  /// <param name="formatProvider">The <see cref="T:System.IFormatProvider" /> to use when formatting the value,
  /// or null to use the current thread's culture to obtain a format provider.
  /// </param>
  /// <filterpriority>2</filterpriority>
//  public string ToString(string patternText, IFormatProvider formatProvider) =>
//      LocalTimePattern.BclSupport.Format(this, patternText, formatProvider);

}