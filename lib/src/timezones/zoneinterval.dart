// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/ZoneInterval.cs
// 24fdeef  on Apr 10, 2017

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

/// <summary>
/// Represents a range of time for which a particular Offset applies.
/// </summary>
/// <threadsafety>This type is an immutable reference type. See the thread safety section of the user guide for more information.</threadsafety>
@immutable
/*sealed*/ class ZoneInterval // : IEquatable<ZoneInterval>
    {

  /// <summary>
  /// Returns the underlying start instant of this zone interval. If the zone interval extends to the
  /// beginning of time, the return value will be <see cref="Instant.BeforeMinValue"/>; this value
  /// should *not* be exposed publicly.
  /// </summary>
  @internal final Instant RawStart;

  /// <summary>
  /// Returns the underlying end instant of this zone interval. If the zone interval extends to the
  /// end of time, the return value will be <see cref="Instant.AfterMaxValue"/>; this value
  /// should *not* be exposed publicly.
  /// </summary>
  @internal final Instant RawEnd;

  final LocalInstant _localStart;
  final LocalInstant _localEnd;

  /// <summary>
  /// Gets the standard offset for this period. This is the offset without any daylight savings
  /// contributions.
  /// </summary>
  /// <remarks>
  /// This is effectively <c>WallOffset - Savings</c>.
  /// </remarks>
  /// <value>The base Offset.</value>
  Offset get StandardOffset => wallOffset - savings;

  /// <summary>
  /// Gets the duration of this zone interval.
  /// </summary>
  /// <remarks>
  /// This is effectively <c>End - Start</c>.
  /// </remarks>
  /// <value>The Duration of this zone interval.</value>
  /// <exception cref="InvalidOperationException">This zone extends to the start or end of time.</exception>
  Span get span => end - start;

  /// <summary>
  /// Returns <c>true</c> if this zone interval has a fixed start point, or <c>false</c> if it
  /// extends to the beginning of time.
  /// </summary>
  /// <value><c>true</c> if this interval has a fixed start point, or <c>false</c> if it
  /// extends to the beginning of time.</value>
  bool get HasStart => RawStart.IsValid;

  /// <summary>
  /// Gets the last Instant (exclusive) that the Offset applies.
  /// </summary>
  /// <value>The last Instant (exclusive) that the Offset applies.</value>
  /// <exception cref="InvalidOperationException">The zone interval extends to the end of time</exception>
  Instant get end {
    Preconditions.checkState(RawEnd.IsValid, "Zone interval extends to the end of time");
    return RawEnd;
  }

  /// <summary>
  /// Returns <c>true</c> if this zone interval has a fixed end point, or <c>false</c> if it
  /// extends to the end of time.
  /// </summary>
  /// <value><c>true</c> if this interval has a fixed end point, or <c>false</c> if it
  /// extends to the end of time.</value>
  bool get HasEnd => RawEnd.IsValid;

// TODO(feature): Consider whether we need some way of checking whether IsoLocalStart/End will throw.
// Clients can check HasStart/HasEnd for infinity, but what about unrepresentable local values?

  /// <summary>
  /// Gets the local start time of the interval, as a <see cref="LocalDateTime" />
  /// in the ISO calendar.
  /// </summary>
  /// <value>The local start time of the interval in the ISO calendar, with the offset of
  /// this zone interval.</value>
  /// <exception cref="OverflowException">The interval starts too early to represent as a `LocalDateTime`.</exception>
  /// <exception cref="InvalidOperationException">The interval extends to the start of time.</exception>
  LocalDateTime get IsoLocalStart =>
      // Use the Start property to trigger the appropriate end-of-time exception.
  // Call Plus to trigger an appropriate out-of-range exception.
  // todo: check this -- I'm not sure how I got so confused on this
  new LocalDateTime.fromInstant(start.SafePlus(wallOffset)); // .WithOffset(wallOffset));


  /// <summary>
  /// Gets the local end time of the interval, as a <see cref="LocalDateTime" />
  /// in the ISO calendar.
  /// </summary>
  /// <value>The local end time of the interval in the ISO calendar, with the offset
  /// of this zone interval. As the end time is exclusive, by the time this local time
  /// is reached, the next interval will be in effect and the local time will usually
  /// have changed (e.g. by adding or subtracting an hour).</value>
  /// <exception cref="OverflowException">The interval ends too late to represent as a `LocalDateTime`.</exception>
  /// <exception cref="InvalidOperationException">The interval extends to the end of time.</exception>
  LocalDateTime get IsoLocalEnd =>
      // Use the End property to trigger the appropriate end-of-time exception.
  // Call Plus to trigger an appropriate out-of-range exception.
  new LocalDateTime.fromInstant(end.plusOffset(wallOffset));


  /// <summary>
  /// Gets the name of this offset period (e.g. PST or PDT).
  /// </summary>
  /// <value>The name of this offset period (e.g. PST or PDT).</value>
  final String name;

  /// <summary>
  /// Gets the offset from UTC for this period. This includes any daylight savings value.
  /// </summary>
  /// <value>The offset from UTC for this period.</value>
  final Offset wallOffset;

  /// <summary>
  /// Gets the daylight savings value for this period.
  /// </summary>
  /// <value>The savings value.</value>
  final Offset savings;

///// <summary>
///// Initializes a new instance of the <see cref="ZoneInterval" /> class.
///// </summary>
///// <param name="name">The name of this offset period (e.g. PST or PDT).</param>
///// <param name="start">The first <see cref="Instant" /> that the <paramref name = "wallOffset" /> applies,
///// or <c>null</c> to make the zone interval extend to the start of time.</param>
///// <param name="end">The last <see cref="Instant" /> (exclusive) that the <paramref name = "wallOffset" /> applies,
///// or <c>null</c> to make the zone interval extend to the end of time.</param>
///// <param name="wallOffset">The <see cref="WallOffset" /> from UTC for this period including any daylight savings.</param>
///// <param name="savings">The <see cref="WallOffset" /> daylight savings contribution to the offset.</param>
///// <exception cref="ArgumentException">If <c><paramref name = "start" /> &gt;= <paramref name = "end" /></c>.</exception>
//ZoneInterval(String name, Instant start, Instant end, Offset wallOffset, Offset savings)
//    : this(name, start ?? Instant.BeforeMinValue, end ?? Instant.AfterMaxValue, wallOffset, savings)
//{
//}

  /// <summary>
  /// Gets the first Instant that the Offset applies.
  /// </summary>
  /// <value>The first Instant that the Offset applies.</value>
  Instant get start {
    Preconditions.checkState(RawStart.IsValid, "Zone interval extends to the beginning of time");
    return RawStart;
  }

  /// <summary>
  /// Initializes a new instance of the <see cref="ZoneInterval" /> class.
  /// </summary>
  /// <param name="name">The name of this offset period (e.g. PST or PDT).</param>
  /// <param name="start">The first <see cref="Instant" /> that the <paramref name = "wallOffset" /> applies,
  /// or <see cref="Instant.BeforeMinValue"/> to make the zone interval extend to the start of time.</param>
  /// <param name="end">The last <see cref="Instant" /> (exclusive) that the <paramref name = "wallOffset" /> applies,
  /// or <see cref="Instant.AfterMaxValue"/> to make the zone interval extend to the end of time.</param>
  /// <param name="wallOffset">The <see cref="WallOffset" /> from UTC for this period including any daylight savings.</param>
  /// <param name="savings">The <see cref="WallOffset" /> daylight savings contribution to the offset.</param>
  /// <exception cref="ArgumentException">If <c><paramref name = "start" /> &gt;= <paramref name = "end" /></c>.</exception>
  @internal ZoneInterval(this.name, this.RawStart, this.RawEnd, this.wallOffset, this.savings)
      :
  // Work out the corresponding local instants, taking care to "go infinite" appropriately.
        _localStart = RawStart.SafePlus(wallOffset),
        _localEnd = RawEnd.SafePlus(wallOffset) {
    Preconditions.checkNotNull(name, 'name');
    print(RawStart);
    print(RawEnd);
    Preconditions.checkArgument(RawStart < RawEnd, 'start', "The start Instant must be less than the end Instant");
  }

  // todo:  make all these factories

  /// <summary>
  /// Returns a copy of this zone interval, but with the given start instant.
  /// </summary>
  @internal ZoneInterval WithStart(Instant newStart) {
    return new ZoneInterval(name, newStart, RawEnd, wallOffset, savings);
  }

  /// <summary>
  /// Returns a copy of this zone interval, but with the given end instant.
  /// </summary>
  @internal ZoneInterval WithEnd(Instant newEnd) {
    return new ZoneInterval(name, RawStart, newEnd, wallOffset, savings);
  }

// #region Contains
  /// <summary>
  ///   Determines whether this period contains the given Instant in its range.
  /// </summary>
  /// <remarks>
  /// Usually this is half-open, i.e. the end is exclusive, but an interval with an end point of "the end of time"
  /// is deemed to be inclusive at the end.
  /// </remarks>
  /// <param name="instant">The instant to test.</param>
  /// <returns>
  ///   <c>true</c> if this period contains the given Instant in its range; otherwise, <c>false</c>.
  /// </returns>

  bool Contains(Instant instant) => RawStart <= instant && instant < RawEnd;

  /// <summary>
  ///   Determines whether this period contains the given LocalInstant in its range.
  /// </summary>
  /// <param name="localInstant">The local instant to test.</param>
  /// <returns>
  ///   <c>true</c> if this period contains the given LocalInstant in its range; otherwise, <c>false</c>.
  /// </returns>

  @internal bool ContainsLocal(LocalInstant localInstant) => _localStart <= localInstant && localInstant < _localEnd;

  /// <summary>
  /// Returns whether this zone interval has the same offsets and name as another.
  /// </summary>
  @internal bool EqualIgnoreBounds(ZoneInterval other) {
    // todo: debug check only
    Preconditions.checkNotNull(other, 'other');
    return other.wallOffset == wallOffset && other.savings == savings && other.name == name;
  }

// #endregion // Contains

// #region IEquatable<ZoneInterval> Members
  /// <summary>
  ///   Indicates whether the current object is equal to another object of the same type.
  /// </summary>
  /// <returns>
  ///   true if the current object is equal to the <paramref name = "other" /> parameter; otherwise, false.
  /// </returns>
  /// <param name="other">An object to compare with this object.
  /// </param>
  bool Equals(ZoneInterval other) {
    if (other == null) {
      return false;
    }
    // todo: unsure if this translates correctly
    if (this == other) {
      return true;
    }
    return name == other.name && RawStart == other.RawStart && RawEnd == other.RawEnd
        && wallOffset == other.wallOffset && savings == other.savings;
  }

  /// <summary>
  ///   Serves as a hash function for a particular type.
  /// </summary>
  /// <returns>
  ///   A hash code for the current <see cref="T:System.Object" />.
  /// </returns>
  /// <filterpriority>2</filterpriority>
  @override int get hashCode => hashObjects([name, RawStart, RawEnd, wallOffset, savings]);

  /// <summary>
  ///   Returns a <see cref="System.String" /> that represents this instance.
  /// </summary>
  /// <returns>
  ///   A <see cref="System.String" /> that represents this instance.
  /// </returns>
  @override String toString() => "${name}: [$RawStart, $RawEnd) $wallOffset ($savings)";
}