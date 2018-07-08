// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';


/// An offset from UTC in seconds. A positive value means that the local time is
/// ahead of UTC (e.g. for Europe); a negative value means that the local time is behind
/// UTC (e.g. for America).
///
/// Offsets are always in the range of [-18, +18] hours. (Note that the ends are inclusive,
/// so an offset of 18 hours can be represented, but an offset of 18 hours and one second cannot.)
/// This allows all offsets within TZDB to be represented.
///
/// Offsets are represented with a granularity of one second. This allows all offsets within TZDB
/// to be represented. It is possible that it could present issues to some other time zone data sources,
/// but only in very rare historical cases (or fictional ones).
@immutable 
class Offset implements Comparable<Offset> {

  /// An offset of zero seconds - effectively the permanent offset for UTC.
  static final Offset zero = new Offset(0);

  /// The minimum permitted offset; 18 hours before UTC.
  static final Offset minValue = new Offset.fromHours(-18);

  /// The maximum permitted offset; 18 hours after UTC.
  static final Offset maxValue = new Offset.fromHours(18);

  static const int _minHours = -18;
  static const int _maxHours = 18;
  static const int _minSeconds = -18 * TimeConstants.secondsPerHour;
  static const int _maxSeconds = 18 * TimeConstants.secondsPerHour;

  /// Gets the number of seconds represented by this offset, which may be negative.
  final int seconds;

  /// Initializes a new instance of the [Offset] struct.
  ///
  /// [seconds]: The number of seconds in the offset.
  Offset._([this.seconds = 0]) {
    assert(Preconditions.debugCheckArgumentRange('seconds', seconds, _minSeconds, _maxSeconds));
  }

  /// Gets the number of milliseconds represented by this offset, which may be negative.
  ///
  /// Offsets are only accurate to second precision; the number of seconds is simply multiplied
  /// by 1,000 to give the number of milliseconds.
  int get milliseconds => (seconds * TimeConstants.millisecondsPerSecond);


  /// Gets the number of microseconds represented by this offset, which may be negative.
  ///
  /// Offsets are only accurate to second precision; the number of seconds is simply multiplied
  /// by 1,000,000 to give the number of microseconds.
  int get microseconds => (seconds * TimeConstants.microsecondsPerSecond);


  /// Gets the number of nanoseconds represented by this offset, which may be negative.
  ///
  /// Offsets are only accurate to second precision; the number of seconds is simply multiplied
  /// by 1,000,000,000 to give the number of nanoseconds.
  int get nanoseconds => (seconds * TimeConstants.nanosecondsPerSecond);


  /// Returns the greater offset of the given two, i.e. the one which will give a later local
  /// time when added to an instant.
  ///
  /// [x]: The first offset
  /// [y]: The second offset
  /// Returns: The greater offset of [x] and [y].
  static Offset max(Offset x, Offset y) => x > y ? x : y;


  /// Returns the lower offset of the given two, i.e. the one which will give an earlier local
  /// time when added to an instant.
  ///
  /// [x]: The first offset
  /// [y]: The second offset
  /// Returns: The lower offset of [x] and [y].
  static Offset min(Offset x, Offset y) => x < y ? x : y;

  ///   Implements the unary operator - (negation).
  ///
  /// [offset]: The offset to negate.
  /// Returns: A new [Offset] instance with a negated value.
  Offset operator -() =>
  // Guaranteed to still be in range.
  new Offset._(-seconds);

  /// Returns the negation of the specified offset. This is the method form of the unary minus operator.
  ///
  /// [offset]: The offset to negate.
  /// Returns: The negation of the specified offset.
  static Offset negate(Offset offset) => -offset;

  /// Implements the operator + (addition).
  ///
  /// [left]: The left hand side of the operator.
  /// [right]: The right hand side of the operator.
  /// [ArgumentOutOfRangeException]: The result of the operation is outside the range of Offset.
  /// Returns: A new [Offset] representing the sum of the given values.
  /// [ArgumentOutOfRangeException]: The result of the operation is outside the range of Offset.
  Offset operator +(Offset right) => new Offset(seconds + right.seconds);


