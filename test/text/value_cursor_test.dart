// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/Text/ValueCursorTest.cs
// 10dbf36  on Apr 23

import 'dart:async';
import 'dart:math' as math;
import 'dart:mirrors';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_patterns.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import '../time_machine_testing.dart';
import 'pattern_test_base.dart';
import 'pattern_test_data.dart';
import 'test_cultures.dart';
import 'text_cursor_test_base_tests.dart';

Future main() async {
  await runTests();
}

@Test()
class ValueCursorTest extends TextCursorTestBase {
  ValidateCurrentCharacter(TextCursor cursor, int expectedCurrentIndex, String /*char*/ expectedCurrentCharacter) =>
      TextCursorTestBase.ValidateCurrentCharacter(cursor, expectedCurrentIndex, expectedCurrentCharacter);

  @internal
  @override
  TextCursor MakeCursor(String value) {
    return new ValueCursor(value);
  }

  @Test()
  void Match_Char() {
    var value = new ValueCursor("abc");
    expect(value.MoveNext(), isTrue, reason: "GetNext() 1");
    expect(value.MatchSingle('a'), isTrue, reason: "First character");
    expect(value.MatchSingle('b'), isTrue, reason: "Second character");
    expect(value.MatchSingle('c'), isTrue, reason: "Third character");
    expect(value.MoveNext(), isFalse, reason: "GetNext() end");
  }

  @Test()
  void Match_String() {
    var value = new ValueCursor("abc");
    expect(value.MoveNext(), isTrue, reason: "GetNext() 1");
    expect(value.MatchText("abc"), isTrue);
    expect(value.MoveNext(), isFalse, reason: "GetNext() end");
  }

  @Test()
  void Match_StringNotMatched() {
    var value = new ValueCursor("xabcdef");
    expect(value.MoveNext(), isTrue, reason: "GetNext() 1");
    expect(value.MatchText("abc"), isFalse);
    ValidateCurrentCharacter(value, 0, 'x');
  }

  @Test()
  void Match_StringOverLongStringToMatch() {
    var value = new ValueCursor("x");
    expect(value.MoveNext(), isTrue);
    expect(value.MatchText("long String"), isFalse);
    ValidateCurrentCharacter(value, 0, 'x');
  }

  @Test()
  @SkipMe.noCompareInfo()
  void MatchCaseInsensitive_MatchAndMove() {
    var value = new ValueCursor("abcd");
    expect(value.MoveNext(), isTrue, reason: "GetNext() 1");
    expect(value.MatchCaseInsensitive("AbC", CultureInfo.invariantCulture.compareInfo, true), isTrue);
    ValidateCurrentCharacter(value, 3, 'd');
  }

  @Test()
  @SkipMe.noCompareInfo()
  void MatchCaseInsensitive_MatchWithoutMoving() {
    var value = new ValueCursor("abcd");
    expect(value.MoveNext(), isTrue, reason: "GetNext() 1");
    expect(value.MatchCaseInsensitive("AbC", CultureInfo.invariantCulture.compareInfo, false), isTrue);
// We're still looking at the start
    ValidateCurrentCharacter(value, 0, 'a');
  }

  @Test()
  @SkipMe.noCompareInfo()
  void MatchCaseInsensitive_StringNotMatched() {
    var value = new ValueCursor("xabcdef");
    expect(value.MoveNext(), isTrue, reason: "GetNext() 1");
    expect(value.MatchCaseInsensitive("abc", CultureInfo.invariantCulture.compareInfo, true), isFalse);
    ValidateCurrentCharacter(value, 0, 'x');
  }

  @Test()
  @SkipMe.noCompareInfo()
  void MatchCaseInsensitive_StringOverLongStringToMatch() {
    var value = new ValueCursor("x");
    expect(value.MoveNext(), isTrue);
    expect(value.MatchCaseInsensitive("long String", CultureInfo.invariantCulture.compareInfo, true), isFalse);
    ValidateCurrentCharacter(value, 0, 'x');
  }

  @Test()
  void Match_StringPartial() {
    var value = new ValueCursor("abcdef");
    expect(value.MoveNext(), isTrue, reason: "GetNext() 1");
    expect(value.MatchText("abc"), isTrue);
    ValidateCurrentCharacter(value, 3, 'd');
  }

