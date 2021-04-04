// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/text/time_machine_text.dart';

/// Represents a pattern for parsing and formatting [Period] values.
@immutable
class PeriodPattern implements IPattern<Period> {
  /// Pattern which uses the normal ISO format for all the supported ISO
  /// fields, but extends the time part with 's' for milliseconds, "t" for ticks and "n" for nanoseconds.
  /// No normalization is carried out, and a period may contain weeks as well as years, months and days.
  /// Each element may also be negative, independently of other elements. This pattern round-trips its
  /// values: a parse/format cycle will produce an identical period, including units.
  ///
  /// Pattern which uses the normal ISO format for all the supported ISO
  /// fields, but extends the time part with 's' for milliseconds, "t" for ticks and "n" for nanoseconds.
  static final PeriodPattern roundtrip = PeriodPattern._(_RoundtripPatternImpl());

  /// A 'normalizing' pattern which abides by the ISO-8601 duration format as far as possible.
  /// Weeks are added to the number of days (after multiplying by 7). Time units are normalized
  /// (extending into days where necessary), and fractions of seconds are represented within the
  /// seconds part. Unlike ISO-8601, which pattern allows for negative values within a period.
  ///
  /// todo: investigate this:
  /// Note that normalizing the period when formatting will cause an [OverflowError]
  /// if the period contains more than [System.Int64.MaxValue] ticks when the
  /// combined weeks/days/time portions are considered. Such a period could never
  /// be useful anyway, however.
  static final PeriodPattern normalizingIso = PeriodPattern._(_NormalizingIsoPatternImpl());

  final IPattern<Period> _pattern;

  PeriodPattern._(IPattern<Period> pattern) : _pattern = Preconditions.checkNotNull(pattern, 'pattern');

  /// Parses the given text value according to the rules of this pattern.
  ///
  /// This method never throws an exception (barring a bug in Time Machine itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  ///
  /// * [text]: The text value to parse.
  ///
  /// Returns: The result of parsing, which may be successful or unsuccessful.
  @override
  ParseResult<Period> parse(String text) => _pattern.parse(text);

  /// Formats the given period as text according to the rules of this pattern.
  ///
  /// * [value]: The period to format.
  ///
  /// Returns: The period formatted according to this pattern.
  @override
  String format(Period value) => _pattern.format(value);

  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given [StringBuffer].
  ///
  /// * [value]: The value to format.
  /// * [builder]: The `StringBuffer` to append to.
  ///
  /// Returns: The builder passed in as [builder].
  @override
  StringBuffer appendFormat(Period value, StringBuffer builder) => _pattern.appendFormat(value, builder);

  static void _appendValue(StringBuffer builder, int value, String suffix) {
    // Avoid having a load of conditions in the calling code by checking here
    if (value == 0) {
      return;
    }
    FormatHelper.formatInvariant(value, builder);
    builder.write(suffix);
  }

  static ParseResult<Period> _invalidUnit(ValueCursor cursor, String unitCharacter) =>
      IParseResult.forInvalidValue<Period>(cursor, TextErrorMessages.invalidUnitSpecifier, [unitCharacter]);

  static ParseResult<Period> _repeatedUnit(ValueCursor cursor, String unitCharacter) =>
      IParseResult.forInvalidValue<Period>(cursor, TextErrorMessages.repeatedUnitSpecifier, [unitCharacter]);

  static ParseResult<Period> _misplacedUnit(ValueCursor cursor, String unitCharacter) =>
      IParseResult.forInvalidValue<Period>(cursor, TextErrorMessages.misplacedUnitSpecifier, [unitCharacter]);
}

