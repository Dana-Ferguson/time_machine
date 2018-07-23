// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

/// Exception thrown to indicate that the specified value could not be parsed.
// todo: should match FormatException's format better..er (Do I want FormatException.. is it compatible? I wish Exception\Error had a common ancestor)
// todo: Is Unparsable (vs Unparseable) okay phrasing -- it's a bit weird? NotParsedValueError ???
class UnparsableValueError extends Error { // extends FormatException {
  final String message;

  /// Creates a new [UnparsableValueError] with the given message.
  ///
  /// * [message]: The failure message
  UnparsableValueError(this.message);

  @override String toString() => message;
}
