// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';

@internal /*sealed*/ class OffsetDateTimePatternParser implements IPatternParser<OffsetDateTime> {
  @private final OffsetDateTime templateValue;

  @private static final Map<String/*char*/, CharacterHandler<OffsetDateTime, OffsetDateTimeParseBucket>> PatternCharacterHandlers =
  // new Dictionary<char, CharacterHandler<OffsetDateTime, OffsetDateTimeParseBucket>>
  {
    '%': SteppedPatternBuilder.handlePercent /**<OffsetDateTime, OffsetDateTimeParseBucket>*/,
    '\'': SteppedPatternBuilder.HandleQuote /**<OffsetDateTime, OffsetDateTimeParseBucket>*/,
    '\"': SteppedPatternBuilder.HandleQuote /**<OffsetDateTime, OffsetDateTimeParseBucket>*/,
    '\\': SteppedPatternBuilder.HandleBackslash /**<OffsetDateTime, OffsetDateTimeParseBucket>*/,
    '/': (pattern, builder) => builder.addLiteral1(builder.formatInfo.dateSeparator, ParseResult.DateSeparatorMismatch /**<OffsetDateTime>*/),
    'T': (pattern, builder) => builder.addLiteral2('T', ParseResult.MismatchedCharacter /**<OffsetDateTime>*/),
    'y': DatePatternHelper.createYearOfEraHandler<OffsetDateTime, OffsetDateTimeParseBucket>((value) => value.yearOfEra, (bucket, value) =>
    bucket.Date.YearOfEra = value),
    'u': SteppedPatternBuilder.handlePaddedField<OffsetDateTime, OffsetDateTimeParseBucket>(
        4, PatternFields.year, -9999, 9999, (value) => value.year, (bucket, value) => bucket.Date.Year = value),
    'M': DatePatternHelper.createMonthOfYearHandler<OffsetDateTime, OffsetDateTimeParseBucket>((value) => value.month, (bucket, value) =>
    bucket.Date.MonthOfYearText = value, (bucket, value) => bucket.Date.MonthOfYearNumeric = value),
    'd': DatePatternHelper.createDayHandler<OffsetDateTime, OffsetDateTimeParseBucket>((value) => value.day, (value) => value.dayOfWeek.value, (bucket,
        value) => bucket.Date.DayOfMonth = value, (bucket, value) => bucket.Date.DayOfWeek = value),
    '.': TimePatternHelper.createPeriodHandler<OffsetDateTime, OffsetDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.Time.FractionalSeconds = value),
    ';': TimePatternHelper.createCommaDotHandler<OffsetDateTime, OffsetDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.Time.FractionalSeconds = value),
    ':': (pattern, builder) => builder.addLiteral1(builder.formatInfo.timeSeparator, ParseResult.TimeSeparatorMismatch /**<OffsetDateTime>*/),
    'h': SteppedPatternBuilder.handlePaddedField<OffsetDateTime, OffsetDateTimeParseBucket>(
        2, PatternFields.hours12, 1, 12, (value) => value.clockHourOfHalfDay, (bucket, value) => bucket.Time.Hours12 = value),
    'H': SteppedPatternBuilder.handlePaddedField<OffsetDateTime, OffsetDateTimeParseBucket>(
        2, PatternFields.hours24, 0, 24, (value) => value.hour, (bucket, value) => bucket.Time.Hours24 = value),
    'm': SteppedPatternBuilder.handlePaddedField<OffsetDateTime, OffsetDateTimeParseBucket>(
        2, PatternFields.minutes, 0, 59, (value) => value.minute, (bucket, value) => bucket.Time.Minutes = value),
    's': SteppedPatternBuilder.handlePaddedField<OffsetDateTime, OffsetDateTimeParseBucket>(
        2, PatternFields.seconds, 0, 59, (value) => value.second, (bucket, value) => bucket.Time.Seconds = value),
    'f': TimePatternHelper.createFractionHandler<OffsetDateTime, OffsetDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.Time.FractionalSeconds = value),
    'F': TimePatternHelper.createFractionHandler<OffsetDateTime, OffsetDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.Time.FractionalSeconds = value),
    't': TimePatternHelper.createAmPmHandler<OffsetDateTime, OffsetDateTimeParseBucket>((time) => time.hour, (bucket, value) => bucket.Time.AmPm = value),
    'c': DatePatternHelper.createCalendarHandler<OffsetDateTime, OffsetDateTimeParseBucket>((value) => value.localDateTime.calendar, (bucket, value) =>
    bucket.Date.Calendar = value),
    'g': DatePatternHelper.createEraHandler<OffsetDateTime, OffsetDateTimeParseBucket>((value) => value.era, (bucket) => bucket.Date),
    'o': HandleOffset,
    'l': (cursor, builder) =>
        builder.addEmbeddedLocalPartial(
            cursor, (bucket) => bucket.Date, (bucket) => bucket.Time, (value) => value.date, (value) => value.timeOfDay, (value) => value.localDateTime)
  };

  @internal OffsetDateTimePatternParser(this.templateValue);

  // Note: public to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  IPattern<OffsetDateTime> parsePattern(String patternText, TimeMachineFormatInfo formatInfo) {
    // Nullity check is performed in OffsetDateTimePattern.
    if (patternText.length == 0) {
      throw new InvalidPatternError(TextErrorMessages.FormatStringEmpty);
    }

    // Handle standard patterns
    if (patternText.length == 1) {
      switch (patternText[0]) {
        case 'G':
          return OffsetDateTimePatterns.GeneralIsoPatternImpl;
        case 'o':
          return OffsetDateTimePatterns.ExtendedIsoPatternImpl;
        case 'r':
          return OffsetDateTimePatterns.FullRoundtripPatternImpl;
        default:
          throw new InvalidPatternError.format(TextErrorMessages.UnknownStandardFormat, [patternText[0], 'OffsetDateTime']);
      }
    }

    var patternBuilder = new SteppedPatternBuilder<OffsetDateTime, OffsetDateTimeParseBucket>(formatInfo, () => new OffsetDateTimeParseBucket(templateValue));
    patternBuilder.parseCustomPattern(patternText, PatternCharacterHandlers);
    patternBuilder.validateUsedFields();
    // Need to reconstruct the template value from the bits...
    return patternBuilder.build(templateValue);
  }

  @private static void HandleOffset(PatternCursor pattern,
      SteppedPatternBuilder<OffsetDateTime, OffsetDateTimeParseBucket> builder) {
    builder.addField(PatternFields.embeddedOffset, pattern.Current);
    String embeddedPattern = pattern.getEmbeddedPattern();
    var offsetPattern = OffsetPattern
        .Create(embeddedPattern, builder.formatInfo)
        .UnderlyingPattern;
    builder.addEmbeddedPattern(offsetPattern, (bucket, offset) => bucket.offset = offset, (zdt) => zdt.offset);
  }
}

@private /*sealed*/ class OffsetDateTimeParseBucket extends ParseBucket<OffsetDateTime> {
  @internal final /*LocalDatePatternParser.*/LocalDateParseBucket Date;
  @internal final /*LocalTimePatternParser.*/LocalTimeParseBucket Time;
  @internal Offset offset;

  @internal OffsetDateTimeParseBucket(OffsetDateTime templateValue)
      : Date = new /*LocalDatePatternParser.*/LocalDateParseBucket(templateValue.date),
        Time = new /*LocalTimePatternParser.*/LocalTimeParseBucket(templateValue.timeOfDay),
        offset = templateValue.offset;


  @internal
  @override
  ParseResult<OffsetDateTime> CalculateValue(PatternFields usedFields, String text) {
    var localResult = /*LocalDateTimePatternParser.*/LocalDateTimeParseBucket.CombineBuckets(usedFields, Date, Time, text);
    if (!localResult.Success) {
      return localResult.ConvertError<OffsetDateTime>();
    }

    var localDateTime = localResult.Value;
    return ParseResult.ForValue<OffsetDateTime>(localDateTime.withOffset(offset));
  }
}


