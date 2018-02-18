// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/SkippedTimeException.cs
// 0958802  on Jun 18, 2017

import 'package:time_machine/time_machine.dart';

/// <summary>
/// Exception thrown to indicate that the specified local time doesn't
/// exist in a particular time zone due to daylight saving time changes.
/// </summary>
/// <remarks>
/// <para>
/// This normally occurs for spring transitions, where the clock goes forward
/// (usually by an hour). For example, suppose the time zone goes forward
/// at 2am, so the second after 01:59:59 becomes 03:00:00. In that case,
/// local times such as 02:30:00 never occur.
/// </para>
/// <para>
/// This exception is used to indicate such problems, as they're usually
/// not the same as other <see cref="ArgumentOutOfRangeException" /> causes,
/// such as entering "15" for a month number.
/// </para>
/// <para>
/// Note that it is possible (though extremely rare) for a whole day to be skipped due to a time zone transition,
/// so this exception may also be thrown in cases where no local time is valid for a particular local date. (For
/// example, Samoa skipped December 30th 2011 entirely, transitioning from UTC-10 to UTC+14 at midnight.)
/// </para>
/// </remarks>
/// <threadsafety>Any static members of this type are thread safe. Any instance members are not guaranteed to be thread safe.
/// See the thread safety section of the user guide for more information.
/// </threadsafety>
class SkippedTimeError extends Error {
  /// <summary>
  /// Gets the local date/time which is invalid in the time zone, prompting this exception.
  /// </summary>
  /// <value>The local date/time which is invalid in the time zone.</value>
  final LocalDateTime localDateTime;

  /// <summary>
  /// Gets the time zone in which the local date/time is invalid.
  /// </summary>
  /// <value>The time zone in which the local date/time is invalid</value>
  final DateTimeZone zone;

  final String message;

  /// <summary>
  /// Creates a new instance for the given local date/time and time zone.
  /// </summary>
  /// <remarks>
  /// User code is unlikely to need to deliberately call this constructor except
  /// possibly for testing.
  /// </remarks>
  /// <param name="localDateTime">The local date/time which is skipped in the specified time zone.</param>
  /// <param name="zone">The time zone in which the local date/time does not exist.</param>
  SkippedTimeError(this.localDateTime, this.zone)
      : message = "Local time $localDateTime is invalid in time zone ${zone?.id ?? 'null'}";
}