// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';


/// Pattern parser for [LocalTime] values.
@internal /*sealed*/ class LocalTimePatternParser implements IPatternParser<LocalTime> {
  @private final LocalTime templateValue;

  @private static final Map<String /*char*/, CharacterHandler<LocalTime, LocalTimeParseBucket>> PatternCharacterHandlers =
  {
    '%': SteppedPatternBuilder.HandlePercent /**<LocalTime, LocalTimeParseBucket>*/,
    '\'': SteppedPatternBuilder.HandleQuote /**<LocalTime, LocalTimeParseBucket>*/,
    '\"': SteppedPatternBuilder.HandleQuote /**<LocalTime, LocalTimeParseBucket>*/,
    '\\': SteppedPatternBuilder.HandleBackslash /**<LocalTime, LocalTimeParseBucket>*/,
    '.': TimePatternHelper.CreatePeriodHandler<LocalTime, LocalTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.FractionalSeconds = value),
    ';': TimePatternHelper.CreateCommaDotHandler<LocalTime, LocalTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.FractionalSeconds = value),
    ':': (pattern, builder) => builder.AddLiteral1(builder.FormatInfo.timeSeparator, ParseResult.TimeSeparatorMismatch /**<LocalTime>*/),
    'h': SteppedPatternBuilder.HandlePaddedField /**<LocalTime, LocalTimeParseBucket>*/(
        2, PatternFields.hours12, 1, 12, (value) => value.clockHourOfHalfDay, (bucket, value) => bucket.Hours12 = value),
    'H': SteppedPatternBuilder.HandlePaddedField /**<LocalTime, LocalTimeParseBucket>*/(
        2, PatternFields.hours24, 0, 23, (value) => value.hour, (bucket, value) => bucket.Hours24 = value),
    'm': SteppedPatternBuilder.HandlePaddedField /**<LocalTime, LocalTimeParseBucket>*/(
        2, PatternFields.minutes, 0, 59, (value) => value.minute, (bucket, value) => bucket.Minutes = value),
    's': SteppedPatternBuilder.HandlePaddedField /**<LocalTime, LocalTimeParseBucket>*/(
        2, PatternFields.seconds, 0, 59, (value) => value.second, (bucket, value) => bucket.Seconds = value),
    'f': TimePatternHelper.CreateFractionHandler<LocalTime, LocalTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.FractionalSeconds = value),
    'F': TimePatternHelper.CreateFractionHandler<LocalTime, LocalTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.FractionalSeconds = value),
    't': TimePatternHelper.CreateAmPmHandler<LocalTime, LocalTimeParseBucket>((time) => time.hour, (bucket, value) => bucket.AmPm = value)
  };

  LocalTimePatternParser(this.templateValue);

  // Note: public to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  IPattern<LocalTime> ParsePattern(String patternText, TimeMachineFormatInfo formatInfo) {
    // Nullity check is performed in LocalTimePattern.
    if (patternText.length == 0) {
      throw new InvalidPatternError(TextErrorMessages.FormatStringEmpty);
    }

    if (patternText.length == 1) {
      String /*char*/ patternCharacter = patternText[0];
      patternText = ExpandStandardFormatPattern(patternCharacter, formatInfo);
      if (patternText == null) {
        throw new InvalidPatternError.format(TextErrorMessages.UnknownStandardFormat, [patternCharacter, 'LocalTime']);
      }
    }

    var patternBuilder = new SteppedPatternBuilder<LocalTime, LocalTimeParseBucket>(formatInfo,
            () => new LocalTimeParseBucket(templateValue));
    patternBuilder.ParseCustomPattern(patternText, PatternCharacterHandlers);
    patternBuilder.ValidateUsedFields();
    return patternBuilder.Build(templateValue);
  }

  @private String ExpandStandardFormatPattern(String /*char*/ patternCharacter, TimeMachineFormatInfo formatInfo) {
    switch (patternCharacter) {
      case 't':
        return formatInfo.dateTimeFormat.shortTimePattern;
      case 'T':
        return formatInfo.dateTimeFormat.longTimePattern;
      case 'r':
        return "HH:mm:ss.FFFFFFFFF";
      default:
        // Will be turned into an exception.
        return null;
    }
  }
}

