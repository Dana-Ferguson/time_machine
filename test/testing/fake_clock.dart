// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';

/// Clock which can be constructed with an initial instant, and then advanced programmatically (and optionally,
/// automatically advanced on each read).
/// This class is designed to be used when testing classes which take an [IClock] as a dependency.
///
/// This class is somewhere between a fake and a stub, depending on how it's used - if it's set to
/// [AutoAdvance] then time will pass, but in a pretty odd way (i.e. dependent on how
/// often it's consulted).
class FakeClock extends Clock {
  // private readonly object mutex = new object();
  late Instant _now;
  Time _autoAdvance = Time.zero;

  /// Creates a fake clock initially set to the given instant. The clock will advance by the given duration on
  /// each read.
  ///
  /// [initial]: The initial instant.
  /// [autoAdvance]: The duration to advance the clock on each read.
  /// <seealso cref='AutoAdvance'/>
  FakeClock(Instant initial, [Time autoAdvance = Time.zero]) {
    _now = initial;
    autoAdvance = autoAdvance;
  }

  /// Returns a fake clock initially set to the given year/month/day/time in UTC in the ISO calendar.
  /// The value of the [AutoAdvance] property will be initialised to zero.
  ///
  /// [year]: The year. This is the 'absolute year',
  /// so a value of 0 means 1 BC, for example.
  /// [monthOfYear]: The month of year.
  /// [dayOfMonth]: The day of month.
  /// [hourOfDay]: The hour.
  /// [minuteOfHour]: The minute.
  /// [secondOfMinute]: The second.
  /// Returns: A [FakeClock] initialised to the given instant, with no auto-advance.
  static FakeClock FromUtc(int year, int monthOfYear, int dayOfMonth, [int hourOfDay = 0, int minuteOfHour = 0, int secondOfMinute = 0]) {
    return FakeClock(Instant.utc(year, monthOfYear, dayOfMonth, hourOfDay, minuteOfHour, secondOfMinute));
  }

  /// Advances the clock by the given duration.
  ///
  /// [duration]: The duration to advance the clock by (or if negative, the duration to move it back
  /// by).
  void Advance(Time duration) {
    //lock (mutex)
    {
      _now += duration;
    }
  }

  /// Advances the clock by the given number of nanoseconds.
  ///
  /// [nanoseconds]: The number of nanoseconds to advance the clock by (or if negative, the number to move it back
  /// by).
  void AdvanceNanoseconds(int nanoseconds) => Advance(Time(nanoseconds: nanoseconds));

  /// Advances the clock by the given number of ticks.
  ///
  /// [ticks]: The number of ticks to advance the clock by (or if negative, the number to move it back
  /// by).
  void AdvanceTicks(int ticks) => Advance(Time(microseconds: ticks));

  /// Advances the clock by the given number of milliseconds.
  ///
  /// [milliseconds]: The number of milliseconds to advance the clock by (or if negative, the number
  /// to move it back by).
  void AdvanceMilliseconds(int milliseconds) => Advance(Time(milliseconds: milliseconds));

  /// Advances the clock by the given number of seconds.
  ///
  /// [seconds]: The number of seconds to advance the clock by (or if negative, the number to move it
  /// back by).
  void AdvanceSeconds(int seconds) => Advance(Time(seconds: seconds));

  /// Advances the clock by the given number of minutes.
  ///
  /// [minutes]: The number of minutes to advance the clock by (or if negative, the number to move it
  /// back by).
  void AdvanceMinutes(int minutes) => Advance(Time(minutes: minutes));

  /// Advances the clock by the given number of hours.
  ///
  /// [hours]: The number of hours to advance the clock by (or if negative, the number to move it
  /// back by).
  void AdvanceHours(int hours) => Advance(Time(hours: hours));

  /// Advances the clock by the given number of standard (24-hour) days.
  ///
  /// [days]: The number of days to advance the clock by (or if negative, the number to move it
  /// back by).
  void AdvanceDays(int days) => Advance(Time(days: days));

  /// Resets the clock to the given instant.
  /// The value of the [AutoAdvance] property will be unchanged.
  ///
  /// [instant]: The instant to set the clock to.
  void Reset(Instant instant) {
    // lock (mutex)
    {
      _now = instant;
    }
  }

  /// Returns the 'current time' for this clock. Unlike a normal clock, this
  /// property may return the same value from repeated calls until one of the methods
  /// to change the time is called.
  ///
  /// If the value of the [AutoAdvance] property is non-zero, then every
  /// call to this method will advance the current time by that value.
  ///
  /// Returns: The 'current time' from this (fake) clock.
  @override
  Instant getCurrentInstant() {
    // lock (mutex)
    {
      Instant then = _now;
      _now += _autoAdvance;
      return then;
    }
  }

  /// Gets the amount of time to advance the clock by on each call to read the current time.
  ///
  /// This defaults to zero, with the exception of the [FakeClock(Instant, Duration)] constructor,
  /// which takes the initial value directly.  If this is zero, the current time as reported by this clock will
  /// not change other than by calls to [Reset] or to one of the [Advance] methods.
  ///
  /// The value could even be negative, to simulate particularly odd system clock effects.
  ///
  /// <seealso cref='GetCurrentInstant'/>
  // ignore: unnecessary_getters_setters
  Time get AutoAdvance => _autoAdvance;

  // ignore: unnecessary_getters_setters
  set AutoAdvance(Time value) => _autoAdvance = value;
}

