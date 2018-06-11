// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';

class OffsetDate // : IEquatable<OffsetDate>
{
  LocalDate _date;
  Offset _offset;


  /// Constructs an instance of the specified date and offset.
  ///
  /// [date]: The date part of the value.
  /// [offset]: The offset part of the value.
  OffsetDate(this._date, this._offset);


  /// Gets the local date represented by this value.
  LocalDate get date => _date;


  /// Gets the offset from UTC of this value.
  Offset get offset => _offset;

  /// Gets the calendar system associated with this offset date.
  CalendarSystem get calendar => date.calendar;

  /// Gets the year of this offset date.
  /// This returns the "absolute year", so, for the ISO calendar,
  /// a value of 0 means 1 BC, for example.
  int get year => date.year;

  /// Gets the month of this offset date within the year.
  int get month => date.month;

  /// Gets the day of this offset date within the month.
  int get day => date.day;


  /// Gets the week day of this offset date expressed as an [IsoDayOfWeek] value.
  IsoDayOfWeek get dayOfWeek => date.dayOfWeek;

  /// Gets the year of this offset date within the era.
  int get yearOfEra => date.yearOfEra;

  /// Gets the era of this offset date.
  Era get era => date.era;

  /// Gets the day of this offset date within the year.
  int get dayOfYear => date.dayOfYear;


/// Creates a new [OffsetDate] for the same date, but with the specified UTC offset.
///
/// [offset]: The new UTC offset.
/// Returns: A new `OffsetDate` for the same date, but with the specified UTC offset.

  OffsetDate withOffset(Offset offset) => new OffsetDate(this._date, offset);


/// Returns this offset date, with the given date adjuster applied to it, maintaining the existing offset.
///
/// If the adjuster attempts to construct an
/// invalid date (such as by trying to set a day-of-month of 30 in February), any exception thrown by
/// that construction attempt will be propagated through this method.
///
/// [adjuster]: The adjuster to apply.
/// Returns: The adjusted offset date.

  OffsetDate With(LocalDate Function(LocalDate) adjuster) =>
      new OffsetDate(date.adjust(adjuster), _offset);


/// Creates a new [OffsetDate] representing the same physical date and offset, but in a different calendar.
/// The returned value is likely to have different date field values to this one.
/// For example, January 1st 1970 in the Gregorian calendar was December 19th 1969 in the Julian calendar.
///
/// [calendar]: The calendar system to convert this offset date to.
/// Returns: The converted `OffsetDate`.

  OffsetDate WithCalendar(CalendarSystem calendar) =>
      new OffsetDate(date.withCalendar(calendar), _offset);


/// Combines this [OffsetDate] with the given [LocalTime]
/// into an [OffsetDateTime].
///
/// [time]: The time to combine with this date.
/// Returns: The [OffsetDateTime] representation of the given time on this date.

  OffsetDateTime At(LocalTime time) => new OffsetDateTime(date.at(time), offset);


  /// Returns a hash code for this offset date.
  ///
  /// Returns: A hash code for this offset date.
  @override int get hashCode => hash2(_date, _offset);

  /// Compares two [OffsetDate] values for equality. This requires
  /// that the date values be the same (in the same calendar) and the offsets.
  ///
  /// [other]: The value to compare this offset date with.
  /// Returns: True if the given value is another offset date equal to this one; false otherwise.
  bool Equals(OffsetDate other) => date == other.date && _offset == other._offset;


  /// Implements the operator == (equality).
  ///
  /// [left]: The left hand side of the operator.
  /// [right]: The right hand side of the operator.
  /// Returns: `true` if values are equal to each other, otherwise `false`.
  bool operator ==(dynamic right) => right is OffsetDate && Equals(right);

  /// Returns a [String] that represents this instance.
  ///
  /// The value of the current instance in the default format pattern ("G"), using the current thread's
  /// culture to obtain a format provider.
  // @override String toString() => TextShim.toStringOffsetDate(this); // OffsetDatePattern.Patterns.BclSupport.Format(this, null, CultureInfo.CurrentCulture);
  @override String toString([String patternText = null, /*IFormatProvider*/ dynamic formatProvider = null]) =>
      OffsetDatePatterns.BclSupport.Format(this, patternText, formatProvider ?? CultureInfo.currentCulture);


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
//  String toString_Pattern(String patternText, IFormatProvider formatProvider) =>
//      OffsetDatePattern.Patterns.BclSupport.Format(this, patternText, formatProvider);

}
