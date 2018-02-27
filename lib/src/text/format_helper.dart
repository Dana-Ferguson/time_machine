import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';
import 'package:time_machine/time_machine_text.dart';

/// <summary>
///   Provides helper methods for formatting values using pattern strings.
/// </summary>
@internal abstract class FormatHelper {
  // '0': 48; '9': 57
  static const int ZeroCodeUnit = 48;
  static const int NineCodeUnit = 57;

  /// <summary>
  /// The maximum number of characters allowed for padded values.
  /// </summary>
  @private static const int MaximumPaddingLength = 16;

  /// <summary>
  /// Maximum number of digits in a (positive) long.
  /// </summary>
  @private static const int MaximumInt64Length = 19;

  /// <summary>
  /// Formats the given value to two digits, left-padding with '0' if necessary.
  /// It is assumed that the value is in the range [0, 100). This is usually
  /// used for month, day-of-month, hour, minute, second and year-of-century values.
  /// </summary>
  @internal static void Format2DigitsNonNegative(int value, StringBuffer outputBuffer)
  {
    Preconditions.debugCheckArgumentRange('value', value, 0, 99);
    outputBuffer.writeCharCode(ZeroCodeUnit + value ~/ 10);
    outputBuffer.writeCharCode(ZeroCodeUnit + value % 10);
  }

  /// <summary>
  /// Formats the given value to two digits, left-padding with '0' if necessary.
  /// It is assumed that the value is in the range [-9999, 10000). This is usually
  /// used for year values. If the value is negative, a '-' character is prepended.
  /// </summary>
  @internal static void Format4DigitsValueFits(int value, StringBuffer outputBuffer) {
    Preconditions.debugCheckArgumentRange('value', value, -9999, 10000);
    if (value < 0) {
      value = -value;
      outputBuffer.write('-');
    }
    outputBuffer.writeCharCode((ZeroCodeUnit + (value ~/ 1000)));
    outputBuffer.writeCharCode((ZeroCodeUnit + ((value ~/ 100) % 10)));
    outputBuffer.writeCharCode((ZeroCodeUnit + ((value ~/ 10) % 10)));
    outputBuffer.writeCharCode((ZeroCodeUnit + (value % 10)));
  }

  /// <summary>
  /// Formats the given value left padded with zeros.
  /// </summary>
  /// <remarks>
  /// Left pads with zeros the value into a field of <paramref name = "length" /> characters. If the value
  /// is longer than <paramref name = "length" />, the entire value is formatted. If the value is negative,
  /// it is preceded by "-" but this does not count against the length.
  /// </remarks>
  /// <param name="value">The value to format.</param>
  /// <param name="length">The length to fill.</param>
  /// <param name="outputBuffer">The output buffer to add the digits to.</param>
  @internal static void LeftPad(int value, int length, StringBuffer outputBuffer) {
    Preconditions.debugCheckArgumentRange('length', length, 1, MaximumPaddingLength);
    if (value >= 0) {
      LeftPadNonNegative(value, length, outputBuffer);
      return;
    }
    outputBuffer.write('-');
    // Special case, as we can't use Math.Abs.
    if (value == Utility.int32MinValue) {
      if (length > 10) {
        outputBuffer.write("000000".substring(16 - length));
      }
      outputBuffer.write("2147483648");
      return;
    }
    LeftPadNonNegative(-value, length, outputBuffer);
  }

