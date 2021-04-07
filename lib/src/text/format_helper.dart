// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';

///   Provides helper methods for formatting values using pattern strings.
@internal
abstract class FormatHelper {
  // '0': 48; '9': 57
  static const int _zeroCodeUnit = 48;
  // ignore: unused_field
  static const int _nineCodeUnit = 57;

  /// The maximum number of characters allowed for padded values.
  static const int _maximumPaddingLength = 16;

  /// Maximum number of digits in a (positive) long.
  static const int _maximumInt64Length = 19;

  /// Formats the given value to two digits, left-padding with '0' if necessary.
  /// It is assumed that the value is in the range [0, 100). This is usually
  /// used for month, day-of-month, hour, minute, second and year-of-century values.
  static void format2DigitsNonNegative(int value, StringBuffer outputBuffer)
  {
    Preconditions.debugCheckArgumentRange('value', value, 0, 99);
    outputBuffer.writeCharCode(_zeroCodeUnit + value ~/ 10);
    outputBuffer.writeCharCode(_zeroCodeUnit + value % 10);
  }

  /// Formats the given value to two digits, left-padding with '0' if necessary.
  /// It is assumed that the value is in the range [-9999, 10000). This is usually
  /// used for year values. If the value is negative, a '-' character is prepended.
  static void format4DigitsValueFits(int value, StringBuffer outputBuffer) {
    Preconditions.debugCheckArgumentRange('value', value, -9999, 10000);
    if (value < 0) {
      value = -value;
      outputBuffer.write('-');
    }
    outputBuffer.writeCharCode((_zeroCodeUnit + (value ~/ 1000)));
    outputBuffer.writeCharCode((_zeroCodeUnit + ((value ~/ 100) % 10)));
    outputBuffer.writeCharCode((_zeroCodeUnit + ((value ~/ 10) % 10)));
    outputBuffer.writeCharCode((_zeroCodeUnit + (value % 10)));
  }

  /// Formats the given value left padded with zeros.
  ///
  /// Left pads with zeros the value into a field of <paramref name = 'length' /> characters. If the value
  /// is longer than <paramref name = 'length' />, the entire value is formatted. If the value is negative,
  /// it is preceded by '-' but this does not count against the length.
  ///
  /// [value]: The value to format.
  /// [length]: The length to fill.
  /// [outputBuffer]: The output buffer to add the digits to.
  static void leftPad(int value, int length, StringBuffer outputBuffer) {
    Preconditions.debugCheckArgumentRange('length', length, 1, _maximumPaddingLength);
    if (value >= 0) {
      leftPadNonNegative(value, length, outputBuffer);
      return;
    }
    outputBuffer.write('-');
    // Special case, as we can't use Math.Abs.
    if (value == Platform.int32MinValue) {
      if (length > 10) {
        outputBuffer.write('000000'.substring(16 - length));
      }
      outputBuffer.write('2147483648');
      return;
    }
    leftPadNonNegative(-value, length, outputBuffer);
  }

