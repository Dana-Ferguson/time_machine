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
/// <list type="bullet">
///   <item><description>g: general; the UTC ISO-8601 instant in the style uuuu-MM-ddTHH:mm:ssZ</description></item>
/// </list>
@internal /*sealed*/ class InstantPatternParser implements IPatternParser<Instant> {
  @private static const String GeneralPatternText = "uuuu'-'MM'-'dd'T'HH':'mm':'ss'Z'";
  @internal static const String BeforeMinValueText = "StartOfTime";
  @internal static const String AfterMaxValueText = "EndOfTime";

  IPattern<Instant> ParsePattern(String patternText, NodaFormatInfo formatInfo) {
    Preconditions.checkNotNull(patternText, 'patternText');
    if (patternText.length == 0) {
      throw new InvalidPatternError(TextErrorMessages.FormatStringEmpty);
    }
    if (patternText.length == 1) {
      switch (patternText) {
        case "g": // Simplest way of handling the general pattern...
          patternText = GeneralPatternText;
          break;
        default:
          throw new InvalidPatternError.format(TextErrorMessages.UnknownStandardFormat, [patternText, 'Instant']);
      }
    }

    IPattern<LocalDateTime> localResult = formatInfo.localDateTimePatternParser.ParsePattern(patternText);
    return new LocalDateTimePatternAdapter(localResult);
  }
}

// This not only converts between LocalDateTime and Instant; it also handles infinity.
@private /*sealed*/ class LocalDateTimePatternAdapter implements IPattern<Instant> {
  @private final IPattern<LocalDateTime> pattern;

  @internal LocalDateTimePatternAdapter(this.pattern);

  String Format(Instant value) =>
  // We don't need to be able to parse before-min/after-max values, but it's convenient to be
  // able to format them - mostly for the sake of testing (but also for ZoneInterval).
  value.IsValid ? pattern.Format(value
      .inUtc()
      .localDateTime)
      : value == Instant.beforeMinValue ? InstantPatternParser.BeforeMinValueText
      : InstantPatternParser.AfterMaxValueText;

  StringBuffer AppendFormat(Instant value, StringBuffer builder) =>
      pattern.AppendFormat(value
          .inUtc()
          .localDateTime, builder);

  ParseResult<Instant> Parse(String text) =>
      pattern.Parse(text).Convert((local) => new Instant.trusted(new Span(days: local.date.daysSinceEpoch, nanoseconds: local.NanosecondOfDay))

      );
}


