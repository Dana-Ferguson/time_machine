// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/text/time_machine_text.dart';


/// Extends [TextCursor] to simplify parsing patterns such as 'uuuu-MM-dd'.
@internal
class PatternCursor extends TextCursor {
  /// The character signifying the start of an embedded pattern.
  static const String embeddedPatternStart = '<';

  /// The character signifying the end of an embedded pattern.
  static const String embeddedPatternEnd = '>';

  PatternCursor(String pattern)
      : super(pattern);

  /// Gets the quoted string.
  ///
  /// The cursor is left positioned at the end of the quoted region.
  /// [closeQuote]: The close quote character to match for the end of the quoted string.
  /// Returns: The quoted string sans open and close quotes. This can be an empty string but will not be null.
  String getQuotedString(String closeQuote) {
    var builder = StringBuffer(); //Length - Index);
    bool endQuoteFound = false;
    while (moveNext()) {
      if (current == closeQuote) {
        moveNext();
        endQuoteFound = true;
        break;
      }
      if (current == '\\') {
        if (!moveNext()) {
          throw InvalidPatternError(TextErrorMessages.escapeAtEndOfString);
        }
      }
      builder.write(current);
    }
    if (!endQuoteFound) {
      throw IInvalidPatternError.format(TextErrorMessages.missingEndQuote, [closeQuote]);
    }
    movePrevious();
    return builder.toString();
  }

  /// Gets the pattern repeat count. The cursor is left on the final character of the
  /// repeated sequence.
  ///
  /// [maximumCount]: The maximum number of repetitions allowed.
  /// Returns: The repetition count which is alway at least `1`.
  int getRepeatCount(int maximumCount) {
    String patternCharacter = current;
    int startPos = index;
    while (moveNext() && current == patternCharacter) {}
    int repeatLength = index - startPos;
    // Move the cursor back to the last character of the repeated pattern
    movePrevious();
    if (repeatLength > maximumCount) {
      throw IInvalidPatternError.format(TextErrorMessages.repeatCountExceeded, [patternCharacter, maximumCount]);
    }
    return repeatLength;
  }

  /// Returns a string containing the embedded pattern within this one.
  ///
  /// The cursor is expected to be positioned immediately before the [embeddedPatternStart] character (`&lt;`),
  /// and on success the cursor will be positioned on the [embeddedPatternEnd] character (`&gt;`).
  ///
  /// Quote characters (' and ") and escaped characters (escaped with a backslash) are handled
  /// but not unescaped: the resulting pattern should be ready for parsing as normal. It is assumed that the
  /// embedded pattern will itself handle embedded patterns, so if the input is on the first `&lt;`
  /// of `'before &lt;outer1 &lt;inner&gt; outer2&gt; after'`
  /// this method will return `'outer1 &lt;inner&gt; outer2'` and the cursor will be positioned
  /// on the final `&gt;` afterwards.
  ///
  /// Returns: The embedded pattern, not including the start/end pattern characters.
  String getEmbeddedPattern() {
    if (!moveNext() || current != embeddedPatternStart) {
      throw InvalidPatternError(stringFormat(TextErrorMessages.missingEmbeddedPatternStart, [embeddedPatternStart]));
    }
    int startIndex = index + 1;
    int depth = 1; // For nesting
    while (moveNext()) {
      var current = super.current;
      if (current == embeddedPatternEnd) {
        depth--;
        if (depth == 0) {
          return value.substring(startIndex, index /*- startIndex*/);
        }
      }
      else if (current == embeddedPatternStart) {
        depth++;
      }
      else if (current == '\\') {
        if (!moveNext()) {
          throw InvalidPatternError(TextErrorMessages.escapeAtEndOfString);
        }
      }
      else if (current == '\'' || current == '\"') {
        // We really don't care about the value here. It's slightly inefficient to
        // create the substring and then ignore it, but it's unlikely to be significant.
        getQuotedString(current);
      }
    }
    // We've reached the end of the enclosing pattern without reaching the end of the embedded pattern. Oops.
    throw InvalidPatternError(stringFormat(TextErrorMessages.missingEmbeddedPatternEnd, [embeddedPatternEnd]));
  }
}
