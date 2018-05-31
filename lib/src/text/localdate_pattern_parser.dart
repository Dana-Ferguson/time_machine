// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Text/LocalDatePatternParser.cs
// 69dedbc  on Apr 23

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';

/// Maximum two-digit-year in the template to treat as the current century.
/// (One day we may want to make this configurable, but it feels very low
/// priority.)
@private const int TwoDigitYearMax = 30;

/// Parser for patterns of <see cref="LocalDate"/> values.
@internal /*sealed*/ class LocalDatePatternParser implements IPatternParser<LocalDate> {
  @private final LocalDate templateValue;

  // todo: was Map<Char
  @private final Map<String, CharacterHandler<LocalDate, LocalDateParseBucket>> PatternCharacterHandlers =
/*new Map<String, CharacterHandler<LocalDate, LocalDateParseBucket>>*/
  {
    '%': SteppedPatternBuilder.HandlePercent/**<LocalDate, LocalDateParseBucket>*/,
    '\'': SteppedPatternBuilder.HandleQuote/**<LocalDate, LocalDateParseBucket>*/,
    '\"': SteppedPatternBuilder.HandleQuote/**<LocalDate, LocalDateParseBucket>*/,
    '\\': SteppedPatternBuilder.HandleBackslash/**<LocalDate, LocalDateParseBucket>*/,
    '/': (pattern, builder) => builder.AddLiteral1(builder.FormatInfo.DateSeparator, ParseResult.DateSeparatorMismatch/**<LocalDate>*/),
    'y': DatePatternHelper.CreateYearOfEraHandler<LocalDate, LocalDateParseBucket>((value) => value.YearOfEra, (bucket, value) => bucket.YearOfEra = value),
    'u': SteppedPatternBuilder.HandlePaddedField<LocalDate, LocalDateParseBucket>(4, PatternFields.year, -9999, 9999, (value) => value.Year, (bucket, value) => bucket.Year = value),
    'M': DatePatternHelper.CreateMonthOfYearHandler<LocalDate, LocalDateParseBucket>((value) => value.Month, (bucket, value) => bucket.MonthOfYearText = value, (bucket, value) => bucket.MonthOfYearNumeric = value),
    'd': DatePatternHelper.CreateDayHandler<LocalDate, LocalDateParseBucket>((value) => value.Day, (value) => /*(int)*/ value.DayOfWeek.value, (bucket, value) => bucket.DayOfMonth = value, (bucket, value) => bucket.DayOfWeek = value),
    'c': DatePatternHelper.CreateCalendarHandler<LocalDate, LocalDateParseBucket>((value) => value.Calendar, (bucket, value) => bucket.Calendar = value),
    'g': DatePatternHelper.CreateEraHandler<LocalDate, LocalDateParseBucket>((date) => date.era, (bucket) => bucket),
  };

  Map aMap = {'s': 0, 'y': 3};

  @internal LocalDatePatternParser(this.templateValue);

// Note: to implement the interface. It does no harm, and it's simpler than using explicit
// interface implementation.
  IPattern<LocalDate> ParsePattern(String patternText, NodaFormatInfo formatInfo) {
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
    patternBuilder.ParseCustomPattern(patternText, PatternCharacterHandlers);
    patternBuilder.ValidateUsedFields();
    return patternBuilder.Build(templateValue);
  }

  @private String ExpandStandardFormatPattern(String /*char*/ patternCharacter, NodaFormatInfo formatInfo) {
    switch (patternCharacter) {
      case 'd':
        return formatInfo.DateTimeFormat.shortDatePattern;
      case 'D':
        return formatInfo.DateTimeFormat.longDatePattern;
      default:
        // Will be turned into an exception.
        return null;
    }
  }
}

