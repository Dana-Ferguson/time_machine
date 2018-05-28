// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Text/DurationPattern.cs
// 32a15d0  on Aug 24, 2017

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';

// Nested class for ease of type initialization
@internal abstract class DurationPatterns
{
  @internal static final DurationPattern RoundtripPatternImpl = DurationPattern.CreateWithInvariantCulture("-D:hh:mm:ss.FFFFFFFFF");
}

/// <summary>
/// Represents a pattern for parsing and formatting <see cref="Duration"/> values.
/// </summary>
/// <threadsafety>
/// When used with a read-only <see cref="CultureInfo" />, this type is immutable and instances
/// may be shared freely between threads. We recommend only using read-only cultures for patterns, although this is
/// not currently enforced.
/// </threadsafety>
@immutable // Well, assuming an immutable culture...
/*sealed*/ class DurationPattern implements IPattern<Duration> {
  /// <summary>
  /// Gets the general pattern for durations using the invariant culture, with a format string of "-D:hh:mm:ss.FFFFFFFFF".
  /// This pattern round-trips.
  /// </summary>
  /// <value>The general pattern for durations using the invariant culture.</value>
  static DurationPattern get Roundtrip => DurationPatterns.RoundtripPatternImpl;

  @internal static final PatternBclSupport<Duration> BclSupport = new PatternBclSupport<Duration>("o", (fi) => fi.durationPatternParser);

  @private final IPattern<Duration> pattern;

  /// <summary>
  /// Gets the pattern text for this pattern, as supplied on creation.
  /// </summary>
  /// <value>The pattern text for this pattern, as supplied on creation.</value>
  final String PatternText;

  @private DurationPattern(this.PatternText, this.pattern);

  /// <summary>
  /// Parses the given text value according to the rules of this pattern.
  /// </summary>
  /// <remarks>
  /// This method never throws an exception (barring a bug in Noda Time itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  /// </remarks>
  /// <param name="text">The text value to parse.</param>
  /// <returns>The result of parsing, which may be successful or unsuccessful.</returns>
  ParseResult<Duration> Parse(String text) => pattern.Parse(text);

  /// <summary>
  /// Formats the given duration as text according to the rules of this pattern.
  /// </summary>
  /// <param name="value">The duration to format.</param>
  /// <returns>The duration formatted according to this pattern.</returns>
  String Format(Duration value) => pattern.Format(value);

  /// <summary>
  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given <see cref="StringBuilder"/>.
  /// </summary>
  /// <param name="value">The value to format.</param>
  /// <param name="builder">The <c>StringBuilder</c> to append to.</param>
  /// <returns>The builder passed in as <paramref name="builder"/>.</returns>
  StringBuffer AppendFormat(Duration value, StringBuffer builder) => pattern.AppendFormat(value, builder);

  /// <summary>
  /// Creates a pattern for the given pattern text and format info.
  /// </summary>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <param name="formatInfo">Localization information</param>
  /// <returns>A pattern for parsing and formatting offsets.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  @private static DurationPattern Create(String patternText, NodaFormatInfo formatInfo) {
    Preconditions.checkNotNull(patternText, 'patternTex');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    var pattern = formatInfo.durationPatternParser.ParsePattern(patternText);
    return new DurationPattern(patternText, pattern);
  }

  /// <summary>
  /// Creates a pattern for the given pattern text and culture.
  /// </summary>
  /// <remarks>
  /// See the user guide for the available pattern text options.
  /// </remarks>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <param name="cultureInfo">The culture to use in the pattern</param>
  /// <returns>A pattern for parsing and formatting offsets.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  static DurationPattern Create2(String patternText, CultureInfo cultureInfo) =>
      Create(patternText, NodaFormatInfo.GetFormatInfo(cultureInfo));

  /// <summary>
  /// Creates a pattern for the given pattern text in the current thread's current culture.
  /// </summary>
  /// <remarks>
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  /// </remarks>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <returns>A pattern for parsing and formatting offsets.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  static DurationPattern CreateWithCurrentCulture(String patternText) =>
      Create(patternText, NodaFormatInfo.CurrentInfo);

  /// <summary>
  /// Creates a pattern for the given pattern text in the invariant culture.
  /// </summary>
  /// <remarks>
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  /// </remarks>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <returns>A pattern for parsing and formatting offsets.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  static DurationPattern CreateWithInvariantCulture(String patternText) =>
      Create(patternText, NodaFormatInfo.InvariantInfo);

  /// <summary>
  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  /// </summary>
  /// <param name="cultureInfo">The culture to use in the new pattern.</param>
  /// <returns>A new pattern with the given culture.</returns>
  DurationPattern WithCulture(CultureInfo cultureInfo) =>
      Create(PatternText, NodaFormatInfo.GetFormatInfo(cultureInfo));
}