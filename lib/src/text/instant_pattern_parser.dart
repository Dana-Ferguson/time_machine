// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';

/// Pattern parsing support for [Instant].
///
/// Supported standard patterns:
///  * g: general; the UTC ISO-8601 instant in the style uuuu-MM-ddTHH:mm:ssZ
@internal /*sealed*/ class InstantPatternParser implements IPatternParser<Instant> {
  @private static const String _generalPatternText = "uuuu'-'MM'-'dd'T'HH':'mm':'ss'Z'";
  static const String beforeMinValueText = "StartOfTime";
  static const String afterMaxValueText = "EndOfTime";

  IPattern<Instant> parsePattern(String patternText, TimeMachineFormatInfo formatInfo) {
    Preconditions.checkNotNull(patternText, 'patternText');
    if (patternText.length == 0) {
      throw new InvalidPatternError(TextErrorMessages.formatStringEmpty);
    }
    if (patternText.length == 1) {
      switch (patternText) {
        case "g": // Simplest way of handling the general pattern...
          patternText = _generalPatternText;
          break;
        default:
          throw new InvalidPatternError.format(TextErrorMessages.unknownStandardFormat, [patternText, 'Instant']);
      }
    }

    IPattern<LocalDateTime> localResult = formatInfo.localDateTimePatternParser.parsePattern(patternText);
    return new _LocalDateTimePatternAdapter(localResult);
  }
}

// This not only converts between LocalDateTime and Instant; it also handles infinity.
/*sealed*/ class _LocalDateTimePatternAdapter implements IPattern<Instant> {
  final IPattern<LocalDateTime> _pattern;

  _LocalDateTimePatternAdapter(this._pattern);

  String format(Instant value) =>
  // We don't need to be able to parse before-min/after-max values, but it's convenient to be
  // able to format them - mostly for the sake of testing (but also for ZoneInterval).
  value.isValid ? _pattern.format(value
      .inUtc()
      .localDateTime)
      : value == Instant.beforeMinValue ? InstantPatternParser.beforeMinValueText
      : InstantPatternParser.afterMaxValueText;

  StringBuffer appendFormat(Instant value, StringBuffer builder) =>
      _pattern.appendFormat(value
          .inUtc()
          .localDateTime, builder);

  ParseResult<Instant> parse(String text) =>
      _pattern
          .parse(text)
          .convert((local) => new Instant.trusted(new Span(days: local.date.daysSinceEpoch, nanoseconds: local.nanosecondOfDay)));
}


