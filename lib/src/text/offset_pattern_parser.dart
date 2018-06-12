// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';

@internal /*sealed*/ class OffsetPatternParser implements IPatternParser<Offset> {
  @private static final Map<String /*char*/, CharacterHandler<Offset, OffsetParseBucket>> PatternCharacterHandlers =
  {
    '%': SteppedPatternBuilder.HandlePercent /**<Offset, OffsetParseBucket>*/,
    '\'': SteppedPatternBuilder.HandleQuote /**<Offset, OffsetParseBucket>*/,
    '\"': SteppedPatternBuilder.HandleQuote /**<Offset, OffsetParseBucket>*/,
    '\\': SteppedPatternBuilder.HandleBackslash /**<Offset, OffsetParseBucket>*/,
    ':': (pattern, builder) => builder.AddLiteral1(builder.FormatInfo.timeSeparator, ParseResult.TimeSeparatorMismatch /**<Offset>*/),
    'h': (pattern, builder) => throw new InvalidPatternError.format(TextErrorMessages.Hour12PatternNotSupported, ['Offset']),
    'H': SteppedPatternBuilder.HandlePaddedField<Offset, OffsetParseBucket>(
        2, PatternFields.hours24, 0, 23, GetPositiveHours, (bucket, value) => bucket.Hours = value),
    'm': SteppedPatternBuilder.HandlePaddedField<Offset, OffsetParseBucket>(
        2, PatternFields.minutes, 0, 59, GetPositiveMinutes, (bucket, value) => bucket.Minutes = value),
    's': SteppedPatternBuilder.HandlePaddedField<Offset, OffsetParseBucket>(
        2, PatternFields.seconds, 0, 59, GetPositiveSeconds, (bucket, value) => bucket.Seconds = value),
    '+': HandlePlus,
    '-': HandleMinus,
    'Z': (ignored1, ignored2) => throw new InvalidPatternError(TextErrorMessages.ZPrefixNotAtStartOfPattern)
  };

  // These are used to compute the individual (always-positive) components of an offset.
  // For example, an offset of "three and a half hours behind UTC" would have a "positive hours" value
  // of 3, and a "positive minutes" value of 30. The sign is computed elsewhere.
  @private static int GetPositiveHours(Offset offset) => offset.milliseconds.abs() ~/ TimeConstants.millisecondsPerHour;

  @private static int GetPositiveMinutes(Offset offset) =>
      (offset.milliseconds.abs() % TimeConstants.millisecondsPerHour) ~/ TimeConstants.millisecondsPerMinute;

  @private static int GetPositiveSeconds(Offset offset) =>
      (offset.milliseconds.abs() % TimeConstants.millisecondsPerMinute) ~/ TimeConstants.millisecondsPerSecond;

  // Note: to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  IPattern<Offset> ParsePattern(String patternText, TimeMachineFormatInfo formatInfo) => ParsePartialPattern(patternText, formatInfo);

  @private IPartialPattern<Offset> ParsePartialPattern(String patternText, TimeMachineFormatInfo formatInfo) {
    // Nullity check is performed in OffsetPattern.
    if (patternText.length == 0) {
      throw new InvalidPatternError(TextErrorMessages.FormatStringEmpty);
    }

    if (patternText.length == 1) {
      switch (patternText) {
        case "g":
          return (new CompositePatternBuilder<Offset>()
            ..Add(ParsePartialPattern(formatInfo.offsetPatternLong, formatInfo), (offset) => true)..Add(
                ParsePartialPattern(formatInfo.offsetPatternMedium, formatInfo), HasZeroSeconds)..Add(
                ParsePartialPattern(formatInfo.offsetPatternShort, formatInfo), HasZeroSecondsAndMinutes)).BuildAsPartial();
        case "G":
          return new ZPrefixPattern(ParsePartialPattern("g", formatInfo));
        case "i":
          return (new CompositePatternBuilder<Offset>()
            ..Add(ParsePartialPattern(formatInfo.offsetPatternLongNoPunctuation, formatInfo), (offset) => true)..Add(
                ParsePartialPattern(formatInfo.offsetPatternMediumNoPunctuation, formatInfo), HasZeroSeconds)..Add(
                ParsePartialPattern(formatInfo.offsetPatternShortNoPunctuation, formatInfo), HasZeroSecondsAndMinutes)).BuildAsPartial();
        case "I":
          return new ZPrefixPattern(ParsePartialPattern("i", formatInfo));
        case "l":
          patternText = formatInfo.offsetPatternLong;
          break;
        case "m":
          patternText = formatInfo.offsetPatternMedium;
          break;
        case "s":
          patternText = formatInfo.offsetPatternShort;
          break;
        case "L":
          patternText = formatInfo.offsetPatternLongNoPunctuation;
          break;
        case "M":
          patternText = formatInfo.offsetPatternMediumNoPunctuation;
          break;
        case "S":
          patternText = formatInfo.offsetPatternShortNoPunctuation;
          break;
        default:
          throw new InvalidPatternError.format(TextErrorMessages.UnknownStandardFormat, [patternText, 'Offset']);
      }
    }
    // This is the only way we'd normally end up in custom parsing land for Z on its own.
    if (patternText == "%Z") {
      throw new InvalidPatternError(TextErrorMessages.EmptyZPrefixedOffsetPattern);
    }

    // Handle Z-prefix by stripping it, parsing the rest as a normal pattern, then building a special pattern
    // which decides whether or not to delegate.
    bool zPrefix = patternText.startsWith("Z");

    var patternBuilder = new SteppedPatternBuilder<Offset, OffsetParseBucket>(formatInfo, () => new OffsetParseBucket());
    patternBuilder.ParseCustomPattern(zPrefix ? patternText.substring(1) : patternText, PatternCharacterHandlers);
    // No need to validate field combinations here, but we do need to do something a bit special
    // for Z-handling.
    IPartialPattern<Offset> pattern = patternBuilder.Build(new Offset.fromHoursAndMinutes(5, 30));
    return zPrefix ? new ZPrefixPattern(pattern) : pattern;
  }

  /// Returns true if the offset is representable just in hours and minutes (no seconds).
  @private static bool HasZeroSeconds(Offset offset) => (offset.seconds % TimeConstants.secondsPerMinute) == 0;

  /// Returns true if the offset is representable just in hours (no minutes or seconds).
  @private static bool HasZeroSecondsAndMinutes(Offset offset) => (offset.seconds % TimeConstants.secondsPerHour) == 0;

  // #region Character handlers
  @private static void HandlePlus(PatternCursor pattern, SteppedPatternBuilder<Offset, OffsetParseBucket> builder) {
    builder.AddField(PatternFields.sign, pattern.Current);
    builder.AddRequiredSign((bucket, positive) => bucket.IsNegative = !positive, (offset) => offset.milliseconds >= 0);
  }

  @private static void HandleMinus(PatternCursor pattern, SteppedPatternBuilder<Offset, OffsetParseBucket> builder) {
    builder.AddField(PatternFields.sign, pattern.Current);
    builder.AddNegativeOnlySign((bucket, positive) => bucket.IsNegative = !positive, (offset) => offset.milliseconds >= 0);
  }
// #endregion
}

