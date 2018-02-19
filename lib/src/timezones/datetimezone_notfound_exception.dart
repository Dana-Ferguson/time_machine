// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/DateTimeZoneNotFoundException.cs
// a667237  on Jul 4, 2017

/// <summary>
/// Exception thrown when time zone is requested from an <see cref="IDateTimeZoneProvider"/>,
/// but the specified ID is invalid for that provider.
/// </summary>
/// <remarks>
/// This type only exists as <c>TimeZoneNotFoundException</c> doesn't exist in netstandard1.x.
/// By creating an exception which derives from <c>TimeZoneNotFoundException</c> on the desktop version
/// and <c>Exception</c> on the .NET Standard 1.3 version, we achieve reasonable consistency while remaining
/// backwardly compatible with Noda Time v1 (which was desktop-only, and threw <c>TimeZoneNotFoundException</c>).
/// </remarks>
// sealed
class DateTimeZoneNotFoundException extends Error {
  final String message;

  /// <summary>
  /// Creates an instance with the given message.
  /// </summary>
  /// <param name="message">The message for the exception.</param>
  DateTimeZoneNotFoundException(this.message);

  @override toString() => message;
}