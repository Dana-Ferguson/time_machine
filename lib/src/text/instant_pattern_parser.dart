// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/text/patterns/time_machine_patterns.dart';

/// Pattern parsing support for [Instant].
///
/// Supported standard patterns:
///  * g: general; the UTC ISO-8601 instant in the style uuuu-MM-ddTHH:mm:ssZ
@internal
class InstantPatternParser implements IPatternParser<Instant> {
  static const String generalPatternText = "uuuu'-'MM'-'dd'T'HH':'mm':'ss'Z'";
  static const String beforeMinValueText = 'StartOfTime';
  static const String afterMaxValueText = 'EndOfTime';

  @override
  IPattern<Instant> parsePattern(String patternText, TimeMachineFormatInfo formatInfo) {
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
        case 'g':
          patternText = generalPatternText;
          break;
        default:
          throw IInvalidPatternError.format(TextErrorMessages.unknownStandardFormat,[patternText[0], 'Instant']);
      }
    }

    IPattern<LocalDateTime> localResult = formatInfo.localDateTimePatternParser.parsePattern(patternText);
    return _LocalDateTimePatternAdapter(localResult);
  }
}

// This not only converts between LocalDateTime and Instant; it also handles infinity.
class _LocalDateTimePatternAdapter implements IPattern<Instant> {
  final IPattern<LocalDateTime> _pattern;

  _LocalDateTimePatternAdapter(this._pattern);

  @override
  String format(Instant value) =>
  // We don't need to be able to parse before-min/after-max values, but it's convenient to be
  // able to format them - mostly for the sake of testing (but also for ZoneInterval).
  value.isValid ? _pattern.format(value
      .inUtc()
      .localDateTime)
      : value == IInstant.beforeMinValue ? InstantPatternParser.beforeMinValueText
      : InstantPatternParser.afterMaxValueText;

  @override
  StringBuffer appendFormat(Instant value, StringBuffer builder) =>
      _pattern.appendFormat(value
          .inUtc()
          .localDateTime, builder);

  @override
  ParseResult<Instant> parse(String text) =>
      _pattern
          .parse(text)
          .convert((local) => IInstant.trusted(Time(days: local.calendarDate.epochDay, nanoseconds: local.clockTime.timeSinceMidnight.inNanoseconds)));
}


