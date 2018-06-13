// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';

@internal /*sealed*/ class OffsetDateTimePatternParser implements IPatternParser<OffsetDateTime> {
  final OffsetDateTime _templateValue;

  static final Map<String/*char*/, CharacterHandler<OffsetDateTime, _OffsetDateTimeParseBucket>> _patternCharacterHandlers =
  // new Dictionary<char, CharacterHandler<OffsetDateTime, OffsetDateTimeParseBucket>>
  {
    '%': SteppedPatternBuilder.handlePercent /**<OffsetDateTime, OffsetDateTimeParseBucket>*/,
    '\'': SteppedPatternBuilder.handleQuote /**<OffsetDateTime, OffsetDateTimeParseBucket>*/,
    '\"': SteppedPatternBuilder.handleQuote /**<OffsetDateTime, OffsetDateTimeParseBucket>*/,
    '\\': SteppedPatternBuilder.handleBackslash /**<OffsetDateTime, OffsetDateTimeParseBucket>*/,
    '/': (pattern, builder) => builder.addLiteral1(builder.formatInfo.dateSeparator, ParseResult.dateSeparatorMismatch /**<OffsetDateTime>*/),
    'T': (pattern, builder) => builder.addLiteral2('T', ParseResult.mismatchedCharacter /**<OffsetDateTime>*/),
    'y': DatePatternHelper.createYearOfEraHandler<OffsetDateTime, _OffsetDateTimeParseBucket>((value) => value.yearOfEra, (bucket, value) =>
    bucket.date.yearOfEra = value),
    'u': SteppedPatternBuilder.handlePaddedField<OffsetDateTime, _OffsetDateTimeParseBucket>(
        4, PatternFields.year, -9999, 9999, (value) => value.year, (bucket, value) => bucket.date.year = value),
    'M': DatePatternHelper.createMonthOfYearHandler<OffsetDateTime, _OffsetDateTimeParseBucket>((value) => value.month, (bucket, value) =>
    bucket.date.monthOfYearText = value, (bucket, value) => bucket.date.monthOfYearNumeric = value),
    'd': DatePatternHelper.createDayHandler<OffsetDateTime, _OffsetDateTimeParseBucket>((value) => value.day, (value) => value.dayOfWeek.value, (bucket,
        value) => bucket.date.dayOfMonth = value, (bucket, value) => bucket.date.dayOfWeek = value),
    '.': TimePatternHelper.createPeriodHandler<OffsetDateTime, _OffsetDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.time.fractionalSeconds = value),
    ';': TimePatternHelper.createCommaDotHandler<OffsetDateTime, _OffsetDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.time.fractionalSeconds = value),
    ':': (pattern, builder) => builder.addLiteral1(builder.formatInfo.timeSeparator, ParseResult.timeSeparatorMismatch /**<OffsetDateTime>*/),
    'h': SteppedPatternBuilder.handlePaddedField<OffsetDateTime, _OffsetDateTimeParseBucket>(
        2, PatternFields.hours12, 1, 12, (value) => value.clockHourOfHalfDay, (bucket, value) => bucket.time.hours12 = value),
    'H': SteppedPatternBuilder.handlePaddedField<OffsetDateTime, _OffsetDateTimeParseBucket>(
        2, PatternFields.hours24, 0, 24, (value) => value.hour, (bucket, value) => bucket.time.hours24 = value),
    'm': SteppedPatternBuilder.handlePaddedField<OffsetDateTime, _OffsetDateTimeParseBucket>(
        2, PatternFields.minutes, 0, 59, (value) => value.minute, (bucket, value) => bucket.time.minutes = value),
    's': SteppedPatternBuilder.handlePaddedField<OffsetDateTime, _OffsetDateTimeParseBucket>(
        2, PatternFields.seconds, 0, 59, (value) => value.second, (bucket, value) => bucket.time.seconds = value),
    'f': TimePatternHelper.createFractionHandler<OffsetDateTime, _OffsetDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.time.fractionalSeconds = value),
    'F': TimePatternHelper.createFractionHandler<OffsetDateTime, _OffsetDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.time.fractionalSeconds = value),
    't': TimePatternHelper.createAmPmHandler<OffsetDateTime, _OffsetDateTimeParseBucket>((time) => time.hour, (bucket, value) => bucket.time.amPm = value),
    'c': DatePatternHelper.createCalendarHandler<OffsetDateTime, _OffsetDateTimeParseBucket>((value) => value.localDateTime.calendar, (bucket, value) =>
    bucket.date.calendar = value),
    'g': DatePatternHelper.createEraHandler<OffsetDateTime, _OffsetDateTimeParseBucket>((value) => value.era, (bucket) => bucket.date),
    'o': _handleOffset,
    'l': (cursor, builder) =>
        builder.addEmbeddedLocalPartial(
            cursor, (bucket) => bucket.date, (bucket) => bucket.time, (value) => value.date, (value) => value.timeOfDay, (value) => value.localDateTime)
  };

  @internal OffsetDateTimePatternParser(this._templateValue);

  // Note: public to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  IPattern<OffsetDateTime> parsePattern(String patternText, TimeMachineFormatInfo formatInfo) {
    // Nullity check is performed in OffsetDateTimePattern.
    if (patternText.length == 0) {
      throw new InvalidPatternError(TextErrorMessages.formatStringEmpty);
    }

    // Handle standard patterns
    if (patternText.length == 1) {
      switch (patternText[0]) {
        case 'G':
          return OffsetDateTimePatterns.generalIsoPatternImpl;
        case 'o':
          return OffsetDateTimePatterns.extendedIsoPatternImpl;
        case 'r':
          return OffsetDateTimePatterns.fullRoundtripPatternImpl;
        default:
          throw new InvalidPatternError.format(TextErrorMessages.unknownStandardFormat, [patternText[0], 'OffsetDateTime']);
      }
    }

    var patternBuilder = new SteppedPatternBuilder<OffsetDateTime, _OffsetDateTimeParseBucket>(formatInfo, () => new _OffsetDateTimeParseBucket(_templateValue));
    patternBuilder.parseCustomPattern(patternText, _patternCharacterHandlers);
    patternBuilder.validateUsedFields();
    // Need to reconstruct the template value from the bits...
    return patternBuilder.build(_templateValue);
  }

  static void _handleOffset(PatternCursor pattern, SteppedPatternBuilder<OffsetDateTime, _OffsetDateTimeParseBucket> builder) {
    builder.addField(PatternFields.embeddedOffset, pattern.current);
    String embeddedPattern = pattern.getEmbeddedPattern();
    var offsetPattern = OffsetPattern
        .create(embeddedPattern, builder.formatInfo)
        .underlyingPattern;
    builder.addEmbeddedPattern(offsetPattern, (bucket, offset) => bucket.offset = offset, (zdt) => zdt.offset);
  }
}

class _OffsetDateTimeParseBucket extends ParseBucket<OffsetDateTime> {
  @internal final /*LocalDatePatternParser.*/LocalDateParseBucket date;
  @internal final /*LocalTimePatternParser.*/LocalTimeParseBucket time;
  @internal Offset offset;

  @internal _OffsetDateTimeParseBucket(OffsetDateTime templateValue)
      : date = new /*LocalDatePatternParser.*/LocalDateParseBucket(templateValue.date),
        time = new /*LocalTimePatternParser.*/LocalTimeParseBucket(templateValue.timeOfDay),
        offset = templateValue.offset;


  @internal
  @override
  ParseResult<OffsetDateTime> calculateValue(PatternFields usedFields, String text) {
    var localResult = /*LocalDateTimePatternParser.*/LocalDateTimeParseBucket.combineBuckets(usedFields, date, time, text);
    if (!localResult.success) {
      return localResult.convertError<OffsetDateTime>();
    }

    var localDateTime = localResult.value;
    return ParseResult.forValue<OffsetDateTime>(localDateTime.withOffset(offset));
  }
}


