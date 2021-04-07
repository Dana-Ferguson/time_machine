// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

/// Class whose existence is solely to avoid type initialization order issues, most of which stem
/// from needing TimeMachineFormatInfo.InvariantInfo...
@internal
abstract class ZonedDateTimePatterns
{
  static final ZonedDateTimePattern generalFormatOnlyPatternImpl = ZonedDateTimePattern.createWithInvariantCulture("uuuu'-'MM'-'dd'T'HH':'mm':'ss z '('o<g>')'", null);
  static final ZonedDateTimePattern extendedFormatOnlyPatternImpl = ZonedDateTimePattern.createWithInvariantCulture("uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFF z '('o<g>')'", null);
  static String format(ZonedDateTime zonedDateTime, String? patternText, Culture? culture) =>
      TimeMachineFormatInfo
          .getInstance(culture)
          .zonedDateTimePatternParser
          // 'G'
          .parsePattern(patternText ?? generalFormatOnlyPatternImpl.patternText)
          .format(zonedDateTime);

  static final ZonedDateTime defaultTemplateValue = LocalDateTime(2000, 1, 1, 0, 0, 0).inUtc();
}

/// Represents a pattern for parsing and formatting [ZonedDateTime] values.
@immutable
class ZonedDateTimePattern implements IPattern<ZonedDateTime> {
  /// Gets an zoned local date/time pattern based on ISO-8601 (down to the second) including offset from UTC and zone ID.
  /// It corresponds to a custom pattern of "uuuu'-'MM'-'dd'T'HH':'mm':'ss z '('o&lt;g&gt;')'" and is available
  /// as the 'G' standard pattern.
  ///
  /// The calendar system is not formatted as part of this pattern, and it cannot be used for parsing as no time zone
  /// provider is included. Call [withZoneProvider] on the value of this property to obtain a
  /// pattern which can be used for parsing.
  static ZonedDateTimePattern get generalFormatOnlyIso => ZonedDateTimePatterns.generalFormatOnlyPatternImpl;

  /// Returns an invariant zoned date/time pattern based on ISO-8601 (down to the nanosecond) including offset from UTC and zone ID.
  /// It corresponds to a custom pattern of "uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFF z '('o&lt;g&gt;')'" and is available
  /// as the 'F' standard pattern.
  ///
  /// The calendar system is not formatted as part of this pattern, and it cannot be used for parsing as no time zone
  /// provider is included. Call [withZoneProvider] on the value of this property to obtain a
  /// pattern which can be used for parsing.
  static ZonedDateTimePattern get extendedFormatOnlyIso => ZonedDateTimePatterns.extendedFormatOnlyPatternImpl;

  final IPattern<ZonedDateTime> _pattern;

  /// Gets the pattern text for this pattern, as supplied on creation.
  final String patternText;

  /// Gets the localization information used in this pattern.
  final TimeMachineFormatInfo _formatInfo;

  /// Gets the value used as a template for parsing: any field values unspecified
  /// in the pattern are taken from the template.
  final ZonedDateTime templateValue;

  /// Gets the resolver which is used to map local date/times to zoned date/times,
  /// handling skipped and ambiguous times appropriately (where the offset isn't specified in the pattern).
  /// This may be null, in which case the pattern can only be used for formatting (not parsing).
  final ZoneLocalMappingResolver? resolver;

  /// Gets the provider which is used to look up time zones when parsing a pattern
  /// which contains a time zone identifier. This may be null, in which case the pattern can
  /// only be used for formatting (not parsing).
  final DateTimeZoneProvider? zoneProvider;

  const ZonedDateTimePattern._(this.patternText, this._formatInfo, this.templateValue, this.resolver, this.zoneProvider, this._pattern);

  // todo: transform to ParseAsync and ParseSync?
  /// Parses the given text value according to the rules of this pattern.
  ///
  /// This method never throws an exception (barring a bug in Time Machine itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  ///
  /// * [text]: The text value to parse.
  ///
  /// Returns: The result of parsing, which may be successful or unsuccessful.
  @override
  ParseResult<ZonedDateTime> parse(String text) => _pattern.parse(text);

