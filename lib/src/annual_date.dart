// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

/// Represents an annual date (month and day) in the ISO calendar but without a specific year,
/// typically for recurrent events such as birthdays, anniversaries, and deadlines.
///
/// In the future, this class may be expanded to support other calendar systems,
/// but this does not generalize terribly cleanly, particularly to the Hebrew calendar system
/// with its leap month.
@immutable
class AnnualDate implements Comparable<AnnualDate> {
  // The underlying value. We only care about the month and day, but for the sake of
  // compatibility with the default value, this ends up being in year 1. This would
  // be an invalid date, but we only actually use it as an argument to SetYear,
  // which we know ignores the year in the ISO calendar. If we ever allow other calendar
  // systems, we can have a YearMonthDayCalendar which would still be in year 1 for the
  // ISO calendar, but would probably be in a more suitable year for other calendars.
  final YearMonthDay _value;

  /// Constructs an instance for the given month and day in the ISO calendar.
  ///
  /// * [month]: The month of year.
  /// * [day]: The day of month.
  ///
  /// * [ArgumentOutOfRangeException]: The parameters do not form a valid date.
  /// (February 29th is considered valid.)
  AnnualDate([int month = 1, int day = 1])
    // See comment below for why this is using year 1, and why that's okay even for February 29th.
    : _value = YearMonthDay(1, month, day)
  {
    // The year 2000 is a leap year, so this is fine for all valid dates.
    GregorianYearMonthDayCalculator.validateGregorianYearMonthDay(2000, month, day);
  }

  /// Gets the month of year.
  int get month => _value.month;

  /// Gets the day of month.
  int get day => _value.day;

  /// Returns this annual date in a particular year, as a [LocalDate].
  ///
  /// If this value represents February 29th, and the specified year is not a leap
  /// year, the returned value will be February 28th of that year. To see whether the
  /// original month and day is valid without truncation in a particular year,
  /// use [IsValidYear]
  ///
  /// * [year]: The year component of the required date.
  ///
  /// Returns: A date in the given year, suitable for this annual date.
  LocalDate inYear(int year) {
    Preconditions.checkArgumentRange('year', year,
        GregorianYearMonthDayCalculator.minGregorianYear,
        GregorianYearMonthDayCalculator.maxGregorianYear);
    var ymd = ICalendarSystem.yearMonthDayCalculator(CalendarSystem.iso).setYear(_value, year);
    return ILocalDate.trusted(ymd.withCalendarOrdinal(const CalendarOrdinal(0))); // ISO calendar
  }

  /// Checks whether the specified year forms a valid date with the month/day in this
  /// value, without any truncation. This will always return `true` except
  /// for values representing February 29th, where the specified year is a non leap year.
  ///
  /// * [year]: The year to test for validity
  ///
  /// Returns: `true` if the current value occurs within the given year;
  /// `false` otherwise.
  bool isValidYear(int year) {
    return month != 2 || day != 29 || CalendarSystem.iso.isLeapYear(year);
  }

  /// Returns a hash code for this annual date.
  @override int get hashCode => _value.hashCode;

  /// Returns a [String] that represents this instance.
  ///
  /// The value of the current instance, in the form MM-dd.
  @override String toString() {
    // AnnualDatePattern.BclSupport.Format(this, null, Culture.currentCulture);
    return '${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  /// Indicates whether this annual date is earlier, later or the same as another one.
  ///
  /// * [other]: The other annual date to compare this one with
  ///
  /// A value less than zero if this annual date is earlier than [other];
  /// zero if this time is the same as [other]; a value greater than zero if this annual date is
  /// later than [other].
  @override
  int compareTo(AnnualDate? other) {
    if (other == null) return 1;
    return _value.compareTo(other._value);
  }

  /// Compares two [AnnualDate] values for equality.
  ///
  /// * [this]: The first value to compare
  /// * [rhs]: The second value to compare
  ///
  /// Returns: True if the two dates are the same; false otherwise
  @override
  bool operator ==(Object rhs) => rhs is AnnualDate && _value == rhs._value;

  /// Compares two annual dates to see if the left one is strictly earlier than the right
  /// one.
  ///
  /// * [this]: First operand of the comparison
  /// * [rhs]: Second operand of the comparison
  ///
  /// Returns: true if the [this] is strictly earlier than [this], false otherwise.
  ///
  /// * [ArgumentException]: The calendar system of [this] is not the same
  /// as the calendar of [this].
  bool operator <(AnnualDate rhs) {
    return compareTo(rhs) < 0;
  }

  /// Compares two annual dates to see if the left one is earlier than or equal to the right
  /// one.
  ///
  /// * [lhs]: First operand of the comparison
  /// * [rhs]: Second operand of the comparison
  ///
  /// Returns: true if the [this] is earlier than or equal to [this], false otherwise.
  bool operator <=(AnnualDate rhs) {
    return compareTo(rhs) <= 0;
  }

  /// Compares two annual dates to see if the left one is strictly later than the right
  /// one.
  ///
  /// * [this]: First operand of the comparison
  /// * [rhs]: Second operand of the comparison
  ///
  /// Returns: true if the [this] is strictly later than [rhs], false otherwise.
  bool operator >(AnnualDate rhs) {
    return compareTo(rhs) > 0;
  }

  /// Compares two annual dates to see if the left one is later than or equal to the right
  /// one.
  ///
  /// * [this]: First operand of the comparison
  /// * [rhs]: Second operand of the comparison
  ///
  /// Returns: true if the [this] is later than or equal to [rhs], false otherwise.
  bool operator >=(AnnualDate rhs) {
    return compareTo(rhs) >= 0;
  }
}
