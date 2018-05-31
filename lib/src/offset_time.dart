// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/OffsetTime.cs
// 90fe960  on Nov 27, 2017

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_text.dart';

@immutable
class OffsetTime // : IEquatable<OffsetTime>, IXmlSerializable
    {
  final LocalTime _time;
  final Offset _offset;

  /// <summary>
  /// Constructs an instance of the specified time and offset.
  /// </summary>
  /// <param name="time">The time part of the value.</param>
  /// <param name="offset">The offset part of the value.</param>
  OffsetTime(this._time, this._offset);

  /// <summary>
  /// Gets the time-of-day represented by this value.
  /// </summary>
  /// <value>The time-of-day represented by this value.</value>
  LocalTime get TimeOfDay => _time;

  /// <summary>
  /// Gets the offset from UTC of this value.
  /// <value>The offset from UTC of this value.</value>
  /// </summary>
  Offset get offset => _offset;

  /// <summary>
  /// Gets the hour of day of this offset time, in the range 0 to 23 inclusive.
  /// </summary>
  /// <value>The hour of day of this offset time, in the range 0 to 23 inclusive.</value>
  int get Hour => _time.Hour;

  /// <summary>
  /// Gets the hour of the half-day of this offset time, in the range 1 to 12 inclusive.
  /// </summary>
  /// <value>The hour of the half-day of this offset time, in the range 1 to 12 inclusive.</value>
  int get ClockHourOfHalfDay => _time.ClockHourOfHalfDay;

  // TODO(feature): Consider exposing this.
  /// <summary>
  /// Gets the hour of the half-day of this offset time, in the range 0 to 11 inclusive.
  /// </summary>
  /// <value>The hour of the half-day of this offset time, in the range 0 to 11 inclusive.</value>
  @internal int get HourOfHalfDay => _time.HourOfHalfDay;

  /// <summary>
  /// Gets the minute of this offset time, in the range 0 to 59 inclusive.
  /// </summary>
  /// <value>The minute of this offset time, in the range 0 to 59 inclusive.</value>
  int get Minute => _time.Minute;

  /// <summary>
  /// Gets the second of this offset time within the minute, in the range 0 to 59 inclusive.
  /// </summary>
  /// <value>The second of this offset time within the minute, in the range 0 to 59 inclusive.</value>
  int get Second => _time.Second;

  /// <summary>
  /// Gets the millisecond of this offset time within the second, in the range 0 to 999 inclusive.
  /// </summary>
  /// <value>The millisecond of this offset time within the second, in the range 0 to 999 inclusive.</value>
  int get Millisecond => _time.Millisecond;

  /// <summary>
  /// Gets the tick of this offset time within the second, in the range 0 to 9,999,999 inclusive.
  /// </summary>
  /// <value>The tick of this offset time within the second, in the range 0 to 9,999,999 inclusive.</value>
  int get TickOfSecond => _time.TickOfSecond;

  /// <summary>
  /// Gets the tick of this offset time within the day, in the range 0 to 863,999,999,999 inclusive.
  /// </summary>
  /// <remarks>
  /// If the value does not fall on a tick boundary, it will be truncated towards zero.
  /// </remarks>
  /// <value>The tick of this offset time within the day, in the range 0 to 863,999,999,999 inclusive.</value>
  int get TickOfDay => _time.TickOfDay;

  /// <summary>
  /// Gets the nanosecond of this offset time within the second, in the range 0 to 999,999,999 inclusive.
  /// </summary>
  /// <value>The nanosecond of this offset time within the second, in the range 0 to 999,999,999 inclusive.</value>
  int get NanosecondOfSecond => _time.NanosecondOfSecond;

  /// <summary>
  /// Gets the nanosecond of this offset time within the day, in the range 0 to 86,399,999,999,999 inclusive.
  /// </summary>
  /// <value>The nanosecond of this offset time within the day, in the range 0 to 86,399,999,999,999 inclusive.</value>
  int get NanosecondOfDay => _time.NanosecondOfDay;

  /// <summary>
  /// Creates a new <see cref="OffsetTime"/> for the same time-of-day, but with the specified UTC offset.
  /// </summary>
  /// <param name="offset">The new UTC offset.</param>
  /// <returns>A new <c>OffsetTime</c> for the same date, but with the specified UTC offset.</returns>

  OffsetTime WithOffset(Offset offset) => new OffsetTime(this._time, offset);

  /// <summary>
  /// Returns this offset time-of-day, with the given date adjuster applied to it, maintaining the existing offset.
  /// </summary>
  /// <remarks>
  /// If the adjuster attempts to construct an invalid time-of-day, any exception thrown by
  /// that construction attempt will be propagated through this method.
  /// </remarks>
  /// <param name="adjuster">The adjuster to apply.</param>
  /// <returns>The adjusted offset date.</returns>

  OffsetTime With(LocalTime Function(LocalTime) adjuster) =>
      new OffsetTime(TimeOfDay.With(adjuster), _offset);

  /// <summary>
  /// Combines this <see cref="OffsetTime"/> with the given <see cref="LocalDate"/>
  /// into an <see cref="OffsetDateTime"/>.
  /// </summary>
  /// <param name="date">The date to combine with this time-of-day.</param>
  /// <returns>The <see cref="OffsetDateTime"/> representation of this time-of-day on the given date.</returns>

  OffsetDateTime On(LocalDate date) => new OffsetDateTime(date.At(_time), offset);

  /// <summary>
  /// Returns a hash code for this offset time.
  /// </summary>
  /// <returns>A hash code for this offset time.</returns>
  @override int get hashCode => hash2(_time, _offset);

  /// <summary>
  /// Compares two <see cref="OffsetTime"/> values for equality. This requires
  /// that the date values be the same and the offsets.
  /// </summary>
  /// <param name="other">The value to compare this offset time with.</param>
  /// <returns>True if the given value is another offset time equal to this one; false otherwise.</returns>
  bool equals(OffsetTime other) => TimeOfDay == other.TimeOfDay && _offset == other._offset;

  /// <summary>
  /// Implements the operator == (equality).
  /// </summary>
  /// <param name="left">The left hand side of the operator.</param>
  /// <param name="right">The right hand side of the operator.</param>
  /// <returns><c>true</c> if values are equal to each other, otherwise <c>false</c>.</returns>
  bool operator ==(dynamic right) => right is OffsetTime && equals(right);

  /// <summary>
  /// Returns a <see cref="System.String" /> that represents this instance.
  /// </summary>
  /// <returns>
  /// The value of the current instance in the default format pattern ("G"), using the current thread's
  /// culture to obtain a format provider.
  /// </returns>
  //@override String toString() => OffsetTimePatterns.BclSupport.Format(this, null, CultureInfo.CurrentCulture);
  //String toStringSimple() => TextShim.toStringOffsetTime(this); // OffsetTimePattern.Patterns.BclSupport.Format(this, null, CultureInfo.CurrentCulture);

  /// <summary>
  /// Formats the value of the current instance using the specified pattern.
  /// </summary>
  /// <returns>
  /// A <see cref="T:System.String" /> containing the value of the current instance in the specified format.
  /// </returns>
  /// <param name="patternText">The <see cref="T:System.String" /> specifying the pattern to use,
  /// or null to use the default format pattern ("G").
  /// </param>
  /// <param name="formatProvider">The <see cref="T:System.IFormatProvider" /> to use when formatting the value,
  /// or null to use the current thread's culture to obtain a format provider.
  /// </param>
  /// <filterpriority>2</filterpriority>
  @override String toString([String patternText = null, /*IFormatProvider*/ dynamic formatProvider = null]) =>
      OffsetTimePatterns.BclSupport.Format(this, patternText, formatProvider ?? CultureInfo.currentCulture);

}