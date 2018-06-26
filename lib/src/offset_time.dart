// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';

// todo: Comparable
@immutable
class OffsetTime {
  final LocalTime _time;
  final Offset _offset;

  /// Constructs an instance of the specified time and offset.
  ///
  /// [time]: The time part of the value.
  /// [offset]: The offset part of the value.
  OffsetTime(this._time, this._offset);

  /// Gets the time-of-day represented by this value.
  LocalTime get timeOfDay => _time;

  /// Gets the offset from UTC of this value.
  Offset get offset => _offset;

  /// Gets the hour of day of this offset time, in the range 0 to 23 inclusive.
  int get hour => _time.hour;

  /// Gets the hour of the half-day of this offset time, in the range 1 to 12 inclusive.
  int get clockHourOfHalfDay => _time.clockHourOfHalfDay;

  // TODO(feature): Consider exposing this.
  /// Gets the hour of the half-day of this offset time, in the range 0 to 11 inclusive.
  /*@internal*/ int get _hourOfHalfDay => ILocalTime.hourOfHalfDay(_time);

  /// Gets the minute of this offset time, in the range 0 to 59 inclusive.
  int get minute => _time.minute;

  /// Gets the second of this offset time within the minute, in the range 0 to 59 inclusive.
  int get second => _time.second;

  /// Gets the millisecond of this offset time within the second, in the range 0 to 999 inclusive.
  int get millisecond => _time.millisecond;

  /// Gets the tick of this offset time within the second, in the range 0 to 9,999,999 inclusive.
  int get tickOfSecond => _time.tickOfSecond;

  /// Gets the tick of this offset time within the day, in the range 0 to 863,999,999,999 inclusive.
  ///
  /// If the value does not fall on a tick boundary, it will be truncated towards zero.
  int get tickOfDay => _time.tickOfDay;

  /// Gets the nanosecond of this offset time within the second, in the range 0 to 999,999,999 inclusive.
  int get nanosecondOfSecond => _time.nanosecondOfSecond;

  /// Gets the nanosecond of this offset time within the day, in the range 0 to 86,399,999,999,999 inclusive.
  int get nanosecondOfDay => _time.nanosecondOfDay;

  /// Creates a new [OffsetTime] for the same time-of-day, but with the specified UTC offset.
  ///
  /// [offset]: The new UTC offset.
  /// Returns: A new `OffsetTime` for the same date, but with the specified UTC offset.
  OffsetTime withOffset(Offset offset) => new OffsetTime(this._time, offset);

  /// Returns this offset time-of-day, with the given date adjuster applied to it, maintaining the existing offset.
  ///
  /// If the adjuster attempts to construct an invalid time-of-day, any exception thrown by
  /// that construction attempt will be propagated through this method.
  ///
  /// [adjuster]: The adjuster to apply.
  /// Returns: The adjusted offset date.
  OffsetTime adjust(LocalTime Function(LocalTime) adjuster) =>
      new OffsetTime(timeOfDay.adjust(adjuster), _offset);

  /// Combines this [OffsetTime] with the given [LocalDate]
  /// into an [OffsetDateTime].
  ///
  /// [date]: The date to combine with this time-of-day.
  /// Returns: The [OffsetDateTime] representation of this time-of-day on the given date.
  OffsetDateTime atDate(LocalDate date) => new OffsetDateTime(date.at(_time), offset);

  /// Returns a hash code for this offset time.
  ///
  /// Returns: A hash code for this offset time.
  @override int get hashCode => hash2(_time, _offset);

  /// Compares two [OffsetTime] values for equality. This requires
  /// that the date values be the same and the offsets.
  ///
  /// [other]: The value to compare this offset time with.
  /// Returns: True if the given value is another offset time equal to this one; false otherwise.
  bool equals(OffsetTime other) => timeOfDay == other.timeOfDay && _offset == other._offset;

  /// Implements the operator == (equality).
  ///
  /// [left]: The left hand side of the operator.
  /// [right]: The right hand side of the operator.
  /// Returns: `true` if values are equal to each other, otherwise `false`.
  bool operator ==(dynamic right) => right is OffsetTime && equals(right);

  /// Formats the value of the current instance using the specified pattern.
  ///
  /// A [String] containing the value of the current instance in the specified format.
  ///
  /// [patternText]: The [String] specifying the pattern to use,
  /// or null to use the default format pattern ("G").
  ///
  /// [formatProvider]: The [IIFormatProvider] to use when formatting the value,
  /// or null to use the current thread's culture to obtain a format provider.
  @override String toString([String patternText = null, /*IFormatProvider*/ dynamic formatProvider = null]) =>
      OffsetTimePatterns.bclSupport.format(this, patternText, formatProvider ?? CultureInfo.currentCulture);
}
