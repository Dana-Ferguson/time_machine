// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/AnnualDate.cs
// 2cd3c25  on Oct 16, 2017

import 'package:meta/meta.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';

/// Represents an annual date (month and day) in the ISO calendar but without a specific year,
/// typically for recurrent events such as birthdays, anniversaries, and deadlines.
///
/// <remarks>In the future, this struct may be expanded to support other calendar systems,
/// but this does not generalize terribly cleanly, particularly to the Hebrew calendar system
/// with its leap month.</remarks>
class AnnualDate implements Comparable<AnnualDate> // : IEquatable<AnnualDate>, IComparable<AnnualDate>
    {
// The underlying value. We only care about the month and day, but for the sake of
// compatibility with the default value, this ends up being in year 1. This would
// be an invalid date, but we only actually use it as an argument to SetYear,
// which we know ignores the year in the ISO calendar. If we ever allow other calendar
// systems, we can have a YearMonthDayCalendar which would still be in year 1 for the
// ISO calendar, but would probably be in a more suitable year for other calendars.
  final YearMonthDay _value;

  /// <summary>
  /// Constructs an instance for the given month and day in the ISO calendar.
  /// </summary>
  /// <param name="month">The month of year.</param>
  /// <param name="day">The day of month.</param>
  /// <exception cref="ArgumentOutOfRangeException">The parameters do not form a valid date.
  /// (February 29th is considered valid.)</exception>
  AnnualDate([int month = 1, int day = 1]) :
    // See comment below for why this is using year 1, and why that's okay even for February 29th.
    _value = new YearMonthDay(1, month, day)
  {
    // The year 2000 is a leap year, so this is fine for all valid dates.
    GregorianYearMonthDayCalculator.validateGregorianYearMonthDay(2000, month, day);
  }

  /// <summary>
  /// Gets the month of year.
  /// </summary>
  /// <value>The month of year.</value>
  int get month => _value.month;

  /// <summary>
  /// Gets the day of month.
  /// </summary>
  /// <value>The day of month.</value>
  int get day => _value.day;

  /// <summary>
  /// Returns this annual date in a particular year, as a <see cref="LocalDate"/>.
  /// </summary>
  /// <remarks>
  /// <para>
  /// If this value represents February 29th, and the specified year is not a leap
  /// year, the returned value will be February 28th of that year. To see whether the
  /// original month and day is valid without truncation in a particular year,
  /// use <see cref="IsValidYear"/>
  /// </para>
  /// </remarks>
  /// <param name="year">The year component of the required date.</param>
  /// <returns>A date in the given year, suitable for this annual date.</returns>
  // todo: does this name fit dart style?
  LocalDate inYear(int year) {
    Preconditions.checkArgumentRange('year', year,
        GregorianYearMonthDayCalculator.minGregorianYear,
        GregorianYearMonthDayCalculator.maxGregorianYear);
    var ymd = CalendarSystem.Iso.yearMonthDayCalculator.setYear(_value, year);
    return new LocalDate.trusted(ymd.WithCalendarOrdinal(new CalendarOrdinal(0))); // ISO calendar
  }

  /// <summary>
  /// Checks whether the specified year forms a valid date with the month/day in this
  /// value, without any truncation. This will always return <c>true</c> except
  /// for values representing February 29th, where the specified year is a non leap year.
  /// </summary>
  /// <param name="year">The year to test for validity</param>
  /// <returns><c>true</c> if the current value occurs within the given year;
  /// <c>false</c> otherwise.</returns>
  bool isValidYear(int year) {
    return month != 2 || day != 29 || CalendarSystem.Iso.IsLeapYear(year);
  }

  /// <summary>
  /// Returns a hash code for this annual date.
  /// </summary>
  /// <returns>A hash code for this annual date.</returns>
  @override int get hashCode => _value.hashCode;

  /// <summary>
  /// Returns a <see cref="System.String" /> that represents this instance.
  /// </summary>
  /// <returns>
  /// The value of the current instance, in the form MM-dd.
  /// </returns>
  @override String toString() {
    return '${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  /// <summary>
  /// Indicates whether this annual date is earlier, later or the same as another one.
  /// </summary>
  /// <param name="other">The other annual date to compare this one with</param>
  /// <returns>A value less than zero if this annual date is earlier than <paramref name="other"/>;
  /// zero if this time is the same as <paramref name="other"/>; a value greater than zero if this annual date is
  /// later than <paramref name="other"/>.</returns>
  int compareTo(AnnualDate other) {
    if (other == null) return 1;
    return _value.compareTo(other._value);
  }

  /// <summary>
  /// Compares two <see cref="AnnualDate" /> values for equality.
  /// </summary>
  /// <param name="lhs">The first value to compare</param>
  /// <param name="rhs">The second value to compare</param>
  /// <returns>True if the two dates are the same; false otherwise</returns>
  bool operator ==(dynamic rhs) => rhs is AnnualDate && _value == rhs._value;

  /// <summary>
  /// Compares two annual dates to see if the left one is strictly earlier than the right
  /// one.
  /// </summary>
  /// <param name="lhs">First operand of the comparison</param>
  /// <param name="rhs">Second operand of the comparison</param>
  /// <exception cref="ArgumentException">The calendar system of <paramref name="rhs"/> is not the same
  /// as the calendar of <paramref name="lhs"/>.</exception>
  /// <returns>true if the <paramref name="lhs"/> is strictly earlier than <paramref name="rhs"/>, false otherwise.</returns>
  bool operator <(AnnualDate rhs) {
    return compareTo(rhs) < 0;
  }

  /// <summary>
  /// Compares two annual dates to see if the left one is earlier than or equal to the right
  /// one.
  /// </summary>
  /// <param name="lhs">First operand of the comparison</param>
  /// <param name="rhs">Second operand of the comparison</param>
  /// <returns>true if the <paramref name="lhs"/> is earlier than or equal to <paramref name="rhs"/>, false otherwise.</returns>
  bool operator <=(AnnualDate rhs) {
    return compareTo(rhs) <= 0;
  }

  /// <summary>
  /// Compares two annual dates to see if the left one is strictly later than the right
  /// one.
  /// </summary>
  /// <param name="lhs">First operand of the comparison</param>
  /// <param name="rhs">Second operand of the comparison</param>
  /// <returns>true if the <paramref name="lhs"/> is strictly later than <paramref name="rhs"/>, false otherwise.</returns>
  bool operator >(AnnualDate rhs) {
    return compareTo(rhs) > 0;
  }

  /// <summary>
  /// Compares two annual dates to see if the left one is later than or equal to the right
  /// one.
  /// </summary>
  /// <param name="lhs">First operand of the comparison</param>
  /// <param name="rhs">Second operand of the comparison</param>
  /// <returns>true if the <paramref name="lhs"/> is later than or equal to <paramref name="rhs"/>, false otherwise.</returns>
  bool operator >=(AnnualDate rhs) {
    return compareTo(rhs) >= 0;
  }
}