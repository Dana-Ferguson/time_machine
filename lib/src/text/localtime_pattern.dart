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
  @internal static final LocalTimePattern ExtendedIsoPatternImpl = LocalTimePattern.CreateWithInvariantCulture("HH':'mm':'ss;FFFFFFFFF");
}


/// Represents a pattern for parsing and formatting [LocalTime] values.
///
/// <threadsafety>
/// When used with a read-only [CultureInfo], this type is immutable and instances
/// may be shared freely between threads. We recommend only using read-only cultures for patterns, although this is
/// not currently enforced.
/// </threadsafety>
@immutable // Well, assuming an immutable culture...
/*sealed*/ class LocalTimePattern implements IPattern<LocalTime> {
  /// Gets an invariant local time pattern which is ISO-8601 compatible, providing up to 9 decimal places.
  /// (These digits are omitted when unnecessary.)
  /// This corresponds to the text pattern "HH':'mm':'ss;FFFFFFFFF".
  static final LocalTimePattern ExtendedIso = _Patterns.ExtendedIsoPatternImpl;

  @private static const String DefaultFormatPattern = "T"; // Long

  @internal static final PatternBclSupport<LocalTime> BclSupport =
  new PatternBclSupport<LocalTime>(DefaultFormatPattern, (fi) => fi.localTimePatternParser);

  /// Returns the pattern that this object delegates to. Mostly useful to avoid this class
  /// implementing an internal interface.
  @internal final IPartialPattern<LocalTime> UnderlyingPattern;

  /// Gets the pattern text for this pattern, as supplied on creation.
  final String PatternText;

  /// Gets the localization information used in this pattern.
  @internal final NodaFormatInfo FormatInfo;

  /// Gets the value used as a template for parsing: any field values unspecified
  /// in the pattern are taken from the template.
  final LocalTime TemplateValue;

  @private LocalTimePattern(this.PatternText, this.FormatInfo, this.TemplateValue, this.UnderlyingPattern);

  /// Parses the given text value according to the rules of this pattern.
  ///
  /// This method never throws an exception (barring a bug in Time Machine itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  ///
  /// [text]: The text value to parse.
  /// Returns: The result of parsing, which may be successful or unsuccessful.
  ParseResult<LocalTime> Parse(String text) => UnderlyingPattern.Parse(text);

  /// Formats the given local time as text according to the rules of this pattern.
  ///
  /// [value]: The local time to format.
  /// Returns: The local time formatted according to this pattern.
  String Format(LocalTime value) => UnderlyingPattern.Format(value);

  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given [StringBuilder].
  ///
  /// [value]: The value to format.
  /// [builder]: The `StringBuilder` to append to.
  /// Returns: The builder passed in as [builder].
  StringBuffer AppendFormat(LocalTime value, StringBuffer builder) => UnderlyingPattern.AppendFormat(value, builder);

  /// Creates a pattern for the given pattern text, format info, and template value.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [formatInfo]: The format info to use in the pattern
  /// [templateValue]: Template value to use for unspecified fields
  /// Returns: A pattern for parsing and formatting local times.
  /// [InvalidPatternException]: The pattern text was invalid.
  @internal static LocalTimePattern Create(String patternText, NodaFormatInfo formatInfo,
      LocalTime templateValue) {
    Preconditions.checkNotNull(patternText, 'patternText');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    // Use the "fixed" parser for the common case of the default template value.
    var pattern = templateValue == LocalTime.midnight
        ? formatInfo.localTimePatternParser.ParsePattern(patternText)
        : new LocalTimePatternParser(templateValue).ParsePattern(patternText, formatInfo);
    // If ParsePattern returns a standard pattern instance, we need to get the underlying partial pattern.
    // (Alternatively, we could just return it directly, instead of creating a new object.)
    pattern = pattern is LocalTimePattern ? pattern.UnderlyingPattern : pattern;
    var partialPattern = pattern as IPartialPattern<LocalTime>;
    return new LocalTimePattern(patternText, formatInfo, templateValue, partialPattern);
  }

// todo: Create names

  /// Creates a pattern for the given pattern text, culture, and template value.
  ///
  /// See the user guide for the available pattern text options.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [cultureInfo]: The culture to use in the pattern
  /// [templateValue]: Template value to use for unspecified fields
  /// Returns: A pattern for parsing and formatting local times.
  /// [InvalidPatternException]: The pattern text was invalid.
  static LocalTimePattern Create2(String patternText, CultureInfo cultureInfo, LocalTime templateValue) =>
      Create(patternText, NodaFormatInfo.GetFormatInfo(cultureInfo), templateValue);

  /// Creates a pattern for the given pattern text and culture, with a template value of midnight.
  ///
  /// See the user guide for the available pattern text options.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [cultureInfo]: The culture to use in the pattern
  /// Returns: A pattern for parsing and formatting local times.
  /// [InvalidPatternException]: The pattern text was invalid.
  static LocalTimePattern Create3(String patternText, CultureInfo cultureInfo) =>
      Create2(patternText, cultureInfo, LocalTime.midnight);

  /// Creates a pattern for the given pattern text in the current thread's current culture.
  ///
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// Returns: A pattern for parsing and formatting local times.
  /// [InvalidPatternException]: The pattern text was invalid.
  static LocalTimePattern CreateWithCurrentCulture(String patternText) =>
      Create(patternText, NodaFormatInfo.CurrentInfo, LocalTime.midnight);

  /// Creates a pattern for the given pattern text in the invariant culture.
  ///
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// Returns: A pattern for parsing and formatting local times.
  /// [InvalidPatternException]: The pattern text was invalid.
  static LocalTimePattern CreateWithInvariantCulture(String patternText) =>
      Create(patternText, NodaFormatInfo.InvariantInfo, LocalTime.midnight);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// localization information.
  ///
  /// [formatInfo]: The localization information to use in the new pattern.
  /// Returns: A new pattern with the given localization information.
  @private LocalTimePattern WithFormatInfo(NodaFormatInfo formatInfo) =>
      Create(PatternText, formatInfo, TemplateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  ///
  /// [cultureInfo]: The culture to use in the new pattern.
  /// Returns: A new pattern with the given culture.
  LocalTimePattern WithCulture(CultureInfo cultureInfo) =>
      WithFormatInfo(NodaFormatInfo.GetFormatInfo(cultureInfo));

  /// Creates a pattern like this one, but with the specified template value.
  ///
  /// [newTemplateValue]: The template value for the new pattern, used to fill in unspecified fields.
  /// Returns: A new pattern with the given template value.
  LocalTimePattern WithTemplateValue(LocalTime newTemplateValue) =>
      Create(PatternText, FormatInfo, newTemplateValue);
}