  /// <summary>
  /// Formats the given value left padded with zeros. The value is assumed to be non-negative.
  /// </summary>
  /// <remarks>
  /// Left pads with zeros the value into a field of <paramref name = "length" /> characters. If the value
  /// is longer than <paramref name = "length" />, the entire value is formatted. If the value is negative,
  /// it is preceded by "-" but this does not count against the length.
  /// </remarks>
  /// <param name="value">The value to format.</param>
  /// <param name="length">The length to fill.</param>
  /// <param name="outputBuffer">The output buffer to add the digits to.</param>
  @internal static void LeftPadNonNegative(int value, int length, StringBuffer outputBuffer) {
    Preconditions.debugCheckArgumentRange('value', value, 0, Utility.int32MaxValue);
    Preconditions.debugCheckArgumentRange('length', length, 1, MaximumPaddingLength);
    // Special handling for common cases, because we really don't want a heap allocation
    // if we can help it...
    if (length == 1) {
      if (value < 10) {
        outputBuffer.writeCharCode((ZeroCodeUnit + value));
        return;
      }
      // Handle overflow by a single character manually
      if (value < 100) {
        String digit1 = new String.fromCharCode(ZeroCodeUnit + (value ~/ 10));
        String digit2 = new String.fromCharCode(ZeroCodeUnit + (value % 10));
        outputBuffer..write(digit1)..write(digit2);
        return;
      }
    }
    if (length == 2 && value < 100) {
      String digit1 = new String.fromCharCode(ZeroCodeUnit + (value ~/ 10));
      String digit2 = new String.fromCharCode(ZeroCodeUnit + (value % 10));
      outputBuffer..write(digit1)..write(digit2);
      return;
    }
    if (length == 3 && value < 1000) {
      String digit1 = new String.fromCharCode(ZeroCodeUnit + ((value ~/ 100) % 10));
      String digit2 = new String.fromCharCode(ZeroCodeUnit + ((value ~/ 10) % 10));
      String digit3 = new String.fromCharCode(ZeroCodeUnit + (value % 10));
      outputBuffer..write(digit1)..write(digit2)..write(digit3);
      return;
    }
    if (length == 4 && value < 10000) {
      String digit1 = new String.fromCharCode(ZeroCodeUnit + (value ~/ 1000));
      String digit2 = new String.fromCharCode(ZeroCodeUnit + ((value ~/ 100) % 10));
      String digit3 = new String.fromCharCode(ZeroCodeUnit + ((value ~/ 10) % 10));
      String digit4 = new String.fromCharCode(ZeroCodeUnit + (value % 10));
      outputBuffer..write(digit1)..write(digit2)..write(digit3)..write(digit4);
      return;
    }
    if (length == 5 && value < 100000) {
      String digit1 = new String.fromCharCode(ZeroCodeUnit + (value ~/ 10000));
      String digit2 = new String.fromCharCode(ZeroCodeUnit + ((value ~/ 1000) % 10));
      String digit3 = new String.fromCharCode(ZeroCodeUnit + ((value ~/ 100) % 10));
      String digit4 = new String.fromCharCode(ZeroCodeUnit + ((value ~/ 10) % 10));
      String digit5 = new String.fromCharCode(ZeroCodeUnit + (value % 10));
      outputBuffer..write(digit1)..write(digit2)..write(digit3)..write(digit4)..write(digit5);
      return;
    }

    // Unfortunate, but never mind - let's go the whole hog...
    var digits = new List<String>(MaximumPaddingLength);
    int pos = MaximumPaddingLength;
    do {
      digits[--pos] = new String.fromCharCode(ZeroCodeUnit + (value % 10));
      value ~/= 10;
    } while (value != 0 && pos > 0);
    while ((MaximumPaddingLength - pos) < length) {
      digits[--pos] = '0';
    }

    outputBuffer.writeAll(digits.skip(pos).take(MaximumPaddingLength - pos)); //.write(digits, pos, MaximumPaddingLength - pos);
  }

