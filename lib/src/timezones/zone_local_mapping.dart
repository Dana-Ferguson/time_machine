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

// Note: documentation that refers to the LocalDateTime type within this class must use the fully-qualified
// reference to avoid being resolved to the LocalDateTime property instead.

/// The result of mapping a [LocalDateTime] within a time zone, i.e. finding out
/// at what "global" time the "local" time occurred.
///
/// This class is used as the return type of [DateTimeZone.MapLocal]. It allows for
/// finely-grained handling of the three possible results:
///
/// <list type="bullet">
///   <item>
///     <term>Unambiguous mapping</term>
///     <description>The local time occurs exactly once in the target time zone.</description>
///   </item>
///   <item>
///     <term>Ambiguous mapping</term>
///     <description>
///       The local time occurs twice in the target time zone, due to the offset from UTC
///       changing. This usually occurs for an autumnal daylight saving transition, where the clocks
///       are put back by an hour. If the clocks change from 2am to 1am for example, then 1:30am occurs
///       twice - once before the transition and once afterwards.
///     </description>
///   </item>
///   <item>
///     <term>Impossible mapping</term>
///     <description>
///       The local time does not occur at all in the target time zone, due to the offset from UTC
///       changing. This usually occurs for a vernal (spring-time) daylight saving transition, where the clocks
///       are put forward by an hour. If the clocks change from 1am to 2am for example, then 1:30am is
///       skipped entirely.
///     </description>
///   </item>
/// </list>
///
/// <threadsafety>This type is an immutable reference type. See the thread safety section of the user guide for more information.</threadsafety>
@immutable
/*sealed*/ class ZoneLocalMapping {
  /// Gets the [DateTimeZone] in which this mapping was performed.
  final DateTimeZone Zone;

  /// Gets the [LocalDateTime] which was mapped within the time zone.
  final LocalDateTime localDateTime;

  /// Gets the earlier [ZoneInterval] within this mapping.
  ///
  /// For unambiguous mappings, this is the same as [LateInterval]; for ambiguous mappings,
  /// this is the interval during which the mapped local time first occurs; for impossible
  /// mappings, this is the interval before which the mapped local time occurs.
  final ZoneInterval EarlyInterval;

  /// Gets the later [ZoneInterval] within this mapping.
  ///
  /// For unambiguous
  /// mappings, this is the same as [EarlyInterval]; for ambiguous mappings,
  /// this is the interval during which the mapped local time last occurs; for impossible
  /// mappings, this is the interval after which the mapped local time occurs.
  final ZoneInterval LateInterval;

  /// Gets the number of results within this mapping: the number of distinct
  /// [ZonedDateTime] values which map to the original [LocalDateTime].
  ///
  /// <value>The number of results within this mapping: the number of distinct values which map to the
  /// original local date and time.</value>
  final int Count;

  @internal ZoneLocalMapping(this.Zone, this.localDateTime, this.EarlyInterval, this.LateInterval, this.Count) {
    Preconditions.debugCheckNotNull(Zone, 'zone');
    Preconditions.debugCheckNotNull(EarlyInterval, 'earlyInterval');
    Preconditions.debugCheckNotNull(LateInterval, 'lateInterval');
    Preconditions.debugCheckArgumentRange('count', Count, 0, 2);
  }

  /// Returns the single [ZonedDateTime] which maps to the original
  /// [LocalDateTime] in the mapped [DateTimeZone].
  ///
  /// [SkippedTimeException]: The local date/time was skipped in the time zone.
  /// [AmbiguousTimeException]: The local date/time was ambiguous in the time zone.
  /// Returns: The unambiguous result of mapping the local date/time in the time zone.
  ZonedDateTime Single() {
    switch (Count) {
      case 0:
        throw new SkippedTimeError(localDateTime, Zone);
      case 1:
        return BuildZonedDateTime(EarlyInterval);
      case 2:
        throw new AmbiguousTimeError(
            BuildZonedDateTime(EarlyInterval),
            BuildZonedDateTime(LateInterval));
      default:
        throw new StateError("Can't happen");
    }
  }

  /// Returns a [ZonedDateTime] which maps to the original [LocalDateTime]
  /// in the mapped [DateTimeZone]: either the single result if the mapping is unambiguous,
  /// or the earlier result if the local date/time occurs twice in the time zone due to a time zone
  /// offset change such as an autumnal daylight saving transition.
  ///
  /// [SkippedTimeException]: The local date/time was skipped in the time zone.
  /// Returns: The unambiguous result of mapping a local date/time in a time zone.
  ZonedDateTime First() {
    switch (Count) {
      case 0:
        throw new SkippedTimeError(localDateTime, Zone);
      case 1:
      case 2:
        return BuildZonedDateTime(EarlyInterval);
      default:
        throw new StateError("Can't happen");
    }
  }

  /// Returns a [ZonedDateTime] which maps to the original [LocalDateTime]
  /// in the mapped [DateTimeZone]: either the single result if the mapping is unambiguous,
  /// or the later result if the local date/time occurs twice in the time zone due to a time zone
  /// offset change such as an autumnal daylight saving transition.
  ///
  /// [SkippedTimeException]: The local date/time was skipped in the time zone.
  /// Returns: The unambiguous result of mapping a local date/time in a time zone.
  ZonedDateTime Last() {
    switch (Count) {
      case 0:
        throw new SkippedTimeError(localDateTime, Zone);
      case 1:
        return BuildZonedDateTime(EarlyInterval);
      case 2:
        return BuildZonedDateTime(LateInterval);
      default:
        throw new StateError("Can't happen");
    }
  }

  @private ZonedDateTime BuildZonedDateTime(ZoneInterval interval) =>
      new ZonedDateTime.trusted(localDateTime.WithOffset(interval.wallOffset), Zone);
}
