// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/OffsetDate.cs
// 90fe960  on Nov 27, 2017

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';

class OffsetDate // : IEquatable<OffsetDate>
{
  LocalDate _date;
  Offset _offset;


  /// Constructs an instance of the specified date and offset.
  ///
  /// <param name="date">The date part of the value.</param>
  /// <param name="offset">The offset part of the value.</param>
  OffsetDate(this._date, this._offset);


  /// Gets the local date represented by this value.
  ///
  /// <value>The local date represented by this value.</value>
  LocalDate get date => _date;


  /// Gets the offset from UTC of this value.
  ///
  /// <value>The offset from UTC of this value.</value>
  Offset get offset => _offset;

  /// Gets the calendar system associated with this offset date.
  /// <value>The calendar system associated with this offset date.</value>
  CalendarSystem get calendar => date.Calendar;

  /// Gets the year of this offset date.
  /// <remarks>This returns the "absolute year", so, for the ISO calendar,
  /// a value of 0 means 1 BC, for example.</remarks>
  /// <value>The year of this offset date.</value>
  int get year => date.Year;

  /// Gets the month of this offset date within the year.
  /// <value>The month of this offset date within the year.</value>
  int get month => date.Month;

  /// Gets the day of this offset date within the month.
  /// <value>The day of this offset date within the month.</value>
  int get day => date.Day;


  /// Gets the week day of this offset date expressed as an <see cref="NodaTime.IsoDayOfWeek"/> value.
  ///
  /// <value>The week day of this offset date expressed as an <c>IsoDayOfWeek</c>.</value>
  IsoDayOfWeek get dayOfWeek => date.DayOfWeek;

  /// Gets the year of this offset date within the era.
  /// <value>The year of this offset date within the era.</value>
  int get yearOfEra => date.YearOfEra;

  /// Gets the era of this offset date.
  /// <value>The era of this offset date.</value>
  Era get era => date.era;

  /// Gets the day of this offset date within the year.
  /// <value>The day of this offset date within the year.</value>
  int get dayOfYear => date.DayOfYear;


  /// Creates a new <see cref="OffsetDate"/> for the same date, but with the specified UTC offset.
  ///
  /// <param name="offset">The new UTC offset.</param>
  /// <returns>A new <c>OffsetDate</c> for the same date, but with the specified UTC offset.</returns>

  OffsetDate withOffset(Offset offset) => new OffsetDate(this._date, offset);


  /// Returns this offset date, with the given date adjuster applied to it, maintaining the existing offset.
  ///
  /// <remarks>
  /// If the adjuster attempts to construct an
  /// invalid date (such as by trying to set a day-of-month of 30 in February), any exception thrown by
  /// that construction attempt will be propagated through this method.
  /// </remarks>
  /// <param name="adjuster">The adjuster to apply.</param>
  /// <returns>The adjusted offset date.</returns>

  OffsetDate With(LocalDate Function(LocalDate) adjuster) =>
      new OffsetDate(date.With(adjuster), _offset);


  /// Creates a new <see cref="OffsetDate"/> representing the same physical date and offset, but in a different calendar.
  /// The returned value is likely to have different date field values to this one.
  /// For example, January 1st 1970 in the Gregorian calendar was December 19th 1969 in the Julian calendar.
  ///
  /// <param name="calendar">The calendar system to convert this offset date to.</param>
  /// <returns>The converted <c>OffsetDate</c>.</returns>

  OffsetDate WithCalendar(CalendarSystem calendar) =>
      new OffsetDate(date.WithCalendar(calendar), _offset);


  /// Combines this <see cref="OffsetDate"/> with the given <see cref="LocalTime"/>
  /// into an <see cref="OffsetDateTime"/>.
  ///
  /// <param name="time">The time to combine with this date.</param>
  /// <returns>The <see cref="OffsetDateTime"/> representation of the given time on this date.</returns>

  OffsetDateTime At(LocalTime time) => new OffsetDateTime(date.At(time), offset);


  /// Returns a hash code for this offset date.
  ///
  /// <returns>A hash code for this offset date.</returns>
  @override int get hashCode => hash2(_date, _offset);

  /// Compares two <see cref="OffsetDate"/> values for equality. This requires
  /// that the date values be the same (in the same calendar) and the offsets.
  ///
  /// <param name="other">The value to compare this offset date with.</param>
  /// <returns>True if the given value is another offset date equal to this one; false otherwise.</returns>
  bool Equals(OffsetDate other) => date == other.date && Offset == other._offset;


  /// Implements the operator == (equality).
  ///
  /// <param name="left">The left hand side of the operator.</param>
  /// <param name="right">The right hand side of the operator.</param>
  /// <returns><c>true</c> if values are equal to each other, otherwise <c>false</c>.</returns>
  bool operator ==(dynamic right) => right is OffsetDate && Equals(right);

  /// Returns a <see cref="System.String" /> that represents this instance.
  ///
  /// <returns>
  /// The value of the current instance in the default format pattern ("G"), using the current thread's
  /// culture to obtain a format provider.
  /// </returns>
  @override String toString() => OffsetDatePattern.Patterns.BclSupport.Format(this, null, CultureInfo.CurrentCulture);


  /// Formats the value of the current instance using the specified pattern.
  ///
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
  String toString_Pattern(String patternText, IFormatProvider formatProvider) =>
      OffsetDatePattern.Patterns.BclSupport.Format(this, patternText, formatProvider);

}