// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';
import 'package:time_machine/src/text/patterns/time_machine_patterns.dart';

/// Parser for patterns of [AnnualDate] values.
@internal
class AnnualDatePatternParser implements IPatternParser<AnnualDate> {
  final AnnualDate _templateValue;

  static final Map<String /*char*/, CharacterHandler<AnnualDate, AnnualDateParseBucket>> _patternCharacterHandlers = {
    '%': SteppedPatternBuilder.handlePercent /**<AnnualDate, AnnualDateParseBucket>*/,
    '\'': SteppedPatternBuilder.handleQuote /**<AnnualDate, AnnualDateParseBucket>*/,
    '\"': SteppedPatternBuilder.handleQuote /**<AnnualDate, AnnualDateParseBucket>*/,
    '\\': SteppedPatternBuilder.handleBackslash /**<AnnualDate, AnnualDateParseBucket>*/,
    '/': (pattern, builder) => builder.addLiteral1(builder.formatInfo.dateSeparator, IParseResult.dateSeparatorMismatch /**<AnnualDate>*/),
    'M': DatePatternHelper.createMonthOfYearHandler<AnnualDate, AnnualDateParseBucket>
      ((value) => value.month, (bucket, value) => bucket.monthOfYearText = value, (bucket, value) => bucket.monthOfYearNumeric = value),
    'd': _handleDayOfMonth
  };

  AnnualDatePatternParser(this._templateValue);

  // Note: to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  @override
  IPattern<AnnualDate> parsePattern(String patternText, TimeMachineFormatInfo formatInfo) {
    // Nullity check is performed in AnnualDatePattern.
    if (patternText.isEmpty) {
      throw InvalidPatternError(TextErrorMessages.formatStringEmpty);
    }

    // todo: I am unsure if this is a 'good' or a 'bad' thing -- this is obviously a 'windows' thing 
    //    -- and I can't seem to find it backed up in a standard
    // https://docs.microsoft.com/en-us/dotnet/standard/base-types/standard-date-and-time-format-strings
    if (patternText.length == 1)
    {
      switch (patternText[0])
      {
        case 'G':
          return AnnualDatePatterns.isoPatternImpl;
        default:
          throw IInvalidPatternError.format(TextErrorMessages.unknownStandardFormat,[patternText[0], 'AnnualDate']);
      }
    }

    var patternBuilder = SteppedPatternBuilder<AnnualDate, AnnualDateParseBucket>(formatInfo,
            () => AnnualDateParseBucket(_templateValue));
    patternBuilder.parseCustomPattern(patternText, _patternCharacterHandlers);
    patternBuilder.validateUsedFields();
    return patternBuilder.build(_templateValue);
  }

  static void _handleDayOfMonth(PatternCursor pattern, SteppedPatternBuilder<AnnualDate, AnnualDateParseBucket> builder) {
    int count = pattern.getRepeatCount(2);
    PatternFields field;
    switch (count) {
      case 1:
      case 2:
        field = PatternFields.dayOfMonth;
        // Handle real maximum value in the bucket
        builder.addParseValueAction(count, 2, pattern.current, 1, 99, (bucket, value) => bucket.dayOfMonth = value);
        builder.addFormatLeftPad(count, (value) => value.day, assumeNonNegative: true, assumeFitsInCount: count == 2);
        break;
      default:
        throw StateError/*InvalidOperationException*/('Invalid count!');
    }
    builder.addField(field, pattern.current);
  }
}

/// Bucket to put parsed values in, ready for later result calculation. This type is also used
/// by AnnualDateTimePattern to store and calculate values.
@internal
class AnnualDateParseBucket extends ParseBucket<AnnualDate> {
  final AnnualDate templateValue;
  int monthOfYearNumeric = 0;
  int monthOfYearText = 0;
  int dayOfMonth = 0;

  AnnualDateParseBucket(this.templateValue);
  
  @override
  ParseResult<AnnualDate> calculateValue(PatternFields usedFields, String text) {
    // This will set MonthOfYearNumeric if necessary
    var failure = _determineMonth(usedFields, text);
    if (failure != null) {
      return failure;
    }

    int day = usedFields.hasAny(PatternFields.dayOfMonth) ? dayOfMonth : templateValue.day;
    // Validate for the year 2000, just like the AnnualDate constructor does.
    if (day > CalendarSystem.iso.getDaysInMonth(2000, monthOfYearNumeric)) {
      return IParseResult.dayOfMonthOutOfRangeNoYear<AnnualDate>(text, day, monthOfYearNumeric);
    }

    return ParseResult.forValue<AnnualDate>(AnnualDate(monthOfYearNumeric, day));
  }

  // PatternFields.monthOfYearNumeric | PatternFields.monthOfYearText
  // static final PatternFields monthOfYearNumeric_booleanOR_monthOfYearText = new PatternFields(_value)
  ParseResult<AnnualDate>? _determineMonth(PatternFields usedFields, String text) {
    var x = usedFields & (PatternFields.monthOfYearNumeric | PatternFields.monthOfYearText);
    if (x == PatternFields.monthOfYearNumeric) {
    // No-op
    }
    else if (x == PatternFields.monthOfYearText) {
      monthOfYearNumeric = monthOfYearText;
    }
    else if (x == PatternFields.monthOfYearNumeric | PatternFields.monthOfYearText) {
      if (monthOfYearNumeric != monthOfYearText) {
        return IParseResult.inconsistentMonthValues<AnnualDate>(text);
      }
    // No need to change MonthOfYearNumeric - this was just a check
    }
    else if (x == PatternFields.none) {
      monthOfYearNumeric = templateValue.month;
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

    if (monthOfYearNumeric > CalendarSystem.iso.getMonthsInYear(2000)) {
      return IParseResult.isoMonthOutOfRange<AnnualDate>(text, monthOfYearNumeric);
    }
    return null;
  }
}
