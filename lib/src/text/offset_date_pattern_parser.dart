// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';

@internal /*sealed*/ class OffsetDatePatternParser implements IPatternParser<OffsetDate> {
  @private final OffsetDate templateValue;

  @private static final Map<String/*char*/, CharacterHandler<OffsetDate, OffsetDateParseBucket>> PatternCharacterHandlers =
  {
    '%': SteppedPatternBuilder.HandlePercent /**<OffsetDate, OffsetDateParseBucket>*/,
    '\'': SteppedPatternBuilder.HandleQuote /**<OffsetDate, OffsetDateParseBucket>*/,
    '\"': SteppedPatternBuilder.HandleQuote /**<OffsetDate, OffsetDateParseBucket>*/,
    '\\': SteppedPatternBuilder.HandleBackslash /**<OffsetDate, OffsetDateParseBucket>*/,
    '/': (pattern, builder) => builder.AddLiteral1(builder.FormatInfo.dateSeparator, ParseResult.DateSeparatorMismatch /**<OffsetDate>*/),
    'y': DatePatternHelper.CreateYearOfEraHandler<OffsetDate, OffsetDateParseBucket>((value) => value.yearOfEra, (bucket, value) =>
    bucket.Date.YearOfEra = value),
    'u': SteppedPatternBuilder.HandlePaddedField<OffsetDate, OffsetDateParseBucket>(
        4, PatternFields.year, -9999, 9999, (value) => value.year, (bucket, value) => bucket.Date.Year = value),
    'M': DatePatternHelper.CreateMonthOfYearHandler<OffsetDate, OffsetDateParseBucket>
      ((value) => value.month, (bucket, value) => bucket.Date.MonthOfYearText = value, (bucket, value) => bucket.Date.MonthOfYearNumeric = value),
    'd': DatePatternHelper.CreateDayHandler<OffsetDate, OffsetDateParseBucket>
      ((value) => value.day, (value) => value.dayOfWeek.value, (bucket, value) => bucket.Date.DayOfMonth = value, (bucket, value) =>
    bucket.Date.DayOfWeek = value),
    'c': DatePatternHelper.CreateCalendarHandler<OffsetDate, OffsetDateParseBucket>((value) => value.date.calendar, (bucket, value) =>
    bucket.Date.Calendar = value),
    'g': DatePatternHelper.CreateEraHandler<OffsetDate, OffsetDateParseBucket>((value) => value.era, (bucket) => bucket.Date),
    'o': HandleOffset,
    'l': (cursor, builder) => builder.AddEmbeddedDatePattern(cursor.Current, cursor.GetEmbeddedPattern(), (bucket) => bucket.Date, (value) => value.date)
  };

  @internal OffsetDatePatternParser(this.templateValue);

  // Note: public to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  IPattern<OffsetDate> ParsePattern(String patternText, TimeMachineFormatInfo formatInfo) {
    // Nullity check is performed in OffsetDatePattern.
    if (patternText.length == 0) {
      throw new InvalidPatternError(TextErrorMessages.FormatStringEmpty);
    }

    // Handle standard patterns
    if (patternText.length == 1) {
      switch (patternText[0]) {
        case 'G':
          return OffsetDatePatterns.GeneralIsoPatternImpl;
        case 'r':
          return OffsetDatePatterns.FullRoundtripPatternImpl;
        default:
          throw new InvalidPatternError.format(TextErrorMessages.UnknownStandardFormat, [patternText[0], 'OffsetDate']);
      }
    }

    var patternBuilder = new SteppedPatternBuilder<OffsetDate, OffsetDateParseBucket>(formatInfo, () => new OffsetDateParseBucket(templateValue));
    patternBuilder.ParseCustomPattern(patternText, PatternCharacterHandlers);
    patternBuilder.ValidateUsedFields();
    // Need to reconstruct the template value from the bits...
    return patternBuilder.Build(templateValue);
  }

  @private static void HandleOffset(PatternCursor pattern,
      SteppedPatternBuilder<OffsetDate, OffsetDateParseBucket> builder) {
    builder.AddField(PatternFields.embeddedOffset, pattern.Current);
    String embeddedPattern = pattern.GetEmbeddedPattern();
    var offsetPattern = OffsetPattern
        .Create(embeddedPattern, builder.FormatInfo)
        .UnderlyingPattern;
    builder.AddEmbeddedPattern(offsetPattern, (bucket, offset) => bucket.offset = offset, (zdt) => zdt.offset);
  }
}

@private /*sealed*/ class OffsetDateParseBucket extends ParseBucket<OffsetDate> {
  @internal final /*LocalDatePatternParser.*/LocalDateParseBucket Date;
  @internal Offset offset;

  @internal OffsetDateParseBucket(OffsetDate templateValue)
      : Date = new /*LocalDatePatternParser.*/LocalDateParseBucket(templateValue.date),
        offset = templateValue.offset;

  @internal
  @override
  ParseResult<OffsetDate> CalculateValue(PatternFields usedFields, String text) {
    ParseResult<LocalDate> dateResult = Date.CalculateValue(usedFields & PatternFields.allDateFields, text);
    if (!dateResult.Success) {
      return dateResult.ConvertError<OffsetDate>();
    }
    LocalDate date = dateResult.Value;
    return ParseResult.ForValue<OffsetDate>(date.withOffset(offset));
  }
}

