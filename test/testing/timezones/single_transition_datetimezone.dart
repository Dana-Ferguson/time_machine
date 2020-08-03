// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

/// Time zone with a single transition between two offsets. This provides a simple way to test behaviour across a transition.
class SingleTransitionDateTimeZone extends DateTimeZone {
  /// Gets the [ZoneInterval] for the period before the transition, starting at the beginning of time.
  final ZoneInterval EarlyInterval;

  /// Gets the [ZoneInterval] for the period after the transition, ending at the end of time.
  final ZoneInterval LateInterval;

  /// Gets the transition instant of the zone.
  Instant get Transition => EarlyInterval.end;

  /// Creates a zone with a single transition between two offsets.
  ///
  /// [transitionPoint]: The transition point as an [Instant].
  /// [offsetBeforeHours]: The offset of local time from UTC, in hours, before the transition.
  /// [offsetAfterHours]: The offset of local time from UTC, in hours, before the transition.
  SingleTransitionDateTimeZone.around(Instant transitionPoint, int offsetBeforeHours, int offsetAfterHours)
      : this(transitionPoint, Offset.hours(offsetBeforeHours), Offset.hours(offsetAfterHours));

  /// Creates a zone with a single transition between two offsets.
  ///
  /// [transitionPoint]: The transition point as an [Instant].
  /// [offsetBefore]: The offset of local time from UTC before the transition.
  /// [offsetAfter]: The offset of local time from UTC before the transition.
  SingleTransitionDateTimeZone(Instant transitionPoint, Offset offsetBefore, Offset offsetAfter)
      : this.withId(transitionPoint, offsetBefore, offsetAfter, 'Single');

  /// Creates a zone with a single transition between two offsets.
  ///
  /// [transitionPoint]: The transition point as an [Instant].
  /// [offsetBefore]: The offset of local time from UTC before the transition.
  /// [offsetAfter]: The offset of local time from UTC before the transition.
  /// [id]: ID for the newly created time zone.
  SingleTransitionDateTimeZone.withId(Instant transitionPoint, Offset offsetBefore, Offset offsetAfter, String id)
      : EarlyInterval = IZoneInterval.newZoneInterval(id + '-Early', null, transitionPoint, offsetBefore, Offset.zero),
        LateInterval = IZoneInterval.newZoneInterval(id + '-Late', transitionPoint, null, offsetAfter, Offset.zero),
        super(id, false, Offset.min(offsetBefore, offsetAfter), Offset. max(offsetBefore, offsetAfter));

  /// <inheritdoc />
  ///
  /// This returns either the zone interval before or after the transition, based on the instant provided.
  @override ZoneInterval getZoneInterval(Instant instant) => EarlyInterval.contains(instant) ? EarlyInterval : LateInterval;
}
