import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';
import 'package:time_machine/src/text/globalization/nodaformatinfo.dart';


// Hacky way of building an action which depends on the final set of pattern fields to determine whether to format a month
// using the genitive form or not.
@private /*sealed*/ class MonthFormatActionHolder<TResult, TBucket extends ParseBucket<TResult>> extends /*SteppedPatternBuilder<TResult, TBucket>.*/IPostPatternParseFormatAction
// where TBucket : ParseBucket<TResult>
    {
  @private final int count;
  @private final NodaFormatInfo formatInfo;
  @private final int Function(TResult) getter;

  @internal MonthFormatActionHolder(this.formatInfo, this.count, this.getter);

  @internal void DummyMethod(TResult value, StringBuffer builder) {
// This method is never called. We use it to create a delegate with a target that implements
// IPostPatternParseFormatAction. There's no test for this throwing.
    throw new StateError("This method should never be called");
  }

  @override
  Function(TResult, StringBuffer) BuildFormatAction(PatternFields finalFields) {
    bool genitive = (finalFields.value & PatternFields.dayOfMonth.value) != 0;
    List<String> textValues = count == 3
        ? (genitive ? formatInfo.ShortMonthGenitiveNames : formatInfo.ShortMonthNames)
        : (genitive ? formatInfo.LongMonthGenitiveNames : formatInfo.LongMonthNames);
    return (value, sb) => sb.write(textValues[getter(value)]);
  }
}

/// <summary>
/// Common methods used when parsing dates - these are used from both LocalDateTimePatternParser
/// and LocalDatePatternParser.
/// </summary>
@internal abstract class DatePatternHelper {
  /// <summary>
  /// Creates a character handler for the year-of-era specifier (y).
  /// </summary>
  @internal static CharacterHandler<TResult, TBucket> CreateYearOfEraHandler<TResult, TBucket extends ParseBucket<TResult>>
      (int Function(TResult) yearGetter, Function(TBucket, int) setter) {
    _patternBuilder(PatternCursor pattern, SteppedPatternBuilder builder) {
      int count = pattern.GetRepeatCount(4);
      builder.AddField(PatternFields.yearOfEra, pattern.Current);
      switch (count) {
        case 2:
          builder.AddParseValueAction(2, 2, 'y', 0, 99, setter);
          // Force the year into the range 0-99.
          builder.AddFormatLeftPad(2, (value) => ((yearGetter(value) % 100) + 100) % 100,
              assumeNonNegative: true,
              assumeFitsInCount: true);
          // Just remember that we've set this particular field. We can't set it twice as we've already got the YearOfEra flag set.
          builder.AddField(PatternFields.yearTwoDigits, pattern.Current);
          break;
        case 4:
        // Left-pad to 4 digits when formatting; parse exactly 4 digits.
          builder.AddParseValueAction(4, 4, 'y', 1, 9999, setter);
          builder.AddFormatLeftPad(4, yearGetter,
              assumeNonNegative: false,
              assumeFitsInCount: true);
          break;
        default:
          throw new InvalidPatternError.format(TextErrorMessages.InvalidRepeatCount, [pattern.Current, count]);
      }
    }

    return _patternBuilder; // (pattern, builder) => _createYearofEraHandler(pattern, builder);
  }

  /// <summary>
  /// Creates a character handler for the month-of-year specifier (M).
  /// </summary>
  @internal static CharacterHandler<TResult, TBucket> CreateMonthOfYearHandler<TResult, TBucket extends ParseBucket<TResult>>
      (int Function(TResult) numberGetter, Function(TBucket, int) textSetter, Function(TBucket, int) numberSetter) {
    patternBuilder(pattern, builder) {
      int count = pattern.GetRepeatCount(4);
      PatternFields field;
      switch (count) {
        case 1:
        case 2:
          field = PatternFields.monthOfYearNumeric;
          // Handle real maximum value in the bucket
          builder.AddParseValueAction(count, 2, pattern.Current, 1, 99, numberSetter);
          builder.AddFormatLeftPad(count, numberGetter, assumeNonNegative: true, assumeFitsInCount: count == 2);
          break;
        case 3:
        case 4:
          field = PatternFields.monthOfYearText;
          var format = builder.FormatInfo;
          List<String> nonGenitiveTextValues = count == 3 ? format.ShortMonthNames : format.LongMonthNames;
          List<String> genitiveTextValues = count == 3 ? format.ShortMonthGenitiveNames : format.LongMonthGenitiveNames;
          if (nonGenitiveTextValues == genitiveTextValues) {
            builder.AddParseLongestTextAction(pattern.Current, textSetter, format.CompareInfo, nonGenitiveTextValues);
          }
          else {
            builder.AddParseLongestTextAction(pattern.Current, textSetter, format.CompareInfo,
                genitiveTextValues, nonGenitiveTextValues);
          }

          // Hack: see below
          // Dart Hack: we don't even need to pass a DummyMethod, we don't have a Delegate.Action in Dart
          //  So instead of, 'formatAction.Target as IPostPatternParseFormatAction' we can do
          //   'formatAction as IPostPatternParseFormatAction' ... Will this still work in Dart 2.0?
          builder.AddFormatAction(new MonthFormatActionHolder<TResult, TBucket>(format, count, numberGetter)); //.DummyMethod);
          break;
        default:
          throw new StateError("Invalid count!");
      }
      builder.AddField(field, pattern.Current);
    }

    return patternBuilder;
  }


