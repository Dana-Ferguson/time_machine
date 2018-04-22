// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/DateInterval.cs
// fa6874e  on Dec 8, 2017

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';


/// An interval between two dates.
/// 
/// <remarks>
/// <para>
/// The two dates must be in the same calendar, and the end date must not be earlier than the start date.
/// </para>
/// <para>
/// The end date is deemed to be part of the range, as this matches many real life uses of
/// date ranges. For example, if someone says "I'm going to be on holiday from Monday to Friday," they
/// usually mean that Friday is part of their holiday.
/// </para>
/// </remarks>
// todo: is there an IEquatable equivalent?
@immutable
class DateInterval // : IEquatable<DateInterval>
{

/// Gets the start date of the interval.
/// 
/// <value>The start date of the interval.</value>
final LocalDate start;


/// Gets the end date of the interval.
/// 
/// <value>The end date of the interval.</value>
final LocalDate end;


/// Constructs a date interval from a start date and an end date, both of which are included
/// in the interval.
/// 
/// <param name="start">Start date of the interval</param>
/// <param name="end">End date of the interval</param>
/// <exception cref="ArgumentException"><paramref name="end"/> is earlier than <paramref name="start"/>
/// or the two dates are in different calendars.
/// </exception>
/// <returns>A date interval between the specified dates.</returns>
DateInterval(this.start, this.end)
{
  // todo: will this equivalence work out?
  Preconditions.checkArgument(start.Calendar == end.Calendar, 'end',
      "Calendars of start and end dates must be the same.");
  Preconditions.checkArgument(!(end < start), 'end', "End date must not be earlier than the start date");
}


/// Returns the hash code for this interval, consistent with <see cref="Equals(DateInterval)"/>.
/// 
/// <returns>The hash code for this interval.</returns>
@override int get hashCode => hash2(start, end);

/// Compares two <see cref="DateInterval" /> values for equality.
/// 
/// <remarks>
/// Date intervals are equal if they have the same start and end dates.
/// </remarks>
/// <param name="lhs">The first value to compare</param>
/// <param name="rhs">The second value to compare</param>
/// <returns>True if the two date intervals have the same properties; false otherwise.</returns>
bool operator ==(dynamic rhs) => rhs is DateInterval && start == rhs.start && end == rhs.end;


/// Compares the given date interval for equality with this one.
/// 
/// <remarks>
/// Date intervals are equal if they have the same start and end dates.
/// </remarks>
/// <param name="other">The date interval to compare this one with.</param>
/// <returns>True if this date interval has the same same start and end date as the one specified.</returns>
bool equals(DateInterval other) => this == other;

/// Checks whether the given date is within this date interval. This requires
/// that the date is not earlier than the start date, and not later than the end
/// date.
/// 
/// <param name="date">The date to check for containment within this interval.</param>
/// <exception cref="ArgumentException"><paramref name="date"/> is not in the same
/// calendar as the start and end date of this interval.</exception>
/// <returns><c>true</c> if <paramref name="date"/> is within this interval; <c>false</c> otherwise.</returns>
bool contains(LocalDate date)
{
  if (date == null) throw new ArgumentError.notNull('date');
  Preconditions.checkArgument(date.Calendar == start.Calendar, 'date',
      "The date to check must be in the same calendar as the start and end dates");
  return start <= date && date <= end;
}


/// Checks whether the given interval is within this interval. This requires that the start date of the specified
/// interval is not earlier than the start date of this interval, and the end date of the specified interval is not
/// later than the end date of this interval.
/// 
/// <remarks>
/// An interval contains another interval with same start and end dates, or itself.
/// </remarks>
/// <param name="interval">The interval to check for containment within this interval.</param>
/// <exception cref="ArgumentException"><paramref name="interval" /> uses a different
/// calendar to this date interval.</exception>
/// <returns><c>true</c> if <paramref name="interval"/> is within this interval; <c>false</c> otherwise.</returns>
bool containsInterval(DateInterval interval)
{
  _validateInterval(interval);
  return contains(interval.start) && contains(interval.end);
}


/// Gets the length of this date interval in days. This will always be at least 1.
/// 
/// <value>The length of this date interval in days.</value>
int get length =>
// Period.DaysBetween will give us the exclusive result, so we need to add 1
// to include the end date.
  Period.DaysBetween(start, end) + 1;


/// Gets the calendar system of the dates in this interval.
/// 
/// <value>The calendar system of the dates in this interval.</value>
CalendarSystem get Calendar => start.Calendar;


/// Returns a string representation of this interval.
/// 
/// <returns>
/// A string representation of this interval, as <c>[start, end]</c>,
/// where "start" and "end" are the dates formatted using an ISO-8601 compatible pattern.
/// </returns>
@override String toString() => TextShim.toStringDateInterval(this);
//{
//  String a = LocalDatePattern.Iso.Format(start);
//  String b = LocalDatePattern.Iso.Format(end);
//  return "[$a, $b]";
//}

/// Returns the intersection between the given interval and this interval.
/// 
/// <param name="interval">
/// The specified interval to intersect with this one.
/// </param>
/// <returns>
/// A <see cref="DateInterval"/> corresponding to the intersection between the given interval and the current
/// instance. If there is no intersection, a null reference is returned.
/// </returns>
/// <exception cref="ArgumentException"><paramref name="interval" /> uses a different
/// calendar to this date interval.</exception>
DateInterval Intersection(DateInterval interval)
{
return containsInterval(interval) ? interval
    : interval.containsInterval(this) ? this
    : interval.contains(start) ? new DateInterval(start, interval.end)
    : interval.contains(end) ? new DateInterval(interval.start, end)
    : null;
}


/// Returns the union between the given interval and this interval, as long as they're overlapping or contiguous.
/// 
/// <param name="interval">The specified interval from which to generate the union interval.</param>
/// <returns>
/// A <see cref="DateInterval"/> corresponding to the union between the given interval and the current
/// instance, in the case the intervals overlap or are contiguous; a null reference otherwise.
/// </returns>
/// <exception cref="ArgumentException"><paramref name="interval" /> uses a different calendar to this date interval.</exception>
DateInterval Union(DateInterval interval)
{
_validateInterval(interval);

var _start = LocalDate.Min(start, interval.start);
var _end = LocalDate.Max(end, interval.end);

// Check whether the length of the interval we *would* construct is greater
// than the sum of the lengths - if it is, there's a day in that candidate union
// that isn't in either interval. Note the absence of "+ 1" and the use of >=
// - it's equivalent to Period.DaysBetween(...) + 1 > Length + interval.Length,
// but with fewer operations.
return Period.DaysBetween(_start, _end) >= length + interval.length
? null
    : new DateInterval(_start, _end);
}

void _validateInterval(DateInterval interval)
{
  Preconditions.checkNotNull(interval, 'interval');
  Preconditions.checkArgument(interval.Calendar == start.Calendar, 'interval',
      "The specified interval uses a different calendar system to this one");
}
}
