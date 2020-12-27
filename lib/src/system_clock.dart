// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

/// Singleton implementation of [Clock] which reads the current system time.
/// It is recommended that for anything other than throwaway code, this is only referenced
/// in a single place in your code: where you provide a value to inject into the rest of
/// your application, which should only depend on the interface.
@immutable
class SystemClock extends Clock {
  /// The singleton instance of [SystemClock].
  static final SystemClock instance = SystemClock._();

  /// Constructor present to prevent external construction.
  SystemClock._();

  /// Gets the current time as an [Instant].
  @override
  Instant getCurrentInstant() => Instant.dateTime(DateTime.now());
}
