// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeAdjusters.cs
// 24fdeef  on Apr 10, 2017

import 'package:meta/meta.dart';
import 'package:time_machine/time_machine.dart';

/// <summary>
/// Factory class for time adjusters: functions from [LocalTime] to <c>LocalTime</c>,
/// which can be applied to [LocalTime], <see cref="LocalDateTime"/>, and <see cref="OffsetDateTime"/>.
/// </summary>
@immutable
class TimeAdjusters {
  /// <summary>
  /// Gets a time adjuster to truncate the time to the second, discarding fractional seconds.
  /// </summary>
  /// <value>A time adjuster to truncate the time to the second, discarding fractional seconds.</value>
  static LocalTime Function(LocalTime) TruncateToSecond
  = (time) => new LocalTime(time.Hour, time.Minute, time.Second);

  /// <summary>
  /// Gets a time adjuster to truncate the time to the minute, discarding fractional minutes.
  /// </summary>
  /// <value>A time adjuster to truncate the time to the minute, discarding fractional minutes.</value>
  static LocalTime Function(LocalTime) TruncateToMinute
  = (time) => new LocalTime(time.Hour, time.Minute);

  /// <summary>
  /// Get a time adjuster to truncate the time to the hour, discarding fractional hours.
  /// </summary>
  /// <value>A time adjuster to truncate the time to the hour, discarding fractional hours.</value>
  static LocalTime Function(LocalTime) TruncateToHour
  = (time) => new LocalTime(time.Hour, 0);
}