// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Utility/InvalidNodaDataException.cs
// b9cc683  on Jun 18, 2017

/// <summary>
/// Exception thrown when data read by Noda Time (such as serialized time zone data) is invalid. This includes
/// data which is truncated, i.e. we expect more data than we can read.
/// </summary>
/// <remarks>
/// This type only exists as <c>InvalidDataException</c> didn't exist in Portable Class Libraries.
/// That does exist in netstandard1.3, but as we shipped 2.0 without realizing this, we're stuck with the
/// new exception type.
/// Unfortunately, <c>InvalidDataException</c> itself is sealed, so we can't derive from it for the sake
/// of backward compatibility.
/// </remarks>
/// <threadsafety>Any public static members of this type are thread safe. Any instance members are not guaranteed to be thread safe.
/// See the thread safety section of the user guide for more information.
/// </threadsafety>
/*sealed*/ class InvalidTimeDataError extends Error
{
  final String message;
  final Error error;

  /// <summary>
  /// Creates an instance with the given message.
  /// </summary>
  /// <param name="message">The message for the exception.</param>
  InvalidTimeDataError(this.message, [this.error = null]);

  @override String toString() => error == null ? '$message' : '$message\n$error';
}