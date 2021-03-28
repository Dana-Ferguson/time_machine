// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';

/// Provides a cursor over text being parsed. None of the methods in this class throw exceptions (unless
/// there is a bug in Time Machine, in which case an exception is appropriate) and none of the methods
/// have ref parameters indicating failures, unlike subclasses. This class is used as the basis for both
/// value and pattern parsing, so can make no judgement about what's wrong (i.e. it wouldn't know what
/// type of failure to indicate). Instead, methods return Boolean values to indicate success or failure.
@internal
abstract class TextCursor {
  /// Gets the length of the string being parsed.
  final int length;

  /// Gets the string being parsed.
  final String value;

  /// A nul character. This character is not allowed in any parsable string and is used to
  /// indicate that the current character is not set.
  static final String nul = String.fromCharCode(0);

  /// Initializes a new instance to parse the given value.
  // Validated by caller.
  @protected TextCursor(this.value) : length = value.length {
    move(-1);
  }

  /// Gets the current character.
  late String _current;
  String get current => _current;

  /// Gets a value indicating whether this instance has more characters.
  ///
  /// <value>
  /// `true` if this instance has more characters; otherwise, `false`.
  /// </value>
  bool get hasMoreCharacters => (index + 1) < length;

  /// Gets the current index into the string being parsed.
  // todo: { get; private set; }
  late int index;

  /// Gets the remainder the string that has not been parsed yet.
  String get remainder => value.substring(index);

  ///   Returns a [String] that represents this instance.
  ///
  ///   A [String] that represents this instance.
  @override String toString() => stringInsert(value, index, '^');

  /// Returns the next character if there is one or [nul] if there isn't.
  ///
  /// Returns: 
  String peekNext() => (hasMoreCharacters ? value[index + 1] : nul);

  /// Moves the specified target index. If the new index is out of range of the valid indicies
  /// for this string then the index is set to the beginning or the end of the string whichever
  /// is nearest the requested index.
  ///
  /// [targetIndex]: Index of the target.
  /// Returns: `true` if the requested index is in range.
  bool move(int targetIndex) {
    if (targetIndex >= 0) {
      if (targetIndex < length) {
        index = targetIndex;
        _current = value[index];
        return true;
      }
      else {
        _current = nul;
        index = length;
        return false;
      }
    }
    _current = nul;
    index = -1;
    return false;
  }

  /// Moves to the next character.
  ///
  /// Returns: `true` if the requested index is in range.
  bool moveNext() {
    // Logically this is Move(Index + 1), but it's micro-optimized as we
    // know we'll never hit the lower limit this way.
    int targetIndex = index + 1;
    if (targetIndex < length) {
      index = targetIndex;
      _current = value[index];
      return true;
    }
    _current = nul;
    index = length;
    return false;
  }

  /// Moves to the previous character.
  ///
  /// Returns: `true` if the requested index is in range.
  bool movePrevious() {
    // Logically this is Move(Index - 1), but it's micro-optimized as we
    // know we'll never hit the upper limit this way.
    if (index > 0) {
      index--;
      _current = value[index];
      return true;
    }
    _current = nul;
    index = -1;
    return false;
  }
}
