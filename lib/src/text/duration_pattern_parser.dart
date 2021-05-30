// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/text/patterns/time_machine_patterns.dart';

@internal
class TimePatternParser implements IPatternParser<Time> {
  static final Map</*char*/String, CharacterHandler<Time, _TimeParseBucket>> _patternCharacterHandlers =
  {
    '%': SteppedPatternBuilder.handlePercent /**<Span, SpanParseBucket>*/,
    '\'': SteppedPatternBuilder.handleQuote /**<Span, SpanParseBucket>*/,
    '\"': SteppedPatternBuilder.handleQuote /**<Span, SpanParseBucket>*/,
    '\\': SteppedPatternBuilder.handleBackslash /**<Span, SpanParseBucket>*/,
    '.': TimePatternHelper.createPeriodHandler<Time, _TimeParseBucket>(9, _getPositiveNanosecondOfSecond, (bucket, value) => bucket.addNanoseconds(value)),
    ':': (pattern, builder) => builder.addLiteral1(builder.formatInfo.timeSeparator, IParseResult.timeSeparatorMismatch /**<Span>*/),
    'D': _createDayHandler(),
    'H': _createTotalHandler(PatternFields.hours24, TimeConstants.nanosecondsPerHour, TimeConstants.hoursPerDay, 402653184),
    'h': _createPartialHandler(PatternFields.hours24, TimeConstants.nanosecondsPerHour, TimeConstants.hoursPerDay),
    'M': _createTotalHandler(PatternFields.minutes, TimeConstants.nanosecondsPerMinute, TimeConstants.minutesPerDay, 24159191040),
    'm': _createPartialHandler(PatternFields.minutes, TimeConstants.nanosecondsPerMinute, TimeConstants.minutesPerHour),
    'S': _createTotalHandler(PatternFields.seconds, TimeConstants.nanosecondsPerSecond, TimeConstants.secondsPerDay, 1449551462400),
    's': _createPartialHandler(PatternFields.seconds, TimeConstants.nanosecondsPerSecond, TimeConstants.secondsPerMinute),
    'f': TimePatternHelper.createFractionHandler<Time, _TimeParseBucket>(9, _getPositiveNanosecondOfSecond, (bucket, value) => bucket.addNanoseconds(value)),
    'F': TimePatternHelper.createFractionHandler<Time, _TimeParseBucket>(9, _getPositiveNanosecondOfSecond, (bucket, value) => bucket.addNanoseconds(value)),
    '+': _handlePlus,
    '-': _handleMinus,
  };