  /// <summary>
  /// Formats the given Int64 value left padded with zeros. The value is assumed to be non-negative.
  /// </summary>
  /// <remarks>
  /// Left pads with zeros the value into a field of <paramref name = "length" /> characters. If the value
  /// is longer than <paramref name = "length" />, the entire value is formatted. If the value is negative,
  /// it is preceded by "-" but this does not count against the length.
  /// </remarks>
  /// <param name="value">The value to format.</param>
  /// <param name="length">The length to fill.</param>
  /// <param name="outputBuffer">The output buffer to add the digits to.</param>
  @internal static void LeftPadNonNegativeInt64(int value, int length, StringBuffer outputBuffer) {
    Preconditions.debugCheckArgumentRange('value', value, 0, Utility.int64MaxValue);
    Preconditions.debugCheckArgumentRange('length', length, 1, MaximumPaddingLength);
    // Special handling for common cases, because we really don't want a heap allocation
    // if we can help it...
    if (length == 1) {
      if (value < 10) {
        outputBuffer.writeCharCode((ZeroCodeUnit + value));
        return;
      }
      // Handle overflow by a single character manually
      if (value < 100) {
        String digit1 = new String.fromCharCode(ZeroCodeUnit + (value ~/ 10));
        String digit2 = new String.fromCharCode(ZeroCodeUnit + (value % 10));
        outputBuffer..write(digit1)..write(digit2);
        return;
      }
    }
    if (length == 2 && value < 100) {
      String digit1 = new String.fromCharCode(ZeroCodeUnit + (value ~/ 10));
      String digit2 = new String.fromCharCode(ZeroCodeUnit + (value % 10));
      outputBuffer..write(digit1)..write(digit2);
      return;
    }
    if (length == 3 && value < 1000) {
      String digit1 = new String.fromCharCode(ZeroCodeUnit + ((value ~/ 100) % 10));
      String digit2 = new String.fromCharCode(ZeroCodeUnit + ((value ~/ 10) % 10));
      String digit3 = new String.fromCharCode(ZeroCodeUnit + (value % 10));
      outputBuffer..write(digit1)..write(digit2)..write(digit3);
      return;
    }
    if (length == 4 && value < 10000) {
      String digit1 = new String.fromCharCode(ZeroCodeUnit + (value ~/ 1000));
      String digit2 = new String.fromCharCode(ZeroCodeUnit + ((value ~/ 100) % 10));
      String digit3 = new String.fromCharCode(ZeroCodeUnit + ((value ~/ 10) % 10));
      String digit4 = new String.fromCharCode(ZeroCodeUnit + (value % 10));
      outputBuffer..write(digit1)..write(digit2)..write(digit3)..write(digit4);
      return;
    }
    if (length == 5 && value < 100000) {
      String digit1 = new String.fromCharCode(ZeroCodeUnit + (value ~/ 10000));
      String digit2 = new String.fromCharCode(ZeroCodeUnit + ((value ~/ 1000) % 10));
      String digit3 = new String.fromCharCode(ZeroCodeUnit + ((value ~/ 100) % 10));
      String digit4 = new String.fromCharCode(ZeroCodeUnit + ((value ~/ 10) % 10));
      String digit5 = new String.fromCharCode(ZeroCodeUnit + (value % 10));
      outputBuffer..write(digit1)..write(digit2)..write(digit3)..write(digit4)..write(digit5);
      return;
    }

    // Unfortunate, but never mind - let's go the whole hog...
    var digits = new List<String>(MaximumPaddingLength);
    int pos = MaximumPaddingLength;
    do {
      digits[--pos] = new String.fromCharCode(ZeroCodeUnit + (value % 10));
      value ~/= 10;
    } while (value != 0 && pos > 0);
    while ((MaximumPaddingLength - pos) < length) {
      digits[--pos] = '0';
    }

    outputBuffer.writeAll(digits.skip(pos).take(MaximumPaddingLength - pos)); //.write(digits, pos, MaximumPaddingLength - pos);
  }

  /// <summary>
  /// Formats the given value, which is an integer representation of a fraction.
  /// Note: current usage means this never has to cope with negative numbers.
  /// </summary>
  /// <example>
  /// <c>AppendFraction(1200, 4, 5, builder)</c> will result in "0120" being
  /// appended to the builder. The value is treated as effectively 0.01200 because
  /// the scale is 5, but only 4 digits are formatted.
  /// </example>
  /// <param name="value">The value to format.</param>
  /// <param name="length">The length to fill. Must be at most <paramref name="scale"/>.</param>
  /// <param name="scale">The scale of the value i.e. the number of significant digits is the range of the value. Must be in the range [1, 7].</param>
  /// <param name="outputBuffer">The output buffer to add the digits to.</param>
  @internal static void AppendFraction(int value, int length, int scale, StringBuffer outputBuffer) {
    int relevantDigits = value;
    while (scale > length)
    {
      relevantDigits ~/= 10;
      scale--;
    }

    // todo: hack around StringBuffer not being indexable, find a better hack?
    var myOutputBuffer = new List<String>.filled(length, '0');
    // for (int i = 0; i < length; i++) outputBuffer.write('0'); //, length);
    int index = myOutputBuffer.length - 1;
    while (relevantDigits > 0)
    {
      myOutputBuffer[index--] = new String.fromCharCode(ZeroCodeUnit + (relevantDigits % 10));
      relevantDigits ~/= 10;
    }

    outputBuffer.writeAll(myOutputBuffer);
  }

