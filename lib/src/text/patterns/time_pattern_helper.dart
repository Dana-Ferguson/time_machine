// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/text/patterns/time_machine_patterns.dart';

/// Common methods used when parsing dates - these are used from LocalDateTimePatternParser,
/// OffsetPatternParser and LocalTimePatternParser.
@internal
abstract class TimePatternHelper
{
  /// Creates a character handler for a dot (period). This is *not* culture sensitive - it is
  /// always treated as a literal, but with the additional behaviour that if it's followed by an 'F' pattern,
  /// that makes the period optional.
  static CharacterHandler<TResult, TBucket> createPeriodHandler<TResult, TBucket extends ParseBucket<TResult>>
      (int maxCount, int Function(TResult) getter, Function(TBucket, int) setter) {
    return(PatternCursor pattern, SteppedPatternBuilder<TResult, TBucket> builder) {
      // Note: Deliberately *not* using the decimal separator of the culture - see issue 21.

      // If the next part of the pattern is an F, then this decimal separator is effectively optional.
      // At parse time, we need to check whether we've matched the decimal separator. If we have, match the fractional
      // seconds part as normal. Otherwise, we continue on to the next parsing token.
      // At format time, we should always append the decimal separator, and then append using PadRightTruncate.
      if (pattern.peekNext() == 'F') {
        pattern.moveNext();
        int count = pattern.getRepeatCount(maxCount);
        builder.addField(PatternFields.fractionalSeconds, pattern.current);
        builder.addParseAction((ValueCursor valueCursor, TBucket bucket) {
          // If the next token isn't the decimal separator, we assume it's part of the next token in the pattern
          if (!valueCursor.matchSingle('.')) {
            return null;
          }

          // If there *was* a decimal separator, we should definitely have a number.
          // Last argument is 1 because we need at least one digit after the decimal separator
          var fractionalSeconds = valueCursor.parseFraction(count, maxCount, 1);
          if (fractionalSeconds == null) {
            return IParseResult.mismatchedNumber<TResult>(valueCursor, stringFilled('F', count));
          }
          // No need to validate the value - we've got one to three digits, so the range 0-999 is guaranteed.
          setter(bucket, fractionalSeconds);
          return null;
        });
        builder.addFormatAction((localTime, StringBuffer sb) => sb.write('.'));
        builder.addFormatFractionTruncate(count, maxCount, getter);
      }
      else {
        builder.addLiteral2('.', IParseResult.mismatchedCharacter);
      }
    };
  }

  /// Creates a character handler for a dot (period) or comma, which have the same meaning.
  /// Formatting always uses a dot, but parsing will allow a comma instead, to conform with
  /// ISO-8601. This is *not* culture sensitive.
  static CharacterHandler<TResult, TBucket> createCommaDotHandler<TResult, TBucket extends ParseBucket<TResult>>
      (int maxCount, int Function(TResult) getter, Function(TBucket, int) setter) {
    return (PatternCursor pattern, SteppedPatternBuilder<TResult, TBucket> builder) {
// Note: Deliberately *not* using the decimal separator of the culture - see issue 21.

      // If the next part of the pattern is an F, then this decimal separator is effectively optional.
      // At parse time, we need to check whether we've matched the decimal separator. If we have, match the fractional
      // seconds part as normal. Otherwise, we continue on to the next parsing token.
      // At format time, we should always append the decimal separator, and then append using PadRightTruncate.
      if (pattern.peekNext() == 'F') {
        pattern.moveNext();
        int count = pattern.getRepeatCount(maxCount);
        builder.addField(PatternFields.fractionalSeconds, pattern.current);
        builder.addParseAction((ValueCursor valueCursor, TBucket bucket) {
          // If the next token isn't a dot or comma, we assume
          // it's part of the next token in the pattern
          // todo: dart: look for this in other places; had to add 'valueCursor.Index >= valueCursor.Length' because our Match's stringOrdinalCompare doesn't work quite the same
          if (valueCursor.index >= valueCursor.length || (!valueCursor.matchSingle('.') && !valueCursor.matchSingle(','))) {
            return null;
          }

          // If there *was* a decimal separator, we should definitely have a number.
          int? fractionalSeconds = valueCursor.parseFraction(count, maxCount, 1);
          // Last argument is 1 because we need at least one digit to be present after a decimal separator
          if (fractionalSeconds == null) {
            return IParseResult.mismatchedNumber<TResult>(valueCursor, stringFilled('F', count));
          }
          // No need to validate the value - we've got an appropriate number of digits, so the range is guaranteed.
          setter(bucket, fractionalSeconds);
          return null;
        });
        builder.addFormatAction((TResult localTime, StringBuffer sb) => sb.write('.'));
        builder.addFormatFractionTruncate(count, maxCount, getter);
      }
      else {
        builder.addParseAction((ValueCursor str, ParseBucket bucket) =>
        str.matchSingle('.') || str.matchSingle(',')
            ? null
            : IParseResult.mismatchedCharacter<TResult>(str, ';'));
        builder.addFormatAction((TResult value, StringBuffer sb) => sb.write('.'));
      }
    };
  }

