// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

// Note: documentation that refers to the LocalDateTime type within this class must use the fully-qualified
// reference to avoid being resolved to the LocalDateTime property instead.

@internal
abstract class ILocalTime {
  static LocalTime trustedNanoseconds(int nanoseconds) => LocalTime._(nanoseconds);

  static LocalTime untrustedNanoseconds(int nanoseconds) => LocalTime._untrusted(nanoseconds);
}

/// LocalTime is an immutable class representing a time of day, with no reference
/// to a particular calendar, time zone or date.
@immutable
class LocalTime implements Comparable<LocalTime> {
  /// Local time at midnight, i.e. 0 hours, 0 minutes, 0 seconds.
  static final LocalTime midnight = LocalTime(0, 0, 0);

  /// The minimum value of this type; equivalent to [midnight].
  static final LocalTime minValue = midnight;

  /// Local time at noon, i.e. 12 hours, 0 minutes, 0 seconds.
  static final LocalTime noon = LocalTime(12, 0, 0);

  /// The maximum value of this type, one nanosecond before midnight.
  ///
  /// This is useful if you have to use an inclusive upper bound for some reason.
  /// In general, it's better to use an exclusive upper bound, in which case use midnight of
  /// the following day.
  static final LocalTime maxValue = LocalTime._(TimeConstants.nanosecondsPerDay - 1);

  /// Nanoseconds since midnight, in the range [0, 86,400,000,000,000). ~ 46 bits
  // final int _nanoseconds;
  final NanosecondTime timeSinceMidnight;

  static const String _munArgumentError = 'Only one subsecond argument allowed.';

  /// Creates a local time at the given hour, minute, second and
  /// millisecond or microseconds or nanoseconds within the second.
  ///
  /// * [hour]: The hour of day.
  /// * [minute]: The minute of the hour.
  /// * [second]: The second of the minute.
  /// * [ms]: The millisecond of the second.
  /// * [us]: The microsecond within the second.
  /// * [ns]: The nanosecond within the second.
  ///
  /// Returns: The resulting time.
  ///
  /// * [RangeError]: The parameters do not form a valid time.
  /// * [ArgumentError]: More than one of ([ms], [us], [ns]) has a value.
  ///
  /// When\if https://github.com/dart-lang/sdk/issues/7056 becomes implemented,
  /// [second] will become optional, like this:
  /// `(int hour, int minute, [int second], {int ms, int us, int ns})`.
  /// The is a planned backwards compatible public API change.
  factory LocalTime(int hour, int minute, int second, {int? ms, int? us, int? ns}) {
    // Avoid the method calls which give a decent exception unless we're actually going to fail.
    if (hour < 0 || hour >= TimeConstants.hoursPerDay ||
        minute < 0 || minute >= TimeConstants.minutesPerHour ||
        second < 0 || second >= TimeConstants.secondsPerMinute) {
      Preconditions.checkArgumentRange('hour', hour, 0, TimeConstants.hoursPerDay - 1);
      Preconditions.checkArgumentRange('minute', minute, 0, TimeConstants.minutesPerHour - 1);
      Preconditions.checkArgumentRange('second', second, 0, TimeConstants.secondsPerMinute - 1);
    }

    var nanoseconds
        = hour * TimeConstants.nanosecondsPerHour
        + minute * TimeConstants.nanosecondsPerMinute
        + second * TimeConstants.nanosecondsPerSecond;
    ;

    // Only one sub-second variable may be implemented.
    // todo: is there a more performant check here?
    if (ms != null) {
      if (us != null) throw ArgumentError(_munArgumentError);
      if (ns != null) throw ArgumentError(_munArgumentError);
      if (ms < 0 || ms >= TimeConstants.millisecondsPerSecond) Preconditions.checkArgumentRange('milliseconds', ms, 0, TimeConstants.millisecondsPerSecond - 1);
      nanoseconds += ms * TimeConstants.nanosecondsPerMillisecond;
    }
    else if (us != null) {
      if (ns != null) throw ArgumentError(_munArgumentError);
      if (us < 0 || us >= TimeConstants.microsecondsPerSecond) Preconditions.checkArgumentRange('microseconds', us, 0, TimeConstants.microsecondsPerSecond - 1);
      nanoseconds += us * TimeConstants.nanosecondsPerMicrosecond;
    }
    else if (ns != null) {
      if (ns < 0 || ns >= TimeConstants.nanosecondsPerSecond) Preconditions.checkArgumentRange('nanoseconds', ns, 0, TimeConstants.nanosecondsPerSecond - 1);
      nanoseconds += ns;
    }

    return LocalTime._(nanoseconds);
  }

