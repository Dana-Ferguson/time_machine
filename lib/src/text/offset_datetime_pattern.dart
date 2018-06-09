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
@internal abstract class OffsetDateTimePatterns {
  @internal static final OffsetDateTimePattern GeneralIsoPatternImpl = OffsetDateTimePattern.Create(
      "uuuu'-'MM'-'dd'T'HH':'mm':'sso<G>", NodaFormatInfo.InvariantInfo, OffsetDateTimePattern.DefaultTemplateValue);
  @internal static final OffsetDateTimePattern ExtendedIsoPatternImpl = OffsetDateTimePattern.Create(
      "uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFFo<G>", NodaFormatInfo.InvariantInfo, OffsetDateTimePattern.DefaultTemplateValue);
  @internal static final OffsetDateTimePattern Rfc3339PatternImpl = OffsetDateTimePattern.Create(
      "uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFFo<Z+HH:mm>", NodaFormatInfo.InvariantInfo, OffsetDateTimePattern.DefaultTemplateValue);
  @internal static final OffsetDateTimePattern FullRoundtripPatternImpl = OffsetDateTimePattern.Create(
      "uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFFo<G> '('c')'", NodaFormatInfo.InvariantInfo, OffsetDateTimePattern.DefaultTemplateValue);
  @internal static final PatternBclSupport<OffsetDateTime> BclSupport = new PatternBclSupport<OffsetDateTime>("G", (fi) => fi.offsetDateTimePatternParser);
}


