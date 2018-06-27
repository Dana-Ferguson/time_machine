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
  final LocalTime _templateValue;

  static final Map<String /*char*/, CharacterHandler<LocalTime, LocalTimeParseBucket>> _patternCharacterHandlers =
  {
    '%': SteppedPatternBuilder.handlePercent /**<LocalTime, LocalTimeParseBucket>*/,
    '\'': SteppedPatternBuilder.handleQuote /**<LocalTime, LocalTimeParseBucket>*/,
    '\"': SteppedPatternBuilder.handleQuote /**<LocalTime, LocalTimeParseBucket>*/,
    '\\': SteppedPatternBuilder.handleBackslash /**<LocalTime, LocalTimeParseBucket>*/,
    '.': TimePatternHelper.createPeriodHandler<LocalTime, LocalTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.fractionalSeconds = value),
    ';': TimePatternHelper.createCommaDotHandler<LocalTime, LocalTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.fractionalSeconds = value),
    ':': (pattern, builder) => builder.addLiteral1(builder.formatInfo.timeSeparator, IParseResult.timeSeparatorMismatch /**<LocalTime>*/),
    'h': SteppedPatternBuilder.handlePaddedField /**<LocalTime, LocalTimeParseBucket>*/(
        2, PatternFields.hours12, 1, 12, (value) => value.clockHourOfHalfDay, (bucket, value) => bucket.hours12 = value),
    'H': SteppedPatternBuilder.handlePaddedField /**<LocalTime, LocalTimeParseBucket>*/(
        2, PatternFields.hours24, 0, 23, (value) => value.hour, (bucket, value) => bucket.hours24 = value),
    'm': SteppedPatternBuilder.handlePaddedField /**<LocalTime, LocalTimeParseBucket>*/(
        2, PatternFields.minutes, 0, 59, (value) => value.minute, (bucket, value) => bucket.minutes = value),
    's': SteppedPatternBuilder.handlePaddedField /**<LocalTime, LocalTimeParseBucket>*/(
        2, PatternFields.seconds, 0, 59, (value) => value.second, (bucket, value) => bucket.seconds = value),
    'f': TimePatternHelper.createFractionHandler<LocalTime, LocalTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.fractionalSeconds = value),
    'F': TimePatternHelper.createFractionHandler<LocalTime, LocalTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.fractionalSeconds = value),
    't': TimePatternHelper.createAmPmHandler<LocalTime, LocalTimeParseBucket>((time) => time.hour, (bucket, value) => bucket.amPm = value)
  };

  LocalTimePatternParser(this._templateValue);

  // Note: public to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  IPattern<LocalTime> parsePattern(String patternText, TimeMachineFormatInfo formatInfo) {
    // Nullity check is performed in LocalTimePattern.
    if (patternText.length == 0) {
      throw new InvalidPatternError(TextErrorMessages.formatStringEmpty);
    }

    if (patternText.length == 1) {
      String /*char*/ patternCharacter = patternText[0];
      patternText = _expandStandardFormatPattern(patternCharacter, formatInfo);
      if (patternText == null) {
        throw new InvalidPatternError.format(TextErrorMessages.unknownStandardFormat, [patternCharacter, 'LocalTime']);
      }
    }

    var patternBuilder = new SteppedPatternBuilder<LocalTime, LocalTimeParseBucket>(formatInfo,
            () => new LocalTimeParseBucket(_templateValue));
    patternBuilder.parseCustomPattern(patternText, _patternCharacterHandlers);
    patternBuilder.validateUsedFields();
    return patternBuilder.build(_templateValue);
  }

  String _expandStandardFormatPattern(String /*char*/ patternCharacter, TimeMachineFormatInfo formatInfo) {
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
  @internal final LocalTime templateValue;

  /// The fractions of a second in nanoseconds, in the range [0, 999999999]
  @internal int fractionalSeconds = 0;

  /// The hours in the range [0, 23].
  @internal int hours24 = 0;

  /// The hours in the range [1, 12].
  @internal int hours12 = 0;

  /// The minutes in the range [0, 59].
  @internal int minutes = 0;

  /// The seconds in the range [0, 59].
  @internal int seconds = 0;

  /// AM (0) or PM (1) - or "take from the template" (2). The latter is used in situations
  /// where we're parsing but there is no AM or PM designator.
  @internal int amPm = 0;

  @internal LocalTimeParseBucket(this.templateValue);

  /// Calculates the value from the parsed pieces.
  @internal
  @override
  ParseResult<LocalTime> calculateValue(PatternFields usedFields, String text) {
    if (usedFields.hasAny(PatternFields.embeddedTime)) {
      return ParseResult.forValue<LocalTime>(new LocalTime.fromHourMinuteSecondNanosecond(hours24, minutes, seconds, fractionalSeconds));
    }
    if (amPm == 2) {
      amPm = templateValue.hour ~/ 12;
    }
    var hour = new OutBox<int>(0);
    ParseResult<LocalTime> failure = _determineHour(usedFields, text, /*todo:out int*/ hour);
    if (failure != null) {
      return failure;
    }
    int _minutes = usedFields.hasAny(PatternFields.minutes) ? minutes : templateValue.minute;
    int _seconds = usedFields.hasAny(PatternFields.seconds) ? seconds : templateValue.second;
    int _fraction = usedFields.hasAny(PatternFields.fractionalSeconds) ? fractionalSeconds : templateValue.nanosecondOfSecond;
    return ParseResult.forValue<LocalTime>(new LocalTime.fromHourMinuteSecondNanosecond(hour.value, _minutes, _seconds, _fraction));
  }

  //static const PatternFields hours12 = const PatternFields(1 << 1);
  //static const PatternFields amPm = const PatternFields(1 << 6);
  static const PatternFields _hours12_booleanOR_amPm = const PatternFields(1 << 1 | 1 << 6);

  ParseResult<LocalTime> _determineHour(PatternFields usedFields, String text, /*todo:out*/ OutBox<int> hour) {
    hour.value = 0;
    if (usedFields.hasAny(PatternFields.hours24)) {
      if (usedFields.hasAll(PatternFields.hours12 | PatternFields.hours24)) {
        if (hours12 % 12 != hours24 % 12) {
          return IParseResult.inconsistentValues<LocalTime>(text, 'H', 'h', 'LocalTime');
        }
      }
      if (usedFields.hasAny(PatternFields.amPm)) {
        if (hours24 ~/ 12 != amPm) {
          return IParseResult.inconsistentValues<LocalTime>(text, 'H', 't', 'LocalTime');
        }
      }
      hour.value = hours24;
      return null;
    }

    // Okay, it's definitely valid - but we've still got 8 possibilities for what's been specified.
    var x = usedFields & (PatternFields.hours12 | PatternFields.amPm);
    if (x == _hours12_booleanOR_amPm) {
      hour.value = (hours12 % 12) + amPm * 12;
    }
    else if (x == PatternFields.hours12) {
      hour.value = (hours12 % 12) + (templateValue.hour ~/ 12) * 12;
    }
    else if (x == PatternFields.amPm) {
      hour.value = (templateValue.hour % 12) + amPm * 12;
    }
    else {
      hour.value = templateValue.hour;
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
