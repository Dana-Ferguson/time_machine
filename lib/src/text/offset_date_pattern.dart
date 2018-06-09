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
@internal abstract class OffsetDatePatterns {
  @internal static final OffsetDatePattern GeneralIsoPatternImpl = OffsetDatePattern.Create(
      "uuuu'-'MM'-'ddo<G>", NodaFormatInfo.InvariantInfo, OffsetDatePattern.DefaultTemplateValue);
  @internal static final OffsetDatePattern FullRoundtripPatternImpl = OffsetDatePattern.Create(
      "uuuu'-'MM'-'ddo<G> '('c')'", NodaFormatInfo.InvariantInfo, OffsetDatePattern.DefaultTemplateValue);
  @internal static final PatternBclSupport<OffsetDate> BclSupport = new PatternBclSupport<OffsetDate>("G", (fi) => fi.offsetDatePatternParser);
}

/// Represents a pattern for parsing and formatting [OffsetDate] values.
///
/// <threadsafety>
/// When used with a read-only [CultureInfo], this type is immutable and instances
/// may be shared freely between threads. We recommend only using read-only cultures for patterns, although this is
/// not currently enforced.
/// </threadsafety>
@immutable // Well, assuming an immutable culture...
/*sealed*/ class OffsetDatePattern implements IPattern<OffsetDate> {
  @internal static final OffsetDate DefaultTemplateValue = new LocalDate(2000, 1, 1).WithOffset(Offset.zero);

  /// Gets an invariant offset date pattern based on ISO-8601, including offset from UTC.
  ///
  /// The calendar system is not parsed or formatted as part of this pattern. It corresponds to a custom pattern of
  /// "uuuu'-'MM'-'ddo&lt;G&gt;". This pattern is available as the "G" standard pattern (even though it is invariant).
  static OffsetDatePattern get GeneralIso => OffsetDatePatterns.GeneralIsoPatternImpl;

  /// Gets an invariant offset date pattern based on ISO-8601
  /// including offset from UTC and calendar ID.
  ///
  /// The returned pattern corresponds to a custom pattern of
  /// "uuuu'-'MM'-'dd'o&lt;G&gt; '('c')'". This will round-trip any value in any calendar,
  /// and is available as the "r" standard pattern.
  ///
  /// <value>An invariant offset date pattern based on ISO-8601 (down to the nanosecond)
  /// including offset from UTC and calendar ID.</value>
  static OffsetDatePattern get FullRoundtrip => OffsetDatePatterns.FullRoundtripPatternImpl;

  @private final IPattern<OffsetDate> pattern;

  /// Gets the pattern text for this pattern, as supplied on creation.
  final String PatternText;

  /// Gets the localization information used in this pattern.
  @internal final NodaFormatInfo FormatInfo;

  /// Gets the value used as a template for parsing: any field values unspecified
  /// in the pattern are taken from the template.
  final OffsetDate TemplateValue;

  @private OffsetDatePattern(this.PatternText, this.FormatInfo, this.TemplateValue, this.pattern);

  /// Parses the given text value according to the rules of this pattern.
  ///
  /// This method never throws an exception (barring a bug in Time Machine itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  ///
  /// [text]: The text value to parse.
  /// Returns: The result of parsing, which may be successful or unsuccessful.
  ParseResult<OffsetDate> Parse(String text) => pattern.Parse(text);

  /// Formats the given zoned date as text according to the rules of this pattern.
  ///
  /// [value]: The zoned date to format.
  /// Returns: The zoned date formatted according to this pattern.
  String Format(OffsetDate value) => pattern.Format(value);

  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given [StringBuilder].
  ///
  /// [value]: The value to format.
  /// [builder]: The `StringBuilder` to append to.
  /// Returns: The builder passed in as [builder].
  StringBuffer AppendFormat(OffsetDate value, StringBuffer builder) => pattern.AppendFormat(value, builder);

  /// Creates a pattern for the given pattern text, format info, and template value.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [formatInfo]: The format info to use in the pattern
  /// [templateValue]: Template value to use for unspecified fields
  /// Returns: A pattern for parsing and formatting zoned dates.
  /// [InvalidPatternException]: The pattern text was invalid.
  @private static OffsetDatePattern Create(String patternText, NodaFormatInfo formatInfo,
      OffsetDate templateValue) {
    Preconditions.checkNotNull(patternText, 'patternText');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    var pattern = new OffsetDatePatternParser(templateValue).ParsePattern(patternText, formatInfo);
    return new OffsetDatePattern(patternText, formatInfo, templateValue, pattern);
  }

  /// Creates a pattern for the given pattern text, culture, and template value.
  ///
  /// See the user guide for the available pattern text options.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [cultureInfo]: The culture to use in the pattern
  /// [templateValue]: Template value to use for unspecified fields
  /// Returns: A pattern for parsing and formatting local dates.
  /// [InvalidPatternException]: The pattern text was invalid.
  static OffsetDatePattern Create2(String patternText, CultureInfo cultureInfo, OffsetDate templateValue) =>
      Create(patternText, NodaFormatInfo.GetFormatInfo(cultureInfo), templateValue);

  /// Creates a pattern for the given pattern text in the invariant culture, using the default
  /// template value of midnight January 1st 2000 at an offset of 0.
  ///
  /// See the user guide for the available pattern text options.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// Returns: A pattern for parsing and formatting local dates.
  /// [InvalidPatternException]: The pattern text was invalid.
  static OffsetDatePattern CreateWithInvariantCulture(String patternText) =>
      Create(patternText, NodaFormatInfo.InvariantInfo, DefaultTemplateValue);

  /// Creates a pattern for the given pattern text in the current culture, using the default
  /// template value of midnight January 1st 2000 at an offset of 0.
  ///
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// Returns: A pattern for parsing and formatting local dates.
  /// [InvalidPatternException]: The pattern text was invalid.
  static OffsetDatePattern CreateWithCurrentCulture(String patternText) =>
      Create(patternText, NodaFormatInfo.CurrentInfo, DefaultTemplateValue);

  /// Creates a pattern for the same original localization information as this pattern, but with the specified
  /// pattern text.
  ///
  /// [patternText]: The pattern text to use in the new pattern.
  /// Returns: A new pattern with the given pattern text.
  OffsetDatePattern WithPatternText(String patternText) =>
      Create(patternText, FormatInfo, TemplateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// localization information.
  ///
  /// [formatInfo]: The localization information to use in the new pattern.
  /// Returns: A new pattern with the given localization information.
  @private OffsetDatePattern WithFormatInfo(NodaFormatInfo formatInfo) =>
      Create(PatternText, formatInfo, TemplateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  ///
  /// [cultureInfo]: The culture to use in the new pattern.
  /// Returns: A new pattern with the given culture.
  OffsetDatePattern WithCulture(CultureInfo cultureInfo) =>
      WithFormatInfo(NodaFormatInfo.GetFormatInfo(cultureInfo));

  /// Creates a pattern for the same original pattern text and culture as this pattern, but with
  /// the specified template value.
  ///
  /// [newTemplateValue]: The template value to use in the new pattern.
  /// Returns: A new pattern with the given template value.
  OffsetDatePattern WithTemplateValue(OffsetDate newTemplateValue) =>
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
  OffsetDatePattern WithCalendar(CalendarSystem calendar) =>
      WithTemplateValue(TemplateValue.WithCalendar(calendar));
}
