// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/text/patterns/time_machine_patterns.dart';

/// Maximum two-digit-year in the template to treat as the current century.
/// (One day we may want to make this configurable, but it feels very low
/// priority.)
const int _twoDigitYearMax = 30;

/// Parser for patterns of [LocalDate] values.
@internal
class LocalDatePatternParser implements IPatternParser<LocalDate> {
  final LocalDate _templateValue;

  // todo: was Map<Char
  final Map<String, CharacterHandler<LocalDate, LocalDateParseBucket>> _patternCharacterHandlers =
/*new Map<String, CharacterHandler<LocalDate, LocalDateParseBucket>>*/
  {
    '%': SteppedPatternBuilder.handlePercent/**<LocalDate, LocalDateParseBucket>*/,
    '\'': SteppedPatternBuilder.handleQuote/**<LocalDate, LocalDateParseBucket>*/,
    '\"': SteppedPatternBuilder.handleQuote/**<LocalDate, LocalDateParseBucket>*/,
    '\\': SteppedPatternBuilder.handleBackslash/**<LocalDate, LocalDateParseBucket>*/,
    '/': (pattern, builder) => builder.addLiteral1(builder.formatInfo.dateSeparator, IParseResult.dateSeparatorMismatch/**<LocalDate>*/),
    'y': DatePatternHelper.createYearOfEraHandler<LocalDate, LocalDateParseBucket>((value) => value.yearOfEra, (bucket, value) => bucket.yearOfEra = value),
    'u': SteppedPatternBuilder.handlePaddedField<LocalDate, LocalDateParseBucket>(4, PatternFields.year, -9999, 9999, (value) => value.year, (bucket, value) => bucket.year = value),
    'M': DatePatternHelper.createMonthOfYearHandler<LocalDate, LocalDateParseBucket>((value) => value.monthOfYear, (bucket, value) => bucket.monthOfYearText = value, (bucket, value) => bucket.monthOfYearNumeric = value),
    'd': DatePatternHelper.createDayHandler<LocalDate, LocalDateParseBucket>((value) => value.dayOfMonth, (value) => /*(int)*/ value.dayOfWeek.value, (bucket, value) => bucket.dayOfMonth = value, (bucket, value) => bucket.dayOfWeek = value),
    'c': DatePatternHelper.createCalendarHandler<LocalDate, LocalDateParseBucket>((value) => value.calendar, (bucket, value) => bucket.calendar = value),
    'g': DatePatternHelper.createEraHandler<LocalDate, LocalDateParseBucket>((date) => date.era, (bucket) => bucket),
  };

  LocalDatePatternParser(this._templateValue);

  // Note: to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  @override
  IPattern<LocalDate> parsePattern(String patternText, TimeMachineFormatInfo formatInfo) {
    // Nullity check is performed in LocalDatePattern.
    if (patternText.isEmpty) {
      throw InvalidPatternError(TextErrorMessages.formatStringEmpty);
    }

    if (patternText.length == 1) {
      // todo: do we want this functionality? (this was similar to the BCL support patterns
      // -- except it hits up dateTimeFormat stuff -- is there a different way this could or should be accessed?
      var patternCharacter = patternText[0];
      String? newPatternText = _expandStandardFormatPattern(patternText, formatInfo);
      if (newPatternText == null) {
        throw IInvalidPatternError.format(TextErrorMessages.unknownStandardFormat, [patternCharacter, 'LocalDate']);
      }
      patternText = newPatternText;
    }

    var patternBuilder = SteppedPatternBuilder<LocalDate, LocalDateParseBucket>(formatInfo,
            () => LocalDateParseBucket(_templateValue));
    patternBuilder.parseCustomPattern(patternText, _patternCharacterHandlers);
    patternBuilder.validateUsedFields();
    return patternBuilder.build(_templateValue);
  }