  // Note: to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  @override
  IPattern<Time> parsePattern(String patternText, TimeMachineFormatInfo formatInfo) {
    Preconditions.checkNotNull(patternText, 'patternText');
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
        case 'o':
          return TimePatterns.roundtripPatternImpl;
        default:
          throw IInvalidPatternError.format(TextErrorMessages.unknownStandardFormat,[patternText[0], 'Time']);
      }
    }

    var patternBuilder = SteppedPatternBuilder<Time, _TimeParseBucket>(formatInfo,
            () => _TimeParseBucket());
    patternBuilder.parseCustomPattern(patternText, _patternCharacterHandlers);
    // Somewhat random sample, admittedly...
    // dana: todo: why is this? ... how much overhead does this add?
    return patternBuilder.build(Time(hours: 1) + Time(minutes: 30) + Time(seconds: 5) + Time(milliseconds: 500));
  }

  static int _getPositiveNanosecondOfSecond(Time time) {
    return ITime.nanosecondOfDurationDay(time).abs() % TimeConstants.nanosecondsPerSecond;
  }

  static CharacterHandler<Time, _TimeParseBucket> _createTotalHandler
      (PatternFields field, int nanosecondsPerUnit, int unitsPerDay, int maxValue) {
    return (pattern, builder) {
      // Needs to be big enough for 1449551462400 seconds
      int count = pattern.getRepeatCount(13);
      // AddField would throw an inappropriate exception here, so handle it specially.
      if ((builder.usedFields & PatternFields.totalTime).value != 0) {
        throw InvalidPatternError(TextErrorMessages.multipleCapitalSpanFields);
      }
      builder.addField(field, pattern.current);
      builder.addField(PatternFields.totalTime, pattern.current);
      builder.addParseInt64ValueAction(count, 13, pattern.current, 0, maxValue, (bucket, value) => bucket.addUnits(value, nanosecondsPerUnit));
      builder.addFormatAction((Time value, StringBuffer sb) =>
          FormatHelper.leftPadNonNegativeInt64(_getPositiveNanosecondUnits(value, nanosecondsPerUnit, unitsPerDay), count, sb));
    };
  }

  static CharacterHandler<Time, _TimeParseBucket> _createDayHandler() {
    return (pattern, builder) {
      int count = pattern.getRepeatCount(8); // Enough for 16777216
      // AddField would throw an inappropriate exception here, so handle it specially.
      if ((builder.usedFields & PatternFields.totalTime).value != 0) {
        throw InvalidPatternError(TextErrorMessages.multipleCapitalSpanFields);
      }
      builder.addField(PatternFields.dayOfMonth, pattern.current);
      builder.addField(PatternFields.totalTime, pattern.current);
      builder.addParseValueAction(count, 8, pattern.current, 0, 16777216, (bucket, value) => bucket.addDays(value));
      builder.addFormatLeftPad(count, (time) {
        int days = IInstant.trusted(time).epochDay; //time.inDays;
        if (days >= 0) {
          return days;
        }
        // Round towards 0.
        return ITime.nanosecondOfEpochDay(time) == 0 ? -days : -(days + 1);
      },
          assumeNonNegative: true,
          assumeFitsInCount: false);
    };
  }

  static CharacterHandler<Time, _TimeParseBucket> _createPartialHandler
      (PatternFields field, int nanosecondsPerUnit, int unitsPerContainer) {
    return (pattern, builder) {
      int count = pattern.getRepeatCount(2);
      builder.addField(field, pattern.current);
      builder.addParseValueAction(count, 2, pattern.current, 0, unitsPerContainer - 1,
              (bucket, value) => bucket.addUnits(value, nanosecondsPerUnit));
      // This is never used for anything larger than a day, so the day part is irrelevant.
      builder.addFormatLeftPad(count,
              (time) => (((ITime.nanosecondOfDurationDay(time).abs() ~/ nanosecondsPerUnit)) % unitsPerContainer),
          assumeNonNegative: true,
          assumeFitsInCount: count == 2);
    };
  }

  static void _handlePlus(PatternCursor pattern, SteppedPatternBuilder<Time, _TimeParseBucket> builder) {
    builder.addField(PatternFields.sign, pattern.current);
    builder.addRequiredSign((bucket, positive) => bucket.isNegative = !positive, (time) => IInstant.trusted(time).epochDay >= 0);
  }

  static void _handleMinus(PatternCursor pattern, SteppedPatternBuilder<Time, _TimeParseBucket> builder) {
    builder.addField(PatternFields.sign, pattern.current);
    builder.addNegativeOnlySign((bucket, positive) => bucket.isNegative = !positive, (time) => IInstant.trusted(time).epochDay >= 0);
  }

  static int _getPositiveNanosecondUnits(Time time, int nanosecondsPerUnit, int unitsPerDay) {
    // The property is declared as an int, but we it as a long to force 64-bit arithmetic when multiplying.
    int floorDays = IInstant.trusted(time).epochDay;
    if (floorDays >= 0) {
      return floorDays * unitsPerDay + ITime.nanosecondOfEpochDay(time) ~/ nanosecondsPerUnit;
    }
    else {
      int nanosecondOfDay = ITime.nanosecondOfDurationDay(time);
      // If it's not an exact number of days, FloorDays will overshoot (negatively) by 1.
      int negativeValue = nanosecondOfDay == 0
          ? floorDays * unitsPerDay
          : (floorDays + 1) * unitsPerDay + nanosecondOfDay ~/ nanosecondsPerUnit;
      return -negativeValue;
    }
  }
}

/// Provides a container for the interim parsed pieces of an [Offset] value.
class _TimeParseBucket extends ParseBucket<Time> {
  static final BigInt _bigIntegerNanosecondsPerDay = BigInt.from(TimeConstants.nanosecondsPerDay);

  // TODO(optimization): We might want to try to optimize this, but it's *much* simpler to get working reliably this way
  // than to manipulate a real Span.
  bool isNegative = false;
  BigInt _currentNanos = BigInt.zero;

  void addNanoseconds(int nanoseconds) {
    _currentNanos += BigInt.from(nanoseconds);
  }

  void addDays(int days) {
    _currentNanos += BigInt.from(days) * _bigIntegerNanosecondsPerDay;
  }

  void addUnits(int units, int nanosecondsPerUnit) {
    _currentNanos += BigInt.from(units) * BigInt.from(nanosecondsPerUnit);
  }

  /// Calculates the value from the parsed pieces.
  @override
  ParseResult<Time> calculateValue(PatternFields usedFields, String text) {
    if (isNegative) {
      _currentNanos = -_currentNanos;
    }
    if (_currentNanos < ITime.minNanoseconds || _currentNanos > ITime.maxNanoseconds) {
      return IParseResult.forInvalidValuePostParse<Time>(text, TextErrorMessages.overallValueOutOfRange, ['Time']);
    }
    return ParseResult.forValue<Time>(Time.bigIntNanoseconds(_currentNanos));
  }
}