  /// Formats the given zoned date/time as text according to the rules of this pattern.
  ///
  /// * [value]: The zoned date/time to format.
  ///
  /// Returns: The zoned date/time formatted according to this pattern.
  @override
  String format(ZonedDateTime value) => _pattern.format(value);

  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given [StringBuilder].
  ///
  /// * [value]: The value to format.
  /// * [builder]: The [StringBuffer] to append to.
  ///
  /// Returns: The builder passed in as [builder].
  @override
  StringBuffer appendFormat(ZonedDateTime value, StringBuffer builder) => _pattern.appendFormat(value, builder);

  /// Creates a pattern for the given pattern text, format info, template value, mapping resolver and time zone provider.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  /// * [formatInfo]: The format info to use in the pattern
  /// * [templateValue]: Template value to use for unspecified fields
  /// * [resolver]: Resolver to apply when mapping local date/time values into the zone.
  /// * [zoneProvider]: Time zone provider, used when parsing text which contains a time zone identifier.
  ///
  /// Returns: A pattern for parsing and formatting zoned date/times.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static ZonedDateTimePattern _create(String patternText, TimeMachineFormatInfo formatInfo,
      ZoneLocalMappingResolver? resolver, DateTimeZoneProvider? zoneProvider, ZonedDateTime templateValue) {
    Preconditions.checkNotNull(patternText, 'patternText');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    var pattern = ZonedDateTimePatternParser(templateValue, resolver, zoneProvider).parsePattern(patternText, formatInfo);
    return ZonedDateTimePattern._(patternText, formatInfo, templateValue, resolver, zoneProvider, pattern);
  }

  // todo: This needs to be a factory
  /// Creates a pattern for the given pattern text, culture, resolver, specified or default time zone provider,
  /// and the specified or default template value.
  ///
  /// todo: we need one
  /// See the user guide for the available pattern text options.
  /// If the resulting [zoneProvider] is null, the resulting pattern can be used for formatting
  /// but not parsing.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  /// * [culture]: The culture to use in the pattern
  /// * [resolver]: Resolver to apply when mapping local date/time values into the zone.
  /// * [zoneProvider]: Time zone provider or default zone provider, used when parsing text which contains a time zone identifier.
  /// If null, defaults to [DateTimeZoneProviders.defaultProvider], which may also be null.
  /// * [templateValue]: Template value to use for unspecified fields
  /// Returns: A pattern for parsing and formatting zoned date/times.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static ZonedDateTimePattern createWithCulture(String patternText, Culture culture,
      [ZoneLocalMappingResolver? resolver, DateTimeZoneProvider? zoneProvider, ZonedDateTime? templateValue]) =>
      _create(patternText, TimeMachineFormatInfo.getFormatInfo(culture), resolver ?? Resolvers.strictResolver,
          zoneProvider ?? DateTimeZoneProviders.defaultProvider, templateValue ?? ZonedDateTimePatterns.defaultTemplateValue);

  /// Creates a pattern for the given pattern text and the specified or default time zone provider, using a strict resolver, the invariant
  /// culture, and a default template value of midnight January 1st 2000 UTC.
  ///
  /// The resolver is only used if the pattern text doesn't include an offset.
  /// If the resulting [zoneProvider] is null, the resulting pattern can be used for formatting
  /// but not parsing.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  /// * [zoneProvider]: Time zone provider, used when parsing text which contains a time zone identifier.
  /// If null, defaults to [DateTimeZoneProviders.defaultProvider], which may also be null.
  ///
  /// Returns: A pattern for parsing and formatting zoned date/times.
  static ZonedDateTimePattern createWithInvariantCulture(String patternText, [DateTimeZoneProvider? zoneProvider]) =>
      _create(patternText, TimeMachineFormatInfo.invariantInfo, Resolvers.strictResolver, zoneProvider ?? DateTimeZoneProviders.defaultProvider, ZonedDateTimePatterns.defaultTemplateValue);

  /// Creates a pattern for the given pattern text and the specified or default time zone provider, using a strict resolver, the current
  /// culture, and a default template value of midnight January 1st 2000 UTC.
  ///
  /// The resolver is only used if the pattern text doesn't include an offset.
  /// If the resulting [zoneProvider] is null, the resulting pattern can be used for formatting
  /// but not parsing. Note that the current culture is captured at the time this method is called
  /// - it is not captured at the point of parsing or formatting values.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  /// * [zoneProvider]: Time zone provider, used when parsing text which contains a time zone identifier.
  /// If null, defaults to [DateTimeZoneProviders.defaultProvider], which may also be null.
  ///
  /// Returns: A pattern for parsing and formatting zoned date/times.
  static ZonedDateTimePattern createWithCurrentCulture(String patternText, [DateTimeZoneProvider? zoneProvider]) =>
      _create(patternText, TimeMachineFormatInfo.currentInfo, Resolvers.strictResolver, zoneProvider ?? DateTimeZoneProviders.defaultProvider, ZonedDateTimePatterns.defaultTemplateValue);

  /// Creates a pattern for the same original localization information as this pattern, but with the specified
  /// pattern text.
  ///
  /// * [patternText]: The pattern text to use in the new pattern.
  ///
  /// Returns: A new pattern with the given pattern text.
  ZonedDateTimePattern withPatternText(String patternText) =>
      _create(patternText, _formatInfo, resolver, zoneProvider, templateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// localization information.
  ///
  /// * [formatInfo]: The localization information to use in the new pattern.
  ///
  /// Returns: A new pattern with the given localization information.
  ZonedDateTimePattern _withFormatInfo(TimeMachineFormatInfo formatInfo) =>
      _create(patternText, formatInfo, resolver, zoneProvider, templateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  ///
  /// * [culture]: The culture to use in the new pattern.
  ///
  /// Returns: A new pattern with the given culture.
  ZonedDateTimePattern withCulture(Culture culture) =>
      _withFormatInfo(TimeMachineFormatInfo.getFormatInfo(culture));

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// resolver.
  ///
  /// * [resolver]: The new local mapping resolver to use.
  ///
  /// Returns: A new pattern with the given resolver.
  ZonedDateTimePattern withResolver(ZoneLocalMappingResolver? resolver) =>
      this.resolver == resolver ? this : _create(patternText, _formatInfo, resolver, zoneProvider, templateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// time zone provider.
  ///
  /// If [newZoneProvider] is null, the resulting pattern can be used for formatting
  /// but not parsing.
  ///
  /// * [newZoneProvider]: The new time zone provider to use.
  ///
  /// Returns: A new pattern with the given time zone provider.
  ZonedDateTimePattern withZoneProvider(DateTimeZoneProvider? newZoneProvider) =>
      newZoneProvider == zoneProvider ? this : _create(patternText, _formatInfo, resolver, newZoneProvider, templateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the default
  /// time zone provider.
  ///
  /// If [DateTimeZoneProviders.defaultProvider] is null, the resulting pattern can be used for formatting
  /// but not parsing.
  ///
  /// Returns: A new pattern with the given time zone provider.
  ZonedDateTimePattern withDefaultZoneProvider() => withZoneProvider(DateTimeZoneProviders.defaultProvider);

  /// Creates a pattern like this one, but with the specified template value.
  ///
  /// * [newTemplateValue]: The template value for the new pattern, used to fill in unspecified fields.
  ///
  /// Returns: A new pattern with the given template value.
  ZonedDateTimePattern withTemplateValue(ZonedDateTime newTemplateValue) =>
      newTemplateValue == templateValue ? this : _create(patternText, _formatInfo, resolver, zoneProvider, newTemplateValue);

  /// Creates a pattern like this one, but with the template value modified to use
  /// the specified calendar system.
  ///
  /// Care should be taken in two (relatively rare) scenarios. Although the default template value
  /// is supported by all Time Machine calendar systems, if a pattern is created with a different
  /// template value and then this method is called with a calendar system which doesn't support that
  /// date, an exception will be thrown. Additionally, if the pattern only specifies some date fields,
  /// it's possible that the new template value will not be suitable for all values.
  ///
  /// * [calendar]: The calendar system to convert the template value into.
  ///
  /// Returns: A new pattern with a template value in the specified calendar system.
  ZonedDateTimePattern withCalendar(CalendarSystem calendar) =>
      withTemplateValue(templateValue.withCalendar(calendar));
}

