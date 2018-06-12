// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';

/// Maximum two-digit-year in the template to treat as the current century.
/// (One day we may want to make this configurable, but it feels very low
/// priority.)
@private const int TwoDigitYearMax = 30;

/// Parser for patterns of [LocalDate] values.
@internal /*sealed*/ class LocalDatePatternParser implements IPatternParser<LocalDate> {
  @private final LocalDate templateValue;

  // todo: was Map<Char
  @private final Map<String, CharacterHandler<LocalDate, LocalDateParseBucket>> PatternCharacterHandlers =
/*new Map<String, CharacterHandler<LocalDate, LocalDateParseBucket>>*/
  {
    '%': SteppedPatternBuilder.handlePercent/**<LocalDate, LocalDateParseBucket>*/,
    '\'': SteppedPatternBuilder.handleQuote/**<LocalDate, LocalDateParseBucket>*/,
    '\"': SteppedPatternBuilder.handleQuote/**<LocalDate, LocalDateParseBucket>*/,
    '\\': SteppedPatternBuilder.handleBackslash/**<LocalDate, LocalDateParseBucket>*/,
    '/': (pattern, builder) => builder.addLiteral1(builder.formatInfo.dateSeparator, ParseResult.DateSeparatorMismatch/**<LocalDate>*/),
    'y': DatePatternHelper.createYearOfEraHandler<LocalDate, LocalDateParseBucket>((value) => value.yearOfEra, (bucket, value) => bucket.YearOfEra = value),
    'u': SteppedPatternBuilder.handlePaddedField<LocalDate, LocalDateParseBucket>(4, PatternFields.year, -9999, 9999, (value) => value.year, (bucket, value) => bucket.Year = value),
    'M': DatePatternHelper.createMonthOfYearHandler<LocalDate, LocalDateParseBucket>((value) => value.month, (bucket, value) => bucket.MonthOfYearText = value, (bucket, value) => bucket.MonthOfYearNumeric = value),
    'd': DatePatternHelper.createDayHandler<LocalDate, LocalDateParseBucket>((value) => value.day, (value) => /*(int)*/ value.dayOfWeek.value, (bucket, value) => bucket.DayOfMonth = value, (bucket, value) => bucket.DayOfWeek = value),
    'c': DatePatternHelper.createCalendarHandler<LocalDate, LocalDateParseBucket>((value) => value.calendar, (bucket, value) => bucket.Calendar = value),
    'g': DatePatternHelper.createEraHandler<LocalDate, LocalDateParseBucket>((date) => date.era, (bucket) => bucket),
  };

  Map aMap = {'s': 0, 'y': 3};

  @internal LocalDatePatternParser(this.templateValue);

  // Note: to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  IPattern<LocalDate> parsePattern(String patternText, TimeMachineFormatInfo formatInfo) {
    // Nullity check is performed in LocalDatePattern.
    if (patternText.length == 0) {
      throw new InvalidPatternError(TextErrorMessages.FormatStringEmpty);
    }

    if (patternText.length == 1) {
      // todo: char
      var patternCharacter = patternText[0];
      patternText = ExpandStandardFormatPattern(patternCharacter, formatInfo);
      if (patternText == null) {
        throw new InvalidPatternError.format(TextErrorMessages.UnknownStandardFormat, [patternCharacter, 'LocalDate']);
      }
    }

    var patternBuilder = new SteppedPatternBuilder<LocalDate, LocalDateParseBucket>(formatInfo,
            () => new LocalDateParseBucket(templateValue));
    patternBuilder.parseCustomPattern(patternText, PatternCharacterHandlers);
    patternBuilder.validateUsedFields();
    return patternBuilder.build(templateValue);
  }

  @private String ExpandStandardFormatPattern(String /*char*/ patternCharacter, TimeMachineFormatInfo formatInfo) {
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
@internal /*sealed*/ class LocalDateParseBucket extends ParseBucket<LocalDate> {
  @internal final LocalDate TemplateValue;

  @internal CalendarSystem Calendar;
  @internal int Year = 0;
  @private Era era = Era.common;
  @internal int YearOfEra = 0;
  @internal int MonthOfYearNumeric = 0;
  @internal int MonthOfYearText = 0;
  @internal int DayOfMonth = 0;
  @internal int DayOfWeek = 0;

  @internal LocalDateParseBucket(this.TemplateValue) {
    // Only fetch this once.
    this.Calendar = TemplateValue.calendar;
  }

  @internal ParseResult<TResult> ParseEra<TResult>(TimeMachineFormatInfo formatInfo, ValueCursor cursor) {
    var compareInfo = formatInfo.compareInfo;
    for (var era in Calendar.eras) {
      for (String eraName in formatInfo.getEraNames(era)) {
        if (cursor.MatchCaseInsensitive(eraName, compareInfo, true)) {
          this.era = era;
          return null;
        }
      }
    }
    return ParseResult.MismatchedText<TResult>(cursor, 'g');
  }

  @internal
  @override
  ParseResult<LocalDate> CalculateValue(PatternFields usedFields, String text) {
    if (usedFields.hasAny(PatternFields.embeddedDate)) {
      return ParseResult.ForValue<LocalDate>(new LocalDate(Year, MonthOfYearNumeric, DayOfMonth, Calendar));
    }
    // This will set Year if necessary
    ParseResult<LocalDate> failure = DetermineYear(usedFields, text);
    if (failure != null) {
      return failure;
    }
    // This will set MonthOfYearNumeric if necessary
    failure = DetermineMonth(usedFields, text);
    if (failure != null) {
      return failure;
    }

    int day = usedFields.hasAny(PatternFields.dayOfMonth) ? DayOfMonth : TemplateValue.day;
    if (day > Calendar.getDaysInMonth(Year, MonthOfYearNumeric)) {
      return ParseResult.DayOfMonthOutOfRange<LocalDate>(text, day, MonthOfYearNumeric, Year);
    }

    LocalDate value = new LocalDate(Year, MonthOfYearNumeric, day, Calendar);

    if (usedFields.hasAny(PatternFields.dayOfWeek) && DayOfWeek != value.dayOfWeek.value) {
      return ParseResult.InconsistentDayOfWeekTextValue<LocalDate>(text);
    }

    return ParseResult.ForValue<LocalDate>(value);
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
  @private ParseResult<LocalDate> DetermineYear(PatternFields usedFields, String text) {
    if (usedFields.hasAny(PatternFields.year)) {
      if (Year > Calendar.maxYear || Year < Calendar.minYear) {
        return ParseResult.FieldValueOutOfRangePostParse<LocalDate>(text, Year, 'u', 'LocalDate');
      }

      if (usedFields.hasAny(PatternFields.era) && era != Calendar.getEra(Year)) {
        return ParseResult.InconsistentValues<LocalDate>(text, 'g', 'u', 'LocalDate');
      }

      if (usedFields.hasAny(PatternFields.yearOfEra)) {
        int yearOfEraFromYear = Calendar.getYearOfEra(Year);
        if (usedFields.hasAny(PatternFields.yearTwoDigits)) {
          // We're only checking the last two digits
          yearOfEraFromYear = yearOfEraFromYear % 100;
        }
        if (yearOfEraFromYear != YearOfEra) {
          return ParseResult.InconsistentValues<LocalDate>(text, 'y', 'u', 'LocalDate');
        }
      }
      return null;
    }

    // Use the year from the template value, possibly checking the era.
    if (!usedFields.hasAny(PatternFields.yearOfEra)) {
      Year = TemplateValue.year;
      return usedFields.hasAny(PatternFields.era) && era != Calendar.getEra(Year)
          ? ParseResult.InconsistentValues<LocalDate>(text, 'g', 'u', 'LocalDate') : null;
    }

    if (!usedFields.hasAny(PatternFields.era)) {
      era = TemplateValue.era;
    }

    if (usedFields.hasAny(PatternFields.yearTwoDigits)) {
      int century = TemplateValue.yearOfEra ~/ 100;
      if (YearOfEra > TwoDigitYearMax && century > 1) {
        century--;
      }
      YearOfEra += century * 100;
    }

    if (YearOfEra < Calendar.getMinYearOfEra(era) ||
        YearOfEra > Calendar.getMaxYearOfEra(era)) {
      return ParseResult.YearOfEraOutOfRange<LocalDate>(text, YearOfEra, era, Calendar);
    }
    Year = Calendar.getAbsoluteYear(YearOfEra, era);
    return null;
  }

  //static const PatternFields monthOfYearNumeric = const PatternFields(1 << 10);
  //static const PatternFields monthOfYearText = const PatternFields(1 << 11);
  static const PatternFields monthOfYearText_booleanOR_monthOfYearText = const PatternFields(1 << 11 | 1 << 10);

  @private ParseResult<LocalDate> DetermineMonth(PatternFields usedFields, String text) {
    var x = usedFields & (PatternFields.monthOfYearNumeric | PatternFields.monthOfYearText);
    if (x ==  PatternFields.monthOfYearNumeric) {
    // No-op
    }
    else if (x == PatternFields.monthOfYearText) {
      MonthOfYearNumeric = MonthOfYearText;
    }
    else if (x == monthOfYearText_booleanOR_monthOfYearText) { // PatternFields.monthOfYearNumeric | PatternFields.monthOfYearText:
      if (MonthOfYearNumeric != MonthOfYearText) {
        return ParseResult.InconsistentMonthValues<LocalDate>(text);
      }
    // No need to change MonthOfYearNumeric - this was just a check
    }
    else if (x == PatternFields.none) {
      MonthOfYearNumeric = TemplateValue.month;
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

    if (MonthOfYearNumeric > Calendar.getMonthsInYear(Year)) {
      return ParseResult.MonthOutOfRange<LocalDate>(text, MonthOfYearNumeric, Year);
    }
    return null;
  }
}
