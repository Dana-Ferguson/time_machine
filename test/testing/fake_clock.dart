// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Testing/FakeClock.cs
// 9b8ed83  on Aug 24, 2017

import 'dart:async';
import 'dart:math' as math;

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import '../time_machine_testing.dart';

/// <summary>
/// Clock which can be constructed with an initial instant, and then advanced programmatically (and optionally,
/// automatically advanced on each read).
/// This class is designed to be used when testing classes which take an <see cref="IClock"/> as a dependency.
/// </summary>
/// <remarks>
/// This class is somewhere between a fake and a stub, depending on how it's used - if it's set to
/// <see cref="AutoAdvance"/> then time will pass, but in a pretty odd way (i.e. dependent on how
/// often it's consulted).
/// </remarks>
/// <threadsafety>
/// This type is thread-safe, primarily in order to allow <see cref="IClock"/> to be documented as
/// "thread safe in all built-in implementations".
/// </threadsafety>
class FakeClock extends Clock {
// private readonly object mutex = new object();
  Instant _now;
  Span _autoAdvance = Span.zero;

  /// <summary>
  /// Creates a fake clock initially set to the given instant. The clock will advance by the given duration on
  /// each read.
  /// </summary>
  /// <param name="initial">The initial instant.</param>
  /// <param name="autoAdvance">The duration to advance the clock on each read.</param>
  /// <seealso cref="AutoAdvance"/>
  FakeClock(Instant initial, [Span autoAdvance = Span.zero]) {
    _now = initial;
    this._autoAdvance = autoAdvance;
  }

  /// <summary>
  /// Returns a fake clock initially set to the given year/month/day/time in UTC in the ISO calendar.
  /// The value of the <see cref="AutoAdvance"/> property will be initialised to zero.
  /// </summary>
  /// <param name="year">The year. This is the "absolute year",
  /// so a value of 0 means 1 BC, for example.</param>
  /// <param name="monthOfYear">The month of year.</param>
  /// <param name="dayOfMonth">The day of month.</param>
  /// <param name="hourOfDay">The hour.</param>
  /// <param name="minuteOfHour">The minute.</param>
  /// <param name="secondOfMinute">The second.</param>
  /// <returns>A <see cref="FakeClock"/> initialised to the given instant, with no auto-advance.</returns>
  static FakeClock FromUtc(int year, int monthOfYear, int dayOfMonth, [int hourOfDay = 0, int minuteOfHour = 0, int secondOfMinute = 0]) {
    return new FakeClock(new Instant.fromUtc(year, monthOfYear, dayOfMonth, hourOfDay, minuteOfHour, secondOfMinute));
  }

  /// <summary>
  /// Advances the clock by the given duration.
  /// </summary>
  /// <param name="duration">The duration to advance the clock by (or if negative, the duration to move it back
  /// by).</param>
  void Advance(Span duration) {
//lock (mutex)
    {
      _now += duration;
    }
  }

  /// <summary>
  /// Advances the clock by the given number of nanoseconds.
  /// </summary>
  /// <param name="nanoseconds">The number of nanoseconds to advance the clock by (or if negative, the number to move it back
  /// by).</param>
  void AdvanceNanoseconds(int nanoseconds) => Advance(new Span(nanoseconds: nanoseconds));

  /// <summary>
  /// Advances the clock by the given number of ticks.
  /// </summary>
  /// <param name="ticks">The number of ticks to advance the clock by (or if negative, the number to move it back
  /// by).</param>
  void AdvanceTicks(int ticks) => Advance(new Span(ticks: ticks));

  /// <summary>
  /// Advances the clock by the given number of milliseconds.
  /// </summary>
  /// <param name="milliseconds">The number of milliseconds to advance the clock by (or if negative, the number
  /// to move it back by).</param>
  void AdvanceMilliseconds(int milliseconds) => Advance(new Span(milliseconds: milliseconds));

  /// <summary>
  /// Advances the clock by the given number of seconds.
  /// </summary>
  /// <param name="seconds">The number of seconds to advance the clock by (or if negative, the number to move it
  /// back by).</param>
  void AdvanceSeconds(int seconds) => Advance(new Span(seconds: seconds));

  /// <summary>
  /// Advances the clock by the given number of minutes.
  /// </summary>
  /// <param name="minutes">The number of minutes to advance the clock by (or if negative, the number to move it
  /// back by).</param>
  void AdvanceMinutes(int minutes) => Advance(new Span(minutes: minutes));

  /// <summary>
  /// Advances the clock by the given number of hours.
  /// </summary>
  /// <param name="hours">The number of hours to advance the clock by (or if negative, the number to move it
  /// back by).</param>
  void AdvanceHours(int hours) => Advance(new Span(hours: hours));

  /// <summary>
  /// Advances the clock by the given number of standard (24-hour) days.
  /// </summary>
  /// <param name="days">The number of days to advance the clock by (or if negative, the number to move it
  /// back by).</param>
  void AdvanceDays(int days) => Advance(new Span(days: days));

  /// <summary>
  /// Resets the clock to the given instant.
  /// The value of the <see cref="AutoAdvance"/> property will be unchanged.
  /// </summary>
  /// <param name="instant">The instant to set the clock to.</param>
  void Reset(Instant instant) {
// lock (mutex)
    {
      _now = instant;
    }
  }

  /// <summary>
  /// Returns the "current time" for this clock. Unlike a normal clock, this
  /// property may return the same value from repeated calls until one of the methods
  /// to change the time is called.
  /// </summary>
  /// <remarks>
  /// If the value of the <see cref="AutoAdvance"/> property is non-zero, then every
  /// call to this method will advance the current time by that value.
  /// </remarks>
  /// <returns>The "current time" from this (fake) clock.</returns>
  Instant getCurrentInstant() {
// lock (mutex)
    {
      Instant then = _now;
      _now += _autoAdvance;
      return then;
    }
  }

  /// <summary>
  /// Gets the amount of time to advance the clock by on each call to read the current time.
  /// </summary>
  /// <remarks>
  /// <para>
  /// This defaults to zero, with the exception of the <see cref="FakeClock(Instant, Duration)"/> constructor,
  /// which takes the initial value directly.  If this is zero, the current time as reported by this clock will
  /// not change other than by calls to <see cref="Reset"/> or to one of the <see cref="Advance"/> methods.
  /// </para>
  /// <para>
  /// The value could even be negative, to simulate particularly odd system clock effects.
  /// </para>
  /// </remarks>
  /// <seealso cref="GetCurrentInstant"/>
  /// <value>The amount of time to advance the clock by on each call to read the current time.</value>
  Span get AutoAdvance => _autoAdvance;

  void set AutoAdvance(Span value) => _autoAdvance = value;
}
