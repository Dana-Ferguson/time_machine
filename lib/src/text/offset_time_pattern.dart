// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

/// Class whose existence is solely to avoid type initialization order issues, most of which stem
/// from needing TimeMachineFormatInfo.InvariantInfo...
@internal
class OffsetTimePatterns {
  // static OffsetTimePattern _GeneralIsoPatternImpl;
  // @internal static OffsetTimePattern get GeneralIsoPatternImpl => _GeneralIsoPatternImpl ??= OffsetTimePattern.Create(
    //  "HH':'mm':'sso<G>", NodaFormatInfo.InvariantInfo, OffsetTimePattern.DefaultTemplateValue);

  static final OffsetTimePattern generalIsoPatternImpl = OffsetTimePattern._create(
      "HH':'mm':'sso<G>", TimeMachineFormatInfo.invariantInfo, defaultTemplateValue);
  static final OffsetTimePattern extendedIsoPatternImpl = OffsetTimePattern._create(
      "HH':'mm':'ss;FFFFFFFFFo<G>", TimeMachineFormatInfo.invariantInfo, defaultTemplateValue);
  static final OffsetTimePattern rfc3339PatternImpl = OffsetTimePattern._create(
      "HH':'mm':'ss;FFFFFFFFFo<Z+HH:mm>", TimeMachineFormatInfo.invariantInfo, defaultTemplateValue);
  static String format(OffsetTime offsetTime, String? patternText, Culture? culture) =>
      TimeMachineFormatInfo
          .getInstance(culture)
          .offsetTimePatternParser
          .parsePattern(patternText ?? generalIsoPatternImpl.patternText)
          .format(offsetTime);

  static final OffsetTime defaultTemplateValue = LocalTime.midnight.withOffset(Offset.zero);

  static TimeMachineFormatInfo formatInfo(OffsetTimePattern offsetTimePattern) => offsetTimePattern._formatInfo;
}

/// Represents a pattern for parsing and formatting [OffsetTime] values.
@immutable
class OffsetTimePattern implements IPattern<OffsetTime> {
  /// Gets an invariant offset time pattern based on ISO-8601 (down to the second), including offset from UTC.
  ///
  /// This corresponds to a custom pattern of "HH':'mm':'sso&lt;G&gt;". It is available as the "G"
  /// standard pattern (even though it is invariant).
  static OffsetTimePattern get generalIso => OffsetTimePatterns.generalIsoPatternImpl;

  /// Gets an invariant offset time pattern based on ISO-8601 (down to the nanosecond), including offset from UTC.
  ///
  /// This corresponds to a custom pattern of "HH':'mm':'ss;FFFFFFFFFo&lt;G&gt;".
  /// This will round-trip all values, and is available as the 'o' standard pattern.
  static OffsetTimePattern get extendedIso => OffsetTimePatterns.extendedIsoPatternImpl;

  /// Gets an invariant offset time pattern based on RFC 3339 (down to the nanosecond), including offset from UTC
  /// as hours and minutes only.
  ///
  /// The minutes part of the offset is always included, but any sub-minute component
  /// of the offset is lost. An offset of zero is formatted as 'Z', but all of 'Z', '+00:00' and '-00:00' are parsed
  /// the same way. The RFC 3339 meaning of '-00:00' is not supported by Time Machine.
  /// Note that parsing is case-sensitive (so 'T' and 'Z' must be upper case).
  /// This pattern corresponds to a custom pattern of
  /// "HH':'mm':'ss;FFFFFFFFFo&lt;Z+HH:mm&gt;".
  static OffsetTimePattern get rfc3339 => OffsetTimePatterns.rfc3339PatternImpl;

  final IPattern<OffsetTime> _pattern;

  /// Gets the pattern text for this pattern, as supplied on creation.
  final String patternText;

  /// Gets the localization information used in this pattern.
  final TimeMachineFormatInfo _formatInfo;

  /// Gets the value used as a template for parsing: any field values unspecified
  /// in the pattern are taken from the template.
  final OffsetTime templateValue;

  const OffsetTimePattern._(this.patternText, this._formatInfo, this.templateValue, this._pattern);

