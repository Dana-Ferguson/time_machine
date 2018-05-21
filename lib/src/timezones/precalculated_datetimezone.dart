// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/PrecalculatedDateTimeZone.cs
// 2e79a7a  on Sep 29, 2017

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

// Essentially Func<Offset, Offset, Offset>
@private typedef Offset _offsetAggregator(Offset x, Offset y);
@private typedef Offset _offsetExtractor</*todo:in*/T>(T input);


/// <summary>
/// Most time zones have a relatively small set of transitions at their start until they finally 
/// settle down to either a fixed time zone or a daylight savings time zone. This provides the
/// container for the initial zone intervals and a pointer to the time zone that handles all of
/// the rest until the end of time.
/// </summary>
// sealed
@internal class PrecalculatedDateTimeZone extends DateTimeZone {
  @private final List<ZoneInterval> periods;
  @private final IZoneIntervalMapWithMinMax tailZone;

  /// <summary>
  /// The first instant covered by the tail zone, or Instant.AfterMaxValue if there's no tail zone.
  /// </summary>
  @private final Instant tailZoneStart;
  @private final ZoneInterval firstTailZoneInterval;

  PrecalculatedDateTimeZone._(String id, this.periods, this.tailZone, this.firstTailZoneInterval, this.tailZoneStart)
      : super(id, false, ComputeOffset(periods, tailZone, Offset.min), ComputeOffset(periods, tailZone, Offset.max));

  /// <summary>
  /// Initializes a new instance of the <see cref="PrecalculatedDateTimeZone"/> class.
  /// </summary>
  /// <param name="id">The id.</param>
  /// <param name="intervals">The intervals before the tail zone.</param>
  /// <param name="tailZone">The tail zone - which can be any IZoneIntervalMap for normal operation,
  /// but must be a StandardDaylightAlternatingMap if the result is to be serialized.</param>
  @visibleForTesting
  @internal
  factory PrecalculatedDateTimeZone(String id, List<ZoneInterval> intervals, IZoneIntervalMapWithMinMax tailZone) {
    // We want this to be AfterMaxValue for tail-less zones.
    var tailZoneStart = intervals[intervals.length - 1].RawEnd;
    // Cache a "clamped" zone interval for use at the start of the tail zone. (if (tailZone != null))
    var firstTailZoneInterval = tailZone?.GetZoneInterval(tailZoneStart)?.WithStart(tailZoneStart);
    ValidatePeriods(intervals, tailZone);

    return new PrecalculatedDateTimeZone._(id, intervals, tailZone, firstTailZoneInterval, tailZoneStart);
  }

/*
  this.id = Preconditions.checkNotNull(id, 'id'),
  this.isFixed = isFixed,
  this.minOffset = minOffset,
  this.maxOffset = maxOffset;
 */

  /// <summary>
  /// Validates that all the periods before the tail zone make sense. We have to start at the beginning of time,
  /// and then have adjoining periods. This is only called in the constructors.
  /// </summary>
  /// <remarks>This is only called from the constructors, but is @internal to make it easier to test.</remarks>
  /// <exception cref="ArgumentException">The periods specified are invalid.</exception>
  @internal static void ValidatePeriods(List<ZoneInterval> periods, IZoneIntervalMap tailZone) {
    Preconditions.checkArgument(periods.length > 0, 'periods', "No periods specified in precalculated time zone");
    Preconditions.checkArgument(!periods[0].HasStart, 'periods', "Periods in precalculated time zone must start with the beginning of time");
    for (int i = 0; i < periods.length - 1; i++) {
// Safe to use End here: there can't be a period *after* an endless one. Likewise it's safe to use Start on the next 
// period, as there can't be a period *before* one which goes back to the start of time.
      Preconditions.checkArgument(periods[i].end == periods[i + 1].start, 'periods', "Non-adjoining ZoneIntervals for precalculated time zone");
    }
    Preconditions.checkArgument(
        tailZone != null || periods[periods.length - 1].RawEnd == Instant.afterMaxValue, 'tailZone',
        "Null tail zone given but periods don't cover all of time");
  }

