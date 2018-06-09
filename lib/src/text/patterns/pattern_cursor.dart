// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';


/// Extends [TextCursor] to simplify parsing patterns such as "uuuu-MM-dd".
@internal /*sealed*/ class PatternCursor extends TextCursor {
  /// The character signifying the start of an embedded pattern.
  @internal static const String EmbeddedPatternStart = '<';

  /// The character signifying the end of an embedded pattern.
  @internal static const String EmbeddedPatternEnd = '>';

  @internal PatternCursor(String pattern)
      : super(pattern);

  /// Gets the quoted string.
  ///
  /// The cursor is left positioned at the end of the quoted region.
  /// [closeQuote]: The close quote character to match for the end of the quoted string.
  /// Returns: The quoted string sans open and close quotes. This can be an empty string but will not be null.
  @internal String GetQuotedString(String closeQuote) {
    var builder = new StringBuffer(); //Length - Index);
    bool endQuoteFound = false;
    while (MoveNext()) {
      if (Current == closeQuote) {
        MoveNext();
        endQuoteFound = true;
        break;
      }
      if (Current == '\\') {
        if (!MoveNext()) {
          throw new InvalidPatternError(TextErrorMessages.EscapeAtEndOfString);
        }
      }
      builder.write(Current);
    }
    if (!endQuoteFound) {
      throw new InvalidPatternError.format(TextErrorMessages.MissingEndQuote, [closeQuote]);
    }
    MovePrevious();
    return builder.toString();
  }

  /// Gets the pattern repeat count. The cursor is left on the final character of the
  /// repeated sequence.
  ///
  /// [maximumCount]: The maximum number of repetitions allowed.
  /// Returns: The repetition count which is alway at least `1`.
  @internal int GetRepeatCount(int maximumCount) {
    String patternCharacter = Current;
    int startPos = Index;
    while (MoveNext() && Current == patternCharacter) {}
    int repeatLength = Index - startPos;
    // Move the cursor back to the last character of the repeated pattern
    MovePrevious();
    if (repeatLength > maximumCount) {
      throw new InvalidPatternError.format(TextErrorMessages.RepeatCountExceeded, [patternCharacter, maximumCount]);
    }
    return repeatLength;
  }

  /// Returns a string containing the embedded pattern within this one.
  ///
  /// The cursor is expected to be positioned immediately before the [EmbeddedPatternStart] character (`&lt;`),
  /// and on success the cursor will be positioned on the [EmbeddedPatternEnd] character (`&gt;`).
  ///
  /// Quote characters (' and ") and escaped characters (escaped with a backslash) are handled
  /// but not unescaped: the resulting pattern should be ready for parsing as normal. It is assumed that the
  /// embedded pattern will itself handle embedded patterns, so if the input is on the first `&lt;`
  /// of `"before &lt;outer1 &lt;inner&gt; outer2&gt; after"`
  /// this method will return `"outer1 &lt;inner&gt; outer2"` and the cursor will be positioned
  /// on the final `&gt;` afterwards.
  ///
  /// Returns: The embedded pattern, not including the start/end pattern characters.
  @internal String GetEmbeddedPattern() {
    if (!MoveNext() || Current != EmbeddedPatternStart) {
      throw new InvalidPatternError(stringFormat(TextErrorMessages.MissingEmbeddedPatternStart, [EmbeddedPatternStart]));
    }
    int startIndex = Index + 1;
    int depth = 1; // For nesting
    while (MoveNext()) {
      var current = Current;
      if (current == EmbeddedPatternEnd) {
        depth--;
        if (depth == 0) {
          return Value.substring(startIndex, Index /*- startIndex*/);
        }
      }
      else if (current == EmbeddedPatternStart) {
        depth++;
      }
      else if (current == '\\') {
        if (!MoveNext()) {
          throw new InvalidPatternError(TextErrorMessages.EscapeAtEndOfString);
        }
      }
      else if (current == '\'' || current == '\"') {
        // We really don't care about the value here. It's slightly inefficient to
        // create the substring and then ignore it, but it's unlikely to be significant.
        GetQuotedString(current);
      }
    }
    // We've reached the end of the enclosing pattern without reaching the end of the embedded pattern. Oops.
    throw new InvalidPatternError(stringFormat(TextErrorMessages.MissingEmbeddedPatternEnd, [EmbeddedPatternEnd]));
  }
}
