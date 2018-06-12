// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

/// Represents a range of time for which a particular Offset applies.
///
/// <threadsafety>This type is an immutable reference type. See the thread safety section of the user guide for more information.</threadsafety>
@immutable
/*sealed*/ class ZoneInterval // : IEquatable<ZoneInterval>
    {

  /// Returns the underlying start instant of this zone interval. If the zone interval extends to the
  /// beginning of time, the return value will be [Instant.beforeMinValue]; this value
  /// should *not* be exposed publicly.
  @internal final Instant RawStart;

  /// Returns the underlying end instant of this zone interval. If the zone interval extends to the
  /// end of time, the return value will be [Instant.afterMaxValue]; this value
  /// should *not* be exposed publicly.
  @internal final Instant RawEnd;

  final LocalInstant _localStart;
  final LocalInstant _localEnd;

  /// Gets the standard offset for this period. This is the offset without any daylight savings
  /// contributions.
  ///
  /// This is effectively `WallOffset - Savings`.
  Offset get StandardOffset => wallOffset - savings;

  /// Gets the duration of this zone interval.
  ///
  /// This is effectively `End - Start`.
  ///
  /// [InvalidOperationException]: This zone extends to the start or end of time.
  Span get span => end - start;

  /// Returns `true` if this zone interval has a fixed start point, or `false` if it
  /// extends to the beginning of time.
  ///
  /// <value>`true` if this interval has a fixed start point, or `false` if it
  /// extends to the beginning of time.</value>
  bool get HasStart => RawStart.IsValid;

  /// Gets the last Instant (exclusive) that the Offset applies.
  ///
  /// [InvalidOperationException]: The zone interval extends to the end of time
  Instant get end {
    Preconditions.checkState(RawEnd.IsValid, "Zone interval extends to the end of time");
    return RawEnd;
  }

  /// Returns `true` if this zone interval has a fixed end point, or `false` if it
  /// extends to the end of time.
  ///
  /// <value>`true` if this interval has a fixed end point, or `false` if it
  /// extends to the end of time.</value>
  bool get HasEnd => RawEnd.IsValid;

// TODO(feature): Consider whether we need some way of checking whether IsoLocalStart/End will throw.
// Clients can check HasStart/HasEnd for infinity, but what about unrepresentable local values?

  /// Gets the local start time of the interval, as a [LocalDateTime]
  /// in the ISO calendar.
  ///
  /// <value>The local start time of the interval in the ISO calendar, with the offset of
  /// this zone interval.</value>
  /// [OverflowException]: The interval starts too early to represent as a `LocalDateTime`.
  /// [InvalidOperationException]: The interval extends to the start of time.
  LocalDateTime get IsoLocalStart =>
  // Use the Start property to trigger the appropriate end-of-time exception.
  // Call Plus to trigger an appropriate out-of-range exception.
  // todo: check this -- I'm not sure how I got so confused on this
  new LocalDateTime.fromInstant(start.SafePlus(wallOffset)); // .WithOffset(wallOffset));


  /// Gets the local end time of the interval, as a [LocalDateTime]
  /// in the ISO calendar.
  ///
  /// <value>The local end time of the interval in the ISO calendar, with the offset
  /// of this zone interval. As the end time is exclusive, by the time this local time
  /// is reached, the next interval will be in effect and the local time will usually
  /// have changed (e.g. by adding or subtracting an hour).</value>
  /// [OverflowException]: The interval ends too late to represent as a `LocalDateTime`.
  /// [InvalidOperationException]: The interval extends to the end of time.
  LocalDateTime get IsoLocalEnd =>
  // Use the End property to trigger the appropriate end-of-time exception.
  // Call Plus to trigger an appropriate out-of-range exception.
  new LocalDateTime.fromInstant(end.plusOffset(wallOffset));


  /// Gets the name of this offset period (e.g. PST or PDT).
  final String name;

  /// Gets the offset from UTC for this period. This includes any daylight savings value.
  final Offset wallOffset;

  /// Gets the daylight savings value for this period.
  final Offset savings;

///// Initializes a new instance of the [ZoneInterval] class.
///// 
///// [name]: The name of this offset period (e.g. PST or PDT).
///// [start]: The first [Instant] that the <paramref name = "wallOffset" /> applies,
///// or `null` to make the zone interval extend to the start of time.
///// [end]: The last [Instant] (exclusive) that the <paramref name = "wallOffset" /> applies,
///// or `null` to make the zone interval extend to the end of time.
///// [wallOffset]: The [WallOffset] from UTC for this period including any daylight savings.
///// [savings]: The [WallOffset] daylight savings contribution to the offset.
///// [ArgumentException]: If `<paramref name = "start" /> &gt;= <paramref name = "end" />`.
//ZoneInterval(String name, Instant start, Instant end, Offset wallOffset, Offset savings)
//    : this(name, start ?? Instant.BeforeMinValue, end ?? Instant.AfterMaxValue, wallOffset, savings)
//{
//}

  /// Gets the first Instant that the Offset applies.
  Instant get start {
    Preconditions.checkState(RawStart.IsValid, "Zone interval extends to the beginning of time");
    return RawStart;
  }

  /// Initializes a new instance of the [ZoneInterval] class.
  ///
  /// [name]: The name of this offset period (e.g. PST or PDT).
  /// [start]: The first [Instant] that the <paramref name = "wallOffset" /> applies,
  /// or [Instant.beforeMinValue] to make the zone interval extend to the start of time.
  /// [end]: The last [Instant] (exclusive) that the <paramref name = "wallOffset" /> applies,
  /// or [Instant.afterMaxValue] to make the zone interval extend to the end of time.
  /// [wallOffset]: The [WallOffset] from UTC for this period including any daylight savings.
  /// [savings]: The [WallOffset] daylight savings contribution to the offset.
  /// [ArgumentException]: If `<paramref name = "start" /> &gt;= <paramref name = "end" />`.
  @internal factory ZoneInterval(String name, Instant rawStart, Instant rawEnd, Offset wallOffset, Offset savings) {
    rawStart ??= Instant.beforeMinValue;
    rawEnd ??= Instant.afterMaxValue;
    // Work out the corresponding local instants, taking care to "go infinite" appropriately.
    Preconditions.checkNotNull(name, 'name');
    Preconditions.checkArgument(rawStart < rawEnd, 'start', "The start Instant must be less than the end Instant");
    return new ZoneInterval._(name, rawStart, rawEnd, wallOffset, savings);
  }

  ZoneInterval._(this.name, this.RawStart, this.RawEnd, this.wallOffset, this.savings) :
        _localStart = RawStart.SafePlus(wallOffset),
        _localEnd = RawEnd.SafePlus(wallOffset);

// todo:  make all these factories

  /// Returns a copy of this zone interval, but with the given start instant.
  @internal ZoneInterval WithStart(Instant newStart) {
    return new ZoneInterval(name, newStart, RawEnd, wallOffset, savings);
  }

  /// Returns a copy of this zone interval, but with the given end instant.
  @internal ZoneInterval WithEnd(Instant newEnd) {
    return new ZoneInterval(name, RawStart, newEnd, wallOffset, savings);
  }

// #region Contains
///   Determines whether this period contains the given Instant in its range.
///
/// Usually this is half-open, i.e. the end is exclusive, but an interval with an end point of "the end of time"
/// is deemed to be inclusive at the end.
///
/// [instant]: The instant to test.
///
///   `true` if this period contains the given Instant in its range; otherwise, `false`.

  bool Contains(Instant instant) => RawStart <= instant && instant < RawEnd;

///   Determines whether this period contains the given LocalInstant in its range.
///
/// [localInstant]: The local instant to test.
///
///   `true` if this period contains the given LocalInstant in its range; otherwise, `false`.

  @internal bool containsLocal(LocalInstant localInstant) => _localStart <= localInstant && localInstant < _localEnd;

  /// Returns whether this zone interval has the same offsets and name as another.
  @internal bool EqualIgnoreBounds(ZoneInterval other) {
    // todo: debug check only
    Preconditions.checkNotNull(other, 'other');
    return other.wallOffset == wallOffset && other.savings == savings && other.name == name;
  }

// #endregion // Contains

  // #region IEquatable<ZoneInterval> Members
  ///   Indicates whether the current object is equal to another object of the same type.
  ///
  ///   true if the current object is equal to the <paramref name = "other" /> parameter; otherwise, false.
  ///
  /// [other]: An object to compare with this object.
  bool Equals(ZoneInterval other) {
    if (identical(other, null)) {
      return false;
    }
    if (identical(this, other)) {
      return true;
    }
    return name == other.name && RawStart == other.RawStart && RawEnd == other.RawEnd
        && wallOffset == other.wallOffset && savings == other.savings;
  }

  @override bool operator==(dynamic other) => other is ZoneInterval ? Equals(other) : false;

  ///   Serves as a hash function for a particular type.
  ///
  ///   A hash code for the current [System.Object].
  ///
  /// <filterpriority>2</filterpriority>
  @override int get hashCode => hashObjects([name, RawStart, RawEnd, wallOffset, savings]);

  ///   Returns a [String] that represents this instance.
  ///
  ///   A [String] that represents this instance.
  // @override String toString() => "${name}: [$RawStart, $RawEnd) $wallOffset ($savings)";
  // @override String toString() => "${name}: [$IsoLocalStart, $IsoLocalEnd) $wallOffset ($savings)";
  @override String toString() => "${name}: [$RawStart, $RawEnd) $wallOffset ($savings)";
}
