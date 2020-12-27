/// Thrown when an expected token is missing from the token stream.
class MissingTokenError extends Error {
  /// Initializes a new instance of the [MissingTokenError] class.
  ///
  /// <param name='name'>The name.</param>
  /// <param name='message'>The message.</param>
  // 'Missing token ' + name
  MissingTokenError(this.name, [String? message]) :
        message = message ?? 'Missing token $name';

  /// Gets or sets the name of the missing token
  final name;

  final message;
}