  /// Constructor only called from other parts of Time Machine - trusted to be the range [0, TimeConstants.nanosecondsPerDay).
  LocalTime._(int nanoseconds) : timeSinceMidnight = NanosecondTime(nanoseconds)
  {
    assert(nanoseconds >= 0 && nanoseconds < TimeConstants.nanosecondsPerDay, 'nanoseconds ($nanoseconds) must be >= 0 and < ${TimeConstants.nanosecondsPerDay}.');
  }

  /// Factory method for creating a local time from the number of ticks which have elapsed since midnight.
  ///
  /// * [nanoseconds]: The number of ticks, in the range [0, 863,999,999,999]
  ///
  /// Returns: The resulting time.
  factory LocalTime._untrusted(int nanoseconds) {
    // Avoid the method calls which give a decent exception unless we're actually going to fail.
    if (nanoseconds < 0 || nanoseconds >= TimeConstants.nanosecondsPerDay) {
      Preconditions.checkArgumentRange('nanoseconds', nanoseconds, 0, TimeConstants.nanosecondsPerDay - 1);
    }
    return LocalTime._(nanoseconds);
  }

  /// Factory method for creating a local time from the number of ticks which have elapsed since midnight.
  ///
  /// * [time]: The amount of time, in the range [Time.zero] inclusive, [Time.oneDay] exclusive.
  ///
  /// Returns: The resulting LocalTime.
  factory LocalTime.sinceMidnight(Time time) {
    var nanoseconds = time.inNanoseconds;
    // Avoid the method calls which give a decent exception unless we're actually going to fail.
    if (nanoseconds < 0 || nanoseconds >= TimeConstants.nanosecondsPerDay) {
      // Range error requires 'num' to be the range bounds, which isn't conceptually true here.
      // todo: is there a way to make this a Range error?
      throw ArgumentError.value('Invalid value: $time was out of range of [${Time.zero}, ${Time.oneDay}).');
    }
    return LocalTime._(nanoseconds);
  }

  /// Produces a [LocalTime] based on your [Clock.current] and your [DateTimeZone.local].
  factory LocalTime.currentClockTime() {
    var now = Instant.now();
    var nanoOfDay = now.epochDayTime.inNanoseconds + DateTimeZone.local.getUtcOffset(now).inNanoseconds;
    if (nanoOfDay >= TimeConstants.nanosecondsPerDay) nanoOfDay -= TimeConstants.nanosecondsPerDay;
    else if (nanoOfDay < 0) nanoOfDay += TimeConstants.nanosecondsPerDay;

    return LocalTime._(nanoOfDay);
  }

  /// Gets the hour of day of this offset time, in the range 0 to 23 inclusive.
  int get hourOfDay => timeSinceMidnight.hourOfDay;

  /// Gets the hour of the half-day of this offset time, in the range 1 to 12 inclusive.
  int get hourOf12HourClock => timeSinceMidnight.hourOf12HourClock;

  /// Gets the minute of this offset time, in the range 0 to 59 inclusive.
  int get minuteOfHour => timeSinceMidnight.minuteOfHour;

  /// Gets the second of this offset time within the minute, in the range 0 to 59 inclusive.
  int get secondOfMinute => timeSinceMidnight.secondOfMinute;

  /// Gets the millisecond of this offset time within the second, in the range 0 to 999 inclusive.
  int get millisecondOfSecond => timeSinceMidnight.millisecondOfSecond;

