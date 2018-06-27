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
@internal
typedef ParseResult<TResult> ParseAction<TResult, TBucket extends ParseBucket<TResult>>(ValueCursor cursor, TBucket bucket);

class _findLongestMatchCursor {
  int bestIndex = -1;
  int longestMatch = 0;
}

/// Builder for a pattern which implements parsing and formatting as a sequence of steps applied
/// in turn.
@internal
class SteppedPatternBuilder<TResult, TBucket extends ParseBucket<TResult>> {
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

  final TimeMachineFormatInfo formatInfo;

  PatternFields get usedFields => _usedFields;

  SteppedPatternBuilder(this.formatInfo, this._bucketProvider);
// : _formatActions ,
// _parseActions = new List<ParseAction<TResult, TBucket>>();

  /// Calls the bucket provider and returns a sample bucket. This means that any values
  /// normally propagated via the bucket can also be used when building the pattern.
  TBucket createSampleBucket() {
    return _bucketProvider();
  }

  /// Sets this pattern to only be capable of formatting; any attempt to parse using the
  /// built pattern will fail immediately.
  void setFormatOnly() {
    _formatOnly = true;
  }

  /// Performs common parsing operations: start with a parse action to move the
  /// value cursor onto the first character, then call a character handler for each
  /// character in the pattern to build up the steps. If any handler fails,
  /// that failure is returned - otherwise the return value is null.
  void parseCustomPattern(String patternText, Map<String, CharacterHandler<TResult, TBucket>> characterHandlers) {
    var patternCursor = new PatternCursor(patternText);

    // Now iterate over the pattern.
    while (patternCursor.moveNext()) {
      CharacterHandler<TResult, TBucket> handler = characterHandlers[patternCursor.current];
      if (handler != null) {
        handler(patternCursor, this);
      }
      else {
        String current = patternCursor.current;
        var currentCodeUnit = current.codeUnitAt(0);
        if ((currentCodeUnit >= _ACodeUnit && currentCodeUnit <= _ZCodeUnit)
            || (currentCodeUnit >= _aCodeUnit && currentCodeUnit <= _zCodeUnit)
            || current == PatternCursor.embeddedPatternStart || current == PatternCursor.embeddedPatternEnd) {
          throw new InvalidPatternError.format(TextErrorMessages.unquotedLiteral, [current]);
        }
        addLiteral2(patternCursor.current, ParseResult.mismatchedCharacter);
      }
    }
  }

  /// Validates the combination of fields used.
  void validateUsedFields() {
  // We assume invalid combinations are global across all parsers. The way that
  // the patterns are parsed ensures we never end up with any invalid individual fields
  // (e.g. time fields within a date pattern).
    if ((_usedFields & (PatternFields.era | PatternFields.yearOfEra)) == PatternFields.era) {
      throw new InvalidPatternError(TextErrorMessages.eraWithoutYearOfEra);
    }
    /*const*/ PatternFields calendarAndEra = PatternFields.era | PatternFields.calendar;
    if ((_usedFields & calendarAndEra) == calendarAndEra) {
      throw new InvalidPatternError(TextErrorMessages.calendarAndEra);
    }
  }

