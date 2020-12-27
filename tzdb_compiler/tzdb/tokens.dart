import 'package:time_machine/src/time_machine_internal.dart';

import 'missing_token_error.dart';

/// Provides a simple String tokenizer that breaks the String into words that are separated by
/// white space.
///
/// <remarks>
///     Multiple white spaces in a row are treated as one separator. White space at the beginning of
///     the line cause an empty token to be returned as the first token. White space at the end of
///     the line are ignored.
/// </remarks>
class Tokens {
  /// Represents an empty token list.
  static final List<String> _noTokens = List<String>.filled(0, '');

  /// The list of words. This will never be null but may be empty.
  final List<String> _words;

  /// The current index into the words list.
  int _index = 0;

  /// Initializes a new instance of the [Tokens] class.
  ///
  /// <param name='words'>The words list.</param>
  Tokens._(this._words);

  /// Gets a value indicating whether this instance has another token.
  ///
  /// <value>
  /// <c>true</c> if this instance has another token; otherwise, <c>false</c>.
  /// </value>
  bool get hasNextToken => _index < _words.length;

  /// Returns the next token.
  ///
  /// <param name='name'>The name of the token. Used in the exception to identify the missing token.</param>
  /// <returns>The next token.</returns>
  /// <exception cref='MissingTokenException'>Thrown if there is no next token.</exception>
  String? nextToken(String name) {
    if (tryNextToken()) {
      return tryNextTokenResult;
    }
    throw MissingTokenError(name);
  }

  /// <summary>
  /// Returns an object that contains the list of the whitespace separated words in the given
  /// string. The String is assumed to be culture invariant.
  /// </summary>
  /// <param name='text'>The text to break into words.</param>
  /// <returns>The tokenized text.</returns>
  static Tokens tokenize(String text) {
    Preconditions.checkNotNull(text, 'text');
    text = text.trimRight();
    if (text == '') {
      return Tokens._(_noTokens);
    }
    // Primitive parser, but we need to handle double quotes.
    var list = <String>[];
    var currentWord = StringBuffer();
    bool inQuotes = false;
    bool lastCharacterWasWhitespace = false;

    // text.runes.forEach((int rune)
    for (var rune in text.runes) {
      String c = String.fromCharCode(rune);

      if (c == '"') {
        inQuotes = !inQuotes;
        lastCharacterWasWhitespace = false;
        continue;
      }

      if (c
          .trim()
          .isEmpty /*char.IsWhiteSpace(c)*/ && !inQuotes) {
        if (!lastCharacterWasWhitespace) {
          list.add(currentWord.toString());
          lastCharacterWasWhitespace = true;
          currentWord.clear();
        }
        // Otherwise, we're just collapsing multiple whitespace
      }
      else {
        currentWord.write(c);
        lastCharacterWasWhitespace = false;
      }
    }
    if (!lastCharacterWasWhitespace) {
      list.add(currentWord.toString());
    }
    if (inQuotes) {
      // InvalidDataException
      throw Exception('Line has unterminated quotes');
    }
    return Tokens._(list);
  }

  // bool tryNextToken(out String result)
  String? _tryNextTokenResult;

  String? get tryNextTokenResult => _tryNextTokenResult;

  /// Tries to get the next token.
  ///
  /// <param name='result'>Where to place the next token.</param>
  /// <returns>True if there was a next token, false otherwise.</returns>
  bool tryNextToken() {
    if (hasNextToken) {
      _tryNextTokenResult = _words[_index++];
      return true;
    }
    _tryNextTokenResult = '';
    return false;
  }
}
