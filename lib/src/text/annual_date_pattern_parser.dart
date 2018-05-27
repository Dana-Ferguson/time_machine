// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Text/AnnualDatePatternParser.cs
// c77bb7b  19 days ago
import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';

/// <summary>
/// Parser for patterns of <see cref="AnnualDate"/> values.
/// </summary>
@internal /*sealed*/ class AnnualDatePatternParser implements IPatternParser<AnnualDate> {
  @private final AnnualDate templateValue;

  @private static final Map<String /*char*/, CharacterHandler<AnnualDate, AnnualDateParseBucket>> PatternCharacterHandlers = {
    '%': SteppedPatternBuilder.HandlePercent /**<AnnualDate, AnnualDateParseBucket>*/,
    '\'': SteppedPatternBuilder.HandleQuote /**<AnnualDate, AnnualDateParseBucket>*/,
    '\"': SteppedPatternBuilder.HandleQuote /**<AnnualDate, AnnualDateParseBucket>*/,
    '\\': SteppedPatternBuilder.HandleBackslash /**<AnnualDate, AnnualDateParseBucket>*/,
    '/': (pattern, builder) => builder.AddLiteral1(builder.FormatInfo.DateSeparator, ParseResult.DateSeparatorMismatch /**<AnnualDate>*/),
    'M': DatePatternHelper.CreateMonthOfYearHandler<AnnualDate, AnnualDateParseBucket>
      ((value) => value.month, (bucket, value) => bucket.MonthOfYearText = value, (bucket, value) => bucket.MonthOfYearNumeric = value),
    'd': HandleDayOfMonth
  };

  @internal AnnualDatePatternParser(this.templateValue);

  // Note: to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  IPattern<AnnualDate> ParsePattern(String patternText, NodaFormatInfo formatInfo) {
    // Nullity check is performed in AnnualDatePattern.
    if (patternText.length == 0) {
      throw new InvalidPatternError(TextErrorMessages.FormatStringEmpty);
    }

    if (patternText.length == 1) {
      switch (patternText[0]) {
        case 'G':
          return AnnualDatePattern.Iso;
        default:
          throw new InvalidPatternError.format(TextErrorMessages.UnknownStandardFormat, [patternText[0], 'AnnualDate']);
      }
    }

    var patternBuilder = new SteppedPatternBuilder<AnnualDate, AnnualDateParseBucket>(formatInfo,
            () => new AnnualDateParseBucket(templateValue));
    patternBuilder.ParseCustomPattern(patternText, PatternCharacterHandlers);
    patternBuilder.ValidateUsedFields();
    return patternBuilder.Build(templateValue);
  }

  @private static void HandleDayOfMonth(PatternCursor pattern, SteppedPatternBuilder<AnnualDate, AnnualDateParseBucket> builder) {
    int count = pattern.GetRepeatCount(2);
    PatternFields field;
    switch (count) {
      case 1:
      case 2:
        field = PatternFields.dayOfMonth;
        // Handle real maximum value in the bucket
        builder.AddParseValueAction(count, 2, pattern.Current, 1, 99, (bucket, value) => bucket.DayOfMonth = value);
        builder.AddFormatLeftPad(count, (value) => value.day, assumeNonNegative: true, assumeFitsInCount: count == 2);
        break;
      default:
        throw new StateError/*InvalidOperationException*/("Invalid count!");
    }
    builder.AddField(field, pattern.Current);
  }
}

/// <summary>
/// Bucket to put parsed values in, ready for later result calculation. This type is also used
/// by AnnualDateTimePattern to store and calculate values.
/// </summary>
@internal /*sealed*/ class AnnualDateParseBucket extends ParseBucket<AnnualDate> {
  @internal final AnnualDate TemplateValue;
  @internal int MonthOfYearNumeric;
  @internal int MonthOfYearText;
  @internal int DayOfMonth;

  @internal AnnualDateParseBucket(this.TemplateValue);

  @internal
  @override
  ParseResult<AnnualDate> CalculateValue(PatternFields usedFields, String text) {
    // This will set MonthOfYearNumeric if necessary
    var failure = DetermineMonth(usedFields, text);
    if (failure != null) {
      return failure;
    }

    int day = usedFields.HasAny(PatternFields.dayOfMonth) ? DayOfMonth : TemplateValue.day;
    // Validate for the year 2000, just like the AnnualDate constructor does.
    if (day > CalendarSystem.Iso.GetDaysInMonth(2000, MonthOfYearNumeric)) {
      return ParseResult.DayOfMonthOutOfRangeNoYear<AnnualDate>(text, day, MonthOfYearNumeric);
    }

    return ParseResult.ForValue<AnnualDate>(new AnnualDate(MonthOfYearNumeric, day));
  }

  // PatternFields.monthOfYearNumeric | PatternFields.monthOfYearText
  // static final PatternFields monthOfYearNumeric_booleanOR_monthOfYearText = new PatternFields(_value)

  @private ParseResult<AnnualDate> DetermineMonth(PatternFields usedFields, String text) {
    var x = usedFields & (PatternFields.monthOfYearNumeric | PatternFields.monthOfYearText);
    if (x == PatternFields.monthOfYearNumeric) {
      // No-op
    }
    else if (x == PatternFields.monthOfYearText) {
      MonthOfYearNumeric = MonthOfYearText;
    }
    else if (x == PatternFields.monthOfYearNumeric | PatternFields.monthOfYearText) {
      if (MonthOfYearNumeric != MonthOfYearText) {
        return ParseResult.InconsistentMonthValues<AnnualDate>(text);
      }
      // No need to change MonthOfYearNumeric - this was just a check
    }
    else if (x == PatternFields.none) {
      MonthOfYearNumeric = TemplateValue.month;
    }

    /*switch (usedFields & (PatternFields.monthOfYearNumeric | PatternFields.monthOfYearText)) {
      case PatternFields.monthOfYearNumeric:
        // No-op
        break;
      case PatternFields.monthOfYearText:
        MonthOfYearNumeric = MonthOfYearText;
        break;
      case PatternFields.monthOfYearNumeric | PatternFields.monthOfYearText:
        if (MonthOfYearNumeric != MonthOfYearText) {
          return ParseResult.InconsistentMonthValues<AnnualDate>(text);
        }
        // No need to change MonthOfYearNumeric - this was just a check
        break;
      case PatternFields.none:
        MonthOfYearNumeric = TemplateValue.month;
        break;
    }*/

    if (MonthOfYearNumeric > CalendarSystem.Iso.GetMonthsInYear(2000)) {
      return ParseResult.IsoMonthOutOfRange<AnnualDate>(text, MonthOfYearNumeric);
    }
    return null;
  }
}