/// Represents a pattern for parsing and formatting [OffsetDateTime] values.
///
/// <threadsafety>
/// When used with a read-only [CultureInfo], this type is immutable and instances
/// may be shared freely between threads. We recommend only using read-only cultures for patterns, although this is
/// not currently enforced.
/// </threadsafety>
@immutable // Well, assuming an immutable culture...
/*sealed*/ class OffsetDateTimePattern implements IPattern<OffsetDateTime> {
  @internal static final OffsetDateTime DefaultTemplateValue = new LocalDateTime.fromYMDHM(2000, 1, 1, 0, 0).WithOffset(Offset.zero);

  /// Gets an invariant offset date/time pattern based on ISO-8601 (down to the second), including offset from UTC.
  ///
  /// The calendar system is not parsed or formatted as part of this pattern. It corresponds to a custom pattern of
  /// "uuuu'-'MM'-'dd'T'HH':'mm':'sso&lt;G&gt;". This pattern is available as the "G"
  /// standard pattern (even though it is invariant).
  static OffsetDateTimePattern get GeneralIso => OffsetDateTimePatterns.GeneralIsoPatternImpl;

  /// Gets an invariant offset date/time pattern based on ISO-8601 (down to the nanosecond), including offset from UTC.
  ///
  /// The calendar system is not parsed or formatted as part of this pattern. It corresponds to a custom pattern of
  /// "uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFFo&lt;G&gt;". This will round-trip any values
  /// in the ISO calendar, and is available as the "o" standard pattern.
  static OffsetDateTimePattern get ExtendedIso => OffsetDateTimePatterns.ExtendedIsoPatternImpl;

  /// Gets an invariant offset date/time pattern based on RFC 3339 (down to the nanosecond), including offset from UTC
  /// as hours and minutes only.
  ///
  /// The minutes part of the offset is always included, but any sub-minute component
  /// of the offset is lost. An offset of zero is formatted as 'Z', but all of 'Z', '+00:00' and '-00:00' are parsed
  /// the same way. The RFC 3339 meaning of '-00:00' is not supported by Time Machine.
  /// Note that parsing is case-sensitive (so 'T' and 'Z' must be upper case).
  /// The calendar system is not parsed or formatted as part of this pattern. It corresponds to a custom pattern of
  /// "uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFFo&lt;Z+HH:mm&gt;".
  ///
  /// <value>An invariant offset date/time pattern based on RFC 3339 (down to the nanosecond), including offset from UTC
  /// as hours and minutes only.</value>
  static OffsetDateTimePattern get Rfc3339 => OffsetDateTimePatterns.Rfc3339PatternImpl;

  /// Gets an invariant offset date/time pattern based on ISO-8601 (down to the nanosecond)
  /// including offset from UTC and calendar ID.
  ///
  /// The returned pattern corresponds to a custom pattern of
  /// "uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFFo&lt;G&gt; '('c')'". This will round-trip any value in any calendar,
  /// and is available as the "r" standard pattern.
  ///
  /// <value>An invariant offset date/time pattern based on ISO-8601 (down to the nanosecond)
  /// including offset from UTC and calendar ID.</value>
  static OffsetDateTimePattern get FullRoundtrip => OffsetDateTimePatterns.FullRoundtripPatternImpl;

  @private final IPattern<OffsetDateTime> pattern;

  /// Gets the pattern text for this pattern, as supplied on creation.
  final String PatternText;

  /// Gets the localization information used in this pattern.
  @internal final NodaFormatInfo FormatInfo;

  /// Gets the value used as a template for parsing: any field values unspecified
  /// in the pattern are taken from the template.
  final OffsetDateTime TemplateValue;

  @private OffsetDateTimePattern(this.PatternText, this.FormatInfo, this.TemplateValue, this.pattern);

  /// Parses the given text value according to the rules of this pattern.
  ///
  /// This method never throws an exception (barring a bug in Time Machine itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  ///
  /// [text]: The text value to parse.
  /// Returns: The result of parsing, which may be successful or unsuccessful.
  ParseResult<OffsetDateTime> Parse(String text) => pattern.Parse(text);

  /// Formats the given zoned date/time as text according to the rules of this pattern.
  ///
  /// [value]: The zoned date/time to format.
  /// Returns: The zoned date/time formatted according to this pattern.
  String Format(OffsetDateTime value) => pattern.Format(value);

  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given [StringBuilder].
  ///
  /// [value]: The value to format.
  /// [builder]: The `StringBuilder` to append to.
  /// Returns: The builder passed in as [builder].
  StringBuffer AppendFormat(OffsetDateTime value, StringBuffer builder) => pattern.AppendFormat(value, builder);

  /// Creates a pattern for the given pattern text, format info, and template value.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [formatInfo]: The format info to use in the pattern
  /// [templateValue]: Template value to use for unspecified fields
  /// Returns: A pattern for parsing and formatting zoned date/times.
  /// [InvalidPatternException]: The pattern text was invalid.
  @private static OffsetDateTimePattern Create(String patternText, NodaFormatInfo formatInfo, OffsetDateTime templateValue) {
    Preconditions.checkNotNull(patternText, 'patternText');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    var pattern = new OffsetDateTimePatternParser(templateValue).ParsePattern(patternText, formatInfo);
    return new OffsetDateTimePattern(patternText, formatInfo, templateValue, pattern);
  }

  /// Creates a pattern for the given pattern text, culture, and template value.
  ///
  /// See the user guide for the available pattern text options.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [cultureInfo]: The culture to use in the pattern
  /// [templateValue]: Template value to use for unspecified fields
  /// Returns: A pattern for parsing and formatting local date/times.
  /// [InvalidPatternException]: The pattern text was invalid.
  static OffsetDateTimePattern Create2(String patternText, CultureInfo cultureInfo, OffsetDateTime templateValue) =>
      Create(patternText, NodaFormatInfo.GetFormatInfo(cultureInfo), templateValue);

  /// Creates a pattern for the given pattern text in the invariant culture, using the default
  /// template value of midnight January 1st 2000 at an offset of 0.
  ///
  /// See the user guide for the available pattern text options.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// Returns: A pattern for parsing and formatting local date/times.
  /// [InvalidPatternException]: The pattern text was invalid.
  static OffsetDateTimePattern CreateWithInvariantCulture(String patternText) =>
      Create(patternText, NodaFormatInfo.InvariantInfo, DefaultTemplateValue);

  /// Creates a pattern for the given pattern text in the current culture, using the default
  /// template value of midnight January 1st 2000 at an offset of 0.
  ///
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// Returns: A pattern for parsing and formatting local date/times.
  /// [InvalidPatternException]: The pattern text was invalid.
  static OffsetDateTimePattern CreateWithCurrentCulture(String patternText) =>
      Create(patternText, NodaFormatInfo.CurrentInfo, DefaultTemplateValue);

  /// Creates a pattern for the same original localization information as this pattern, but with the specified
  /// pattern text.
  ///
  /// [patternText]: The pattern text to use in the new pattern.
  /// Returns: A new pattern with the given pattern text.
  OffsetDateTimePattern WithPatternText(String patternText) =>
      Create(patternText, FormatInfo, TemplateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// localization information.
  ///
  /// [formatInfo]: The localization information to use in the new pattern.
  /// Returns: A new pattern with the given localization information.
  @private OffsetDateTimePattern WithFormatInfo(NodaFormatInfo formatInfo) =>
      Create(PatternText, formatInfo, TemplateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  ///
  /// [cultureInfo]: The culture to use in the new pattern.
  /// Returns: A new pattern with the given culture.
  OffsetDateTimePattern WithCulture(CultureInfo cultureInfo) =>
      WithFormatInfo(NodaFormatInfo.GetFormatInfo(cultureInfo));

  /// Creates a pattern for the same original pattern text and culture as this pattern, but with
  /// the specified template value.
  ///
  /// [newTemplateValue]: The template value to use in the new pattern.
  /// Returns: A new pattern with the given template value.
  OffsetDateTimePattern WithTemplateValue(OffsetDateTime newTemplateValue) =>
      Create(PatternText, FormatInfo, newTemplateValue);

  /// Creates a pattern like this one, but with the template value modified to use
  /// the specified calendar system.
  ///
  /// Care should be taken in two (relatively rare) scenarios. Although the default template value
  /// is supported by all Time Machine calendar systems, if a pattern is created with a different
  /// template value and then this method is called with a calendar system which doesn't support that
  /// date, an exception will be thrown. Additionally, if the pattern only specifies some date fields,
  /// it's possible that the new template value will not be suitable for all values.
  ///
  /// [calendar]: The calendar system to convert the template value into.
  /// Returns: A new pattern with a template value in the specified calendar system.
  OffsetDateTimePattern WithCalendar(CalendarSystem calendar) =>
      WithTemplateValue(TemplateValue.WithCalendar(calendar));
}
