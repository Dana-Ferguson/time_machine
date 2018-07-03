// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/time_machine_internal.dart';

/// Internal interface supporting partial parsing and formatting. This is used
/// when one pattern is embedded within another.
///
/// [T]: The type of value to be parsed or formatted.
@internal
@interface
abstract class IPartialPattern<T> implements IPattern<T>
{
  /// Parses a value from the current position in the cursor. This will
  /// not fail if the pattern ends before the cursor does - that's expected
  /// in most cases.
  ///
  /// [cursor]: The cursor to parse from.
  /// Returns: The result of parsing from the cursor.
  ParseResult<T> parsePartial(ValueCursor cursor);
}
