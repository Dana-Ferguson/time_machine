// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';


// todo: ******************** REMOVE ALL REF'S \\ OUT'S

// was originally a class inside SteppedPatternBuilder
// internal delegate ParseResult<TResult> ParseAction(ValueCursor cursor, TBucket bucket);
// @internal typedef ParseAction = ParseResult<TResult> Function<TResult, TBucket extends ParseBucket<TResult>>(ValueCursor cursor, TBucket bucket);
@internal typedef ParseResult<TResult> ParseAction<TResult, TBucket extends ParseBucket<TResult>>(ValueCursor cursor, TBucket bucket);

class _findLongestMatchCursor {
  int bestIndex = -1;
  int longestMatch = 0;
}

/// Builder for a pattern which implements parsing and formatting as a sequence of steps applied
/// in turn.
// where TBucket : ParseBucket<TResult>
@internal /*sealed*/ class SteppedPatternBuilder<TResult, TBucket extends ParseBucket<TResult>> {
  static const int _aCodeUnit = 97;
  static const int _zCodeUnit = 122;
  static const int _ACodeUnit = 65;
  static const int _ZCodeUnit = 90;

  // #Hack: this accommodates IPostPatternParseFormatAction
  final List<Object> _formatActions = new List<Object>();
  // final List<Function(TResult, StringBuffer)> _formatActions = new List<Function(TResult, StringBuffer)>();
  final List<ParseAction<TResult, TBucket>> _parseActions = new List<ParseAction<TResult, TBucket>>();
  final TBucket Function() _bucketProvider;
  PatternFields _usedFields = PatternFields.none;
  bool _formatOnly = false;

  @internal final TimeMachineFormatInfo FormatInfo;

  @internal PatternFields get UsedFields => _usedFields;

  @internal SteppedPatternBuilder(this.FormatInfo, this._bucketProvider);
// : _formatActions ,
// _parseActions = new List<ParseAction<TResult, TBucket>>();

  /// Calls the bucket provider and returns a sample bucket. This means that any values
  /// normally propagated via the bucket can also be used when building the pattern.
  @internal TBucket CreateSampleBucket() {
    return _bucketProvider();
  }

  /// Sets this pattern to only be capable of formatting; any attempt to parse using the
  /// built pattern will fail immediately.
  @internal void SetFormatOnly() {
    _formatOnly = true;
  }

  /// Performs common parsing operations: start with a parse action to move the
  /// value cursor onto the first character, then call a character handler for each
  /// character in the pattern to build up the steps. If any handler fails,
  /// that failure is returned - otherwise the return value is null.
  @internal void ParseCustomPattern(String patternText, Map<String, CharacterHandler<TResult, TBucket>> characterHandlers) {
    var patternCursor = new PatternCursor(patternText);

    // Now iterate over the pattern.
    while (patternCursor.MoveNext()) {
      CharacterHandler<TResult, TBucket> handler = characterHandlers[patternCursor.Current];
      if (handler != null) {
        handler(patternCursor, this);
      }
      else {
        String current = patternCursor.Current;
        var currentCodeUnit = current.codeUnitAt(0);
        if ((currentCodeUnit >= _ACodeUnit && currentCodeUnit <= _ZCodeUnit)
            || (currentCodeUnit >= _aCodeUnit && currentCodeUnit <= _zCodeUnit)
            || current == PatternCursor.EmbeddedPatternStart || current == PatternCursor.EmbeddedPatternEnd) {
          throw new InvalidPatternError.format(TextErrorMessages.UnquotedLiteral, [current]);
        }
        AddLiteral2(patternCursor.Current, ParseResult.MismatchedCharacter);
      }
    }
  }

  /// Validates the combination of fields used.
  @internal void ValidateUsedFields() {
// We assume invalid combinations are global across all parsers. The way that
// the patterns are parsed ensures we never end up with any invalid individual fields
// (e.g. time fields within a date pattern).

    if ((_usedFields & (PatternFields.era | PatternFields.yearOfEra)) == PatternFields.era) {
      throw new InvalidPatternError(TextErrorMessages.EraWithoutYearOfEra);
    }
    /*const*/ PatternFields calendarAndEra = PatternFields.era | PatternFields.calendar;
    if ((_usedFields & calendarAndEra) == calendarAndEra) {
      throw new InvalidPatternError(TextErrorMessages.CalendarAndEra);
    }
  }

  /// Returns a built pattern. This is mostly to keep the API for the builder separate from that of the pattern,
  /// and for thread safety (publishing a new object, thus leading to a memory barrier).
  /// Note that this builder *must not* be used after the result has been built.
  @internal IPartialPattern<TResult> Build(TResult sample) {
    // If we've got an embedded date and any *other* date fields, throw.
    if (_usedFields.HasAny(PatternFields.embeddedDate) &&
        _usedFields.HasAny(PatternFields.allDateFields & ~PatternFields.embeddedDate)) {
      throw new InvalidPatternError(TextErrorMessages.DateFieldAndEmbeddedDate);
    }
    // Ditto for time
    if (_usedFields.HasAny(PatternFields.embeddedTime) &&
        _usedFields.HasAny(PatternFields.allTimeFields & ~PatternFields.embeddedTime)) {
      throw new InvalidPatternError(TextErrorMessages.TimeFieldAndEmbeddedTime);
    }

    List<Function/*(TResult, StringBuffer)*/> formatDelegate = [];
    for (/*Function(TResult, StringBuffer)*/ dynamic formatAction in _formatActions) {
      if (formatAction is IPostPatternParseFormatAction) {
        formatDelegate.add(formatAction.BuildFormatAction(_usedFields));
      } else {
        formatDelegate.add(formatAction);
      }

    // IPostPatternParseFormatAction postAction = formatAction.Target as IPostPatternParseFormatAction;
    // formatDelegate.add(postAction == null ? formatAction : postAction.BuildFormatAction(usedFields));
    }
    return new _SteppedPattern(formatDelegate, _formatOnly ? null : _parseActions, _bucketProvider, _usedFields, sample);
  }

  /// Registers that a pattern field has been used in this pattern, and throws a suitable error
  /// result if it's already been used.
  @internal void AddField(PatternFields field, String characterInPattern) {
    PatternFields newUsedFields = _usedFields | field;
    if (newUsedFields == _usedFields) {
      throw new InvalidPatternError.format(TextErrorMessages.RepeatedFieldInPattern, [characterInPattern]);
    }
    _usedFields = newUsedFields;
  }

  @internal void AddParseAction(ParseAction<TResult, TBucket> parseAction) => _parseActions.add(parseAction);

  @internal void AddFormatAction(Function(TResult, StringBuffer) formatAction) => _formatActions.add(formatAction);

  @internal void AddPostPatternParseFormatAction(IPostPatternParseFormatAction formatAction) => _formatActions.add(formatAction);

  /// Equivalent of [AddParseValueAction] but for 64-bit integers. Currently only
  /// positive values are supported.
  @internal void AddParseInt64ValueAction(int minimumDigits, int maximumDigits, String patternChar,
      int minimumValue, int maximumValue, Function(TBucket, int) valueSetter) {
    Preconditions.debugCheckArgumentRange('minimumValue', minimumValue, 0, Utility.int64MaxValue);

    AddParseAction((ValueCursor cursor, TBucket bucket) {
      int startingIndex = cursor.Index;
      int value = cursor.ParseInt64Digits(minimumDigits, maximumDigits);
      if (value == null) {
        cursor.Move(startingIndex);
        return ParseResult.MismatchedNumber<TResult>(cursor, stringFilled(patternChar, minimumDigits));
      }
      if (value < minimumValue || value > maximumValue) {
        cursor.Move(startingIndex);
        return ParseResult.FieldValueOutOfRange<TResult>(cursor, value, patternChar, TResult.toString());
      }

      valueSetter(bucket, value);
      return null;
    });
  }

  @internal void AddParseValueAction(int minimumDigits, int maximumDigits, String patternChar,
      int minimumValue, int maximumValue, Function(TBucket, int) valueSetter) {

    AddParseAction((ValueCursor cursor, TBucket bucket) {
      int startingIndex = cursor.Index;
      int value;
      bool negative = cursor.MatchSingle('-');
      if (negative && minimumValue >= 0) {
        cursor.Move(startingIndex);
        return ParseResult.UnexpectedNegative<TResult>(cursor);
      }

      value = cursor.ParseDigits(minimumDigits, maximumDigits);
      if (value == null) {
        cursor.Move(startingIndex);
        return ParseResult.MismatchedNumber<TResult>(cursor, stringFilled(patternChar, minimumDigits));
      }
      if (negative) {
        value = -value;
      }
      if (value < minimumValue || value > maximumValue) {
        cursor.Move(startingIndex);
        return ParseResult.FieldValueOutOfRange<TResult>(cursor, value, patternChar, TResult.toString());
      }

      valueSetter(bucket, value);
      return null;
    });
  }

// ParseResult<TResult> ParseAction<TResult, TBucket extends ParseBucket<TResult>>(ValueCursor cursor, TBucket bucket);
// internal void AddParseAction(ParseAction parseAction) => parseActions.Add(parseAction);


  /// Adds text which must be matched exactly when parsing, and appended directly when formatting.
  @internal void AddLiteral1(String expectedText, ParseResult<TResult> Function(ValueCursor) failure) {
    // Common case - single character literal, often a date or time separator.
    if (expectedText.length == 1) {
      String expectedChar = expectedText[0];
      AddParseAction((ValueCursor str, TBucket bucket) => str.MatchSingle(expectedChar) ? null : failure(str));
      AddFormatAction((TResult value, StringBuffer builder) => builder.write(expectedChar));
      return;
    }
    AddParseAction((ValueCursor str, TBucket bucket) => str.MatchText(expectedText) ? null : failure(str));
    AddFormatAction((TResult value, StringBuffer builder) => builder.write(expectedText));
  }

  @internal static void HandleQuote<TResult, TBucket extends ParseBucket<TResult>>(PatternCursor pattern, SteppedPatternBuilder<TResult, TBucket> builder) {
    String quoted = pattern.GetQuotedString(pattern.Current);
    builder.AddLiteral1(quoted, ParseResult.QuotedStringMismatch);
  }

  @internal static void HandleBackslash<TResult, TBucket extends ParseBucket<TResult>>(PatternCursor pattern, SteppedPatternBuilder<TResult, TBucket> builder) {
    if (!pattern.MoveNext()) {
      throw new InvalidPatternError(TextErrorMessages.EscapeAtEndOfString);
    }
    builder.AddLiteral2(pattern.Current, ParseResult.EscapedCharacterMismatch);
  }

  /// Handle a leading "%" which acts as a pseudo-escape - it's mostly used to allow format strings such as "%H" to mean
  /// "use a custom format string consisting of H instead of a standard pattern H".
  @internal static void HandlePercent<TResult, TBucket extends ParseBucket<TResult>>(PatternCursor pattern, SteppedPatternBuilder<TResult, TBucket> builder) {
    if (pattern.HasMoreCharacters) {
      if (pattern.PeekNext() != '%') {
        // Handle the next character as normal
        return;
      }
      throw new InvalidPatternError(TextErrorMessages.PercentDoubled);
    }
    throw new InvalidPatternError(TextErrorMessages.PercentAtEndOfString);
  }

  /// Returns a handler for a zero-padded purely-numeric field specifier, such as "seconds", "minutes", "24-hour", "12-hour" etc.
  ///
  /// [maxCount]: Maximum permissable count (usually two)
  /// [field]: Field to remember that we've seen
  /// [minValue]: Minimum valid value for the field (inclusive)
  /// [maxValue]: Maximum value value for the field (inclusive)
  /// [getter]: Delegate to retrieve the field value when formatting
  /// [setter]: Delegate to set the field value into a bucket when parsing
  /// Returns: The pattern parsing failure, or null on success.
  @internal static CharacterHandler<TResult, TBucket> HandlePaddedField<TResult, TBucket extends ParseBucket<TResult>>(int maxCount, PatternFields field, int minValue, int maxValue,
      int Function(TResult) getter, int Function(TBucket, int) setter) {
    return (PatternCursor pattern,  SteppedPatternBuilder<TResult, TBucket> builder) {
      int count = pattern.GetRepeatCount(maxCount);
      builder.AddField(field, pattern.Current);
      builder.AddParseValueAction(count, maxCount, pattern.Current, minValue, maxValue, setter);
      builder.AddFormatLeftPad(count, getter, assumeNonNegative: minValue >= 0, assumeFitsInCount: count == maxCount);
    };
  }

  /// Adds a character which must be matched exactly when parsing, and appended directly when formatting.
  @internal void AddLiteral2(String expectedChar, ParseResult<TResult> Function(ValueCursor, String) failureSelector) {
    AddParseAction((ValueCursor str, TBucket bucket) => str.MatchSingle(expectedChar) ? null : failureSelector(str, expectedChar));
    AddFormatAction((TResult value, StringBuffer builder) => builder.write(expectedChar));
  }

  /// Adds parse actions for a list of strings, such as days of the week or month names.
  /// The parsing is performed case-insensitively. All candidates are tested, and only the longest
  /// match is used.
  ///
  /// Adds parse actions for two list of strings, such as non-genitive and genitive month names.
  /// The parsing is performed case-insensitively. All candidates are tested, and only the longest
  /// match is used.
  @internal void AddParseLongestTextAction(String field, Function(TBucket, int) setter, CompareInfo compareInfo, Iterable<String> textValues1,
      [Iterable<String> textValues2 = null]) {
    AddParseAction((ValueCursor str, TBucket bucket) {
      var matchCursor = new _findLongestMatchCursor();

      FindLongestMatch(compareInfo, str, textValues1, matchCursor);
      if (textValues2 != null) FindLongestMatch(compareInfo, str, textValues2, matchCursor);
      if (matchCursor.bestIndex != -1) {
        setter(bucket, matchCursor.bestIndex);
        str.Move(str.Index + matchCursor.longestMatch);
        return null;
      }
      return ParseResult.MismatchedText<TResult>(str, field);
    });
  }
/*
          private static void FindLongestMatch(CompareInfo compareInfo, ValueCursor cursor, IList<string> values, ref int bestIndex, ref int longestMatch)
        {
            for (int i = 0; i < values.Count; i++)
            {
                string candidate = values[i];
                if (candidate == null || candidate.Length <= longestMatch)
                {
                    continue;
                }
                if (cursor.MatchCaseInsensitive(candidate, compareInfo, false))
                {
                    bestIndex = i;
                    longestMatch = candidate.Length;
                }
            }
        }
  */

  /// Find the longest match from a given set of candidate strings, updating the index/length of the best value
  /// accordingly.
  ///  // todo: _findLongestMatchCursor should be a return value
  @private static void FindLongestMatch(CompareInfo compareInfo, ValueCursor cursor, List<String> values, _findLongestMatchCursor matchCursor) {
    for (int i = 0; i < values.length; i++) {
      String candidate = values[i];
      if (candidate == null || candidate.length <= matchCursor.longestMatch) {
        continue;
      }
      if (cursor.MatchCaseInsensitive(candidate, compareInfo, false)) {
        matchCursor.bestIndex = i;
        matchCursor.longestMatch = candidate.length;
      }
    }
  }

  /// Adds parse and format actions for a mandatory positive/negative sign.
  ///
  /// [signSetter]: Action to take when to set the given sign within the bucket
  /// [nonNegativePredicate]: Predicate to detect whether the value being formatted is non-negative
  void AddRequiredSign(Function(TBucket, bool) signSetter, bool Function(TResult) nonNegativePredicate) {
    AddParseAction((ValueCursor str, TBucket bucket) {
      if (str.MatchSingle("-")) {
        signSetter(bucket, false);
        return null;
      }
      if (str.MatchSingle("+")) {
        signSetter(bucket, true);
        return null;
      }
      return ParseResult.MissingSign<TResult>(str);
    }
    );
    AddFormatAction((TResult value, StringBuffer sb) => sb.write(nonNegativePredicate(value) ? "+" : "-"));
  }

  /// Adds parse and format actions for an "negative only" sign.
  ///
  /// [signSetter]: Action to take when to set the given sign within the bucket
  /// [nonNegativePredicate]: Predicate to detect whether the value being formatted is non-negative
  void AddNegativeOnlySign(Function(TBucket, bool) signSetter, bool Function(TResult) nonNegativePredicate) {
    AddParseAction((ValueCursor str, TBucket bucket) {
      if (str.MatchSingle("-")) {
        signSetter(bucket, false);
        return null;
      }
      if (str.MatchSingle("+")) {
        return ParseResult.PositiveSignInvalid<TResult>(str);
      }
      signSetter(bucket, true);
      return null;
    });
    AddFormatAction((TResult value, StringBuffer builder) {
      if (!nonNegativePredicate(value)) {
        builder.write("-");
      }
    });
  }

  /// Adds an action to pad a selected value to a given minimum lenth.
  ///
  /// [count]: The minimum length to pad to
  /// [selector]: The selector function to apply to obtain a value to format
  /// [assumeNonNegative]: Whether it is safe to assume the value will be non-negative
  /// [assumeFitsInCount]: Whether it is safe to assume the value will not exceed the specified length
  @internal void AddFormatLeftPad(int count, int Function(TResult) selector, {bool assumeNonNegative, bool assumeFitsInCount}) {
    if (count == 2 && assumeNonNegative && assumeFitsInCount) {
      AddFormatAction((TResult value, StringBuffer sb) => FormatHelper.Format2DigitsNonNegative(selector(value), sb));
    }
    else if (count == 4 && assumeFitsInCount) {
      AddFormatAction((TResult value, StringBuffer sb) => FormatHelper.Format4DigitsValueFits(selector(value), sb));
    }
    else if (assumeNonNegative) {
      AddFormatAction((TResult value, StringBuffer sb) => FormatHelper.LeftPadNonNegative(selector(value), count, sb));
    }
    else {
      AddFormatAction((TResult value, StringBuffer sb) => FormatHelper.LeftPad(selector(value), count, sb));
    }
  }

  @internal void AddFormatFraction(int width, int scale, int Function(TResult) selector) =>
      AddFormatAction((TResult value, StringBuffer sb) => FormatHelper.AppendFraction(selector(value), width, scale, sb));

  @internal void AddFormatFractionTruncate(int width, int scale, int Function(TResult) selector) =>
      AddFormatAction((TResult value, StringBuffer sb) => FormatHelper.AppendFractionTruncate(selector(value), width, scale, sb));

  /// Handles date, time and date/time embedded patterns.
  @internal void AddEmbeddedLocalPartial(PatternCursor pattern,
      /*LocalDatePatternParser.*/LocalDateParseBucket Function(TBucket) dateBucketExtractor,
      /*LocalTimePatternParser.*/LocalTimeParseBucket Function(TBucket) timeBucketExtractor,
      LocalDate Function(TResult) dateExtractor,
      LocalTime Function(TResult) timeExtractor,
      // null if date/time embedded patterns are invalid
      LocalDateTime Function(TResult) dateTimeExtractor) {

    // This will be d (date-only), t (time-only), or < (date and time)
    // If it's anything else, we'll see the problem when we try to get the pattern.
    var patternType = pattern.PeekNext();
    if (patternType == 'd' || patternType == 't') {
      pattern.MoveNext();
    }
    String embeddedPatternText = pattern.GetEmbeddedPattern();
    switch (patternType) {
      case '<':
        {
          var sampleBucket = CreateSampleBucket();
          var templateTime = timeBucketExtractor(sampleBucket).TemplateValue;
          var templateDate = dateBucketExtractor(sampleBucket).TemplateValue;
          if (dateTimeExtractor == null) {
            throw new InvalidPatternError(TextErrorMessages.InvalidEmbeddedPatternType);
          }
          AddField(PatternFields.embeddedDate, 'l');
          AddField(PatternFields.embeddedTime, 'l');
          AddEmbeddedPattern(
              LocalDateTimePattern
                  .Create(embeddedPatternText, FormatInfo, templateDate.at(templateTime))
                  .UnderlyingPattern,
                  (TBucket bucket, LocalDateTime value) {
                var dateBucket = dateBucketExtractor(bucket);
                var timeBucket = timeBucketExtractor(bucket);
                dateBucket.Calendar = value.calendar;
                dateBucket.Year = value.year;
                dateBucket.MonthOfYearNumeric = value.month;
                dateBucket.DayOfMonth = value.day;
                timeBucket.Hours24 = value.hour;
                timeBucket.Minutes = value.minute;
                timeBucket.Seconds = value.second;
                timeBucket.FractionalSeconds = value.nanosecondOfSecond;
              },
              dateTimeExtractor);
          break;
        }
      case 'd':
        AddEmbeddedDatePattern('l', embeddedPatternText, dateBucketExtractor, dateExtractor);
        break;
      case 't':
        AddEmbeddedTimePattern('l', embeddedPatternText, timeBucketExtractor, timeExtractor);
        break;
      default:
        throw new StateError("Bug in Noda Time: embedded pattern type wasn't date, time, or date+time");
    }
  }

  @internal void AddEmbeddedDatePattern(String characterInPattern,
      String embeddedPatternText,
      /*LocalDatePatternParser.*/LocalDateParseBucket Function(TBucket) dateBucketExtractor,
      LocalDate Function(TResult) dateExtractor) {
    var templateDate = dateBucketExtractor(CreateSampleBucket()).TemplateValue;
    AddField(PatternFields.embeddedDate, characterInPattern);
    AddEmbeddedPattern(
        LocalDatePattern
            .Create(embeddedPatternText, FormatInfo, templateDate)
            .UnderlyingPattern,
            (TBucket bucket, LocalDate value) {
          var dateBucket = dateBucketExtractor(bucket);
          dateBucket.Calendar = value.calendar;
          dateBucket.Year = value.year;
          dateBucket.MonthOfYearNumeric = value.month;
          dateBucket.DayOfMonth = value.day;
        },
        dateExtractor);
  }

  @internal void AddEmbeddedTimePattern(String characterInPattern,
      String embeddedPatternText,
      /*LocalTimePatternParser.*/LocalTimeParseBucket Function(TBucket) timeBucketExtractor,
      LocalTime Function(TResult) timeExtractor) {
    var templateTime = timeBucketExtractor(CreateSampleBucket()).TemplateValue;
    AddField(PatternFields.embeddedTime, characterInPattern);
    AddEmbeddedPattern(
        LocalTimePattern
            .Create(embeddedPatternText, FormatInfo, templateTime)
            .UnderlyingPattern,
            (TBucket bucket, LocalTime value) {
          var timeBucket = timeBucketExtractor(bucket);
          timeBucket.Hours24 = value.hour;
          timeBucket.Minutes = value.minute;
          timeBucket.Seconds = value.second;
          timeBucket.FractionalSeconds = value.nanosecondOfSecond;
        },
        timeExtractor);
  }

  /// Adds parsing/formatting of an embedded pattern, e.g. an offset within a ZonedDateTime/OffsetDateTime.
  @internal void AddEmbeddedPattern<TEmbedded>(
      IPartialPattern<TEmbedded> embeddedPattern,
      Function(TBucket, TEmbedded) parseAction,
      TEmbedded Function(TResult) valueExtractor) {

    AddParseAction((ValueCursor value, TBucket bucket) {
      var result = embeddedPattern.ParsePartial(value);
      if (!result.Success) {
        return result.ConvertError<TResult>();
      }
      parseAction(bucket, result.Value);
      return null;
    });
    AddFormatAction((value, StringBuffer sb) => embeddedPattern.AppendFormat(valueExtractor(value), sb));
  }
}

