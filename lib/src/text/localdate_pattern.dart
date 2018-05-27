// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Text/LocalDatePattern.cs
// 95327c5  on Apr 10, 2017

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
@private abstract class _Patterns
{
  @internal static final LocalDatePattern IsoPatternImpl = LocalDatePattern.CreateWithInvariantCulture("uuuu'-'MM'-'dd");
}


/// <summary>
/// Represents a pattern for parsing and formatting <see cref="LocalDate"/> values.
/// </summary>
/// <threadsafety>
/// When used with a read-only <see cref="CultureInfo" />, this type is immutable and instances
/// may be shared freely between threads. We recommend only using read-only cultures for patterns, although this is
/// not currently enforced.
/// </threadsafety>
@immutable // Well, assuming an immutable culture...
/*sealed*/ class LocalDatePattern implements IPattern<LocalDate> {
  @internal static final LocalDate DefaultTemplateValue = new LocalDate(2000, 1, 1);

  @private static const String DefaultFormatPattern = "D"; // Long

  @internal static final PatternBclSupport<LocalDate> BclSupport = new PatternBclSupport<LocalDate>(DefaultFormatPattern, (fi) => fi.LocalDatePatternParser);

  /// <summary>
  /// Gets an invariant local date pattern which is ISO-8601 compatible.
  /// This corresponds to the text pattern "uuuu'-'MM'-'dd".
  /// </summary>
  /// <value>An invariant local date pattern which is ISO-8601 compatible.</value>
  static final LocalDatePattern Iso = _Patterns.IsoPatternImpl;

  /// <summary>
  /// Returns the pattern that this object delegates to. Mostly useful to avoid this class
  /// implementing an internal interface.
  /// </summary>
  @internal final IPartialPattern<LocalDate> UnderlyingPattern;

  /// <summary>
  /// Gets the pattern text for this pattern, as supplied on creation.
  /// </summary>
  /// <value>The pattern text for this pattern, as supplied on creation.</value>
  final String PatternText;

  /// <summary>
  /// Returns the localization information used in this pattern.
  /// </summary>
  @internal final NodaFormatInfo FormatInfo;

  /// <summary>
  /// Gets the value used as a template for parsing: any field values unspecified
  /// in the pattern are taken from the template.
  /// </summary>
  /// <value>The value used as a template for parsing.</value>
  final LocalDate TemplateValue;

  @private LocalDatePattern(this.PatternText, this.FormatInfo, this.TemplateValue, this.UnderlyingPattern);

  /// <summary>
  /// Parses the given text value according to the rules of this pattern.
  /// </summary>
  /// <remarks>
  /// This method never throws an exception (barring a bug in Noda Time itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  /// </remarks>
  /// <param name="text">The text value to parse.</param>
  /// <returns>The result of parsing, which may be successful or unsuccessful.</returns>
  ParseResult<LocalDate> Parse(String text) => UnderlyingPattern.Parse(text);

  /// <summary>
  /// Formats the given local date as text according to the rules of this pattern.
  /// </summary>
  /// <param name="value">The local date to format.</param>
  /// <returns>The local date formatted according to this pattern.</returns>
  String Format(LocalDate value) => UnderlyingPattern.Format(value);

  /// <summary>
  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given <see cref="StringBuilder"/>.
  /// </summary>
  /// <param name="value">The value to format.</param>
  /// <param name="builder">The <c>StringBuilder</c> to append to.</param>
  /// <returns>The builder passed in as <paramref name="builder"/>.</returns>
  StringBuffer AppendFormat(LocalDate value, StringBuffer builder) => UnderlyingPattern.AppendFormat(value, builder);

  /// <summary>
  /// Creates a pattern for the given pattern text, format info, and template value.
  /// </summary>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <param name="formatInfo">The format info to use in the pattern</param>
  /// <param name="templateValue">Template value to use for unspecified fields</param>
  /// <returns>A pattern for parsing and formatting local dates.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  @internal static LocalDatePattern Create(String patternText, NodaFormatInfo formatInfo, LocalDate templateValue) {
    Preconditions.checkNotNull(patternText, 'patternText');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    // Use the "fixed" parser for the common case of the default template value.
    var pattern = templateValue == DefaultTemplateValue
        ? formatInfo.LocalDatePatternParser.ParsePattern(patternText)
        : new LocalDatePatternParser(templateValue).ParsePattern(patternText, formatInfo);
    // If ParsePattern returns a standard pattern instance, we need to get the underlying partial pattern.
    pattern = (pattern as LocalDatePattern)?.UnderlyingPattern ?? pattern;
    var partialPattern = pattern as IPartialPattern<LocalDate>;
    return new LocalDatePattern(patternText, formatInfo, templateValue, partialPattern);
  }

  // todo: naming strategy: Create, Create2, Create3
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
  static LocalDatePattern Create2(String patternText, CultureInfo cultureInfo, LocalDate templateValue) =>
      Create(patternText, NodaFormatInfo.GetFormatInfo(cultureInfo), templateValue);

  /// <summary>
  /// Creates a pattern for the given pattern text and culture, with a template value of 2000-01-01.
  /// </summary>
  /// <remarks>
  /// See the user guide for the available pattern text options.
  /// </remarks>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <param name="cultureInfo">The culture to use in the pattern</param>
  /// <returns>A pattern for parsing and formatting local dates.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  static LocalDatePattern Create3(String patternText, CultureInfo cultureInfo) => Create2(patternText, cultureInfo, DefaultTemplateValue);

  /// <summary>
  /// Creates a pattern for the given pattern text in the current thread's current culture.
  /// </summary>
  /// <remarks>
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  /// </remarks>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <returns>A pattern for parsing and formatting local dates.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  static LocalDatePattern CreateWithCurrentCulture(String patternText) => Create(patternText, NodaFormatInfo.CurrentInfo, DefaultTemplateValue);

  /// <summary>
  /// Creates a pattern for the given pattern text in the invariant culture.
  /// </summary>
  /// <remarks>
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  /// </remarks>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <returns>A pattern for parsing and formatting local dates.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  static LocalDatePattern CreateWithInvariantCulture(String patternText) => Create(patternText, NodaFormatInfo.InvariantInfo, DefaultTemplateValue);

  /// <summary>
  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// localization information.
  /// </summary>
  /// <param name="formatInfo">The localization information to use in the new pattern.</param>
  /// <returns>A new pattern with the given localization information.</returns>
  @private LocalDatePattern WithFormatInfo(NodaFormatInfo formatInfo) => Create(PatternText, formatInfo, TemplateValue);

  /// <summary>
  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  /// </summary>
  /// <param name="cultureInfo">The culture to use in the new pattern.</param>
  /// <returns>A new pattern with the given culture.</returns>
  LocalDatePattern WithCulture(CultureInfo cultureInfo) => WithFormatInfo(NodaFormatInfo.GetFormatInfo(cultureInfo));

  /// <summary>
  /// Creates a pattern like this one, but with the specified template value.
  /// </summary>
  /// <param name="newTemplateValue">The template value for the new pattern, used to fill in unspecified fields.</param>
  /// <returns>A new pattern with the given template value.</returns>
  LocalDatePattern WithTemplateValue(LocalDate newTemplateValue) => Create(PatternText, FormatInfo, newTemplateValue);

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
  LocalDatePattern WithCalendar(CalendarSystem calendar) => WithTemplateValue(TemplateValue.WithCalendar(calendar));
}