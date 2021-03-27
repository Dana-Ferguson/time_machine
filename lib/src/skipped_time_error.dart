// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';

/// Exception thrown to indicate that the specified local time doesn't
/// exist in a particular time zone due to daylight saving time changes.
///
/// This normally occurs for spring transitions, where the clock goes forward
/// (usually by an hour). For example, suppose the time zone goes forward
/// at 2am, so the second after 01:59:59 becomes 03:00:00. In that case,
/// local times such as 02:30:00 never occur.
///
/// This exception is used to indicate such problems, as they're usually
/// not the same as other [RangeError] causes,
/// such as entering '15' for a month number.
///
/// Note that it is possible (though extremely rare) for a whole day to be skipped due to a time zone transition,
/// so this exception may also be thrown in cases where no local time is valid for a particular local date. (For
/// example, Samoa skipped December 30th 2011 entirely, transitioning from UTC-10 to UTC+14 at midnight.)
class SkippedTimeError extends Error {
  /// Gets the local date/time which is invalid in the time zone, prompting this exception.
  final LocalDateTime localDateTime;

  /// Gets the time zone in which the local date/time is invalid.
  final DateTimeZone zone;

  final String message;

  /// Creates a new instance for the given local date/time and time zone.
  ///
  /// User code is unlikely to need to deliberately call this constructor except
  /// possibly for testing.
  ///
  /// * [localDateTime]: The local date/time which is skipped in the specified time zone.
  /// * [zone]: The time zone in which the local date/time does not exist.
  SkippedTimeError(this.localDateTime, this.zone)
      : message = "Local time $localDateTime is invalid in time zone ${zone.id}";
}
