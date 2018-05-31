// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Text/LocalDateTimePattern.cs
// 95327c5  on Apr 10, 2017

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';

/// <summary>
/// Class whose existence is solely to avoid type initialization order issues, most of which stem
/// from needing NodaFormatInfo.InvariantInfo...
/// </summary>
@internal abstract class LocalDateTimePatterns
{
  @internal static final LocalDateTimePattern GeneralIsoPatternImpl = LocalDateTimePattern.CreateWithInvariantCulture("uuuu'-'MM'-'dd'T'HH':'mm':'ss");
  @internal static final LocalDateTimePattern ExtendedIsoPatternImpl = LocalDateTimePattern.CreateWithInvariantCulture("uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFF");
  @internal static final LocalDateTimePattern BclRoundtripPatternImpl = LocalDateTimePattern.CreateWithInvariantCulture("uuuu'-'MM'-'dd'T'HH':'mm':'ss'.'fffffff");
  @internal static final LocalDateTimePattern FullRoundtripWithoutCalendarImpl = LocalDateTimePattern.CreateWithInvariantCulture("uuuu'-'MM'-'dd'T'HH':'mm':'ss'.'fffffffff");
  @internal static final LocalDateTimePattern FullRoundtripPatternImpl = LocalDateTimePattern.CreateWithInvariantCulture("uuuu'-'MM'-'dd'T'HH':'mm':'ss'.'fffffffff '('c')'");
}

