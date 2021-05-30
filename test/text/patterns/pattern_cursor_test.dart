// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import '../../time_machine_testing.dart';
import '../text_cursor_test_base_tests.dart';

Future main() async {
  await runTests();
}

@Test()
class PatternCursorTest extends TextCursorTestBase {
  @internal
  @override
  TextCursor MakeCursor(String value) {
    return PatternCursor(value);
  }

  @Test()
  @TestCase([r"'abc\"], "Escape at end")
  @TestCase(["'abc"], "Missing close quote")
  void GetQuotedString_Invalid(String pattern) {
    var cursor = PatternCursor(pattern);
    expect('\'', GetNextCharacter(cursor));
    expect(() => cursor.getQuotedString('\''), willThrow<InvalidPatternError>());
  }

  @Test()
  @TestCase(["'abc'", "abc"])
  @TestCase(["''", ""])
  @TestCase(["'\"abc\"'", "\"abc\""], "Double quotes")
  @TestCase([r"'ab\c'", "abc"], "Escaped backslash")
  @TestCase([r"'ab\'c'", "ab'c"], "Escaped close quote")
  void GetQuotedString_Valid(String pattern, String expected) {
    var cursor = PatternCursor(pattern);
    expect('\'', GetNextCharacter(cursor));
    String actual = cursor.getQuotedString('\'');
    expect(expected, actual);
    expect(cursor.moveNext(), isFalse);
  }

  @Test()
  void GetQuotedString_HandlesOtherQuote() {
    var cursor = PatternCursor('[abc]');
    GetNextCharacter(cursor);
    String actual = cursor.getQuotedString(']');
    expect('abc', actual);
    expect(cursor.moveNext(), isFalse);
  }

  @Test()
  void GetQuotedString_NotAtEnd() {
    var cursor = PatternCursor("'abc'more");
    String openQuote = GetNextCharacter(cursor);
    String actual = cursor.getQuotedString(openQuote);
    expect('abc', actual);
    TextCursorTestBase.ValidateCurrentCharacter(cursor, 4, '\'');

    expect('m', GetNextCharacter(cursor));
  }

  @Test()
  @TestCase(['aaa', 3])
  @TestCase(['a', 1])
  @TestCase(['aaadaa', 3])
  void GetRepeatCount_Valid(String text, int expectedCount) {
    var cursor = PatternCursor(text);
    expect(cursor.moveNext(), isTrue);
    int actual = cursor.getRepeatCount(10);
    expect(expectedCount, actual);
    TextCursorTestBase.ValidateCurrentCharacter(cursor, expectedCount - 1, 'a');
  }

  @Test()
  void GetRepeatCount_ExceedsMax() {
    var cursor = PatternCursor('aaa');
    expect(cursor.moveNext(), isTrue);
    expect(() => cursor.getRepeatCount(2), willThrow<InvalidPatternError>());
  }

  @Test()
  @TestCase(['x<HH:mm>y', "HH:mm"], "Simple")
  @TestCase(["x<HH:'T'mm>y", "HH:'T'mm"], "Quoting")
  @TestCase([r"x<HH:\Tmm>y", r"HH:\Tmm"], "Escaping")
  @TestCase(['x<a<b>c>y', "a<b>c"], "Simple nesting")
  @TestCase(["x<a'<'bc>y", "a'<'bc"], "Quoted start embedded")
  @TestCase(["x<a'>'bc>y", "a'>'bc"], "Quoted end embedded")
  @TestCase([r"x<a\<bc>y", r"a\<bc"], "Escaped start embedded")
  @TestCase([r"x<a\>bc>y", r"a\>bc"], "Escaped end embedded")
  void GetEmbeddedPattern_Valid(String pattern, String expectedEmbedded) {
    var cursor = PatternCursor(pattern);
    cursor.moveNext();
    String embedded = cursor.getEmbeddedPattern();
    expect(expectedEmbedded, embedded);
    TextCursorTestBase.ValidateCurrentCharacter(cursor, expectedEmbedded.length + 2, '>');
  }

  @Test()
  @TestCase(['x(oops)'], "Wrong start character")
  @TestCase(['x<oops)'], "No end")
  @TestCase([r"x<oops\>"], "Escaped end")
  @TestCase(["x<oops'>'"], "Quoted end")
  @TestCase(['x<oops<nested>'], "Incomplete after nesting")
  void GetEmbeddedPattern_Invalid(String text) {
    var cursor = PatternCursor(text);
    cursor.moveNext();
    expect(() => cursor.getEmbeddedPattern(), willThrow<InvalidPatternError>());
  }
}
