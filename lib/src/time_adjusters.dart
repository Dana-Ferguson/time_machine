// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

/// Factory class for time adjusters: functions from [LocalTime] to [LocalTime],
/// which can be applied to [LocalTime], [LocalDateTime], and [OffsetDateTime].
@immutable
class TimeAdjusters {
  /// Gets a time adjuster to truncate the time to the second, discarding fractional seconds.
  static LocalTime Function(LocalTime) truncateToSecond = (time) => LocalTime(time.hourOfDay, time.minuteOfHour, time.secondOfMinute);

  /// Gets a time adjuster to truncate the time to the minute, discarding fractional minutes.
  static LocalTime Function(LocalTime) truncateToMinute = (time) => LocalTime(time.hourOfDay, time.minuteOfHour, 0);

  /// Get a time adjuster to truncate the time to the hour, discarding fractional hours.
  static LocalTime Function(LocalTime) truncateToHour = (time) => LocalTime(time.hourOfDay, 0, 0);
}
