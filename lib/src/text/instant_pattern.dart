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


/// Class whose existence is solely to avoid type initialization order issues, most of which stem
/// from needing NodaFormatInfo.InvariantInfo...
abstract class _InstantPatterns
{
  @internal static final InstantPattern extendedIsoPatternImpl = InstantPattern.createWithInvariantCulture("uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFF'Z'");
  @internal static final InstantPattern generalPatternImpl = InstantPattern.createWithInvariantCulture("uuuu-MM-ddTHH:mm:ss'Z'");
}

/// Represents a pattern for parsing and formatting [Instant] values.
@immutable // Well, assuming an immutable culture...
class InstantPattern implements IPattern<Instant> {
  /// Gets the general pattern, which always uses an invariant culture. The general pattern represents
  /// an instant as a UTC date/time in ISO-8601 style "uuuu-MM-ddTHH:mm:ss'Z'".
  static InstantPattern get general => _InstantPatterns.generalPatternImpl;

  /// Gets an invariant instant pattern which is ISO-8601 compatible, providing up to 9 decimal places
  /// of sub-second accuracy. (These digits are omitted when unnecessary.)
  /// This corresponds to the text pattern "uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFF'Z'".
  ///
  /// <value>An invariant instant pattern which is ISO-8601 compatible, providing up to 9 decimal places
  /// of sub-second accuracy.</value>
  static InstantPattern get extendedIso => _InstantPatterns.extendedIsoPatternImpl;

  static const String _defaultFormatPattern = "g";

  @internal static final PatternBclSupport<Instant> bclSupport = new PatternBclSupport<Instant>(_defaultFormatPattern, (fi) => fi.instantPatternParser);

  final IPattern<Instant> _pattern;

  /// Gets the pattern text for this pattern, as supplied on creation.
  final String PatternText;

  InstantPattern._(this.PatternText, this._pattern);

  /// Parses the given text value according to the rules of this pattern.
  ///
  /// This method never throws an exception (barring a bug in Time Machine itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  ///
  /// [text]: The text value to parse.
  /// Returns: The result of parsing, which may be successful or unsuccessful.
  ParseResult<Instant> parse(String text) => _pattern.parse(text);

  /// Formats the given instant as text according to the rules of this pattern.
  ///
  /// [value]: The instant to format.
  /// Returns: The instant formatted according to this pattern.
  String format(Instant value) => _pattern.format(value);

  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given [StringBuilder].
  ///
  /// [value]: The value to format.
  /// [builder]: The `StringBuilder` to append to.
  /// Returns: The builder passed in as [builder].
  StringBuffer appendFormat(Instant value, StringBuffer builder) => _pattern.appendFormat(value, builder);

  /// Creates a pattern for the given pattern text and format info.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [formatInfo]: The format info to use in the pattern
  /// Returns: A pattern for parsing and formatting instants.
  /// [InvalidPatternException]: The pattern text was invalid.
  static InstantPattern _create(String patternText, TimeMachineFormatInfo formatInfo) {
    Preconditions.checkNotNull(patternText, 'patternText');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    var pattern = formatInfo.instantPatternParser.parsePattern(patternText);
    return new InstantPattern._(patternText, pattern);
  }

  /// Creates a pattern for the given pattern text and culture.
  ///
  /// See the user guide for the available pattern text options.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [cultureInfo]: The culture to use in the pattern
  /// Returns: A pattern for parsing and formatting instants.
  /// [InvalidPatternException]: The pattern text was invalid.
  static InstantPattern create(String patternText, CultureInfo cultureInfo) =>
      _create(patternText, TimeMachineFormatInfo.getFormatInfo(cultureInfo));

  /// Creates a pattern for the given pattern text in the current thread's current culture.
  ///
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// Returns: A pattern for parsing and formatting instants.
  /// [InvalidPatternException]: The pattern text was invalid.
  static InstantPattern createWithCurrentCulture(String patternText) =>
      _create(patternText, TimeMachineFormatInfo.currentInfo);

  /// Creates a pattern for the given pattern text in the invariant culture.
  ///
  /// See the user guide for the available pattern text options.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// Returns: A pattern for parsing and formatting instants.
  /// [InvalidPatternException]: The pattern text was invalid.
  static InstantPattern createWithInvariantCulture(String patternText) =>
      _create(patternText, TimeMachineFormatInfo.invariantInfo);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// localization information.
  ///
  /// [formatInfo]: The localization information to use in the new pattern.
  /// Returns: A new pattern with the given localization information.
  InstantPattern _withFormatInfo(TimeMachineFormatInfo formatInfo) => _create(PatternText, formatInfo);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  ///
  /// [cultureInfo]: The culture to use in the new pattern.
  /// Returns: A new pattern with the given culture.
  InstantPattern withCulture(CultureInfo cultureInfo) =>
      _withFormatInfo(TimeMachineFormatInfo.getFormatInfo(cultureInfo));
}

