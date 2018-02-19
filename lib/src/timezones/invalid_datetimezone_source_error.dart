/// <summary>
/// Exception thrown to indicate that a time zone source has violated the contract of <see cref="IDateTimeZoneSource"/>.
/// This exception is primarily intended to be thrown from <see cref="DateTimeZoneCache"/>, and only in the face of a buggy
/// source; user code should not usually need to be aware of this or catch it.
/// </summary>
// sealed
class InvalidDateTimeZoneSourceError extends Error
{
  final String message;

  /// <summary>
  /// Creates a new instance with the given message.
  /// </summary>
  /// <param name="message">The message for the exception.</param>
  InvalidDateTimeZoneSourceError(this.message);

  @override String toString() => message;
}