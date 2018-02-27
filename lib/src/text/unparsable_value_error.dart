/// <summary>
/// Exception thrown to indicate that the specified value could not be parsed.
/// </summary>
/// <threadsafety>Any public static members of this type are thread safe. Any instance members are not guaranteed to be thread safe.
/// See the thread safety section of the user guide for more information.
/// </threadsafety>
// todo: should match FormatException's format better..er (Do I want FormatException.. is it compatible? I wish Exception\Error had a common ancestor)
class UnparsableValueError extends Error { // extends FormatException {
  final String message;

  /// <summary>
  /// Creates a new UnparsableValueException with the given message.
  /// </summary>
  /// <param name="message">The failure message</param>
  UnparsableValueError(this.message);

  @override String toString() => message;
}