  /// <summary>
  /// Creates a character handler for the day specifier (d).
  /// </summary>
  @internal static CharacterHandler<TResult, TBucket> CreateDayHandler<TResult, TBucket extends ParseBucket<TResult>>
      (int Function(TResult) dayOfMonthGetter, int Function(TResult) dayOfWeekGetter,
      Function(TBucket, int) dayOfMonthSetter, Function(TBucket, int) dayOfWeekSetter) {
    patternBuilder(pattern, builder) {
      int count = pattern.GetRepeatCount(4);
      PatternFields field;
      switch (count) {
        case 1:
        case 2:
          field = PatternFields.dayOfMonth;
          // Handle real maximum value in the bucket
          builder.AddParseValueAction(count, 2, pattern.Current, 1, 99, dayOfMonthSetter);
          builder.AddFormatLeftPad(count, dayOfMonthGetter, assumeNonNegative: true, assumeFitsInCount: count == 2);
          break;
        case 3:
        case 4:
          field = PatternFields.dayOfWeek;
          var format = builder.FormatInfo;
          List<String> textValues = count == 3 ? format.ShortDayNames : format.LongDayNames;
          builder.AddParseLongestTextAction(pattern.Current, dayOfWeekSetter, format.CompareInfo, textValues);
          builder.AddFormatAction((value, sb) => sb.Append(textValues[dayOfWeekGetter(value)]));
          break;
        default:
          throw new StateError("Invalid count!");
      }
      builder.AddField(field, pattern.Current);
    }

    return patternBuilder;
  }

  /// <summary>
  /// Creates a character handler for the era specifier (g).
  /// </summary>
  @internal static CharacterHandler<TResult, TBucket> CreateEraHandler<TResult, TBucket extends ParseBucket<TResult>>
      (Era Function(TResult) eraFromValue, /*LocalDatePatternParser.*/LocalDateParseBucket Function(TBucket) dateBucketFromBucket) {
    _patternBuilder(pattern, builder) {
      pattern.GetRepeatCount(2);
      builder.AddField(PatternFields.era, pattern.Current);
      var formatInfo = builder.FormatInfo;

      _parseAction(cursor, bucket) {
        var dateBucket = dateBucketFromBucket(bucket);
        return dateBucket.ParseEra<TResult>(formatInfo, cursor);
      }

      // Note: currently the count is ignored. More work needed to determine whether abbreviated era names should be used for just "g".
      builder.AddParseAction(_parseAction);

      builder.AddFormatAction((value, sb) => sb.Append(formatInfo.GetEraPrimaryName(eraFromValue(value))));
    }

    return _patternBuilder;
  }

  /// <summary>
  /// Creates a character handler for the calendar specifier (c).
  /// </summary>
  @internal static CharacterHandler<TResult, TBucket> CreateCalendarHandler<TResult, TBucket extends ParseBucket<TResult>>
      (CalendarSystem Function(TResult) getter, Function(TBucket, CalendarSystem) setter) {
    _function(pattern, builder) {
      builder.AddField(PatternFields.calendar, pattern.Current);

      _parseAction(cursor, bucket) {
        for (var id in CalendarSystem.Ids) {
          if (cursor.Match(id)) {
            setter(bucket, CalendarSystem.ForId(id));
            return null;
          }
        }
        return ParseResult.NoMatchingCalendarSystem<TResult>(cursor);
      }

      builder.AddParseAction(_parseAction);
      builder.AddFormatAction((value, sb) => sb.Append(getter(value).id));
    }
    return _function;
  }
}
