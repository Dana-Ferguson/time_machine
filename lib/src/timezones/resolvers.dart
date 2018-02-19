// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/Resolvers.cs
// 9aa4e04  on Apr 14, 2017

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';


/// <summary>
/// Commonly-used implementations of the delegates used in resolving a <see cref="LocalDateTime"/> to a
/// <see cref="ZonedDateTime"/>, and a method to combine two "partial" resolvers into a full one.
/// </summary>
/// <remarks>
/// <para>
/// This class contains predefined implementations of <see cref="ZoneLocalMappingResolver"/>,
/// <see cref="AmbiguousTimeResolver"/>, and <see cref="SkippedTimeResolver"/>, along with
/// <see cref="CreateMappingResolver"/>, which produces a <c>ZoneLocalMappingResolver</c> from instances of the
/// other two.
/// </para>
/// </remarks>
/// <threadsafety>All members of this class are thread-safe, as are the values returned by them.</threadsafety>
abstract class Resolvers
{
  /// <summary>
  /// An <see cref="AmbiguousTimeResolver"/> which returns the earlier of the two matching times.
  /// </summary>
  /// <value>An <see cref="AmbiguousTimeResolver"/> which returns the earlier of the two matching times.</value>
  static final AmbiguousTimeResolver ReturnEarlier = (earlier, later) => earlier;

  /// <summary>
  /// An <see cref="AmbiguousTimeResolver"/> which returns the later of the two matching times.
  /// </summary>
  /// <value>An <see cref="AmbiguousTimeResolver"/> which returns the later of the two matching times.</value>
  static final AmbiguousTimeResolver ReturnLater = (earlier, later) => later;

  /// <summary>
  /// An <see cref="AmbiguousTimeResolver"/> which simply throws an <see cref="AmbiguousTimeException"/>.
  /// </summary>
  /// <value>An <see cref="AmbiguousTimeResolver"/> which simply throws an <see cref="AmbiguousTimeException"/>.</value>
  static final AmbiguousTimeResolver ThrowWhenAmbiguous = (earlier, later) => throw new AmbiguousTimeError(earlier, later);

  /// <summary>
  /// A <see cref="SkippedTimeResolver"/> which returns the final tick of the time zone interval
  /// before the "gap".
  /// </summary>
  /// <value>A <see cref="SkippedTimeResolver"/> which returns the final tick of the time zone interval
  /// before the "gap".</value>
  static final SkippedTimeResolver ReturnEndOfIntervalBefore = returnEndOfIntervalBefore;
  static ZonedDateTime returnEndOfIntervalBefore(LocalDateTime local, DateTimeZone zone, ZoneInterval before, ZoneInterval after) {
    Preconditions.checkNotNull(zone, 'zone');
    Preconditions.checkNotNull(before, 'before');
    Preconditions.checkNotNull(after, 'after');
    // Given that there's a zone after before, it can't extend to the end of time.
    return new ZonedDateTime.withCalendar(before.end - Span.epsilon, zone, local.Calendar);
  }

  /// <summary>
  /// A <see cref="SkippedTimeResolver"/> which returns the first tick of the time zone interval
  /// after the "gap".
  /// </summary>
  /// <value>
  /// A <see cref="SkippedTimeResolver"/> which returns the first tick of the time zone interval
  /// after the "gap".
  /// </value>
  static final SkippedTimeResolver ReturnStartOfIntervalAfter = returnStartOfIntervalAfter;
  static ZonedDateTime returnStartOfIntervalAfter(LocalDateTime local, DateTimeZone zone, ZoneInterval before, ZoneInterval after) {
    Preconditions.checkNotNull(zone, 'zone');
    Preconditions.checkNotNull(before, 'before');
    Preconditions.checkNotNull(after, 'after');
    return new ZonedDateTime.withCalendar(after.start, zone, local.Calendar);
  }

  /// <summary>
  /// A <see cref="SkippedTimeResolver"/> which shifts values in the "gap" forward by the duration
  /// of the gap (which is usually 1 hour). This corresponds to the instant that would have occured,
  /// had there not been a transition.
  /// </summary>
  /// <value>
  /// A <see cref="SkippedTimeResolver"/> which shifts values in the "gap" forward by the duration
  /// of the gap (which is usually 1 hour).
  /// </value>
  static final SkippedTimeResolver ReturnForwardShifted = returnForwardShifted;
  static ZonedDateTime returnForwardShifted(LocalDateTime local, DateTimeZone zone, ZoneInterval before, ZoneInterval after) {
    Preconditions.checkNotNull(zone, 'zone');
    Preconditions.checkNotNull(before, 'before');
    Preconditions.checkNotNull(after, 'after');
    return new ZonedDateTime(new OffsetDateTime(local, before.wallOffset).WithOffset(after.wallOffset), zone);
  }

