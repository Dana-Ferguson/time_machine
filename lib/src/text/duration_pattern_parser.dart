// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Text/DurationPatternParser.cs
// e81483f  on Sep 15, 2017
import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';

@internal /*sealed*/ class SpanPatternParser implements IPatternParser<Span> {
  @private static final Map</*char*/String, CharacterHandler<Span, SpanParseBucket>> PatternCharacterHandlers =
  {
    '%': SteppedPatternBuilder.HandlePercent /**<Span, SpanParseBucket>*/,
    '\'': SteppedPatternBuilder.HandleQuote /**<Span, SpanParseBucket>*/,
    '\"': SteppedPatternBuilder.HandleQuote /**<Span, SpanParseBucket>*/,
    '\\': SteppedPatternBuilder.HandleBackslash /**<Span, SpanParseBucket>*/,
    '.': TimePatternHelper.CreatePeriodHandler<Span, SpanParseBucket>(9, GetPositiveNanosecondOfSecond, (bucket, value) => bucket.AddNanoseconds(value)),
    ':': (pattern, builder) => builder.AddLiteral1(builder.FormatInfo.TimeSeparator, ParseResult.TimeSeparatorMismatch /**<Span>*/),
    'D': CreateDayHandler(),
    'H': CreateTotalHandler(PatternFields.hours24, TimeConstants.nanosecondsPerHour, TimeConstants.hoursPerDay, 402653184),
    'h': CreatePartialHandler(PatternFields.hours24, TimeConstants.nanosecondsPerHour, TimeConstants.hoursPerDay),
    'M': CreateTotalHandler(PatternFields.minutes, TimeConstants.nanosecondsPerMinute, TimeConstants.minutesPerDay, 24159191040),
    'm': CreatePartialHandler(PatternFields.minutes, TimeConstants.nanosecondsPerMinute, TimeConstants.minutesPerHour),
    'S': CreateTotalHandler(PatternFields.seconds, TimeConstants.nanosecondsPerSecond, TimeConstants.secondsPerDay, 1449551462400),
    's': CreatePartialHandler(PatternFields.seconds, TimeConstants.nanosecondsPerSecond, TimeConstants.secondsPerMinute),
    'f': TimePatternHelper.CreateFractionHandler<Span, SpanParseBucket>(9, GetPositiveNanosecondOfSecond, (bucket, value) => bucket.AddNanoseconds(value)),
    'F': TimePatternHelper.CreateFractionHandler<Span, SpanParseBucket>(9, GetPositiveNanosecondOfSecond, (bucket, value) => bucket.AddNanoseconds(value)),
    '+': HandlePlus,
    '-': HandleMinus,
  };

  // Note: to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  IPattern<Span> ParsePattern(String patternText, NodaFormatInfo formatInfo) {
    Preconditions.checkNotNull(patternText, 'patternText');
    if (patternText.length == 0) {
      throw new InvalidPatternError(TextErrorMessages.FormatStringEmpty);
    }

    // The sole standard pattern...
    if (patternText.length == 1) {
      switch (patternText[0]) {
        case 'o':
          return SpanPatterns.RoundtripPatternImpl;
        default:
          throw new InvalidPatternError.format(TextErrorMessages.UnknownStandardFormat, [patternText[0], 'Span']);
      }
    }

    var patternBuilder = new SteppedPatternBuilder<Span, SpanParseBucket>(formatInfo,
            () => new SpanParseBucket());
    patternBuilder.ParseCustomPattern(patternText, PatternCharacterHandlers);
    // Somewhat random sample, admittedly...
    // dana: todo: why is this?
    return patternBuilder.Build(new Span(hours: 1) + new Span(minutes: 30) + new Span(seconds: 5) + new Span(milliseconds: 500));
  }

  @private static int GetPositiveNanosecondOfSecond(Span Span) {
    return ((Span.nanosecondOfDay) % TimeConstants.nanosecondsPerSecond).abs();
  }

  @private static CharacterHandler<Span, SpanParseBucket> CreateTotalHandler
      (PatternFields field, int nanosecondsPerUnit, int unitsPerDay, int maxValue) {
    return (pattern, builder) {
      // Needs to be big enough for 1449551462400 seconds
      int count = pattern.GetRepeatCount(13);
      // AddField would throw an inappropriate exception here, so handle it specially.
      if ((builder.UsedFields & PatternFields.totalSpan).value != 0) {
        throw new InvalidPatternError(TextErrorMessages.MultipleCapitalSpanFields);
      }
      builder.AddField(field, pattern.Current);
      builder.AddField(PatternFields.totalSpan, pattern.Current);
      builder.AddParseInt64ValueAction(count, 13, pattern.Current, 0, maxValue, (bucket, value) => bucket.AddUnits(value, nanosecondsPerUnit));
      builder.AddFormatAction((value, sb) =>
          FormatHelper.LeftPadNonNegativeInt64(GetPositiveNanosecondUnits(value, nanosecondsPerUnit, unitsPerDay), count, sb));
    };
  }

  @private static CharacterHandler<Span, SpanParseBucket> CreateDayHandler() {
    return (pattern, builder) {
      int count = pattern.GetRepeatCount(8); // Enough for 16777216
      // AddField would throw an inappropriate exception here, so handle it specially.
      if ((builder.UsedFields & PatternFields.totalSpan).value != 0) {
        throw new InvalidPatternError(TextErrorMessages.MultipleCapitalSpanFields);
      }
      builder.AddField(PatternFields.dayOfMonth, pattern.Current);
      builder.AddField(PatternFields.totalSpan, pattern.Current);
      builder.AddParseValueAction(count, 8, pattern.Current, 0, 16777216, (bucket, value) => bucket.AddDays(value));
      builder.AddFormatLeftPad(count, (Span) {
        int days = Span.floorDays;
        if (days >= 0) {
          return days;
        }
        // Round towards 0.
        return Span.nanosecondOfFloorDay == 0 ? -days : -(days + 1);
      },
          assumeNonNegative: true,
          assumeFitsInCount: false);
    };
  }

  @private static CharacterHandler<Span, SpanParseBucket> CreatePartialHandler
      (PatternFields field, int nanosecondsPerUnit, int unitsPerContainer) {
    return (pattern, builder) {
      int count = pattern.GetRepeatCount(2);
      builder.AddField(field, pattern.Current);
      builder.AddParseValueAction(count, 2, pattern.Current, 0, unitsPerContainer - 1,
              (bucket, value) => bucket.AddUnits(value, nanosecondsPerUnit));
      // This is never used for anything larger than a day, so the day part is irrelevant.
      builder.AddFormatLeftPad(count,
              (Span) => (((Span.nanosecondOfDay.abs() ~/ nanosecondsPerUnit)) % unitsPerContainer),
          assumeNonNegative: true,
          assumeFitsInCount: count == 2);
    };
  }

  @private static void HandlePlus(PatternCursor pattern, SteppedPatternBuilder<Span, SpanParseBucket> builder) {
    builder.AddField(PatternFields.sign, pattern.Current);
    builder.AddRequiredSign((bucket, positive) => bucket.IsNegative = !positive, (Span) => Span.floorDays >= 0);
  }

  @private static void HandleMinus(PatternCursor pattern, SteppedPatternBuilder<Span, SpanParseBucket> builder) {
    builder.AddField(PatternFields.sign, pattern.Current);
    builder.AddNegativeOnlySign((bucket, positive) => bucket.IsNegative = !positive, (Span) => Span.floorDays >= 0);
  }

  @private static int GetPositiveNanosecondUnits(Span Span, int nanosecondsPerUnit, int unitsPerDay) {
    // The property is declared as an int, but we it as a long to force 64-bit arithmetic when multiplying.
    int floorDays = Span.floorDays;
    if (floorDays >= 0) {
      return floorDays * unitsPerDay + Span.nanosecondOfFloorDay ~/ nanosecondsPerUnit;
    }
    else {
      int nanosecondOfDay = Span.nanosecondOfDay;
      // If it's not an exact number of days, FloorDays will overshoot (negatively) by 1.
      int negativeValue = nanosecondOfDay == 0
          ? floorDays * unitsPerDay
          : (floorDays + 1) * unitsPerDay + nanosecondOfDay / nanosecondsPerUnit;
      return -negativeValue;
    }
  }
}

