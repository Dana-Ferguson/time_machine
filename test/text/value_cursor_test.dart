// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import '../time_machine_testing.dart';
import 'text_cursor_test_base_tests.dart';

Future main() async {
  await runTests();
}

@Test()
class ValueCursorTest extends TextCursorTestBase {
  void ValidateCurrentCharacter(TextCursor cursor, int expectedCurrentIndex, String /*char*/ expectedCurrentCharacter) =>
      TextCursorTestBase.ValidateCurrentCharacter(cursor, expectedCurrentIndex, expectedCurrentCharacter);

  @internal
  @override
  TextCursor MakeCursor(String value) {
    return ValueCursor(value);
  }

  @Test()
  void Match_Char() {
    var value = ValueCursor('abc');
    expect(value.moveNext(), isTrue, reason: 'GetNext() 1');
    expect(value.matchSingle('a'), isTrue, reason: "First character");
    expect(value.matchSingle('b'), isTrue, reason: "Second character");
    expect(value.matchSingle('c'), isTrue, reason: "Third character");
    expect(value.moveNext(), isFalse, reason: 'GetNext() end');
  }

  @Test()
  void Match_String() {
    var value = ValueCursor('abc');
    expect(value.moveNext(), isTrue, reason: 'GetNext() 1');
    expect(value.matchText('abc'), isTrue);
    expect(value.moveNext(), isFalse, reason: 'GetNext() end');
  }

  @Test()
  void Match_StringNotMatched() {
    var value = ValueCursor('xabcdef');
    expect(value.moveNext(), isTrue, reason: 'GetNext() 1');
    expect(value.matchText('abc'), isFalse);
    ValidateCurrentCharacter(value, 0, 'x');
  }

  @Test()
  void Match_StringOverLongStringToMatch() {
    var value = ValueCursor('x');
    expect(value.moveNext(), isTrue);
    expect(value.matchText('long String'), isFalse);
    ValidateCurrentCharacter(value, 0, 'x');
  }

  @Test()
  void MatchCaseInsensitive_MatchAndMove() {
    var value = ValueCursor('abcd');
    expect(value.moveNext(), isTrue, reason: 'GetNext() 1');
    expect(value.matchCaseInsensitive('AbC', Culture.invariant.compareInfo, true), isTrue);
    ValidateCurrentCharacter(value, 3, 'd');
  }

  @Test()
  void MatchCaseInsensitive_MatchWithoutMoving() {
    var value = ValueCursor('abcd');
    expect(value.moveNext(), isTrue, reason: 'GetNext() 1');
    expect(value.matchCaseInsensitive('AbC', Culture.invariant.compareInfo, false), isTrue);
    // We're still looking at the start
    ValidateCurrentCharacter(value, 0, 'a');
  }

  @Test()
  void MatchCaseInsensitive_StringNotMatched() {
    var value = ValueCursor('xabcdef');
    expect(value.moveNext(), isTrue, reason: 'GetNext() 1');
    expect(value.matchCaseInsensitive('abc', Culture.invariant.compareInfo, true), isFalse);
    ValidateCurrentCharacter(value, 0, 'x');
  }

  @Test()
  void MatchCaseInsensitive_StringOverLongStringToMatch() {
    var value = ValueCursor('x');
    expect(value.moveNext(), isTrue);
    expect(value.matchCaseInsensitive('long String', Culture.invariant.compareInfo, true), isFalse);
    ValidateCurrentCharacter(value, 0, 'x');
  }

  @Test()
  void Match_StringPartial() {
    var value = ValueCursor('abcdef');
    expect(value.moveNext(), isTrue, reason: 'GetNext() 1');
    expect(value.matchText('abc'), isTrue);
    ValidateCurrentCharacter(value, 3, 'd');
  }

  @Test()
  void ParseDigits_TooFewDigits() {
    var value = ValueCursor('a12b');
    expect(value.moveNext(), isTrue);
    ValidateCurrentCharacter(value, 0, 'a');
    expect(value.moveNext(), isTrue);
    // expect(value.ParseDigits(3, 3, out int actual), isFalse);
    expect(value.parseDigits(3, 3), isNull);
    ValidateCurrentCharacter(value, 1, '1');
  }

