// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
/// Exception thrown to indicate that a time zone source has violated the contract of [IDateTimeZoneSource].
/// This exception is primarily intended to be thrown from [DateTimeZoneCache], and only in the face of a buggy
/// source; user code should not usually need to be aware of this or catch it.
// sealed
class InvalidDateTimeZoneSourceError extends Error
{
  final String message;

  /// Creates a new instance with the given message.
  ///
  /// [message]: The message for the exception.
  InvalidDateTimeZoneSourceError(this.message);

  @override String toString() => message;
}
