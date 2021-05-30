// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

@internal
abstract class LocalDatePatterns {
  /// Class whose existence is solely to avoid type initialization order issues, most of which stem
  /// from needing TimeFormatInfo.InvariantInfo...
  static final LocalDatePattern isoPatternImpl = LocalDatePattern.createWithInvariantCulture("uuuu'-'MM'-'dd");

  static LocalDatePattern create(String patternText, TimeMachineFormatInfo formatInfo, LocalDate templateValue) =>
      LocalDatePattern._create(patternText, formatInfo, templateValue);

  static final LocalDate defaultTemplateValue = LocalDate(2000, 1, 1);
  static IPartialPattern<LocalDate> underlyingPattern(LocalDatePattern localDatePattern) => localDatePattern._underlyingPattern;

  // formatInfo.dateTimeFormat.longDatePattern
  static String format(LocalDate localDate, String? patternText, Culture? culture) =>
      TimeMachineFormatInfo
          .getInstance(culture)
          .localDatePatternParser
      // todo: can this be smoothed out? (reduce call complexity?)
          .parsePattern(patternText ?? LocalDatePattern._defaultFormatPattern)
          .format(localDate);
}

/// Represents a pattern for parsing and formatting [LocalDate] values.
@immutable
class LocalDatePattern implements IPattern<LocalDate> {
  static const String _defaultFormatPattern = 'D'; // Long

  /// Gets an invariant local date pattern which is ISO-8601 compatible.
  /// This corresponds to the text pattern "uuuu'-'MM'-'dd".
  static final LocalDatePattern iso = LocalDatePatterns.isoPatternImpl;

  /// Returns the pattern that this object delegates to. Mostly useful to avoid this class
  /// implementing an internal interface.
  final IPartialPattern<LocalDate> _underlyingPattern;

  /// Gets the pattern text for this pattern, as supplied on creation.
  final String patternText;

  /// Returns the localization information used in this pattern.
  final TimeMachineFormatInfo _formatInfo;

  /// Gets the value used as a template for parsing: any field values unspecified
  /// in the pattern are taken from the template.
  final LocalDate templateValue;

  const LocalDatePattern._(this.patternText, this._formatInfo, this.templateValue, this._underlyingPattern);

  /// Parses the given text value according to the rules of this pattern.
  ///
  /// This method never throws an exception (barring a bug in Time Machine itself). Even errors such as
  /// the argument being null are wrapped in a parse result.
  ///
  /// * [text]: The text value to parse.
  ///
  /// Returns: The result of parsing, which may be successful or unsuccessful.
  @override
  ParseResult<LocalDate> parse(String text) => _underlyingPattern.parse(text);

  /// Formats the given local date as text according to the rules of this pattern.
  ///
  /// * [value]: The local date to format.
  ///
  /// Returns: The local date formatted according to this pattern.
  @override
  String format(LocalDate value) => _underlyingPattern.format(value);

  /// Formats the given value as text according to the rules of this pattern,
  /// appending to the given [StringBuilder].
  ///
  /// * [value]: The value to format.
  /// * [builder]: The `StringBuilder` to append to.
  ///
  /// Returns: The builder passed in as [builder].
  @override
  StringBuffer appendFormat(LocalDate value, StringBuffer builder) => _underlyingPattern.appendFormat(value, builder);

  // todo: to factory... or merge with default constructor?
  /// Creates a pattern for the given pattern text, format info, and template value.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  /// * [formatInfo]: The format info to use in the pattern
  /// * [templateValue]: Template value to use for unspecified fields
  ///
  /// Returns: A pattern for parsing and formatting local dates.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static LocalDatePattern _create(String patternText, TimeMachineFormatInfo formatInfo, LocalDate templateValue) {
    Preconditions.checkNotNull(patternText, 'patternText');
    Preconditions.checkNotNull(formatInfo, 'formatInfo');
    // Use the 'fixed' parser for the common case of the default template value.
    var pattern = templateValue == LocalDatePatterns.defaultTemplateValue
        ? formatInfo.localDatePatternParser.parsePattern(patternText)
        : LocalDatePatternParser(templateValue).parsePattern(patternText, formatInfo);
    // If ParsePattern returns a standard pattern instance, we need to get the underlying partial pattern.
    pattern = pattern is LocalDatePattern ? pattern._underlyingPattern : pattern;
    var partialPattern = pattern as IPartialPattern<LocalDate>;
    return LocalDatePattern._(patternText, formatInfo, templateValue, partialPattern);
  }

  /// Creates a pattern for the given pattern text, culture, and template value.
  ///
  /// todo: we don't have this yet
  /// See the user guide for the available pattern text options.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  /// * [culture]: The culture to use in the pattern
  /// * [templateValue]: Template value to use for unspecified fields. Defaults to a value of 2000-01-01.
  ///
  /// Returns: A pattern for parsing and formatting local dates.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static LocalDatePattern createWithCulture(String patternText, Culture culture, [LocalDate? templateValue]) =>
      _create(patternText, TimeMachineFormatInfo.getFormatInfo(culture), templateValue ?? LocalDatePatterns.defaultTemplateValue);

  /// Creates a pattern for the given pattern text in the current thread's current culture.
  ///
  /// todo: we don't have this yet
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  ///
  /// Returns: A pattern for parsing and formatting local dates.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static LocalDatePattern createWithCurrentCulture(String patternText) => _create(patternText, TimeMachineFormatInfo.currentInfo, LocalDatePatterns.defaultTemplateValue);

  /// Creates a pattern for the given pattern text in the invariant culture.
  ///
  /// See the user guide for the available pattern text options. Note that the current culture
  /// is captured at the time this method is called - it is not captured at the point of parsing
  /// or formatting values.
  ///
  /// * [patternText]: Pattern text to create the pattern for
  ///
  /// Returns: A pattern for parsing and formatting local dates.
  ///
  /// * [InvalidPatternError]: The pattern text was invalid.
  static LocalDatePattern createWithInvariantCulture(String patternText) => _create(patternText, TimeMachineFormatInfo.invariantInfo, LocalDatePatterns.defaultTemplateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// localization information.
  ///
  /// * [formatInfo]: The localization information to use in the new pattern.
  ///
  /// Returns: A new pattern with the given localization information.
  LocalDatePattern _withFormatInfo(TimeMachineFormatInfo formatInfo) => _create(patternText, formatInfo, templateValue);

  /// Creates a pattern for the same original pattern text as this pattern, but with the specified
  /// culture.
  ///
  /// * [culture]: The culture to use in the new pattern.
  ///
  /// Returns: A new pattern with the given culture.
  LocalDatePattern withCulture(Culture culture) => _withFormatInfo(TimeMachineFormatInfo.getFormatInfo(culture));

  /// Creates a pattern like this one, but with the specified template value.
  ///
  /// * [newTemplateValue]: The template value for the new pattern, used to fill in unspecified fields.
  ///
  /// Returns: A new pattern with the given template value.
  LocalDatePattern withTemplateValue(LocalDate newTemplateValue) => _create(patternText, _formatInfo, newTemplateValue);

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
  LocalDatePattern withCalendar(CalendarSystem calendar) => withTemplateValue(templateValue.withCalendar(calendar));
}