  /// Creates a character handler to handle the 'fraction of a second' specifier (f or F).
  static CharacterHandler<TResult, TBucket> createFractionHandler<TResult, TBucket extends ParseBucket<TResult>>
      (int maxCount, int Function(TResult) getter, Function(TBucket, int) setter) {
    return (PatternCursor pattern, SteppedPatternBuilder<TResult, TBucket> builder) {
      String patternCharacter = pattern.current;
      int count = pattern.getRepeatCount(maxCount);
      builder.addField(PatternFields.fractionalSeconds, pattern.current);

      builder.addParseAction((ValueCursor str, TBucket bucket) {
        int? fractionalSeconds = str.parseFraction(count, maxCount, patternCharacter == 'f' ? count : 0);
        // If the pattern is 'f', we need exactly "count" digits. Otherwise ('F') we need
        // 'up to count' digits.
        if (fractionalSeconds == null) {
          return IParseResult.mismatchedNumber<TResult>(str, stringFilled(patternCharacter, count));
        }
        // No need to validate the value - we've got an appropriate number of digits, so the range is guaranteed.
        setter(bucket, fractionalSeconds);
        return null;
      });
      if (patternCharacter == 'f') {
        builder.addFormatFraction(count, maxCount, getter);
      }
      else {
        builder.addFormatFractionTruncate(count, maxCount, getter);
      }
    };
  }

