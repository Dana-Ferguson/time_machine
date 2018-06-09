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
@internal abstract class LocalDateTimePatterns
{
  @internal static final LocalDateTimePattern GeneralIsoPatternImpl = LocalDateTimePattern.CreateWithInvariantCulture("uuuu'-'MM'-'dd'T'HH':'mm':'ss");
  @internal static final LocalDateTimePattern ExtendedIsoPatternImpl = LocalDateTimePattern.CreateWithInvariantCulture("uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFF");
  @internal static final LocalDateTimePattern BclRoundtripPatternImpl = LocalDateTimePattern.CreateWithInvariantCulture("uuuu'-'MM'-'dd'T'HH':'mm':'ss'.'fffffff");
  @internal static final LocalDateTimePattern FullRoundtripWithoutCalendarImpl = LocalDateTimePattern.CreateWithInvariantCulture("uuuu'-'MM'-'dd'T'HH':'mm':'ss'.'fffffffff");
  @internal static final LocalDateTimePattern FullRoundtripPatternImpl = LocalDateTimePattern.CreateWithInvariantCulture("uuuu'-'MM'-'dd'T'HH':'mm':'ss'.'fffffffff '('c')'");
}

/// Represents a pattern for parsing and formatting [LocalDateTime] values.
///
/// <threadsafety>
/// When used with a read-only [CultureInfo], this type is immutable and instances
/// may be shared freely between threads. We recommend only using read-only cultures for patterns, although this is
/// not currently enforced.
/// </threadsafety>
@immutable // Well, assuming an immutable culture...
/*sealed*/ class LocalDateTimePattern implements IPattern<LocalDateTime> {
  @internal static final LocalDateTime DefaultTemplateValue = new LocalDateTime.fromYMDHM(2000, 1, 1, 0, 0);

  @private static const String DefaultFormatPattern = "G"; // General (long time)

  @internal static final PatternBclSupport<LocalDateTime> BclSupport = new PatternBclSupport<LocalDateTime>(
      DefaultFormatPattern, (fi) => fi.localDateTimePatternParser);

  /// Gets an invariant local date/time pattern which is ISO-8601 compatible, down to the second.
  /// This corresponds to the text pattern "uuuu'-'MM'-'dd'T'HH':'mm':'ss", and is also used as the "sortable"
  /// standard pattern.
  static LocalDateTimePattern get GeneralIso => LocalDateTimePatterns.GeneralIsoPatternImpl;

  /// Gets an invariant local date/time pattern which is ISO-8601 compatible, providing up to 9 decimal places
  /// of sub-second accuracy. (These digits are omitted when unnecessary.)
  /// This corresponds to the text pattern "uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFF".
  ///
  /// <value>An invariant local date/time pattern which is ISO-8601 compatible, providing up to 9 decimal places
  /// of sub-second accuracy.</value>
  static LocalDateTimePattern get ExtendedIso => LocalDateTimePatterns.ExtendedIsoPatternImpl;

  /// Gets an invariant local date/time pattern which is ISO-8601 compatible, providing up to 7 decimal places
  /// of sub-second accuracy which are always present (including trailing zeroes). This is compatible with the
  /// BCL round-trip formatting of [DateTime] values with a kind of "unspecified".
  /// This corresponds to the text pattern "uuuu'-'MM'-'dd'T'HH':'mm':'ss'.'fffffff". It does not necessarily
  /// round-trip all `LocalDateTime` values as it will lose sub-tick information. Use
  /// [FullRoundtripWithoutCalendar]
  ///
  /// <value>An invariant local date/time pattern which is ISO-8601 compatible, providing up to 7 decimal places
  /// of sub-second accuracy which are always present (including trailing zeroes).</value>
  static LocalDateTimePattern get BclRoundtrip => LocalDateTimePatterns.BclRoundtripPatternImpl;

  /// Gets an invariant local date/time pattern which round trips values, but doesn't include the calendar system.
  /// It provides up to 9 decimal places of sub-second accuracy which are always present (including trailing zeroes).
  /// This corresponds to the text pattern "uuuu'-'MM'-'dd'T'HH':'mm':'ss'.'fffffffff". It will
  /// round-trip all [LocalDateTime] values if the calendar system of the template value is the same
  /// as the calendar system of the original value.
  ///
  /// <value>An invariant local date/time pattern which is ISO-8601 compatible, providing up to 7 decimal places
  /// of sub-second accuracy which are always present (including trailing zeroes).</value>
  static LocalDateTimePattern get FullRoundtripWithoutCalendar => LocalDateTimePatterns.FullRoundtripWithoutCalendarImpl;

  /// Gets an invariant local date/time pattern which round trips values including the calendar system.
  /// This corresponds to the text pattern "uuuu'-'MM'-'dd'T'HH':'mm':'ss'.'fffffffff '('c')'".
  static LocalDateTimePattern get FullRoundtrip => LocalDateTimePatterns.FullRoundtripPatternImpl;

  /// Gets the pattern text for this pattern, as supplied on creation.
  final String PatternText;

  /// Gets the localization information used in this pattern.
  @internal final NodaFormatInfo FormatInfo;

  /// Get the value used as a template for parsing: any field values unspecified
  /// in the pattern are taken from the template.
  final LocalDateTime TemplateValue;

  /// Returns the pattern that this object delegates to. Mostly useful to avoid this public class
  /// implementing an @internal interface.
  @internal final IPartialPattern<LocalDateTime> UnderlyingPattern;

  @private LocalDateTimePattern(this.PatternText, this.FormatInfo, this.TemplateValue, this.UnderlyingPattern);

  /// Parses the given text value according to the rules of this pattern.
  ///
  /// This method never throws an exception (barring a bug in Time Machine itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  ///
  /// [text]: The text value to parse.
  /// Returns: The result of parsing, which may be successful or unsuccessful.
  ParseResult<LocalDateTime> Parse(String text) => UnderlyingPattern.Parse(text);

  /// Formats the given local date/time as text according to the rules of this pattern.
  ///
  /// [value]: The local date/time to format.
  /// Returns: The local date/time formatted according to this pattern.
  String Format(LocalDateTime value) => UnderlyingPattern.Format(value);

  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given [StringBuilder].
  ///
  /// [value]: The value to format.
  /// [builder]: The `StringBuilder` to append to.
  /// Returns: The builder passed in as [builder].
  StringBuffer AppendFormat(LocalDateTime value, StringBuffer builder) => UnderlyingPattern.AppendFormat(value, builder);

// todo: create, create2, create3

  /// Creates a pattern for the given pattern text, format info, and template value.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [formatInfo]: The format info to use in the pattern
  /// [templateValue]: Template value to use for unspecified fields
  /// Returns: A pattern for parsing and formatting local date/times.
  /// [InvalidPatternException]: The pattern text was invalid.
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

  /// Creates a pattern for the given pattern text, culture, and template value.
  ///
  /// See the user guide for the available pattern text options.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [cultureInfo]: The culture to use in the pattern
  /// [templateValue]: Template value to use for unspecified fields
  /// Returns: A pattern for parsing and formatting local date/times.
  /// [InvalidPatternException]: The pattern text was invalid.
  static LocalDateTimePattern Create2(String patternText, CultureInfo cultureInfo,
      LocalDateTime templateValue) =>
      Create(patternText, NodaFormatInfo.GetFormatInfo(cultureInfo), templateValue);

  /// Creates a pattern for the given pattern text and culture, with a template value of midnight on 2000-01-01.
  ///
  /// See the user guide for the available pattern text options.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [cultureInfo]: The culture to use in the pattern
  /// Returns: A pattern for parsing and formatting local date/times.
  /// [InvalidPatternException]: The pattern text was invalid.
  static LocalDateTimePattern Create3(String patternText, CultureInfo cultureInfo) =>
      Create2(patternText, cultureInfo, DefaultTemplateValue);

  /// Creates a pattern for the given pattern text in the current thread's current culture.
  ///
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// Returns: A pattern for parsing and formatting local date/times.
  /// [InvalidPatternException]: The pattern text was invalid.
  static LocalDateTimePattern CreateWithCurrentCulture(String patternText) =>
      Create(patternText, NodaFormatInfo.CurrentInfo, DefaultTemplateValue);

  /// Creates a pattern for the given pattern text in the invariant culture.
  ///
  /// See the user guide for the available pattern text options.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// Returns: A pattern for parsing and formatting local date/times.
  /// [InvalidPatternException]: The pattern text was invalid.
  static LocalDateTimePattern CreateWithInvariantCulture(String patternText) =>
      Create(patternText, NodaFormatInfo.InvariantInfo, DefaultTemplateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// localization information.
  ///
  /// [formatInfo]: The localization information to use in the new pattern.
  /// Returns: A new pattern with the given localization information.
  @private LocalDateTimePattern WithFormatInfo(NodaFormatInfo formatInfo) =>
      Create(PatternText, formatInfo, TemplateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  ///
  /// [cultureInfo]: The culture to use in the new pattern.
  /// Returns: A new pattern with the given culture.
  LocalDateTimePattern WithCulture(CultureInfo cultureInfo) =>
      WithFormatInfo(NodaFormatInfo.GetFormatInfo(cultureInfo));

  /// Creates a pattern like this one, but with the specified template value.
  ///
  /// [newTemplateValue]: The template value for the new pattern, used to fill in unspecified fields.
  /// Returns: A new pattern with the given template value.
  LocalDateTimePattern WithTemplateValue(LocalDateTime newTemplateValue) =>
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
  LocalDateTimePattern WithCalendar(CalendarSystem calendar) =>
      WithTemplateValue(TemplateValue.WithCalendar(calendar));
}