  @Test()
  void ParseDigits_TooFewDigits() {
    var value = new ValueCursor("a12b");
    expect(value.MoveNext(), isTrue);
    ValidateCurrentCharacter(value, 0, 'a');
    expect(value.MoveNext(), isTrue);
// expect(value.ParseDigits(3, 3, out int actual), isFalse);
    expect(value.ParseDigits(3, 3), isNull);
    ValidateCurrentCharacter(value, 1, '1');
  }

  @Test()
  void ParseDigits_NoNumber() {
    var value = new ValueCursor("abc");
    expect(value.MoveNext(), isTrue);
// expect(value.ParseDigits(1, 2, out int actual), isFalse);
    expect(value.ParseDigits(1, 2), isNull);
    ValidateCurrentCharacter(value, 0, 'a');
  }

  @Test()
  void ParseDigits_Maximum() {
    var value = new ValueCursor("12");
    expect(value.MoveNext(), isTrue);
// expect(value.ParseDigits(1, 2, out int actual), isTrue);
    int actual;
    expect(actual = value.ParseDigits(1, 2), isNotNull);
    expect(actual, 12);
  }

  @Test()
  void ParseDigits_MaximumMoreDigits() {
    var value = new ValueCursor("1234");
    expect(value.MoveNext(), isTrue);
// expect(value.ParseDigits(1, 2, out int actual), isTrue);
    int actual;
    expect(actual = value.ParseDigits(1, 2), isNotNull);
    expect(actual, 12);
    ValidateCurrentCharacter(value, 2, '3');
  }

  @Test()
  void ParseDigits_Minimum() {
    var value = new ValueCursor("1");
    value.MoveNext();
// expect(value.ParseDigits(1, 2, out int actual), isTrue);
    int actual;
    expect(actual = value.ParseDigits(1, 2), isNotNull);
    expect(actual, 1);
    TextCursorTestBase.ValidateEndOfString(value);
  }

  @Test()
  void ParseDigits_MinimumNonDigits() {
    var value = new ValueCursor("1abc");
    expect(value.MoveNext(), isTrue);
// expect(value.ParseDigits(1, 2, out int actual), isTrue);
    int actual;
    expect(actual = value.ParseDigits(1, 2), isNotNull);
    expect(1, actual);
    ValidateCurrentCharacter(value, 1, 'a');
  }

  @Test()
  void ParseDigits_NonAscii_NeverMatches() {
// Arabic-Indic digits 0 and 1. See
// http://www.unicode.org/charts/PDF/U0600.pdf
    var value = new ValueCursor("\u0660\u0661");
    expect(value.MoveNext(), isTrue);
    expect(value.ParseDigits(1, 2), isNull);
  }

  @Test()
  void ParseInt64Digits_TooFewDigits() {
    var value = new ValueCursor("a12b");
    expect(value.MoveNext(), isTrue);
    ValidateCurrentCharacter(value, 0, 'a');
    expect(value.MoveNext(), isTrue);
    expect(value.ParseInt64Digits(3, 3), isNull);
    ValidateCurrentCharacter(value, 1, '1');
  }

  @Test()
  void ParseInt64Digits_NoNumber() {
    var value = new ValueCursor("abc");
    expect(value.MoveNext(), isTrue);
    expect(value.ParseInt64Digits(1, 2), isNull);
    ValidateCurrentCharacter(value, 0, 'a');
  }

  @Test()
  void ParseInt64Digits_Maximum() {
    var value = new ValueCursor("12");
    expect(value.MoveNext(), isTrue);
    int actual;
    expect(actual = value.ParseInt64Digits(1, 2), isNotNull);
    expect(12, actual);
  }

  @Test()
  void ParseInt64Digits_MaximumMoreDigits() {
    var value = new ValueCursor("1234");
    expect(value.MoveNext(), isTrue);
    int actual;
    expect(actual = value.ParseInt64Digits(1, 2), isNotNull);
    expect(12, actual);
    ValidateCurrentCharacter(value, 2, '3');
  }

  @Test()
  void ParseInt64Digits_Minimum() {
    var value = new ValueCursor("1");
    value.MoveNext();
    int actual;
    expect(actual = value.ParseInt64Digits(1, 2), isNotNull);
    expect(1, actual);
    TextCursorTestBase.ValidateEndOfString(value);
  }

