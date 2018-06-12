// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';

// Nested class for ease of type initialization
@internal abstract class SpanPatterns
{
  @internal static final SpanPattern RoundtripPatternImpl = SpanPattern.CreateWithInvariantCulture("-D:hh:mm:ss.FFFFFFFFF");
}

/// Represents a pattern for parsing and formatting [Span] values.
///
/// <threadsafety>
/// When used with a read-only [CultureInfo], this type is immutable and instances
/// may be shared freely between threads. We recommend only using read-only cultures for patterns, although this is
/// not currently enforced.
/// </threadsafety>
@immutable // Well, assuming an immutable culture...
/*sealed*/ class SpanPattern implements IPattern<Span> {
  /// Gets the general pattern for Spans using the invariant culture, with a format string of "-D:hh:mm:ss.FFFFFFFFF".
  /// This pattern round-trips.
  static SpanPattern get Roundtrip => SpanPatterns.RoundtripPatternImpl;

  @internal static final PatternBclSupport<Span> BclSupport = new PatternBclSupport<Span>("o", (fi) => fi.spanPatternParser);

  @private final IPattern<Span> pattern;

  /// Gets the pattern text for this pattern, as supplied on creation.
  final String PatternText;

  @private SpanPattern(this.PatternText, this.pattern);

  /// Parses the given text value according to the rules of this pattern.
  ///
  /// This method never throws an exception (barring a bug in Time Machine itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  ///
  /// [text]: The text value to parse.
  /// Returns: The result of parsing, which may be successful or unsuccessful.
  ParseResult<Span> Parse(String text) => pattern.Parse(text);

  /// Formats the given Span as text according to the rules of this pattern.
  ///
  /// [value]: The Span to format.
  /// Returns: The Span formatted according to this pattern.
  String Format(Span value) => pattern.Format(value);

  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given [StringBuilder].
  ///
  /// [value]: The value to format.
  /// [builder]: The `StringBuilder` to append to.
  /// Returns: The builder passed in as [builder].
  StringBuffer AppendFormat(Span value, StringBuffer builder) => pattern.AppendFormat(value, builder);

  /// Creates a pattern for the given pattern text and format info.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [formatInfo]: Localization information
  /// Returns: A pattern for parsing and formatting offsets.
  /// [InvalidPatternException]: The pattern text was invalid.
  @private static SpanPattern Create(String patternText, TimeMachineFormatInfo formatInfo) {
    Preconditions.checkNotNull(patternText, 'patternTex');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    var pattern = formatInfo.spanPatternParser.ParsePattern(patternText);
    return new SpanPattern(patternText, pattern);
  }

  /// Creates a pattern for the given pattern text and culture.
  ///
  /// See the user guide for the available pattern text options.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [cultureInfo]: The culture to use in the pattern
  /// Returns: A pattern for parsing and formatting offsets.
  /// [InvalidPatternException]: The pattern text was invalid.
  static SpanPattern Create2(String patternText, CultureInfo cultureInfo) =>
      Create(patternText, TimeMachineFormatInfo.getFormatInfo(cultureInfo));

  /// Creates a pattern for the given pattern text in the current thread's current culture.
  ///
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// Returns: A pattern for parsing and formatting offsets.
  /// [InvalidPatternException]: The pattern text was invalid.
  static SpanPattern CreateWithCurrentCulture(String patternText) =>
      Create(patternText, TimeMachineFormatInfo.currentInfo);

  /// Creates a pattern for the given pattern text in the invariant culture.
  ///
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// Returns: A pattern for parsing and formatting offsets.
  /// [InvalidPatternException]: The pattern text was invalid.
  static SpanPattern CreateWithInvariantCulture(String patternText) =>
      Create(patternText, TimeMachineFormatInfo.invariantInfo);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  ///
  /// [cultureInfo]: The culture to use in the new pattern.
  /// Returns: A new pattern with the given culture.
  SpanPattern WithCulture(CultureInfo cultureInfo) =>
      Create(PatternText, TimeMachineFormatInfo.getFormatInfo(cultureInfo));
}
