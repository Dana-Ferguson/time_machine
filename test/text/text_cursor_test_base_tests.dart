// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/src/time_machine_internal.dart';

import '../time_machine_testing.dart';

//Future main() async {
//  await runTests();
//}

/// Base class for tests of classes derived from TextCursor.
abstract class TextCursorTestBase {
  @Test()
  void TestConstructor() {
    const String testString = 'test';
    TextCursor cursor = MakeCursor(testString);
    ValidateContents(cursor, testString);
    ValidateBeginningOfString(cursor);
  }

  @Test()
  void TestMove() {
    TextCursor cursor = MakeCursor('test');
    ValidateBeginningOfString(cursor);
    expect(cursor.move(0), isTrue);
    ValidateCurrentCharacter(cursor, 0, 't');
    expect(cursor.move(1), isTrue);
    ValidateCurrentCharacter(cursor, 1, 'e');
    expect(cursor.move(2), isTrue);
    ValidateCurrentCharacter(cursor, 2, 's');
    expect(cursor.move(3), isTrue);
    ValidateCurrentCharacter(cursor, 3, 't');
    expect(cursor.move(4), isFalse);
    ValidateEndOfString(cursor);
  }

  @Test()
  void TestMove_NextPrevious() {
    TextCursor cursor = MakeCursor('test');
    ValidateBeginningOfString(cursor);
    expect(cursor.move(2), isTrue, reason: 'Move(2)');
    ValidateCurrentCharacter(cursor, 2, 's');
    expect(cursor.movePrevious(), isTrue, reason: 'MovePrevious()');
    ValidateCurrentCharacter(cursor, 1, 'e');
    expect(cursor.moveNext(), isTrue, reason: 'MoveNext()');
    ValidateCurrentCharacter(cursor, 2, 's');
    expect(cursor.movePrevious(), isTrue); // 1
    expect(cursor.movePrevious(), isTrue); // 0
    expect(cursor.movePrevious(), isFalse);
    ValidateCurrentCharacter(cursor, -1, TextCursor.nul);
    expect(cursor.movePrevious(), isFalse);
    ValidateCurrentCharacter(cursor, -1, TextCursor.nul);
  }

  @Test()
  void TestMove_invalid() {
    TextCursor cursor = MakeCursor('test');
    ValidateBeginningOfString(cursor);
    expect(cursor.move(-1000), isFalse);
    ValidateBeginningOfString(cursor);
    expect(cursor.move(1000), isFalse);
    ValidateEndOfString(cursor);
    expect(cursor.move(-1000), isFalse);
    ValidateBeginningOfString(cursor);
  }

  @internal String GetNextCharacter(TextCursor cursor) {
    expect(cursor.moveNext(), isTrue);
    return cursor.current;
  }

  @internal static void ValidateBeginningOfString(TextCursor cursor) {
    ValidateCurrentCharacter(cursor, -1, TextCursor.nul);
  }

  @internal static void ValidateCurrentCharacter(TextCursor cursor, int expectedCurrentIndex, String /*char*/ expectedCurrentCharacter) {
    expect(cursor.current, expectedCurrentCharacter);
    expect(cursor.index, expectedCurrentIndex);
  }

  @internal static void ValidateEndOfString(TextCursor cursor) {
    ValidateCurrentCharacter(cursor, cursor.length, TextCursor.nul);
  }

  /*
  @internal static void ValidateContents(TextCursor cursor, String value) {
    ValidateContents(cursor, value, -1);
  }*/

  @internal static void ValidateContents(TextCursor cursor, String value, [int length = -1]) {
    if (length < 0) {
      length = value.length;
    }
    expect(value, cursor.value, reason: 'Cursor Value mismatch');
    expect(length, cursor.length, reason: 'Cursor Length mismatch');
  }

  @internal TextCursor MakeCursor(String value);
}

