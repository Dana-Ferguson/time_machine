// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/text/patterns/time_machine_patterns.dart';

@internal
class OffsetDateTimePatternParser implements IPatternParser<OffsetDateTime> {
  final OffsetDateTime _templateValue;

  static final Map<String/*char*/, CharacterHandler<OffsetDateTime, _OffsetDateTimeParseBucket>> _patternCharacterHandlers =
  // new Dictionary<char, CharacterHandler<OffsetDateTime, OffsetDateTimeParseBucket>>
  {
    '%': SteppedPatternBuilder.handlePercent /**<OffsetDateTime, OffsetDateTimeParseBucket>*/,
    '\'': SteppedPatternBuilder.handleQuote /**<OffsetDateTime, OffsetDateTimeParseBucket>*/,
    '\"': SteppedPatternBuilder.handleQuote /**<OffsetDateTime, OffsetDateTimeParseBucket>*/,
    '\\': SteppedPatternBuilder.handleBackslash /**<OffsetDateTime, OffsetDateTimeParseBucket>*/,
    '/': (pattern, builder) => builder.addLiteral1(builder.formatInfo.dateSeparator, IParseResult.dateSeparatorMismatch /**<OffsetDateTime>*/),
    'T': (pattern, builder) => builder.addLiteral2('T', IParseResult.mismatchedCharacter /**<OffsetDateTime>*/),
    'y': DatePatternHelper.createYearOfEraHandler<OffsetDateTime, _OffsetDateTimeParseBucket>((value) => value.yearOfEra, (bucket, value) =>
    bucket.date.yearOfEra = value),
    'u': SteppedPatternBuilder.handlePaddedField<OffsetDateTime, _OffsetDateTimeParseBucket>(
        4, PatternFields.year, -9999, 9999, (value) => value.year, (bucket, value) => bucket.date.year = value),
    'M': DatePatternHelper.createMonthOfYearHandler<OffsetDateTime, _OffsetDateTimeParseBucket>((value) => value.monthOfYear, (bucket, value) =>
    bucket.date.monthOfYearText = value, (bucket, value) => bucket.date.monthOfYearNumeric = value),
    'd': DatePatternHelper.createDayHandler<OffsetDateTime, _OffsetDateTimeParseBucket>((value) => value.dayOfMonth, (value) => value.dayOfWeek.value, (bucket,
        value) => bucket.date.dayOfMonth = value, (bucket, value) => bucket.date.dayOfWeek = value),
    '.': TimePatternHelper.createPeriodHandler<OffsetDateTime, _OffsetDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.time.fractionalSeconds = value),
    ';': TimePatternHelper.createCommaDotHandler<OffsetDateTime, _OffsetDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.time.fractionalSeconds = value),
    ':': (pattern, builder) => builder.addLiteral1(builder.formatInfo.timeSeparator, IParseResult.timeSeparatorMismatch /**<OffsetDateTime>*/),
    'h': SteppedPatternBuilder.handlePaddedField<OffsetDateTime, _OffsetDateTimeParseBucket>(
        2, PatternFields.hours12, 1, 12, (value) => value.hourOf12HourClock, (bucket, value) => bucket.time.hours12 = value),
    'H': SteppedPatternBuilder.handlePaddedField<OffsetDateTime, _OffsetDateTimeParseBucket>(
        2, PatternFields.hours24, 0, 24, (value) => value.hourOfDay, (bucket, value) => bucket.time.hours24 = value),
    'm': SteppedPatternBuilder.handlePaddedField<OffsetDateTime, _OffsetDateTimeParseBucket>(
        2, PatternFields.minutes, 0, 59, (value) => value.minuteOfHour, (bucket, value) => bucket.time.minutes = value),
    's': SteppedPatternBuilder.handlePaddedField<OffsetDateTime, _OffsetDateTimeParseBucket>(
        2, PatternFields.seconds, 0, 59, (value) => value.secondOfMinute, (bucket, value) => bucket.time.seconds = value),
    'f': TimePatternHelper.createFractionHandler<OffsetDateTime, _OffsetDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.time.fractionalSeconds = value),
    'F': TimePatternHelper.createFractionHandler<OffsetDateTime, _OffsetDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.time.fractionalSeconds = value),
    't': TimePatternHelper.createAmPmHandler<OffsetDateTime, _OffsetDateTimeParseBucket>((time) => time.hourOfDay, (bucket, value) => bucket.time.amPm = value),
    'c': DatePatternHelper.createCalendarHandler<OffsetDateTime, _OffsetDateTimeParseBucket>((value) => value.localDateTime.calendar, (bucket, value) =>
    bucket.date.calendar = value),
    'g': DatePatternHelper.createEraHandler<OffsetDateTime, _OffsetDateTimeParseBucket>((value) => value.era, (bucket) => bucket.date),
    'o': _handleOffset,
    'l': (cursor, builder) =>
        builder.addEmbeddedLocalPartial(
            cursor, (bucket) => bucket.date, (bucket) => bucket.time, (value) => value.calendarDate, (value) => value.clockTime, (value) => value.localDateTime)
  };

  OffsetDateTimePatternParser(this._templateValue);

  // Note: public to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  @override
  IPattern<OffsetDateTime> parsePattern(String patternText, TimeMachineFormatInfo formatInfo) {
    // Nullity check is performed in OffsetDateTimePattern.
    if (patternText.isEmpty) {
      throw InvalidPatternError(TextErrorMessages.formatStringEmpty);
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
          throw IInvalidPatternError.format(TextErrorMessages.unknownStandardFormat, [patternText[0], 'OffsetDateTime']);
      }
    }

    var patternBuilder = SteppedPatternBuilder<OffsetDateTime, _OffsetDateTimeParseBucket>(formatInfo, () => _OffsetDateTimeParseBucket(_templateValue));
    patternBuilder.parseCustomPattern(patternText, _patternCharacterHandlers);
    patternBuilder.validateUsedFields();
    // Need to reconstruct the template value from the bits...
    return patternBuilder.build(_templateValue);
  }

  static void _handleOffset(PatternCursor pattern, SteppedPatternBuilder<OffsetDateTime, _OffsetDateTimeParseBucket> builder) {
    builder.addField(PatternFields.embeddedOffset, pattern.current);
    String embeddedPattern = pattern.getEmbeddedPattern();
    var offsetPattern = OffsetPatterns.underlyingPattern(OffsetPatterns.create(embeddedPattern, builder.formatInfo));
    builder.addEmbeddedPattern<Offset>(offsetPattern, (bucket, offset) => bucket.offset = offset, (zdt) => zdt.offset);
  }
}

class _OffsetDateTimeParseBucket extends ParseBucket<OffsetDateTime> {
  final /*LocalDatePatternParser.*/LocalDateParseBucket date;
  final /*LocalTimePatternParser.*/LocalTimeParseBucket time;
  Offset offset;

  _OffsetDateTimeParseBucket(OffsetDateTime templateValue)
      : date = /*LocalDatePatternParser.*/LocalDateParseBucket(templateValue.calendarDate),
        time = /*LocalTimePatternParser.*/LocalTimeParseBucket(templateValue.clockTime),
        offset = templateValue.offset;


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