  /// Gets the microsecond of this local time within the second, in the range 0 to 999,999 inclusive.
  int get microsecondOfSecond => timeSinceMidnight.microsecondOfSecond;

  /// Gets the nanosecond of this offset time within the second, in the range 0 to 999,999,999 inclusive.
  int get nanosecondOfSecond => timeSinceMidnight.nanosecondOfSecond;

  /// Adds the specified period to the time. Friendly alternative to `operator+()`.
  ///
  /// * [time]: The time to add the period to
  /// * [period]: The period to add. Must not contain any (non-zero) date units.
  ///
  /// Returns: The sum of the given time and period
  static LocalTime plus(LocalTime time, Period period) => time + period;

  /// Subtracts the specified period from the time. Friendly alternative to `operator-()`.
  ///
  /// * [time]: The time to subtract the period from
  /// * [period]: The period to subtract. Must not contain any (non-zero) date units.
  ///
  /// Returns: The result of subtracting the given period from the time.
  static LocalTime minus(LocalTime time, Period period) => time.subtract(period);

  /// Subtracts the specified time from this time, returning the result as a [Period].
  /// Fluent alternative to `operator-()`.
  ///
  /// * [time]: The time to subtract from this
  ///
  /// Returns: The difference between the specified time and this one
  static Period difference(LocalTime end, LocalTime start) => Period.differenceBetweenTimes(start, end);

  /// Creates a new local time by adding a period to an existing time. The period must not contain
  /// any date-related units (days etc) with non-zero values.
  ///
  /// * [time]: The time to add the period to
  /// * [period]: The period to add
  ///
  /// Returns: The result of adding the period to the time, wrapping via midnight if necessary
  LocalTime operator +(Period period) {
    Preconditions.checkNotNull(period, 'period');
    Preconditions.checkArgument(!period.hasDateComponent, 'period', "Cannot add a period with a date component to a time");
    return IPeriod.addTimeTo(period, this, 1);
  }

  /// Creates a new local time by subtracting a period from an existing time. The period must not contain
  /// any date-related units (days etc) with non-zero values.
  /// This is a convenience operator over the [Minus(Period)] method.
  ///
  /// * [this]: The [LocalTime] to subtract the period from
  /// * [period]: The [Period] to subtract
  ///
  /// Returns: The result of subtract the period from the time, wrapping via midnight if necessary
  LocalTime operator -(Period period) => subtract(period);
  // dynamic operator -(dynamic rhs) => rhs is Period ? minusPeriod(rhs) : rhs is LocalTime ? between(rhs) : throw new ArgumentError();

  /// Adds the specified period to this time. Fluent alternative to `operator+()`.
  ///
  /// * [period]: The period to add. Must not contain any (non-zero) date units.
  ///
  /// Returns: The sum of this time and the given period
  LocalTime add(Period period) => this + period;

  /// Subtracts the specified period from this time. Fluent alternative to `operator-()`.
  ///
  /// * [period]: The period to subtract. Must not contain any (non-zero) date units.
  ///
  /// Returns: The result of subtracting the given period from this time.
  LocalTime subtract(Period period) {
    Preconditions.checkNotNull(period, 'period');
    Preconditions.checkArgument(!period.hasDateComponent, 'period', "Cannot subtract a period with a date component from a time");
    return IPeriod.addTimeTo(period, this, -1);
  }

  /// Subtracts the specified time from this time, returning the result as a [Period].
  /// Cognitively similar to: `this - time`.
  ///
  /// The specified time must be in the same calendar system as this.
  ///
  /// * [time]: The time to subtract from this
  ///
  /// Returns: The difference between the specified time and this one
  Period periodSince(LocalTime time) => Period.differenceBetweenTimes(time, this);

  /// Subtracts the specified time from this time, returning the result as a [Period].
  /// Cognitively similar to: `time - this`.
  ///
  /// The specified time must be in the same calendar system as this.
  ///
  /// * [time]: The time to subtract this from
  ///
  /// Returns: The difference between the specified time and this one
  Period periodUntil(LocalTime time) => Period.differenceBetweenTimes(this, time);