  String? _expandStandardFormatPattern(String patternCharacter, TimeMachineFormatInfo formatInfo) {
    switch (patternCharacter) {
      case 'd':
        return formatInfo.dateTimeFormat.shortDatePattern;
      case 'D':
        return formatInfo.dateTimeFormat.longDatePattern;
      default:
        // Will be turned into an exception.
        return null;
    }
  }
}

// todo: was a sub class of LocalDatePatternParser
/// Bucket to put parsed values in, ready for later result calculation. This type is also used
/// by LocalDateTimePattern to store and calculate values.
@internal
class LocalDateParseBucket extends ParseBucket<LocalDate> {
  final LocalDate templateValue;

  CalendarSystem calendar;
  int year = 0;
  Era _era = Era.common;
  int yearOfEra = 0;
  int monthOfYearNumeric = 0;
  int monthOfYearText = 0;
  int dayOfMonth = 0;
  int dayOfWeek = 0;

  LocalDateParseBucket(this.templateValue) :
    // Only fetch this once.
    calendar = templateValue.calendar;

  ParseResult<TResult>? parseEra<TResult>(TimeMachineFormatInfo formatInfo, ValueCursor cursor) {
    var compareInfo = formatInfo.compareInfo;
    for (var era in calendar.eras) {
      for (String eraName in formatInfo.getEraNames(era)) {
        if (cursor.matchCaseInsensitive(eraName, compareInfo, true)) {
          _era = era;
          return null;
        }
      }
    }
    return IParseResult.mismatchedText<TResult>(cursor, 'g');
  }

  @internal
  @override
  ParseResult<LocalDate> calculateValue(PatternFields usedFields, String text) {
    if (usedFields.hasAny(PatternFields.embeddedDate)) {
      return ParseResult.forValue<LocalDate>(LocalDate(year, monthOfYearNumeric, dayOfMonth, calendar));
    }
    // This will set Year if necessary
    ParseResult<LocalDate>? failure = _determineYear(usedFields, text);
    if (failure != null) {
      return failure;
    }
    // This will set MonthOfYearNumeric if necessary
    failure = _determineMonth(usedFields, text);
    if (failure != null) {
      return failure;
    }

    int day = usedFields.hasAny(PatternFields.dayOfMonth) ? dayOfMonth : templateValue.dayOfMonth;
    if (day > calendar.getDaysInMonth(year, monthOfYearNumeric)) {
      return IParseResult.dayOfMonthOutOfRange<LocalDate>(text, day, monthOfYearNumeric, year);
    }

    LocalDate value = LocalDate(year, monthOfYearNumeric, day, calendar);

    if (usedFields.hasAny(PatternFields.dayOfWeek) && dayOfWeek != value.dayOfWeek.value) {
      return IParseResult.inconsistentDayOfWeekTextValue<LocalDate>(text);
    }

    return ParseResult.forValue<LocalDate>(value);
  }

