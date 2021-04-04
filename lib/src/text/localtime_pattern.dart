// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

@internal
abstract class LocalTimePatterns {
  // todo: we may not need _Patterns classes for our Dart port
  /// Class whose existence is solely to avoid type initialization order issues, most of which stem
  /// from needing TimeFormatInfo.InvariantInfo...
  static final LocalTimePattern extendedIsoPatternImpl = LocalTimePattern.createWithInvariantCulture("HH':'mm':'ss;FFFFFFFFF");

  static String format(LocalTime localTime, String? patternText, Culture? culture) =>
      TimeMachineFormatInfo
          .getInstance(culture)
          .localTimePatternParser
          .parsePattern(patternText ?? LocalTimePattern._defaultFormatPattern)
          .format(localTime);

  static LocalTimePattern create(String patternText, TimeMachineFormatInfo formatInfo, LocalTime templateValue) =>
      LocalTimePattern._create(patternText, formatInfo, templateValue);

  static IPartialPattern<LocalTime> underlyingPattern(LocalTimePattern localTimePattern) => localTimePattern._underlyingPattern;
}

/// Represents a pattern for parsing and formatting [LocalTime] values.
@immutable
class LocalTimePattern implements IPattern<LocalTime> {
  /// Gets an invariant local time pattern which is ISO-8601 compatible, providing up to 9 decimal places.
  /// (These digits are omitted when unnecessary.)
  /// This corresponds to the text pattern "HH':'mm':'ss;FFFFFFFFF".
  static final LocalTimePattern extendedIso = LocalTimePatterns.extendedIsoPatternImpl;

  static const String _defaultFormatPattern = 'T'; // Long

  /// Returns the pattern that this object delegates to. Mostly useful to avoid this class
  /// implementing an internal interface.
  final IPartialPattern<LocalTime> _underlyingPattern;

  /// Gets the pattern text for this pattern, as supplied on creation.
  final String patternText;

  /// Gets the localization information used in this pattern.
  final TimeMachineFormatInfo _formatInfo;

  /// Gets the value used as a template for parsing: any field values unspecified
  /// in the pattern are taken from the template.
  final LocalTime templateValue;

  const LocalTimePattern._(this.patternText, this._formatInfo, this.templateValue, this._underlyingPattern);

  /// Parses the given text value according to the rules of this pattern.
  ///
  /// This method never throws an exception (barring a bug in Time Machine itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  ///
  /// * [text]: The text value to parse.
  ///
  /// Returns: The result of parsing, which may be successful or unsuccessful.
  @override
  ParseResult<LocalTime> parse(String text) => _underlyingPattern.parse(text);

  /// Formats the given local time as text according to the rules of this pattern.
  ///
  /// * [value]: The local time to format.
  ///
  /// Returns: The local time formatted according to this pattern.
  @override
  String format(LocalTime value) => _underlyingPattern.format(value);

  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given [StringBuilder].
  ///
  /// * [value]: The value to format.
  /// * [builder]: The `StringBuilder` to append to.
  ///
  /// Returns: The builder passed in as [builder].
  @override
  StringBuffer appendFormat(LocalTime value, StringBuffer builder) => _underlyingPattern.appendFormat(value, builder);

  /// Creates a pattern for the given pattern text, format info, and template value.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  /// * [formatInfo]: The format info to use in the pattern
  /// * [templateValue]: Template value to use for unspecified fields
  ///
  /// Returns: A pattern for parsing and formatting local times.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static LocalTimePattern _create(String patternText, TimeMachineFormatInfo formatInfo,
      LocalTime templateValue) {
    Preconditions.checkNotNull(patternText, 'patternText');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    // Use the 'fixed' parser for the common case of the default template value.
    var pattern = templateValue == LocalTime.midnight
        ? formatInfo.localTimePatternParser.parsePattern(patternText)
        : LocalTimePatternParser(templateValue).parsePattern(patternText, formatInfo);
    // If ParsePattern returns a standard pattern instance, we need to get the underlying partial pattern.
    // (Alternatively, we could just return it directly, instead of creating a new object.)
    pattern = pattern is LocalTimePattern ? pattern._underlyingPattern : pattern;
    var partialPattern = pattern as IPartialPattern<LocalTime>;
    return LocalTimePattern._(patternText, formatInfo, templateValue, partialPattern);
  }

  /// Creates a pattern for the given pattern text, culture, and template value or [LocalTime.midnight].
  ///
  /// See the user guide for the available pattern text options.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  /// * [culture]: The culture to use in the pattern
  /// * [templateValue]: Template value to use for unspecified fields
  ///
  /// Returns: A pattern for parsing and formatting local times.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static LocalTimePattern createWithCulture(String patternText, Culture culture, [LocalTime? templateValue]) =>
      _create(patternText, TimeMachineFormatInfo.getFormatInfo(culture), templateValue ?? LocalTime.midnight);

  /// Creates a pattern for the given pattern text in the current thread's current culture.
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
  static LocalTimePattern createWithCurrentCulture(String patternText) =>
      _create(patternText, TimeMachineFormatInfo.currentInfo, LocalTime.midnight);

  /// Creates a pattern for the given pattern text in the invariant culture.
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
  static LocalTimePattern createWithInvariantCulture(String patternText) =>
      _create(patternText, TimeMachineFormatInfo.invariantInfo, LocalTime.midnight);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// localization information.
  ///
  /// * [formatInfo]: The localization information to use in the new pattern.
  ///
  /// Returns: A new pattern with the given localization information.
  LocalTimePattern _withFormatInfo(TimeMachineFormatInfo formatInfo) =>
      _create(patternText, formatInfo, templateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  ///
  /// * [culture]: The culture to use in the new pattern.
  ///
  /// Returns: A new pattern with the given culture.
  LocalTimePattern withCulture(Culture culture) =>
      _withFormatInfo(TimeMachineFormatInfo.getFormatInfo(culture));

  /// Creates a pattern like this one, but with the specified template value.
  ///
  /// * [newTemplateValue]: The template value for the new pattern, used to fill in unspecified fields.
  ///
  /// Returns: A new pattern with the given template value.
  LocalTimePattern withTemplateValue(LocalTime newTemplateValue) =>
      _create(patternText, _formatInfo, newTemplateValue);
}