  /// Compares two local times for equality, by checking whether they represent
  /// the exact same local time, down to the tick.
  ///
  /// * [this]: The first value to compare
  /// * [other]: The second value to compare
  ///
  /// Returns: True if the two times are the same; false otherwise
  @override bool operator ==(Object other) => other is LocalTime && timeSinceMidnight.inNanoseconds == other.timeSinceMidnight.inNanoseconds;

  /// Compares two LocalTime values to see if the left one is strictly earlier than the right
  /// one.
  ///
  /// * [this]: First operand of the comparison
  /// * [other]: Second operand of the comparison
  ///
  /// Returns: true if the [this] is strictly earlier than [other], false otherwise.
  bool operator <(LocalTime other) => timeSinceMidnight.inNanoseconds < other.timeSinceMidnight.inNanoseconds;

  /// Compares two LocalTime values to see if the left one is earlier than or equal to the right
  /// one.
  ///
  /// * [this]: First operand of the comparison
  /// * [other]: Second operand of the comparison
  ///
  /// Returns: true if the [this] is earlier than or equal to [other], false otherwise.
  bool operator <=(LocalTime other) => timeSinceMidnight.inNanoseconds <= other.timeSinceMidnight.inNanoseconds;

  /// Compares two LocalTime values to see if the left one is strictly later than the right
  /// one.
  ///
  /// * [this]: First operand of the comparison
  /// * [other]: Second operand of the comparison
  ///
  /// Returns: true if the [this] is strictly later than [other], false otherwise.
  bool operator >(LocalTime other) => timeSinceMidnight.inNanoseconds > other.timeSinceMidnight.inNanoseconds;

  /// Compares two LocalTime values to see if the left one is later than or equal to the right
  /// one.
  ///
  /// * [this]: First operand of the comparison
  /// * [other]: Second operand of the comparison
  ///
  /// Returns: true if the [this] is later than or equal to [other], false otherwise.
  bool operator >=(LocalTime other) => timeSinceMidnight.inNanoseconds >= other.timeSinceMidnight.inNanoseconds;

  /// Indicates whether this time is earlier, later or the same as another one.
  ///
  /// * [other]: The other date/time to compare this one with
  ///
  /// A value less than zero if this time is earlier than [other];
  /// zero if this time is the same as [other]; a value greater than zero if this time is
  /// later than [other].
  @override
  int compareTo(LocalTime? other) => timeSinceMidnight.inNanoseconds.compareTo(other?.timeSinceMidnight.inNanoseconds ?? 0);

  /// Returns a hash code for this local time.
  @override int get hashCode => timeSinceMidnight.inNanoseconds.hashCode;

  /// Compares this local time with the specified one for equality,
  /// by checking whether the two values represent the exact same local time, down to the tick.
  ///
  /// * [other]: The other local time to compare this one with
  ///
  /// Returns: True if the specified time is equal to this one; false otherwise
  bool equals(LocalTime other) => this == other;

  /// Returns a new LocalTime representing the current value with the given number of hours added.
  ///
  /// If the value goes past the start or end of the day, it wraps - so 11pm plus two hours is 1am, for example.
  ///
  /// * [hours]: The number of hours to add
  ///
  /// Returns: The current value plus the given number of hours.
  LocalTime addHours(int hours) => TimePeriodField.hours.addTime(this, hours);
  LocalTime subtractHours(int hours) => addHours(-hours);

  /// Returns a new LocalTime representing the current value with the given number of minutes added.
  ///
  /// If the value goes past the start or end of the day, it wraps - so 11pm plus 120 minutes is 1am, for example.
  ///
  /// * [minutes]: The number of minutes to add
  ///
  /// Returns: The current value plus the given number of minutes.
  LocalTime addMinutes(int minutes) => TimePeriodField.minutes.addTime(this, minutes);
  LocalTime subtractMinutes(int minutes) => addMinutes(-minutes);

