// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
// import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

class _TransitionRecurrenceResult {
  final Transition transition;
  final ZoneRecurrence zoneRecurrence;
  _TransitionRecurrenceResult(this.transition, this.zoneRecurrence);
}

// Reader notes, 2017-04-05:
// - It's not clear that this really needs to be standard/daylight - it could just be two arbitrary recurrences
//   with the same standard offset. Knowing which one is standard avoids one memory access (for the offset) in
//   many occurrences, but we could potentially optimize this in other ways anyway.
//
// - The comment around America/Resolute was added on July 20th 2011. The TZDB release at the time was 2011h.
//   From https://github.com/eggert/tz/blob/338ff27740c38fcef26920c9dbd776c09768eb3b/northamerica
//     Rule    Resolute 2006	max	-	Nov	Sun>=1	2:00	0	ES
//     Rule    Resolute 2007	max	-	Mar Sun>=8	2:00	0	CD
//   We probably still want to be able to consume 2011h later, so let's not remove that functionality.

/// Provides a zone interval map representing an infinite sequence of standard/daylight
/// transitions from a pair of rules.
///
/// IMPORTANT: This class *accepts* recurrences which start from a particular year
/// rather than being infinite back to the start of time, but *treats* them as if
/// they were infinite. This makes various calculations easier, but this map should
/// only be used as part of a zone which will only ask it for values within the right
/// portion of the timeline.
@immutable
@internal
class StandardDaylightAlternatingMap implements ZoneIntervalMapWithMinMax  {
  final Offset _standardOffset;
  final ZoneRecurrence _standardRecurrence;
  final ZoneRecurrence _dstRecurrence;

  @override
  Offset get minOffset => Offset.min(_standardOffset, _standardOffset + _dstRecurrence.savings);

  @override
  Offset get maxOffset => Offset.max(_standardOffset, _standardOffset + _dstRecurrence.savings);

  const StandardDaylightAlternatingMap._(this._standardOffset, this._standardRecurrence, this._dstRecurrence);

  /// Initializes a new instance of the [StandardDaylightAlternatingMap] class.
  ///
  /// At least one of the recurrences (it doesn't matter which) must be a "standard", i.e. not have any savings
  /// applied. The other may still not have any savings (e.g. for America/Resolute) or (for BCL compatibility) may
  /// even have negative daylight savings.
  ///
  /// [standardOffset]: The standard offset.
  /// [startRecurrence]: The start recurrence.
  /// [endRecurrence]: The end recurrence.
  factory StandardDaylightAlternatingMap(Offset standardOffset, ZoneRecurrence startRecurrence, ZoneRecurrence endRecurrence)
  {
    // Treat the recurrences as if they extended to the start of time.
    startRecurrence = startRecurrence.toStartOfTime();
    endRecurrence = endRecurrence.toStartOfTime();
    Preconditions.checkArgument(startRecurrence.isInfinite, 'startRecurrence', "Start recurrence must extend to the end of time");
    Preconditions.checkArgument(endRecurrence.isInfinite, 'endRecurrence', "End recurrence must extend to the end of time");
    var dst = startRecurrence;
    var standard = endRecurrence;
    if (startRecurrence.savings == Offset.zero) {
      dst = endRecurrence;
      standard = startRecurrence;
    }
    Preconditions.checkArgument(standard.savings == Offset.zero, 'startRecurrence', "At least one recurrence must not have savings applied");
    return StandardDaylightAlternatingMap._(standardOffset, standard, dst);
  }

  bool equals(StandardDaylightAlternatingMap other) =>
          _standardOffset == other._standardOffset &&
          _dstRecurrence.equals(other._dstRecurrence) &&
          _standardRecurrence.equals(other._standardRecurrence);

  @override
  bool operator==(Object other) => other is StandardDaylightAlternatingMap && equals(other);

  @override int get hashCode => hash3(_standardOffset, _dstRecurrence, _standardRecurrence);

  /// Gets the zone interval for the given instant.
  ///
  /// [instant]: The Instant to test.
  /// Returns: The ZoneInterval in effect at the given instant.
  /// [ArgumentOutOfRangeException]: The instant falls outside the bounds
  /// of the recurrence rules of the zone.
  @override
  ZoneInterval getZoneInterval(Instant instant) {
    var result = _nextTransition(instant);
    ZoneRecurrence recurrence = result.zoneRecurrence;
    var next = result.transition;

    // Now we know the recurrence we're in, we can work out when we went into it. (We'll never have
    // two transitions into the same recurrence in a row.)
    Offset previousSavings = identical(recurrence, _standardRecurrence) ? _dstRecurrence.savings : Offset.zero;
    var previous = recurrence.previousOrSameOrFail(instant, _standardOffset, previousSavings);
    return IZoneInterval.newZoneInterval(recurrence.name, previous.instant, next.instant, _standardOffset + recurrence.savings, recurrence.savings);
  }