  static CharacterHandler<TResult, TBucket> createAmPmHandler<TResult, TBucket extends ParseBucket<TResult>>
      (int Function(TResult) hourOfDayGetter, Function(TBucket, int) amPmSetter) {
    return(PatternCursor pattern, SteppedPatternBuilder<TResult, TBucket> builder) {
      int count = pattern.getRepeatCount(2);
      builder.addField(PatternFields.amPm, pattern.current);

      String amDesignator = builder.formatInfo.amDesignator;
      String pmDesignator = builder.formatInfo.pmDesignator;

      // If we don't have an AM or PM designator, we're nearly done. Set the AM/PM designator
      // to the special value of 2, meaning 'take it from the template'.
      if (amDesignator == '' && pmDesignator == "") {
        Null _parseAction(ValueCursor str, TBucket bucket) {
          amPmSetter(bucket, 2);
          return null;
        }

        builder.addParseAction(_parseAction);
        return;
      }
      // Odd scenario (but present in af-ZA for .NET 2) - exactly one of the AM/PM designator is valid.
      // Delegate to a separate method to keep this clearer...
      if (amDesignator == '' || pmDesignator == "") {
        int specifiedDesignatorValue = amDesignator == '' ? 1 : 0;
        String specifiedDesignator = specifiedDesignatorValue == 1 ? pmDesignator : amDesignator;
        TimePatternHelper._handleHalfAmPmDesignator(count, specifiedDesignator, specifiedDesignatorValue, hourOfDayGetter, amPmSetter, builder);
        return;
      }

      CompareInfo? compareInfo = builder.formatInfo.compareInfo;
      // Single character designator
      if (count == 1) {
        // It's not entirely clear whether this is the right thing to do... there's no nice
        // way of providing a single-character case-insensitive match.
        String amFirst = amDesignator.substring(0, 1);
        String pmFirst = pmDesignator.substring(0, 1);

        builder.addParseAction((ValueCursor str, TBucket bucket) {
          if (str.matchCaseInsensitive(amFirst, compareInfo, true)) {
            amPmSetter(bucket, 0);
            return null;
          }
          if (str.matchCaseInsensitive(pmFirst, compareInfo, true)) {
            amPmSetter(bucket, 1);
            return null;
          }
          return IParseResult.missingAmPmDesignator<TResult>(str);
        });
        builder.addFormatAction((value, sb) => sb.write(hourOfDayGetter(value) > 11 ? pmDesignator[0] : amDesignator[0]));
        return;
      }

      // Full designator
      builder.addParseAction((ValueCursor str, TBucket bucket) {
        // Could use the 'match longest' approach, but with only two it feels a bit silly to build a list...
        bool pmLongerThanAm = pmDesignator.length > amDesignator.length;
        String longerDesignator = pmLongerThanAm ? pmDesignator : amDesignator;
        String shorterDesignator = pmLongerThanAm ? amDesignator : pmDesignator;
        int longerValue = pmLongerThanAm ? 1 : 0;
        if (str.matchCaseInsensitive(longerDesignator, compareInfo, true)) {
          amPmSetter(bucket, longerValue);
          return null;
        }
        if (str.matchCaseInsensitive(shorterDesignator, compareInfo, true)) {
          amPmSetter(bucket, 1 - longerValue);
          return null;
        }
        return IParseResult.missingAmPmDesignator<TResult>(str);
      });
      builder.addFormatAction((TResult value, StringBuffer sb) => sb.write(hourOfDayGetter(value) > 11 ? pmDesignator : amDesignator));
    };
  }

  static void _handleHalfAmPmDesignator<TResult, TBucket extends ParseBucket<TResult>>
      (int count, String specifiedDesignator, int specifiedDesignatorValue, int Function(TResult) hourOfDayGetter, Function(TBucket, int) amPmSetter,
      SteppedPatternBuilder<TResult, TBucket> builder) {
    CompareInfo? compareInfo = builder.formatInfo.compareInfo;
    if (count == 1) {
      String abbreviation = specifiedDesignator.substring(0, 1);

      builder.addParseAction((ValueCursor str, TBucket bucket) {
        int value = str.matchCaseInsensitive(abbreviation, compareInfo, true) ? specifiedDesignatorValue : 1 - specifiedDesignatorValue;
        amPmSetter(bucket, value);
        return null;
      });

      builder.addFormatAction((TResult value, StringBuffer sb) {
        // Only append anything if it's the non-empty designator.
        if (hourOfDayGetter(value) ~/ 12 == specifiedDesignatorValue) {
          sb.write(specifiedDesignator[0]);
        }
      });
      return;
    }

    builder.addParseAction((ValueCursor str, TBucket bucket) {
      int value = str.matchCaseInsensitive(specifiedDesignator, compareInfo, true) ? specifiedDesignatorValue : 1 - specifiedDesignatorValue;
      amPmSetter(bucket, value);
      return null;
    });
    builder.addFormatAction((TResult value, StringBuffer sb) {
      // Only append anything if it's the non-empty designator.
      if (hourOfDayGetter(value) ~/ 12 == specifiedDesignatorValue) {
        sb.write(specifiedDesignator);
      }
    });
  }
}
