// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/IClock.cs
// a209e60  on Mar 18, 2015

import 'package:time_machine/time_machine.dart';

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
}