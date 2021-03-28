// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/text/patterns/time_machine_patterns.dart';
import 'package:time_machine/src/text/globalization/time_machine_format_info.dart';

// Hacky way of building an action which depends on the final set of pattern fields to determine whether to format a month
// using the genitive form or not.
class _MonthFormatActionHolder<TResult, TBucket extends ParseBucket<TResult>> extends IPostPatternParseFormatAction<TResult> {
  final int _count;
  final TimeMachineFormatInfo _formatInfo;
  final int Function(TResult) _getter;

  _MonthFormatActionHolder(this._formatInfo, this._count, this._getter);

  @override
  Function(TResult, StringBuffer) buildFormatAction(PatternFields finalFields) {
    bool genitive = (finalFields.value & PatternFields.dayOfMonth.value) != 0;
    List<String> textValues = _count == 3
        ? (genitive ? _formatInfo.shortMonthGenitiveNames : _formatInfo.shortMonthNames)
        : (genitive ? _formatInfo.longMonthGenitiveNames : _formatInfo.longMonthNames);
    return (value, sb) => sb.write(textValues[_getter(value)]);
  }
}

/// Common methods used when parsing dates - these are used from both LocalDateTimePatternParser
/// and LocalDatePatternParser.
@internal
abstract class DatePatternHelper {
  /// Creates a character handler for the year-of-era specifier (y).
  static CharacterHandler<TResult, TBucket> createYearOfEraHandler<TResult, TBucket extends ParseBucket<TResult>>
      (int Function(TResult) yearGetter, Function(TBucket, int) setter) {
    return (PatternCursor pattern, SteppedPatternBuilder<TResult, TBucket> builder) {
      int count = pattern.getRepeatCount(4);
      builder.addField(PatternFields.yearOfEra, pattern.current);
      switch (count) {
        case 2:
          builder.addParseValueAction(2, 2, 'y', 0, 99, setter);
          // Force the year into the range 0-99.
          builder.addFormatLeftPad(2, (value) => ((yearGetter(value) % 100) + 100) % 100,
              assumeNonNegative: true,
              assumeFitsInCount: true);
          // Just remember that we've set this particular field. We can't set it twice as we've already got the YearOfEra flag set.
          builder.addField(PatternFields.yearTwoDigits, pattern.current);
          break;
        case 4:
          // Left-pad to 4 digits when formatting; parse exactly 4 digits.
          builder.addParseValueAction(4, 4, 'y', 1, 9999, setter);
          builder.addFormatLeftPad(4, yearGetter,
              assumeNonNegative: false,
              assumeFitsInCount: true);
          break;
        default:
          throw IInvalidPatternError.format(TextErrorMessages.invalidRepeatCount, [pattern.current, count]);
      }
    };

  // (pattern, builder) => _createYearofEraHandler(pattern, builder);
  }

  /// Creates a character handler for the month-of-year specifier (M).
  static CharacterHandler<TResult, TBucket> createMonthOfYearHandler<TResult, TBucket extends ParseBucket<TResult>>
      (int Function(TResult) numberGetter, Function(TBucket, int) textSetter, Function(TBucket, int) numberSetter) {
    return (PatternCursor pattern, SteppedPatternBuilder<TResult, TBucket> builder) {
      int count = pattern.getRepeatCount(4);
      PatternFields field;
      switch (count) {
        case 1:
        case 2:
          field = PatternFields.monthOfYearNumeric;
          // Handle real maximum value in the bucket
          builder.addParseValueAction(count, 2, pattern.current, 1, 99, numberSetter);
          builder.addFormatLeftPad(count, numberGetter, assumeNonNegative: true, assumeFitsInCount: count == 2);
          break;
        case 3:
        case 4:
          field = PatternFields.monthOfYearText;
          var format = builder.formatInfo;
          List<String> nonGenitiveTextValues = count == 3 ? format.shortMonthNames : format.longMonthNames;
          List<String> genitiveTextValues = count == 3 ? format.shortMonthGenitiveNames : format.longMonthGenitiveNames;
          if (nonGenitiveTextValues == genitiveTextValues) {
            builder.addParseLongestTextAction(pattern.current, textSetter, format.compareInfo, nonGenitiveTextValues);
          }
          else {
            builder.addParseLongestTextAction(pattern.current, textSetter, format.compareInfo,
                genitiveTextValues, nonGenitiveTextValues);
          }

          // Hack: see below
          // Dart Hack: we don't have a Delegate.Action in Dart
          //  So instead of, 'formatAction.Target as IPostPatternParseFormatAction' we perform type erasure
          builder.addPostPatternParseFormatAction(_MonthFormatActionHolder<TResult, TBucket>(format, count, numberGetter));
          break;
        default:
          throw StateError('Invalid count!');
      }
      builder.addField(field, pattern.current);
    };
  }


