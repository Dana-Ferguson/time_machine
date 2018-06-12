// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';


/// Parser for patterns of [LocalDateTime] values.
@internal /*sealed*/ class LocalDateTimePatternParser implements IPatternParser<LocalDateTime> {
  // Split the template value into date and time once, to avoid doing it every time we parse.
  @private final LocalDate templateValueDate;
  @private final LocalTime templateValueTime;

  @private static final Map<String /*char*/, CharacterHandler<LocalDateTime, LocalDateTimeParseBucket>> PatternCharacterHandlers =
  {
    '%': SteppedPatternBuilder.HandlePercent /**<LocalDateTime, LocalDateTimeParseBucket>*/,
    '\'': SteppedPatternBuilder.HandleQuote /**<LocalDateTime, LocalDateTimeParseBucket>*/,
    '\"': SteppedPatternBuilder.HandleQuote /**<LocalDateTime, LocalDateTimeParseBucket>*/,
    '\\': SteppedPatternBuilder.HandleBackslash /**<LocalDateTime, LocalDateTimeParseBucket>*/,
    '/': (pattern, builder) => builder.AddLiteral1(builder.FormatInfo.dateSeparator, ParseResult.DateSeparatorMismatch /**<LocalDateTime>*/),
    'T': (pattern, builder) => builder.AddLiteral2('T', ParseResult.MismatchedCharacter /**<LocalDateTime>*/),
    'y': DatePatternHelper.CreateYearOfEraHandler<LocalDateTime, LocalDateTimeParseBucket>((value) => value.yearOfEra, (bucket, value) =>
    bucket.Date.YearOfEra = value),
    'u': SteppedPatternBuilder.HandlePaddedField /**<LocalDateTime, LocalDateTimeParseBucket>*/
      (4, PatternFields.year, -9999, 9999, (value) => value.year, (bucket, value) => bucket.Date.Year = value),
    'M': DatePatternHelper.CreateMonthOfYearHandler<LocalDateTime, LocalDateTimeParseBucket>
      ((value) => value.month, (bucket, value) => bucket.Date.MonthOfYearText = value, (bucket, value) => bucket.Date.MonthOfYearNumeric = value),
    'd': DatePatternHelper.CreateDayHandler<LocalDateTime, LocalDateTimeParseBucket>
      ((value) => value.day, (value) => value.dayOfWeek.value, (bucket, value) => bucket.Date.DayOfMonth = value, (bucket, value) =>
    bucket.Date.DayOfWeek = value),
    '.': TimePatternHelper.CreatePeriodHandler<LocalDateTime, LocalDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.Time.FractionalSeconds = value),
    ';': TimePatternHelper.CreateCommaDotHandler<LocalDateTime, LocalDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.Time.FractionalSeconds = value),
    ':': (pattern, builder) => builder.AddLiteral1(builder.FormatInfo.timeSeparator, ParseResult.TimeSeparatorMismatch /**<LocalDateTime>*/),
    'h': SteppedPatternBuilder.HandlePaddedField<LocalDateTime, LocalDateTimeParseBucket>
      (2, PatternFields.hours12, 1, 12, (value) => value.clockHourOfHalfDay, (bucket, value) => bucket.Time.Hours12 = value),
    'H': SteppedPatternBuilder.HandlePaddedField<LocalDateTime, LocalDateTimeParseBucket>
      (2, PatternFields.hours24, 0, 24, (value) => value.hour, (bucket, value) => bucket.Time.Hours24 = value),
    'm': SteppedPatternBuilder.HandlePaddedField<LocalDateTime, LocalDateTimeParseBucket>
      (2, PatternFields.minutes, 0, 59, (value) => value.minute, (bucket, value) => bucket.Time.Minutes = value),
    's': SteppedPatternBuilder.HandlePaddedField<LocalDateTime, LocalDateTimeParseBucket>
      (2, PatternFields.seconds, 0, 59, (value) => value.second, (bucket, value) => bucket.Time.Seconds = value),
    'f': TimePatternHelper.CreateFractionHandler<LocalDateTime, LocalDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.Time.FractionalSeconds = value),
    'F': TimePatternHelper.CreateFractionHandler<LocalDateTime, LocalDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.Time.FractionalSeconds = value),
    't': TimePatternHelper.CreateAmPmHandler<LocalDateTime, LocalDateTimeParseBucket>((time) => time.hour, (bucket, value) => bucket.Time.AmPm = value),
    'c': DatePatternHelper.CreateCalendarHandler<LocalDateTime, LocalDateTimeParseBucket>((value) => value.calendar, (bucket, value) =>
    bucket.Date.Calendar = value),
    'g': DatePatternHelper.CreateEraHandler<LocalDateTime, LocalDateTimeParseBucket>((value) => value.era, (bucket) => bucket.Date),
    'l': (cursor, builder) =>
        builder.AddEmbeddedLocalPartial(cursor, (bucket) => bucket.Date, (bucket) => bucket.Time, (value) => value.date, (value) => value.time, null),
  };

  @internal LocalDateTimePatternParser(LocalDateTime templateValue)
      : templateValueDate = templateValue.date,
        templateValueTime = templateValue.time;

  // Note: to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  IPattern<LocalDateTime> ParsePattern(String patternText, TimeMachineFormatInfo formatInfo) {
    // Nullity check is performed in LocalDateTimePattern.
    if (patternText.length == 0) {
      throw new InvalidPatternError(TextErrorMessages.FormatStringEmpty);
    }

    if (patternText.length == 1) {
      String /*char*/ patternCharacter = patternText[0];
      if (patternCharacter == 'o' || patternCharacter == 'O') {
        return LocalDateTimePatterns.BclRoundtripPatternImpl;
      }
      if (patternCharacter == 'r') {
        return LocalDateTimePatterns.FullRoundtripPatternImpl;
      }
      if (patternCharacter == 'R') {
        return LocalDateTimePatterns.FullRoundtripWithoutCalendarImpl;
      }
      if (patternCharacter == 's') {
        return LocalDateTimePatterns.GeneralIsoPatternImpl;
      }
      patternText = ExpandStandardFormatPattern(patternCharacter, formatInfo);
      if (patternText == null) {
        throw new InvalidPatternError.format(TextErrorMessages.UnknownStandardFormat, [patternCharacter, 'LocalDateTime']);
      }
    }

    var patternBuilder = new SteppedPatternBuilder<LocalDateTime, LocalDateTimeParseBucket>(formatInfo,
            () => new LocalDateTimeParseBucket(templateValueDate, templateValueTime));
    patternBuilder.ParseCustomPattern(patternText, PatternCharacterHandlers);
    patternBuilder.ValidateUsedFields();
    return patternBuilder.Build(templateValueDate.at(templateValueTime));
  }

  @private String ExpandStandardFormatPattern(/*char*/ String patternCharacter, TimeMachineFormatInfo formatInfo) {
    switch (patternCharacter) {
      case 'f':
        return formatInfo.dateTimeFormat.longDatePattern + " " + formatInfo.dateTimeFormat.shortTimePattern;
      case 'F':
        return formatInfo.dateTimeFormat.fullDateTimePattern;
      case 'g':
        return formatInfo.dateTimeFormat.shortDatePattern + " " + formatInfo.dateTimeFormat.shortTimePattern;
      case 'G':
        return formatInfo.dateTimeFormat.shortDatePattern + " " + formatInfo.dateTimeFormat.longTimePattern;
      default:
        // Will be turned into an exception.
        return null;
    }
  }
}