  /// Parses the given text value according to the rules of this pattern.
  ///
  /// This method never throws an exception (barring a bug in Time Machine itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  ///
  /// * [text]: The text value to parse.
  ///
  /// Returns: The result of parsing, which may be successful or unsuccessful.
  @override
  ParseResult<OffsetTime> parse(String text) => _pattern.parse(text);

  /// Formats the given zoned time as text according to the rules of this pattern.
  ///
  /// * [value]: The zoned time to format.
  ///
  /// Returns: The zoned time formatted according to this pattern.
  @override
  String format(OffsetTime value) => _pattern.format(value);

  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given [StringBuilder].
  ///
  /// * [value]: The value to format.
  /// * [builder]: The `StringBuffer` to append to.
  ///
  /// Returns: The builder passed in as [builder].
  @override
  StringBuffer appendFormat(OffsetTime value, StringBuffer builder) => _pattern.appendFormat(value, builder);

  /// Creates a pattern for the given pattern text, format info, and template value.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  /// * [formatInfo]: The format info to use in the pattern
  /// * [templateValue]: Template value to use for unspecified fields
  ///
  /// Returns: A pattern for parsing and formatting zoned times.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static OffsetTimePattern _create(String patternText, TimeMachineFormatInfo formatInfo,
      OffsetTime templateValue) {
    Preconditions.checkNotNull(patternText, 'patternText');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    var pattern = OffsetTimePatternParser(templateValue).parsePattern(patternText, formatInfo);
    return OffsetTimePattern._(patternText, formatInfo, templateValue, pattern);
  }

  /// Creates a pattern for the given pattern text, culture, and template value.
  ///
  /// todo: we need one
  /// See the user guide for the available pattern text options.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  /// * [culture]: The culture to use in the pattern
  /// * [templateValue]: Template value to use for unspecified fields
  ///
  /// Returns: A pattern for parsing and formatting local times.
  ///
  /// [InvalidPatternError]: The pattern text was invalid.
  static OffsetTimePattern createWithCulture(String patternText, Culture culture, OffsetTime templateValue) =>
      _create(patternText, TimeMachineFormatInfo.getFormatInfo(culture), templateValue);

  /// Creates a pattern for the given pattern text in the invariant culture, using the default
  /// template value of midnight January 1st 2000 at an offset of 0.
  ///
  /// todo: we need one
  /// See the user guide for the available pattern text options.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  ///
  /// Returns: A pattern for parsing and formatting local times.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static OffsetTimePattern createWithInvariantCulture(String patternText) =>
      _create(patternText, TimeMachineFormatInfo.invariantInfo, OffsetTimePatterns.defaultTemplateValue);

  /// Creates a pattern for the given pattern text in the current culture, using the default
  /// template value of midnight January 1st 2000 at an offset of 0.
  ///
  /// todo: we need one
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  ///
  /// Returns: A pattern for parsing and formatting local times.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static OffsetTimePattern createWithCurrentCulture(String patternText) =>
      _create(patternText, TimeMachineFormatInfo.currentInfo, OffsetTimePatterns.defaultTemplateValue);

  /// Creates a pattern for the same original localization information as this pattern, but with the specified
  /// pattern text.
  ///
  /// * [patternText]: The pattern text to use in the new pattern.
  ///
  /// Returns: A new pattern with the given pattern text.
  OffsetTimePattern withPatternText(String patternText) =>
      _create(patternText, _formatInfo, templateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// localization information.
  ///
  /// * [formatInfo]: The localization information to use in the new pattern.
  ///
  /// Returns: A new pattern with the given localization information.
  OffsetTimePattern _withFormatInfo(TimeMachineFormatInfo formatInfo) =>
      _create(patternText, formatInfo, templateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  ///
  /// * [culture]: The culture to use in the new pattern.
  ///
  /// Returns: A new pattern with the given culture.
  OffsetTimePattern withCulture(Culture culture) =>
      _withFormatInfo(TimeMachineFormatInfo.getFormatInfo(culture));

  /// Creates a pattern for the same original pattern text and culture as this pattern, but with
  /// the specified template value.
  ///
  /// * [newTemplateValue]: The template value to use in the new pattern.
  ///
  /// Returns: A new pattern with the given template value.
  OffsetTimePattern withTemplateValue(OffsetTime newTemplateValue) =>
      _create(patternText, _formatInfo, newTemplateValue);
}
