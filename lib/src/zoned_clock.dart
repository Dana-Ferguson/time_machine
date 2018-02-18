// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/ZonedClock.cs
// a209e60  on Mar 18, 2015

import 'package:meta/meta.dart';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';

/// A clock with an associated time zone and calendar. This is effectively a convenience
/// class decorating an [Clock].
@immutable
class ZonedClock extends Clock {
  final Clock _clock;
  final DateTimeZone _zone;
  final CalendarSystem _calendar;

  /// <summary>
  /// Creates a new <see cref="ZonedClock"/> with the given clock, time zone and calendar system.
  /// </summary>
  /// <param name="clock">Clock to use to obtain instants.</param>
  /// <param name="zone">Time zone to adjust instants into.</param>
  /// <param name="calendar">Calendar system to use.</param>
  ZonedClock(this._clock, this._zone, this._calendar) {
    Preconditions.checkNotNull(_clock, 'clock');
    Preconditions.checkNotNull(_zone, 'zone');
    Preconditions.checkNotNull(_calendar, 'calendar');
  }

  /// <summary>
  /// Returns the current instant provided by the underlying clock.
  /// </summary>
  /// <returns>The current instant provided by the underlying clock.</returns>
  Instant getCurrentInstant() => _clock.getCurrentInstant();

  /// <summary>
  /// Returns the current instant provided by the underlying clock, adjusted
  /// to the time zone of this object.
  /// </summary>
  /// <returns>The current instant provided by the underlying clock, adjusted to the
  /// time zone of this object.</returns>
  ZonedDateTime getCurrentZonedDateTime() => getCurrentInstant().InZone_Calendar(_zone, _calendar);

  /// <summary>
  /// Returns the local date/time of the current instant provided by the underlying clock, adjusted
  /// to the time zone of this object.
  /// </summary>
  /// <returns>The local date/time of the current instant provided by the underlying clock, adjusted to the
  /// time zone of this object.</returns>
  LocalDateTime getCurrentLocalDateTime() => getCurrentZonedDateTime().LocalDateTime;

  /// <summary>
  /// Returns the offset date/time of the current instant provided by the underlying clock, adjusted
  /// to the time zone of this object.
  /// </summary>
  /// <returns>The offset date/time of the current instant provided by the underlying clock, adjusted to the
  /// time zone of this object.</returns>
  OffsetDateTime getCurrentOffsetDateTime() => getCurrentZonedDateTime().ToOffsetDateTime();

  /// <summary>
  /// Returns the local date of the current instant provided by the underlying clock, adjusted
  /// to the time zone of this object.
  /// </summary>
  /// <returns>The local date of the current instant provided by the underlying clock, adjusted to the
  /// time zone of this object.</returns>
  LocalDate getCurrentDate() => getCurrentZonedDateTime().Date;

  /// <summary>
  /// Returns the local time of the current instant provided by the underlying clock, adjusted
  /// to the time zone of this object.
  /// </summary>
  /// <returns>The local time of the current instant provided by the underlying clock, adjusted to the
  /// time zone of this object.</returns>
  LocalTime getCurrentTimeOfDay() => getCurrentZonedDateTime().TimeOfDay;
}