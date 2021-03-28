// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:math' as math;

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/text/time_machine_text.dart';

@internal
class ValueCursor extends TextCursor {
  // '0': 48; '9': 57
  static const int _zeroCodeUnit = 48;
  static const int _nineCodeUnit = 57;

  /// Initializes a new instance of the [ValueCursor] class.
  ///
  /// [value]: The string to parse.
  ValueCursor(String value)
      : super(value);

  /// Attempts to match the specified character with the current character of the string. If the
  /// character matches then the index is moved passed the character.
  ///
  /// [character]: The character to match.
  /// Returns: `true` if the character matches.
  bool matchSingle(String character) {
    assert(character.length == 1);
    if (current == character) {
      moveNext();
      return true;
    }
    return false;
  }

  /// Attempts to match the specified string with the current point in the string. If the
  /// character matches then the index is moved past the string.
  ///
  /// [match]: The string to match.
  /// Returns: `true` if the string matches.
  bool matchText(String match) {
    // string.CompareOrdinal(Value, Index, match, 0, match.length) == 0) {
    // Value, Index, match, 0, match.length
    if (stringOrdinalCompare(value, index, match, 0, match.length) == 0) {
      move(index + match.length);
      return true;
    }
    return false;
  }

  /// Attempts to match the specified string with the current point in the string in a case-insensitive
  /// manner, according to the given comparison info. The cursor is optionally updated to the end of the match.
  bool matchCaseInsensitive(String match, CompareInfo? compareInfo, bool moveOnSuccess) {
    if (match.length > value.length - index) {
      return false;
    }
    // Note: This will fail if the length in the input string is different to the length in the
    // match string for culture-specific reasons. It's not clear how to handle that...
    // See issue 210 for details - we're not intending to fix this, but it's annoying.
    if (stringOrdinalIgnoreCaseCompare(value, index, match, 0, match.length) == 0) {
      if (moveOnSuccess) {
        move(index + match.length);
      }
      return true;
    }

    // int Compare(String string1, int offset1, int length1, String string2, int offset2, int length2, CompareOptions options)
    //    if (compareInfo.Compare(
    //        Value,
    //        Index,
    //        match.length,
    //        match,
    //        0,
    //        match.length,
    //        CompareOptions.IgnoreCase) == 0) {
    //      if (moveOnSuccess) {
    //        Move(Index + match.length);
    //      }
    //      return true;
    //    }
    return false;
  }

  /// Compares the value from the current cursor position with the given match. If the
  /// given match string is longer than the remaining length, the comparison still goes
  /// ahead but the result is never 0: if the result of comparing to the end of the
  /// value returns 0, the result is -1 to indicate that the value is earlier than the given match.
  /// Conversely, if the remaining value is longer than the match string, the comparison only
  /// goes as far as the end of the match. So 'xabcd' with the cursor at "a" will return 0 when
  /// matched with 'abc'.
  ///
  /// A negative number if the value (from the current cursor position) is lexicographically
  /// earlier than the given match string; 0 if they are equal (as far as the end of the match) and
  /// a positive number if the value is lexicographically later than the given match string.
  int compareOrdinal(String match) {
    int remaining = value.length - index;
    if (match.length > remaining) {
      // string.CompareOrdinal(Value, Index, match, 0, remaining);
      int ret = stringOrdinalCompare(value, index, match, 0, remaining); // Value.startsWith(match, Index);
      return ret == 0 ? -1 : ret;
    }
    // string.CompareOrdinal(Value, Index, match, 0, match.length);
    return stringOrdinalCompare(value, index, match, 0, match.length);
  }

  // hack: we need to know what T is at runtime for error messages
  // todo: <T> on these values currently don't do anything -- we can't access T directly on VM -- and on JS, I'm not sure it even exists
  //  --> [tType] ferries the information across we need. <T> should be the value being parsed by the Value_Cursor, but I don't think anything enforces that
  /// Parses digits at the current point in the string as a signed 64-bit integer value.
  /// Currently this method only supports cultures whose negative sign is '-' (and
  /// using ASCII digits).
  ///
  /// [result]: The result integer value. The value of this is not guaranteed
  /// to be anything specific if the return value is non-null.
  /// todo: update
  /// Returns: null if the digits were parsed, or the appropriate parse failure
  ParseResult<int> parseInt64<T>(String tType) { ///*out*/ int result) {
    int result = 0;
    int startIndex = index;
    bool negative = current == '-';
    if (negative) {
      if (!moveNext()) {
        move(startIndex);
        return IParseResult.endOfString<int>(this);
      }
    }
    int count = 0;
    int digit;
    while (result < Platform.valueCursorPrediction && (digit = _getDigit()) != -1) {
      result = result * 10 + digit;
      count++;
      if (!moveNext()) {
        break;
      }
    }

    if (count == 0) {
      move(startIndex);
      return IParseResult.missingNumber<int>(this);
    }

    if (result >= Platform.valueCursorPrediction && (digit = _getDigit()) != -1) {
      if (result > Platform.valueCursorPrediction) {
        return _buildNumberOutOfRangeResult<int>(startIndex, tType);
      }
      if (negative && digit == 8) {
        moveNext();
        result = Platform.int64MinValue;
        return ParseResult.forValue<int>(result);
      }
      if (digit > 7) {
        return _buildNumberOutOfRangeResult<int>(startIndex, tType);
      }
      // We know we can cope with this digit...
      result = result * 10 + digit;
      moveNext();
      if (_getDigit() != -1) {
        // Too many digits. Die.
        return _buildNumberOutOfRangeResult<int>(startIndex, tType);
      }
    }
    if (negative) {
      result = -result;
    }

    return ParseResult.forValue<int>(result);
  }

