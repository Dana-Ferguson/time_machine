// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/SystemClock.cs
// 24fdeef  on Apr 10, 2017

import 'package:meta/meta.dart';
import 'package:time_machine/time_machine.dart';

/// <summary>
/// Singleton implementation of <see cref="IClock"/> which reads the current system time.
/// It is recommended that for anything other than throwaway code, this is only referenced
/// in a single place in your code: where you provide a value to inject into the rest of
/// your application, which should only depend on the interface.
/// </summary>
/// <threadsafety>This type has no state, and is thread-safe. See the thread safety section of the user guide for more information.</threadsafety>
@immutable
class SystemClock extends Clock {
  /// <summary>
  /// The singleton instance of [SystemClock].
  /// </summary>
  /// <value>The singleton instance of [SystemClock].</value>
  static final SystemClock instance = new SystemClock._();

  /// <summary>
  /// Constructor present to prevent external construction.
  /// </summary>
  SystemClock._();

  // note: this is extra allocations -- but this pipes to an external function -- so it's very convenient
  /// <summary>
  /// Gets the current time as an [Instant].
  /// </summary>
  /// <returns>The current time in ticks as an [Instant].</returns>
  Instant getCurrentInstant() => new Instant.fromDateTime(new DateTime.now());
}