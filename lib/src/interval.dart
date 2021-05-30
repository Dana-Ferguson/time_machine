// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
// import 'package:quiver_hashcode/hashcode.dart';
import 'package:time_machine/src/time_machine_internal.dart';

@internal
abstract class IInterval {
  static Instant rawEnd(Interval interval) => interval._rawEnd;
}

/// An interval between two instants in time (start and end).
///
/// The interval includes the start instant and excludes the end instant. However, an interval
/// may be missing its start or end, in which case the interval is deemed to be infinite in that
/// direction.
///
/// The end may equal the start (resulting in an empty interval), but will not be before the start.
@immutable
class Interval {
  /// The start of the interval.
  final Instant _start;

  /// The end of the interval. This will never be earlier than the start.
  final Instant _end;

  // todo: would this make sense? Interval.forever()? Interval.tillEndOfTime(Instant start)? Interval.startOfTimeTill(Instant end)? Interval.empty([Instant time])?
  // todo: Instant.timeSince needs better doc comment!
  /// Initializes a new instance of the [Interval] struct.
  /// The interval includes the [start] instant and excludes the
  /// [end] instant. The end may equal the start (resulting in an empty interval), but must not be before the start.
  ///
  /// * [start]: The start [Instant].
  /// * [end]: The end [Instant].
  ///
  /// * [ArgumentOutOfRangeException]: [end] is earlier than [start].
  Interval(Instant? start, Instant? end)
      : _start = start ?? IInstant.beforeMinValue,
        _end = end ?? IInstant.afterMaxValue {
    if (_end < _start) {
      throw RangeError('The end parameter must be equal to or later than the start parameter');
    }
  }

  /// Gets the start instant - the inclusive lower bound of the interval.
  ///
  /// This will never be later than [end], though it may be equal to it.
  ///
  /// * [StateError]: The interval extends to the start of time.
  Instant get start {
    Preconditions.checkState(_start.isValid, 'Interval extends to start of time');
    return _start;
  }

  /// Returns `true` if this interval has a fixed start point, or `false` if it
  /// extends to the start of time.
  bool get hasStart => _start.isValid;

  /// Gets the end instant - the exclusive upper bound of the interval.
  ///
  /// * [StateError]: The interval extends to the end of time.
  Instant get end {
    Preconditions.checkState(_end.isValid, 'Interval extends to end of time');
    return _end;
  }

  /// Returns the raw end value of the interval: a normal instant or [IInstant.afterMaxValue].
  /// This value should never be exposed.
  Instant get _rawEnd => _end;

  /// Returns `true` if this interval has a fixed end point, or `false` if it
  /// extends to the end of time.
  bool get hasEnd => _end.isValid;

  /// Returns the duration of the interval.
  ///
  /// This will always be a non-negative duration, though it may be zero.
  ///
  /// * [StateError]: The interval extends to the start or end of time.
  Time get totalTime => start.timeUntil(end);

  /// Returns whether or not this interval contains the given instant.
  ///
  /// * [instant]: Instant to test.
  ///
  /// Returns: True if this interval contains the given instant; false otherwise.
  bool contains(Instant instant) => instant >= _start && instant < _end;

  /// Indicates whether the value of this interval is equal to the value of the specified interval.
  ///
  /// * [other]: The value to compare with this instance.
  ///
  /// true if the value of this instant is equal to the value of the <paramref name='other' /> parameter;
  /// otherwise, false.
  bool equals(Interval other) => identical(this, other) || _start == other._start && _end == other._end;

  /// Returns true if this Interval overlaps the [other] Interval.
  ///
  /// * [other]: The value to check for overlap with this instance.
  ///
  /// These two intervals overlap
  /// ```
  ///  *     *
  ///    *      *
  /// ```
  ///
  /// These intervals do not overlap
  /// ```
  /// *   *
  ///     *   *
  ///         *   *
  ///                     *        *
  /// ```
  bool overlaps(Interval other) {
    if (other.start >= end) return false;
    if (other.end <= start) return false;
    return true;
  }

  /// Returns the hash code for this instance.
  @override int get hashCode => hash2(_start, _end);

  /// Returns a string representation of this interval, in extended ISO-8601 format: the format
  /// is 'start/end' where each instant uses a format of "uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFF'Z'".
  /// If the start or end is infinite, the relevant part uses 'StartOfTime' or "EndOfTime" to
  /// represent this.
  ///
  /// Returns: A string representation of this interval.
  @override String toString()
  {
    var pattern = InstantPattern.extendedIso;
    return pattern.format(_start) + '/' + pattern.format(_end);
  }

  /// Implements the operator ==.
  @override
  bool operator ==(Object other) => other is Interval && _start == other._start && _end == other._end;
}