  /// Creates a character handler for the day specifier (d).
  static CharacterHandler<TResult, TBucket> createDayHandler<TResult, TBucket extends ParseBucket<TResult>>
      (int Function(TResult) dayOfMonthGetter, int Function(TResult) dayOfWeekGetter,
      Function(TBucket, int) dayOfMonthSetter, Function(TBucket, int) dayOfWeekSetter) {
    return(pattern, builder) {
      int count = pattern.getRepeatCount(4);
      PatternFields field;
      switch (count) {
        case 1:
        case 2:
          field = PatternFields.dayOfMonth;
          // Handle real maximum value in the bucket
          builder.addParseValueAction(count, 2, pattern.current, 1, 99, dayOfMonthSetter);
          builder.addFormatLeftPad(count, dayOfMonthGetter, assumeNonNegative: true, assumeFitsInCount: count == 2);
          break;
        case 3:
        case 4:
          field = PatternFields.dayOfWeek;
          var format = builder.formatInfo;
          List<String?> textValues = count == 3 ? format.shortDayNames : format.longDayNames;
          builder.addParseLongestTextAction(pattern.current, dayOfWeekSetter, format.compareInfo, textValues);
          builder.addFormatAction((value, sb) => sb.write(textValues[dayOfWeekGetter(value)]));
          break;
        default:
          throw StateError('Invalid count!');
      }
      builder.addField(field, pattern.current);
    };
  }

  /// Creates a character handler for the era specifier (g).
  static CharacterHandler<TResult, TBucket> createEraHandler<TResult, TBucket extends ParseBucket<TResult>>
      (Era Function(TResult) eraFromValue, /*LocalDatePatternParser.*/LocalDateParseBucket Function(TBucket) dateBucketFromBucket) {
    return (pattern, builder) {
      pattern.getRepeatCount(2);
      builder.addField(PatternFields.era, pattern.current);
      var formatInfo = builder.formatInfo;

      ParseResult<TResult>? _parseAction(cursor, bucket) {
        var dateBucket = dateBucketFromBucket(bucket);
        return dateBucket.parseEra<TResult>(formatInfo, cursor);
      }

      // Note: currently the count is ignored. More work needed to determine whether abbreviated era names should be used for just 'g'.
      builder.addParseAction(_parseAction);

      builder.addFormatAction((value, sb) => sb.write(formatInfo.getEraPrimaryName(eraFromValue(value))));
    };
  }

  /// Creates a character handler for the calendar specifier (c).
  static CharacterHandler<TResult, TBucket> createCalendarHandler<TResult, TBucket extends ParseBucket<TResult>>
      (CalendarSystem Function(TResult) getter, Function(TBucket, CalendarSystem) setter) {
    return (pattern, builder) {
      builder.addField(PatternFields.calendar, pattern.current);

      builder.addParseAction((cursor, bucket) {
        for (var id in CalendarSystem.ids) {
          if (cursor.matchText(id)) {
            setter(bucket, CalendarSystem.forId(id));
            return null;
          }
        }
        return IParseResult.noMatchingCalendarSystem<TResult>(cursor);
      });
      builder.addFormatAction((value, sb) => sb.write(getter(value).id));
    };
  }
}

