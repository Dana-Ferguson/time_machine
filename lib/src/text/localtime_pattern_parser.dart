// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';

/// Pattern parser for [LocalTime] values.
@internal
class LocalTimePatternParser implements IPatternParser<LocalTime> {
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
        2, PatternFields.hours12, 1, 12, (value) => value.hourOf12HourClock, (bucket, value) => bucket.hours12 = value),
    'H': SteppedPatternBuilder.handlePaddedField /**<LocalTime, LocalTimeParseBucket>*/(
        2, PatternFields.hours24, 0, 23, (value) => value.hourOfDay, (bucket, value) => bucket.hours24 = value),
    'm': SteppedPatternBuilder.handlePaddedField /**<LocalTime, LocalTimeParseBucket>*/(
        2, PatternFields.minutes, 0, 59, (value) => value.minuteOfHour, (bucket, value) => bucket.minutes = value),
    's': SteppedPatternBuilder.handlePaddedField /**<LocalTime, LocalTimeParseBucket>*/(
        2, PatternFields.seconds, 0, 59, (value) => value.secondOfMinute, (bucket, value) => bucket.seconds = value),
    'f': TimePatternHelper.createFractionHandler<LocalTime, LocalTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.fractionalSeconds = value),
    'F': TimePatternHelper.createFractionHandler<LocalTime, LocalTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.fractionalSeconds = value),
    't': TimePatternHelper.createAmPmHandler<LocalTime, LocalTimeParseBucket>((time) => time.hourOfDay, (bucket, value) => bucket.amPm = value)
  };

  LocalTimePatternParser(this._templateValue);

  // Note: public to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  @override
  IPattern<LocalTime> parsePattern(String patternText, TimeMachineFormatInfo formatInfo) {
    // Nullity check is performed in LocalTimePattern.
    if (patternText.isEmpty) {
      throw InvalidPatternError(TextErrorMessages.formatStringEmpty);
    }

    if (patternText.length == 1) {
      String /*char*/ patternCharacter = patternText[0];
      final expandedPatternText = _expandStandardFormatPattern(patternCharacter, formatInfo);
      if (expandedPatternText == null) {
        throw IInvalidPatternError.format(TextErrorMessages.unknownStandardFormat, [patternCharacter, 'LocalTime']);
      }
      patternText = expandedPatternText;
    }

    var patternBuilder = SteppedPatternBuilder<LocalTime, LocalTimeParseBucket>(formatInfo,
            () => LocalTimeParseBucket(_templateValue));
    patternBuilder.parseCustomPattern(patternText, _patternCharacterHandlers);
    patternBuilder.validateUsedFields();
    return patternBuilder.build(_templateValue);
  }

  String? _expandStandardFormatPattern(String /*char*/ patternCharacter, TimeMachineFormatInfo formatInfo) {
    switch (patternCharacter) {
      case 't':
        return formatInfo.dateTimeFormat.shortTimePattern;
      case 'T':
        return formatInfo.dateTimeFormat.longTimePattern;
      case 'r':
        return 'HH:mm:ss.FFFFFFFFF';
      default:
        // Will be turned into an exception.
        return null;
    }
  }
}

/// Bucket to put parsed values in, ready for later result calculation. This type is also used
/// by LocalDateTimePattern to store and calculate values.
@internal
class LocalTimeParseBucket extends ParseBucket<LocalTime> {
  final LocalTime templateValue;

  /// The fractions of a second in nanoseconds, in the range [0, 999999999]
  int fractionalSeconds = 0;

  /// The hours in the range [0, 23].
  int hours24 = 0;

  /// The hours in the range [1, 12].
  int hours12 = 0;

  /// The minutes in the range [0, 59].
  int minutes = 0;

  /// The seconds in the range [0, 59].
  int seconds = 0;

  /// AM (0) or PM (1) - or 'take from the template' (2). The latter is used in situations
  /// where we're parsing but there is no AM or PM designator.
  int amPm = 0;

  LocalTimeParseBucket(this.templateValue);

  /// Calculates the value from the parsed pieces.
  @override
  ParseResult<LocalTime> calculateValue(PatternFields usedFields, String text) {
    if (usedFields.hasAny(PatternFields.embeddedTime)) {
      return ParseResult.forValue<LocalTime>(LocalTime(hours24, minutes, seconds, ns:fractionalSeconds));
    }
    if (amPm == 2) {
      amPm = templateValue.hourOfDay ~/ 12;
    }
    var parseResult = _determineHour(usedFields, text);
    if (!parseResult.success) {
      return parseResult.convertError();
    }
    int hour = parseResult.value;
    int _minutes = usedFields.hasAny(PatternFields.minutes) ? minutes : templateValue.minuteOfHour;
    int _seconds = usedFields.hasAny(PatternFields.seconds) ? seconds : templateValue.secondOfMinute;
    int _nanoseconds = usedFields.hasAny(PatternFields.fractionalSeconds) ? fractionalSeconds : templateValue.nanosecondOfSecond;
    return ParseResult.forValue<LocalTime>(LocalTime(hour, _minutes, _seconds, ns:_nanoseconds));
  }

  //static const PatternFields hours12 = const PatternFields(1 << 1);
  //static const PatternFields amPm = const PatternFields(1 << 6);
  static const PatternFields _hours12_booleanOR_amPm = PatternFields(1 << 1 | 1 << 6);

  ParseResult<int> _determineHour(PatternFields usedFields, String text) {
    if (usedFields.hasAny(PatternFields.hours24)) {
      if (usedFields.hasAll(PatternFields.hours12 | PatternFields.hours24)) {
        if (hours12 % 12 != hours24 % 12) {
          return IParseResult.inconsistentValues<int>(text, 'H', 'h', 'LocalTime');
        }
      }
      if (usedFields.hasAny(PatternFields.amPm)) {
        if (hours24 ~/ 12 != amPm) {
          return IParseResult.inconsistentValues<int>(text, 'H', 't', 'LocalTime');
        }
      }
      return ParseResult.forValue(hours24);
    }

    // Okay, it's definitely valid - but we've still got 8 possibilities for what's been specified.
    int hour = 0;
    var x = usedFields & (PatternFields.hours12 | PatternFields.amPm);
    if (x == _hours12_booleanOR_amPm) {
      hour = (hours12 % 12) + amPm * 12;
    }
    else if (x == PatternFields.hours12) {
      hour = (hours12 % 12) + (templateValue.hourOfDay ~/ 12) * 12;
    }
    else if (x == PatternFields.amPm) {
      hour = (templateValue.hourOfDay % 12) + amPm * 12;
    }
    else {
      hour = templateValue.hourOfDay;
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

    return ParseResult.forValue(hour);
  }
}
