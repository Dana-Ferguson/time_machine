// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

/// Exception thrown when time zone is requested from an [IDateTimeZoneProvider],
/// but the specified ID is invalid for that provider.
///
/// This type only exists as `TimeZoneNotFoundException` doesn't exist in netstandard1.x.
/// By creating an exception which derives from `TimeZoneNotFoundException` on the desktop version
/// and `Exception` on the .NET Standard 1.3 version, we achieve reasonable consistency while remaining
/// backwardly compatible with Noda Time v1 (which was desktop-only, and threw `TimeZoneNotFoundException`).
// sealed
class DateTimeZoneNotFoundException extends Error {
  final String message;

  /// Creates an instance with the given message.
  ///
  /// [message]: The message for the exception.
  DateTimeZoneNotFoundException(this.message);

  @override toString() => message;
}
