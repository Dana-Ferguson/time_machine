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
@private abstract class _Patterns
{
  @internal static final AnnualDatePattern isoPatternImpl = AnnualDatePattern.createWithInvariantCulture("MM'-'dd");
}


/// Represents a pattern for parsing and formatting [AnnualDate] values.
///
/// <threadsafety>
/// When used with a read-only [CultureInfo], this type is immutable and instances
/// may be shared freely between threads. We recommend only using read-only cultures for patterns, although this is
/// not currently enforced.
/// </threadsafety>
@immutable // Well, assuming an immutable culture...
/*sealed*/ class AnnualDatePattern implements IPattern<AnnualDate> {
  @internal static final AnnualDate defaultTemplateValue = new AnnualDate(1, 1);

  static const String _defaultFormatPattern = "G"; // General, ISO-like

  @internal static final PatternBclSupport<AnnualDate> bclSupport =
  new PatternBclSupport<AnnualDate>(_defaultFormatPattern, (fi) => fi.annualDatePatternParser);

  /// Gets an invariant annual date pattern which is compatible with the month/day part of ISO-8601.
  /// This corresponds to the text pattern "MM'-'dd".
  static AnnualDatePattern get iso => _Patterns.isoPatternImpl;

  /// Returns the pattern that this object delegates to. Mostly useful to avoid this class
  /// implementing an @internal interface.
  @internal final IPartialPattern<AnnualDate> underlyingPattern;

  /// Gets the pattern text for this pattern, as supplied on creation.
  final String patternText;

  /// Returns the localization information used in this pattern.
  @internal final TimeMachineFormatInfo formatInfo;

  /// Gets the value used as a template for parsing: any field values unspecified
  /// in the pattern are taken from the template.
  final AnnualDate templateValue;

  AnnualDatePattern._(this.patternText, this.formatInfo, this.templateValue, this.underlyingPattern);

  /// Parses the given text value according to the rules of this pattern.
  ///
  /// This method never throws an exception (barring a bug in Time Machine itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  ///
  /// [text]: The text value to parse.
  /// Returns: The result of parsing, which may be successful or unsuccessful.
  ParseResult<AnnualDate> parse(String text) => underlyingPattern.parse(text);

  /// Formats the given annual date as text according to the rules of this pattern.
  ///
  /// [value]: The annual date to format.
  /// Returns: The annual date formatted according to this pattern.
  String format(AnnualDate value) => underlyingPattern.format(value);

  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given [StringBuilder].
  ///
  /// [value]: The value to format.
  /// [builder]: The `StringBuilder` to append to.
  /// Returns: The builder passed in as [builder].
  StringBuffer appendFormat(AnnualDate value, StringBuffer builder) => underlyingPattern.appendFormat(value, builder);

  /// Creates a pattern for the given pattern text, format info, and template value.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [formatInfo]: The format info to use in the pattern
  /// [templateValue]: Template value to use for unspecified fields
  /// Returns: A pattern for parsing and formatting annual dates.
  /// [InvalidPatternException]: The pattern text was invalid.
  @internal static AnnualDatePattern _create(String patternText, TimeMachineFormatInfo formatInfo, AnnualDate templateValue) {
    Preconditions.checkNotNull(patternText, 'patternText');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    // Use the "fixed" parser for the common case of the default template value.
    var pattern = templateValue == defaultTemplateValue
        ? formatInfo.annualDatePatternParser.parsePattern(patternText)
        : new AnnualDatePatternParser(templateValue).parsePattern(patternText, formatInfo);
    // If ParsePattern returns a standard pattern instance, we need to get the underlying partial pattern.
    pattern = pattern is AnnualDatePattern ? pattern.underlyingPattern : pattern;
    var partialPattern = pattern as IPartialPattern<AnnualDate>;
    return new AnnualDatePattern._(patternText, formatInfo, templateValue, partialPattern);
  }

  /// Creates a pattern for the given pattern text, culture, and template value.
  ///
  /// See the user guide for the available pattern text options.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [cultureInfo]: The culture to use in the pattern
  /// [templateValue]: Template value to use for unspecified fields. Defaults to a template value of 2000-01-01. 
  /// Returns: A pattern for parsing and formatting annual dates.
  /// [InvalidPatternException]: The pattern text was invalid.
  static AnnualDatePattern create(String patternText, CultureInfo cultureInfo, [AnnualDate templateValue]) =>
      _create(patternText, TimeMachineFormatInfo.getFormatInfo(cultureInfo), templateValue ?? defaultTemplateValue);

  /// Creates a pattern for the given pattern text in the current thread's current culture.
  ///
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// Returns: A pattern for parsing and formatting annual dates.
  /// [InvalidPatternException]: The pattern text was invalid.
  static AnnualDatePattern createWithCurrentCulture(String patternText) =>
      _create(patternText, TimeMachineFormatInfo.currentInfo, defaultTemplateValue);

  /// Creates a pattern for the given pattern text in the invariant culture.
  ///
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// Returns: A pattern for parsing and formatting annual dates.
  /// [InvalidPatternException]: The pattern text was invalid.
  static AnnualDatePattern createWithInvariantCulture(String patternText) =>
      _create(patternText, TimeMachineFormatInfo.invariantInfo, defaultTemplateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// localization information.
  ///
  /// [formatInfo]: The localization information to use in the new pattern.
  /// Returns: A new pattern with the given localization information.
  AnnualDatePattern _withFormatInfo(TimeMachineFormatInfo formatInfo) =>
      _create(patternText, formatInfo, templateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  ///
  /// [cultureInfo]: The culture to use in the new pattern.
  /// Returns: A new pattern with the given culture.
  AnnualDatePattern withCulture(CultureInfo cultureInfo) =>
      _withFormatInfo(TimeMachineFormatInfo.getFormatInfo(cultureInfo));

  /// Creates a pattern like this one, but with the specified template value.
  ///
  /// [newTemplateValue]: The template value for the new pattern, used to fill in unspecified fields.
  /// Returns: A new pattern with the given template value.
  AnnualDatePattern withTemplateValue(AnnualDate newTemplateValue) =>
      _create(patternText, formatInfo, newTemplateValue);
}
