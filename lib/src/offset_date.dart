// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
// import 'package:quiver_hashcode/hashcode.dart';
import 'package:time_machine/src/time_machine_internal.dart';

/// A combination of a [LocalDate] and an [Offset], to represent
/// a date at a specific offset from UTC but without any time-of-day information.
///
/// This type is immutable.
@immutable
class OffsetDate
{
  /// Gets the local date represented by this value.
  final LocalDate calendarDate;
  /// Gets the local date represented by this value.
  final Offset offset;

  /// Constructs an instance of the specified date and offset.
  ///
  /// * [date]: The date part of the value.
  /// * [offset]: The offset part of the value.
  const OffsetDate(this.calendarDate, this.offset);

  /// Gets the calendar system associated with this offset date.
  CalendarSystem get calendar => calendarDate.calendar;

  /// Gets the year of this offset date.
  /// This returns the 'absolute year', so, for the ISO calendar,
  /// a value of 0 means 1 BC, for example.
  int get year => calendarDate.year;

  /// Gets the month of this offset date within the year.
  int get monthOfYear => calendarDate.monthOfYear;

  /// Gets the day of this offset date within the month.
  int get dayOfMonth => calendarDate.dayOfMonth;

  /// Gets the week day of this offset date expressed as an [DayOfWeek] value.
  DayOfWeek get dayOfWeek => calendarDate.dayOfWeek;

  /// Gets the year of this offset date within the era.
  int get yearOfEra => calendarDate.yearOfEra;

  /// Gets the era of this offset date.
  Era get era => calendarDate.era;

  /// Gets the day of this offset date within the year.
  int get dayOfYear => calendarDate.dayOfYear;

  /// Creates a new [OffsetDate] for the same date, but with the specified UTC offset.
  ///
  /// * [offset]: The new UTC offset.
  ///
  /// Returns: A new `OffsetDate` for the same date, but with the specified UTC offset.
  OffsetDate withOffset(Offset offset) => OffsetDate(calendarDate, offset);

  /// Returns this offset date, with the given date adjuster applied to it, maintaining the existing offset.
  ///
  /// If the adjuster attempts to construct an
  /// invalid date (such as by trying to set a day-of-month of 30 in February), any exception thrown by
  /// that construction attempt will be propagated through this method.
  ///
  /// * [adjuster]: The adjuster to apply.
  ///
  /// Returns: The adjusted offset date.
  OffsetDate adjust(LocalDate Function(LocalDate) adjuster) =>
      OffsetDate(calendarDate.adjust(adjuster), offset);


  /// Creates a new [OffsetDate] representing the same physical date and offset, but in a different calendar.
  /// The returned value is likely to have different date field values to this one.
  /// For example, January 1st 1970 in the Gregorian calendar was December 19th 1969 in the Julian calendar.
  ///
  /// * [calendar]: The calendar system to convert this offset date to.
  ///
  /// Returns: The converted [OffsetDate].
  OffsetDate withCalendar(CalendarSystem calendar) =>
      OffsetDate(calendarDate.withCalendar(calendar), offset);


  /// Combines this [OffsetDate] with the given [LocalTime]
  /// into an [OffsetDateTime].
  ///
  /// * [time]: The time to combine with this date.
  ///
  /// Returns: The [OffsetDateTime] representation of the given time on this date.
  OffsetDateTime at(LocalTime time) => OffsetDateTime(calendarDate.at(time), offset);


  /// Returns a hash code for this offset date.
  @override int get hashCode => hash2(calendarDate, offset);

  /// Compares two [OffsetDate] values for equality. This requires
  /// that the date values be the same (in the same calendar) and the offsets.
  ///
  /// * [other]: The value to compare this offset date with.
  ///
  /// Returns: True if the given value is another offset date equal to this one; false otherwise.
  bool equals(OffsetDate other) => calendarDate == other.calendarDate && offset == other.offset;

  /// Implements the operator == (equality).
  ///
  /// * [left]: The left hand side of the operator.
  /// * [right]: The right hand side of the operator.
  ///
  /// Returns: `true` if values are equal to each other, otherwise `false`.
  @override
  bool operator ==(Object right) => right is OffsetDate && equals(right);

  /// Returns a [String] that represents this instance.
  ///
  /// The value of the current instance in the default format pattern ('G'), using the current isolate's
  /// culture to obtain a format provider.
  @override String toString([String? patternText, Culture? culture]) =>
      OffsetDatePatterns.format(this, patternText, culture);
}
