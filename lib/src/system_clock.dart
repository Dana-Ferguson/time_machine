// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/time_machine.dart';

/// Singleton implementation of [IClock] which reads the current system time.
/// It is recommended that for anything other than throwaway code, this is only referenced
/// in a single place in your code: where you provide a value to inject into the rest of
/// your application, which should only depend on the interface.
///
/// <threadsafety>This type has no state, and is thread-safe. See the thread safety section of the user guide for more information.</threadsafety>
@immutable
class SystemClock extends Clock {
  /// The singleton instance of [SystemClock].
  static final SystemClock instance = new SystemClock._();

  /// Constructor present to prevent external construction.
  SystemClock._();

  // note: this is extra allocations -- but this pipes to an external function -- so it's very convenient
  /// Gets the current time as an [Instant].
  ///
  /// Returns: The current time in ticks as an [Instant].
  Instant getCurrentInstant() => new Instant.fromDateTime(new DateTime.now());
}
