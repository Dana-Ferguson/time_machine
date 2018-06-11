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
@internal abstract class ZonedDateTimePatterns
{
  @internal static final ZonedDateTimePattern GeneralFormatOnlyPatternImpl = ZonedDateTimePattern.CreateWithInvariantCulture("uuuu'-'MM'-'dd'T'HH':'mm':'ss z '('o<g>')'", null);
  @internal static final ZonedDateTimePattern ExtendedFormatOnlyPatternImpl = ZonedDateTimePattern.CreateWithInvariantCulture("uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFF z '('o<g>')'", null);
  @internal static final PatternBclSupport<ZonedDateTime> BclSupport = new PatternBclSupport<ZonedDateTime>("G", (fi) => fi.zonedDateTimePatternParser);
}

/// Represents a pattern for parsing and formatting [ZonedDateTime] values.
///
/// <threadsafety>
/// When used with a read-only [CultureInfo], this type is immutable and instances
/// may be shared freely between threads. We recommend only using read-only cultures for patterns, although this is
/// not currently enforced.
/// </threadsafety>
@immutable // Well, assuming an immutable culture...
/*sealed*/ class ZonedDateTimePattern implements IPattern<ZonedDateTime> {
  @internal static final ZonedDateTime DefaultTemplateValue = new LocalDateTime.fromYMDHM(2000, 1, 1, 0, 0).inUtc();

  /// Gets an zoned local date/time pattern based on ISO-8601 (down to the second) including offset from UTC and zone ID.
  /// It corresponds to a custom pattern of "uuuu'-'MM'-'dd'T'HH':'mm':'ss z '('o&lt;g&gt;')'" and is available
  /// as the 'G' standard pattern.
  ///
  /// The calendar system is not formatted as part of this pattern, and it cannot be used for parsing as no time zone
  /// provider is included. Call [WithZoneProvider] on the value of this property to obtain a
  /// pattern which can be used for parsing.
  static ZonedDateTimePattern get GeneralFormatOnlyIso => ZonedDateTimePatterns.GeneralFormatOnlyPatternImpl;

  /// Returns an invariant zoned date/time pattern based on ISO-8601 (down to the nanosecond) including offset from UTC and zone ID.
  /// It corresponds to a custom pattern of "uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFF z '('o&lt;g&gt;')'" and is available
  /// as the 'F' standard pattern.
  ///
  /// The calendar system is not formatted as part of this pattern, and it cannot be used for parsing as no time zone
  /// provider is included. Call [WithZoneProvider] on the value of this property to obtain a
  /// pattern which can be used for parsing.
  static ZonedDateTimePattern get ExtendedFormatOnlyIso => ZonedDateTimePatterns.ExtendedFormatOnlyPatternImpl;

  @private final IPattern<ZonedDateTime> pattern;

  /// Gets the pattern text for this pattern, as supplied on creation.
  final String PatternText;

  /// Gets the localization information used in this pattern.
  @internal final NodaFormatInfo FormatInfo;

  /// Gets the value used as a template for parsing: any field values unspecified
  /// in the pattern are taken from the template.
  final ZonedDateTime TemplateValue;

/// Gets the resolver which is used to map local date/times to zoned date/times,
/// handling skipped and ambiguous times appropriately (where the offset isn't specified in the pattern).
/// This may be null, in which case the pattern can only be used for formatting (not parsing).
/*[CanBeNull]*/
  final ZoneLocalMappingResolver Resolver;

/// Gets the provider which is used to look up time zones when parsing a pattern
/// which contains a time zone identifier. This may be null, in which case the pattern can
/// only be used for formatting (not parsing).
///
/// <value>The provider which is used to look up time zones when parsing a pattern
/// which contains a time zone identifier.</value>
/*[CanBeNull]*/
  final IDateTimeZoneProvider ZoneProvider;

  @private ZonedDateTimePattern(this.PatternText, this.FormatInfo, this.TemplateValue, this.Resolver, this.ZoneProvider, this.pattern);

  // todo: transform to ParseAsync and ParseSync?
  /// Parses the given text value according to the rules of this pattern.
  ///
  /// This method never throws an exception (barring a bug in Time Machine itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  ///
  /// [text]: The text value to parse.
  /// Returns: The result of parsing, which may be successful or unsuccessful.
  ParseResult<ZonedDateTime> Parse(String text) => pattern.Parse(text);

  /// Formats the given zoned date/time as text according to the rules of this pattern.
  ///
  /// [value]: The zoned date/time to format.
  /// Returns: The zoned date/time formatted according to this pattern.
  String Format(ZonedDateTime value) => pattern.Format(value);

  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given [StringBuilder].
  ///
  /// [value]: The value to format.
  /// [builder]: The `StringBuilder` to append to.
  /// Returns: The builder passed in as [builder].
  StringBuffer AppendFormat(ZonedDateTime value, StringBuffer builder) => pattern.AppendFormat(value, builder);

  /// Creates a pattern for the given pattern text, format info, template value, mapping resolver and time zone provider.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [formatInfo]: The format info to use in the pattern
  /// [templateValue]: Template value to use for unspecified fields
  /// [resolver]: Resolver to apply when mapping local date/time values into the zone.
  /// [zoneProvider]: Time zone provider, used when parsing text which contains a time zone identifier.
  /// Returns: A pattern for parsing and formatting zoned date/times.
  /// [InvalidPatternException]: The pattern text was invalid.
  @private static ZonedDateTimePattern Create(String patternText, NodaFormatInfo formatInfo,
      ZoneLocalMappingResolver resolver, IDateTimeZoneProvider zoneProvider, ZonedDateTime templateValue) {
    Preconditions.checkNotNull(patternText, 'patternText');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    var pattern = new ZonedDateTimePatternParser(templateValue, resolver, zoneProvider).ParsePattern(patternText, formatInfo);
    return new ZonedDateTimePattern(patternText, formatInfo, templateValue, resolver, zoneProvider, pattern);
  }

  /// Creates a pattern for the given pattern text, culture, resolver, time zone provider, and template value.
  ///
  /// See the user guide for the available pattern text options.
  /// If [zoneProvider] is null, the resulting pattern can be used for formatting
  /// but not parsing.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [cultureInfo]: The culture to use in the pattern
  /// [resolver]: Resolver to apply when mapping local date/time values into the zone.
  /// [zoneProvider]: Time zone provider, used when parsing text which contains a time zone identifier.
  /// [templateValue]: Template value to use for unspecified fields
  /// Returns: A pattern for parsing and formatting zoned date/times.
  /// [InvalidPatternException]: The pattern text was invalid.
  static ZonedDateTimePattern Create2(String patternText, CultureInfo cultureInfo,
/*[CanBeNull]*/ZoneLocalMappingResolver resolver, /*[CanBeNull]*/IDateTimeZoneProvider zoneProvider, ZonedDateTime templateValue) =>
      Create(patternText, NodaFormatInfo.GetFormatInfo(cultureInfo), resolver, zoneProvider, templateValue);

  /// Creates a pattern for the given pattern text and time zone provider, using a strict resolver, the invariant
  /// culture, and a default template value of midnight January 1st 2000 UTC.
  ///
  /// The resolver is only used if the pattern text doesn't include an offset.
  /// If [zoneProvider] is null, the resulting pattern can be used for formatting
  /// but not parsing.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [zoneProvider]: Time zone provider, used when parsing text which contains a time zone identifier.
  /// Returns: A pattern for parsing and formatting zoned date/times.
  static ZonedDateTimePattern CreateWithInvariantCulture(String patternText, /*[CanBeNull]*/IDateTimeZoneProvider zoneProvider) =>
      Create(patternText, NodaFormatInfo.InvariantInfo, Resolvers.strictResolver, zoneProvider, DefaultTemplateValue);

  /// Creates a pattern for the given pattern text and time zone provider, using a strict resolver, the current
  /// culture, and a default template value of midnight January 1st 2000 UTC.
  ///
  /// The resolver is only used if the pattern text doesn't include an offset.
  /// If [zoneProvider] is null, the resulting pattern can be used for formatting
  /// but not parsing. Note that the current culture is captured at the time this method is called
  /// - it is not captured at the point of parsing or formatting values.
  ///
  /// [patternText]: Pattern text to create the pattern for
  /// [zoneProvider]: Time zone provider, used when parsing text which contains a time zone identifier.
  /// Returns: A pattern for parsing and formatting zoned date/times.
  static ZonedDateTimePattern CreateWithCurrentCulture(String patternText, /*[CanBeNull]*/IDateTimeZoneProvider zoneProvider) =>
      Create(patternText, NodaFormatInfo.CurrentInfo, Resolvers.strictResolver, zoneProvider, DefaultTemplateValue);

  /// Creates a pattern for the same original localization information as this pattern, but with the specified
  /// pattern text.
  ///
  /// [patternText]: The pattern text to use in the new pattern.
  /// Returns: A new pattern with the given pattern text.
  ZonedDateTimePattern WithPatternText(String patternText) =>
      Create(patternText, FormatInfo, Resolver, ZoneProvider, TemplateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// localization information.
  ///
  /// [formatInfo]: The localization information to use in the new pattern.
  /// Returns: A new pattern with the given localization information.
  @private ZonedDateTimePattern WithFormatInfo(NodaFormatInfo formatInfo) =>
      Create(PatternText, formatInfo, Resolver, ZoneProvider, TemplateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  ///
  /// [cultureInfo]: The culture to use in the new pattern.
  /// Returns: A new pattern with the given culture.
  ZonedDateTimePattern WithCulture(CultureInfo cultureInfo) =>
      WithFormatInfo(NodaFormatInfo.GetFormatInfo(cultureInfo));

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// resolver.
  ///
  /// [resolver]: The new local mapping resolver to use.
  /// Returns: A new pattern with the given resolver.
  ZonedDateTimePattern WithResolver(/*[CanBeNull]*/ZoneLocalMappingResolver resolver) =>
      Resolver == resolver ? this : Create(PatternText, FormatInfo, resolver, ZoneProvider, TemplateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// time zone provider.
  ///
  /// If [newZoneProvider] is null, the resulting pattern can be used for formatting
  /// but not parsing.
  ///
  /// [newZoneProvider]: The new time zone provider to use.
  /// Returns: A new pattern with the given time zone provider.
  ZonedDateTimePattern WithZoneProvider(/*[CanBeNull]*/IDateTimeZoneProvider newZoneProvider) =>
      newZoneProvider == ZoneProvider ? this : Create(PatternText, FormatInfo, Resolver, newZoneProvider, TemplateValue);

  /// Creates a pattern like this one, but with the specified template value.
  ///
  /// [newTemplateValue]: The template value for the new pattern, used to fill in unspecified fields.
  /// Returns: A new pattern with the given template value.
  ZonedDateTimePattern WithTemplateValue(ZonedDateTime newTemplateValue) =>
      newTemplateValue == TemplateValue ? this : Create(PatternText, FormatInfo, Resolver, ZoneProvider, newTemplateValue);

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
  ZonedDateTimePattern WithCalendar(CalendarSystem calendar) =>
      WithTemplateValue(TemplateValue.WithCalendar(calendar));
}

