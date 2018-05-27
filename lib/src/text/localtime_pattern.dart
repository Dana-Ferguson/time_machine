// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Text/LocalTimePattern.cs
// 57e7c6f  on Nov 8, 2017

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
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


/// <summary>
/// Represents a pattern for parsing and formatting <see cref="LocalTime"/> values.
/// </summary>
/// <threadsafety>
/// When used with a read-only <see cref="CultureInfo" />, this type is immutable and instances
/// may be shared freely between threads. We recommend only using read-only cultures for patterns, although this is
/// not currently enforced.
/// </threadsafety>
@immutable // Well, assuming an immutable culture...
/*sealed*/ class LocalTimePattern implements IPattern<LocalTime> {
  /// <summary>
  /// Gets an invariant local time pattern which is ISO-8601 compatible, providing up to 9 decimal places.
  /// (These digits are omitted when unnecessary.)
  /// This corresponds to the text pattern "HH':'mm':'ss;FFFFFFFFF".
  /// </summary>
  /// <value>An invariant local time pattern which is ISO-8601 compatible, providing up to 9 decimal places.</value>
  static final LocalTimePattern ExtendedIso = _Patterns.ExtendedIsoPatternImpl;

  @private static const String DefaultFormatPattern = "T"; // Long

  //internal static readonly PatternBclSupport<LocalTime> BclSupport =
  //new PatternBclSupport<LocalTime>(DefaultFormatPattern, fi => fi.LocalTimePatternParser);

  /// <summary>
  /// Returns the pattern that this object delegates to. Mostly useful to avoid this class
  /// implementing an internal interface.
  /// </summary>
  @internal final IPartialPattern<LocalTime> UnderlyingPattern;

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
  final LocalTime TemplateValue;

  @private LocalTimePattern(this.PatternText, this.FormatInfo, this.TemplateValue, this.UnderlyingPattern);

  /// <summary>
  /// Parses the given text value according to the rules of this pattern.
  /// </summary>
  /// <remarks>
  /// This method never throws an exception (barring a bug in Noda Time itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  /// </remarks>
  /// <param name="text">The text value to parse.</param>
  /// <returns>The result of parsing, which may be successful or unsuccessful.</returns>
  ParseResult<LocalTime> Parse(String text) => UnderlyingPattern.Parse(text);

  /// <summary>
  /// Formats the given local time as text according to the rules of this pattern.
  /// </summary>
  /// <param name="value">The local time to format.</param>
  /// <returns>The local time formatted according to this pattern.</returns>
  String Format(LocalTime value) => UnderlyingPattern.Format(value);

  /// <summary>
  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given <see cref="StringBuilder"/>.
  /// </summary>
  /// <param name="value">The value to format.</param>
  /// <param name="builder">The <c>StringBuilder</c> to append to.</param>
  /// <returns>The builder passed in as <paramref name="builder"/>.</returns>
  StringBuffer AppendFormat(LocalTime value, StringBuffer builder) => UnderlyingPattern.AppendFormat(value, builder);

  /// <summary>
  /// Creates a pattern for the given pattern text, format info, and template value.
  /// </summary>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <param name="formatInfo">The format info to use in the pattern</param>
  /// <param name="templateValue">Template value to use for unspecified fields</param>
  /// <returns>A pattern for parsing and formatting local times.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  @internal static LocalTimePattern Create(String patternText, NodaFormatInfo formatInfo,
      LocalTime templateValue) {
    Preconditions.checkNotNull(patternText, 'patternText');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    // Use the "fixed" parser for the common case of the default template value.
    var pattern = templateValue == LocalTime.Midnight
        ? formatInfo.LocalTimePatternParser.ParsePattern(patternText)
        : new LocalTimePatternParser(templateValue).ParsePattern(patternText, formatInfo);
    // If ParsePattern returns a standard pattern instance, we need to get the underlying partial pattern.
    // (Alternatively, we could just return it directly, instead of creating a new object.)
    pattern = (pattern as LocalTimePattern)?.UnderlyingPattern ?? pattern;
    var partialPattern = pattern as IPartialPattern<LocalTime>;
    return new LocalTimePattern(patternText, formatInfo, templateValue, partialPattern);
  }

// todo: Create names

  /// <summary>
  /// Creates a pattern for the given pattern text, culture, and template value.
  /// </summary>
  /// <remarks>
  /// See the user guide for the available pattern text options.
  /// </remarks>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <param name="cultureInfo">The culture to use in the pattern</param>
  /// <param name="templateValue">Template value to use for unspecified fields</param>
  /// <returns>A pattern for parsing and formatting local times.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  static LocalTimePattern Create2(String patternText, CultureInfo cultureInfo, LocalTime templateValue) =>
      Create(patternText, NodaFormatInfo.GetFormatInfo(cultureInfo), templateValue);

  /// <summary>
  /// Creates a pattern for the given pattern text and culture, with a template value of midnight.
  /// </summary>
  /// <remarks>
  /// See the user guide for the available pattern text options.
  /// </remarks>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <param name="cultureInfo">The culture to use in the pattern</param>
  /// <returns>A pattern for parsing and formatting local times.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  static LocalTimePattern Create3(String patternText, CultureInfo cultureInfo) =>
      Create2(patternText, cultureInfo, LocalTime.Midnight);

  /// <summary>
  /// Creates a pattern for the given pattern text in the current thread's current culture.
  /// </summary>
  /// <remarks>
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  /// </remarks>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <returns>A pattern for parsing and formatting local times.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  static LocalTimePattern CreateWithCurrentCulture(String patternText) =>
      Create(patternText, NodaFormatInfo.CurrentInfo, LocalTime.Midnight);

  /// <summary>
  /// Creates a pattern for the given pattern text in the invariant culture.
  /// </summary>
  /// <remarks>
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  /// </remarks>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <returns>A pattern for parsing and formatting local times.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  static LocalTimePattern CreateWithInvariantCulture(String patternText) =>
      Create(patternText, NodaFormatInfo.InvariantInfo, LocalTime.Midnight);

  /// <summary>
  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// localization information.
  /// </summary>
  /// <param name="formatInfo">The localization information to use in the new pattern.</param>
  /// <returns>A new pattern with the given localization information.</returns>
  @private LocalTimePattern WithFormatInfo(NodaFormatInfo formatInfo) =>
      Create(PatternText, formatInfo, TemplateValue);

  /// <summary>
  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  /// </summary>
  /// <param name="cultureInfo">The culture to use in the new pattern.</param>
  /// <returns>A new pattern with the given culture.</returns>
  LocalTimePattern WithCulture(CultureInfo cultureInfo) =>
      WithFormatInfo(NodaFormatInfo.GetFormatInfo(cultureInfo));

  /// <summary>
  /// Creates a pattern like this one, but with the specified template value.
  /// </summary>
  /// <param name="newTemplateValue">The template value for the new pattern, used to fill in unspecified fields.</param>
  /// <returns>A new pattern with the given template value.</returns>
  LocalTimePattern WithTemplateValue(LocalTime newTemplateValue) =>
      Create(PatternText, FormatInfo, newTemplateValue);
}