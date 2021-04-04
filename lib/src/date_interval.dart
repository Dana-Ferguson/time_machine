// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
// import 'package:quiver_hashcode/hashcode.dart';
import 'package:time_machine/src/time_machine_internal.dart';

/// An interval between two dates.
///
/// The two dates must be in the same calendar, and the end date must not be earlier than the start date.
///
/// The end date is deemed to be part of the range, as this matches many real life uses of
/// date ranges. For example, if someone says "I'm going to be on holiday from Monday to Friday," they
/// usually mean that Friday is part of their holiday.
@immutable
class DateInterval {
  /// Gets the start date of the interval.
  final LocalDate start;

  /// Gets the end date of the interval.
  final LocalDate end;

  /// Constructs a date interval from a start date and an end date, both of which are included
  /// in the interval.
  ///
  /// * [start]: Start date of the interval
  /// * [end]: End date of the interval
  ///
  /// Returns: A date interval between the specified dates.
  ///
  /// * [ArgumentError]: [end] is earlier than [start]
  /// or the two dates are in different calendars.
  DateInterval(this.start, this.end) {
    // todo: will this equivalence work out?
    Preconditions.checkArgument(start.calendar == end.calendar, 'end', "Calendars of start and end dates must be the same.");
    Preconditions.checkArgument(!(end < start), 'end', "End date must not be earlier than the start date");
  }


  /// Returns the hash code for this interval, consistent with [Equals(DateInterval)].
  @override int get hashCode => hash2(start, end);

  /// Compares two [DateInterval] values for equality.
  ///
  /// Date intervals are equal if they have the same start and end dates.
  ///
  /// * [this]: The first value to compare
  /// * [rhs]: The second value to compare
  ///
  /// Returns: True if the two date intervals have the same properties; false otherwise.
  @override
  bool operator ==(Object rhs) => rhs is DateInterval && start == rhs.start && end == rhs.end;


  /// Compares the given date interval for equality with this one.
  ///
  /// Date intervals are equal if they have the same start and end dates.
  ///
  /// * [other]: The date interval to compare this one with.
  ///
  /// Returns: True if this date interval has the same same start and end date as the one specified.
  bool equals(DateInterval other) => this == other;

  /// Checks whether the given date is within this date interval. This requires
  /// that the date is not earlier than the start date, and not later than the end
  /// date.
  ///
  /// * [date]: The date to check for containment within this interval.
  ///
  /// Returns: `true` if [date] is within this interval; `false` otherwise.
  ///
  /// * [ArgumentException]: [date] is not in the same
  /// calendar as the start and end date of this interval.
  bool contains(LocalDate date) {
    // if (date == null) throw ArgumentError.notNull('date');
    Preconditions.checkArgument(date.calendar == start.calendar, 'date', "The date to check must be in the same calendar as the start and end dates");
    return start <= date && date <= end;
  }

  /// Checks whether the given interval is within this interval. This requires that the start date of the specified
  /// interval is not earlier than the start date of this interval, and the end date of the specified interval is not
  /// later than the end date of this interval.
  ///
  /// An interval contains another interval with same start and end dates, or itself.
  ///
  /// * [interval]: The interval to check for containment within this interval.
  ///
  /// Returns: `true` if [interval] is within this interval; `false` otherwise.
  ///
  /// [ArgumentException]: [interval] uses a different
  /// calendar to this date interval.
  bool containsInterval(DateInterval interval) {
    _validateInterval(interval);
    return contains(interval.start) && contains(interval.end);
  }


  /// Gets the length of this date interval in days. This will always be at least 1.
  int get length =>
    // Period.DaysBetween will give us the exclusive result, so we need to add 1
    // to include the end date.
    IPeriod.daysBetween(start, end) + 1;

  /// Gets the calendar system of the dates in this interval.
  CalendarSystem get calendar => start.calendar;

  /// Returns a string representation of this interval.
  ///
  /// A string representation of this interval, as `[start, end]`,
  /// where 'start' and "end" are the dates formatted using an ISO-8601 compatible pattern.
  @override String toString() {
    String a = LocalDatePattern.iso.format(start);
    String b = LocalDatePattern.iso.format(end);
    return '[$a, $b]';
  }

  /// Returns the intersection between the given interval and this interval.
  ///
  /// * [interval]: The specified interval to intersect with this one.
  ///
  /// A [DateInterval] corresponding to the intersection between the given interval and the current
  /// instance. If there is no intersection, a null reference is returned.
  ///
  /// * [ArgumentException]: [interval] uses a different
  /// calendar to this date interval.
  DateInterval? intersection(DateInterval interval) {
    return containsInterval(interval) ? interval
        : interval.containsInterval(this) ? this
        : interval.contains(start) ? DateInterval(start, interval.end)
        : interval.contains(end) ? DateInterval(interval.start, end)
        : null;
  }


  /// Returns the union between the given interval and this interval, as long as they're overlapping or contiguous.
  ///
  /// * [interval]: The specified interval from which to generate the union interval.
  ///
  /// A [DateInterval] corresponding to the union between the given interval and the current
  /// instance, in the case the intervals overlap or are contiguous; a null reference otherwise.
  ///
  /// * [ArgumentException]: [interval] uses a different calendar to this date interval.
  DateInterval? union(DateInterval interval) {
    _validateInterval(interval);

    var _start = LocalDate.min(start, interval.start);
    var _end = LocalDate.max(end, interval.end);

    // Check whether the length of the interval we *would* construct is greater
    // than the sum of the lengths - if it is, there's a day in that candidate union
    // that isn't in either interval. Note the absence of "+ 1" and the use of >=
    // - it's equivalent to Period.DaysBetween(...) + 1 > Length + interval.Length,
    // but with fewer operations.
    return IPeriod.daysBetween(_start, _end) >= length + interval.length
        ? null
        : DateInterval(_start, _end);
  }

  void _validateInterval(DateInterval interval) {
    Preconditions.checkNotNull(interval, 'interval');
    Preconditions.checkArgument(interval.calendar == start.calendar, 'interval',
        'The specified interval uses a different calendar system to this one');
  }
}

