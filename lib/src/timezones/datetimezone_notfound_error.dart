// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

/// Exception thrown when time zone is requested from an [IDateTimeZoneProvider],
/// but the specified ID is invalid for that provider.
class DateTimeZoneNotFoundError extends Error {
  final String message;

  /// Creates an instance with the given message.
  ///
  /// [message]: The message for the exception.
  DateTimeZoneNotFoundError(this.message);

  @override String toString() => message;
}
