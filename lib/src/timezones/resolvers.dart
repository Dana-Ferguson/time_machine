// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

/// Commonly-used implementations of the delegates used in resolving a [LocalDateTime] to a
/// [ZonedDateTime], and a method to combine two 'partial' resolvers into a full one.
///
/// This class contains predefined implementations of [ZoneLocalMappingResolver],
/// [AmbiguousTimeResolver], and [SkippedTimeResolver], along with
/// [createMappingResolver], which produces a `ZoneLocalMappingResolver` from instances of the
/// other two.
abstract class Resolvers
{
  /// An [AmbiguousTimeResolver] which returns the earlier of the two matching times.
  static final AmbiguousTimeResolver returnEarlier = (earlier, later) => earlier;

  /// An [AmbiguousTimeResolver] which returns the later of the two matching times.
  static final AmbiguousTimeResolver returnLater = (earlier, later) => later;

  /// An [AmbiguousTimeResolver] which simply throws an [AmbiguousTimeException].
  static final AmbiguousTimeResolver throwWhenAmbiguous = (earlier, later) => throw AmbiguousTimeError(earlier, later);

  /// A [SkippedTimeResolver] which returns the final tick of the time zone interval
  /// before the 'gap'.
  ///
  /// <value>A [SkippedTimeResolver] which returns the final tick of the time zone interval
  /// before the 'gap'.</value>
  static final SkippedTimeResolver returnEndOfIntervalBefore = (LocalDateTime local, DateTimeZone zone, ZoneInterval before, ZoneInterval after) {
    Preconditions.checkNotNull(zone, 'zone');
    Preconditions.checkNotNull(before, 'before');
    Preconditions.checkNotNull(after, 'after');
    // Given that there's a zone after before, it can't extend to the end of time.
    return ZonedDateTime(before.end - Time.epsilon, zone, local.calendar);
  };

  /// A [SkippedTimeResolver] which returns the first tick of the time zone interval
  /// after the 'gap'.
  ///
  /// <value>
  /// A [SkippedTimeResolver] which returns the first tick of the time zone interval
  /// after the 'gap'.
  /// </value>
  static final SkippedTimeResolver returnStartOfIntervalAfter = (LocalDateTime local, DateTimeZone zone, ZoneInterval before, ZoneInterval after) {
    Preconditions.checkNotNull(zone, 'zone');
    Preconditions.checkNotNull(before, 'before');
    Preconditions.checkNotNull(after, 'after');
    return ZonedDateTime(after.start, zone, local.calendar);
  };

  /// A [SkippedTimeResolver] which shifts values in the 'gap' forward by the duration
  /// of the gap (which is usually 1 hour). This corresponds to the instant that would have occured,
  /// had there not been a transition.
  ///
  /// <value>
  /// A [SkippedTimeResolver] which shifts values in the 'gap' forward by the duration
  /// of the gap (which is usually 1 hour).
  /// </value>
  static final SkippedTimeResolver returnForwardShifted = (LocalDateTime local, DateTimeZone zone, ZoneInterval before, ZoneInterval after) {
    Preconditions.checkNotNull(zone, 'zone');
    Preconditions.checkNotNull(before, 'before');
    Preconditions.checkNotNull(after, 'after');
    return IZonedDateTime.trusted(OffsetDateTime(local, before.wallOffset).withOffset(after.wallOffset), zone);
  };

  /// A [SkippedTimeResolver] which simply throws a [SkippedTimeException].
  static final SkippedTimeResolver throwWhenSkipped = (LocalDateTime local, DateTimeZone zone, ZoneInterval before, ZoneInterval after) {
    Preconditions.checkNotNull(zone, 'zone');
    Preconditions.checkNotNull(before, 'before');
    Preconditions.checkNotNull(after, 'after');
    throw SkippedTimeError(local, zone);
  };

  /// A [ZoneLocalMappingResolver] which only ever succeeds in the (usual) case where the result
  /// of the mapping is unambiguous.
  ///
  /// If the mapping is ambiguous or skipped, this throws [SkippedTimeException] or
  /// [AmbiguousTimeException], as appropriate. This resolver combines
  /// [throwWhenAmbiguous] and [throwWhenSkipped].
  ///
  /// <seealso cref='DateTimeZone.AtStrictly'/>
  /// <value>A [ZoneLocalMappingResolver] which only ever succeeds in the (usual) case where the result
  /// of the mapping is unambiguous.</value>
  static final ZoneLocalMappingResolver strictResolver = createMappingResolver(throwWhenAmbiguous, throwWhenSkipped);

  /// A [ZoneLocalMappingResolver] which never throws an exception due to ambiguity or skipped time.
  ///
  /// Ambiguity is handled by returning the earlier occurrence, and skipped times are shifted forward by the duration
  /// of the gap. This resolver combines [returnEarlier] and [returnForwardShifted].
  /// Note: The behavior of this resolver was changed in version 2.0 to fit the most commonly seen real-world
  /// usage pattern.  Previous versions combined the [returnLater] and [returnStartOfIntervalAfter]
  /// resolvers, which can still be used separately if desired.
  ///
  /// <seealso cref='DateTimeZone.AtLeniently'/>
  static final ZoneLocalMappingResolver lenientResolver = createMappingResolver(returnEarlier, returnForwardShifted);

  /// Combines an [ambiguousTimeResolver] and a [SkippedTimeResolver] to create a
  /// [ZoneLocalMappingResolver].
  ///
  /// The `ZoneLocalMappingResolver` created by this method operates in the obvious way: unambiguous mappings
  /// are returned directly, ambiguous mappings are delegated to the given `AmbiguousTimeResolver`, and
  /// 'skipped' mappings are delegated to the given `SkippedTimeResolver`.
  ///
  /// [ambiguousTimeResolver]: Resolver to use for ambiguous mappings.
  /// [skippedTimeResolver]: Resolver to use for 'skipped' mappings.
  /// Returns: The logical combination of the two resolvers.
  static ZoneLocalMappingResolver createMappingResolver(AmbiguousTimeResolver ambiguousTimeResolver, SkippedTimeResolver skippedTimeResolver) {
    // typedef ZoneLocalMappingResolver = ZonedDateTime Function(ZoneLocalMapping mapping);
    Preconditions.checkNotNull(ambiguousTimeResolver, 'ambiguousTimeResolver');
    Preconditions.checkNotNull(skippedTimeResolver, 'skippedTimeResolver');

    ZonedDateTime mappingResolve(ZoneLocalMapping mapping) {
      Preconditions.checkNotNull(mapping, 'mapping');
      switch (mapping.count) {
        case 0:
          return skippedTimeResolver(mapping.localDateTime, mapping.zone, mapping.earlyInterval, mapping.lateInterval);
        case 1:
          return mapping.first();
        case 2:
          return ambiguousTimeResolver(mapping.first(), mapping.last());
        default:
          throw StateError('Mapping has count outside range 0-2; should not happen.');
      }
    }

    return mappingResolve;
  }
}
