// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/StandardDaylightAlternatingMap.cs
// 5aa91eb  on Apr 5, 2017

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

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

/// <summary>
/// Provides a zone interval map representing an infinite sequence of standard/daylight
/// transitions from a pair of rules.
/// </summary>
/// <remarks>
/// IMPORTANT: This class *accepts* recurrences which start from a particular year
/// rather than being infinite back to the start of time, but *treats* them as if
/// they were infinite. This makes various calculations easier, but this map should
/// only be used as part of a zone which will only ask it for values within the right
/// portion of the timeline.
/// </remarks>
@internal /*sealed*/ class StandardDaylightAlternatingMap implements IZoneIntervalMapWithMinMax // IEquatable<StandardDaylightAlternatingMap>
    {
  @private final Offset standardOffset;
  @private final ZoneRecurrence standardRecurrence;
  @private final ZoneRecurrence dstRecurrence;

  Offset get MinOffset => Offset.min(standardOffset, standardOffset + dstRecurrence.savings);

  Offset get MaxOffset => Offset.max(standardOffset, standardOffset + dstRecurrence.savings);

  StandardDaylightAlternatingMap._(this.standardOffset, this.standardRecurrence, this.dstRecurrence);

  /// <summary>
  /// Initializes a new instance of the <see cref="StandardDaylightAlternatingMap"/> class.
  /// </summary>
  /// <remarks>
  /// At least one of the recurrences (it doesn't matter which) must be a "standard", i.e. not have any savings
  /// applied. The other may still not have any savings (e.g. for America/Resolute) or (for BCL compatibility) may
  /// even have negative daylight savings.
  /// </remarks>
  /// <param name="standardOffset">The standard offset.</param>
  /// <param name="startRecurrence">The start recurrence.</param>
  /// <param name="endRecurrence">The end recurrence.</param>
  @internal factory StandardDaylightAlternatingMap(Offset standardOffset, ZoneRecurrence startRecurrence, ZoneRecurrence endRecurrence)
  {
    // Treat the recurrences as if they extended to the start of time.
    startRecurrence = startRecurrence.ToStartOfTime();
    endRecurrence = endRecurrence.ToStartOfTime();
    Preconditions.checkArgument(startRecurrence.isInfinite, 'startRecurrence', "Start recurrence must extend to the end of time");
    Preconditions.checkArgument(endRecurrence.isInfinite, 'endRecurrence', "End recurrence must extend to the end of time");
    var dst = startRecurrence;
    var standard = endRecurrence;
    if (startRecurrence.savings == Offset.zero) {
      dst = endRecurrence;
      standard = startRecurrence;
    }
    Preconditions.checkArgument(standard.savings == Offset.zero, 'startRecurrence', "At least one recurrence must not have savings applied");
    return new StandardDaylightAlternatingMap._(standardOffset, standard, dst);
  }

// @override bool Equals(dynamic other) => Equals(other as StandardDaylightAlternatingMap);

  bool Equals(StandardDaylightAlternatingMap other) =>
      other != null &&
          standardOffset == other.standardOffset &&
          dstRecurrence.Equals(other.dstRecurrence) &&
          standardRecurrence.Equals(other.standardRecurrence);

  @override int get hashCode => hash3(standardOffset, dstRecurrence, standardRecurrence);

  /// <summary>
  /// Gets the zone interval for the given instant.
  /// </summary>
  /// <param name="instant">The Instant to test.</param>
  /// <returns>The ZoneInterval in effect at the given instant.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The instant falls outside the bounds
  /// of the recurrence rules of the zone.</exception>
  ZoneInterval GetZoneInterval(Instant instant) {
    var result = NextTransition(instant);
    ZoneRecurrence recurrence = result.zoneRecurrence;
    var next = result.transition;

    // Now we know the recurrence we're in, we can work out when we went into it. (We'll never have
    // two transitions into the same recurrence in a row.)
    Offset previousSavings = ReferenceEquals(recurrence, standardRecurrence) ? dstRecurrence.savings : Offset.zero;
    var previous = recurrence.PreviousOrSameOrFail(instant, standardOffset, previousSavings);
    return new ZoneInterval(recurrence.name, previous.instant, next.instant, standardOffset + recurrence.savings, recurrence.savings);
  }

  /// <summary>
  /// Returns the transition occurring strictly after the specified instant. The <paramref name="recurrence"/>
  /// parameter will be populated with the recurrence the transition goes *from*.
  /// </summary>
  /// <param name="instant">The instant after which to consider transitions.</param>
  /// <param name="recurrence">Receives the savings offset for the transition.</param>
  @private _TransitionRecurrenceResult NextTransition(Instant instant) {
    // Both recurrences are infinite, so they'll both have next transitions (possibly at infinity).
    Transition dstTransition = dstRecurrence.NextOrFail(instant, standardOffset, Offset.zero);
    Transition standardTransition = standardRecurrence.NextOrFail(instant, standardOffset, dstRecurrence.savings);
    var standardTransitionInstant = standardTransition.instant;
    var dstTransitionInstant = dstTransition.instant;
    if (standardTransitionInstant < dstTransitionInstant) {
      // Next transition is from DST to standard.
      return new _TransitionRecurrenceResult(standardTransition, dstRecurrence);
    }
    else if (standardTransitionInstant > dstTransitionInstant) {
      // Next transition is from standard to DST.
      return new _TransitionRecurrenceResult(dstTransition, standardRecurrence);
    }
    else {
      // Okay, the transitions happen at the same time. If they're not at infinity, we're stumped.
      if (standardTransitionInstant.IsValid) {
        throw new StateError("Zone recurrence rules have identical transitions. This time zone is broken.");
      }
      // Okay, the two transitions must be to the end of time. Find which recurrence has the later *previous* transition...
      var previousDstTransition = dstRecurrence.PreviousOrSameOrFail(instant, standardOffset, Offset.zero);
      var previousStandardTransition = standardRecurrence.PreviousOrSameOrFail(instant, standardOffset, dstRecurrence.savings);
      // No point in checking for equality here... they can't go back from the end of time to the start...
      if (previousDstTransition.instant > previousStandardTransition.instant) {
        // The previous transition is from standard to DST. Therefore the next one is from DST to standard.
        return new _TransitionRecurrenceResult(standardTransition, dstRecurrence);
      }
      else {
        // The previous transition is from DST to standard. Therefore the next one is from standard to DST.
        return new _TransitionRecurrenceResult(dstTransition, standardRecurrence);
      }
    }
  }

  /// <summary>
  /// Writes the time zone to the specified writer.
  /// </summary>
  /// <param name="writer">The writer to write to.</param>
  @internal void Write(IDateTimeZoneWriter writer) {
    // We don't need everything a recurrence can supply: we know that both recurrences should be
    // infinite, and that only the DST recurrence should have savings.
    Preconditions.checkNotNull(writer, 'writer');
    writer.WriteOffset(standardOffset);
    writer.WriteString(standardRecurrence.name);
    standardRecurrence.yearOffset.Write(writer);
    writer.WriteString(dstRecurrence.name);
    dstRecurrence.yearOffset.Write(writer);
    writer.WriteOffset(dstRecurrence.savings);
  }

  @internal static StandardDaylightAlternatingMap Read(IDateTimeZoneReader reader) {
    Preconditions.checkNotNull(reader, 'reader');
    Offset standardOffset = reader.ReadOffset();
    String standardName = reader.ReadString();
    ZoneYearOffset standardYearOffset = ZoneYearOffset.Read(reader);
    String daylightName = reader.ReadString();
    ZoneYearOffset daylightYearOffset = ZoneYearOffset.Read(reader);
    Offset savings = reader.ReadOffset();
    ZoneRecurrence standardRecurrence = new ZoneRecurrence(standardName, Offset.zero, standardYearOffset, Utility.intMinValueJS, Utility.intMaxValueJS);
    ZoneRecurrence dstRecurrence = new ZoneRecurrence(daylightName, savings, daylightYearOffset, Utility.intMinValueJS, Utility.intMaxValueJS);
    return new StandardDaylightAlternatingMap(standardOffset, standardRecurrence, dstRecurrence);
  }
}