  @Test()
  void ParseInt64Digits_MinimumNonDigits() {
    var value = new ValueCursor("1abc");
    expect(value.MoveNext(), isTrue);
    int actual;
    expect(actual = value.ParseInt64Digits(1, 2), isNotNull);
    expect(1, actual);
    ValidateCurrentCharacter(value, 1, 'a');
  }

  @Test()
  void ParseInt64Digits_NonAscii_NeverMatches() {
// Arabic-Indic digits 0 and 1. See
// http://www.unicode.org/charts/PDF/U0600.pdf
    var value = new ValueCursor("\u0660\u0661");
    expect(value.MoveNext(), isTrue);
    expect(value.ParseInt64Digits(1, 2), isNull);
  }

  @Test()
  void ParseInt64Digits_LargeNumber() {
    var value = new ValueCursor("9999999999999");
    expect(value.MoveNext(), isTrue);
    int actual;
    expect(actual = value.ParseInt64Digits(1, 13), isNotNull);
    expect(actual, 9999999999999 /*L*/);
// Assert.Greater(9999999999999/*L*/, Utility.int32MaxValue);
    expect(9999999999999 /*L*/, greaterThan(Utility.int32MaxValue));
  }

  @Test()
  void ParseFraction_NonAscii_NeverMatches() {
// Arabic-Indic digits 0 and 1. See
// http://www.unicode.org/charts/PDF/U0600.pdf
    var value = new ValueCursor("\u0660\u0661");
    expect(value.MoveNext(), isTrue);
    expect(value.ParseFraction(2, 2, 2), isNull);
  }

  @Test()
  void ParseInt64_Simple() {
    var value = new ValueCursor("56x");
    expect(value.MoveNext(), isTrue);
    OutBox<int> result = new OutBox<int>(0);
    expect(value.ParseInt64<String>(result, 'String'), isNull);
    expect(56 /*L*/, result.value);
// Cursor ends up post-number
    expect(2, value.Index);
  }

  @Test()
  void ParseInt64_Negative() {
    var value = new ValueCursor("-56x");
    expect(value.MoveNext(), isTrue);
    OutBox<int> result = new OutBox<int>(0);
    expect(value.ParseInt64<String>(result, 'String'), isNull);
    expect(-56 /*L*/, result.value);
  }

  @Test()
  void ParseInt64_NonNumber() {
    var value = new ValueCursor("xyz");
    expect(value.MoveNext(), isTrue);
    OutBox<int> result = new OutBox<int>(0);
    expect(value.ParseInt64<String>(result, 'String'), isNotNull);
// Cursor has not moved
    expect(0, value.Index);
  }

  @Test()
  void ParseInt64_DoubleNegativeSign() {
    var value = new ValueCursor("--10xyz");
    expect(value.MoveNext(), isTrue);
    OutBox<int> result = new OutBox<int>(0);
    expect(value.ParseInt64<String>(result, 'String'), isNotNull);
// Cursor has not moved
    expect(0, value.Index);
  }

  @Test()
  void ParseInt64_NegativeThenNonDigit() {
    var value = new ValueCursor("-x");
    expect(value.MoveNext(), isTrue);
    OutBox<int> result = new OutBox<int>(0);
    expect(value.ParseInt64<String>(result, 'String'), isNotNull);
// Cursor has not moved
    expect(0, value.Index);
  }

  @Test()
  void ParseInt64_NumberOutOfRange_LowLeadingDigits() {
    var value = new ValueCursor("1000000000000000000000000");
    expect(value.MoveNext(), isTrue);
    OutBox<int> result = new OutBox<int>(0);
    expect(value.ParseInt64<String>(result, 'String'), isNotNull);
// Cursor has not moved
    expect(0, value.Index);
  }

  @Test()
  void ParseInt64_NumberOutOfRange_HighLeadingDigits() {
    var value = new ValueCursor("999999999999999999999999");
    expect(value.MoveNext(), isTrue);
    OutBox<int> result = new OutBox<int>(0);
    expect(value.ParseInt64<String>(result, 'String'), isNotNull);
// Cursor has not moved
    expect(0, value.Index);
  }