// todo: convert int to BigInt for Dart 2.0
/// Provides a container for the interim parsed pieces of an <see cref="Offset" /> value.
@private /*sealed*/ class SpanParseBucket extends ParseBucket<Span> {
  @private static final /*BigInt*/ int BigIntegerNanosecondsPerDay = TimeConstants.nanosecondsPerDay;

  // TODO(optimization): We might want to try to optimize this, but it's *much* simpler to get working reliably this way
  // than to manipulate a real Span.
  @internal bool IsNegative;
  @private /*BigInt*/ int currentNanos;

  @internal void AddNanoseconds(int nanoseconds) {
    this.currentNanos += nanoseconds;
  }

  @internal void AddDays(int days) {
    currentNanos += days * BigIntegerNanosecondsPerDay;
  }

  @internal void AddUnits(int units, /*BigInt*/ int nanosecondsPerUnit) {
    currentNanos += units * nanosecondsPerUnit;
  }

  /// Calculates the value from the parsed pieces.
  @internal
  @override
  ParseResult<Span> CalculateValue(PatternFields usedFields, String text) {
    if (IsNegative) {
      currentNanos = -currentNanos;
    }
    if (currentNanos < Span.minNanoseconds || currentNanos > Span.maxNanoseconds) {
      return ParseResult.ForInvalidValuePostParse<Span>(text, TextErrorMessages.OverallValueOutOfRange, ['Span']);
    }
    return ParseResult.ForValue<Span>(new Span(nanoseconds: currentNanos));
  }
}