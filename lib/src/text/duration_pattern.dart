// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

// Nested class for ease of type initialization
@internal
abstract class TimePatterns {
  static final TimePattern roundtripPatternImpl = TimePattern.createWithInvariantCulture('-D:hh:mm:ss.FFFFFFFFF');
  static String format(Time time, String? patternText, Culture? culture) =>
      TimeMachineFormatInfo
        .getInstance(culture)
        .timePatternParser
        .parsePattern(patternText ?? roundtripPatternImpl.patternText)
        .format(time);
}

/// Represents a pattern for parsing and formatting [Time] values.
@immutable
class TimePattern implements IPattern<Time> {
  /// Gets the general pattern for Spans using the invariant culture, with a format string of '-D:hh:mm:ss.FFFFFFFFF'.
  /// This pattern round-trips.
  static TimePattern get roundtrip => TimePatterns.roundtripPatternImpl;

  final IPattern<Time> _pattern;

  /// Gets the pattern text for this pattern, as supplied on creation.
  final String patternText;

  const TimePattern._(this.patternText, this._pattern);

  /// Parses the given text value according to the rules of this pattern.
  ///
  /// This method never throws an exception (barring a bug in Time Machine itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  ///
  /// * [text]: The text value to parse.
  ///
  /// Returns: The result of parsing, which may be successful or unsuccessful.
  @override
  ParseResult<Time> parse(String text) => _pattern.parse(text);

  /// Formats the given Span as text according to the rules of this pattern.
  ///
  /// * [value]: The Span to format.
  ///
  /// Returns: The Span formatted according to this pattern.
  @override
  String format(Time value) => _pattern.format(value);

  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given [StringBuilder].
  ///
  /// * [value]: The value to format.
  /// * [builder]: The [StringBuffer] to append to.
  ///
  /// Returns: The builder passed in as [builder].
  @override
  StringBuffer appendFormat(Time value, StringBuffer builder) => _pattern.appendFormat(value, builder);

  // todo: should this be internal, or should all the other *_pattern classes creates' be private
  /// Creates a pattern for the given pattern text and format info.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  /// * [formatInfo]: Localization information
  ///
  /// Returns: A pattern for parsing and formatting offsets.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static TimePattern _create(String patternText, TimeMachineFormatInfo formatInfo) {
    Preconditions.checkNotNull(patternText, 'patternText');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    var pattern = formatInfo.timePatternParser.parsePattern(patternText);
    return TimePattern._(patternText, pattern);
  }

  /// Creates a pattern for the given pattern text and culture.
  ///
  /// todo: we need one
  /// See the user guide for the available pattern text options.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  /// * [culture]: The culture to use in the pattern
  ///
  /// Returns: A pattern for parsing and formatting offsets.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static TimePattern createWithCulture(String patternText, Culture culture) =>
      _create(patternText, TimeMachineFormatInfo.getFormatInfo(culture));

  /// Creates a pattern for the given pattern text in the current thread's current culture.
  ///
  /// todo: we need one
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  ///
  /// Returns: A pattern for parsing and formatting offsets.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static TimePattern createWithCurrentCulture(String patternText) =>
      _create(patternText, TimeMachineFormatInfo.currentInfo);

  /// Creates a pattern for the given pattern text in the invariant culture.
  ///
  /// todo: we need one
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  ///
  /// Returns: A pattern for parsing and formatting offsets.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static TimePattern createWithInvariantCulture(String patternText) =>
      _create(patternText, TimeMachineFormatInfo.invariantInfo);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  ///
  /// * [culture]: The culture to use in the new pattern.
  ///
  /// Returns: A new pattern with the given culture.
  TimePattern withCulture(Culture culture) =>
      _create(patternText, TimeMachineFormatInfo.getFormatInfo(culture));
}
