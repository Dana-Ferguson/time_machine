// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_text.dart';

// todo: can this be refactored out to decrease code-size?

/// Represents a local date and time without reference to a calendar system. Essentially
/// this is a duration since a Unix epoch shifted by an offset (but we don't store what that
/// offset is). This class has been slimmed down considerably over time - it's used much less
/// than it used to be... almost solely for time zones.
@immutable
@internal
class LocalInstant {
  static final LocalInstant beforeMinValue = new LocalInstant._trusted(IInstant.beforeMinValue.daysSinceEpoch, deliberatelyInvalid: true);
  static final LocalInstant afterMaxValue = new LocalInstant._trusted(IInstant.afterMaxValue.daysSinceEpoch, deliberatelyInvalid: true);

  /// Elapsed time since the local 1970-01-01T00:00:00.
  final Span _span;

  LocalInstant._ (this._span);

  /// Constructor which should *only* be used to construct the invalid instances.
  factory LocalInstant._trusted(int days, {bool deliberatelyInvalid})
  {
    return new LocalInstant._(new Span(days: days));
  }

  /// Initializes a new instance of [LocalInstant].
  factory LocalInstant(Span nanoseconds) {
    // todo: would it? (from Dart perspective -- we have different bounds? or do we? -- investigate)
    //int days = nanoseconds.FloorDays;
    //if (days < Instant.MinDays || days > Instant.MaxDays)
    //{
    //throw new OverflowException("Operation would overflow bounds of local date/time");
    //}
    return new LocalInstant._(nanoseconds);
  }

  /// Initializes a new instance of [LocalInstant].
  ///
  /// [days]: Number of days since 1970-01-01, in a time zone neutral fashion.
  /// [nanoOfDay]: Nanosecond of the local day.
  factory LocalInstant.daysNanos(int days, int nanoOfDay)
  {
    return new LocalInstant._(new Span(days: days, nanoseconds: nanoOfDay));
  }

  /// Returns whether or not this is a valid instant. Returns true for all but
  /// [beforeMinValue] and [afterMaxValue].
  bool get isValid => daysSinceEpoch >= IInstant.minDays && daysSinceEpoch <= IInstant.maxDays;

  /// Number of nanoseconds since the local unix epoch.
  Span get timeSinceLocalEpoch => _span;

  /// Number of days since the local unix epoch.
  int get daysSinceEpoch => _span.floorDays;

  /// Nanosecond within the day.
  int get nanosecondOfDay => _span.nanosecondOfFloorDay;

  /// Returns a new instant based on this local instant, as if we'd applied a zero offset.
  /// This is just a slight optimization over calling `localInstant.Minus(Offset.Zero)`.
  // todo: this is an API pickle
  Instant minusZeroOffset() => IInstant.trusted(_span);

  /// Subtracts the given time zone offset from this local instant, to give an [Instant].
  ///
  /// This would normally be implemented as an operator, but as the corresponding "plus" operation
  /// on Instant cannot be written (as Instant is a type and LocalInstant is an type)
  /// it makes sense to keep them both as methods for consistency.
  ///
  /// [offset]: The offset between UTC and a time zone for this local instant
  /// Returns: A new [Instant] representing the difference of the given values.
  Instant minus(Offset offset) => IInstant.untrusted(ISpan.plusSmallNanoseconds(_span, -offset.nanoseconds)); // _span.MinusSmallNanoseconds(offset.Nanoseconds));

  /// Implements the operator == (equality).
  ///
  /// [left]: The left hand side of the operator.
  /// [right]: The right hand side of the operator.
  /// Returns: `true` if values are equal to each other, otherwise `false`.
  bool operator ==(dynamic right) => right is LocalInstant && _span == right._span;

  /// Equivalent to [Instant.safePlus], but in the opposite direction.
  Instant safeMinus(Offset offset) {
    int days = _span.days;
    // If we can do the arithmetic safely, do so.
    if (days > IInstant.minDays && days < IInstant.maxDays) {
      return minus(offset);
    }
    // Handle BeforeMinValue and BeforeMaxValue simply.
    if (days < IInstant.minDays) {
      return IInstant.beforeMinValue;
    }
    if (days > IInstant.maxDays) {
      return IInstant.afterMaxValue;
    }
    // Okay, do the arithmetic as a Duration, then check the result for overflow, effectively.
    var asDuration = ISpan.plusSmallNanoseconds(_span, -offset.nanoseconds);
    if (asDuration.days < IInstant.minDays) { // FloorDays
      return IInstant.beforeMinValue;
    }
    if (asDuration.days > IInstant.maxDays) { // FloorDays
      return IInstant.afterMaxValue;
    }
    // And now we don't need any more checks.
    return IInstant.trusted(asDuration);
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
    if (this == beforeMinValue) {
      return "StartOfTime"; // InstantPatternParser.BeforeMinValueText;
    }
    if (this == afterMaxValue) {
      return "EndOfTime"; //InstantPatternParser.AfterMaxValueText;
    }
    var date = ILocalDate.fromDaysSinceEpoch(_span.floorDays);
    var pattern = LocalDateTimePattern.createWithInvariantCulture("uuuu-MM-ddTHH:mm:ss.FFFFFFFFF 'LOC'");
    var utc = new LocalDateTime(date, ILocalTime.fromNanosecondsSinceMidnight(_span.nanosecondOfFloorDay));
    return pattern.format(utc);
  // return TextShim.toStringLocalDateTime(utc); // + ' ${_span.days}::${_span.nanosecondOfDay} ';
  }

  // #region IEquatable<LocalInstant> Members
  /// Indicates whether the current object is equal to another object of the same type.
  ///
  /// [other]: An object to compare with this object.
  ///
  /// true if the current object is equal to the [other] parameter;
  /// otherwise, false.
  bool equals(LocalInstant other) => this == other;
}