/// Pattern which optionally delegates to another, but both parses and formats Offset.Zero as "Z".
@private /*sealed*/ class ZPrefixPattern implements IPartialPattern<Offset> {
  @private final IPartialPattern<Offset> fullPattern;

  @internal ZPrefixPattern(this.fullPattern);

  ParseResult<Offset> Parse(String text) => text == "Z" ? ParseResult.ForValue<Offset>(Offset.zero) : fullPattern.Parse(text);

  String Format(Offset value) => value == Offset.zero ? "Z" : fullPattern.Format(value);

  ParseResult<Offset> ParsePartial(ValueCursor cursor) {
    if (cursor.Current == 'Z') {
      cursor.MoveNext();
      return ParseResult.ForValue<Offset>(Offset.zero);
    }
    return fullPattern.ParsePartial(cursor);
  }

  StringBuffer AppendFormat(Offset value, StringBuffer builder) {
    Preconditions.checkNotNull(builder, 'builder');
    return value == Offset.zero ? (builder..write("Z")) : fullPattern.AppendFormat(value, builder);
  }
}

/// Provides a container for the interim parsed pieces of an [Offset] value.
@private /*sealed*/ class OffsetParseBucket extends ParseBucket<Offset> {
  /// The hours in the range [0, 23].
  @internal int Hours = 0;

  /// The minutes in the range [0, 59].
  @internal int Minutes = 0;

  /// The seconds in the range [0, 59].
  @internal int Seconds = 0;

  /// Gets a value indicating whether this instance is negative.
  ///
  /// <value>
  /// `true` if this instance is negative; otherwise, `false`.
  /// </value>
  bool IsNegative = false;

  /// Calculates the value from the parsed pieces.
  @internal
  @override
  ParseResult<Offset> CalculateValue(PatternFields usedFields, String text) {
    int seconds = Hours * TimeConstants.secondsPerHour + Minutes * TimeConstants.secondsPerMinute +
        Seconds;
    if (IsNegative) {
      seconds = -seconds;
    }
    return ParseResult.ForValue<Offset>(new Offset.fromSeconds(seconds));
  }
}

