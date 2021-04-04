// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

@internal
abstract class InstantPatterns {
  /// Class whose existence is solely to avoid type initialization order issues, most of which stem
  /// from needing NodaFormatInfo.InvariantInfo...
  static final InstantPattern extendedIsoPatternImpl = InstantPattern.createWithInvariantCulture("uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFF'Z'");
  static final InstantPattern generalPatternImpl = InstantPattern.createWithInvariantCulture("uuuu-MM-ddTHH:mm:ss'Z'");

  static IPattern<Instant> patternOf(InstantPattern instantPattern) => instantPattern._pattern;

  static String format(Instant instant, String? patternText, Culture? culture) =>
      TimeMachineFormatInfo
          .getInstance(culture)
          .instantPatternParser
          .parsePattern(patternText ?? InstantPatternParser.generalPatternText)
          .format(instant);
}

/// Represents a pattern for parsing and formatting [Instant] values.
@immutable
class InstantPattern implements IPattern<Instant> {
  /// Gets the general pattern, which always uses an invariant culture. The general pattern represents
  /// an instant as a UTC date/time in ISO-8601 style "uuuu-MM-ddTHH:mm:ss'Z'".
  static InstantPattern get general => InstantPatterns.generalPatternImpl;

  /// Gets an invariant instant pattern which is ISO-8601 compatible, providing up to 9 decimal places
  /// of sub-second accuracy. (These digits are omitted when unnecessary.)
  /// This corresponds to the text pattern "uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFF'Z'".
  static InstantPattern get extendedIso => InstantPatterns.extendedIsoPatternImpl;

  // ignore: unused_field
  static const String _defaultFormatPattern = 'g';

  final IPattern<Instant> _pattern;

  /// Gets the pattern text for this pattern, as supplied on creation.
  final String patternText;

  const InstantPattern._(this.patternText, this._pattern);

  /// Parses the given text value according to the rules of this pattern.
  ///
  /// This method never throws an exception (barring a bug in Time Machine itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  ///
  /// * [text]: The text value to parse.
  ///
  /// Returns: The result of parsing, which may be successful or unsuccessful.
  @override
  ParseResult<Instant> parse(String text) => _pattern.parse(text);

  /// Formats the given instant as text according to the rules of this pattern.
  ///
  /// * [value]: The instant to format.
  ///
  /// Returns: The instant formatted according to this pattern.
  @override
  String format(Instant value) => _pattern.format(value);

  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given [StringBuilder].
  ///
  /// * [value]: The value to format.
  /// * [builder]: The `StringBuffer` to append to.
  ///
  /// Returns: The builder passed in as [builder].
  @override
  StringBuffer appendFormat(Instant value, StringBuffer builder) => _pattern.appendFormat(value, builder);

  /// Creates a pattern for the given pattern text and format info.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  /// * [formatInfo]: The format info to use in the pattern
  ///
  /// Returns: A pattern for parsing and formatting instants.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static InstantPattern _create(String patternText, TimeMachineFormatInfo formatInfo) {
    Preconditions.checkNotNull(patternText, 'patternText');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    var pattern = formatInfo.instantPatternParser.parsePattern(patternText);
    return InstantPattern._(patternText, pattern);
  }

  /// Creates a pattern for the given pattern text and culture.
  ///
  /// todo: we need one
  /// See the user guide for the available pattern text options.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  /// * [culture]: The culture to use in the pattern
  ///
  /// Returns: A pattern for parsing and formatting instants.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static InstantPattern createWithCulture(String patternText, Culture culture) =>
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
  /// Returns: A pattern for parsing and formatting instants.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static InstantPattern createWithCurrentCulture(String patternText) =>
      _create(patternText, TimeMachineFormatInfo.currentInfo);

  /// Creates a pattern for the given pattern text in the invariant culture.
  ///
  /// todo: we need one
  /// See the user guide for the available pattern text options.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  ///
  /// Returns: A pattern for parsing and formatting instants.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static InstantPattern createWithInvariantCulture(String patternText) =>
      _create(patternText, TimeMachineFormatInfo.invariantInfo);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// localization information.
  ///
  /// * [formatInfo]: The localization information to use in the new pattern.
  ///
  /// Returns: A new pattern with the given localization information.
  InstantPattern _withFormatInfo(TimeMachineFormatInfo formatInfo) => _create(patternText, formatInfo);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  ///
  /// * [culture] :The culture to use in the new pattern.
  ///
  /// Returns: A new pattern with the given culture.
  InstantPattern withCulture(Culture culture) =>
      _withFormatInfo(TimeMachineFormatInfo.getFormatInfo(culture));
}