  @Test()
  void ParseInt64_NumberOutOfRange_MaxValueLeadingDigits() {
    var value = new ValueCursor("9223372036854775808");
    expect(value.MoveNext(), isTrue);
    OutBox<int> result = new OutBox<int>(0);
    expect(value.ParseInt64<String>(result, 'String'), isNotNull);
// Cursor has not moved
    expect(0, value.Index);
  }

  @Test()
  void ParseInt64_NumberOutOfRange_MinValueLeadingDigits() {
    var value = new ValueCursor("-9223372036854775809");
    expect(value.MoveNext(), isTrue);
    OutBox<int> result = new OutBox<int>(0);
    expect(value.ParseInt64<String>(result, 'String'), isNotNull);
// Cursor has not moved
    expect(0, value.Index);
  }

  @Test()
  void ParseInt64_MaxValue() {
    var value = new ValueCursor("9223372036854775807");
    expect(value.MoveNext(), isTrue);
    OutBox<int> result = new OutBox<int>(0);
    expect(value.ParseInt64<String>(result, 'String'), isNull);
    expect(Utility.int64MaxValue, result.value);
  }

  @Test()
  void ParseInt64_MinValue() {
    var value = new ValueCursor("-9223372036854775808");
    expect(value.MoveNext(), isTrue);
    OutBox<int> result = new OutBox<int>(0);
    expect(value.ParseInt64<String>(result, 'String'), isNull);
    expect(Utility.int64MinValue, result.value);
  }

  @Test()
  void CompareOrdinal_ExactMatchToEndOfValue() {
    var value = new ValueCursor("xabc");
    value.Move(1);
    expect(0, value.CompareOrdinal("abc"));
    expect(1, value.Index); // Cursor hasn't moved
  }

  @Test()
  void CompareOrdinal_ExactMatchValueContinues() {
    var value = new ValueCursor("xabc");
    value.Move(1);
    expect(0, value.CompareOrdinal("ab"));
    expect(1, value.Index); // Cursor hasn't moved
  }

  @Test()
  void CompareOrdinal_ValueIsEarlier() {
    var value = new ValueCursor("xabc");
    value.Move(1);
// Assert.Less(value.CompareOrdinal("mm"), 0);
    expect(value.CompareOrdinal("mm"), lessThan(0));
    expect(1, value.Index); // Cursor hasn't moved
  }

  @Test()
  void CompareOrdinal_ValueIsLater() {
    var value = new ValueCursor("xabc");
    value.Move(1);
// Assert.Greater(value.CompareOrdinal("aa"), 0);
    expect(value.CompareOrdinal("aa"), greaterThan(0));
    expect(1, value.Index); // Cursor hasn't moved
  }

  @Test()
  void CompareOrdinal_LongMatch_EqualToEnd() {
    var value = new ValueCursor("xabc");
    value.Move(1);
// Assert.Less(value.CompareOrdinal("abcd"), 0);
    expect(value.CompareOrdinal("abcd"), lessThan(0));
    expect(1, value.Index); // Cursor hasn't moved
  }

  @Test()
  void CompareOrdinal_LongMatch_ValueIsEarlier() {
    var value = new ValueCursor("xabc");
    value.Move(1);
// Assert.Less(value.CompareOrdinal("cccc"), 0);
    expect(value.CompareOrdinal("cccc"), lessThan(0));
    expect(1, value.Index); // Cursor hasn't moved
  }

  @Test()
  void CompareOrdinal_LongMatch_ValueIsLater() {
    var value = new ValueCursor("xabc");
    value.Move(1);
// Assert.Greater(value.CompareOrdinal("aaaa"), 0);
    expect(value.CompareOrdinal("aaaa"), greaterThan(0));
    expect(1, value.Index); // Cursor hasn't moved
  }

  @Test()
  void ParseInt64_TooManyDigits() {
// We can cope as far as 9223372036854775807, but the trailing 1 causes a failure.
    var value = new ValueCursor("92233720368547758071");
    value.Move(0);
    OutBox<int> result = new OutBox<int>(0);
    var parseResult = value.ParseInt64<String>(result, 'String');
    expect(parseResult.Success, isFalse);
// Assert.IsInstanceOf<UnparsableValueException>(parseResult.Exception);
    expect(parseResult.Exception, new isInstanceOf<UnparsableValueError>());
    expect(0, value.Index); // Cursor hasn't moved
  }
}



