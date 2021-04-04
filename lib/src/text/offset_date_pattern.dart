// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

/// Class whose existence is solely to avoid type initialization order issues, most of which stem
/// from needing NodaFormatInfo.InvariantInfo...
@internal
abstract class OffsetDatePatterns {
  static final OffsetDatePattern generalIsoPatternImpl = OffsetDatePattern._create(
      "uuuu'-'MM'-'ddo<G>", TimeMachineFormatInfo.invariantInfo, defaultTemplateValue);
  static final OffsetDatePattern fullRoundtripPatternImpl = OffsetDatePattern._create(
      "uuuu'-'MM'-'ddo<G> '('c')'", TimeMachineFormatInfo.invariantInfo, defaultTemplateValue);

  static String format(OffsetDate offsetDate, String? patternText, Culture? culture) =>
      TimeMachineFormatInfo
          .getInstance(culture)
          .offsetDatePatternParser
          .parsePattern(patternText ?? generalIsoPatternImpl.patternText)
          .format(offsetDate);

  static final OffsetDate defaultTemplateValue = LocalDate(2000, 1, 1).withOffset(Offset.zero);

  static TimeMachineFormatInfo formatInfo(OffsetDatePattern offsetDatePattern) => offsetDatePattern._formatInfo;
}

/// Represents a pattern for parsing and formatting [OffsetDate] values.
@immutable
class OffsetDatePattern implements IPattern<OffsetDate> {
  /// Gets an invariant offset date pattern based on ISO-8601, including offset from UTC.
  ///
  /// The calendar system is not parsed or formatted as part of this pattern. It corresponds to a custom pattern of
  /// "uuuu'-'MM'-'ddo&lt;G&gt;". This pattern is available as the "G" standard pattern (even though it is invariant).
  static OffsetDatePattern get generalIso => OffsetDatePatterns.generalIsoPatternImpl;

  /// Gets an invariant offset date pattern based on ISO-8601
  /// including offset from UTC and calendar ID.
  ///
  /// The returned pattern corresponds to a custom pattern of
  /// "uuuu'-'MM'-'dd'o&lt;G&gt; '('c')'". This will round-trip any value in any calendar,
  /// and is available as the 'r' standard pattern.
  static OffsetDatePattern get fullRoundtrip => OffsetDatePatterns.fullRoundtripPatternImpl;

  final IPattern<OffsetDate> _pattern;

  /// Gets the pattern text for this pattern, as supplied on creation.
  final String patternText;

  /// Gets the localization information used in this pattern.
  final TimeMachineFormatInfo _formatInfo;

  /// Gets the value used as a template for parsing: any field values unspecified
  /// in the pattern are taken from the template.
  final OffsetDate templateValue;

  const OffsetDatePattern._(this.patternText, this._formatInfo, this.templateValue, this._pattern);

  /// Parses the given text value according to the rules of this pattern.
  ///
  /// This method never throws an exception (barring a bug in Time Machine itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  ///
  /// * [text]: The text value to parse.
  ///
  /// Returns: The result of parsing, which may be successful or unsuccessful.
  @override
  ParseResult<OffsetDate> parse(String text) => _pattern.parse(text);

  /// Formats the given zoned date as text according to the rules of this pattern.
  ///
  /// * [value]: The zoned date to format.
  ///
  /// Returns: The zoned date formatted according to this pattern.
  @override
  String format(OffsetDate value) => _pattern.format(value);

  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given [StringBuilder].
  ///
  /// * [value]: The value to format.
  /// * [builder]: The `StringBuffer` to append to.
  ///
  /// Returns: The builder passed in as [builder].
  @override
  StringBuffer appendFormat(OffsetDate value, StringBuffer builder) => _pattern.appendFormat(value, builder);

  /// Creates a pattern for the given pattern text, format info, and template value.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  /// * [formatInfo]: The format info to use in the pattern
  /// * [templateValue]: Template value to use for unspecified fields
  ///
  /// Returns: A pattern for parsing and formatting zoned dates.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static OffsetDatePattern _create(String patternText, TimeMachineFormatInfo formatInfo,
      OffsetDate templateValue) {
    Preconditions.checkNotNull(patternText, 'patternText');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    var pattern = OffsetDatePatternParser(templateValue).parsePattern(patternText, formatInfo);
    return OffsetDatePattern._(patternText, formatInfo, templateValue, pattern);
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
  /// Returns: A pattern for parsing and formatting local dates.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static OffsetDatePattern createWithCulture(String patternText, Culture culture, OffsetDate templateValue) =>
      _create(patternText, TimeMachineFormatInfo.getFormatInfo(culture), templateValue);

  /// Creates a pattern for the given pattern text in the invariant culture, using the default
  /// template value of midnight January 1st 2000 at an offset of 0.
  ///
  /// todo: we need one
  /// See the user guide for the available pattern text options.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  ///
  /// Returns: A pattern for parsing and formatting local dates.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static OffsetDatePattern createWithInvariantCulture(String patternText) =>
      _create(patternText, TimeMachineFormatInfo.invariantInfo, OffsetDatePatterns.defaultTemplateValue);

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
  /// Returns: A pattern for parsing and formatting local dates.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static OffsetDatePattern createWithCurrentCulture(String patternText) =>
      _create(patternText, TimeMachineFormatInfo.currentInfo, OffsetDatePatterns.defaultTemplateValue);

  /// Creates a pattern for the same original localization information as this pattern, but with the specified
  /// pattern text.
  ///
  /// * [patternText]: The pattern text to use in the new pattern.
  ///
  /// Returns: A new pattern with the given pattern text.
  OffsetDatePattern withPatternText(String patternText) =>
      _create(patternText, _formatInfo, templateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// localization information.
  ///
  /// * [formatInfo]: The localization information to use in the new pattern.
  ///
  /// Returns: A new pattern with the given localization information.
  OffsetDatePattern _withFormatInfo(TimeMachineFormatInfo formatInfo) =>
      _create(patternText, formatInfo, templateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  ///
  /// * [culture]: The culture to use in the new pattern.
  ///
  /// Returns: A new pattern with the given culture.
  OffsetDatePattern withCulture(Culture culture) =>
      _withFormatInfo(TimeMachineFormatInfo.getFormatInfo(culture));

  /// Creates a pattern for the same original pattern text and culture as this pattern, but with
  /// the specified template value.
  ///
  /// * [newTemplateValue]: The template value to use in the new pattern.
  ///
  /// Returns: A new pattern with the given template value.
  OffsetDatePattern withTemplateValue(OffsetDate newTemplateValue) =>
      _create(patternText, _formatInfo, newTemplateValue);

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
  OffsetDatePattern withCalendar(CalendarSystem calendar) =>
      withTemplateValue(templateValue.withCalendar(calendar));
}