  @Test()
  void ParseDigits_NoNumber() {
    var value = ValueCursor('abc');
    expect(value.moveNext(), isTrue);
    // expect(value.ParseDigits(1, 2, out int actual), isFalse);
    expect(value.parseDigits(1, 2), isNull);
    ValidateCurrentCharacter(value, 0, 'a');
  }

  @Test()
  void ParseDigits_Maximum() {
    var value = ValueCursor('12');
    expect(value.moveNext(), isTrue);
    // expect(value.ParseDigits(1, 2, out int actual), isTrue);
    int? actual;
    expect(actual = value.parseDigits(1, 2), isNotNull);
    expect(actual, 12);
  }

  @Test()
  void ParseDigits_MaximumMoreDigits() {
    var value = ValueCursor('1234');
    expect(value.moveNext(), isTrue);
    // expect(value.ParseDigits(1, 2, out int actual), isTrue);
    int? actual;
    expect(actual = value.parseDigits(1, 2), isNotNull);
    expect(actual, 12);
    ValidateCurrentCharacter(value, 2, '3');
  }

  @Test()
  void ParseDigits_Minimum() {
    var value = ValueCursor('1');
    value.moveNext();
    // expect(value.ParseDigits(1, 2, out int actual), isTrue);
    int? actual;
    expect(actual = value.parseDigits(1, 2), isNotNull);
    expect(actual, 1);
    TextCursorTestBase.ValidateEndOfString(value);
  }

  @Test()
  void ParseDigits_MinimumNonDigits() {
    var value = ValueCursor('1abc');
    expect(value.moveNext(), isTrue);
    // expect(value.ParseDigits(1, 2, out int actual), isTrue);
    int? actual;
    expect(actual = value.parseDigits(1, 2), isNotNull);
    expect(1, actual);
    ValidateCurrentCharacter(value, 1, 'a');
  }

  @Test()
  void ParseDigits_NonAscii_NeverMatches() {
    // Arabic-Indic digits 0 and 1. See
    // http://www.unicode.org/charts/PDF/U0600.pdf
    var value = ValueCursor("\u0660\u0661");
    expect(value.moveNext(), isTrue);
    expect(value.parseDigits(1, 2), isNull);
  }

  @Test()
  void ParseInt64Digits_TooFewDigits() {
    var value = ValueCursor('a12b');
    expect(value.moveNext(), isTrue);
    ValidateCurrentCharacter(value, 0, 'a');
    expect(value.moveNext(), isTrue);
    expect(value.parseInt64Digits(3, 3), isNull);
    ValidateCurrentCharacter(value, 1, '1');
  }

  @Test()
  void ParseInt64Digits_NoNumber() {
    var value = ValueCursor('abc');
    expect(value.moveNext(), isTrue);
    expect(value.parseInt64Digits(1, 2), isNull);
    ValidateCurrentCharacter(value, 0, 'a');
  }

  @Test()
  void ParseInt64Digits_Maximum() {
    var value = ValueCursor('12');
    expect(value.moveNext(), isTrue);
    int? actual;
    expect(actual = value.parseInt64Digits(1, 2), isNotNull);
    expect(12, actual);
  }

  @Test()
  void ParseInt64Digits_MaximumMoreDigits() {
    var value = ValueCursor('1234');
    expect(value.moveNext(), isTrue);
    int? actual;
    expect(actual = value.parseInt64Digits(1, 2), isNotNull);
    expect(12, actual);
    ValidateCurrentCharacter(value, 2, '3');
  }

  @Test()
  void ParseInt64Digits_Minimum() {
    var value = ValueCursor('1');
    value.moveNext();
    int? actual;
    expect(actual = value.parseInt64Digits(1, 2), isNotNull);
    expect(1, actual);
    TextCursorTestBase.ValidateEndOfString(value);
  }

