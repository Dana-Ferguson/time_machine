// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

// Essentially Func<Offset, Offset, Offset>
typedef _offsetAggregator = Offset Function(Offset x, Offset y);
// typedef _offsetExtractor = Offset Function</*todo:in*/T>(T input);

/// Most time zones have a relatively small set of transitions at their start until they finally
/// settle down to either a fixed time zone or a daylight savings time zone. This provides the
/// container for the initial zone intervals and a pointer to the time zone that handles all of
/// the rest until the end of time.
@immutable // todo: we need immutable lists?
@internal
class PrecalculatedDateTimeZone extends DateTimeZone {
  final List<ZoneInterval> _periods;
  final ZoneIntervalMapWithMinMax? _tailZone;

  /// The first instant covered by the tail zone, or Instant.AfterMaxValue if there's no tail zone.
  final Instant _tailZoneStart;
  final ZoneInterval? _firstTailZoneInterval;

  PrecalculatedDateTimeZone._(String id, this._periods, this._tailZone, this._firstTailZoneInterval, this._tailZoneStart)
      : super(id, false, _computeOffset(_periods, _tailZone, Offset.min), _computeOffset(_periods, _tailZone, Offset.max));

  /// Initializes a new instance of the [PrecalculatedDateTimeZone] class.
  ///
  /// [id]: The id.
  /// [intervals]: The intervals before the tail zone.
  /// [tailZone]: The tail zone - which can be any IZoneIntervalMap for normal operation,
  /// but must be a StandardDaylightAlternatingMap if the result is to be serialized.
  // @visibleForTesting
  factory PrecalculatedDateTimeZone(String id, List<ZoneInterval> intervals, ZoneIntervalMapWithMinMax? tailZone) {
    // We want this to be AfterMaxValue for tail-less zones.
    var tailZoneStart = IZoneInterval.rawEnd(intervals[intervals.length - 1]);
    // Cache a 'clamped' zone interval for use at the start of the tail zone. (if (tailZone != null))
    var firstTailZoneInterval = IZoneInterval.withStart(tailZone?.getZoneInterval(tailZoneStart), tailZoneStart);
    validatePeriods(intervals, tailZone);

    return PrecalculatedDateTimeZone._(id, intervals, tailZone, firstTailZoneInterval, tailZoneStart);
  }

/*
  this.id = Preconditions.checkNotNull(id, 'id'),
  this.isFixed = isFixed,
  this.minOffset = minOffset,
  this.maxOffset = maxOffset;
 */

  /// Validates that all the periods before the tail zone make sense. We have to start at the beginning of time,
  /// and then have adjoining periods. This is only called in the constructors.
  ///
  /// This is only called from the constructors, but is @internal to make it easier to test.
  /// [ArgumentException]: The periods specified are invalid.
  static void validatePeriods(List<ZoneInterval> periods, ZoneIntervalMap? tailZone) {
    Preconditions.checkArgument(periods.isNotEmpty, 'periods', "No periods specified in precalculated time zone");
    Preconditions.checkArgument(!periods[0].hasStart, 'periods', "Periods in precalculated time zone must start with the beginning of time");
    for (int i = 0; i < periods.length - 1; i++) {
      // Safe to use End here: there can't be a period *after* an endless one. Likewise it's safe to use Start on the next
      // period, as there can't be a period *before* one which goes back to the start of time.
      Preconditions.checkArgument(periods[i].end == periods[i + 1].start, 'periods', "Non-adjoining ZoneIntervals for precalculated time zone");
    }
    Preconditions.checkArgument(
        tailZone != null || IZoneInterval.rawEnd(periods[periods.length - 1]) == IInstant.afterMaxValue, 'tailZone',
        "Null tail zone given but periods don't cover all of time");
  }

