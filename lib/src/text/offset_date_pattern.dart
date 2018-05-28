// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Text/OffsetDatePattern.cs
// 41dc54e  on Nov 8, 2017

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';

/// <summary>
/// Class whose existence is solely to avoid type initialization order issues, most of which stem
/// from needing NodaFormatInfo.InvariantInfo...
/// </summary>
@internal abstract class OffsetDatePatterns {
  @internal static final OffsetDatePattern GeneralIsoPatternImpl = OffsetDatePattern.Create(
      "uuuu'-'MM'-'ddo<G>", NodaFormatInfo.InvariantInfo, OffsetDatePattern.DefaultTemplateValue);
  @internal static final OffsetDatePattern FullRoundtripPatternImpl = OffsetDatePattern.Create(
      "uuuu'-'MM'-'ddo<G> '('c')'", NodaFormatInfo.InvariantInfo, OffsetDatePattern.DefaultTemplateValue);
  @internal static final PatternBclSupport<OffsetDate> BclSupport = new PatternBclSupport<OffsetDate>("G", (fi) => fi.offsetDatePatternParser);
}

/// <summary>
/// Represents a pattern for parsing and formatting <see cref="OffsetDate"/> values.
/// </summary>
/// <threadsafety>
/// When used with a read-only <see cref="CultureInfo" />, this type is immutable and instances
/// may be shared freely between threads. We recommend only using read-only cultures for patterns, although this is
/// not currently enforced.
/// </threadsafety>
@immutable // Well, assuming an immutable culture...
/*sealed*/ class OffsetDatePattern implements IPattern<OffsetDate> {
  @internal static final OffsetDate DefaultTemplateValue = new LocalDate(2000, 1, 1).WithOffset(Offset.zero);

  /// <summary>
  /// Gets an invariant offset date pattern based on ISO-8601, including offset from UTC.
  /// </summary>
  /// <remarks>
  /// The calendar system is not parsed or formatted as part of this pattern. It corresponds to a custom pattern of
  /// "uuuu'-'MM'-'ddo&lt;G&gt;". This pattern is available as the "G" standard pattern (even though it is invariant).
  /// </remarks>
  /// <value>An invariant offset date pattern based on ISO-8601 (down to the second), including offset from UTC.</value>
  static OffsetDatePattern get GeneralIso => OffsetDatePatterns.GeneralIsoPatternImpl;

  /// <summary>
  /// Gets an invariant offset date pattern based on ISO-8601
  /// including offset from UTC and calendar ID.
  /// </summary>
  /// <remarks>
  /// The returned pattern corresponds to a custom pattern of
  /// "uuuu'-'MM'-'dd'o&lt;G&gt; '('c')'". This will round-trip any value in any calendar,
  /// and is available as the "r" standard pattern.
  /// </remarks>
  /// <value>An invariant offset date pattern based on ISO-8601 (down to the nanosecond)
  /// including offset from UTC and calendar ID.</value>
  static OffsetDatePattern get FullRoundtrip => OffsetDatePatterns.FullRoundtripPatternImpl;

  @private final IPattern<OffsetDate> pattern;

  /// <summary>
  /// Gets the pattern text for this pattern, as supplied on creation.
  /// </summary>
  /// <value>The pattern text for this pattern, as supplied on creation.</value>
  final String PatternText;

  /// <summary>
  /// Gets the localization information used in this pattern.
  /// </summary>
  @internal final NodaFormatInfo FormatInfo;

  /// <summary>
  /// Gets the value used as a template for parsing: any field values unspecified
  /// in the pattern are taken from the template.
  /// </summary>
  /// <value>The value used as a template for parsing.</value>
  final OffsetDate TemplateValue;

  @private OffsetDatePattern(this.PatternText, this.FormatInfo, this.TemplateValue, this.pattern);

  /// <summary>
  /// Parses the given text value according to the rules of this pattern.
  /// </summary>
  /// <remarks>
  /// This method never throws an exception (barring a bug in Noda Time itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  /// </remarks>
  /// <param name="text">The text value to parse.</param>
  /// <returns>The result of parsing, which may be successful or unsuccessful.</returns>
  ParseResult<OffsetDate> Parse(String text) => pattern.Parse(text);

  /// <summary>
  /// Formats the given zoned date as text according to the rules of this pattern.
  /// </summary>
  /// <param name="value">The zoned date to format.</param>
  /// <returns>The zoned date formatted according to this pattern.</returns>
  String Format(OffsetDate value) => pattern.Format(value);

  /// <summary>
  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given <see cref="StringBuilder"/>.
  /// </summary>
  /// <param name="value">The value to format.</param>
  /// <param name="builder">The <c>StringBuilder</c> to append to.</param>
  /// <returns>The builder passed in as <paramref name="builder"/>.</returns>
  StringBuffer AppendFormat(OffsetDate value, StringBuffer builder) => pattern.AppendFormat(value, builder);

  /// <summary>
  /// Creates a pattern for the given pattern text, format info, and template value.
  /// </summary>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <param name="formatInfo">The format info to use in the pattern</param>
  /// <param name="templateValue">Template value to use for unspecified fields</param>
  /// <returns>A pattern for parsing and formatting zoned dates.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  @private static OffsetDatePattern Create(String patternText, NodaFormatInfo formatInfo,
      OffsetDate templateValue) {
    Preconditions.checkNotNull(patternText, 'patternText');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    var pattern = new OffsetDatePatternParser(templateValue).ParsePattern(patternText, formatInfo);
    return new OffsetDatePattern(patternText, formatInfo, templateValue, pattern);
  }

  /// <summary>
  /// Creates a pattern for the given pattern text, culture, and template value.
  /// </summary>
  /// <remarks>
  /// See the user guide for the available pattern text options.
  /// </remarks>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <param name="cultureInfo">The culture to use in the pattern</param>
  /// <param name="templateValue">Template value to use for unspecified fields</param>
  /// <returns>A pattern for parsing and formatting local dates.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  static OffsetDatePattern Create2(String patternText, CultureInfo cultureInfo, OffsetDate templateValue) =>
      Create(patternText, NodaFormatInfo.GetFormatInfo(cultureInfo), templateValue);

  /// <summary>
  /// Creates a pattern for the given pattern text in the invariant culture, using the default
  /// template value of midnight January 1st 2000 at an offset of 0.
  /// </summary>
  /// <remarks>
  /// See the user guide for the available pattern text options.
  /// </remarks>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <returns>A pattern for parsing and formatting local dates.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  static OffsetDatePattern CreateWithInvariantCulture(String patternText) =>
      Create(patternText, NodaFormatInfo.InvariantInfo, DefaultTemplateValue);

  /// <summary>
  /// Creates a pattern for the given pattern text in the current culture, using the default
  /// template value of midnight January 1st 2000 at an offset of 0.
  /// </summary>
  /// <remarks>
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  /// </remarks>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <returns>A pattern for parsing and formatting local dates.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  static OffsetDatePattern CreateWithCurrentCulture(String patternText) =>
      Create(patternText, NodaFormatInfo.CurrentInfo, DefaultTemplateValue);

  /// <summary>
  /// Creates a pattern for the same original localization information as this pattern, but with the specified
  /// pattern text.
  /// </summary>
  /// <param name="patternText">The pattern text to use in the new pattern.</param>
  /// <returns>A new pattern with the given pattern text.</returns>
  OffsetDatePattern WithPatternText(String patternText) =>
      Create(patternText, FormatInfo, TemplateValue);

  /// <summary>
  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// localization information.
  /// </summary>
  /// <param name="formatInfo">The localization information to use in the new pattern.</param>
  /// <returns>A new pattern with the given localization information.</returns>
  @private OffsetDatePattern WithFormatInfo(NodaFormatInfo formatInfo) =>
      Create(PatternText, formatInfo, TemplateValue);

  /// <summary>
  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  /// </summary>
  /// <param name="cultureInfo">The culture to use in the new pattern.</param>
  /// <returns>A new pattern with the given culture.</returns>
  OffsetDatePattern WithCulture(CultureInfo cultureInfo) =>
      WithFormatInfo(NodaFormatInfo.GetFormatInfo(cultureInfo));

  /// <summary>
  /// Creates a pattern for the same original pattern text and culture as this pattern, but with
  /// the specified template value.
  /// </summary>
  /// <param name="newTemplateValue">The template value to use in the new pattern.</param>
  /// <returns>A new pattern with the given template value.</returns>
  OffsetDatePattern WithTemplateValue(OffsetDate newTemplateValue) =>
      Create(PatternText, FormatInfo, newTemplateValue);

  /// <summary>
  /// Creates a pattern like this one, but with the template value modified to use
  /// the specified calendar system.
  /// </summary>
  /// <remarks>
  /// <para>
  /// Care should be taken in two (relatively rare) scenarios. Although the default template value
  /// is supported by all Noda Time calendar systems, if a pattern is created with a different
  /// template value and then this method is called with a calendar system which doesn't support that
  /// date, an exception will be thrown. Additionally, if the pattern only specifies some date fields,
  /// it's possible that the new template value will not be suitable for all values.
  /// </para>
  /// </remarks>
  /// <param name="calendar">The calendar system to convert the template value into.</param>
  /// <returns>A new pattern with a template value in the specified calendar system.</returns>
  OffsetDatePattern WithCalendar(CalendarSystem calendar) =>
      WithTemplateValue(TemplateValue.WithCalendar(calendar));
}