// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/LocalInstant.cs
// 2dcb64f  on Aug 22, 2017

import 'package:meta/meta.dart';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_utilities.dart';

/// <summary>
/// Represents a local date and time without reference to a calendar system. Essentially
/// this is a duration since a Unix epoch shifted by an offset (but we don't store what that
/// offset is). This class has been slimmed down considerably over time - it's used much less
/// than it used to be... almost solely for time zones.
/// </summary>
@internal class LocalInstant // : IEquatable<LocalInstant>
    {
  static final LocalInstant BeforeMinValue = new LocalInstant._trusted(Instant.beforeMinValue.daysSinceEpoch, deliberatelyInvalid: true);
  static final LocalInstant AfterMaxValue = new LocalInstant._trusted(Instant.afterMaxValue.daysSinceEpoch, deliberatelyInvalid: true);

  /// <summary>
  /// Elapsed time since the local 1970-01-01T00:00:00.
  /// </summary>
  Span _span;

  /// <summary>
  /// Constructor which should *only* be used to construct the invalid instances.
  /// </summary>
  LocalInstant._trusted(int days, {bool deliberatelyInvalid})
  {
    this._span = new Span(days: days);
  }

  /// <summary>
  /// Initializes a new instance of the <see cref="LocalInstant"/> struct.
  /// </summary>
  @internal LocalInstant(Span nanoseconds) {
// todo: would it? (from Dart perspective -- we have different bounds? or do we? -- investigate)
//int days = nanoseconds.FloorDays;
//if (days < Instant.MinDays || days > Instant.MaxDays)
//{
//throw new OverflowException("Operation would overflow bounds of local date/time");
//}
    this._span = nanoseconds;
  }

  /// <summary>
  /// Initializes a new instance of the <see cref="LocalInstant"/> struct.
  /// </summary>
  /// <param name="days">Number of days since 1970-01-01, in a time zone neutral fashion.</param>
  /// <param name="nanoOfDay">Nanosecond of the local day.</param>
// todo: replace -- we use milliseconds\nanoseconds
  @internal LocalInstant.daysNanos(int days, int nanoOfDay)
  {
    this._span = new Span(days: days, nanoseconds: nanoOfDay);
  }

  /// <summary>
  /// Returns whether or not this is a valid instant. Returns true for all but
  /// <see cref="BeforeMinValue"/> and <see cref="AfterMaxValue"/>.
  /// </summary>
  @internal bool get IsValid => DaysSinceEpoch >= Instant.minDays && DaysSinceEpoch <= Instant.maxDays;

  /// <summary>
  /// Number of nanoseconds since the local unix epoch.
  /// </summary>
  @internal Span get TimeSinceLocalEpoch => _span;

  /// <summary>
  /// Number of days since the local unix epoch.
  /// </summary>
  @internal int get DaysSinceEpoch => _span.floorDays;

  /// <summary>
  /// Nanosecond within the day.
  /// </summary>
  @internal int get NanosecondOfDay => _span.nanosecondOfDay;

  /// <summary>
  /// Returns a new instant based on this local instant, as if we'd applied a zero offset.
  /// This is just a slight optimization over calling <c>localInstant.Minus(Offset.Zero)</c>.
  /// </summary>
  // todo: this is an API pickle
  @internal Instant MinusZeroOffset() => new Instant.trusted(_span);

  /// <summary>
  /// Subtracts the given time zone offset from this local instant, to give an <see cref="Instant" />.
  /// </summary>
  /// <remarks>
  /// This would normally be implemented as an operator, but as the corresponding "plus" operation
  /// on Instant cannot be written (as Instant is a type and LocalInstant is an @internal type)
  /// it makes sense to keep them both as methods for consistency.
  /// </remarks>
  /// <param name="offset">The offset between UTC and a time zone for this local instant</param>
  /// <returns>A new <see cref="Instant"/> representing the difference of the given values.</returns>
  Instant Minus(Offset offset) => new Instant.untrusted(_span.plusSmallNanoseconds(-offset.nanoseconds)); // _span.MinusSmallNanoseconds(offset.Nanoseconds));

  /// <summary>
  /// Implements the operator == (equality).
  /// </summary>
  /// <param name="left">The left hand side of the operator.</param>
  /// <param name="right">The right hand side of the operator.</param>
  /// <returns><c>true</c> if values are equal to each other, otherwise <c>false</c>.</returns>
  bool operator ==(dynamic right) => right is LocalInstant && _span == right._span;

  /// <summary>
  /// Equivalent to <see cref="Instant.SafePlus"/>, but in the opposite direction.
  /// </summary>
  @internal Instant SafeMinus(Offset offset) {
    int days = _span.days;
    // If we can do the arithmetic safely, do so.
    if (days > Instant.minDays && days < Instant.maxDays) {
      return Minus(offset);
    }
    // Handle BeforeMinValue and BeforeMaxValue simply.
    if (days < Instant.minDays) {
      return Instant.beforeMinValue;
    }
    if (days > Instant.maxDays) {
      return Instant.afterMaxValue;
    }
    // Okay, do the arithmetic as a Duration, then check the result for overflow, effectively.
    var asDuration = _span.plusSmallNanoseconds(-offset.nanoseconds);
    if (asDuration.days < Instant.minDays) { // FloorDays
      return Instant.beforeMinValue;
    }
    if (asDuration.days > Instant.maxDays) { // FloorDays
      return Instant.afterMaxValue;
    }
    // And now we don't need any more checks.
    return new Instant.trusted(asDuration);
  }

  /// <summary>
  /// Implements the operator &lt; (less than).
  /// </summary>
  /// <param name="left">The left hand side of the operator.</param>
  /// <param name="right">The right hand side of the operator.</param>
  /// <returns><c>true</c> if the left value is less than the right value, otherwise <c>false</c>.</returns>
  bool operator <(LocalInstant right) => _span < right._span;

  /// <summary>
  /// Implements the operator &lt;= (less than or equal).
  /// </summary>
  /// <param name="left">The left hand side of the operator.</param>
  /// <param name="right">The right hand side of the operator.</param>
  /// <returns><c>true</c> if the left value is less than or equal to the right value, otherwise <c>false</c>.</returns>
  bool operator <=(LocalInstant right) => _span <= right._span;

  /// <summary>
  /// Implements the operator &gt; (greater than).
  /// </summary>
  /// <param name="left">The left hand side of the operator.</param>
  /// <param name="right">The right hand side of the operator.</param>
  /// <returns><c>true</c> if the left value is greater than the right value, otherwise <c>false</c>.</returns>
  bool operator >(LocalInstant right) => _span > right._span;

  /// <summary>
  /// Implements the operator &gt;= (greater than or equal).
  /// </summary>
  /// <param name="left">The left hand side of the operator.</param>
  /// <param name="right">The right hand side of the operator.</param>
  /// <returns><c>true</c> if the left value is greater than or equal to the right value, otherwise <c>false</c>.</returns>
  bool operator >=(LocalInstant right) => _span >= right._span;

  /// <summary>
  /// Returns a hash code for this instance.
  /// </summary>
  /// <returns>
  /// A hash code for this instance, suitable for use in hashing algorithms and data
  /// structures like a hash table.
  /// </returns>
  @override int get hashCode => _span.hashCode;

  /// <summary>
  /// Returns a <see cref="System.String"/> that represents this instance.
  /// </summary>
  /// <returns>
  /// A <see cref="System.String"/> that represents this instance.
  /// </returns>
  @override String toString() // => TextShim.toStringLocalInstant(this);
  {
    if (this == BeforeMinValue) {
      return "StartOfTime"; // InstantPatternParser.BeforeMinValueText;
    }
    if (this == AfterMaxValue) {
      return "EndOfTime"; //InstantPatternParser.AfterMaxValueText;
    }
    var date = new LocalDate.fromDaysSinceEpoch(_span.floorDays);
    var pattern = LocalDateTimePattern.CreateWithInvariantCulture("uuuu-MM-ddTHH:mm:ss.FFFFFFFFF 'LOC'");
    var utc = new LocalDateTime(date, LocalTime.FromNanosecondsSinceMidnight(_span.nanosecondOfFloorDay));
    return pattern.Format(utc);
    // return TextShim.toStringLocalDateTime(utc); // + ' ${_span.days}::${_span.nanosecondOfDay} ';
  }

// #region IEquatable<LocalInstant> Members
  /// <summary>
  /// Indicates whether the current object is equal to another object of the same type.
  /// </summary>
  /// <param name="other">An object to compare with this object.</param>
  /// <returns>
  /// true if the current object is equal to the <paramref name="other"/> parameter;
  /// otherwise, false.
  /// </returns>
  bool Equals(LocalInstant other) => this == other;
}