  /// Gets the zone offset period for the given instant.
  ///
  /// [instant]: The Instant to find.
  /// Returns: The ZoneInterval including the given instant.
  @override ZoneInterval getZoneInterval(Instant instant) {
    if (_tailZone != null && instant >= _tailZoneStart) {
      // Clamp the tail zone interval to start at the end of our final period, if necessary, so that the
      // join is seamless.
      ZoneInterval intervalFromTailZone = _tailZone!.getZoneInterval(instant);
      return IZoneInterval.rawStart(intervalFromTailZone) < _tailZoneStart ? _firstTailZoneInterval! : intervalFromTailZone;
    }

    int lower = 0; // Inclusive
    int upper = _periods.length; // Exclusive

    while (lower < upper) {
      int current = (lower + upper) ~/ 2;
      var candidate = _periods[current];
      if (IZoneInterval.rawStart(candidate) > instant) {
        upper = current;
      }
      // Safe to use RawEnd, as it's just for the comparison.
      else if (IZoneInterval.rawEnd(candidate) <= instant) {
        lower = current + 1;
      }
      else {
        return candidate;
      }
    }
    // Note: this would indicate a bug. The time zone is meant to cover the whole of time.
    throw StateError('Instant $instant did not exist in time zone $id');
  }

  // #region I/O
  /// Writes the time zone to the specified writer.
  ///
  /// [writer]: The writer to write to.
  void write(IDateTimeZoneWriter writer) {
    Preconditions.checkNotNull(writer, 'writer');

    writer.write7BitEncodedInt(_periods.length);
    for (var period in _periods) {
      writer.writeZoneInterval(period);
    }

    writer.writeUint8(_tailZone == null ? 0 : 1);
    if (_tailZone != null)
    {
      // This is the only kind of zone we support in the new format. Enforce that...
      var tailDstZone = _tailZone as StandardDaylightAlternatingMap;
      tailDstZone.write(writer);
    }

    /*
    // We used to create a pool of strings just for this zone. This was more efficient
    // for some zones, as it meant that each String would be written out with just a single
    // byte after the pooling. Optimizing the String pool globally instead allows for
    // roughly the same efficiency, and simpler code here.
    Instant previous;
    for (var period in _periods)
    {
    writer.WriteZoneIntervalTransition(previous, (Instant) (previous = period.RawStart));
    writer.WriteString(period.Name);
    writer.WriteOffset(period.WallOffset);
    writer.WriteOffset(period.Savings);
    }
    writer.WriteZoneIntervalTransition(previous, tailZoneStart);
    // We could just check whether we've got to the end of the stream, but this
    // feels slightly safer.
    writer.WriteByte((byte) (tailZone == null ? 0 : 1));
    if (tailZone != null)
    {
    // This is the only kind of zone we support in the new format. Enforce that...
    var tailDstZone = tailZone as StandardDaylightAlternatingMap;
    tailDstZone.Write(writer);
    }*/
  }

  /// Reads a time zone from the specified reader.
  ///
  /// [reader]: The reader.
  /// [id]: The id.
  /// Returns: The time zone.
  static DateTimeZone read(DateTimeZoneReader reader, String id) {
    var periodsCount = reader.read7BitEncodedInt();
    if (periodsCount > 10000) throw Exception('Parse error for id = $id. Too many periods. Count = $periodsCount.');
    var periods = Iterable
        .generate(periodsCount)
        .map((i) => reader.readZoneInterval())
        .toList();

    var tailFlag = reader.readUint8();
    if (tailFlag == 1) {
      var tailZone = StandardDaylightAlternatingMap.read(reader);
      return PrecalculatedDateTimeZone(id, periods, tailZone);
    }
    return PrecalculatedDateTimeZone(id, periods, null);
  }

  /// Reasonably simple way of computing the maximum/minimum offset
  /// from either periods or transitions, with or without a tail zone.
  static Offset _computeOffset(List<ZoneInterval> intervals, ZoneIntervalMapWithMinMax? tailZone, _offsetAggregator aggregator) {
    Preconditions.checkNotNull(intervals, 'intervals');
    Preconditions.checkArgument(intervals.isNotEmpty, 'intervals', "No intervals specified");
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
}
