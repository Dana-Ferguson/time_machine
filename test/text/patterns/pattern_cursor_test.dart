// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:mirrors';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_patterns.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

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
    return new PatternCursor(value);
  }

  @Test()
  @TestCase(const [r"'abc\"], "Escape at end")
  @TestCase(const ["'abc"], "Missing close quote")
  void GetQuotedString_Invalid(String pattern) {
    var cursor = new PatternCursor(pattern);
    expect('\'', GetNextCharacter(cursor));
    expect(() => cursor.getQuotedString('\''), willThrow<InvalidPatternError>());
  }

  @Test()
  @TestCase(const ["'abc'", "abc"])
  @TestCase(const ["''", ""])
  @TestCase(const ["'\"abc\"'", "\"abc\""], "Double quotes")
  @TestCase(const [r"'ab\c'", "abc"], "Escaped backslash")
  @TestCase(const [r"'ab\'c'", "ab'c"], "Escaped close quote")
  void GetQuotedString_Valid(String pattern, String expected) {
    var cursor = new PatternCursor(pattern);
    expect('\'', GetNextCharacter(cursor));
    String actual = cursor.getQuotedString('\'');
    expect(expected, actual);
    expect(cursor.moveNext(), isFalse);
  }

  @Test()
  void GetQuotedString_HandlesOtherQuote() {
    var cursor = new PatternCursor("[abc]");
    GetNextCharacter(cursor);
    String actual = cursor.getQuotedString(']');
    expect("abc", actual);
    expect(cursor.moveNext(), isFalse);
  }

  @Test()
  void GetQuotedString_NotAtEnd() {
    var cursor = new PatternCursor("'abc'more");
    String openQuote = GetNextCharacter(cursor);
    String actual = cursor.getQuotedString(openQuote);
    expect("abc", actual);
    TextCursorTestBase.ValidateCurrentCharacter(cursor, 4, '\'');

    expect('m', GetNextCharacter(cursor));
  }

  @Test()
  @TestCase(const ["aaa", 3])
  @TestCase(const ["a", 1])
  @TestCase(const ["aaadaa", 3])
  void GetRepeatCount_Valid(String text, int expectedCount) {
    var cursor = new PatternCursor(text);
    expect(cursor.moveNext(), isTrue);
    int actual = cursor.getRepeatCount(10);
    expect(expectedCount, actual);
    TextCursorTestBase.ValidateCurrentCharacter(cursor, expectedCount - 1, 'a');
  }

  @Test()
  void GetRepeatCount_ExceedsMax() {
    var cursor = new PatternCursor("aaa");
    expect(cursor.moveNext(), isTrue);
    expect(() => cursor.getRepeatCount(2), willThrow<InvalidPatternError>());
  }

  @Test()
  @TestCase(const ["x<HH:mm>y", "HH:mm"], "Simple")
  @TestCase(const ["x<HH:'T'mm>y", "HH:'T'mm"], "Quoting")
  @TestCase(const [r"x<HH:\Tmm>y", r"HH:\Tmm"], "Escaping")
  @TestCase(const ["x<a<b>c>y", "a<b>c"], "Simple nesting")
  @TestCase(const ["x<a'<'bc>y", "a'<'bc"], "Quoted start embedded")
  @TestCase(const ["x<a'>'bc>y", "a'>'bc"], "Quoted end embedded")
  @TestCase(const [r"x<a\<bc>y", r"a\<bc"], "Escaped start embedded")
  @TestCase(const [r"x<a\>bc>y", r"a\>bc"], "Escaped end embedded")
  void GetEmbeddedPattern_Valid(String pattern, String expectedEmbedded) {
    var cursor = new PatternCursor(pattern);
    cursor.moveNext();
    String embedded = cursor.getEmbeddedPattern();
    expect(expectedEmbedded, embedded);
    TextCursorTestBase.ValidateCurrentCharacter(cursor, expectedEmbedded.length + 2, '>');
  }

  @Test()
  @TestCase(const ["x(oops)"], "Wrong start character")
  @TestCase(const ["x<oops)"], "No end")
  @TestCase(const [r"x<oops\>"], "Escaped end")
  @TestCase(const ["x<oops'>'"], "Quoted end")
  @TestCase(const ["x<oops<nested>"], "Incomplete after nesting")
  void GetEmbeddedPattern_Invalid(String text) {
    var cursor = new PatternCursor(text);
    cursor.moveNext();
    expect(() => cursor.getEmbeddedPattern(), willThrow<InvalidPatternError>());
  }
}
