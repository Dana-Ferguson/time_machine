// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';

@internal /*sealed*/ class OffsetTimePatternParser implements IPatternParser<OffsetTime> {
  final OffsetTime _templateValue;

  static final Map<String/*char*/, CharacterHandler<OffsetTime, _OffsetTimeParseBucket>> _patternCharacterHandlers =
  {
    '%': SteppedPatternBuilder.handlePercent /**<OffsetTime, OffsetTimeParseBucket>*/,
    '\'': SteppedPatternBuilder.handleQuote /**<OffsetTime, OffsetTimeParseBucket>*/,
    '\"': SteppedPatternBuilder.handleQuote /**<OffsetTime, OffsetTimeParseBucket>*/,
    '\\': SteppedPatternBuilder.handleBackslash /**<OffsetTime, OffsetTimeParseBucket>*/,
    '.': TimePatternHelper.createPeriodHandler<OffsetTime, _OffsetTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.time.fractionalSeconds = value),
    ';': TimePatternHelper.createCommaDotHandler<OffsetTime, _OffsetTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.time.fractionalSeconds = value),
    ':': (pattern, builder) => builder.addLiteral1(builder.formatInfo.timeSeparator, IParseResult.timeSeparatorMismatch /**<OffsetTime>*/),
    'h': SteppedPatternBuilder.handlePaddedField<OffsetTime, _OffsetTimeParseBucket>(
        2, PatternFields.hours12, 1, 12, (value) => value.clockHourOfHalfDay, (bucket, value) => bucket.time.hours12 = value),
    'H': SteppedPatternBuilder.handlePaddedField<OffsetTime, _OffsetTimeParseBucket>(
        2, PatternFields.hours24, 0, 24, (value) => value.hour, (bucket, value) => bucket.time.hours24 = value),
    'm': SteppedPatternBuilder.handlePaddedField<OffsetTime, _OffsetTimeParseBucket>(
        2, PatternFields.minutes, 0, 59, (value) => value.minute, (bucket, value) => bucket.time.minutes = value),
    's': SteppedPatternBuilder.handlePaddedField<OffsetTime, _OffsetTimeParseBucket>(
        2, PatternFields.seconds, 0, 59, (value) => value.second, (bucket, value) => bucket.time.seconds = value),
    'f': TimePatternHelper.createFractionHandler<OffsetTime, _OffsetTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.time.fractionalSeconds = value),
    'F': TimePatternHelper.createFractionHandler<OffsetTime, _OffsetTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.time.fractionalSeconds = value),
    't': TimePatternHelper.createAmPmHandler<OffsetTime, _OffsetTimeParseBucket>((time) => time.hour, (bucket, value) => bucket.time.amPm = value),
    'o': _handleOffset,
    'l': (cursor, builder) => builder.addEmbeddedTimePattern(cursor.current, cursor.getEmbeddedPattern(), (bucket) => bucket.time, (value) => value.timeOfDay),
  };

  @internal OffsetTimePatternParser(this._templateValue);

  // Note: to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  IPattern<OffsetTime> parsePattern(String patternText, TimeMachineFormatInfo formatInfo) {
    // Nullity check is performed in OffsetTimePattern.
    if (patternText.length == 0) {
      throw new InvalidPatternError(TextErrorMessages.formatStringEmpty);
    }

    // Handle standard patterns
    if (patternText.length == 1) {
      switch (patternText[0]) {
        case 'G':
          return OffsetTimePatterns.generalIsoPatternImpl;
        case 'o':
          return OffsetTimePatterns.extendedIsoPatternImpl;
        default:
          throw IInvalidPatternError.format(TextErrorMessages.unknownStandardFormat, [patternText[0], 'OffsetTime']);
      }
    }

    var patternBuilder = new SteppedPatternBuilder<OffsetTime, _OffsetTimeParseBucket>(formatInfo, () => new _OffsetTimeParseBucket(_templateValue));
    patternBuilder.parseCustomPattern(patternText, _patternCharacterHandlers);
    patternBuilder.validateUsedFields();
    // Need to reconstruct the template value from the bits...
    return patternBuilder.build(_templateValue);
  }

  static void _handleOffset(PatternCursor pattern,
      SteppedPatternBuilder<OffsetTime, _OffsetTimeParseBucket> builder) {
    builder.addField(PatternFields.embeddedOffset, pattern.current);
    String embeddedPattern = pattern.getEmbeddedPattern();
    var offsetPattern = OffsetPattern
        .create(embeddedPattern, builder.formatInfo)
        .underlyingPattern;
    builder.addEmbeddedPattern(offsetPattern, (bucket, offset) => bucket.offset = offset, (zdt) => zdt.offset);
  }
}

class _OffsetTimeParseBucket extends ParseBucket<OffsetTime> {
  @internal final /*LocalTimePatternParser.*/LocalTimeParseBucket time;
  @internal Offset offset;

  @internal _OffsetTimeParseBucket(OffsetTime templateValue)
      :time = new /*LocalTimePatternParser.*/LocalTimeParseBucket(templateValue.timeOfDay),
        offset = templateValue.offset;


  @internal
  @override
  ParseResult<OffsetTime> calculateValue(PatternFields usedFields, String text) {
    ParseResult<LocalTime> timeResult = time.calculateValue(usedFields & PatternFields.allTimeFields, text);
    if (!timeResult.success) {
      return timeResult.convertError<OffsetTime>();
    }
    LocalTime date = timeResult.value;
    return ParseResult.forValue<OffsetTime>(date.withOffset(offset));
  }
}

