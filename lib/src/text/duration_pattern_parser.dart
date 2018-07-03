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
  IPattern<Time> parsePattern(String patternText, TimeMachineFormatInfo formatInfo) {
    Preconditions.checkNotNull(patternText, 'patternText');
    if (patternText.length == 0) {
      throw new InvalidPatternError(TextErrorMessages.formatStringEmpty);
    }

    // The sole standard pattern...
    if (patternText.length == 1) {
      switch (patternText[0]) {
        case 'o':
          return TimePatterns.roundtripPatternImpl;
        default:
          throw IInvalidPatternError.format(TextErrorMessages.unknownStandardFormat, [patternText[0], 'Span']);
      }
    }

    var patternBuilder = new SteppedPatternBuilder<Time, _TimeParseBucket>(formatInfo,
            () => new _TimeParseBucket());
    patternBuilder.parseCustomPattern(patternText, _patternCharacterHandlers);
    // Somewhat random sample, admittedly...
    // dana: todo: why is this?
    return patternBuilder.build(new Time(hours: 1) + new Time(minutes: 30) + new Time(seconds: 5) + new Time(milliseconds: 500));
  }

  static int _getPositiveNanosecondOfSecond(Time time) {
    return time.nanosecondOfDay.abs() % TimeConstants.nanosecondsPerSecond;
  }

  static CharacterHandler<Time, _TimeParseBucket> _createTotalHandler
      (PatternFields field, int nanosecondsPerUnit, int unitsPerDay, int maxValue) {
    return (pattern, builder) {
      // Needs to be big enough for 1449551462400 seconds
      int count = pattern.getRepeatCount(13);
      // AddField would throw an inappropriate exception here, so handle it specially.
      if ((builder.usedFields & PatternFields.totalSpan).value != 0) {
        throw new InvalidPatternError(TextErrorMessages.multipleCapitalSpanFields);
      }
      builder.addField(field, pattern.current);
      builder.addField(PatternFields.totalSpan, pattern.current);
      builder.addParseInt64ValueAction(count, 13, pattern.current, 0, maxValue, (bucket, value) => bucket.addUnits(value, nanosecondsPerUnit));
      builder.addFormatAction((Time value, StringBuffer sb) =>
          FormatHelper.leftPadNonNegativeInt64(_getPositiveNanosecondUnits(value, nanosecondsPerUnit, unitsPerDay), count, sb));
    };
  }

  static CharacterHandler<Time, _TimeParseBucket> _createDayHandler() {
    return (pattern, builder) {
      int count = pattern.getRepeatCount(8); // Enough for 16777216
      // AddField would throw an inappropriate exception here, so handle it specially.
      if ((builder.usedFields & PatternFields.totalSpan).value != 0) {
        throw new InvalidPatternError(TextErrorMessages.multipleCapitalSpanFields);
      }
      builder.addField(PatternFields.dayOfMonth, pattern.current);
      builder.addField(PatternFields.totalSpan, pattern.current);
      builder.addParseValueAction(count, 8, pattern.current, 0, 16777216, (bucket, value) => bucket.addDays(value));
      builder.addFormatLeftPad(count, (span) {
        int days = span.floorDays;
        if (days >= 0) {
          return days;
        }
        // Round towards 0.
        return span.nanosecondOfFloorDay == 0 ? -days : -(days + 1);
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
              (span) => (((span.nanosecondOfDay.abs() ~/ nanosecondsPerUnit)) % unitsPerContainer),
          assumeNonNegative: true,
          assumeFitsInCount: count == 2);
    };
  }

  static void _handlePlus(PatternCursor pattern, SteppedPatternBuilder<Time, _TimeParseBucket> builder) {
    builder.addField(PatternFields.sign, pattern.current);
    builder.addRequiredSign((bucket, positive) => bucket.isNegative = !positive, (time) => time.floorDays >= 0);
  }

  static void _handleMinus(PatternCursor pattern, SteppedPatternBuilder<Time, _TimeParseBucket> builder) {
    builder.addField(PatternFields.sign, pattern.current);
    builder.addNegativeOnlySign((bucket, positive) => bucket.isNegative = !positive, (time) => time.floorDays >= 0);
  }

  static int _getPositiveNanosecondUnits(Time time, int nanosecondsPerUnit, int unitsPerDay) {
    // The property is declared as an int, but we it as a long to force 64-bit arithmetic when multiplying.
    int floorDays = time.floorDays;
    if (floorDays >= 0) {
      return floorDays * unitsPerDay + time.nanosecondOfFloorDay ~/ nanosecondsPerUnit;
    }
    else {
      int nanosecondOfDay = time.nanosecondOfDay;
      // If it's not an exact number of days, FloorDays will overshoot (negatively) by 1.
      int negativeValue = nanosecondOfDay == 0
          ? floorDays * unitsPerDay
          : (floorDays + 1) * unitsPerDay + nanosecondOfDay ~/ nanosecondsPerUnit;
      return -negativeValue;
    }
  }
}

// todo: convert int to BigInt for Dart 2.0
/// Provides a container for the interim parsed pieces of an [Offset] value.
class _TimeParseBucket extends ParseBucket<Time> {
  static final /*BigInt*/ int _bigIntegerNanosecondsPerDay = TimeConstants.nanosecondsPerDay;

  // TODO(optimization): We might want to try to optimize this, but it's *much* simpler to get working reliably this way
  // than to manipulate a real Span.
  bool isNegative = false;
  /*BigInt*/ int _currentNanos = 0;

  void addNanoseconds(int nanoseconds) {
    this._currentNanos += nanoseconds;
  }

  void addDays(int days) {
    _currentNanos += days * _bigIntegerNanosecondsPerDay;
  }

  void addUnits(int units, /*BigInt*/ int nanosecondsPerUnit) {
    _currentNanos += units * nanosecondsPerUnit;
  }

  /// Calculates the value from the parsed pieces.
  @override
  ParseResult<Time> calculateValue(PatternFields usedFields, String text) {
    if (isNegative) {
      _currentNanos = -_currentNanos;
    }
    if (_currentNanos < ITime.minNanoseconds || _currentNanos > ITime.maxNanoseconds) {
      return IParseResult.forInvalidValuePostParse<Time>(text, TextErrorMessages.overallValueOutOfRange, ['Span']);
    }
    return ParseResult.forValue<Time>(new Time(nanoseconds: _currentNanos));
  }
}