@internal /*sealed*/ class LocalDateTimeParseBucket extends ParseBucket<LocalDateTime> {
  @internal final /*LocalDatePatternParser.*/LocalDateParseBucket Date;
  @internal final /*LocalTimePatternParser.*/LocalTimeParseBucket Time;

  @internal LocalDateTimeParseBucket(LocalDate templateValueDate, LocalTime templateValueTime)
      : Date = new /*LocalDatePatternParser.*/LocalDateParseBucket(templateValueDate),
        Time = new /*LocalTimePatternParser.*/LocalTimeParseBucket(templateValueTime);

  /// Combines the values in a date bucket with the values in a time bucket.
  ///
  /// This would normally be the [CalculateValue] method, but we want
  /// to be able to use the same logic when parsing an [OffsetDateTime]
  /// and [ZonedDateTime].
  @internal static ParseResult<LocalDateTime> CombineBuckets(PatternFields usedFields,
/*LocalDatePatternParser.*/LocalDateParseBucket dateBucket,
/*LocalTimePatternParser.*/LocalTimeParseBucket timeBucket,
      String text) {
    // Handle special case of hour = 24
    bool hour24 = false;
    if (timeBucket.Hours24 == 24) {
      timeBucket.Hours24 = 0;
      hour24 = true;
    }

    ParseResult<LocalDate> dateResult = dateBucket.CalculateValue(usedFields & PatternFields.allDateFields, text);
    if (!dateResult.Success) {
      return dateResult.ConvertError<LocalDateTime>();
    }
    ParseResult<LocalTime> timeResult = timeBucket.CalculateValue(usedFields & PatternFields.allTimeFields, text);
    if (!timeResult.Success) {
      return timeResult.ConvertError<LocalDateTime>();
    }

    LocalDate date = dateResult.Value;
    LocalTime time = timeResult.Value;

    if (hour24) {
      if (time != LocalTime.midnight) {
        return ParseResult.InvalidHour24<LocalDateTime>(text);
      }
      date = date.plusDays(1);
    }
    return ParseResult.ForValue<LocalDateTime>(date.at(time));
  }

  @internal
  @override
  ParseResult<LocalDateTime> CalculateValue(PatternFields usedFields, String text) =>
      CombineBuckets(usedFields, Date, Time, text);
}

