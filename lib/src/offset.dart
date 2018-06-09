// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_utilities.dart';


/// An offset from UTC in seconds. A positive value means that the local time is
/// ahead of UTC (e.g. for Europe); a negative value means that the local time is behind
/// UTC (e.g. for America).
///
/// Offsets are always in the range of [-18, +18] hours. (Note that the ends are inclusive,
/// so an offset of 18 hours can be represented, but an offset of 18 hours and one second cannot.)
/// This allows all offsets within TZDB to be represented. The BCL [DateTimeOffset] type
/// only allows offsets up to 14 hours, which means some historical data within TZDB could not be
/// represented.
///
/// Offsets are represented with a granularity of one second. This allows all offsets within TZDB
/// to be represented. It is possible that it could present issues to some other time zone data sources,
/// but only in very rare historical cases (or fictional ones).
///
/// <threadsafety>This type is an immutable value type. See the thread safety section of the user guide for more information.</threadsafety>
class Offset implements Comparable<Offset> // : IEquatable<Offset>, IComparable<Offset>, IFormattable, IComparable, IXmlSerializable
    {

  /// An offset of zero seconds - effectively the permanent offset for UTC.
  static final Offset zero = new Offset.fromSeconds(0);


  /// The minimum permitted offset; 18 hours before UTC.
  static final Offset minValue = new Offset.fromHours(-18);

  /// The maximum permitted offset; 18 hours after UTC.
  static final Offset maxValue = new Offset.fromHours(18);

  static const int _minHours = -18;
  static const int _maxHours = 18;
  @internal static const int minSeconds = -18 * TimeConstants.secondsPerHour;
  @internal static const int maxSeconds = 18 * TimeConstants.secondsPerHour;
  static const int _minMilliseconds = -18 * TimeConstants.millisecondsPerHour;
  static const int _maxMilliseconds = 18 * TimeConstants.millisecondsPerHour;
  static const int _minTicks = -18 * TimeConstants.ticksPerHour;
  static const int _maxTicks = 18 * TimeConstants.ticksPerHour;
  static const int _minNanoseconds = -18 * TimeConstants.nanosecondsPerHour;
  static const int _maxNanoseconds = 18 * TimeConstants.nanosecondsPerHour;

  final int _seconds;

// todo: I have a lot of static constructors to convert to factory methods in here

  /// Initializes a new instance of the [Offset] struct.
  ///
  /// [seconds]: The number of seconds in the offset.
  @internal Offset([this._seconds = 0]) {
    Preconditions.debugCheckArgumentRange('seconds', _seconds, minSeconds, maxSeconds);
  }

// Offset.fromHours(int hours) : this(hours * TimeConstants.secondsPerHour);

  // todo: constant?
  Span toSpan() => new Span(seconds: _seconds);

  /// Gets the number of seconds represented by this offset, which may be negative.
  int get seconds => _seconds;


  /// Gets the number of milliseconds represented by this offset, which may be negative.
  ///
  /// Offsets are only accurate to second precision; the number of seconds is simply multiplied
  /// by 1,000 to give the number of milliseconds.
  int get milliseconds => (_seconds * TimeConstants.millisecondsPerSecond);


  /// Gets the number of ticks represented by this offset, which may be negative.
  ///
  /// Offsets are only accurate to second precision; the number of seconds is simply multiplied
  /// by 10,000,000 to give the number of ticks.
  int get ticks => (_seconds * TimeConstants.ticksPerSecond);


  /// Gets the number of nanoseconds represented by this offset, which may be negative.
  ///
  /// Offsets are only accurate to second precision; the number of seconds is simply multiplied
  /// by 1,000,000,000 to give the number of nanoseconds.
  int get nanoseconds => (_seconds * TimeConstants.nanosecondsPerSecond);


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
  new Offset(-seconds);

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
  Offset operator +(Offset right) => new Offset.fromSeconds(seconds + right.seconds);


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
      new Offset.fromSeconds(seconds - subtrahend.seconds);


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
  bool operator ==(dynamic right) => right is Offset && Equals(right);


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
  ///   <list type = "table">
  ///     <listheader>
  ///       <term>Value</term>
  ///       <description>Meaning</description>
  ///     </listheader>
  ///     <item>
  ///       <term>&lt; 0</term>
  ///       <description>This object is less than the <paramref name = "other" /> parameter.</description>
  ///     </item>
  ///     <item>
  ///       <term>0</term>
  ///       <description>This object is equal to <paramref name = "other" />.</description>
  ///     </item>
  ///     <item>
  ///       <term>&gt; 0</term>
  ///       <description>This object is greater than <paramref name = "other" />.</description>
  ///     </item>
  ///   </list>
  int compareTo(Offset other) => other == null ? 1 : seconds.compareTo(other.seconds);

  ///   Indicates whether the current object is equal to another object of the same type.
  ///
  /// [other]: An object to compare with this object.
  ///
  ///   true if the current object is equal to the <paramref name = "other" /> parameter;
  ///   otherwise, false.
  bool Equals(Offset other) => seconds == other.seconds;

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
  @override String toString([String patternText = null, /*IFormatProvider*/ dynamic formatProvider = null]) =>
      OffsetPattern.BclSupport.Format(this, patternText, formatProvider ?? CultureInfo.currentCulture);

/// Formats the value of the current instance using the specified pattern.
///
/// A [String] containing the value of the current instance in the specified format.
///
/// [patternText]: The [String] specifying the pattern to use,
/// or null to use the default format pattern ("g").
///
/// [formatProvider]: The [IIFormatProvider] to use when formatting the value,
/// or null to use the current thread's culture to obtain a format provider.
///
/// <filterpriority>2</filterpriority>
//  String toString_Formatted(String patternText, IFormatProvider formatProvider) =>
//      OffsetPattern.BclSupport.Format(this, patternText, formatProvider);

  /// Returns an offset for the given seconds value, which may be negative.
  ///
  /// [seconds]: The int seconds value.
  /// Returns: An offset representing the given number of seconds.
  /// [ArgumentOutOfRangeException]: The specified number of seconds is outside the range of
  /// [-18, +18] hours.
  factory Offset.fromSeconds(int seconds) {
    Preconditions.checkArgumentRange('seconds', seconds, minSeconds, maxSeconds);
    return new Offset(seconds);
  }


  /// Returns an offset for the given milliseconds value, which may be negative.
  ///
  /// Offsets are only accurate to second precision; the given number of milliseconds is simply divided
  /// by 1,000 to give the number of seconds - any remainder is truncated.
  ///
  /// [milliseconds]: The int milliseconds value.
  /// Returns: An offset representing the given number of milliseconds, to the (truncated) second.
  /// [ArgumentOutOfRangeException]: The specified number of milliseconds is outside the range of
  /// [-18, +18] hours.
  factory Offset.fromMilliseconds(int milliseconds) {
    Preconditions.checkArgumentRange('milliseconds', milliseconds, _minMilliseconds, _maxMilliseconds);
    return new Offset(milliseconds ~/ TimeConstants.millisecondsPerSecond);
  }


  /// Returns an offset for the given number of ticks, which may be negative.
  ///
  /// Offsets are only accurate to second precision; the given number of ticks is simply divided
  /// by 10,000,000 to give the number of seconds - any remainder is truncated.
  ///
  /// [ticks]: The number of ticks specifying the length of the new offset.
  /// Returns: An offset representing the given number of ticks, to the (truncated) second.
  /// [ArgumentOutOfRangeException]: The specified number of ticks is outside the range of
  /// [-18, +18] hours.
  factory Offset.fromTicks(int ticks) {
    Preconditions.checkArgumentRange('ticks', ticks, _minTicks, _maxTicks);
    return new Offset((ticks ~/ TimeConstants.ticksPerSecond));
  }


  /// Returns an offset for the given number of nanoseconds, which may be negative.
  ///
  /// Offsets are only accurate to second precision; the given number of nanoseconds is simply divided
  /// by 1,000,000,000 to give the number of seconds - any remainder is truncated towards zero.
  ///
  /// [nanoseconds]: The number of nanoseconds specifying the length of the new offset.
  /// Returns: An offset representing the given number of nanoseconds, to the (truncated) second.
  /// [ArgumentOutOfRangeException]: The specified number of nanoseconds is outside the range of
  /// [-18, +18] hours.
  factory Offset.fromNanoseconds(int nanoseconds) {
    Preconditions.checkArgumentRange('nanoseconds', nanoseconds, _minNanoseconds, _maxNanoseconds);
    return new Offset((nanoseconds ~/ TimeConstants.nanosecondsPerSecond));
  }


  /// Returns an offset for the specified number of hours, which may be negative.
  ///
  /// [hours]: The number of hours to represent in the new offset.
  /// Returns: An offset representing the given value.
  /// [ArgumentOutOfRangeException]: The specified number of hours is outside the range of
  /// [-18, +18].
  factory Offset.fromHours(int hours) {
    Preconditions.checkArgumentRange('hours', hours, _minHours, _maxHours);
    return new Offset(hours * TimeConstants.secondsPerHour);
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
      new Offset.fromSeconds(hours * TimeConstants.secondsPerHour + minutes * TimeConstants.secondsPerMinute);


/// Converts this offset to a .NET standard [TimeSpan] value.
///
/// Returns: An equivalent [TimeSpan] to this value.

  Duration toDuration() => new Duration(seconds: _seconds);


  /// Converts the given [TimeSpan] to an offset, with fractional seconds truncated.
  ///
  /// [timeSpan]: The timespan to convert
  /// [ArgumentOutOfRangeException]: The given time span falls outside the range of +/- 18 hours.
  /// Returns: An offset for the same time as the given time span.
  factory Offset.fromDuration(Duration timeSpan) {
    int seconds = timeSpan.inMilliseconds;
    Preconditions.checkArgumentRange('timeSpan', seconds, _minMilliseconds, _maxMilliseconds);
    return new Offset.fromSeconds(seconds);
  }

  factory Offset.fromSpan(Span timeSpan) {
    int ticks = timeSpan.floorTicks;
    Preconditions.checkArgumentRange('timeSpan', ticks, _minTicks, _maxTicks);
    return new Offset.fromSeconds(ticks);
  }

}
