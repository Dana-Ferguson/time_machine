import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine.dart';

/// <summary>
/// Internal interface supporting partial parsing and formatting. This is used
/// when one pattern is embedded within another.
/// </summary>
/// <typeparam name="T">The type of value to be parsed or formatted.</typeparam>
@internal abstract class IPartialPattern<T> implements IPattern<T>
{
  /// <summary>
  /// Parses a value from the current position in the cursor. This will
  /// not fail if the pattern ends before the cursor does - that's expected
  /// in most cases.
  /// </summary>
  /// <param name="cursor">The cursor to parse from.</param>
  /// <returns>The result of parsing from the cursor.</returns>
  ParseResult<T> ParsePartial(ValueCursor cursor);
}