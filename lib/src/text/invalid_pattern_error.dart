// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';

/// Exception thrown to indicate that the format pattern provided for either formatting or parsing is invalid.
class InvalidPatternError extends Error // FormatException
    {
  final String message;

  /// Creates a new InvalidPatternException with the given message.
  ///
  /// * [message]: A message describing the nature of the failure
  InvalidPatternError(this.message);

  /// Creates a new InvalidPatternException by formatting the given format string with
  /// the specified parameters, in the current culture.
  ///
  /// * [formatString]: Format string to use in order to create the final message
  /// * [parameters]: Format string parameters
  InvalidPatternError._format(String formatString, List<dynamic> parameters)
      : this(stringFormat(formatString, parameters));

  @override String toString() => 'InvalidPatternError: $message';
}

abstract class IInvalidPatternError {
  static InvalidPatternError format(String formatString, List<dynamic> parameters) => InvalidPatternError._format(formatString, parameters);
}