  /// <summary>
  /// Formats the given value, which is an integer representation of a fraction,
  /// truncating any right-most zero digits.
  /// If the entire value is truncated then the preceeding decimal separater is also removed.
  /// Note: current usage means this never has to cope with negative numbers.
  /// </summary>
  /// <example>
  /// <c>AppendFractionTruncate(1200, 4, 5, builder)</c> will result in "001" being
  /// appended to the builder. The value is treated as effectively 0.01200 because
  /// the scale is 5; only 4 digits are formatted (leaving "0120") and then the rightmost
  /// 0 digit is truncated.
  /// </example>
  /// <param name="value">The value to format.</param>
  /// <param name="length">The length to fill. Must be at most <paramref name="scale"/>.</param>
  /// <param name="scale">The scale of the value i.e. the number of significant digits is the range of the value. Must be in the range [1, 7].</param>
  /// <param name="outputBuffer">The output buffer to add the digits to.</param>
  @internal static void AppendFractionTruncate(int value, int length, int scale, StringBuffer outputBuffer) {
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

    var buffer = new List<String>.filled(relevantLength, '0');

    if (relevantLength > 0)
    {
      // outputBuffer.write('0', relevantLength);
      int index = outputBuffer.length - 1;
      while (relevantDigits > 0)
      {
        buffer[index--] = new String.fromCharCode(ZeroCodeUnit + (relevantDigits % 10));
        relevantDigits ~/= 10;
      }

      outputBuffer.writeAll(buffer);
    }
    else if (buffer.length > 0 && buffer[buffer.length - 1] == '.')
    {
      // buffer.length--;
      outputBuffer.writeAll(buffer.take(buffer.length-1));
    }
  }

  /// <summary>
  /// Formats the given value using the invariant culture, with no truncation or padding.
  /// </summary>
  /// <param name="value">The value to format.</param>
  /// <param name="outputBuffer">The output buffer to add the digits to.</param>
  @internal static void FormatInvariant(int value, StringBuffer outputBuffer) {
    if (value <= 0) {
      if (value == 0) {
        outputBuffer.write('0');
        return;
      }
      if (value == Utility.int64MinValue) {
        outputBuffer.write("-9223372036854775808");
        return;
      }
      outputBuffer.write('-');
      FormatInvariant(-value, outputBuffer);
      return;
    }
    // Optimize common small cases (particularly for periods)
    if (value < 10) {
      outputBuffer.writeCharCode((ZeroCodeUnit + value));
      return;
    }
    if (value < 100) {
      String digit1 = new String.fromCharCode(ZeroCodeUnit + (value ~/ 10));
      String digit2 = new String.fromCharCode(ZeroCodeUnit + (value % 10));
      outputBuffer..write(digit1)..write(digit2);
      return;
    }
    if (value < 1000) {
      String digit1 = new String.fromCharCode(ZeroCodeUnit + ((value ~/ 100) % 10));
      String digit2 = new String.fromCharCode(ZeroCodeUnit + ((value ~/ 10) % 10));
      String digit3 = new String.fromCharCode(ZeroCodeUnit + (value % 10));
      outputBuffer..write(digit1)..write(digit2)..write(digit3);
      return;
    }

    var digits = new List<String>(MaximumInt64Length);
    int pos = MaximumInt64Length;
    do {
      digits[--pos] = new String.fromCharCode(ZeroCodeUnit + (value % 10));
      value ~/= 10;
    } while (value != 0);
    // outputBuffer.write(digits, pos, MaximumInt64Length - pos);
    outputBuffer.writeAll(digits.skip(pos).take(MaximumInt64Length - pos));
  }
}