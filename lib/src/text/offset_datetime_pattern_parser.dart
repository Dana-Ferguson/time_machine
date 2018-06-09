// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';

@internal /*sealed*/ class OffsetDateTimePatternParser implements IPatternParser<OffsetDateTime> {
  @private final OffsetDateTime templateValue;

  @private static final Map<String/*char*/, CharacterHandler<OffsetDateTime, OffsetDateTimeParseBucket>> PatternCharacterHandlers =
  // new Dictionary<char, CharacterHandler<OffsetDateTime, OffsetDateTimeParseBucket>>
  {
    '%': SteppedPatternBuilder.HandlePercent /**<OffsetDateTime, OffsetDateTimeParseBucket>*/,
    '\'': SteppedPatternBuilder.HandleQuote /**<OffsetDateTime, OffsetDateTimeParseBucket>*/,
    '\"': SteppedPatternBuilder.HandleQuote /**<OffsetDateTime, OffsetDateTimeParseBucket>*/,
    '\\': SteppedPatternBuilder.HandleBackslash /**<OffsetDateTime, OffsetDateTimeParseBucket>*/,
    '/': (pattern, builder) => builder.AddLiteral1(builder.FormatInfo.DateSeparator, ParseResult.DateSeparatorMismatch /**<OffsetDateTime>*/),
    'T': (pattern, builder) => builder.AddLiteral2('T', ParseResult.MismatchedCharacter /**<OffsetDateTime>*/),
    'y': DatePatternHelper.CreateYearOfEraHandler<OffsetDateTime, OffsetDateTimeParseBucket>((value) => value.YearOfEra, (bucket, value) =>
    bucket.Date.YearOfEra = value),
    'u': SteppedPatternBuilder.HandlePaddedField<OffsetDateTime, OffsetDateTimeParseBucket>(
        4, PatternFields.year, -9999, 9999, (value) => value.Year, (bucket, value) => bucket.Date.Year = value),
    'M': DatePatternHelper.CreateMonthOfYearHandler<OffsetDateTime, OffsetDateTimeParseBucket>((value) => value.Month, (bucket, value) =>
    bucket.Date.MonthOfYearText = value, (bucket, value) => bucket.Date.MonthOfYearNumeric = value),
    'd': DatePatternHelper.CreateDayHandler<OffsetDateTime, OffsetDateTimeParseBucket>((value) => value.Day, (value) => value.DayOfWeek.value, (bucket,
        value) => bucket.Date.DayOfMonth = value, (bucket, value) => bucket.Date.DayOfWeek = value),
    '.': TimePatternHelper.CreatePeriodHandler<OffsetDateTime, OffsetDateTimeParseBucket>(
        9, (value) => value.NanosecondOfSecond, (bucket, value) => bucket.Time.FractionalSeconds = value),
    ';': TimePatternHelper.CreateCommaDotHandler<OffsetDateTime, OffsetDateTimeParseBucket>(
        9, (value) => value.NanosecondOfSecond, (bucket, value) => bucket.Time.FractionalSeconds = value),
    ':': (pattern, builder) => builder.AddLiteral1(builder.FormatInfo.TimeSeparator, ParseResult.TimeSeparatorMismatch /**<OffsetDateTime>*/),
    'h': SteppedPatternBuilder.HandlePaddedField<OffsetDateTime, OffsetDateTimeParseBucket>(
        2, PatternFields.hours12, 1, 12, (value) => value.ClockHourOfHalfDay, (bucket, value) => bucket.Time.Hours12 = value),
    'H': SteppedPatternBuilder.HandlePaddedField<OffsetDateTime, OffsetDateTimeParseBucket>(
        2, PatternFields.hours24, 0, 24, (value) => value.Hour, (bucket, value) => bucket.Time.Hours24 = value),
    'm': SteppedPatternBuilder.HandlePaddedField<OffsetDateTime, OffsetDateTimeParseBucket>(
        2, PatternFields.minutes, 0, 59, (value) => value.Minute, (bucket, value) => bucket.Time.Minutes = value),
    's': SteppedPatternBuilder.HandlePaddedField<OffsetDateTime, OffsetDateTimeParseBucket>(
        2, PatternFields.seconds, 0, 59, (value) => value.Second, (bucket, value) => bucket.Time.Seconds = value),
    'f': TimePatternHelper.CreateFractionHandler<OffsetDateTime, OffsetDateTimeParseBucket>(
        9, (value) => value.NanosecondOfSecond, (bucket, value) => bucket.Time.FractionalSeconds = value),
    'F': TimePatternHelper.CreateFractionHandler<OffsetDateTime, OffsetDateTimeParseBucket>(
        9, (value) => value.NanosecondOfSecond, (bucket, value) => bucket.Time.FractionalSeconds = value),
    't': TimePatternHelper.CreateAmPmHandler<OffsetDateTime, OffsetDateTimeParseBucket>((time) => time.Hour, (bucket, value) => bucket.Time.AmPm = value),
    'c': DatePatternHelper.CreateCalendarHandler<OffsetDateTime, OffsetDateTimeParseBucket>((value) => value.localDateTime.Calendar, (bucket, value) =>
    bucket.Date.Calendar = value),
    'g': DatePatternHelper.CreateEraHandler<OffsetDateTime, OffsetDateTimeParseBucket>((value) => value.era, (bucket) => bucket.Date),
    'o': HandleOffset,
    'l': (cursor, builder) =>
        builder.AddEmbeddedLocalPartial(
            cursor, (bucket) => bucket.Date, (bucket) => bucket.Time, (value) => value.Date, (value) => value.TimeOfDay, (value) => value.localDateTime)
  };

  @internal OffsetDateTimePatternParser(this.templateValue);

  // Note: public to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  IPattern<OffsetDateTime> ParsePattern(String patternText, NodaFormatInfo formatInfo) {
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
    patternBuilder.ParseCustomPattern(patternText, PatternCharacterHandlers);
    patternBuilder.ValidateUsedFields();
    // Need to reconstruct the template value from the bits...
    return patternBuilder.Build(templateValue);
  }

  @private static void HandleOffset(PatternCursor pattern,
      SteppedPatternBuilder<OffsetDateTime, OffsetDateTimeParseBucket> builder) {
    builder.AddField(PatternFields.embeddedOffset, pattern.Current);
    String embeddedPattern = pattern.GetEmbeddedPattern();
    var offsetPattern = OffsetPattern
        .Create(embeddedPattern, builder.FormatInfo)
        .UnderlyingPattern;
    builder.AddEmbeddedPattern(offsetPattern, (bucket, offset) => bucket.offset = offset, (zdt) => zdt.offset);
  }
}

@private /*sealed*/ class OffsetDateTimeParseBucket extends ParseBucket<OffsetDateTime> {
  @internal final /*LocalDatePatternParser.*/LocalDateParseBucket Date;
  @internal final /*LocalTimePatternParser.*/LocalTimeParseBucket Time;
  @internal Offset offset;

  @internal OffsetDateTimeParseBucket(OffsetDateTime templateValue)
      : Date = new /*LocalDatePatternParser.*/LocalDateParseBucket(templateValue.Date),
        Time = new /*LocalTimePatternParser.*/LocalTimeParseBucket(templateValue.TimeOfDay),
        offset = templateValue.offset;


  @internal
  @override
  ParseResult<OffsetDateTime> CalculateValue(PatternFields usedFields, String text) {
    var localResult = /*LocalDateTimePatternParser.*/LocalDateTimeParseBucket.CombineBuckets(usedFields, Date, Time, text);
    if (!localResult.Success) {
      return localResult.ConvertError<OffsetDateTime>();
    }

    var localDateTime = localResult.Value;
    return ParseResult.ForValue<OffsetDateTime>(localDateTime.WithOffset(offset));
  }
}