  /// Formats the given value left padded with zeros. The value is assumed to be non-negative.
  ///
  /// Left pads with zeros the value into a field of <paramref name = 'length' /> characters. If the value
  /// is longer than <paramref name = 'length' />, the entire value is formatted. If the value is negative,
  /// it is preceded by '-' but this does not count against the length.
  ///
  /// [value]: The value to format.
  /// [length]: The length to fill.
  /// [outputBuffer]: The output buffer to add the digits to.
  static void leftPadNonNegative(int value, int length, StringBuffer outputBuffer) {
    Preconditions.debugCheckArgumentRange('value', value, 0, Platform.int32MaxValue);
    Preconditions.debugCheckArgumentRange('length', length, 1, _maximumPaddingLength);
    // Special handling for common cases, because we really don't want a heap allocation
    // if we can help it...
    if (length == 1) {
      if (value < 10) {
        outputBuffer.writeCharCode((_zeroCodeUnit + value));
        return;
      }
      // Handle overflow by a single character manually
      if (value < 100) {
        String digit1 = String.fromCharCode(_zeroCodeUnit + (value ~/ 10));
        String digit2 = String.fromCharCode(_zeroCodeUnit + (value % 10));
        outputBuffer..write(digit1)..write(digit2);
        return;
      }
    }
    if (length == 2 && value < 100) {
      String digit1 = String.fromCharCode(_zeroCodeUnit + (value ~/ 10));
      String digit2 = String.fromCharCode(_zeroCodeUnit + (value % 10));
      outputBuffer..write(digit1)..write(digit2);
      return;
    }
    if (length == 3 && value < 1000) {
      String digit1 = String.fromCharCode(_zeroCodeUnit + ((value ~/ 100) % 10));
      String digit2 = String.fromCharCode(_zeroCodeUnit + ((value ~/ 10) % 10));
      String digit3 = String.fromCharCode(_zeroCodeUnit + (value % 10));
      outputBuffer..write(digit1)..write(digit2)..write(digit3);
      return;
    }
    if (length == 4 && value < 10000) {
      String digit1 = String.fromCharCode(_zeroCodeUnit + (value ~/ 1000));
      String digit2 = String.fromCharCode(_zeroCodeUnit + ((value ~/ 100) % 10));
      String digit3 = String.fromCharCode(_zeroCodeUnit + ((value ~/ 10) % 10));
      String digit4 = String.fromCharCode(_zeroCodeUnit + (value % 10));
      outputBuffer..write(digit1)..write(digit2)..write(digit3)..write(digit4);
      return;
    }
    if (length == 5 && value < 100000) {
      String digit1 = String.fromCharCode(_zeroCodeUnit + (value ~/ 10000));
      String digit2 = String.fromCharCode(_zeroCodeUnit + ((value ~/ 1000) % 10));
      String digit3 = String.fromCharCode(_zeroCodeUnit + ((value ~/ 100) % 10));
      String digit4 = String.fromCharCode(_zeroCodeUnit + ((value ~/ 10) % 10));
      String digit5 = String.fromCharCode(_zeroCodeUnit + (value % 10));
      outputBuffer..write(digit1)..write(digit2)..write(digit3)..write(digit4)..write(digit5);
      return;
    }

    // Unfortunate, but never mind - let's go the whole hog...
    var digits = List<String>.filled(_maximumPaddingLength, '');
    int pos = _maximumPaddingLength;
    do {
      digits[--pos] = String.fromCharCode(_zeroCodeUnit + (value % 10));
      value ~/= 10;
    } while (value != 0 && pos > 0);
    while ((_maximumPaddingLength - pos) < length) {
      digits[--pos] = '0';
    }

    outputBuffer.writeAll(digits.skip(pos).take(_maximumPaddingLength - pos)); //.write(digits, pos, MaximumPaddingLength - pos);
  }

