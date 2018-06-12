// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_utilities.dart';

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

  /// Initializes a new instance of the [Interval] struct.
  /// The interval includes the [start] instant and excludes the
  /// [end] instant. The end may equal the start (resulting in an empty interval), but must not be before the start.
  ///
  /// [ArgumentOutOfRangeException]: [end] is earlier than [start].
  /// [start]: The start [Instant].
  /// [end]: The end [Instant].
  Interval(this._start, this._end) {
    if (_end < _start) {
      throw new ArgumentError("The end parameter must be equal to or later than the start parameter");
    }
  }

  /// Gets the start instant - the inclusive lower bound of the interval.
  ///
  /// This will never be later than [end], though it may be equal to it.
  ///
  /// [InvalidOperationException]: The interval extends to the start of time.
  /// <seealso cref="HasStart"/>
  Instant get start {
    // todo: IsValid .. replace with a null check???
    Preconditions.checkState(_start.IsValid, "Interval extends to start of time");
    return _start;
  }

  /// Returns `true` if this interval has a fixed start point, or `false` if it
  /// extends to the start of time.
  ///
  /// <value>`true` if this interval has a fixed start point, or `false` if it
  /// extends to the start of time.</value>
  bool get hasStart => _start.IsValid;

  /// Gets the end instant - the exclusive upper bound of the interval.
  ///
  /// [InvalidOperationException]: The interval extends to the end of time.
  /// <seealso cref="HasEnd"/>
  Instant get end {
    Preconditions.checkState(_end.IsValid, "Interval extends to end of time");
    return _end;
  }

  /// Returns the raw end value of the interval: a normal instant or [Instant.afterMaxValue].
  /// This value should never be exposed.
  @internal Instant get rawEnd => _end;

  /// Returns `true` if this interval has a fixed end point, or `false` if it
  /// extends to the end of time.
  ///
  /// <value>`true` if this interval has a fixed end point, or `false` if it
  /// extends to the end of time.</value>
  bool get hasEnd => _end.IsValid;

  /// Returns the duration of the interval.
  ///
  /// This will always be a non-negative duration, though it may be zero.
  ///
  /// [InvalidOperationException]: The interval extends to the start or end of time.
  Span get span => end - start;

  /// Returns whether or not this interval contains the given instant.
  ///
  /// [instant]: Instant to test.
  /// Returns: True if this interval contains the given instant; false otherwise.
  bool contains(Instant instant) => instant >= _start && instant < _end;

  /// Indicates whether the value of this interval is equal to the value of the specified interval.
  ///
  /// [other]: The value to compare with this instance.
  ///
  /// true if the value of this instant is equal to the value of the <paramref name="other" /> parameter;
  /// otherwise, false.
  bool equals(Interval other) => _start == other._start && _end == other._end;

  /// Returns the hash code for this instance.
  ///
  /// A 32-bit signed integer that is the hash code for this instance.
  ///
  /// <filterpriority>2</filterpriority>
  @override int get hashCode => hash2(_start, _end);

  /// Returns a string representation of this interval, in extended ISO-8601 format: the format
  /// is "start/end" where each instant uses a format of "uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFF'Z'".
  /// If the start or end is infinite, the relevant part uses "StartOfTime" or "EndOfTime" to
  /// represent this.
  ///
  /// Returns: A string representation of this interval.
  @override String toString() // => TextShim.toStringInterval(this);
  {
    var pattern = InstantPattern.ExtendedIso;
    return pattern.Format(_start) + "/" + pattern.Format(_end);
  }

  /// Implements the operator ==.
  ///
  /// [left]: The left.
  /// [right]: The right.
  /// Returns: The result of the operator.
  bool operator ==(dynamic right) => right is Interval && equals(right);
}