class _RoundtripPatternImpl implements IPattern<Period> {
  @override
  ParseResult<Period> parse(String? text) {
    if (text == null) {
      return IParseResult.argumentNull<Period>('text');
    }
    if (text.isEmpty) {
      return IParseResult.valueStringEmpty.convertError();
    }

    ValueCursor valueCursor = ValueCursor(text);

    valueCursor.moveNext();
    if (valueCursor.current != 'P') {
      return IParseResult.mismatchedCharacter<Period>(valueCursor, 'P');
    }
    bool inDate = true;
    PeriodBuilder builder = PeriodBuilder();
    PeriodUnits unitsSoFar = PeriodUnits.none;
    while (valueCursor.moveNext()) {
      if (inDate && valueCursor.current == 'T') {
        inDate = false;
        continue;
      }
      var parseResult = valueCursor.parseInt64<Period>('Period');
      if (!parseResult.success) {
        return parseResult.convertError();
      }
      if (valueCursor.length == valueCursor.index) {
        return IParseResult.endOfString<Period>(valueCursor);
      }
      // Various failure cases:
      // - Repeated unit (e.g. P1M2M)
      // - Time unit is in date part (e.g. P5M)
      // - Date unit is in time part (e.g. PT1D)
      // - Unit is in incorrect order (e.g. P5D1Y)
      // - Unit is invalid (e.g. P5J)
      // - Unit is missing (e.g. P5)
      PeriodUnits unit;
      switch (valueCursor.current) {
        case 'Y':
          unit = PeriodUnits.years;
          break;
        case 'M':
          unit = inDate ? PeriodUnits.months : PeriodUnits.minutes;
          break;
        case 'W':
          unit = PeriodUnits.weeks;
          break;
        case 'D':
          unit = PeriodUnits.days;
          break;
        case 'H':
          unit = PeriodUnits.hours;
          break;
        case 'S':
          unit = PeriodUnits.seconds;
          break;
        case 's':
          unit = PeriodUnits.milliseconds;
          break;
        case 't':
          unit = PeriodUnits.microseconds;
          break;
        case 'n':
          unit = PeriodUnits.nanoseconds;
          break;
        default:
          return PeriodPattern._invalidUnit(valueCursor, valueCursor.current);
      }
      if ((unit & unitsSoFar).value != 0) {
        return PeriodPattern._repeatedUnit(valueCursor, valueCursor.current);
      }

      // This handles putting months before years, for example. Less significant units
      // have higher integer representations.
      if (unit < unitsSoFar) {
        return PeriodPattern._misplacedUnit(valueCursor, valueCursor.current);
      }
      // The result of checking "there aren't any time units in this unit" should be
      // equal to "we're still in the date part".
      if (((unit & PeriodUnits.allTimeUnits).value == 0) != inDate) {
        return PeriodPattern._misplacedUnit(valueCursor, valueCursor.current);
      }
      builder[unit] = parseResult.value;
      unitsSoFar |= unit;
    }
    return ParseResult.forValue<Period>(builder.build());
  }

  @override
  String format(Period value) => appendFormat(value, StringBuffer()).toString();

  @override
  StringBuffer appendFormat(Period value, StringBuffer builder) {
    Preconditions.checkNotNull(value, 'value');
    Preconditions.checkNotNull(builder, 'builder');
    builder.write('P');
    PeriodPattern._appendValue(builder, value.years, 'Y');
    PeriodPattern._appendValue(builder, value.months, 'M');
    PeriodPattern._appendValue(builder, value.weeks, 'W');
    PeriodPattern._appendValue(builder, value.days, 'D');
    if (value.hasTimeComponent) {
      builder.write('T');
      PeriodPattern._appendValue(builder, value.hours, 'H');
      PeriodPattern._appendValue(builder, value.minutes, 'M');
      PeriodPattern._appendValue(builder, value.seconds, 'S');
      PeriodPattern._appendValue(builder, value.milliseconds, 's');
      PeriodPattern._appendValue(builder, value.microseconds, 't');
      PeriodPattern._appendValue(builder, value.nanoseconds, 'n');
    }
    return builder;
  }
}

