// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/IClock.cs
// a209e60  on Mar 18, 2015

// https://github.com/nodatime/nodatime/blob/b9cc683a5071c6020ca2cc40907acbcf9017d498/src/NodaTime/Extensions/ClockExtensions.cs
// 0958802  on Jun 18, 2017

import 'dart:async';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_timezones.dart';

// Represents a clock which can return the current time as an <see cref="Instant" />.
/// <remarks>
/// <see cref="IClock"/> is intended for use anywhere you need to have access to the current time.
/// Although it's not strictly incorrect to call <c>SystemClock.Instance.GetCurrentInstant()</c> directly,
/// in the same way as you might call <see cref="DateTime.UtcNow"/>, it's strongly discouraged
/// as a matter of style for production code. We recommend providing an instance of <see cref="IClock"/>
/// to anything that needs it, which allows you to write tests using the fake clock in the NodaTime.Testing
/// assembly (or your own implementation).
/// </remarks>
/// <seealso cref="SystemClock"/>
/// <seealso cref="T:NodaTime.Testing.FakeClock"/>
abstract class Clock
{
  /// Gets the current <see cref="Instant"/> on the time line according to this clock.
  /// Returns the current instant on the time line according to this clock.
  Instant getCurrentInstant();

  // *** The below fields where originally extension methods ***
  // *** They change this class from an Interface to implement, to a subclass to extend ***

  /// <summary>
  /// Constructs a <see cref="ZonedClock"/> from a clock (the target of the method),
  /// a time zone, and a calendar system.
  /// </summary>
  /// <param name="clock">Clock to use in the returned object.</param>
  /// <param name="zone">Time zone to use in the returned object.</param>
  /// <param name="calendar">Calendar to use in the returned object.</param>
  /// <returns>A <see cref="ZonedClock"/> with the given clock, time zone and calendar system.</returns>
  ZonedClock InZone(DateTimeZone zone, [CalendarSystem calendar = null]) => new ZonedClock(this, zone, calendar ?? CalendarSystem.Iso);

  /// <summary>
  /// Constructs a <see cref="ZonedClock"/> from a clock (the target of the method),
  /// using the UTC time zone and ISO calendar system.
  /// </summary>
  /// <param name="clock">Clock to use in the returned object.</param>
  /// <returns>A <see cref="ZonedClock"/> with the given clock, in the UTC time zone and ISO calendar system.</returns>
  ZonedClock InUtc() => new ZonedClock(this, DateTimeZone.Utc, CalendarSystem.Iso);

  /// <summary>
  /// Constructs a <see cref="ZonedClock"/> from a clock (the target of the method),
  /// in the TZDB mapping for the system default time zone time zone and the ISO calendar system.
  /// </summary>
  /// <param name="clock">Clock to use in the returned object.</param>
  /// <returns>A <c>ZonedClock</c> in the system default time zone (using TZDB) and the ISO calendar system,
  /// using the system clock.</returns>
  /// <exception cref="DateTimeZoneNotFoundException">The system default time zone is not mapped by
  /// TZDB.</exception>
  /// <seealso cref="DateTimeZoneProviders.Tzdb"/>
  Future<ZonedClock> InTzdbSystemDefaultZone() async
  {
    var zone = await (await DateTimeZoneProviders.Tzdb).GetSystemDefault();
    return new ZonedClock(this, zone, CalendarSystem.Iso);
  }
}