// todo: this was a C# hack ... it was inside SteppedPatternBuilder original ... this hack is messy
/// Hack to handle genitive month names - we only know what we need to do *after* we've parsed the whole pattern.
@internal abstract class IPostPatternParseFormatAction<TResult>
{
  Function(TResult, StringBuffer) BuildFormatAction(PatternFields finalFields);
}

@private /*sealed*/ class _SteppedPattern<TResult, TBucket extends ParseBucket<TResult>> implements IPartialPattern<TResult>
{
  // @private final Function(TResult, StringBuffer) formatActions;
  @private final List<Function(TResult, StringBuffer)> formatActions;
  // This will be null if the pattern is only capable of formatting.
  @private final Iterable<ParseAction<TResult, TBucket>> parseActions;
  @private final TBucket Function() bucketProvider;
  @private final PatternFields usedFields;
  @private final int expectedLength;

  _SteppedPattern._(this.formatActions, this.parseActions, this.bucketProvider, this.usedFields, TResult sample, this.expectedLength);

  factory _SteppedPattern(List<Function/*(TResult, StringBuffer)*/> formatActions, Iterable<ParseAction<TResult, TBucket>> parseActions, TBucket Function() bucketProvider,
      PatternFields usedFields, TResult sample)
  {
    // Format the sample value to work out the expected length, so we
    // can use that when creating a StringBuffer. This will definitely not always
    // be appropriate, but it's a start.
    StringBuffer builder = new StringBuffer();
    formatActions.forEach((formatAction) => formatAction(sample, builder));
    var expectedLength = builder.length;

    return new _SteppedPattern._(formatActions, parseActions, bucketProvider, usedFields, sample, expectedLength);
  }

  ParseResult<TResult> Parse(String text)
  {
    if (parseActions == null)
    {
      return ParseResult.FormatOnlyPattern;
    }
    if (text == null)
    {
      return ParseResult.ArgumentNull<TResult>("text");
    }
    if (text.length == 0)
    {
      return ParseResult.ValueStringEmpty;
    }

    var valueCursor = new ValueCursor(text);
    // Prime the pump... the value cursor ends up *before* the first character, but
    // our steps always assume it's *on* the right character.
    valueCursor.MoveNext();
    var result = ParsePartial(valueCursor);
    if (!result.Success)
    {
      return result;
    }
    // Check that we've used up all the text
    if (valueCursor.Current != TextCursor.Nul)
    {
      return ParseResult.ExtraValueCharacters<TResult>(valueCursor, valueCursor.Remainder);
    }
    return result;
  }

  String Format(TResult value)
  {
    // if StringBuffer gets an initial size: pass in expectedLength
    StringBuffer builder = new StringBuffer();
    // This will call all the actions in the multicast delegate.
    formatActions.forEach((formatAction) => formatAction(value, builder));
    /* todo: remove me
    for (var formatAction in formatActions) {
      var x = builder.toString();
      formatAction(value, builder);
      print('${x} --> ${builder.toString()}');
    }*/
    return builder.toString();
  }

  ParseResult<TResult> ParsePartial(ValueCursor cursor)
  {
    TBucket bucket = bucketProvider();

    for (var action in parseActions)
    {
      ParseResult<TResult> failure = action(cursor, bucket);
      if (failure != null)
      {
        return failure;
      }
    }
    return bucket.CalculateValue(usedFields, cursor.Value);
  }

  StringBuffer AppendFormat(TResult value, StringBuffer builder)
  {
    Preconditions.checkNotNull(builder, 'builder');
    formatActions.forEach((formatAction) => formatAction(value, builder));
    return builder;
  }
}