/// Bucket to put parsed values in, ready for later result calculation. This type is also used
/// by LocalDateTimePattern to store and calculate values.
@internal /*sealed*/ class LocalTimeParseBucket extends ParseBucket<LocalTime> {
  @internal final LocalTime TemplateValue;

  /// The fractions of a second in nanoseconds, in the range [0, 999999999]
  @internal int FractionalSeconds = 0;

  /// The hours in the range [0, 23].
  @internal int Hours24 = 0;

  /// The hours in the range [1, 12].
  @internal int Hours12 = 0;

  /// The minutes in the range [0, 59].
  @internal int Minutes = 0;

  /// The seconds in the range [0, 59].
  @internal int Seconds = 0;

  /// AM (0) or PM (1) - or "take from the template" (2). The latter is used in situations
  /// where we're parsing but there is no AM or PM designator.
  @internal int AmPm = 0;

  @internal LocalTimeParseBucket(this.TemplateValue);

  /// Calculates the value from the parsed pieces.
  @internal
  @override
  ParseResult<LocalTime> CalculateValue(PatternFields usedFields, String text) {
    if (usedFields.HasAny(PatternFields.embeddedTime)) {
      return ParseResult.ForValue<LocalTime>(new LocalTime.fromHourMinuteSecondNanosecond(Hours24, Minutes, Seconds, FractionalSeconds));
    }
    if (AmPm == 2) {
      AmPm = TemplateValue.hour ~/ 12;
    }
    var hour = new OutBox<int>(0);
    ParseResult<LocalTime> failure = DetermineHour(usedFields, text, /*todo:out int*/ hour);
    if (failure != null) {
      return failure;
    }
    int minutes = usedFields.HasAny(PatternFields.minutes) ? Minutes : TemplateValue.minute;
    int seconds = usedFields.HasAny(PatternFields.seconds) ? Seconds : TemplateValue.second;
    int fraction = usedFields.HasAny(PatternFields.fractionalSeconds) ? FractionalSeconds : TemplateValue.nanosecondOfSecond;
    return ParseResult.ForValue<LocalTime>(new LocalTime.fromHourMinuteSecondNanosecond(hour.value, minutes, seconds, fraction));
  }

  //static const PatternFields hours12 = const PatternFields(1 << 1);
  //static const PatternFields amPm = const PatternFields(1 << 6);
  static const PatternFields hours12_booleanOR_amPm = const PatternFields(1 << 1 | 1 << 6);

  @private ParseResult<LocalTime> DetermineHour(PatternFields usedFields, String text, /*todo:out*/ OutBox<int> hour) {
    hour.value = 0;
    if (usedFields.HasAny(PatternFields.hours24)) {
      if (usedFields.HasAll(PatternFields.hours12 | PatternFields.hours24)) {
        if (Hours12 % 12 != Hours24 % 12) {
          return ParseResult.InconsistentValues<LocalTime>(text, 'H', 'h', 'LocalTime');
        }
      }
      if (usedFields.HasAny(PatternFields.amPm)) {
        if (Hours24 ~/ 12 != AmPm) {
          return ParseResult.InconsistentValues<LocalTime>(text, 'H', 't', 'LocalTime');
        }
      }
      hour.value = Hours24;
      return null;
    }

    // Okay, it's definitely valid - but we've still got 8 possibilities for what's been specified.
    var x = usedFields & (PatternFields.hours12 | PatternFields.amPm);
    if (x == hours12_booleanOR_amPm) {
      hour.value = (Hours12 % 12) + AmPm * 12;
    }
    else if (x == PatternFields.hours12) {
      hour.value = (Hours12 % 12) + (TemplateValue.hour ~/ 12) * 12;
    }
    else if (x == PatternFields.amPm) {
      hour.value = (TemplateValue.hour % 12) + AmPm * 12;
    }
    else {
      hour.value = TemplateValue.hour;
    }

    /*
    switch (usedFields & (PatternFields.hours12 | PatternFields.amPm)) {
      case hours12_booleanOR_amPm: // PatternFields.hours12 | PatternFields.amPm:
        hour = (Hours12 % 12) + AmPm * 12;
        break;
      case PatternFields.hours12:
        // Preserve AM/PM from template value
        hour = (Hours12 % 12) + (TemplateValue.Hour ~/ 12) * 12;
        break;
      case PatternFields.amPm:
        // Preserve 12-hour hour of day from template value, use specified AM/PM
        hour = (TemplateValue.Hour % 12) + AmPm * 12;
        break;
      case PatternFields.none:
        hour = TemplateValue.Hour;
        break;
    }*/

    return null;
  }
}
