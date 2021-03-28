// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';

/// General representation of the difference between two dates in a particular time unit,
/// such as 'days' or "months".
@internal
abstract class IDatePeriodField {
  /// Adds a duration value (which may be negative) to the date. This may not
  /// be reversible; for example, adding a month to January 30th will result in
  /// February 28th or February 29th.
  ///
  /// * [localDate]: The local date to add to
  /// * [value]: The value to add, in the units of the field
  ///
  /// Returns: The updated local date
  LocalDate add(LocalDate localDate, int value);

  /// Computes the difference between two local dates, as measured in the units
  /// of this field, rounding towards zero. This rounding means that
  /// unit.Add(start, unit.unitsBetween(start, end)) always ends up with a date
  /// between start and end. (Ideally equal to end, but importantly, it never overshoots.)
  ///
  /// * [start]: The start date
  /// * [end]: The end date
  ///
  /// Returns: The difference in the units of this field
  int unitsBetween(LocalDate start, LocalDate end);
}