  /// Formats the given Int64 value left padded with zeros. The value is assumed to be non-negative.
  ///
  /// Left pads with zeros the value into a field of <paramref name = 'length' /> characters. If the value
  /// is longer than <paramref name = 'length' />, the entire value is formatted. If the value is negative,
  /// it is preceded by '-' but this does not count against the length.
  ///
  /// [value]: The value to format.
  /// [length]: The length to fill.
  /// [outputBuffer]: The output buffer to add the digits to.
  static void leftPadNonNegativeInt64(int value, int length, StringBuffer outputBuffer) {
    Preconditions.debugCheckArgumentRange('value', value, 0, Platform.int64MaxValue);
    Preconditions.debugCheckArgumentRange('length', length, 1, _maximumPaddingLength);
    // Special handling for common cases, because we really don't want a heap allocation
    // if we can help it...
    if (length == 1) {
      if (value < 10) {
        outputBuffer.writeCharCode((_zeroCodeUnit + value));
        return;
      }
      // Handle overflow by a single character manually
      if (value < 100) {
        String digit1 = String.fromCharCode(_zeroCodeUnit + (value ~/ 10));
        String digit2 = String.fromCharCode(_zeroCodeUnit + (value % 10));
        outputBuffer..write(digit1)..write(digit2);
        return;
      }
    }
    if (length == 2 && value < 100) {
      String digit1 = String.fromCharCode(_zeroCodeUnit + (value ~/ 10));
      String digit2 = String.fromCharCode(_zeroCodeUnit + (value % 10));
      outputBuffer..write(digit1)..write(digit2);
      return;
    }
    if (length == 3 && value < 1000) {
      String digit1 = String.fromCharCode(_zeroCodeUnit + ((value ~/ 100) % 10));
      String digit2 = String.fromCharCode(_zeroCodeUnit + ((value ~/ 10) % 10));
      String digit3 = String.fromCharCode(_zeroCodeUnit + (value % 10));
      outputBuffer..write(digit1)..write(digit2)..write(digit3);
      return;
    }
    if (length == 4 && value < 10000) {
      String digit1 = String.fromCharCode(_zeroCodeUnit + (value ~/ 1000));
      String digit2 = String.fromCharCode(_zeroCodeUnit + ((value ~/ 100) % 10));
      String digit3 = String.fromCharCode(_zeroCodeUnit + ((value ~/ 10) % 10));
      String digit4 = String.fromCharCode(_zeroCodeUnit + (value % 10));
      outputBuffer..write(digit1)..write(digit2)..write(digit3)..write(digit4);
      return;
    }
    if (length == 5 && value < 100000) {
      String digit1 = String.fromCharCode(_zeroCodeUnit + (value ~/ 10000));
      String digit2 = String.fromCharCode(_zeroCodeUnit + ((value ~/ 1000) % 10));
      String digit3 = String.fromCharCode(_zeroCodeUnit + ((value ~/ 100) % 10));
      String digit4 = String.fromCharCode(_zeroCodeUnit + ((value ~/ 10) % 10));
      String digit5 = String.fromCharCode(_zeroCodeUnit + (value % 10));
      outputBuffer..write(digit1)..write(digit2)..write(digit3)..write(digit4)..write(digit5);
      return;
    }

    // Unfortunate, but never mind - let's go the whole hog...
    var digits = List<String>.filled(_maximumPaddingLength, '');
    int pos = _maximumPaddingLength;
    do {
      digits[--pos] = String.fromCharCode(_zeroCodeUnit + (value % 10));
      value ~/= 10;
    } while (value != 0 && pos > 0);
    while ((_maximumPaddingLength - pos) < length) {
      digits[--pos] = '0';
    }

    outputBuffer.writeAll(digits.skip(pos).take(_maximumPaddingLength - pos)); //.write(digits, pos, MaximumPaddingLength - pos);
  }

  /// Formats the given value, which is an integer representation of a fraction.
  /// Note: current usage means this never has to cope with negative numbers.
  ///
  /// <example>
  /// `AppendFraction(1200, 4, 5, builder)` will result in '0120' being
  /// appended to the builder. The value is treated as effectively 0.01200 because
  /// the scale is 5, but only 4 digits are formatted.
  /// </example>
  /// [value]: The value to format.
  /// [length]: The length to fill. Must be at most [scale].
  /// [scale]: The scale of the value i.e. the number of significant digits is the range of the value. Must be in the range [1, 7].
  /// [outputBuffer]: The output buffer to add the digits to.
  static void appendFraction(int value, int length, int scale, StringBuffer outputBuffer) {
    int relevantDigits = value;
    while (scale > length)
    {
      relevantDigits ~/= 10;
      scale--;
    }

    // todo: hack around StringBuffer not being indexable, find a better hack?
    var myOutputBuffer = List<String>.filled(length, '0');
    // for (int i = 0; i < length; i++) outputBuffer.write('0'); //, length);
    int index = myOutputBuffer.length - 1;
    while (relevantDigits > 0)
    {
      myOutputBuffer[index--] = String.fromCharCode(_zeroCodeUnit + (relevantDigits % 10));
      relevantDigits ~/= 10;
    }

    outputBuffer.writeAll(myOutputBuffer);
  }