  /// Work out the year, based on fields of:
  /// - Year
  /// - YearOfEra
  /// - YearTwoDigits (implies YearOfEra)
  /// - Era
  ///
  /// If the year is specified, that trumps everything else - any other fields
  /// are just used for checking.
  ///
  /// If nothing is specified, the year of the template value is used.
  ///
  /// If just the era is specified, the year of the template value is used,
  /// and the specified era is checked against it. (Hopefully no-one will
  /// expect to get useful information from a format String with era but no year...)
  ///
  /// Otherwise, we have the year of era (possibly only two digits) and possibly the
  /// era. If the era isn't specified, take it from the template value.
  /// Finally, if we only have two digits, then use either the century of the template
  /// value or the previous century if the year-of-era is greater than TwoDigitYearMax...
  /// and if the template value isn't in the first century already.
  ///
  /// Phew.
  ParseResult<LocalDate>? _determineYear(PatternFields usedFields, String text) {
    if (usedFields.hasAny(PatternFields.year)) {
      if (year > calendar.maxYear || year < calendar.minYear) {
        return IParseResult.fieldValueOutOfRangePostParse<LocalDate>(text, year, 'u', 'LocalDate');
      }

      if (usedFields.hasAny(PatternFields.era) && _era != ICalendarSystem.getEra(calendar, year)) {
        return IParseResult.inconsistentValues<LocalDate>(text, 'g', 'u', 'LocalDate');
      }

      if (usedFields.hasAny(PatternFields.yearOfEra)) {
        int yearOfEraFromYear = ICalendarSystem.getYearOfEra(calendar, year);
        if (usedFields.hasAny(PatternFields.yearTwoDigits)) {
          // We're only checking the last two digits
          yearOfEraFromYear = yearOfEraFromYear % 100;
        }
        if (yearOfEraFromYear != yearOfEra) {
          return IParseResult.inconsistentValues<LocalDate>(text, 'y', 'u', 'LocalDate');
        }
      }
      return null;
    }

    // Use the year from the template value, possibly checking the era.
    if (!usedFields.hasAny(PatternFields.yearOfEra)) {
      year = templateValue.year;
      return usedFields.hasAny(PatternFields.era) && _era != ICalendarSystem.getEra(calendar, year)
          ? IParseResult.inconsistentValues<LocalDate>(text, 'g', 'u', 'LocalDate') : null;
    }

    if (!usedFields.hasAny(PatternFields.era)) {
      _era = templateValue.era;
    }

    if (usedFields.hasAny(PatternFields.yearTwoDigits)) {
      int century = templateValue.yearOfEra ~/ 100;
      if (yearOfEra > _twoDigitYearMax && century > 1) {
        century--;
      }
      yearOfEra += century * 100;
    }

    if (yearOfEra < calendar.getMinYearOfEra(_era) ||
        yearOfEra > calendar.getMaxYearOfEra(_era)) {
      return IParseResult.yearOfEraOutOfRange<LocalDate>(text, yearOfEra, _era, calendar);
    }
    year = calendar.getAbsoluteYear(yearOfEra, _era);
    return null;
  }

  //static const PatternFields monthOfYearNumeric = const PatternFields(1 << 10);
  //static const PatternFields monthOfYearText = const PatternFields(1 << 11);
  static const PatternFields _monthOfYearText_booleanOR_monthOfYearText = PatternFields(1 << 11 | 1 << 10);

  ParseResult<LocalDate>? _determineMonth(PatternFields usedFields, String text) {
    var x = usedFields & (PatternFields.monthOfYearNumeric | PatternFields.monthOfYearText);
    if (x ==  PatternFields.monthOfYearNumeric) {
    // No-op
    }
    else if (x == PatternFields.monthOfYearText) {
      monthOfYearNumeric = monthOfYearText;
    }
    else if (x == _monthOfYearText_booleanOR_monthOfYearText) { // PatternFields.monthOfYearNumeric | PatternFields.monthOfYearText:
      if (monthOfYearNumeric != monthOfYearText) {
        return IParseResult.inconsistentMonthValues<LocalDate>(text);
      }
    // No need to change MonthOfYearNumeric - this was just a check
    }
    else if (x == PatternFields.none) {
      monthOfYearNumeric = templateValue.monthOfYear;
    }

    /*
    switch (usedFields & (PatternFields.monthOfYearNumeric | PatternFields.monthOfYearText)) {
      case PatternFields.monthOfYearNumeric:
        // No-op
        break;
      case PatternFields.monthOfYearText:
        MonthOfYearNumeric = MonthOfYearText;
        break;
      case monthOfYearText_booleanOR_monthOfYearText: // PatternFields.monthOfYearNumeric | PatternFields.monthOfYearText:
        if (MonthOfYearNumeric != MonthOfYearText) {
          return ParseResult.InconsistentMonthValues<LocalDate>(text);
        }
        // No need to change MonthOfYearNumeric - this was just a check
        break;
      case PatternFields.none:
        MonthOfYearNumeric = TemplateValue.Month;
        break;
    }*/

    if (monthOfYearNumeric > calendar.getMonthsInYear(year)) {
      return IParseResult.monthOutOfRange<LocalDate>(text, monthOfYearNumeric, year);
    }
    return null;
  }
}
