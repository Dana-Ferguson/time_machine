// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

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

  /// Constructs an instance of the specified time and offset.
  ///
  /// [time]: The time part of the value.
  /// [offset]: The offset part of the value.
  OffsetTime(this._time, this._offset);

  /// Gets the time-of-day represented by this value.
  LocalTime get TimeOfDay => _time;

  /// Gets the offset from UTC of this value.
  Offset get offset => _offset;

  /// Gets the hour of day of this offset time, in the range 0 to 23 inclusive.
  int get Hour => _time.Hour;

  /// Gets the hour of the half-day of this offset time, in the range 1 to 12 inclusive.
  int get ClockHourOfHalfDay => _time.ClockHourOfHalfDay;

  // TODO(feature): Consider exposing this.
  /// Gets the hour of the half-day of this offset time, in the range 0 to 11 inclusive.
  @internal int get HourOfHalfDay => _time.HourOfHalfDay;

  /// Gets the minute of this offset time, in the range 0 to 59 inclusive.
  int get Minute => _time.Minute;

  /// Gets the second of this offset time within the minute, in the range 0 to 59 inclusive.
  int get Second => _time.Second;

  /// Gets the millisecond of this offset time within the second, in the range 0 to 999 inclusive.
  int get Millisecond => _time.Millisecond;

  /// Gets the tick of this offset time within the second, in the range 0 to 9,999,999 inclusive.
  int get TickOfSecond => _time.TickOfSecond;

  /// Gets the tick of this offset time within the day, in the range 0 to 863,999,999,999 inclusive.
  ///
  /// If the value does not fall on a tick boundary, it will be truncated towards zero.
  int get TickOfDay => _time.TickOfDay;

  /// Gets the nanosecond of this offset time within the second, in the range 0 to 999,999,999 inclusive.
  int get NanosecondOfSecond => _time.NanosecondOfSecond;

  /// Gets the nanosecond of this offset time within the day, in the range 0 to 86,399,999,999,999 inclusive.
  int get NanosecondOfDay => _time.NanosecondOfDay;

/// Creates a new [OffsetTime] for the same time-of-day, but with the specified UTC offset.
///
/// [offset]: The new UTC offset.
/// Returns: A new `OffsetTime` for the same date, but with the specified UTC offset.

  OffsetTime WithOffset(Offset offset) => new OffsetTime(this._time, offset);

/// Returns this offset time-of-day, with the given date adjuster applied to it, maintaining the existing offset.
///
/// If the adjuster attempts to construct an invalid time-of-day, any exception thrown by
/// that construction attempt will be propagated through this method.
///
/// [adjuster]: The adjuster to apply.
/// Returns: The adjusted offset date.

  OffsetTime With(LocalTime Function(LocalTime) adjuster) =>
      new OffsetTime(TimeOfDay.With(adjuster), _offset);

/// Combines this [OffsetTime] with the given [LocalDate]
/// into an [OffsetDateTime].
///
/// [date]: The date to combine with this time-of-day.
/// Returns: The [OffsetDateTime] representation of this time-of-day on the given date.

  OffsetDateTime On(LocalDate date) => new OffsetDateTime(date.At(_time), offset);

  /// Returns a hash code for this offset time.
  ///
  /// Returns: A hash code for this offset time.
  @override int get hashCode => hash2(_time, _offset);

  /// Compares two [OffsetTime] values for equality. This requires
  /// that the date values be the same and the offsets.
  ///
  /// [other]: The value to compare this offset time with.
  /// Returns: True if the given value is another offset time equal to this one; false otherwise.
  bool equals(OffsetTime other) => TimeOfDay == other.TimeOfDay && _offset == other._offset;

  /// Implements the operator == (equality).
  ///
  /// [left]: The left hand side of the operator.
  /// [right]: The right hand side of the operator.
  /// Returns: `true` if values are equal to each other, otherwise `false`.
  bool operator ==(dynamic right) => right is OffsetTime && equals(right);

/// Returns a [String] that represents this instance.
///
/// The value of the current instance in the default format pattern ("G"), using the current thread's
/// culture to obtain a format provider.
//@override String toString() => OffsetTimePatterns.BclSupport.Format(this, null, CultureInfo.CurrentCulture);
//String toStringSimple() => TextShim.toStringOffsetTime(this); // OffsetTimePattern.Patterns.BclSupport.Format(this, null, CultureInfo.CurrentCulture);

  /// Formats the value of the current instance using the specified pattern.
  ///
  /// A [String] containing the value of the current instance in the specified format.
  ///
  /// [patternText]: The [String] specifying the pattern to use,
  /// or null to use the default format pattern ("G").
  ///
  /// [formatProvider]: The [IIFormatProvider] to use when formatting the value,
  /// or null to use the current thread's culture to obtain a format provider.
  ///
  /// <filterpriority>2</filterpriority>
  @override String toString([String patternText = null, /*IFormatProvider*/ dynamic formatProvider = null]) =>
      OffsetTimePatterns.BclSupport.Format(this, patternText, formatProvider ?? CultureInfo.currentCulture);

}