  ParseResult<T> _buildNumberOutOfRangeResult<T>(int startIndex, String tType) {
    move(startIndex);
    if (current == '-') {
      moveNext();
    }
    // End of string works like not finding a digit.
    while (_getDigit() != -1) {
      moveNext();
    }
    String badValue = value.substring(startIndex, index /*- startIndex*/);
    move(startIndex);
    return IParseResult.valueOutOfRange<T>(this, badValue, tType);
  }

  /// Parses digits at the current point in the string, as an [Int64] value.
  /// If the minimum required
  /// digits are not present then the index is unchanged. If there are more digits than
  /// the maximum allowed they are ignored.
  ///
  /// [minimumDigits]: The minimum allowed digits.
  /// [maximumDigits]: The maximum allowed digits.
  /// [result]: The result integer value. The value of this is not guaranteed
  /// to be anything specific if the return value is false.
  /// Returns: `true` if the digits were parsed.
  int? parseInt64Digits(int minimumDigits, int maximumDigits) {
    int result = 0;
    int localIndex = index;
    int maxIndex = localIndex + maximumDigits;
    if (maxIndex >= length) {
      maxIndex = length;
    }
    for (; localIndex < maxIndex; localIndex++) {
      // Optimized digit handling: rather than checking for the range, returning -1
      // and then checking whether the result is -1, we can do both checks at once.
      int digit = value[localIndex].codeUnitAt(0) - _zeroCodeUnit;
      if (digit < 0 || digit > 9) {
        break;
      }
      result = result * 10 + digit;
    }
    int count = localIndex - index;
    if (count < minimumDigits) {
      return null;
    }
    move(localIndex);
    return result;
  }

  /// Parses digits at the current point in the string. If the minimum required
  /// digits are not present then the index is unchanged. If there are more digits than
  /// the maximum allowed they are ignored.
  ///
  /// [minimumDigits]: The minimum allowed digits.
  /// [maximumDigits]: The maximum allowed digits.
  /// [result]: The result integer value. The value of this is not guaranteed
  /// to be anything specific if the return value is false.
  /// Returns: `true` if the digits were parsed.
  int? parseDigits(int minimumDigits, int maximumDigits) {
    int result = 0;
    int localIndex = index;
    int maxIndex = localIndex + maximumDigits;
    if (maxIndex >= length) {
      maxIndex = length;
    }
    for (; localIndex < maxIndex; localIndex++) {
      // Optimized digit handling: rather than checking for the range, returning -1
      // and then checking whether the result is -1, we can do both checks at once.
      int digit = value[localIndex].codeUnitAt(0) - _zeroCodeUnit;
      if (digit < 0 || digit > 9) {
        break;
      }
      result = result * 10 + digit;
    }
    int count = localIndex - index;
    if (count < minimumDigits) {
      return null;
    }
    move(localIndex);
    return result;
  }

  /// Parses digits at the current point in the string as a fractional value.
  ///
  /// [maximumDigits]: The maximum allowed digits. Trusted to be less than or equal to scale.
  /// [scale]: The scale of the fractional value.
  /// [result]: The result value scaled by scale. The value of this is not guaranteed
  /// to be anything specific if the return value is false.
  /// [minimumDigits]: The minimum number of digits that must be specified in the value.
  /// Returns: `true` if the digits were parsed.
  int? parseFraction(int maximumDigits, int scale, int minimumDigits) {
    Preconditions.debugCheckArgument(maximumDigits <= scale, 'maximumDigits',
        'Must not allow more maximum digits than scale');

    int result = 0;
    int localIndex = index;
    int minIndex = localIndex + minimumDigits;
    if (minIndex > length) {
      // If we don't have all the digits we're meant to have, we can't possibly succeed.
      return null;
    }
    int maxIndex = math.min(localIndex + maximumDigits, length);
    for (; localIndex < maxIndex; localIndex++) {
      // Optimized digit handling: rather than checking for the range, returning -1
      // and then checking whether the result is -1, we can do both checks at once.
      int digit = value[localIndex].codeUnitAt(0) - _zeroCodeUnit;
      if (digit < 0 || digit > 9) {
        break;
      }
      result = result * 10 + digit;
    }
    int count = localIndex - index;
    // Couldn't parse the minimum number of digits required?
    if (count < minimumDigits) {
      return null;
    }
    result = (result * math.pow(10.0, scale - count).toInt());
    move(localIndex);
    return result;
  }

  /// Gets the integer value of the current digit character, or -1 for 'not a digit'.
  ///
  /// This currently only handles ASCII digits, which is all we have to parse to stay in line with the BCL.
  int _getDigit() {
    int c = current.codeUnitAt(0);
    return c < _zeroCodeUnit || c > _nineCodeUnit ? -1 : c - _zeroCodeUnit;
  }
}
