// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Text/OffsetPattern.cs
// 32a15d0  on Aug 24, 2017

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
/// Represents a pattern for parsing and formatting <see cref="Offset"/> values.
/// </summary>
/// <threadsafety>
/// When used with a read-only <see cref="CultureInfo" />, this type is immutable and instances
/// may be shared freely between threads. We recommend only using read-only cultures for patterns, although this is
/// not currently enforced.
/// </threadsafety>
@immutable // Well, assuming an immutable culture...
/*sealed*/ class OffsetPattern implements IPattern<Offset> {
  /// <summary>
  /// The "general" offset pattern (e.g. +HH, +HH:mm, +HH:mm:ss, +HH:mm:ss.fff) for the invariant culture.
  /// </summary>
  /// <value>The "general" offset pattern for the invariant culture.</value>
  static final OffsetPattern GeneralInvariant = CreateWithInvariantCulture("g");

  /// <summary>
  /// The "general" offset pattern (e.g. +HH, +HH:mm, +HH:mm:ss, +HH:mm:ss.fff) for the invariant culture,
  /// but producing (and allowing) Z as a value for a zero offset.
  /// </summary>
  /// <value>The "general" offset pattern for the invariant culture but producing (and allowing) Z as a value for a zero offset.</value>
  static final OffsetPattern GeneralInvariantWithZ = CreateWithInvariantCulture("G");

  @private static const String DefaultFormatPattern = "g";

  @internal static final PatternBclSupport<Offset> BclSupport = new PatternBclSupport<Offset>(DefaultFormatPattern, (fi) => fi.offsetPatternParser);

  /// <summary>
  /// Gets the pattern text for this pattern, as supplied on creation.
  /// </summary>
  /// <value>The pattern text for this pattern, as supplied on creation.</value>
  final String PatternText;

  /// <summary>
  /// Returns the pattern that this object delegates to. Mostly useful to avoid this class
  /// implementing an @internal interface.
  /// </summary>
  @internal final IPartialPattern<Offset> UnderlyingPattern;

  @private OffsetPattern(this.PatternText, this.UnderlyingPattern);

  /// <summary>
  /// Parses the given text value according to the rules of this pattern.
  /// </summary>
  /// <remarks>
  /// This method never throws an exception (barring a bug in Noda Time itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  /// </remarks>
  /// <param name="text">The text value to parse.</param>
  /// <returns>The result of parsing, which may be successful or unsuccessful.</returns>
  ParseResult<Offset> Parse(String text) => UnderlyingPattern.Parse(text);

  /// <summary>
  /// Formats the given offset as text according to the rules of this pattern.
  /// </summary>
  /// <param name="value">The offset to format.</param>
  /// <returns>The offset formatted according to this pattern.</returns>
  String Format(Offset value) => UnderlyingPattern.Format(value);

  /// <summary>
  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given <see cref="StringBuilder"/>.
  /// </summary>
  /// <param name="value">The value to format.</param>
  /// <param name="builder">The <c>StringBuilder</c> to append to.</param>
  /// <returns>The builder passed in as <paramref name="builder"/>.</returns>
  StringBuffer AppendFormat(Offset value, StringBuffer builder) => UnderlyingPattern.AppendFormat(value, builder);

  /// <summary>
  /// Creates a pattern for the given pattern text and format info.
  /// </summary>
  /// <param name="patternText">Pattern text to create the pattern for</param>
  /// <param name="formatInfo">Localization information</param>
  /// <returns>A pattern for parsing and formatting offsets.</returns>
  /// <exception cref="InvalidPatternException">The pattern text was invalid.</exception>
  @internal static OffsetPattern Create(String patternText, NodaFormatInfo formatInfo) {
    Preconditions.checkNotNull(patternText, 'patternText');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    var pattern = formatInfo.offsetPatternParser.ParsePattern(patternText) as IPartialPattern<Offset>;
    return new OffsetPattern(patternText, pattern);
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
  static OffsetPattern Create2(String patternText, CultureInfo cultureInfo) =>
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
  static OffsetPattern CreateWithCurrentCulture(String patternText) =>
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
  static OffsetPattern CreateWithInvariantCulture(String patternText) => Create(patternText, NodaFormatInfo.InvariantInfo);

  /// <summary>
  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  /// </summary>
  /// <param name="cultureInfo">The culture to use in the new pattern.</param>
  /// <returns>A new pattern with the given culture.</returns>
  OffsetPattern WithCulture(CultureInfo cultureInfo) => Create(PatternText, NodaFormatInfo.GetFormatInfo(cultureInfo));
}