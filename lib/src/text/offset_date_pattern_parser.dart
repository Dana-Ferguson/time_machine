// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/text/patterns/time_machine_patterns.dart';

@internal
class OffsetDatePatternParser implements IPatternParser<OffsetDate> {
  final OffsetDate _templateValue;

  static final Map<String/*char*/, CharacterHandler<OffsetDate, _OffsetDateParseBucket>> _patternCharacterHandlers =
  {
    '%': SteppedPatternBuilder.handlePercent /**<OffsetDate, OffsetDateParseBucket>*/,
    '\'': SteppedPatternBuilder.handleQuote /**<OffsetDate, OffsetDateParseBucket>*/,
    '\"': SteppedPatternBuilder.handleQuote /**<OffsetDate, OffsetDateParseBucket>*/,
    '\\': SteppedPatternBuilder.handleBackslash /**<OffsetDate, OffsetDateParseBucket>*/,
    '/': (pattern, builder) => builder.addLiteral1(builder.formatInfo.dateSeparator, IParseResult.dateSeparatorMismatch /**<OffsetDate>*/),
    'y': DatePatternHelper.createYearOfEraHandler<OffsetDate, _OffsetDateParseBucket>((value) => value.yearOfEra, (bucket, value) =>
    bucket.date.yearOfEra = value),
    'u': SteppedPatternBuilder.handlePaddedField<OffsetDate, _OffsetDateParseBucket>(
        4, PatternFields.year, -9999, 9999, (value) => value.year, (bucket, value) => bucket.date.year = value),
    'M': DatePatternHelper.createMonthOfYearHandler<OffsetDate, _OffsetDateParseBucket>
      ((value) => value.monthOfYear, (bucket, value) => bucket.date.monthOfYearText = value, (bucket, value) => bucket.date.monthOfYearNumeric = value),
    'd': DatePatternHelper.createDayHandler<OffsetDate, _OffsetDateParseBucket>
      ((value) => value.dayOfMonth, (value) => value.dayOfWeek.value, (bucket, value) => bucket.date.dayOfMonth = value, (bucket, value) =>
    bucket.date.dayOfWeek = value),
    'c': DatePatternHelper.createCalendarHandler<OffsetDate, _OffsetDateParseBucket>((value) => value.calendarDate.calendar, (bucket, value) =>
    bucket.date.calendar = value),
    'g': DatePatternHelper.createEraHandler<OffsetDate, _OffsetDateParseBucket>((value) => value.era, (bucket) => bucket.date),
    'o': _handleOffset,
    'l': (cursor, builder) => builder.addEmbeddedDatePattern(cursor.current, cursor.getEmbeddedPattern(), (bucket) => bucket.date, (value) => value.calendarDate)
  };

  OffsetDatePatternParser(this._templateValue);

  // Note: public to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  @override
  IPattern<OffsetDate> parsePattern(String patternText, TimeMachineFormatInfo formatInfo) {
    // Nullity check is performed in OffsetDatePattern.
    if (patternText.isEmpty) {
      throw InvalidPatternError(TextErrorMessages.formatStringEmpty);
    }

    // Handle standard patterns
    if (patternText.length == 1) {
      switch (patternText[0]) {
        case 'G':
          return OffsetDatePatterns.generalIsoPatternImpl;
        case 'r':
          return OffsetDatePatterns.fullRoundtripPatternImpl;
        default:
          throw IInvalidPatternError.format(TextErrorMessages.unknownStandardFormat, [patternText[0], 'OffsetDate']);
      }
    }

    var patternBuilder = SteppedPatternBuilder<OffsetDate, _OffsetDateParseBucket>(formatInfo, () => _OffsetDateParseBucket(_templateValue));
    patternBuilder.parseCustomPattern(patternText, _patternCharacterHandlers);
    patternBuilder.validateUsedFields();
    // Need to reconstruct the template value from the bits...
    return patternBuilder.build(_templateValue);
  }

  static void _handleOffset(PatternCursor pattern,
      SteppedPatternBuilder<OffsetDate, _OffsetDateParseBucket> builder) {
    builder.addField(PatternFields.embeddedOffset, pattern.current);
    String embeddedPattern = pattern.getEmbeddedPattern();
    var offsetPattern = OffsetPatterns.underlyingPattern(OffsetPatterns.create(embeddedPattern, builder.formatInfo));
    builder.addEmbeddedPattern<Offset>(offsetPattern, (bucket, offset) => bucket.offset = offset, (zdt) => zdt.offset);
  }
}

class _OffsetDateParseBucket extends ParseBucket<OffsetDate> {
  final /*LocalDatePatternParser.*/LocalDateParseBucket date;
  Offset offset;

  _OffsetDateParseBucket(OffsetDate templateValue)
      : date = /*LocalDatePatternParser.*/LocalDateParseBucket(templateValue.calendarDate),
        offset = templateValue.offset;

  @override
  ParseResult<OffsetDate> calculateValue(PatternFields usedFields, String text) {
    ParseResult<LocalDate> dateResult = date.calculateValue(usedFields & PatternFields.allDateFields, text);
    if (!dateResult.success) {
      return dateResult.convertError<OffsetDate>();
    }
    LocalDate resultDate = dateResult.value;
    return ParseResult.forValue<OffsetDate>(resultDate.withOffset(offset));
  }
}

