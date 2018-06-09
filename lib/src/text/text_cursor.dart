// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';
import 'package:time_machine/time_machine_text.dart';

/// Provides a cursor over text being parsed. None of the methods in this class throw exceptions (unless
/// there is a bug in Noda Time, in which case an exception is appropriate) and none of the methods
/// have ref parameters indicating failures, unlike subclasses. This class is used as the basis for both
/// value and pattern parsing, so can make no judgement about what's wrong (i.e. it wouldn't know what
/// type of failure to indicate). Instead, methods return Boolean values to indicate success or failure.
@internal abstract class TextCursor {
  /// Gets the length of the string being parsed.
  @internal final int Length;

  /// Gets the string being parsed.
  @internal final String Value;

  /// A nul character. This character is not allowed in any parsable string and is used to
  /// indicate that the current character is not set.
  @internal static final String Nul = new String.fromCharCode(0);

  /// Initializes a new instance to parse the given value.
  // Validated by caller.
  @protected TextCursor(this.Value) : Length = Value.length {
    Move(-1);
  }

  /// Gets the current character.
  String _current;
  @internal String get Current => _current;

  /// Gets a value indicating whether this instance has more characters.
  ///
  /// <value>
  /// `true` if this instance has more characters; otherwise, `false`.
  /// </value>
  @internal bool get HasMoreCharacters => (Index + 1) < Length;

  /// Gets the current index into the string being parsed.
  // todo: { get; private set; }
  @internal int Index;

  /// Gets the remainder the string that has not been parsed yet.
  @internal String get Remainder => Value.substring(Index);

  ///   Returns a [String] that represents this instance.
  ///
  ///   A [String] that represents this instance.
  @override String toString() => stringInsert(Value, Index, '^');

  /// Returns the next character if there is one or [Nul] if there isn't.
  ///
  /// Returns: 
  @internal String PeekNext() => (HasMoreCharacters ? Value[Index + 1] : Nul);

  /// Moves the specified target index. If the new index is out of range of the valid indicies
  /// for this string then the index is set to the beginning or the end of the string whichever
  /// is nearest the requested index.
  ///
  /// [targetIndex]: Index of the target.
  /// Returns: `true` if the requested index is in range.
  @internal bool Move(int targetIndex) {
    if (targetIndex >= 0) {
      if (targetIndex < Length) {
        Index = targetIndex;
        _current = Value[Index];
        return true;
      }
      else {
        _current = Nul;
        Index = Length;
        return false;
      }
    }
    _current = Nul;
    Index = -1;
    return false;
  }

  /// Moves to the next character.
  ///
  /// Returns: `true` if the requested index is in range.
  @internal bool MoveNext() {
    // Logically this is Move(Index + 1), but it's micro-optimized as we
    // know we'll never hit the lower limit this way.
    int targetIndex = Index + 1;
    if (targetIndex < Length) {
      Index = targetIndex;
      _current = Value[Index];
      return true;
    }
    _current = Nul;
    Index = Length;
    return false;
  }

  /// Moves to the previous character.
  ///
  /// Returns: `true` if the requested index is in range.
  @internal bool MovePrevious() {
    // Logically this is Move(Index - 1), but it's micro-optimized as we
    // know we'll never hit the upper limit this way.
    if (Index > 0) {
      Index--;
      _current = Value[Index];
      return true;
    }
    _current = Nul;
    Index = -1;
    return false;
  }
}
