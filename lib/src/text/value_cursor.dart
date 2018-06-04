import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';
import 'package:time_machine/time_machine_text.dart';

@internal /*sealed*/ class ValueCursor extends TextCursor {
  // '0': 48; '9': 57
  static const int ZeroCodeUnit = 48;
  static const int NineCodeUnit = 57;

  /// <summary>
  ///   Initializes a new instance of the <see cref="ValueCursor" /> class.
  /// </summary>
  /// <param name="value">The string to parse.</param>
  @internal ValueCursor(String value)
      : super(value);

  /// <summary>
  ///   Attempts to match the specified character with the current character of the string. If the
  ///   character matches then the index is moved passed the character.
  /// </summary>
  /// <param name="character">The character to match.</param>
  /// <returns><c>true</c> if the character matches.</returns>
  @internal bool MatchSingle(String character) {
    assert(character.length == 1);
    if (Current == character) {
      MoveNext();
      return true;
    }
    return false;
  }

  /// <summary>
  /// Attempts to match the specified string with the current point in the string. If the
  /// character matches then the index is moved past the string.
  /// </summary>
  /// <param name="match">The string to match.</param>
  /// <returns><c>true</c> if the string matches.</returns>
  @internal bool MatchText(String match) {
    // string.CompareOrdinal(Value, Index, match, 0, match.length) == 0) {
    // Value, Index, match, 0, match.length
    if (stringOrdinalCompare(Value, Index, match, 0, match.length) == 0) {
      Move(Index + match.length);
      return true;
    }
    return false;
  }

  // todo: I don't think this is ever used (CompareInfo is a BCL class)
  /// <summary>
  /// Attempts to match the specified string with the current point in the string in a case-insensitive
  /// manner, according to the given comparison info. The cursor is optionally updated to the end of the match.
  /// </summary>
  @internal bool MatchCaseInsensitive(String match, CompareInfo compareInfo, bool moveOnSuccess) {
    if (match.length > Value.length - Index) {
      return false;
    }
    // Note: This will fail if the length in the input string is different to the length in the
    // match string for culture-specific reasons. It's not clear how to handle that...
    // See issue 210 for details - we're not intending to fix this, but it's annoying.
    if (stringOrdinalIgnoreCaseCompare(Value, Index, match, 0, match.length) == 0) {
      if (moveOnSuccess) {
        Move(Index + match.length);
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

  /// <summary>
  /// Compares the value from the current cursor position with the given match. If the
  /// given match string is longer than the remaining length, the comparison still goes
  /// ahead but the result is never 0: if the result of comparing to the end of the
  /// value returns 0, the result is -1 to indicate that the value is earlier than the given match.
  /// Conversely, if the remaining value is longer than the match string, the comparison only
  /// goes as far as the end of the match. So "xabcd" with the cursor at "a" will return 0 when
  /// matched with "abc".
  /// </summary>
  /// <returns>A negative number if the value (from the current cursor position) is lexicographically
  /// earlier than the given match string; 0 if they are equal (as far as the end of the match) and
  /// a positive number if the value is lexicographically later than the given match string.</returns>
  @internal int CompareOrdinal(String match) {
    int remaining = Value.length - Index;
    if (match.length > remaining) {
      // string.CompareOrdinal(Value, Index, match, 0, remaining);
      int ret = stringOrdinalCompare(Value, Index, match, 0, remaining); // Value.startsWith(match, Index);
      return ret == 0 ? -1 : ret;
    }
    // string.CompareOrdinal(Value, Index, match, 0, match.length);
    return stringOrdinalCompare(Value, Index, match, 0, match.length);
  }

  /// <summary>
  /// Parses digits at the current point in the string as a signed 64-bit integer value.
  /// Currently this method only supports cultures whose negative sign is "-" (and
  /// using ASCII digits).
  /// </summary>
  /// <param name="result">The result integer value. The value of this is not guaranteed
  /// to be anything specific if the return value is non-null.</param>
  /// <returns>null if the digits were parsed, or the appropriate parse failure</returns>
  // hack: we need to know what T is at runtime for error messages
  @internal ParseResult<T> ParseInt64<T>(OutBox<int> result, String tType) { ///*out*/ int result) {
    result.value = 0;
    int startIndex = Index;
    bool negative = Current == '-';
    if (negative) {
      if (!MoveNext()) {
        Move(startIndex);
        return ParseResult.EndOfString<T>(this);
      }
    }
    int count = 0;
    int digit;
    while (result.value < 922337203685477580 && (digit = GetDigit()) != -1) {
      result.value = result.value * 10 + digit;
      count++;
      if (!MoveNext()) {
        break;
      }
    }

    if (count == 0) {
      Move(startIndex);
      return ParseResult.MissingNumber<T>(this);
    }

    if (result.value >= 922337203685477580 && (digit = GetDigit()) != -1) {
      if (result.value > 922337203685477580) {
        return BuildNumberOutOfRangeResult<T>(startIndex, tType);
      }
      if (negative && digit == 8) {
        MoveNext();
        result.value = Utility.int64MinValue;
        return null;
      }
      if (digit > 7) {
        return BuildNumberOutOfRangeResult<T>(startIndex, tType);
      }
      // We know we can cope with this digit...
      result.value = result.value * 10 + digit;
      MoveNext();
      if (GetDigit() != -1) {
        // Too many digits. Die.
        return BuildNumberOutOfRangeResult<T>(startIndex, tType);
      }
    }
    if (negative) {
      result.value = -result.value;
    }

    return null;
  }

  @private ParseResult<T> BuildNumberOutOfRangeResult<T>(int startIndex, String tType) {
    Move(startIndex);
    if (Current == '-') {
      MoveNext();
    }
    // End of string works like not finding a digit.
    while (GetDigit() != -1) {
      MoveNext();
    }
    String badValue = Value.substring(startIndex, Index /*- startIndex*/);
    Move(startIndex);
    return ParseResult.ValueOutOfRange<T>(this, badValue, tType);
  }

  /// <summary>
  /// Parses digits at the current point in the string, as an <see cref="Int64"/> value.
  /// If the minimum required
  /// digits are not present then the index is unchanged. If there are more digits than
  /// the maximum allowed they are ignored.
  /// </summary>
  /// <param name="minimumDigits">The minimum allowed digits.</param>
  /// <param name="maximumDigits">The maximum allowed digits.</param>
  /// <param name="result">The result integer value. The value of this is not guaranteed
  /// to be anything specific if the return value is false.</param>
  /// <returns><c>true</c> if the digits were parsed.</returns>
  @internal int ParseInt64Digits(int minimumDigits, int maximumDigits) {
    int result = 0;
    int localIndex = Index;
    int maxIndex = localIndex + maximumDigits;
    if (maxIndex >= Length) {
      maxIndex = Length;
    }
    for (; localIndex < maxIndex; localIndex++) {
      // Optimized digit handling: rather than checking for the range, returning -1
      // and then checking whether the result is -1, we can do both checks at once.
      int digit = Value[localIndex].codeUnitAt(0) - ZeroCodeUnit;
      if (digit < 0 || digit > 9) {
        break;
      }
      result = result * 10 + digit;
    }
    int count = localIndex - Index;
    if (count < minimumDigits) {
      return null;
    }
    Move(localIndex);
    return result;
  }

  /// <summary>
  /// Parses digits at the current point in the string. If the minimum required
  /// digits are not present then the index is unchanged. If there are more digits than
  /// the maximum allowed they are ignored.
  /// </summary>
  /// <param name="minimumDigits">The minimum allowed digits.</param>
  /// <param name="maximumDigits">The maximum allowed digits.</param>
  /// <param name="result">The result integer value. The value of this is not guaranteed
  /// to be anything specific if the return value is false.</param>
  /// <returns><c>true</c> if the digits were parsed.</returns>
  @internal int ParseDigits(int minimumDigits, int maximumDigits) {
    int result = 0;
    int localIndex = Index;
    int maxIndex = localIndex + maximumDigits;
    if (maxIndex >= Length) {
      maxIndex = Length;
    }
    for (; localIndex < maxIndex; localIndex++) {
      // Optimized digit handling: rather than checking for the range, returning -1
      // and then checking whether the result is -1, we can do both checks at once.
      int digit = Value[localIndex].codeUnitAt(0) - ZeroCodeUnit;
      if (digit < 0 || digit > 9) {
        break;
      }
      result = result * 10 + digit;
    }
    int count = localIndex - Index;
    if (count < minimumDigits) {
      return null;
    }
    Move(localIndex);
    return result;
  }

  /// <summary>
  /// Parses digits at the current point in the string as a fractional value.
  /// </summary>
  /// <param name="maximumDigits">The maximum allowed digits. Trusted to be less than or equal to scale.</param>
  /// <param name="scale">The scale of the fractional value.</param>
  /// <param name="result">The result value scaled by scale. The value of this is not guaranteed
  /// to be anything specific if the return value is false.</param>
  /// <param name="minimumDigits">The minimum number of digits that must be specified in the value.</param>
  /// <returns><c>true</c> if the digits were parsed.</returns>
  @internal int ParseFraction(int maximumDigits, int scale, int minimumDigits) {
    Preconditions.debugCheckArgument(maximumDigits <= scale, 'maximumDigits',
        "Must not allow more maximum digits than scale");

    int result = 0;
    int localIndex = Index;
    int minIndex = localIndex + minimumDigits;
    if (minIndex > Length) {
      // If we don't have all the digits we're meant to have, we can't possibly succeed.
      return null;
    }
    int maxIndex = math.min(localIndex + maximumDigits, Length);
    for (; localIndex < maxIndex; localIndex++) {
      // Optimized digit handling: rather than checking for the range, returning -1
      // and then checking whether the result is -1, we can do both checks at once.
      int digit = Value[localIndex].codeUnitAt(0) - ZeroCodeUnit;
      if (digit < 0 || digit > 9) {
        break;
      }
      result = result * 10 + digit;
    }
    int count = localIndex - Index;
    // Couldn't parse the minimum number of digits required?
    if (count < minimumDigits) {
      return null;
    }
    result = (result * math.pow(10.0, scale - count).toInt());
    Move(localIndex);
    return result;
  }

  /// <summary>
  /// Gets the integer value of the current digit character, or -1 for "not a digit".
  /// </summary>
  /// <remarks>
  /// This currently only handles ASCII digits, which is all we have to parse to stay in line with the BCL.
  /// </remarks>
  @private int GetDigit() {
    int c = Current.codeUnitAt(0);
    return c < ZeroCodeUnit || c > NineCodeUnit ? -1 : c - ZeroCodeUnit;
  }
}