  @Test()
  void ParseInt64Digits_MinimumNonDigits() {
    var value = ValueCursor('1abc');
    expect(value.moveNext(), isTrue);
    int? actual;
    expect(actual = value.parseInt64Digits(1, 2), isNotNull);
    expect(1, actual);
    ValidateCurrentCharacter(value, 1, 'a');
  }

  @Test()
  void ParseInt64Digits_NonAscii_NeverMatches() {
    // Arabic-Indic digits 0 and 1. See
    // http://www.unicode.org/charts/PDF/U0600.pdf
    var value = ValueCursor("\u0660\u0661");
    expect(value.moveNext(), isTrue);
    expect(value.parseInt64Digits(1, 2), isNull);
  }

  @Test()
  void ParseInt64Digits_LargeNumber() {
    var value = ValueCursor('9999999999999');
    expect(value.moveNext(), isTrue);
    int? actual;
    expect(actual = value.parseInt64Digits(1, 13), isNotNull);
    expect(actual, 9999999999999 /*L*/);
    // Assert.Greater(9999999999999/*L*/, Utility.int32MaxValue);
    expect(9999999999999 /*L*/, greaterThan(Platform.int32MaxValue));
  }

  @Test()
  void ParseFraction_NonAscii_NeverMatches() {
    // Arabic-Indic digits 0 and 1. See
    // http://www.unicode.org/charts/PDF/U0600.pdf
    var value = ValueCursor("\u0660\u0661");
    expect(value.moveNext(), isTrue);
    expect(value.parseFraction(2, 2, 2), isNull);
  }

  @Test()
  void ParseInt64_Simple() {
    var value = ValueCursor('56x');
    expect(value.moveNext(), isTrue);
    var pr = value.parseInt64<String>('String');
    expect(pr.success, isTrue);
    expect(56 /*L*/, pr.value);
    // Cursor ends up post-number
    expect(2, value.index);
  }

  @Test()
  void ParseInt64_Negative() {
    var value = ValueCursor('-56x');
    expect(value.moveNext(), isTrue);
    var result = value.parseInt64<String>('String');
    expect(result.success, isTrue);
    expect(-56 /*L*/, result.value);
  }

  @Test()
  void ParseInt64_NonNumber() {
    var value = ValueCursor('xyz');
    expect(value.moveNext(), isTrue);
    var result = value.parseInt64<String>('String');
    expect(result.success, isFalse);
    // Cursor has not moved
    expect(0, value.index);
  }

  @Test()
  void ParseInt64_DoubleNegativeSign() {
    var value = ValueCursor('--10xyz');
    expect(value.moveNext(), isTrue);
    var result = value.parseInt64<String>('String');
    expect(result.success, isFalse);
    // Cursor has not moved
    expect(0, value.index);
  }

  @Test()
  void ParseInt64_NegativeThenNonDigit() {
    var value = ValueCursor('-x');
    expect(value.moveNext(), isTrue);
    var result = value.parseInt64<String>('String');
    expect(result.success, isFalse);
    // Cursor has not moved
    expect(0, value.index);
  }

  @Test()
  void ParseInt64_NumberOutOfRange_LowLeadingDigits() {
    var value = ValueCursor('1000000000000000000000000');
    expect(value.moveNext(), isTrue);
    var result = value.parseInt64<String>('String');
    expect(result.success, isFalse);
    // Cursor has not moved
    expect(0, value.index);
  }

  @Test()
  void ParseInt64_NumberOutOfRange_HighLeadingDigits() {
    var value = ValueCursor('999999999999999999999999');
    expect(value.moveNext(), isTrue);
    var result = value.parseInt64<String>('String');
    expect(result.success, isFalse);
    // Cursor has not moved
    expect(0, value.index);
  }

  @Test()
  void ParseInt64_NumberOutOfRange_MaxValueLeadingDigits() {
    var value = ValueCursor('9223372036854775808');
    expect(value.moveNext(), isTrue);
    var result = value.parseInt64<String>('String');
    expect(result.success, isFalse);
    // Cursor has not moved
    expect(0, value.index);
  }