  /// <summary>
  /// A <see cref="SkippedTimeResolver"/> which simply throws a <see cref="SkippedTimeException"/>.
  /// </summary>
  /// <value>A <see cref="SkippedTimeResolver"/> which simply throws a <see cref="SkippedTimeException"/>.</value>
  static final SkippedTimeResolver ThrowWhenSkipped = throwWhenSkipped;
  static ZonedDateTime throwWhenSkipped(LocalDateTime local, DateTimeZone zone, ZoneInterval before, ZoneInterval after) {
    Preconditions.checkNotNull(zone, 'zone');
    Preconditions.checkNotNull(before, 'before');
    Preconditions.checkNotNull(after, 'after');
    throw new SkippedTimeError(local, zone);
  }

  /// <summary>
  /// A <see cref="ZoneLocalMappingResolver"/> which only ever succeeds in the (usual) case where the result
  /// of the mapping is unambiguous.
  /// </summary>
  /// <remarks>
  /// If the mapping is ambiguous or skipped, this throws <see cref="SkippedTimeException"/> or
  /// <see cref="AmbiguousTimeException"/>, as appropriate. This resolver combines
  /// <see cref="ThrowWhenAmbiguous"/> and <see cref="ThrowWhenSkipped"/>.
  /// </remarks>
  /// <seealso cref="DateTimeZone.AtStrictly"/>
  /// <value>A <see cref="ZoneLocalMappingResolver"/> which only ever succeeds in the (usual) case where the result
  /// of the mapping is unambiguous.</value>
  static final ZoneLocalMappingResolver StrictResolver = CreateMappingResolver(ThrowWhenAmbiguous, ThrowWhenSkipped);

  /// <summary>
  /// A <see cref="ZoneLocalMappingResolver"/> which never throws an exception due to ambiguity or skipped time.
  /// </summary>
  /// <remarks>
  /// Ambiguity is handled by returning the earlier occurrence, and skipped times are shifted forward by the duration
  /// of the gap. This resolver combines <see cref="ReturnEarlier"/> and <see cref="ReturnForwardShifted"/>.
  /// <para>Note: The behavior of this resolver was changed in version 2.0 to fit the most commonly seen real-world
  /// usage pattern.  Previous versions combined the <see cref="ReturnLater"/> and <see cref="ReturnStartOfIntervalAfter"/>
  /// resolvers, which can still be used separately if desired.</para>
  /// </remarks>
  /// <seealso cref="DateTimeZone.AtLeniently"/>
  /// <value>A <see cref="ZoneLocalMappingResolver"/> which never throws an exception due to ambiguity or skipped time.</value>
  static final ZoneLocalMappingResolver LenientResolver = CreateMappingResolver(ReturnEarlier, ReturnForwardShifted);

  /// <summary>
  /// Combines an <see cref="AmbiguousTimeResolver"/> and a <see cref="SkippedTimeResolver"/> to create a
  /// <see cref="ZoneLocalMappingResolver"/>.
  /// </summary>
  /// <remarks>
  /// The <c>ZoneLocalMappingResolver</c> created by this method operates in the obvious way: unambiguous mappings
  /// are returned directly, ambiguous mappings are delegated to the given <c>AmbiguousTimeResolver</c>, and
  /// "skipped" mappings are delegated to the given <c>SkippedTimeResolver</c>.
  /// </remarks>
  /// <param name="ambiguousTimeResolver">Resolver to use for ambiguous mappings.</param>
  /// <param name="skippedTimeResolver">Resolver to use for "skipped" mappings.</param>
  /// <returns>The logical combination of the two resolvers.</returns>
  static ZoneLocalMappingResolver CreateMappingResolver(AmbiguousTimeResolver ambiguousTimeResolver, SkippedTimeResolver skippedTimeResolver) {
    // typedef ZonedDateTime ZoneLocalMappingResolver(ZoneLocalMapping mapping);
    Preconditions.checkNotNull(ambiguousTimeResolver, 'ambiguousTimeResolver');
    Preconditions.checkNotNull(skippedTimeResolver, 'skippedTimeResolver');

    ZonedDateTime mappingResolve(ZoneLocalMapping mapping) {
      Preconditions.checkNotNull(mapping, 'mapping');
      switch (mapping.length) {
        case 0:
          return skippedTimeResolver(mapping.LocalDateTime, mapping.Zone, mapping.EarlyInterval, mapping.LateInterval);
        case 1:
          return mapping.First();
        case 2:
          return ambiguousTimeResolver(mapping.First(), mapping.Last());
        default:
          throw new StateError("Mapping has count outside range 0-2; should not happen.");
      }
    }

    return mappingResolve;
  }
}