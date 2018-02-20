// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Fields/IDatePeriodField.cs
// ce257e4  on May 24, 2017

import 'package:time_machine/time_machine.dart';

/// General representation of the difference between two dates in a particular time unit,
/// such as "days" or "months".
@internal abstract class IDatePeriodField {
  /// <summary>
  /// Adds a duration value (which may be negative) to the date. This may not
  /// be reversible; for example, adding a month to January 30th will result in
  /// February 28th or February 29th.
  /// </summary>
  /// <param name="localDate">The local date to add to</param>
  /// <param name="value">The value to add, in the units of the field</param>
  /// <returns>The updated local date</returns>
  LocalDate Add(LocalDate localDate, int value);

  /// <summary>
  /// Computes the difference between two local dates, as measured in the units
  /// of this field, rounding towards zero. This rounding means that
  /// unit.Add(start, unit.UnitsBetween(start, end)) always ends up with a date
  /// between start and end. (Ideally equal to end, but importantly, it never overshoots.)
  /// </summary>
  /// <param name="start">The start date</param>
  /// <param name="end">The end date</param>
  /// <returns>The difference in the units of this field</returns>
  int UnitsBetween(LocalDate start, LocalDate end);
}