  @Test()
  void ParseInt64_NumberOutOfRange_MinValueLeadingDigits() {
    var value = ValueCursor('-9223372036854775809');
    expect(value.moveNext(), isTrue);
    var result = value.parseInt64<String>('String');
    expect(result.success, isFalse);
    // Cursor has not moved
    expect(0, value.index);
  }

  @Test()
  void ParseInt64_MaxValue() {
    // Can't parse this in JS
    if (Platform.isWeb) return;

    var value = ValueCursor('9223372036854775807');
    expect(value.moveNext(), isTrue);
    var result = value.parseInt64<String>('String');
    expect(result.success, isTrue);
    expect(Platform.int64MaxValue, result.value);
  }

  @Test()
  void ParseInt64_MinValue() {
    // Can't parse this in JS
    if (Platform.isWeb) return;

    var value = ValueCursor('-9223372036854775808');
    expect(value.moveNext(), isTrue);
    var result = value.parseInt64<String>('String');
    expect(result.success, isTrue);
    expect(Platform.int64MinValue, result.value);
  }

  @Test()
  void CompareOrdinal_ExactMatchToEndOfValue() {
    var value = ValueCursor('xabc');
    value.move(1);
    expect(0, value.compareOrdinal('abc'));
    expect(1, value.index); // Cursor hasn't moved
  }

  @Test()
  void CompareOrdinal_ExactMatchValueContinues() {
    var value = ValueCursor('xabc');
    value.move(1);
    expect(0, value.compareOrdinal('ab'));
    expect(1, value.index); // Cursor hasn't moved
  }

  @Test()
  void CompareOrdinal_ValueIsEarlier() {
    var value = ValueCursor('xabc');
    value.move(1);
    // Assert.Less(value.CompareOrdinal('mm'), 0);
    expect(value.compareOrdinal('mm'), lessThan(0));
    expect(1, value.index); // Cursor hasn't moved
  }

  @Test()
  void CompareOrdinal_ValueIsLater() {
    var value = ValueCursor('xabc');
    value.move(1);
    // Assert.Greater(value.CompareOrdinal('aa'), 0);
    expect(value.compareOrdinal('aa'), greaterThan(0));
    expect(1, value.index); // Cursor hasn't moved
  }

  @Test()
  void CompareOrdinal_LongMatch_EqualToEnd() {
    var value = ValueCursor('xabc');
    value.move(1);
    // Assert.Less(value.CompareOrdinal('abcd'), 0);
    expect(value.compareOrdinal('abcd'), lessThan(0));
    expect(1, value.index); // Cursor hasn't moved
  }

  @Test()
  void CompareOrdinal_LongMatch_ValueIsEarlier() {
    var value = ValueCursor('xabc');
    value.move(1);
    // Assert.Less(value.CompareOrdinal('cccc'), 0);
    expect(value.compareOrdinal('cccc'), lessThan(0));
    expect(1, value.index); // Cursor hasn't moved
  }

  @Test()
  void CompareOrdinal_LongMatch_ValueIsLater() {
    var value = ValueCursor('xabc');
    value.move(1);
    // Assert.Greater(value.CompareOrdinal('aaaa'), 0);
    expect(value.compareOrdinal('aaaa'), greaterThan(0));
    expect(1, value.index); // Cursor hasn't moved
  }

  @Test()
  void ParseInt64_TooManyDigits() {
    // We can cope as far as 9223372036854775807, but the trailing 1 causes a failure.
    var value = ValueCursor('92233720368547758071');
    value.move(0);
    var result = value.parseInt64<String>('String');
    expect(result.success, isFalse);
    // Assert.IsInstanceOf<UnparsableValueException>(parseResult.Exception);
    expect(result.error, const TypeMatcher<UnparsableValueError>());
    expect(0, value.index); // Cursor hasn't moved
  }
}