class _NormalizingIsoPatternImpl implements IPattern<Period> {
  // TODO(misc): Tidy this up a *lot*.
  @override
  ParseResult<Period> parse(String? text) {
    if (text == null) {
      return IParseResult.argumentNull<Period>('text');
    }
    if (text.isEmpty) {
      return IParseResult.valueStringEmpty.convertError();
    }

    ValueCursor valueCursor = ValueCursor(text);

    valueCursor.moveNext();
    if (valueCursor.current != 'P') {
      return IParseResult.mismatchedCharacter<Period>(valueCursor, 'P');
    }
    bool inDate = true;
    PeriodBuilder builder = PeriodBuilder();
    PeriodUnits unitsSoFar = PeriodUnits.none;
    while (valueCursor.moveNext()) {
      if (inDate && valueCursor.current == 'T') {
        inDate = false;
        continue;
      }
      bool negative = valueCursor.current == '-';
      var parseResult = valueCursor.parseInt64<Period>('Period');
      if (!parseResult.success) {
        return parseResult.convertError();
      }
      if (valueCursor.length == valueCursor.index) {
        return IParseResult.endOfString<Period>(valueCursor);
      }
      // Various failure cases:
      // - Repeated unit (e.g. P1M2M)
      // - Time unit is in date part (e.g. P5M)
      // - Date unit is in time part (e.g. PT1D)
      // - Unit is in incorrect order (e.g. P5D1Y)
      // - Unit is invalid (e.g. P5J)
      // - Unit is missing (e.g. P5)
      PeriodUnits unit;
      switch (valueCursor.current) {
        case 'Y':
          unit = PeriodUnits.years;
          break;
        case 'M':
          unit = inDate ? PeriodUnits.months : PeriodUnits.minutes;
          break;
        case 'W':
          unit = PeriodUnits.weeks;
          break;
        case 'D':
          unit = PeriodUnits.days;
          break;
        case 'H':
          unit = PeriodUnits.hours;
          break;
        case 'S':
          unit = PeriodUnits.seconds;
          break;
        case ',':
        case '.':
          unit = PeriodUnits.nanoseconds;
          break; // Special handling below
        default:
          return PeriodPattern._invalidUnit(valueCursor, valueCursor.current);
      }
      if ((unit.value & unitsSoFar.value) != 0) {
        return PeriodPattern._repeatedUnit(valueCursor, valueCursor.current);
      }

      // This handles putting months before years, for example. Less significant units
      // have higher integer representations.
      if (unit < unitsSoFar) {
        return PeriodPattern._misplacedUnit(valueCursor, valueCursor.current);
      }

      // The result of checking "there aren't any time units in this unit" should be
      // equal to "we're still in the date part".
      if (((unit.value & PeriodUnits.allTimeUnits.value) == 0) != inDate) {
        return PeriodPattern._misplacedUnit(valueCursor, valueCursor.current);
      }

      // Seen a . or , which need special handling.
      if (unit == PeriodUnits.nanoseconds) {
        // Check for already having seen seconds, e.g. PT5S0.5
        if ((unitsSoFar & PeriodUnits.seconds).value != 0) {
          return PeriodPattern._misplacedUnit(valueCursor, valueCursor.current);
        }
        builder.seconds = parseResult.value;

        if (!valueCursor.moveNext()) {
          return IParseResult.missingNumber<Period>(valueCursor);
        }
        int? totalNanoseconds = valueCursor.parseFraction(9, 9, 1);
        // Can cope with at most 999999999 nanoseconds
        if (totalNanoseconds == null) {
          return IParseResult.missingNumber<Period>(valueCursor);
        }
        // Use whether or not the seconds value was negative (even if 0)
        // as the indication of whether this value is negative.
        if (negative) {
          totalNanoseconds = -totalNanoseconds;
        }
        builder.milliseconds = arithmeticMod(totalNanoseconds ~/ TimeConstants.nanosecondsPerMillisecond, TimeConstants.millisecondsPerSecond);
        builder.microseconds = arithmeticMod(totalNanoseconds ~/ TimeConstants.nanosecondsPerMicrosecond, TimeConstants.microsecondsPerMillisecond);
        builder.nanoseconds = arithmeticMod(totalNanoseconds, TimeConstants.nanosecondsPerMicrosecond);

        if (valueCursor.current != 'S') {
          return IParseResult.mismatchedCharacter<Period>(valueCursor, 'S');
        }
        if (valueCursor.moveNext()) {
          return IParseResult.expectedEndOfString<Period>(valueCursor);
        }
        return ParseResult.forValue<Period>(builder.build());
      }

      builder[unit] = parseResult.value;
      unitsSoFar |= unit;
    }
    if (unitsSoFar.value == 0) {
      return IParseResult.forInvalidValue<Period>(valueCursor, TextErrorMessages.emptyPeriod);
    }
    return ParseResult.forValue<Period>(builder.build());
  }

  @override
  String format(Period value) => appendFormat(value, StringBuffer()).toString();

  @override
  StringBuffer appendFormat(Period value, StringBuffer builder) {
    Preconditions.checkNotNull(value, 'value');
    Preconditions.checkNotNull(builder, 'builder');
    value = value.normalize();
    // Always ensure we've got *some* unit; arbitrarily pick days.
    if (value.equals(Period.zero)) {
      builder.write('P0D');
      return builder;
    }
    builder.write('P');
    PeriodPattern._appendValue(builder, value.years, 'Y');
    PeriodPattern._appendValue(builder, value.months, 'M');
    PeriodPattern._appendValue(builder, value.weeks, 'W');
    PeriodPattern._appendValue(builder, value.days, 'D');
    if (value.hasTimeComponent) {
      builder.write('T');
      PeriodPattern._appendValue(builder, value.hours, 'H');
      PeriodPattern._appendValue(builder, value.minutes, 'M');
      int nanoseconds = value.milliseconds * TimeConstants.nanosecondsPerMillisecond + value.microseconds * TimeConstants.nanosecondsPerMicrosecond + value.nanoseconds;
      int seconds = value.seconds;
      if (nanoseconds != 0 || seconds != 0) {
        if (nanoseconds < 0 || seconds < 0) {
          builder.write('-');
          nanoseconds = -nanoseconds;
          seconds = -seconds;
        }
        FormatHelper.formatInvariant(seconds, builder);
        if (nanoseconds != 0) {
          builder.write('.');
          FormatHelper.appendFractionTruncate(nanoseconds, 9, 9, builder);
        }
        builder.write('S');
      }
    }
    return builder;
  }
}
