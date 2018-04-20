// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Offset.cs
// 0913621  on Aug 26, 2017

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';


/// An offset from UTC in seconds. A positive value means that the local time is
/// ahead of UTC (e.g. for Europe); a negative value means that the local time is behind
/// UTC (e.g. for America).
/// 
/// <remarks>
/// <para>
/// Offsets are always in the range of [-18, +18] hours. (Note that the ends are inclusive,
/// so an offset of 18 hours can be represented, but an offset of 18 hours and one second cannot.)
/// This allows all offsets within TZDB to be represented. The BCL <see cref="DateTimeOffset"/> type
/// only allows offsets up to 14 hours, which means some historical data within TZDB could not be
/// represented.
/// </para>
/// <para>Offsets are represented with a granularity of one second. This allows all offsets within TZDB
/// to be represented. It is possible that it could present issues to some other time zone data sources,
/// but only in very rare historical cases (or fictional ones).</para>
/// </remarks>
/// <threadsafety>This type is an immutable value type. See the thread safety section of the user guide for more information.</threadsafety>
class Offset implements Comparable<Offset> // : IEquatable<Offset>, IComparable<Offset>, IFormattable, IComparable, IXmlSerializable
    {

  /// An offset of zero seconds - effectively the permanent offset for UTC.
  ///
  static final Offset zero = new Offset.fromSeconds(0);


  /// The minimum permitted offset; 18 hours before UTC.
  ///
  static final Offset minValue = new Offset.fromHours(-18);

  /// The maximum permitted offset; 18 hours after UTC.
  ///
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

  /// Initializes a new instance of the <see cref="Offset" /> struct.
  ///
  /// <param name="seconds">The number of seconds in the offset.</param>
  @internal Offset(this._seconds) {
    Preconditions.debugCheckArgumentRange('seconds', _seconds, minSeconds, maxSeconds);
  }

  // Offset.fromHours(int hours) : this(hours * TimeConstants.secondsPerHour);

  // todo: constant?
  Span toSpan() => new Span(seconds: _seconds);

  /// Gets the number of seconds represented by this offset, which may be negative.
  ///
  /// <value>The number of seconds represented by this offset, which may be negative.</value>
  int get seconds => _seconds;


  /// Gets the number of milliseconds represented by this offset, which may be negative.
  ///
  /// <remarks>
  /// Offsets are only accurate to second precision; the number of seconds is simply multiplied
  /// by 1,000 to give the number of milliseconds.
  /// </remarks>
  /// <value>The number of milliseconds represented by this offset, which may be negative.</value>
  int get milliseconds => (_seconds * TimeConstants.millisecondsPerSecond);


  /// Gets the number of ticks represented by this offset, which may be negative.
  ///
  /// <remarks>
  /// Offsets are only accurate to second precision; the number of seconds is simply multiplied
  /// by 10,000,000 to give the number of ticks.
  /// </remarks>
  /// <value>The number of ticks.</value>
  int get ticks => (_seconds * TimeConstants.ticksPerSecond);


  /// Gets the number of nanoseconds represented by this offset, which may be negative.
  ///
  /// <remarks>
  /// Offsets are only accurate to second precision; the number of seconds is simply multiplied
  /// by 1,000,000,000 to give the number of nanoseconds.
  /// </remarks>
  /// <value>The number of nanoseconds.</value>
  int get nanoseconds => (_seconds * TimeConstants.nanosecondsPerSecond);


  /// Returns the greater offset of the given two, i.e. the one which will give a later local
  /// time when added to an instant.
  ///
  /// <param name="x">The first offset</param>
  /// <param name="y">The second offset</param>
  /// <returns>The greater offset of <paramref name="x"/> and <paramref name="y"/>.</returns>
  static Offset max(Offset x, Offset y) => x > y ? x : y;


  /// Returns the lower offset of the given two, i.e. the one which will give an earlier local
  /// time when added to an instant.
  ///
  /// <param name="x">The first offset</param>
  /// <param name="y">The second offset</param>
  /// <returns>The lower offset of <paramref name="x"/> and <paramref name="y"/>.</returns>
  static Offset min(Offset x, Offset y) => x < y ? x : y;

  ///   Implements the unary operator - (negation).
  ///
  /// <param name="offset">The offset to negate.</param>
  /// <returns>A new <see cref="Offset" /> instance with a negated value.</returns>
  Offset operator -() =>
// Guaranteed to still be in range.
  new Offset(-seconds);


  /// Returns the negation of the specified offset. This is the method form of the unary minus operator.
  ///
  /// <param name="offset">The offset to negate.</param>
  /// <returns>The negation of the specified offset.</returns>
  static Offset negate(Offset offset) => -offset;

  /// Implements the operator + (addition).
  ///
  /// <param name="left">The left hand side of the operator.</param>
  /// <param name="right">The right hand side of the operator.</param>
  /// <exception cref="ArgumentOutOfRangeException">The result of the operation is outside the range of Offset.</exception>
  /// <returns>A new <see cref="Offset" /> representing the sum of the given values.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The result of the operation is outside the range of Offset.</exception>
  Offset operator +(Offset right) => new Offset.fromSeconds(seconds + right.seconds);


  /// Adds one Offset to another. Friendly alternative to <c>operator+()</c>.
  ///
  /// <param name="left">The left hand side of the operator.</param>
  /// <param name="right">The right hand side of the operator.</param>
  /// <exception cref="ArgumentOutOfRangeException">The result of the operation is outside the range of Offset.</exception>
  /// <returns>A new <see cref="Offset" /> representing the sum of the given values.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The result of the operation is outside the range of Offset.</exception>
  static Offset add(Offset left, Offset right) => left + right;


  /// Returns the result of adding another Offset to this one, for a fluent alternative to <c>operator+()</c>.
  ///
  /// <param name="other">The offset to add</param>
  /// <exception cref="ArgumentOutOfRangeException">The result of the operation is outside the range of Offset.</exception>
  /// <returns>The result of adding the other offset to this one.</returns>

  Offset plus(Offset other) => this + other;


  /// Implements the operator - (subtraction).
  ///
  /// <param name="minuend">The left hand side of the operator.</param>
  /// <param name="subtrahend">The right hand side of the operator.</param>
  /// <exception cref="ArgumentOutOfRangeException">The result of the operation is outside the range of Offset.</exception>
  /// <returns>A new <see cref="Offset" /> representing the difference of the given values.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The result of the operation is outside the range of Offset.</exception>
  Offset operator -(Offset subtrahend) =>
      new Offset.fromSeconds(seconds - subtrahend.seconds);


  /// Subtracts one Offset from another. Friendly alternative to <c>operator-()</c>.
  ///
  /// <param name="minuend">The left hand side of the operator.</param>
  /// <param name="subtrahend">The right hand side of the operator.</param>
  /// <exception cref="ArgumentOutOfRangeException">The result of the operation is outside the range of Offset.</exception>
  /// <returns>A new <see cref="Offset" /> representing the difference of the given values.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The result of the operation is outside the range of Offset.</exception>
  static Offset subtract(Offset minuend, Offset subtrahend) => minuend - subtrahend;


  /// Returns the result of subtracting another Offset from this one, for a fluent alternative to <c>operator-()</c>.
  ///
  /// <param name="other">The offset to subtract</param>
  /// <exception cref="ArgumentOutOfRangeException">The result of the operation is outside the range of Offset.</exception>
  /// <returns>The result of subtracting the other offset from this one.</returns>

  Offset minus(Offset other) => this - other;


  /// Implements the operator == (equality).
  ///
  /// <param name="left">The left hand side of the operator.</param>
  /// <param name="right">The right hand side of the operator.</param>
  /// <returns><c>true</c> if values are equal to each other, otherwise <c>false</c>.</returns>
  bool operator ==(dynamic right) => right is Offset && Equals(right);


  /// Implements the operator &lt; (less than).
  ///
  /// <param name="left">The left hand side of the operator.</param>
  /// <param name="right">The right hand side of the operator.</param>
  /// <returns><c>true</c> if the left value is less than the right value, otherwise <c>false</c>.</returns>
  bool operator <(Offset right) => compareTo(right) < 0;


  /// Implements the operator &lt;= (less than or equal).
  ///
  /// <param name="left">The left hand side of the operator.</param>
  /// <param name="right">The right hand side of the operator.</param>
  /// <returns><c>true</c> if the left value is less than or equal to the right value, otherwise <c>false</c>.</returns>
  bool operator <=(Offset right) => compareTo(right) <= 0;


  /// Implements the operator &gt; (greater than).
  ///
  /// <param name="left">The left hand side of the operator.</param>
  /// <param name="right">The right hand side of the operator.</param>
  /// <returns><c>true</c> if the left value is greater than the right value, otherwise <c>false</c>.</returns>
  bool operator >(Offset right) => compareTo(right) > 0;


  ///   Implements the operator &gt;= (greater than or equal).
  ///
  /// <param name="left">The left hand side of the operator.</param>
  /// <param name="right">The right hand side of the operator.</param>
  /// <returns><c>true</c> if the left value is greater than or equal to the right value, otherwise <c>false</c>.</returns>
  bool operator >=(Offset right) => compareTo(right) >= 0;

  // Operators

  /// Compares the current object with another object of the same type.
  ///
  /// <param name="other">An object to compare with this object.</param>
  /// <returns>
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
  /// </returns>
  int compareTo(Offset other) => seconds.compareTo(other.seconds);

  ///   Indicates whether the current object is equal to another object of the same type.
  ///
  /// <param name="other">An object to compare with this object.</param>
  /// <returns>
  ///   true if the current object is equal to the <paramref name = "other" /> parameter;
  ///   otherwise, false.
  /// </returns>
  bool Equals(Offset other) => seconds == other.seconds;

  ///   Returns a hash code for this instance.
  ///
  /// <returns>
  ///   A hash code for this instance, suitable for use in hashing algorithms and data
  ///   structures like a hash table.
  /// </returns>
  @override int get hashCode => seconds.hashCode;

  /// Returns a <see cref="System.String" /> that represents this instance.
  ///
  /// <returns>
  /// The value of the current instance in the default format pattern ("g"), using the current thread's
  /// culture to obtain a format provider.
  /// </returns>
  @override String toString() => TextShim.toStringOffset(this); // OffsetPattern.BclSupport.Format(this, null, CultureInfo.CurrentCulture);


  /// Formats the value of the current instance using the specified pattern.
  ///
  /// <returns>
  /// A <see cref="T:System.String" /> containing the value of the current instance in the specified format.
  /// </returns>
  /// <param name="patternText">The <see cref="T:System.String" /> specifying the pattern to use,
  /// or null to use the default format pattern ("g").
  /// </param>
  /// <param name="formatProvider">The <see cref="T:System.IFormatProvider" /> to use when formatting the value,
  /// or null to use the current thread's culture to obtain a format provider.
  /// </param>
  /// <filterpriority>2</filterpriority>
//  String toString_Formatted(String patternText, IFormatProvider formatProvider) =>
//      OffsetPattern.BclSupport.Format(this, patternText, formatProvider);

  /// Returns an offset for the given seconds value, which may be negative.
  ///
  /// <param name="seconds">The int seconds value.</param>
  /// <returns>An offset representing the given number of seconds.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The specified number of seconds is outside the range of
  /// [-18, +18] hours.</exception>
  factory Offset.fromSeconds(int seconds) {
    Preconditions.checkArgumentRange('seconds', seconds, minSeconds, maxSeconds);
    return new Offset(seconds);
  }


  /// Returns an offset for the given milliseconds value, which may be negative.
  ///
  /// <remarks>
  /// Offsets are only accurate to second precision; the given number of milliseconds is simply divided
  /// by 1,000 to give the number of seconds - any remainder is truncated.
  /// </remarks>
  /// <param name="milliseconds">The int milliseconds value.</param>
  /// <returns>An offset representing the given number of milliseconds, to the (truncated) second.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The specified number of milliseconds is outside the range of
  /// [-18, +18] hours.</exception>
  factory Offset.fromMilliseconds(int milliseconds) {
    Preconditions.checkArgumentRange('milliseconds', milliseconds, _minMilliseconds, _maxMilliseconds);
    return new Offset(milliseconds ~/ TimeConstants.millisecondsPerSecond);
  }


  /// Returns an offset for the given number of ticks, which may be negative.
  ///
  /// <remarks>
  /// Offsets are only accurate to second precision; the given number of ticks is simply divided
  /// by 10,000,000 to give the number of seconds - any remainder is truncated.
  /// </remarks>
  /// <param name="ticks">The number of ticks specifying the length of the new offset.</param>
  /// <returns>An offset representing the given number of ticks, to the (truncated) second.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The specified number of ticks is outside the range of
  /// [-18, +18] hours.</exception>
  factory Offset.fromTicks(int ticks) {
    Preconditions.checkArgumentRange('ticks', ticks, _minTicks, _maxTicks);
    return new Offset((ticks ~/ TimeConstants.ticksPerSecond));
  }


  /// Returns an offset for the given number of nanoseconds, which may be negative.
  ///
  /// <remarks>
  /// Offsets are only accurate to second precision; the given number of nanoseconds is simply divided
  /// by 1,000,000,000 to give the number of seconds - any remainder is truncated towards zero.
  /// </remarks>
  /// <param name="nanoseconds">The number of nanoseconds specifying the length of the new offset.</param>
  /// <returns>An offset representing the given number of nanoseconds, to the (truncated) second.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The specified number of nanoseconds is outside the range of
  /// [-18, +18] hours.</exception>
  factory Offset.fromNanoseconds(int nanoseconds) {
    Preconditions.checkArgumentRange('nanoseconds', nanoseconds, _minNanoseconds, _maxNanoseconds);
    return new Offset((nanoseconds ~/ TimeConstants.nanosecondsPerSecond));
  }


  /// Returns an offset for the specified number of hours, which may be negative.
  ///
  /// <param name="hours">The number of hours to represent in the new offset.</param>
  /// <returns>An offset representing the given value.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The specified number of hours is outside the range of
  /// [-18, +18].</exception>
  factory Offset.fromHours(int hours) {
    Preconditions.checkArgumentRange('hours', hours, _minHours, _maxHours);
    return new Offset(hours * TimeConstants.secondsPerHour);
  }


  /// Returns an offset for the specified number of hours and minutes.
  ///
  /// <remarks>
  /// The result simply takes the hours and minutes and converts each component into milliseconds
  /// separately. As a result, a negative offset should usually be obtained by making both arguments
  /// negative. For example, to obtain "three hours and ten minutes behind UTC" you might call
  /// <c>Offset.FromHoursAndMinutes(-3, -10)</c>.
  /// </remarks>
  /// <param name="hours">The number of hours to represent in the new offset.</param>
  /// <param name="minutes">The number of minutes to represent in the new offset.</param>
  /// <returns>An offset representing the given value.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The result of the operation is outside the range of Offset.</exception>
  factory Offset.fromHoursAndMinutes(int hours, int minutes) =>
      new Offset.fromSeconds(hours * TimeConstants.secondsPerHour + minutes * TimeConstants.secondsPerMinute);


  /// Converts this offset to a .NET standard <see cref="TimeSpan" /> value.
  ///
  /// <returns>An equivalent <see cref="TimeSpan"/> to this value.</returns>

  Duration toDuration() => new Duration(seconds: _seconds);


  /// Converts the given <see cref="TimeSpan"/> to an offset, with fractional seconds truncated.
  ///
  /// <param name="timeSpan">The timespan to convert</param>
  /// <exception cref="ArgumentOutOfRangeException">The given time span falls outside the range of +/- 18 hours.</exception>
  /// <returns>An offset for the same time as the given time span.</returns>
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