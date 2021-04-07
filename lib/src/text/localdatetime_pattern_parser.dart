// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/text/patterns/time_machine_patterns.dart';

/// Parser for patterns of [LocalDateTime] values.
@internal
class LocalDateTimePatternParser implements IPatternParser<LocalDateTime> {
  // Split the template value into date and time once, to avoid doing it every time we parse.
  final LocalDate _templateValueDate;
  final LocalTime _templateValueTime;

  static final Map<String /*char*/, CharacterHandler<LocalDateTime, LocalDateTimeParseBucket>> _patternCharacterHandlers =
  {
    '%': SteppedPatternBuilder.handlePercent /**<LocalDateTime, LocalDateTimeParseBucket>*/,
    '\'': SteppedPatternBuilder.handleQuote /**<LocalDateTime, LocalDateTimeParseBucket>*/,
    '\"': SteppedPatternBuilder.handleQuote /**<LocalDateTime, LocalDateTimeParseBucket>*/,
    '\\': SteppedPatternBuilder.handleBackslash /**<LocalDateTime, LocalDateTimeParseBucket>*/,
    '/': (pattern, builder) => builder.addLiteral1(builder.formatInfo.dateSeparator, IParseResult.dateSeparatorMismatch /**<LocalDateTime>*/),
    'T': (pattern, builder) => builder.addLiteral2('T', IParseResult.mismatchedCharacter /**<LocalDateTime>*/),
    'y': DatePatternHelper.createYearOfEraHandler<LocalDateTime, LocalDateTimeParseBucket>((value) => value.yearOfEra, (bucket, value) =>
    bucket.date.yearOfEra = value),
    'u': SteppedPatternBuilder.handlePaddedField /**<LocalDateTime, LocalDateTimeParseBucket>*/
      (4, PatternFields.year, -9999, 9999, (value) => value.year, (bucket, value) => bucket.date.year = value),
    'M': DatePatternHelper.createMonthOfYearHandler<LocalDateTime, LocalDateTimeParseBucket>
      ((value) => value.monthOfYear, (bucket, value) => bucket.date.monthOfYearText = value, (bucket, value) => bucket.date.monthOfYearNumeric = value),
    'd': DatePatternHelper.createDayHandler<LocalDateTime, LocalDateTimeParseBucket>
      ((value) => value.dayOfMonth, (value) => value.dayOfWeek.value, (bucket, value) => bucket.date.dayOfMonth = value, (bucket, value) =>
    bucket.date.dayOfWeek = value),
    '.': TimePatternHelper.createPeriodHandler<LocalDateTime, LocalDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.time.fractionalSeconds = value),
    ';': TimePatternHelper.createCommaDotHandler<LocalDateTime, LocalDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.time.fractionalSeconds = value),
    ':': (pattern, builder) => builder.addLiteral1(builder.formatInfo.timeSeparator, IParseResult.timeSeparatorMismatch /**<LocalDateTime>*/),
    'h': SteppedPatternBuilder.handlePaddedField<LocalDateTime, LocalDateTimeParseBucket>
      (2, PatternFields.hours12, 1, 12, (value) => value.hourOf12HourClock, (bucket, value) => bucket.time.hours12 = value),
    'H': SteppedPatternBuilder.handlePaddedField<LocalDateTime, LocalDateTimeParseBucket>
      (2, PatternFields.hours24, 0, 24, (value) => value.hourOfDay, (bucket, value) => bucket.time.hours24 = value),
    'm': SteppedPatternBuilder.handlePaddedField<LocalDateTime, LocalDateTimeParseBucket>
      (2, PatternFields.minutes, 0, 59, (value) => value.minuteOfHour, (bucket, value) => bucket.time.minutes = value),
    's': SteppedPatternBuilder.handlePaddedField<LocalDateTime, LocalDateTimeParseBucket>
      (2, PatternFields.seconds, 0, 59, (value) => value.secondOfMinute, (bucket, value) => bucket.time.seconds = value),
    'f': TimePatternHelper.createFractionHandler<LocalDateTime, LocalDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.time.fractionalSeconds = value),
    'F': TimePatternHelper.createFractionHandler<LocalDateTime, LocalDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.time.fractionalSeconds = value),
    't': TimePatternHelper.createAmPmHandler<LocalDateTime, LocalDateTimeParseBucket>((time) => time.hourOfDay, (bucket, value) => bucket.time.amPm = value),
    'c': DatePatternHelper.createCalendarHandler<LocalDateTime, LocalDateTimeParseBucket>((value) => value.calendar, (bucket, value) =>
    bucket.date.calendar = value),
    'g': DatePatternHelper.createEraHandler<LocalDateTime, LocalDateTimeParseBucket>((value) => value.era, (bucket) => bucket.date),
    'l': (cursor, builder) =>
        builder.addEmbeddedLocalPartial(cursor, (bucket) => bucket.date, (bucket) => bucket.time, (value) => value.calendarDate, (value) => value.clockTime, null),
  };

  LocalDateTimePatternParser(LocalDateTime templateValue)
      : _templateValueDate = templateValue.calendarDate,
        _templateValueTime = templateValue.clockTime;

  // Note: to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  @override
  IPattern<LocalDateTime> parsePattern(String patternText, TimeMachineFormatInfo formatInfo) {
    // Nullity check is performed in LocalDateTimePattern.
    if (patternText.isEmpty) {
      throw InvalidPatternError(TextErrorMessages.formatStringEmpty);
    }

    if (patternText.length == 1) {
      String /*char*/ patternCharacter = patternText[0];
      if (patternCharacter == 'o' || patternCharacter == 'O') {
        return LocalDateTimePatterns.roundtripPatternImpl;
      }
      if (patternCharacter == 'r') {
        return LocalDateTimePatterns.fullRoundtripPatternImpl;
      }
      if (patternCharacter == 'R') {
        return LocalDateTimePatterns.fullRoundtripWithoutCalendarImpl;
      }
      if (patternCharacter == 's') {
        return LocalDateTimePatterns.generalIsoPatternImpl;
      }
      String? newPatternText = _expandStandardFormatPattern(patternCharacter, formatInfo);
      if (newPatternText == null) {
        throw IInvalidPatternError.format(TextErrorMessages.unknownStandardFormat, [patternCharacter, 'LocalDateTime']);
      }
      patternText = newPatternText;
    }

    var patternBuilder = SteppedPatternBuilder<LocalDateTime, LocalDateTimeParseBucket>(formatInfo,
            () => LocalDateTimeParseBucket(_templateValueDate, _templateValueTime));
    patternBuilder.parseCustomPattern(patternText, _patternCharacterHandlers);
    patternBuilder.validateUsedFields();
    return patternBuilder.build(_templateValueDate.at(_templateValueTime));
  }

  String? _expandStandardFormatPattern(/*char*/ String patternCharacter, TimeMachineFormatInfo formatInfo) {
    switch (patternCharacter) {
      case 'f':
        return formatInfo.dateTimeFormat.longDatePattern + ' ' + formatInfo.dateTimeFormat.shortTimePattern;
      case 'F':
        return formatInfo.dateTimeFormat.fullDateTimePattern;
      case 'g':
        return formatInfo.dateTimeFormat.shortDatePattern + ' ' + formatInfo.dateTimeFormat.shortTimePattern;
      case 'G':
        return formatInfo.dateTimeFormat.shortDatePattern + ' ' + formatInfo.dateTimeFormat.longTimePattern;
      default:
        // Will be turned into an exception.
        return null;
    }
  }
}

