// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Interval.cs
// a696ed0  on Nov 11, 2017

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';

/// An interval between two instants in time (start and end).
/// </summary>
/// <remarks>
/// <para>
/// The interval includes the start instant and excludes the end instant. However, an interval
/// may be missing its start or end, in which case the interval is deemed to be infinite in that
/// direction.
/// </para>
/// <para>
/// The end may equal the start (resulting in an empty interval), but will not be before the start.
/// </para>
/// </remarks>
@immutable
class Interval // : IEquatable<Interval>
    {
  /// <summary>The start of the interval.</summary>
  final Instant _start;

  /// <summary>The end of the interval. This will never be earlier than the start.</summary>
  final Instant _end;

  /// <summary>
  /// Initializes a new instance of the <see cref="Interval"/> struct.
  /// The interval includes the <paramref name="start"/> instant and excludes the
  /// <paramref name="end"/> instant. The end may equal the start (resulting in an empty interval), but must not be before the start.
  /// </summary>
  /// <exception cref="ArgumentOutOfRangeException"><paramref name="end"/> is earlier than <paramref name="start"/>.</exception>
  /// <param name="start">The start <see cref="Instant"/>.</param>
  /// <param name="end">The end <see cref="Instant"/>.</param>
  Interval(this._start, this._end) {
    if (_end < _start) {
      throw new ArgumentError("The end parameter must be equal to or later than the start parameter");
    }
  }

  /// <summary>
  /// Gets the start instant - the inclusive lower bound of the interval.
  /// </summary>
  /// <remarks>
  /// This will never be later than <see cref="End"/>, though it may be equal to it.
  /// </remarks>
  /// <value>The start <see cref="Instant"/>.</value>
  /// <exception cref="InvalidOperationException">The interval extends to the start of time.</exception>
  /// <seealso cref="HasStart"/>
  Instant get Start {
    // todo: IsValid .. replace with a null check???
    Preconditions.checkState(_start.IsValid, "Interval extends to start of time");
    return _start;
  }

  /// <summary>
  /// Returns <c>true</c> if this interval has a fixed start point, or <c>false</c> if it
  /// extends to the start of time.
  /// </summary>
  /// <value><c>true</c> if this interval has a fixed start point, or <c>false</c> if it
  /// extends to the start of time.</value>
  bool get HasStart => _start.IsValid;

  /// <summary>
  /// Gets the end instant - the exclusive upper bound of the interval.
  /// </summary>
  /// <value>The end <see cref="Instant"/>.</value>
  /// <exception cref="InvalidOperationException">The interval extends to the end of time.</exception>
  /// <seealso cref="HasEnd"/>
  Instant get End {
    Preconditions.checkState(_end.IsValid, "Interval extends to end of time");
    return _end;
  }

  /// <summary>
  /// Returns the raw end value of the interval: a normal instant or <see cref="Instant.AfterMaxValue"/>.
  /// This value should never be exposed.
  /// </summary>
  @internal Instant get RawEnd => _end;

  /// <summary>
  /// Returns <c>true</c> if this interval has a fixed end point, or <c>false</c> if it
  /// extends to the end of time.
  /// </summary>
  /// <value><c>true</c> if this interval has a fixed end point, or <c>false</c> if it
  /// extends to the end of time.</value>
  bool get HasEnd => _end.IsValid;

  /// <summary>
  /// Returns the duration of the interval.
  /// </summary>
  /// <remarks>
  /// This will always be a non-negative duration, though it may be zero.
  /// </remarks>
  /// <value>The duration of the interval.</value>
  /// <exception cref="InvalidOperationException">The interval extends to the start or end of time.</exception>
  Span get span => End - Start;

  /// <summary>
  /// Returns whether or not this interval contains the given instant.
  /// </summary>
  /// <param name="instant">Instant to test.</param>
  /// <returns>True if this interval contains the given instant; false otherwise.</returns>

  bool contains(Instant instant) => instant >= _start && instant < _end;

  /// <summary>
  /// Indicates whether the value of this interval is equal to the value of the specified interval.
  /// </summary>
  /// <param name="other">The value to compare with this instance.</param>
  /// <returns>
  /// true if the value of this instant is equal to the value of the <paramref name="other" /> parameter;
  /// otherwise, false.
  /// </returns>
  bool equals(Interval other) => _start == other._start && _end == other._end;

  /// <summary>
  /// Returns the hash code for this instance.
  /// </summary>
  /// <returns>
  /// A 32-bit signed integer that is the hash code for this instance.
  /// </returns>
  /// <filterpriority>2</filterpriority>
  @override int get hashCode => hash2(_start, _end);

  /// <summary>
  /// Returns a string representation of this interval, in extended ISO-8601 format: the format
  /// is "start/end" where each instant uses a format of "uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFF'Z'".
  /// If the start or end is infinite, the relevant part uses "StartOfTime" or "EndOfTime" to
  /// represent this.
  /// </summary>
  /// <returns>A string representation of this interval.</returns>
  @override String ToString() {
    var pattern = InstantPattern.ExtendedIso;
    return pattern.Format(_start) + "/" + pattern.Format(_end);
  }

  /// <summary>
  /// Implements the operator ==.
  /// </summary>
  /// <param name="left">The left.</param>
  /// <param name="right">The right.</param>
  /// <returns>The result of the operator.</returns>
  bool operator ==(dynamic right) => right is Interval && equals(right);
}