  /// Adds one Offset to another. Friendly alternative to `operator+()`.
  ///
  /// [left]: The left hand side of the operator.
  /// [right]: The right hand side of the operator.
  /// [ArgumentOutOfRangeException]: The result of the operation is outside the range of Offset.
  /// Returns: A new [Offset] representing the sum of the given values.
  /// [ArgumentOutOfRangeException]: The result of the operation is outside the range of Offset.
  static Offset add(Offset left, Offset right) => left + right;


  /// Returns the result of adding another Offset to this one, for a fluent alternative to `operator+()`.
  ///
  /// [other]: The offset to add
  /// [ArgumentOutOfRangeException]: The result of the operation is outside the range of Offset.
  /// Returns: The result of adding the other offset to this one.
  Offset plus(Offset other) => this + other;


  /// Implements the operator - (subtraction).
  ///
  /// [minuend]: The left hand side of the operator.
  /// [subtrahend]: The right hand side of the operator.
  /// [ArgumentOutOfRangeException]: The result of the operation is outside the range of Offset.
  /// Returns: A new [Offset] representing the difference of the given values.
  /// [ArgumentOutOfRangeException]: The result of the operation is outside the range of Offset.
  Offset operator -(Offset subtrahend) =>
      new Offset(seconds - subtrahend.seconds);


  /// Subtracts one Offset from another. Friendly alternative to `operator-()`.
  ///
  /// [minuend]: The left hand side of the operator.
  /// [subtrahend]: The right hand side of the operator.
  /// [ArgumentOutOfRangeException]: The result of the operation is outside the range of Offset.
  /// Returns: A new [Offset] representing the difference of the given values.
  /// [ArgumentOutOfRangeException]: The result of the operation is outside the range of Offset.
  static Offset subtract(Offset minuend, Offset subtrahend) => minuend - subtrahend;


  /// Returns the result of subtracting another Offset from this one, for a fluent alternative to `operator-()`.
  ///
  /// [other]: The offset to subtract
  /// [ArgumentOutOfRangeException]: The result of the operation is outside the range of Offset.
  /// Returns: The result of subtracting the other offset from this one.
  Offset minus(Offset other) => this - other;


  /// Implements the operator == (equality).
  ///
  /// [left]: The left hand side of the operator.
  /// [right]: The right hand side of the operator.
  /// Returns: `true` if values are equal to each other, otherwise `false`.
  bool operator ==(dynamic right) => right is Offset && equals(right);


  /// Implements the operator &lt; (less than).
  ///
  /// [left]: The left hand side of the operator.
  /// [right]: The right hand side of the operator.
  /// Returns: `true` if the left value is less than the right value, otherwise `false`.
  bool operator <(Offset right) => compareTo(right) < 0;


  /// Implements the operator &lt;= (less than or equal).
  ///
  /// [left]: The left hand side of the operator.
  /// [right]: The right hand side of the operator.
  /// Returns: `true` if the left value is less than or equal to the right value, otherwise `false`.
  bool operator <=(Offset right) => compareTo(right) <= 0;


  /// Implements the operator &gt; (greater than).
  ///
  /// [left]: The left hand side of the operator.
  /// [right]: The right hand side of the operator.
  /// Returns: `true` if the left value is greater than the right value, otherwise `false`.
  bool operator >(Offset right) => compareTo(right) > 0;


  ///   Implements the operator &gt;= (greater than or equal).
  ///
  /// [left]: The left hand side of the operator.
  /// [right]: The right hand side of the operator.
  /// Returns: `true` if the left value is greater than or equal to the right value, otherwise `false`.
  bool operator >=(Offset right) => compareTo(right) >= 0;

// Operators

  /// Compares the current object with another object of the same type.
  ///
  /// [other]: An object to compare with this object.
  ///
  ///   A 32-bit signed integer that indicates the relative order of the objects being compared.
  ///   The return value has the following meanings:
  ///   | Value        | Meaning|
  ///   | ------------- |:-------------|
  ///   | < 0      | This object is less than the [other] parameter. |
  ///   | 0      | This object is equal to [other].      |
  ///   | > 0 | This object is greater than [other].      |
  int compareTo(Offset other) => other == null ? 1 : seconds.compareTo(other.seconds);