  /// Returns a new LocalTime representing the current value with the given number of seconds added.
  ///
  /// If the value goes past the start or end of the day, it wraps - so 11:59pm plus 120 seconds is 12:01am, for example.
  ///
  /// * [seconds]: The number of seconds to add
  ///
  /// Returns: The current value plus the given number of seconds.
  LocalTime addSeconds(int seconds) => TimePeriodField.seconds.addTime(this, seconds);
  LocalTime subtractSeconds(int seconds) => addSeconds(-seconds);

  /// Returns a new LocalTime representing the current value with the given number of milliseconds added.
  ///
  /// * [milliseconds]: The number of milliseconds to add
  ///
  /// Returns: The current value plus the given number of milliseconds.
  LocalTime addMilliseconds(int milliseconds) => TimePeriodField.milliseconds.addTime(this, milliseconds);
  LocalTime subtractMilliseconds(int milliseconds) => addMilliseconds(-milliseconds);

  /// Returns a new LocalTime representing the current value with the given number of microseconds added.
  ///
  /// * [microseconds]: The number of microseconds to add
  ///
  /// Returns: The current value plus the given number of microseconds.
  LocalTime addMicroseconds(int microseconds) => TimePeriodField.microseconds.addTime(this, microseconds);
  LocalTime subtractMicroseconds(int microseconds) => addMicroseconds(-microseconds);

  /// Returns a new LocalTime representing the current value with the given number of nanoseconds added.
  ///
  /// * [nanoseconds]: The number of nanoseconds to add
  ///
  /// Returns: The current value plus the given number of ticks.
  LocalTime addNanoseconds(int nanoseconds) => TimePeriodField.nanoseconds.addTime(this, nanoseconds);
  LocalTime subtractNanoseconds(int nanoseconds) => addNanoseconds(-nanoseconds);

  /// Returns this time, with the given adjuster applied to it.
  ///
  /// If the adjuster attempts to construct an invalid time, any exception thrown by
  /// that construction attempt will be propagated through this method.
  ///
  /// * [adjuster]: The adjuster to apply.
  ///
  /// Returns: The adjusted time.
  LocalTime adjust(LocalTime Function(LocalTime) adjuster) =>
      Preconditions.checkNotNull(adjuster, 'adjuster')(this);

  /// Returns an [OffsetTime] for this time-of-day with the given offset.
  ///
  /// This method is purely a convenient alternative to calling the [OffsetTime] constructor directly.
  ///
  /// * [offset]: The offset to apply.
  ///
  /// Returns: The result of this time-of-day offset by the given amount.
  OffsetTime withOffset(Offset offset) => OffsetTime(this, offset);

  /// Combines this [LocalTime] with the given [LocalDate]
  /// into a single [LocalDateTime].
  /// Fluent alternative to `operator+()`.
  ///
  /// * [date]: The date to combine with this time
  ///
  /// Returns: The [LocalDateTime] representation of the given time on this date
  LocalDateTime atDate(LocalDate date) => LocalDateTime.localDateAtTime(date, this);

  /// Returns the later time of the given two.
  ///
  /// * [x]: The first time to compare.
  /// * [y]: The second time to compare.
  ///
  /// Returns: The later instant of [x] or [y].
  static LocalTime max(LocalTime x, LocalTime y) {
    return x > y ? x : y;
  }

  /// Returns the earlier time of the given two.
  ///
  /// * [x]: The first time to compare.
  /// * [y]: The second time to compare.
  ///
  /// Returns: The earlier time of [x] or [y].
  static LocalTime min(LocalTime x, LocalTime y) => x < y ? x : y;

  /// Formats the value of the current instance using the specified pattern.
  ///
  /// A [String] containing the value of the current instance in the specified format.
  ///
  /// * [patternText]: The [String] specifying the pattern to use,
  /// or null to use the default format pattern ('T').
  /// * [culture]: The [Culture] to use when formatting the value,
  /// or null to use the current isolate's culture.
  @override String toString([String? patternText, Culture? culture]) =>
      LocalTimePatterns.format(this, patternText, culture);
}
