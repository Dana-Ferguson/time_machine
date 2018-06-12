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

/// Represents a pattern for parsing and formatting [Offset] values.
///
/// <threadsafety>
/// When used with a read-only [CultureInfo], this type is immutable and instances
/// may be shared freely between threads. We recommend only using read-only cultures for patterns, although this is
/// not currently enforced.
/// </threadsafety>
@immutable // Well, assuming an immutable culture...
/*sealed*/ class OffsetPattern implements IPattern<Offset> {
  /// The "general" offset pattern (e.g. +HH, +HH:mm, +HH:mm:ss, +HH:mm:ss.fff) for the invariant culture.
  static final OffsetPattern GeneralInvariant = CreateWithInvariantCulture("g");

  /// The "general" offset pattern (e.g. +HH, +HH:mm, +HH:mm:ss, +HH:mm:ss.fff) for the invariant culture,
  /// but producing (and allowing) Z as a value for a zero offset.
  static final OffsetPattern GeneralInvariantWithZ = CreateWithInvariantCulture("G");

  @private static const String DefaultFormatPattern = "g";

  @internal static final PatternBclSupport<Offset> BclSupport = new PatternBclSupport<Offset>(DefaultFormatPattern, (fi) => fi.offsetPatternParser);

  /// Gets the pattern text for this pattern, as supplied on creation.
  final String PatternText;

  /// Returns the pattern that this object delegates to. Mostly useful to avoid this class
  /// implementing an @internal interface.
  @internal final IPartialPattern<Offset> UnderlyingPattern;

  @private OffsetPattern(this.PatternText, this.UnderlyingPattern);

  /// Parses the given text value according to the rules of this pattern.
  ///
  /// This method never throws an exception (barring a bug in Time Machine itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  ///
  /// [text]: The text value to parse.
  /// Returns: The result of parsing, which may be successful or unsuccessful.
  ParseResult<Offset> parse(String text) => UnderlyingPattern.parse(text);

  /// Formats the given offset as text according to the rules of this pattern.
  ///
  /// [value]: The offset to format.
  /// Returns: The offset formatted according to this pattern.
  String format(Offset value) => UnderlyingPattern.format(value);

  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given [StringBuilder].
  ///
  /// [value]: The value to format.
  /// [builder]: The `StringBuilder` to append to.
  /// Returns: The builder passed in as [builder].
  StringBuffer appendFormat(Offset value, StringBuffer builder) => UnderlyingPattern.appendFormat(value, builder);

  /// Creates a pattern for the given pattern text and format info.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [formatInfo]: Localization information
  /// Returns: A pattern for parsing and formatting offsets.
  /// [InvalidPatternException]: The pattern text was invalid.
  @internal static OffsetPattern Create(String patternText, TimeMachineFormatInfo formatInfo) {
    Preconditions.checkNotNull(patternText, 'patternText');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    var pattern = formatInfo.offsetPatternParser.ParsePattern(patternText) as IPartialPattern<Offset>;
    return new OffsetPattern(patternText, pattern);
  }

  /// Creates a pattern for the given pattern text and culture.
  ///
  /// See the user guide for the available pattern text options.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [cultureInfo]: The culture to use in the pattern
  /// Returns: A pattern for parsing and formatting offsets.
  /// [InvalidPatternException]: The pattern text was invalid.
  static OffsetPattern Create2(String patternText, CultureInfo cultureInfo) =>
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
  static OffsetPattern CreateWithCurrentCulture(String patternText) =>
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
  static OffsetPattern CreateWithInvariantCulture(String patternText) => Create(patternText, TimeMachineFormatInfo.invariantInfo);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  ///
  /// [cultureInfo]: The culture to use in the new pattern.
  /// Returns: A new pattern with the given culture.
  OffsetPattern WithCulture(CultureInfo cultureInfo) => Create(PatternText, TimeMachineFormatInfo.getFormatInfo(cultureInfo));
}