  /// Formats the given value, which is an integer representation of a fraction,
  /// truncating any right-most zero digits.
  /// If the entire value is truncated then the preceeding decimal separater is also removed.
  /// Note: current usage means this never has to cope with negative numbers.
  ///
  /// <example>
  /// `AppendFractionTruncate(1200, 4, 5, builder)` will result in '001' being
  /// appended to the builder. The value is treated as effectively 0.01200 because
  /// the scale is 5; only 4 digits are formatted (leaving '0120') and then the rightmost
  /// 0 digit is truncated.
  /// </example>
  /// [value]: The value to format.
  /// [length]: The length to fill. Must be at most [scale].
  /// [scale]: The scale of the value i.e. the number of significant digits is the range of the value. Must be in the range [1, 7].
  /// [outputBuffer]: The output buffer to add the digits to.
  static void appendFractionTruncate(int value, int length, int scale, StringBuffer outputBuffer) {
    int relevantDigits = value;
    while (scale > length)
    {
      relevantDigits ~/= 10;
      scale--;
    }
    int relevantLength = length;
    while (relevantLength > 0)
    {
      if ((relevantDigits % 10) != 0)
      {
        break;
      }
      relevantDigits ~/= 10;
      relevantLength--;
    }

    // note: StringBuffer doesn't have [index] semantics and can't be contracted
    // so... we have to go through some gymnastics here, todo: definitely some optimization is possible here
    if (relevantLength > 0)
    {
      var buffer = List<String>.filled(relevantLength, '0', growable: false);

      // outputBuffer.Append('0', relevantLength);
      int index = /*outputBuffer*/buffer.length - 1;
      while (relevantDigits > 0)
      {
        buffer[index--] = String.fromCharCode(_zeroCodeUnit + (relevantDigits % 10));
        relevantDigits ~/= 10;
      }

      outputBuffer.writeAll(buffer);
    }
    else if (outputBuffer.length > 0) {
      var buffer = outputBuffer.toString();
      if (buffer.endsWith('.')) {
        // buffer.length--;
        outputBuffer.clear();
        outputBuffer.write(buffer.substring(0, buffer.length-1));
      }
    }
  }

  /// Formats the given value using the invariant culture, with no truncation or padding.
  ///
  /// [value]: The value to format.
  /// [outputBuffer]: The output buffer to add the digits to.
  static void formatInvariant(int value, StringBuffer outputBuffer) {
    if (value <= 0) {
      if (value == 0) {
        outputBuffer.write('0');
        return;
      }
      if (value == Platform.int64MinValue) {
        outputBuffer.write('-9223372036854775808');
        return;
      }
      outputBuffer.write('-');
      formatInvariant(-value, outputBuffer);
      return;
    }
    // Optimize common small cases (particularly for periods)
    if (value < 10) {
      outputBuffer.writeCharCode((_zeroCodeUnit + value));
      return;
    }
    if (value < 100) {
      String digit1 = String.fromCharCode(_zeroCodeUnit + (value ~/ 10));
      String digit2 = String.fromCharCode(_zeroCodeUnit + (value % 10));
      outputBuffer..write(digit1)..write(digit2);
      return;
    }
    if (value < 1000) {
      String digit1 = String.fromCharCode(_zeroCodeUnit + ((value ~/ 100) % 10));
      String digit2 = String.fromCharCode(_zeroCodeUnit + ((value ~/ 10) % 10));
      String digit3 = String.fromCharCode(_zeroCodeUnit + (value % 10));
      outputBuffer..write(digit1)..write(digit2)..write(digit3);
      return;
    }

    var digits = List<String>.filled(_maximumInt64Length, '');
    int pos = _maximumInt64Length;
    do {
      digits[--pos] = String.fromCharCode(_zeroCodeUnit + (value % 10));
      value ~/= 10;
    } while (value != 0);
    // outputBuffer.write(digits, pos, MaximumInt64Length - pos);
    outputBuffer.writeAll(digits.skip(pos).take(_maximumInt64Length - pos));
  }
}