  /// Returns a built pattern. This is mostly to keep the API for the builder separate from that of the pattern,
  /// and for thread safety (publishing a new object, thus leading to a memory barrier).
  /// Note that this builder *must not* be used after the result has been built.
  IPartialPattern<TResult> build(TResult sample) {
    // If we've got an embedded date and any *other* date fields, throw.
    if (_usedFields.hasAny(PatternFields.embeddedDate) &&
        _usedFields.hasAny(PatternFields.allDateFields & ~PatternFields.embeddedDate)) {
      throw new InvalidPatternError(TextErrorMessages.dateFieldAndEmbeddedDate);
    }
    // Ditto for time
    if (_usedFields.hasAny(PatternFields.embeddedTime) &&
        _usedFields.hasAny(PatternFields.allTimeFields & ~PatternFields.embeddedTime)) {
      throw new InvalidPatternError(TextErrorMessages.timeFieldAndEmbeddedTime);
    }

    List<Function/*(TResult, StringBuffer)*/> formatDelegate = [];
    for (/*Function(TResult, StringBuffer)*/ dynamic formatAction in _formatActions) {
      if (formatAction is IPostPatternParseFormatAction) {
        formatDelegate.add(formatAction.buildFormatAction(_usedFields));
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
  void addField(PatternFields field, String characterInPattern) {
    PatternFields newUsedFields = _usedFields | field;
    if (newUsedFields == _usedFields) {
      throw new InvalidPatternError.format(TextErrorMessages.repeatedFieldInPattern, [characterInPattern]);
    }
    _usedFields = newUsedFields;
  }

  void addParseAction(ParseAction<TResult, TBucket> parseAction) => _parseActions.add(parseAction);

  void addFormatAction(Function(TResult, StringBuffer) formatAction) => _formatActions.add(formatAction);

  void addPostPatternParseFormatAction(IPostPatternParseFormatAction formatAction) => _formatActions.add(formatAction);

  /// Equivalent of [addParseValueAction] but for 64-bit integers. Currently only
  /// positive values are supported.
  void addParseInt64ValueAction(int minimumDigits, int maximumDigits, String patternChar,
      int minimumValue, int maximumValue, Function(TBucket, int) valueSetter) {
    Preconditions.debugCheckArgumentRange('minimumValue', minimumValue, 0, Utility.int64MaxValue);

    addParseAction((ValueCursor cursor, TBucket bucket) {
      int startingIndex = cursor.index;
      int value = cursor.parseInt64Digits(minimumDigits, maximumDigits);
      if (value == null) {
        cursor.move(startingIndex);
        return ParseResult.mismatchedNumber<TResult>(cursor, stringFilled(patternChar, minimumDigits));
      }
      if (value < minimumValue || value > maximumValue) {
        cursor.move(startingIndex);
        return ParseResult.fieldValueOutOfRange<TResult>(cursor, value, patternChar, TResult.toString());
      }

      valueSetter(bucket, value);
      return null;
    });
  }

  void addParseValueAction(int minimumDigits, int maximumDigits, String patternChar,
      int minimumValue, int maximumValue, Function(TBucket, int) valueSetter) {

    addParseAction((ValueCursor cursor, TBucket bucket) {
      int startingIndex = cursor.index;
      int value;
      bool negative = cursor.matchSingle('-');
      if (negative && minimumValue >= 0) {
        cursor.move(startingIndex);
        return ParseResult.unexpectedNegative<TResult>(cursor);
      }

      value = cursor.parseDigits(minimumDigits, maximumDigits);
      if (value == null) {
        cursor.move(startingIndex);
        return ParseResult.mismatchedNumber<TResult>(cursor, stringFilled(patternChar, minimumDigits));
      }
      if (negative) {
        value = -value;
      }
      if (value < minimumValue || value > maximumValue) {
        cursor.move(startingIndex);
        return ParseResult.fieldValueOutOfRange<TResult>(cursor, value, patternChar, TResult.toString());
      }

      valueSetter(bucket, value);
      return null;
    });
  }

// ParseResult<TResult> ParseAction<TResult, TBucket extends ParseBucket<TResult>>(ValueCursor cursor, TBucket bucket);
// internal void AddParseAction(ParseAction parseAction) => parseActions.Add(parseAction);


  /// Adds text which must be matched exactly when parsing, and appended directly when formatting.
  void addLiteral1(String expectedText, ParseResult<TResult> Function(ValueCursor) failure) {
    // Common case - single character literal, often a date or time separator.
    if (expectedText.length == 1) {
      String expectedChar = expectedText[0];
      addParseAction((ValueCursor str, TBucket bucket) => str.matchSingle(expectedChar) ? null : failure(str));
      addFormatAction((TResult value, StringBuffer builder) => builder.write(expectedChar));
      return;
    }
    addParseAction((ValueCursor str, TBucket bucket) => str.matchText(expectedText) ? null : failure(str));
    addFormatAction((TResult value, StringBuffer builder) => builder.write(expectedText));
  }

  static void handleQuote<TResult, TBucket extends ParseBucket<TResult>>(PatternCursor pattern, SteppedPatternBuilder<TResult, TBucket> builder) {
    String quoted = pattern.getQuotedString(pattern.current);
    builder.addLiteral1(quoted, ParseResult.quotedStringMismatch);
  }

  static void handleBackslash<TResult, TBucket extends ParseBucket<TResult>>(PatternCursor pattern, SteppedPatternBuilder<TResult, TBucket> builder) {
    if (!pattern.moveNext()) {
      throw new InvalidPatternError(TextErrorMessages.escapeAtEndOfString);
    }
    builder.addLiteral2(pattern.current, ParseResult.escapedCharacterMismatch);
  }

  /// Handle a leading "%" which acts as a pseudo-escape - it's mostly used to allow format strings such as "%H" to mean
  /// "use a custom format string consisting of H instead of a standard pattern H".
  static void handlePercent<TResult, TBucket extends ParseBucket<TResult>>(PatternCursor pattern, SteppedPatternBuilder<TResult, TBucket> builder) {
    if (pattern.hasMoreCharacters) {
      if (pattern.peekNext() != '%') {
        // Handle the next character as normal
        return;
      }
      throw new InvalidPatternError(TextErrorMessages.percentDoubled);
    }
    throw new InvalidPatternError(TextErrorMessages.percentAtEndOfString);
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
  static CharacterHandler<TResult, TBucket> handlePaddedField<TResult, TBucket extends ParseBucket<TResult>>(int maxCount, PatternFields field, int minValue, int maxValue,
      int Function(TResult) getter, int Function(TBucket, int) setter) {
    return (PatternCursor pattern,  SteppedPatternBuilder<TResult, TBucket> builder) {
      int count = pattern.getRepeatCount(maxCount);
      builder.addField(field, pattern.current);
      builder.addParseValueAction(count, maxCount, pattern.current, minValue, maxValue, setter);
      builder.addFormatLeftPad(count, getter, assumeNonNegative: minValue >= 0, assumeFitsInCount: count == maxCount);
    };
  }

  /// Adds a character which must be matched exactly when parsing, and appended directly when formatting.
  void addLiteral2(String expectedChar, ParseResult<TResult> Function(ValueCursor, String) failureSelector) {
    addParseAction((ValueCursor str, TBucket bucket) => str.matchSingle(expectedChar) ? null : failureSelector(str, expectedChar));
    addFormatAction((TResult value, StringBuffer builder) => builder.write(expectedChar));
  }

  /// Adds parse actions for a list of strings, such as days of the week or month names.
  /// The parsing is performed case-insensitively. All candidates are tested, and only the longest
  /// match is used.
  ///
  /// Adds parse actions for two list of strings, such as non-genitive and genitive month names.
  /// The parsing is performed case-insensitively. All candidates are tested, and only the longest
  /// match is used.
  void addParseLongestTextAction(String field, Function(TBucket, int) setter, CompareInfo compareInfo, Iterable<String> textValues1,
      [Iterable<String> textValues2 = null]) {
    addParseAction((ValueCursor str, TBucket bucket) {
      var matchCursor = new _findLongestMatchCursor();

      _findLongestMatch(compareInfo, str, textValues1, matchCursor);
      if (textValues2 != null) _findLongestMatch(compareInfo, str, textValues2, matchCursor);
      if (matchCursor.bestIndex != -1) {
        setter(bucket, matchCursor.bestIndex);
        str.move(str.index + matchCursor.longestMatch);
        return null;
      }
      return ParseResult.mismatchedText<TResult>(str, field);
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
  static void _findLongestMatch(CompareInfo compareInfo, ValueCursor cursor, List<String> values, _findLongestMatchCursor matchCursor) {
    for (int i = 0; i < values.length; i++) {
      String candidate = values[i];
      if (candidate == null || candidate.length <= matchCursor.longestMatch) {
        continue;
      }
      if (cursor.matchCaseInsensitive(candidate, compareInfo, false)) {
        matchCursor.bestIndex = i;
        matchCursor.longestMatch = candidate.length;
      }
    }
  }

  /// Adds parse and format actions for a mandatory positive/negative sign.
  ///
  /// [signSetter]: Action to take when to set the given sign within the bucket
  /// [nonNegativePredicate]: Predicate to detect whether the value being formatted is non-negative
  void addRequiredSign(Function(TBucket, bool) signSetter, bool Function(TResult) nonNegativePredicate) {
    addParseAction((ValueCursor str, TBucket bucket) {
      if (str.matchSingle("-")) {
        signSetter(bucket, false);
        return null;
      }
      if (str.matchSingle("+")) {
        signSetter(bucket, true);
        return null;
      }
      return ParseResult.missingSign<TResult>(str);
    }
    );
    addFormatAction((TResult value, StringBuffer sb) => sb.write(nonNegativePredicate(value) ? "+" : "-"));
  }

  /// Adds parse and format actions for an "negative only" sign.
  ///
  /// [signSetter]: Action to take when to set the given sign within the bucket
  /// [nonNegativePredicate]: Predicate to detect whether the value being formatted is non-negative
  void addNegativeOnlySign(Function(TBucket, bool) signSetter, bool Function(TResult) nonNegativePredicate) {
    addParseAction((ValueCursor str, TBucket bucket) {
      if (str.matchSingle("-")) {
        signSetter(bucket, false);
        return null;
      }
      if (str.matchSingle("+")) {
        return ParseResult.positiveSignInvalid<TResult>(str);
      }
      signSetter(bucket, true);
      return null;
    });
    addFormatAction((TResult value, StringBuffer builder) {
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
  void addFormatLeftPad(int count, int Function(TResult) selector, {bool assumeNonNegative, bool assumeFitsInCount}) {
    if (count == 2 && assumeNonNegative && assumeFitsInCount) {
      addFormatAction((TResult value, StringBuffer sb) => FormatHelper.format2DigitsNonNegative(selector(value), sb));
    }
    else if (count == 4 && assumeFitsInCount) {
      addFormatAction((TResult value, StringBuffer sb) => FormatHelper.format4DigitsValueFits(selector(value), sb));
    }
    else if (assumeNonNegative) {
      addFormatAction((TResult value, StringBuffer sb) => FormatHelper.leftPadNonNegative(selector(value), count, sb));
    }
    else {
      addFormatAction((TResult value, StringBuffer sb) => FormatHelper.leftPad(selector(value), count, sb));
    }
  }

  void addFormatFraction(int width, int scale, int Function(TResult) selector) =>
      addFormatAction((TResult value, StringBuffer sb) => FormatHelper.appendFraction(selector(value), width, scale, sb));

  void addFormatFractionTruncate(int width, int scale, int Function(TResult) selector) =>
      addFormatAction((TResult value, StringBuffer sb) => FormatHelper.appendFractionTruncate(selector(value), width, scale, sb));

  /// Handles date, time and date/time embedded patterns.
  void addEmbeddedLocalPartial(PatternCursor pattern,
      /*LocalDatePatternParser.*/LocalDateParseBucket Function(TBucket) dateBucketExtractor,
      /*LocalTimePatternParser.*/LocalTimeParseBucket Function(TBucket) timeBucketExtractor,
      LocalDate Function(TResult) dateExtractor,
      LocalTime Function(TResult) timeExtractor,
      // null if date/time embedded patterns are invalid
      LocalDateTime Function(TResult) dateTimeExtractor) {

    // This will be d (date-only), t (time-only), or < (date and time)
    // If it's anything else, we'll see the problem when we try to get the pattern.
    var patternType = pattern.peekNext();
    if (patternType == 'd' || patternType == 't') {
      pattern.moveNext();
    }
    String embeddedPatternText = pattern.getEmbeddedPattern();
    switch (patternType) {
      case '<':
        {
          var sampleBucket = createSampleBucket();
          var templateTime = timeBucketExtractor(sampleBucket).templateValue;
          var templateDate = dateBucketExtractor(sampleBucket).templateValue;
          if (dateTimeExtractor == null) {
            throw new InvalidPatternError(TextErrorMessages.invalidEmbeddedPatternType);
          }
          addField(PatternFields.embeddedDate, 'l');
          addField(PatternFields.embeddedTime, 'l');
          addEmbeddedPattern(
              LocalDateTimePattern
                  .create(embeddedPatternText, formatInfo, templateDate.at(templateTime))
                  .underlyingPattern,
                  (TBucket bucket, LocalDateTime value) {
                var dateBucket = dateBucketExtractor(bucket);
                var timeBucket = timeBucketExtractor(bucket);
                dateBucket.calendar = value.calendar;
                dateBucket.year = value.year;
                dateBucket.monthOfYearNumeric = value.month;
                dateBucket.dayOfMonth = value.day;
                timeBucket.hours24 = value.hour;
                timeBucket.minutes = value.minute;
                timeBucket.seconds = value.second;
                timeBucket.fractionalSeconds = value.nanosecondOfSecond;
              },
              dateTimeExtractor);
          break;
        }
      case 'd':
        addEmbeddedDatePattern('l', embeddedPatternText, dateBucketExtractor, dateExtractor);
        break;
      case 't':
        addEmbeddedTimePattern('l', embeddedPatternText, timeBucketExtractor, timeExtractor);
        break;
      default:
        throw new StateError("Bug in Time Machine: embedded pattern type wasn't date, time, or date+time");
    }
  }

  void addEmbeddedDatePattern(String characterInPattern,
      String embeddedPatternText,
      /*LocalDatePatternParser.*/LocalDateParseBucket Function(TBucket) dateBucketExtractor,
      LocalDate Function(TResult) dateExtractor) {
    var templateDate = dateBucketExtractor(createSampleBucket()).templateValue;
    addField(PatternFields.embeddedDate, characterInPattern);
    addEmbeddedPattern(
        LocalDatePattern
            .create(embeddedPatternText, formatInfo, templateDate)
            .underlyingPattern,
            (TBucket bucket, LocalDate value) {
          var dateBucket = dateBucketExtractor(bucket);
          dateBucket.calendar = value.calendar;
          dateBucket.year = value.year;
          dateBucket.monthOfYearNumeric = value.month;
          dateBucket.dayOfMonth = value.day;
        },
        dateExtractor);
  }

  void addEmbeddedTimePattern(String characterInPattern,
      String embeddedPatternText,
      /*LocalTimePatternParser.*/LocalTimeParseBucket Function(TBucket) timeBucketExtractor,
      LocalTime Function(TResult) timeExtractor) {
    var templateTime = timeBucketExtractor(createSampleBucket()).templateValue;
    addField(PatternFields.embeddedTime, characterInPattern);
    addEmbeddedPattern(
        LocalTimePattern
            .create(embeddedPatternText, formatInfo, templateTime)
            .underlyingPattern,
            (TBucket bucket, LocalTime value) {
          var timeBucket = timeBucketExtractor(bucket);
          timeBucket.hours24 = value.hour;
          timeBucket.minutes = value.minute;
          timeBucket.seconds = value.second;
          timeBucket.fractionalSeconds = value.nanosecondOfSecond;
        },
        timeExtractor);
  }

  /// Adds parsing/formatting of an embedded pattern, e.g. an offset within a ZonedDateTime/OffsetDateTime.
  void addEmbeddedPattern<TEmbedded>(
      IPartialPattern<TEmbedded> embeddedPattern,
      Function(TBucket, TEmbedded) parseAction,
      TEmbedded Function(TResult) valueExtractor) {

    addParseAction((ValueCursor value, TBucket bucket) {
      var result = embeddedPattern.parsePartial(value);
      if (!result.success) {
        return result.convertError<TResult>();
      }
      parseAction(bucket, result.value);
      return null;
    });
    addFormatAction((value, StringBuffer sb) => embeddedPattern.appendFormat(valueExtractor(value), sb));
  }
}

// todo: this was a C# hack ... it was inside SteppedPatternBuilder original ... this hack is messy
/// Hack to handle genitive month names - we only know what we need to do *after* we've parsed the whole pattern.
@internal
abstract class IPostPatternParseFormatAction<TResult>
{
  Function(TResult, StringBuffer) buildFormatAction(PatternFields finalFields);
}

class _SteppedPattern<TResult, TBucket extends ParseBucket<TResult>> implements IPartialPattern<TResult>
{
  // @private final Function(TResult, StringBuffer) formatActions;
  // todo: check back after Dart 2.0 stable to see if we can bring back type safety here (we can sort of use this in VM, fails in DDC)
  final List<Function/*(TResult, StringBuffer)*/> _formatActions;
  // This will be null if the pattern is only capable of formatting.
  final Iterable<ParseAction<TResult, TBucket>> _parseActions;
  final TBucket Function() _bucketProvider;
  final PatternFields _usedFields;
  final int _expectedLength;

  _SteppedPattern._(this._formatActions, this._parseActions, this._bucketProvider, this._usedFields, TResult sample, this._expectedLength);

  factory _SteppedPattern(List<Function/*(TResult, StringBuffer)*/> formatActions, Iterable<ParseAction<TResult, TBucket>> parseActions, TBucket Function() bucketProvider,
      PatternFields usedFields, TResult sample)
  {
    // todo: evaluate and remove:: we don't get to pre-game StringBuffer -- or... can we? Investigate!
    // Format the sample value to work out the expected length, so we
    // can use that when creating a StringBuffer. This will definitely not always
    // be appropriate, but it's a start.
    StringBuffer builder = new StringBuffer();
    formatActions.forEach((formatAction) => formatAction(sample, builder));
    var expectedLength = builder.length;

    return new _SteppedPattern<TResult, TBucket>._(formatActions, parseActions, bucketProvider, usedFields, sample, expectedLength);
  }

  ParseResult<TResult> parse(String text)
  {
    if (_parseActions == null)
    {
      return ParseResult.formatOnlyPattern;
    }
    if (text == null)
    {
      return ParseResult.argumentNull<TResult>("text");
    }
    if (text.length == 0)
    {
      return ParseResult.valueStringEmpty;
    }

    var valueCursor = new ValueCursor(text);
    // Prime the pump... the value cursor ends up *before* the first character, but
    // our steps always assume it's *on* the right character.
    valueCursor.moveNext();
    var result = parsePartial(valueCursor);
    if (!result.success)
    {
      return result;
    }
    // Check that we've used up all the text
    if (valueCursor.current != TextCursor.nul)
    {
      return ParseResult.extraValueCharacters<TResult>(valueCursor, valueCursor.remainder);
    }
    return result;
  }

  String format(TResult value)
  {
    // if StringBuffer gets an initial size: pass in expectedLength
    StringBuffer builder = new StringBuffer();
    // This will call all the actions in the multicast delegate.
     _formatActions.forEach((formatAction) => formatAction(value, builder));
    /* todo: remove me
    for (var formatAction in _formatActions) {
      var x = builder.toString();
      formatAction(value, builder);
      print('${x} --> ${builder.toString()}');
    }*/
    return builder.toString();
  }

  ParseResult<TResult> parsePartial(ValueCursor cursor)
  {
    TBucket bucket = _bucketProvider();

    for (var action in _parseActions)
    {
      ParseResult<TResult> failure = action(cursor, bucket);
      if (failure != null)
      {
        return failure;
      }
    }
    return bucket.calculateValue(_usedFields, cursor.value);
  }

  StringBuffer appendFormat(TResult value, StringBuffer builder)
  {
    Preconditions.checkNotNull(builder, 'builder');
    _formatActions.forEach((formatAction) => formatAction(value, builder));
    return builder;
  }
}