@internal
class LocalDateTimeParseBucket extends ParseBucket<LocalDateTime> {
  final /*LocalDatePatternParser.*/LocalDateParseBucket date;
  final /*LocalTimePatternParser.*/LocalTimeParseBucket time;

  LocalDateTimeParseBucket(LocalDate templateValueDate, LocalTime templateValueTime)
      : date = /*LocalDatePatternParser.*/LocalDateParseBucket(templateValueDate),
        time = /*LocalTimePatternParser.*/LocalTimeParseBucket(templateValueTime);

  /// Combines the values in a date bucket with the values in a time bucket.
  ///
  /// This would normally be the [calculateValue] method, but we want
  /// to be able to use the same logic when parsing an [OffsetDateTime]
  /// and [ZonedDateTime].
  static ParseResult<LocalDateTime> combineBuckets(PatternFields usedFields,
/*LocalDatePatternParser.*/LocalDateParseBucket dateBucket,
/*LocalTimePatternParser.*/LocalTimeParseBucket timeBucket,
      String text) {
    // Handle special case of hour = 24
    bool hour24 = false;
    if (timeBucket.hours24 == 24) {
      timeBucket.hours24 = 0;
      hour24 = true;
    }

    ParseResult<LocalDate> dateResult = dateBucket.calculateValue(usedFields & PatternFields.allDateFields, text);
    if (!dateResult.success) {
      return dateResult.convertError<LocalDateTime>();
    }
    ParseResult<LocalTime> timeResult = timeBucket.calculateValue(usedFields & PatternFields.allTimeFields, text);
    if (!timeResult.success) {
      return timeResult.convertError<LocalDateTime>();
    }

    LocalDate date = dateResult.value;
    LocalTime time = timeResult.value;

    if (hour24) {
      if (time != LocalTime.midnight) {
        return IParseResult.invalidHour24<LocalDateTime>(text);
      }
      date = date.addDays(1);
    }
    return ParseResult.forValue<LocalDateTime>(date.at(time));
  }

  @override
  ParseResult<LocalDateTime> calculateValue(PatternFields usedFields, String text) =>
      combineBuckets(usedFields, date, time, text);
}

