// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_utilities.dart';

import '../time_machine_testing.dart';

//Future main() async {
//  await runTests();
//}

/// Base class for tests of classes derived from TextCursor.
abstract class TextCursorTestBase {
  @Test()
  void TestConstructor() {
    const String testString = "test";
    TextCursor cursor = MakeCursor(testString);
    ValidateContents(cursor, testString);
    ValidateBeginningOfString(cursor);
  }

  @Test()
  void TestMove() {
    TextCursor cursor = MakeCursor("test");
    ValidateBeginningOfString(cursor);
    expect(cursor.Move(0), isTrue);
    ValidateCurrentCharacter(cursor, 0, 't');
    expect(cursor.Move(1), isTrue);
    ValidateCurrentCharacter(cursor, 1, 'e');
    expect(cursor.Move(2), isTrue);
    ValidateCurrentCharacter(cursor, 2, 's');
    expect(cursor.Move(3), isTrue);
    ValidateCurrentCharacter(cursor, 3, 't');
    expect(cursor.Move(4), isFalse);
    ValidateEndOfString(cursor);
  }

  @Test()
  void TestMove_NextPrevious() {
    TextCursor cursor = MakeCursor("test");
    ValidateBeginningOfString(cursor);
    expect(cursor.Move(2), isTrue, reason: "Move(2)");
    ValidateCurrentCharacter(cursor, 2, 's');
    expect(cursor.MovePrevious(), isTrue, reason: "MovePrevious()");
    ValidateCurrentCharacter(cursor, 1, 'e');
    expect(cursor.MoveNext(), isTrue, reason: "MoveNext()");
    ValidateCurrentCharacter(cursor, 2, 's');
    expect(cursor.MovePrevious(), isTrue); // 1
    expect(cursor.MovePrevious(), isTrue); // 0
    expect(cursor.MovePrevious(), isFalse);
    ValidateCurrentCharacter(cursor, -1, TextCursor.Nul);
    expect(cursor.MovePrevious(), isFalse);
    ValidateCurrentCharacter(cursor, -1, TextCursor.Nul);
  }

  @Test()
  void TestMove_invalid() {
    TextCursor cursor = MakeCursor("test");
    ValidateBeginningOfString(cursor);
    expect(cursor.Move(-1000), isFalse);
    ValidateBeginningOfString(cursor);
    expect(cursor.Move(1000), isFalse);
    ValidateEndOfString(cursor);
    expect(cursor.Move(-1000), isFalse);
    ValidateBeginningOfString(cursor);
  }

  @internal String GetNextCharacter(TextCursor cursor) {
    expect(cursor.MoveNext(), isTrue);
    return cursor.Current;
  }

  @internal static void ValidateBeginningOfString(TextCursor cursor) {
    ValidateCurrentCharacter(cursor, -1, TextCursor.Nul);
  }

  @internal static void ValidateCurrentCharacter(TextCursor cursor, int expectedCurrentIndex, String /*char*/ expectedCurrentCharacter) {
    expect(cursor.Current, expectedCurrentCharacter);
    expect(cursor.Index, expectedCurrentIndex);
  }

  @internal static void ValidateEndOfString(TextCursor cursor) {
    ValidateCurrentCharacter(cursor, cursor.Length, TextCursor.Nul);
  }

  /*
  @internal static void ValidateContents(TextCursor cursor, String value) {
    ValidateContents(cursor, value, -1);
  }*/

  @internal static void ValidateContents(TextCursor cursor, String value, [int length = -1]) {
    if (length < 0) {
      length = value.length;
    }
    expect(value, cursor.Value, reason: "Cursor Value mismatch");
    expect(length, cursor.Length, reason: "Cursor Length mismatch");
  }

  @internal TextCursor MakeCursor(String value);
}