// todo: was a sub class of LocalDatePatternParser
/// <summary>
/// Bucket to put parsed values in, ready for later result calculation. This type is also used
/// by LocalDateTimePattern to store and calculate values.
/// </summary>
@internal /*sealed*/ class LocalDateParseBucket extends ParseBucket<LocalDate> {
  @internal final LocalDate TemplateValue;

  @internal CalendarSystem Calendar;
  @internal int Year = 0;
  @private Era era = Era.Common;
  @internal int YearOfEra = 0;
  @internal int MonthOfYearNumeric = 0;
  @internal int MonthOfYearText = 0;
  @internal int DayOfMonth = 0;
  @internal int DayOfWeek = 0;

  @internal LocalDateParseBucket(this.TemplateValue) {
// Only fetch this once.
    this.Calendar = TemplateValue.Calendar;
  }

  @internal ParseResult<TResult> ParseEra<TResult>(NodaFormatInfo formatInfo, ValueCursor cursor) {
    var compareInfo = formatInfo.compareInfo;
    for (var era in Calendar.eras) {
      for (String eraName in formatInfo.GetEraNames(era)) {
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
    if (usedFields.HasAny(PatternFields.embeddedDate)) {
      return ParseResult.ForValue<LocalDate>(new LocalDate.forCalendar(Year, MonthOfYearNumeric, DayOfMonth, Calendar));
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

    int day = usedFields.HasAny(PatternFields.dayOfMonth) ? DayOfMonth : TemplateValue.Day;
    if (day > Calendar.GetDaysInMonth(Year, MonthOfYearNumeric)) {
      return ParseResult.DayOfMonthOutOfRange<LocalDate>(text, day, MonthOfYearNumeric, Year);
    }

    LocalDate value = new LocalDate.forCalendar(Year, MonthOfYearNumeric, day, Calendar);

    if (usedFields.HasAny(PatternFields.dayOfWeek) && DayOfWeek != value.DayOfWeek.value) {
      return ParseResult.InconsistentDayOfWeekTextValue<LocalDate>(text);
    }

    return ParseResult.ForValue<LocalDate>(value);
  }

  /// <summary>
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
  /// </summary>
  @private ParseResult<LocalDate> DetermineYear(PatternFields usedFields, String text) {
    if (usedFields.HasAny(PatternFields.year)) {
      if (Year > Calendar.maxYear || Year < Calendar.minYear) {
        return ParseResult.FieldValueOutOfRangePostParse<LocalDate>(text, Year, 'u');
      }

      if (usedFields.HasAny(PatternFields.era) && era != Calendar.GetEra(Year)) {
        return ParseResult.InconsistentValues<LocalDate>(text, 'g', 'u');
      }

      if (usedFields.HasAny(PatternFields.yearOfEra)) {
        int yearOfEraFromYear = Calendar.GetYearOfEra(Year);
        if (usedFields.HasAny(PatternFields.yearTwoDigits)) {
// We're only checking the last two digits
          yearOfEraFromYear = yearOfEraFromYear % 100;
        }
        if (yearOfEraFromYear != YearOfEra) {
          return ParseResult.InconsistentValues<LocalDate>(text, 'y', 'u');
        }
      }
      return null;
    }

// Use the year from the template value, possibly checking the era.
    if (!usedFields.HasAny(PatternFields.yearOfEra)) {
      Year = TemplateValue.Year;
      return usedFields.HasAny(PatternFields.era) && era != Calendar.GetEra(Year)
          ? ParseResult.InconsistentValues<LocalDate>(text, 'g', 'u') : null;
    }

    if (!usedFields.HasAny(PatternFields.era)) {
      era = TemplateValue.era;
    }

    if (usedFields.HasAny(PatternFields.yearTwoDigits)) {
      int century = TemplateValue.YearOfEra ~/ 100;
      if (YearOfEra > TwoDigitYearMax && century > 1) {
        century--;
      }
      YearOfEra += century * 100;
    }

    if (YearOfEra < Calendar.GetMinYearOfEra(era) ||
        YearOfEra > Calendar.GetMaxYearOfEra(era)) {
      return ParseResult.YearOfEraOutOfRange<LocalDate>(text, YearOfEra, era, Calendar);
    }
    Year = Calendar.GetAbsoluteYear(YearOfEra, era);
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
      MonthOfYearNumeric = TemplateValue.Month;
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

    if (MonthOfYearNumeric > Calendar.GetMonthsInYear(Year)) {
      return ParseResult.MonthOutOfRange<LocalDate>(text, MonthOfYearNumeric, Year);
    }
    return null;
  }
}