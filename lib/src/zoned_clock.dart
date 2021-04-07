// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';

/// A clock with an associated time zone and calendar. This is effectively a convenience
/// class decorating an [Clock].
@immutable
class ZonedClock extends Clock {
  final Clock _clock;
  final DateTimeZone _zone;
  final CalendarSystem _calendar;

  /// Creates a new [ZonedClock] with the given clock, time zone and calendar system.
  ///
  /// * [clock]: Clock to use to obtain instants.
  /// * [zone]: Time zone to adjust instants into.
  /// * [calendar]: Calendar system to use.
  ZonedClock(this._clock, this._zone, this._calendar) {
    Preconditions.checkNotNull(_clock, 'clock');
    Preconditions.checkNotNull(_zone, 'zone');
    Preconditions.checkNotNull(_calendar, 'calendar');
  }

  /// Returns the current instant provided by the underlying clock.
  @override
  Instant getCurrentInstant() => _clock.getCurrentInstant();

  /// Returns the current instant provided by the underlying clock, adjusted
  /// to the time zone of this object.
  ///
  /// The current instant provided by the underlying clock, adjusted to the
  /// time zone of this object.
  ZonedDateTime getCurrentZonedDateTime() => getCurrentInstant().inZone(_zone, _calendar);

  /// Returns the local date/time of the current instant provided by the underlying clock, adjusted
  /// to the time zone of this object.
  ///
  /// The local date/time of the current instant provided by the underlying clock, adjusted to the
  /// time zone of this object.
  LocalDateTime getCurrentLocalDateTime() => getCurrentZonedDateTime().localDateTime;

  /// Returns the offset date/time of the current instant provided by the underlying clock, adjusted
  /// to the time zone of this object.
  ///
  /// The offset date/time of the current instant provided by the underlying clock, adjusted to the
  /// time zone of this object.
  OffsetDateTime getCurrentOffsetDateTime() => getCurrentZonedDateTime().toOffsetDateTime();

  /// Returns the local date of the current instant provided by the underlying clock, adjusted
  /// to the time zone of this object.
  ///
  /// The local date of the current instant provided by the underlying clock, adjusted to the
  /// time zone of this object.
  LocalDate getCurrentDate() => getCurrentZonedDateTime().calendarDate;

  /// Returns the local time of the current instant provided by the underlying clock, adjusted
  /// to the time zone of this object.
  ///
  /// The local time of the current instant provided by the underlying clock, adjusted to the
  /// time zone of this object.
  LocalTime getCurrentTimeOfDay() => getCurrentZonedDateTime().clockTime;
}
