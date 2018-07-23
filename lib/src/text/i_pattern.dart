// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';

/// Generic interface supporting parsing and formatting. Parsing always results in a
/// [ParseResult] which can represent success or failure.
///
/// Idiomatic text handling in Time Machine involves creating a pattern once and reusing it multiple
/// times, rather than specifying the pattern text repeatedly. All patterns are immutable and isolate-safe,
/// and include the culture used for localization purposes.
///
/// * [T]: Type of value to parse or format.
@interface
abstract class IPattern<T> {
  /// Parses the given text value according to the rules of this pattern.
  ///
  /// This method never throws an exception (barring a bug in Time Machine itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  ///
  /// * [text]: The text value to parse.
  ///
  /// Returns: The result of parsing, which may be successful or unsuccessful.
  ParseResult<T> parse(String text);

  /// Formats the given value as text according to the rules of this pattern.
  ///
  /// * [value]: The value to format.
  ///
  /// Returns: The value formatted according to this pattern.
  String format(T value);

  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given [StringBuilder].
  ///
  /// * [value]: The value to format.
  /// * [builder]: The `StringBuilder` to append to.
  ///
  /// Returns: The builder passed in as [builder].
  StringBuffer appendFormat(T value, StringBuffer builder);
}

