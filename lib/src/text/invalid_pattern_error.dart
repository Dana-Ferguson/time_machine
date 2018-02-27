import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';

/// <summary>
/// Exception thrown to indicate that the format pattern provided for either formatting or parsing is invalid.
/// </summary>
/// <threadsafety>Any public static members of this type are thread safe. Any instance members are not guaranteed to be thread safe.
/// See the thread safety section of the user guide for more information.
/// </threadsafety>
/*sealed*/ class InvalidPatternError extends Error // FormatException
    {
  final String message;

  /// <summary>
  /// Creates a new InvalidPatternException with the given message.
  /// </summary>
  /// <param name="message">A message describing the nature of the failure</param>
  InvalidPatternError(this.message);

  /// <summary>
  /// Creates a new InvalidPatternException by formatting the given format string with
  /// the specified parameters, in the current culture.
  /// </summary>
  /// <param name="formatString">Format string to use in order to create the final message</param>
  /// <param name="parameters">Format string parameters</param>
  @internal InvalidPatternError.format(String formatString, List<dynamic> parameters)
      : this(stringFormat(formatString, parameters));
}