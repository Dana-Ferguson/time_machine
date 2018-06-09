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
@internal class OffsetTimePatterns {
//static OffsetTimePattern _GeneralIsoPatternImpl = null;
//@internal static OffsetTimePattern get GeneralIsoPatternImpl => _GeneralIsoPatternImpl ??= OffsetTimePattern.Create(
//    "HH':'mm':'sso<G>", NodaFormatInfo.InvariantInfo, OffsetTimePattern.DefaultTemplateValue);

  @internal static final OffsetTimePattern GeneralIsoPatternImpl = OffsetTimePattern.Create(
      "HH':'mm':'sso<G>", NodaFormatInfo.InvariantInfo, OffsetTimePattern.DefaultTemplateValue);
  @internal static final OffsetTimePattern ExtendedIsoPatternImpl = OffsetTimePattern.Create(
      "HH':'mm':'ss;FFFFFFFFFo<G>", NodaFormatInfo.InvariantInfo, OffsetTimePattern.DefaultTemplateValue);
  @internal static final OffsetTimePattern Rfc3339PatternImpl = OffsetTimePattern.Create(
      "HH':'mm':'ss;FFFFFFFFFo<Z+HH:mm>", NodaFormatInfo.InvariantInfo, OffsetTimePattern.DefaultTemplateValue);
  @internal static final PatternBclSupport<OffsetTime> BclSupport = new PatternBclSupport<OffsetTime>("G", (fi) => fi.offsetTimePatternParser);
}

