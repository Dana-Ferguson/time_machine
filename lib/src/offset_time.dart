// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
// import 'package:quiver_hashcode/hashcode.dart';
import 'package:time_machine/src/time_machine_internal.dart';

// todo: Comparable
@immutable
class OffsetTime {
  /// Gets the time-of-day represented by this value.
  final LocalTime clockTime;
  /// Gets the offset from UTC of this value.
  final Offset offset;

  /// Constructs an instance of the specified time and offset.
  ///
  /// * [time]: The time part of the value.
  /// * [offset]: The offset part of the value.
  const OffsetTime(this.clockTime, this.offset);

  /// Gets the hour of day of this offset time, in the range 0 to 23 inclusive.
  int get hourOfDay => clockTime.timeSinceMidnight.hourOfDay;

  /// Gets the hour of the half-day of this offset time, in the range 1 to 12 inclusive.
  int get hourOf12HourClock => clockTime.timeSinceMidnight.hourOf12HourClock;

  /// Gets the minute of this offset time, in the range 0 to 59 inclusive.
  int get minuteOfHour => clockTime.timeSinceMidnight.minuteOfHour;

  /// Gets the second of this offset time within the minute, in the range 0 to 59 inclusive.
  int get secondOfMinute => clockTime.timeSinceMidnight.secondOfMinute;

  /// Gets the millisecond of this offset time within the second, in the range 0 to 999 inclusive.
  int get millisecondOfSecond => clockTime.timeSinceMidnight.millisecondOfSecond;

  /// Gets the nanosecond of this offset time within the second, in the range 0 to 999,999,999 inclusive.
  int get nanosecondOfSecond => clockTime.timeSinceMidnight.nanosecondOfSecond;

  /// Creates a new [OffsetTime] for the same time-of-day, but with the specified UTC offset.
  ///
  /// * [offset]: The new UTC offset.
  ///
  /// Returns: A new `OffsetTime` for the same date, but with the specified UTC offset.
  OffsetTime withOffset(Offset offset) => OffsetTime(clockTime, offset);

  /// Returns this offset time-of-day, with the given date adjuster applied to it, maintaining the existing offset.
  ///
  /// If the adjuster attempts to construct an invalid time-of-day, any exception thrown by
  /// that construction attempt will be propagated through this method.
  ///
  /// * [adjuster]: The adjuster to apply.
  ///
  /// Returns: The adjusted offset date.
  OffsetTime adjust(LocalTime Function(LocalTime) adjuster) =>
      OffsetTime(clockTime.adjust(adjuster), offset);

  /// Combines this [OffsetTime] with the given [LocalDate]
  /// into an [OffsetDateTime].
  ///
  /// * [date]: The date to combine with this time-of-day.
  ///
  /// Returns: The [OffsetDateTime] representation of this time-of-day on the given date.
  OffsetDateTime atDate(LocalDate date) => OffsetDateTime(date.at(clockTime), offset);

  /// Returns a hash code for this offset time.
  @override int get hashCode => hash2(clockTime, offset);

  /// Compares two [OffsetTime] values for equality. This requires
  /// that the date values be the same and the offsets.
  ///
  /// * [other]: The value to compare this offset time with.
  ///
  /// Returns: True if the given value is another offset time equal to this one; false otherwise.
  bool equals(OffsetTime other) => clockTime == other.clockTime && offset == other.offset;

  /// Implements the operator == (equality).
  ///
  /// * [left]: The left hand side of the operator.
  /// * [right]: The right hand side of the operator.
  ///
  /// Returns: `true` if values are equal to each other, otherwise `false`.
  @override
  bool operator ==(Object right) => right is OffsetTime && equals(right);

  /// Formats the value of the current instance using the specified pattern.
  ///
  /// A [String] containing the value of the current instance in the specified format.
  ///
  /// * [patternText]: The [String] specifying the pattern to use,
  /// or null to use the default format pattern ('G').
  ///
  /// * [culture]: The [Culture] to use when formatting the value,
  /// or null to use the current isolate's culture.
  @override String toString([String? patternText, Culture? culture]) =>
      OffsetTimePatterns.format(this, patternText, culture);
}