  /// Returns the transition occurring strictly after the specified instant. The [_recurrence]
  /// parameter will be populated with the recurrence the transition goes *from*.
  ///
  /// [instant]: The instant after which to consider transitions.
  /// [recurrence]: Receives the savings offset for the transition.
  _TransitionRecurrenceResult _nextTransition(Instant instant) {
    // Both recurrences are infinite, so they'll both have next transitions (possibly at infinity).
    Transition dstTransition = _dstRecurrence.nextOrFail(instant, _standardOffset, Offset.zero);
    Transition standardTransition = _standardRecurrence.nextOrFail(instant, _standardOffset, _dstRecurrence.savings);
    var standardTransitionInstant = standardTransition.instant;
    var dstTransitionInstant = dstTransition.instant;
    if (standardTransitionInstant < dstTransitionInstant) {
      // Next transition is from DST to standard.
      return _TransitionRecurrenceResult(standardTransition, _dstRecurrence);
    }
    else if (standardTransitionInstant > dstTransitionInstant) {
      // Next transition is from standard to DST.
      return _TransitionRecurrenceResult(dstTransition, _standardRecurrence);
    }
    else {
      // Okay, the transitions happen at the same time. If they're not at infinity, we're stumped.
      if (standardTransitionInstant.isValid) {
        throw StateError('Zone recurrence rules have identical transitions. This time zone is broken.');
      }
      // Okay, the two transitions must be to the end of time. Find which recurrence has the later *previous* transition...
      var previousDstTransition = _dstRecurrence.previousOrSameOrFail(instant, _standardOffset, Offset.zero);
      var previousStandardTransition = _standardRecurrence.previousOrSameOrFail(instant, _standardOffset, _dstRecurrence.savings);
      // No point in checking for equality here... they can't go back from the end of time to the start...
      if (previousDstTransition.instant > previousStandardTransition.instant) {
        // The previous transition is from standard to DST. Therefore the next one is from DST to standard.
        return _TransitionRecurrenceResult(standardTransition, _dstRecurrence);
      }
      else {
        // The previous transition is from DST to standard. Therefore the next one is from standard to DST.
        return _TransitionRecurrenceResult(dstTransition, _standardRecurrence);
      }
    }
  }

  /// Writes the time zone to the specified writer.
  ///
  /// [writer]: The writer to write to.
  void write(IDateTimeZoneWriter writer) {
    Preconditions.checkNotNull(writer, 'writer');
    writer.writeOffsetSeconds2(_standardOffset); // Offset.fromSeconds(reader.readInt32());
    _standardRecurrence.write(writer);
    _dstRecurrence.write(writer);

    // We don't need everything a recurrence can supply: we know that both recurrences should be
    // infinite, and that only the DST recurrence should have savings.
    //    Preconditions.checkNotNull(writer, 'writer');
    //    writer.WriteOffset(standardOffset);
    //    writer.WriteString(standardRecurrence.name);
    //    standardRecurrence.yearOffset.Write(writer);
    //    writer.WriteString(dstRecurrence.name);
    //    dstRecurrence.yearOffset.Write(writer);
    //    writer.WriteOffset(dstRecurrence.savings);
  }

  static StandardDaylightAlternatingMap read(DateTimeZoneReader reader) {
    Preconditions.checkNotNull(reader, 'reader');
    var standardOffset = reader.readOffsetSeconds2(); // Offset.fromSeconds(reader.readInt32());
    var standardRecurrence = ZoneRecurrence.read(reader);
    var dstRecurrence = ZoneRecurrence.read(reader);

    return StandardDaylightAlternatingMap(standardOffset, standardRecurrence, dstRecurrence);

    // Offset standardOffset = reader.ReadOffset();
    //    String standardName = reader.ReadString();
    //    ZoneYearOffset standardYearOffset = ZoneYearOffset.Read(reader);
    //    String daylightName = reader.ReadString();
    //    ZoneYearOffset daylightYearOffset = ZoneYearOffset.Read(reader);
    //    Offset savings = reader.ReadOffset();
    //    ZoneRecurrence standardRecurrence = new ZoneRecurrence(standardName, Offset.zero, standardYearOffset, Utility.int32MinValue, Utility.int32MaxValue);
    //    ZoneRecurrence dstRecurrence = new ZoneRecurrence(daylightName, savings, daylightYearOffset, Utility.int32MinValue, Utility.int32MaxValue);
    //    return new StandardDaylightAlternatingMap(standardOffset, standardRecurrence, dstRecurrence);
  }
}