/// <summary>
/// Represents a pattern for parsing and formatting <see cref="LocalDateTime"/> values.
/// </summary>
/// <threadsafety>
/// When used with a read-only <see cref="CultureInfo" />, this type is immutable and instances
/// may be shared freely between threads. We recommend only using read-only cultures for patterns, although this is
/// not currently enforced.
/// </threadsafety>
@immutable // Well, assuming an immutable culture...
/*sealed*/ class LocalDateTimePattern implements IPattern<LocalDateTime> {
  @internal static final LocalDateTime DefaultTemplateValue = new LocalDateTime.fromYMDHM(2000, 1, 1, 0, 0);

  @private static const String DefaultFormatPattern = "G"; // General (long time)

  @internal static final PatternBclSupport<LocalDateTime> BclSupport = new PatternBclSupport<LocalDateTime>(
      DefaultFormatPattern, (fi) => fi.localDateTimePatternParser);

  /// <summary>
  /// Gets an invariant local date/time pattern which is ISO-8601 compatible, down to the second.
  /// This corresponds to the text pattern "uuuu'-'MM'-'dd'T'HH':'mm':'ss", and is also used as the "sortable"
  /// standard pattern.
  /// </summary>
  /// <value>An invariant local date/time pattern which is ISO-8601 compatible, down to the second.</value>
  static LocalDateTimePattern get GeneralIso => LocalDateTimePatterns.GeneralIsoPatternImpl;

  /// <summary>
  /// Gets an invariant local date/time pattern which is ISO-8601 compatible, providing up to 9 decimal places
  /// of sub-second accuracy. (These digits are omitted when unnecessary.)
  /// This corresponds to the text pattern "uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFF".
  /// </summary>
  /// <value>An invariant local date/time pattern which is ISO-8601 compatible, providing up to 9 decimal places
  /// of sub-second accuracy.</value>
  static LocalDateTimePattern get ExtendedIso => LocalDateTimePatterns.ExtendedIsoPatternImpl;

  /// <summary>
  /// Gets an invariant local date/time pattern which is ISO-8601 compatible, providing up to 7 decimal places
  /// of sub-second accuracy which are always present (including trailing zeroes). This is compatible with the
  /// BCL round-trip formatting of <see cref="DateTime"/> values with a kind of "unspecified".
  /// This corresponds to the text pattern "uuuu'-'MM'-'dd'T'HH':'mm':'ss'.'fffffff". It does not necessarily
  /// round-trip all <c>LocalDateTime</c> values as it will lose sub-tick information. Use
  /// <see cref="FullRoundtripWithoutCalendar"/>
  /// </summary>
  /// <value>An invariant local date/time pattern which is ISO-8601 compatible, providing up to 7 decimal places
  /// of sub-second accuracy which are always present (including trailing zeroes).</value>
  static LocalDateTimePattern get BclRoundtrip => LocalDateTimePatterns.BclRoundtripPatternImpl;

  /// <summary>
  /// Gets an invariant local date/time pattern which round trips values, but doesn't include the calendar system.
  /// It provides up to 9 decimal places of sub-second accuracy which are always present (including trailing zeroes).
  /// This corresponds to the text pattern "uuuu'-'MM'-'dd'T'HH':'mm':'ss'.'fffffffff". It will
  /// round-trip all <see cref="LocalDateTime"/> values if the calendar system of the template value is the same
  /// as the calendar system of the original value.
  /// </summary>
  /// <value>An invariant local date/time pattern which is ISO-8601 compatible, providing up to 7 decimal places
  /// of sub-second accuracy which are always present (including trailing zeroes).</value>
  static LocalDateTimePattern get FullRoundtripWithoutCalendar => LocalDateTimePatterns.FullRoundtripWithoutCalendarImpl;

  /// <summary>
  /// Gets an invariant local date/time pattern which round trips values including the calendar system.
  /// This corresponds to the text pattern "uuuu'-'MM'-'dd'T'HH':'mm':'ss'.'fffffffff '('c')'".
  /// </summary>
  /// <value>An invariant local date/time pattern which round trips values including the calendar system.</value>
  static LocalDateTimePattern get FullRoundtrip => LocalDateTimePatterns.FullRoundtripPatternImpl;

  /// <summary>
  /// Gets the pattern text for this pattern, as supplied on creation.
  /// </summary>
  /// <value>The pattern text for this pattern, as supplied on creation.</value>
  final String PatternText;

  /// <summary>
  /// Gets the localization information used in this pattern.
  /// </summary>
  /// <value>The localization information used in this pattern.</value>
  @internal final NodaFormatInfo FormatInfo;

  /// <summary>
  /// Get the value used as a template for parsing: any field values unspecified
  /// in the pattern are taken from the template.
  /// </summary>
  /// <value>The value used as a template for parsing.</value>
  final LocalDateTime TemplateValue;

  /// <summary>
  /// Returns the pattern that this object delegates to. Mostly useful to avoid this public class
  /// implementing an @internal interface.
  /// </summary>
  @internal final IPartialPattern<LocalDateTime> UnderlyingPattern;

  @private LocalDateTimePattern(this.PatternText, this.FormatInfo, this.TemplateValue, this.UnderlyingPattern);

  /// <summary>
  /// Parses the given text value according to the rules of this pattern.
  /// </summary>
  /// <remarks>
  /// This method never throws an exception (barring a bug in Noda Time itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  /// </remarks>
  /// <param name="text">The text value to parse.</param>
  /// <returns>The result of parsing, which may be successful or unsuccessful.</returns>
  ParseResult<LocalDateTime> Parse(String text) => UnderlyingPattern.Parse(text);

  /// <summary>
  /// Formats the given local date/time as text according to the rules of this pattern.
  /// </summary>
  /// <param name="value">The local date/time to format.</param>
  /// <returns>The local date/time formatted according to this pattern.</returns>
  String Format(LocalDateTime value) => UnderlyingPattern.Format(value);

  /// <summary>
  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given <see cref="StringBuilder"/>.
  /// </summary>
  /// <param name="value">The value to format.</param>
  /// <param name="builder">The <c>StringBuilder</c> to append to.</param>
  /// <returns>The builder passed in as <paramref name="builder"/>.</returns>
  StringBuffer AppendFormat(LocalDateTime value, StringBuffer builder) => UnderlyingPattern.AppendFormat(value, builder);

// todo: create, create2, create3

  /// <summary>
  /// Creates a pattern for the given pattern text, format info, and template value.
  /// </summary>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <param name="formatInfo">The format info to use in the pattern</param>
  /// <param name="templateValue">Template value to use for unspecified fields</param>
  /// <returns>A pattern for parsing and formatting local date/times.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  @internal static LocalDateTimePattern Create(String patternText, NodaFormatInfo formatInfo,
      LocalDateTime templateValue) {
    Preconditions.checkNotNull(patternText, 'patternText');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    // Use the "fixed" parser for the common case of the default template value.
    var pattern = templateValue == DefaultTemplateValue
        ? formatInfo.localDateTimePatternParser.ParsePattern(patternText)
        : new LocalDateTimePatternParser(templateValue).ParsePattern(patternText, formatInfo);
    // If ParsePattern returns a standard pattern instance, we need to get the underlying partial pattern.
    pattern = pattern is LocalDateTimePattern ? pattern.UnderlyingPattern : pattern;
    var partialPattern = pattern as IPartialPattern<LocalDateTime>;
    return new LocalDateTimePattern(patternText, formatInfo, templateValue, partialPattern);
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
  /// <returns>A pattern for parsing and formatting local date/times.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  static LocalDateTimePattern Create2(String patternText, CultureInfo cultureInfo,
      LocalDateTime templateValue) =>
      Create(patternText, NodaFormatInfo.GetFormatInfo(cultureInfo), templateValue);

  /// <summary>
  /// Creates a pattern for the given pattern text and culture, with a template value of midnight on 2000-01-01.
  /// </summary>
  /// <remarks>
  /// See the user guide for the available pattern text options.
  /// </remarks>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <param name="cultureInfo">The culture to use in the pattern</param>
  /// <returns>A pattern for parsing and formatting local date/times.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  static LocalDateTimePattern Create3(String patternText, CultureInfo cultureInfo) =>
      Create2(patternText, cultureInfo, DefaultTemplateValue);

  /// <summary>
  /// Creates a pattern for the given pattern text in the current thread's current culture.
  /// </summary>
  /// <remarks>
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  /// </remarks>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <returns>A pattern for parsing and formatting local date/times.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  static LocalDateTimePattern CreateWithCurrentCulture(String patternText) =>
      Create(patternText, NodaFormatInfo.CurrentInfo, DefaultTemplateValue);

  /// <summary>
  /// Creates a pattern for the given pattern text in the invariant culture.
  /// </summary>
  /// <remarks>
  /// See the user guide for the available pattern text options.
  /// </remarks>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <returns>A pattern for parsing and formatting local date/times.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  static LocalDateTimePattern CreateWithInvariantCulture(String patternText) =>
      Create(patternText, NodaFormatInfo.InvariantInfo, DefaultTemplateValue);

  /// <summary>
  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// localization information.
  /// </summary>
  /// <param name="formatInfo">The localization information to use in the new pattern.</param>
  /// <returns>A new pattern with the given localization information.</returns>
  @private LocalDateTimePattern WithFormatInfo(NodaFormatInfo formatInfo) =>
      Create(PatternText, formatInfo, TemplateValue);

  /// <summary>
  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  /// </summary>
  /// <param name="cultureInfo">The culture to use in the new pattern.</param>
  /// <returns>A new pattern with the given culture.</returns>
  LocalDateTimePattern WithCulture(CultureInfo cultureInfo) =>
      WithFormatInfo(NodaFormatInfo.GetFormatInfo(cultureInfo));

  /// <summary>
  /// Creates a pattern like this one, but with the specified template value.
  /// </summary>
  /// <param name="newTemplateValue">The template value for the new pattern, used to fill in unspecified fields.</param>
  /// <returns>A new pattern with the given template value.</returns>
  LocalDateTimePattern WithTemplateValue(LocalDateTime newTemplateValue) =>
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
  LocalDateTimePattern WithCalendar(CalendarSystem calendar) =>
      WithTemplateValue(TemplateValue.WithCalendar(calendar));
}