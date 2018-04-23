// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Testing/TimeZones/SingleTransitionDateTimeZone.cs
// b9ee218  on Dec 22, 2016

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_timezones.dart';

/// <summary>
/// Time zone with a single transition between two offsets. This provides a simple way to test behaviour across a transition.
/// </summary>
class SingleTransitionDateTimeZone extends DateTimeZone {
  /// <summary>
  /// Gets the <see cref="ZoneInterval"/> for the period before the transition, starting at the beginning of time.
  /// </summary>
  /// <value>The zone interval for the period before the transition, starting at the beginning of time.</value>
  final ZoneInterval EarlyInterval;

  /// <summary>
  /// Gets the <see cref="ZoneInterval"/> for the period after the transition, ending at the end of time.
  /// </summary>
  /// <value>The zone interval for the period after the transition, ending at the end of time.</value>
  final ZoneInterval LateInterval;

  /// <summary>
  /// Gets the transition instant of the zone.
  /// </summary>
  /// <value>The transition instant of the zone.</value>
  Instant get Transition => EarlyInterval.end;

  /// <summary>
  /// Creates a zone with a single transition between two offsets.
  /// </summary>
  /// <param name="transitionPoint">The transition point as an <see cref="Instant"/>.</param>
  /// <param name="offsetBeforeHours">The offset of local time from UTC, in hours, before the transition.</param>
  /// <param name="offsetAfterHours">The offset of local time from UTC, in hours, before the transition.</param>
  SingleTransitionDateTimeZone.around(Instant transitionPoint, int offsetBeforeHours, int offsetAfterHours)
      : this(transitionPoint, new Offset.fromHours(offsetBeforeHours), new Offset.fromHours(offsetAfterHours));

  /// <summary>
  /// Creates a zone with a single transition between two offsets.
  /// </summary>
  /// <param name="transitionPoint">The transition point as an <see cref="Instant"/>.</param>
  /// <param name="offsetBefore">The offset of local time from UTC before the transition.</param>
  /// <param name="offsetAfter">The offset of local time from UTC before the transition.</param>
  SingleTransitionDateTimeZone(Instant transitionPoint, Offset offsetBefore, Offset offsetAfter)
      : this.withId(transitionPoint, offsetBefore, offsetAfter, "Single");

  /// <summary>
  /// Creates a zone with a single transition between two offsets.
  /// </summary>
  /// <param name="transitionPoint">The transition point as an <see cref="Instant"/>.</param>
  /// <param name="offsetBefore">The offset of local time from UTC before the transition.</param>
  /// <param name="offsetAfter">The offset of local time from UTC before the transition.</param>
  /// <param name="id">ID for the newly created time zone.</param>
  SingleTransitionDateTimeZone.withId(Instant transitionPoint, Offset offsetBefore, Offset offsetAfter, String id)
      : EarlyInterval = new ZoneInterval(id + "-Early", null, transitionPoint, offsetBefore, Offset.zero),
        LateInterval = new ZoneInterval(id + "-Late", transitionPoint, null, offsetAfter, Offset.zero),
        super(id, false, Offset.min(offsetBefore, offsetAfter), Offset. max(offsetBefore, offsetAfter));

  /// <inheritdoc />
  /// <remarks>
  /// This returns either the zone interval before or after the transition, based on the instant provided.
  /// </remarks>
  @override ZoneInterval GetZoneInterval(Instant instant) => EarlyInterval.Contains(instant) ? EarlyInterval : LateInterval;
}