/// Represents a pattern for parsing and formatting [OffsetTime] values.
///
/// <threadsafety>
/// When used with a read-only [CultureInfo], this type is immutable and instances
/// may be shared freely between threads. We recommend only using read-only cultures for patterns, although this is
/// not currently enforced.
/// </threadsafety>
@immutable // Well, assuming an immutable culture...
/*sealed*/ class OffsetTimePattern implements IPattern<OffsetTime> {
  @internal static final OffsetTime DefaultTemplateValue = LocalTime.Midnight.WithOffset(Offset.zero);

  /// Gets an invariant offset time pattern based on ISO-8601 (down to the second), including offset from UTC.
  ///
  /// This corresponds to a custom pattern of "HH':'mm':'sso&lt;G&gt;". It is available as the "G"
  /// standard pattern (even though it is invariant).
  static OffsetTimePattern get GeneralIso => OffsetTimePatterns.GeneralIsoPatternImpl;

  /// Gets an invariant offset time pattern based on ISO-8601 (down to the nanosecond), including offset from UTC.
  ///
  /// This corresponds to a custom pattern of "HH':'mm':'ss;FFFFFFFFFo&lt;G&gt;".
  /// This will round-trip all values, and is available as the "o" standard pattern.
  static OffsetTimePattern get ExtendedIso => OffsetTimePatterns.ExtendedIsoPatternImpl;

  /// Gets an invariant offset time pattern based on RFC 3339 (down to the nanosecond), including offset from UTC
  /// as hours and minutes only.
  ///
  /// The minutes part of the offset is always included, but any sub-minute component
  /// of the offset is lost. An offset of zero is formatted as 'Z', but all of 'Z', '+00:00' and '-00:00' are parsed
  /// the same way. The RFC 3339 meaning of '-00:00' is not supported by Time Machine.
  /// Note that parsing is case-sensitive (so 'T' and 'Z' must be upper case).
  /// This pattern corresponds to a custom pattern of
  /// "HH':'mm':'ss;FFFFFFFFFo&lt;Z+HH:mm&gt;".
  ///
  /// <value>An invariant offset time pattern based on RFC 3339 (down to the nanosecond), including offset from UTC
  /// as hours and minutes only.</value>
  static OffsetTimePattern get Rfc3339 => OffsetTimePatterns.Rfc3339PatternImpl;

  @private final IPattern<OffsetTime> pattern;

  /// Gets the pattern text for this pattern, as supplied on creation.
  final String PatternText;

  /// Gets the localization information used in this pattern.
  @internal final NodaFormatInfo FormatInfo;

  /// Gets the value used as a template for parsing: any field values unspecified
  /// in the pattern are taken from the template.
  final OffsetTime TemplateValue;

  @private OffsetTimePattern(this.PatternText, this.FormatInfo, this.TemplateValue, this.pattern);

  /// Parses the given text value according to the rules of this pattern.
  ///
  /// This method never throws an exception (barring a bug in Time Machine itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  ///
  /// [text]: The text value to parse.
  /// Returns: The result of parsing, which may be successful or unsuccessful.
  ParseResult<OffsetTime> Parse(String text) => pattern.Parse(text);

  /// Formats the given zoned time as text according to the rules of this pattern.
  ///
  /// [value]: The zoned time to format.
  /// Returns: The zoned time formatted according to this pattern.
  String Format(OffsetTime value) => pattern.Format(value);

  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given [StringBuilder].
  ///
  /// [value]: The value to format.
  /// [builder]: The `StringBuilder` to append to.
  /// Returns: The builder passed in as [builder].
  StringBuffer AppendFormat(OffsetTime value, StringBuffer builder) => pattern.AppendFormat(value, builder);

  /// Creates a pattern for the given pattern text, format info, and template value.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [formatInfo]: The format info to use in the pattern
  /// [templateValue]: Template value to use for unspecified fields
  /// Returns: A pattern for parsing and formatting zoned times.
  /// [InvalidPatternException]: The pattern text was invalid.
  @private static OffsetTimePattern Create(String patternText, NodaFormatInfo formatInfo,
      OffsetTime templateValue) {
    Preconditions.checkNotNull(patternText, 'patternText');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    var pattern = new OffsetTimePatternParser(templateValue).ParsePattern(patternText, formatInfo);
    return new OffsetTimePattern(patternText, formatInfo, templateValue, pattern);
  }

  /// Creates a pattern for the given pattern text, culture, and template value.
  ///
  /// See the user guide for the available pattern text options.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [cultureInfo]: The culture to use in the pattern
  /// [templateValue]: Template value to use for unspecified fields
  /// Returns: A pattern for parsing and formatting local times.
  /// [InvalidPatternException]: The pattern text was invalid.
  static OffsetTimePattern Create2(String patternText, CultureInfo cultureInfo, OffsetTime templateValue) =>
      Create(patternText, NodaFormatInfo.GetFormatInfo(cultureInfo), templateValue);

  /// Creates a pattern for the given pattern text in the invariant culture, using the default
  /// template value of midnight January 1st 2000 at an offset of 0.
  ///
  /// See the user guide for the available pattern text options.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// Returns: A pattern for parsing and formatting local times.
  /// [InvalidPatternException]: The pattern text was invalid.
  static OffsetTimePattern CreateWithInvariantCulture(String patternText) =>
      Create(patternText, NodaFormatInfo.InvariantInfo, DefaultTemplateValue);

  /// Creates a pattern for the given pattern text in the current culture, using the default
  /// template value of midnight January 1st 2000 at an offset of 0.
  ///
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// Returns: A pattern for parsing and formatting local times.
  /// [InvalidPatternException]: The pattern text was invalid.
  static OffsetTimePattern CreateWithCurrentCulture(String patternText) =>
      Create(patternText, NodaFormatInfo.CurrentInfo, DefaultTemplateValue);

  /// Creates a pattern for the same original localization information as this pattern, but with the specified
  /// pattern text.
  ///
  /// [patternText]: The pattern text to use in the new pattern.
  /// Returns: A new pattern with the given pattern text.
  OffsetTimePattern WithPatternText(String patternText) =>
      Create(patternText, FormatInfo, TemplateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// localization information.
  ///
  /// [formatInfo]: The localization information to use in the new pattern.
  /// Returns: A new pattern with the given localization information.
  @private OffsetTimePattern WithFormatInfo(NodaFormatInfo formatInfo) =>
      Create(PatternText, formatInfo, TemplateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  ///
  /// [cultureInfo]: The culture to use in the new pattern.
  /// Returns: A new pattern with the given culture.
  OffsetTimePattern WithCulture(CultureInfo cultureInfo) =>
      WithFormatInfo(NodaFormatInfo.GetFormatInfo(cultureInfo));

  /// Creates a pattern for the same original pattern text and culture as this pattern, but with
  /// the specified template value.
  ///
  /// [newTemplateValue]: The template value to use in the new pattern.
  /// Returns: A new pattern with the given template value.
  OffsetTimePattern WithTemplateValue(OffsetTime newTemplateValue) =>
      Create(PatternText, FormatInfo, newTemplateValue);
}
