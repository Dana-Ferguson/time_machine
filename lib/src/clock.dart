// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// https://github.com/nodatime/nodatime/blob/b9cc683a5071c6020ca2cc40907acbcf9017d498/src/NodaTime/Extensions/ClockExtensions.cs
// 0958802  on Jun 18, 2017

import 'dart:async';
import 'package:time_machine/src/time_machine_internal.dart';

// Represents a clock which can return the current time as an <see cref='Instant' />.
///
/// [IClock] is intended for use anywhere you need to have access to the current time.
/// Although it's not strictly incorrect to call `SystemClock.Instance.GetCurrentInstant()` directly,
/// in the same way as you might call [DateTime.UtcNow], it's strongly discouraged
/// as a matter of style for production code. We recommend providing an instance of [IClock]
/// to anything that needs it, which allows you to write tests using the fake clock in the TimeMachine.Testing
/// assembly (or your own implementation).
///
/// see also:
/// * [SystemClock]
/// * [FakeClock]
abstract class Clock
{
  /// Gets the current [Instant] on the time line according to this clock.
  /// Returns the current instant on the time line according to this clock.
  Instant getCurrentInstant();

// *** The below fields where originally extension methods ***
// *** They change this class from an Interface to implement, to a subclass to extend ***

  /// Constructs a [ZonedClock] from a clock (the target of the method),
  /// a time zone, and a calendar system.
  ///
  /// * [clock]: Clock to use in the returned object.
  /// * [zone]: Time zone to use in the returned object.
  /// * [calendar]: Calendar to use in the returned object.
  ///
  /// Returns: A [ZonedClock] with the given clock, time zone and calendar system.
  ZonedClock inZone(DateTimeZone zone, [CalendarSystem? calendar]) => ZonedClock(this, zone, calendar ?? CalendarSystem.iso);

  /// Constructs a [ZonedClock] from a clock (the target of the method),
  /// using the UTC time zone and ISO calendar system.
  ///
  /// * [clock]: Clock to use in the returned object.
  ///
  /// Returns: A [ZonedClock] with the given clock, in the UTC time zone and ISO calendar system.
  ZonedClock inUtc() => ZonedClock(this, DateTimeZone.utc, CalendarSystem.iso);

  // todo: rename inLocalZone?
  /// Constructs a [ZonedClock] from a clock (the target of the method),
  /// in the TZDB mapping for the system default time zone time zone and the ISO calendar system.
  ///
  /// * [clock]: Clock to use in the returned object.
  ///
  /// A `ZonedClock` in the system default time zone (using TZDB) and the ISO calendar system,
  /// using the system clock.
  ///
  /// * [DateTimeZoneNotFoundException]: The system default time zone is not mapped by
  ///
  /// see: [DateTimeZoneProviders.Tzdb]
  Future<ZonedClock> inTzdbSystemDefaultZone() async
  {
    var zone = await (await DateTimeZoneProviders.tzdb).getSystemDefault();
    return ZonedClock(this, zone, CalendarSystem.iso);
  }

  /// The default [Clock] is the [SystemClock] but can be changed by the user.
  /// This is used for [Instant.now]. Replacing this with [FakeClock] can be useful
  /// for testing.
  ///
  /// Library writers should not set this variable.
  static Clock current = SystemClock.instance;
}