  /// <summary>
  /// Gets the zone offset period for the given instant.
  /// </summary>
  /// <param name="instant">The Instant to find.</param>
  /// <returns>The ZoneInterval including the given instant.</returns>
  @override ZoneInterval GetZoneInterval(Instant instant) {
    if (tailZone != null && instant >= tailZoneStart) {
      // Clamp the tail zone interval to start at the end of our final period, if necessary, so that the
      // join is seamless.
      ZoneInterval intervalFromTailZone = tailZone.GetZoneInterval(instant);
      return intervalFromTailZone.RawStart < tailZoneStart ? firstTailZoneInterval : intervalFromTailZone;
    }

    int lower = 0; // Inclusive
    int upper = periods.length; // Exclusive

    while (lower < upper) {
      int current = (lower + upper) ~/ 2;
      var candidate = periods[current];
      if (candidate.RawStart > instant) {
        upper = current;
      }
      // Safe to use RawEnd, as it's just for the comparison.
      else if (candidate.RawEnd <= instant) {
        lower = current + 1;
      }
      else {
        return candidate;
      }
    }
    // Note: this would indicate a bug. The time zone is meant to cover the whole of time.
    throw new StateError("Instant $instant did not exist in time zone $id");
  }

// #region I/O
  /// <summary>
  /// Writes the time zone to the specified writer.
  /// </summary>
  /// <param name="writer">The writer to write to.</param>
  @internal void Write(IDateTimeZoneWriter writer) {
    throw new UnimplementedError('This code will be different for Dart');
//Preconditions.checkNotNull(writer, 'writer');
//
//// We used to create a pool of strings just for this zone. This was more efficient
//// for some zones, as it meant that each String would be written out with just a single
//// byte after the pooling. Optimizing the String pool globally instead allows for
//// roughly the same efficiency, and simpler code here.
//writer.WriteCount(periods.Length);
//Instant previous = null;
//for (var period in periods)
//{
//writer.WriteZoneIntervalTransition(previous, (Instant) (previous = period.RawStart));
//writer.WriteString(period.Name);
//writer.WriteOffset(period.WallOffset);
//writer.WriteOffset(period.Savings);
//}
//writer.WriteZoneIntervalTransition(previous, tailZoneStart);
//// We could just check whether we've got to the end of the stream, but this
//// feels slightly safer.
//writer.WriteByte((byte) (tailZone == null ? 0 : 1));
//if (tailZone != null)
//{
//// This is the only kind of zone we support in the new format. Enforce that...
//var tailDstZone = tailZone as StandardDaylightAlternatingMap;
//tailDstZone.Write(writer);
//}
  }

  /// <summary>
  /// Reads a time zone from the specified reader.
  /// </summary>
  /// <param name="reader">The reader.</param>
  /// <param name="id">The id.</param>
  /// <returns>The time zone.</returns>
  @internal static DateTimeZone Read(DateTimeZoneReader reader, String id) {
    // todo: remove later -- but useful for now
    print('loading id = $id!');

    var periodsCount = reader.read7BitEncodedInt();
    if (periodsCount > 10000) throw new Exception('Parse error for id = $id. Too many periods. Count = $periodsCount.');
    var periods = new Iterable
        .generate(periodsCount)
        .map((i) => reader.readZoneInterval())
        .toList();

    var tailFlag = reader.readUint8();
    if (tailFlag == 1) {
      var tailZone = StandardDaylightAlternatingMap.Read(reader);
      return new PrecalculatedDateTimeZone(id, periods, tailZone);
    }
    return new PrecalculatedDateTimeZone(id, periods, null);
  }

// #endregion // I/O

// #region Offset computation for constructors

  // Reasonably simple way of computing the maximum/minimum offset
  // from either periods or transitions, with or without a tail zone.
  @private static Offset ComputeOffset(List<ZoneInterval> intervals, IZoneIntervalMapWithMinMax tailZone, _offsetAggregator aggregator) {
    Preconditions.checkNotNull(intervals, 'intervals');
    Preconditions.checkArgument(intervals.length > 0, 'intervals', "No intervals specified");
    Offset ret = intervals[0].wallOffset;
    for (int i = 1; i < intervals.length; i++) {
      ret = aggregator(ret, intervals[i].wallOffset);
    }
    if (tailZone != null) {
      // Effectively a shortcut for picking either tailZone.MinOffset or
      // tailZone.MaxOffset
      Offset bestFromZone = aggregator(tailZone.minOffset, tailZone.maxOffset);
      ret = aggregator(ret, bestFromZone);
    }
    return ret;
  }
// #endregion
}