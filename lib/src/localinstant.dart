// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_utilities.dart';

/// Represents a local date and time without reference to a calendar system. Essentially
/// this is a duration since a Unix epoch shifted by an offset (but we don't store what that
/// offset is). This class has been slimmed down considerably over time - it's used much less
/// than it used to be... almost solely for time zones.
@internal class LocalInstant // : IEquatable<LocalInstant>
    {
  static final LocalInstant BeforeMinValue = new LocalInstant._trusted(Instant.beforeMinValue.daysSinceEpoch, deliberatelyInvalid: true);
  static final LocalInstant AfterMaxValue = new LocalInstant._trusted(Instant.afterMaxValue.daysSinceEpoch, deliberatelyInvalid: true);

  /// Elapsed time since the local 1970-01-01T00:00:00.
  Span _span;

  /// Constructor which should *only* be used to construct the invalid instances.
  LocalInstant._trusted(int days, {bool deliberatelyInvalid})
  {
    this._span = new Span(days: days);
  }

  /// Initializes a new instance of the [LocalInstant] struct.
  @internal LocalInstant(Span nanoseconds) {
    // todo: would it? (from Dart perspective -- we have different bounds? or do we? -- investigate)
    //int days = nanoseconds.FloorDays;
    //if (days < Instant.MinDays || days > Instant.MaxDays)
    //{
    //throw new OverflowException("Operation would overflow bounds of local date/time");
    //}
    this._span = nanoseconds;
  }

  /// Initializes a new instance of the [LocalInstant] struct.
  ///
  /// [days]: Number of days since 1970-01-01, in a time zone neutral fashion.
  /// [nanoOfDay]: Nanosecond of the local day.
  // todo: replace -- we use milliseconds\nanoseconds
  @internal LocalInstant.daysNanos(int days, int nanoOfDay)
  {
    this._span = new Span(days: days, nanoseconds: nanoOfDay);
  }

  /// Returns whether or not this is a valid instant. Returns true for all but
  /// [BeforeMinValue] and [AfterMaxValue].
  @internal bool get IsValid => DaysSinceEpoch >= Instant.minDays && DaysSinceEpoch <= Instant.maxDays;

  /// Number of nanoseconds since the local unix epoch.
  @internal Span get TimeSinceLocalEpoch => _span;

  /// Number of days since the local unix epoch.
  @internal int get DaysSinceEpoch => _span.floorDays;

  /// Nanosecond within the day.
  @internal int get NanosecondOfDay => _span.nanosecondOfFloorDay;

  /// Returns a new instant based on this local instant, as if we'd applied a zero offset.
  /// This is just a slight optimization over calling `localInstant.Minus(Offset.Zero)`.
  // todo: this is an API pickle
  @internal Instant MinusZeroOffset() => new Instant.trusted(_span);

  /// Subtracts the given time zone offset from this local instant, to give an [Instant].
  ///
  /// This would normally be implemented as an operator, but as the corresponding "plus" operation
  /// on Instant cannot be written (as Instant is a type and LocalInstant is an @internal type)
  /// it makes sense to keep them both as methods for consistency.
  ///
  /// [offset]: The offset between UTC and a time zone for this local instant
  /// Returns: A new [Instant] representing the difference of the given values.
  Instant Minus(Offset offset) => new Instant.untrusted(_span.plusSmallNanoseconds(-offset.nanoseconds)); // _span.MinusSmallNanoseconds(offset.Nanoseconds));

  /// Implements the operator == (equality).
  ///
  /// [left]: The left hand side of the operator.
  /// [right]: The right hand side of the operator.
  /// Returns: `true` if values are equal to each other, otherwise `false`.
  bool operator ==(dynamic right) => right is LocalInstant && _span == right._span;

  /// Equivalent to [Instant.SafePlus], but in the opposite direction.
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

  /// Implements the operator &lt; (less than).
  ///
  /// [left]: The left hand side of the operator.
  /// [right]: The right hand side of the operator.
  /// Returns: `true` if the left value is less than the right value, otherwise `false`.
  bool operator <(LocalInstant right) => _span < right._span;

  /// Implements the operator &lt;= (less than or equal).
  ///
  /// [left]: The left hand side of the operator.
  /// [right]: The right hand side of the operator.
  /// Returns: `true` if the left value is less than or equal to the right value, otherwise `false`.
  bool operator <=(LocalInstant right) => _span <= right._span;

  /// Implements the operator &gt; (greater than).
  ///
  /// [left]: The left hand side of the operator.
  /// [right]: The right hand side of the operator.
  /// Returns: `true` if the left value is greater than the right value, otherwise `false`.
  bool operator >(LocalInstant right) => _span > right._span;

  /// Implements the operator &gt;= (greater than or equal).
  ///
  /// [left]: The left hand side of the operator.
  /// [right]: The right hand side of the operator.
  /// Returns: `true` if the left value is greater than or equal to the right value, otherwise `false`.
  bool operator >=(LocalInstant right) => _span >= right._span;

  /// Returns a hash code for this instance.
  ///
  /// A hash code for this instance, suitable for use in hashing algorithms and data
  /// structures like a hash table.
  @override int get hashCode => _span.hashCode;

  /// Returns a [String] that represents this instance.
  ///
  /// A [String] that represents this instance.
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
  /// Indicates whether the current object is equal to another object of the same type.
  ///
  /// [other]: An object to compare with this object.
  ///
  /// true if the current object is equal to the [other] parameter;
  /// otherwise, false.
  bool Equals(LocalInstant other) => this == other;
}

