// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

/// Exception thrown when data read by Time Machine (such as serialized time zone data) is invalid. This includes
/// data which is truncated, i.e. we expect more data than we can read.
class InvalidTimeDataError extends Error
{
  final String message;
  final Error? error;

  /// Creates an instance with the given message.
  ///
  /// [message]: The message for the exception.
  InvalidTimeDataError(this.message, [this.error]);

  @override String toString() => error == null ? '$message' : '$message\n$error';
}