  ///   Indicates whether the current object is equal to another object of the same type.
  ///
  /// [other]: An object to compare with this object.
  ///
  ///   true if the current object is equal to the <paramref name = "other" /> parameter;
  ///   otherwise, false.
  bool equals(Offset other) => seconds == other.seconds;

  ///   Returns a hash code for this instance.
  ///
  ///   A hash code for this instance, suitable for use in hashing algorithms and data
  ///   structures like a hash table.
  @override int get hashCode => seconds.hashCode;

  /// Returns a [String] that represents this instance.
  ///
  /// The value of the current instance in the default format pattern ("g"), using the current thread's
  /// culture to obtain a format provider.
  // @override String toString() => TextShim.toStringOffset(this); // OffsetPattern.BclSupport.Format(this, null, CultureInfo.CurrentCulture);
  @override String toString([String patternText, Culture culture]) =>
      OffsetPatterns.format(this, patternText, culture);

  /// Returns an offset for the given seconds value, which may be negative.
  ///
  /// [seconds]: The int seconds value.
  /// Returns: An offset representing the given number of seconds.
  /// [ArgumentOutOfRangeException]: The specified number of seconds is outside the range of
  /// [-18, +18] hours.
  factory Offset([int seconds = 0]) {
    Preconditions.checkArgumentRange('seconds', seconds, _minSeconds, _maxSeconds);
    return new Offset._(seconds);
  }

  /// Returns an offset for the specified number of hours, which may be negative.
  ///
  /// [hours]: The number of hours to represent in the new offset.
  /// Returns: An offset representing the given value.
  /// [ArgumentOutOfRangeException]: The specified number of hours is outside the range of
  /// [-18, +18].
  factory Offset.fromHours(int hours) {
    Preconditions.checkArgumentRange('hours', hours, _minHours, _maxHours);
    return new Offset._(hours * TimeConstants.secondsPerHour);
  }

  /// Returns an offset for the specified number of hours and minutes.
  ///
  /// The result simply takes the hours and minutes and converts each component into milliseconds
  /// separately. As a result, a negative offset should usually be obtained by making both arguments
  /// negative. For example, to obtain "three hours and ten minutes behind UTC" you might call
  /// `Offset.FromHoursAndMinutes(-3, -10)`.
  ///
  /// [hours]: The number of hours to represent in the new offset.
  /// [minutes]: The number of minutes to represent in the new offset.
  /// Returns: An offset representing the given value.
  /// [ArgumentOutOfRangeException]: The result of the operation is outside the range of Offset.
  factory Offset.fromHoursAndMinutes(int hours, int minutes) =>
      new Offset(hours * TimeConstants.secondsPerHour + minutes * TimeConstants.secondsPerMinute);

  /// Converts this offset to a [Duration] value.
  Duration toDuration() => new Duration(seconds: seconds);

  /// Converts this offset to a [Time] value.
  Time toTime() => new Time(seconds: seconds);

  /// Converts the given [Duration] to an offset, with fractional seconds truncated.
  ///
  /// [timeSpan]: The [Duration] to convert
  /// [ArgumentOutOfRangeException]: The given time span falls outside the range of +/- 18 hours.
  /// Returns: An offset for the same time as the given time span.
  factory Offset.fromDuration(Duration duration) {
    int seconds = duration.inSeconds;
    Preconditions.checkArgumentRange('duration', seconds, _minSeconds, _maxSeconds);
    return new Offset(seconds);
  }

  /// Converts the given [Time] to an offset, with fractional seconds truncated.
  ///
  /// [timeSpan]: The [Time] to convert
  /// [ArgumentOutOfRangeException]: The given time span falls outside the range of +/- 18 hours.
  /// Returns: An offset for the same time as the given time span.
  factory Offset.fromTime(Time time) {
    int seconds = time.totalSeconds.floor();
    Preconditions.checkArgumentRange('time', seconds, _minSeconds, _maxSeconds);
    return new Offset(seconds);
  }
}
