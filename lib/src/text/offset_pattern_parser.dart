// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/text/patterns/time_machine_patterns.dart';

@internal
class OffsetPatternParser implements IPatternParser<Offset> {
  static final Map<String /*char*/, CharacterHandler<Offset, _OffsetParseBucket>> _patternCharacterHandlers = {
    '%': SteppedPatternBuilder.handlePercent /**<Offset, OffsetParseBucket>*/,
    '\'': SteppedPatternBuilder.handleQuote /**<Offset, OffsetParseBucket>*/,
    '\"': SteppedPatternBuilder.handleQuote /**<Offset, OffsetParseBucket>*/,
    '\\': SteppedPatternBuilder.handleBackslash /**<Offset, OffsetParseBucket>*/,
    ':': (pattern, builder) => builder.addLiteral1(builder.formatInfo.timeSeparator, IParseResult.timeSeparatorMismatch /**<Offset>*/),
    'h': (pattern, builder) => throw IInvalidPatternError.format(TextErrorMessages.hour12PatternNotSupported, ['Offset']),
    'H': SteppedPatternBuilder.handlePaddedField<Offset, _OffsetParseBucket>(
        2, PatternFields.hours24, 0, 23, _getPositiveHours, (bucket, value) => bucket.hours = value),
    'm': SteppedPatternBuilder.handlePaddedField<Offset, _OffsetParseBucket>(
        2, PatternFields.minutes, 0, 59, _getPositiveMinutes, (bucket, value) => bucket.minutes = value),
    's': SteppedPatternBuilder.handlePaddedField<Offset, _OffsetParseBucket>(
        2, PatternFields.seconds, 0, 59, _getPositiveSeconds, (bucket, value) => bucket.seconds = value),
    '+': _handlePlus,
    '-': _handleMinus,
    'Z': (ignored1, ignored2) => throw InvalidPatternError(TextErrorMessages.zPrefixNotAtStartOfPattern)
  };

  // These are used to compute the individual (always-positive) components of an offset.
  // For example, an offset of 'three and a half hours behind UTC' would have a "positive hours" value
  // of 3, and a 'positive minutes' value of 30. The sign is computed elsewhere.
  static int _getPositiveHours(Offset offset) => offset.inMilliseconds.abs() ~/ TimeConstants.millisecondsPerHour;

  static int _getPositiveMinutes(Offset offset) => (offset.inMilliseconds.abs() % TimeConstants.millisecondsPerHour) ~/ TimeConstants.millisecondsPerMinute;

  static int _getPositiveSeconds(Offset offset) => (offset.inMilliseconds.abs() % TimeConstants.millisecondsPerMinute) ~/ TimeConstants.millisecondsPerSecond;

  // Note: to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  @override
  IPartialPattern<Offset> parsePattern(String patternText, TimeMachineFormatInfo formatInfo) => _parsePartialPattern(patternText, formatInfo);

  IPartialPattern<Offset> _parsePartialPattern(String patternText, TimeMachineFormatInfo formatInfo) {
    // Nullity check is performed in OffsetPattern.
    if (patternText.isEmpty) {
      throw InvalidPatternError(TextErrorMessages.formatStringEmpty);
    }

    if (patternText.length == 1) {
      switch (patternText) {
        case 'g':
          return ICompositePatternBuilder.buildAsPartial(CompositePatternBuilder<Offset>()
            ..add(_parsePartialPattern(formatInfo.offsetPatternLong, formatInfo), (offset) => true)
            // _hasZeroSeconds, _hasZeroSecondsAndMinutes can be supplied directly in DartVM
            // we get this failure in Flutter: '(#lib1::Offset) → dart.core::bool' that isn't of expected type '(dynamic) → dart.core::bool'
            //  --> which saddens me
            // todo: investigate (I feel when all the platforms are on the same version of Dart, life will get easier)
            ..add(_parsePartialPattern(formatInfo.offsetPatternMedium, formatInfo), (arg) => _hasZeroSeconds(arg))
            ..add(_parsePartialPattern(formatInfo.offsetPatternShort, formatInfo), (arg) => _hasZeroSecondsAndMinutes(arg)));
        case 'G':
          return _ZPrefixPattern(_parsePartialPattern('g', formatInfo));
        case 'i':
          return ICompositePatternBuilder.buildAsPartial(CompositePatternBuilder<Offset>()
            ..add(_parsePartialPattern(formatInfo.offsetPatternLongNoPunctuation, formatInfo), (offset) => true)
            ..add(_parsePartialPattern(formatInfo.offsetPatternMediumNoPunctuation, formatInfo), (arg) => _hasZeroSeconds(arg))
            ..add(_parsePartialPattern(formatInfo.offsetPatternShortNoPunctuation, formatInfo), (arg) => _hasZeroSecondsAndMinutes(arg)));
        case 'I':
          return _ZPrefixPattern(_parsePartialPattern('i', formatInfo));
        case 'l':
          patternText = formatInfo.offsetPatternLong;
          break;
        case 'm':
          patternText = formatInfo.offsetPatternMedium;
          break;
        case 's':
          patternText = formatInfo.offsetPatternShort;
          break;
        case 'L':
          patternText = formatInfo.offsetPatternLongNoPunctuation;
          break;
        case 'M':
          patternText = formatInfo.offsetPatternMediumNoPunctuation;
          break;
        case 'S':
          patternText = formatInfo.offsetPatternShortNoPunctuation;
          break;
        default:
          throw IInvalidPatternError.format(TextErrorMessages.unknownStandardFormat, [patternText, 'Offset']);
      }
    }
    // This is the only way we'd normally end up in custom parsing land for Z on its own.
    if (patternText == '%Z') {
      throw InvalidPatternError(TextErrorMessages.emptyZPrefixedOffsetPattern);
    }

    // Handle Z-prefix by stripping it, parsing the rest as a normal pattern, then building a special pattern
    // which decides whether or not to delegate.
    bool zPrefix = patternText.startsWith('Z');

    var patternBuilder = SteppedPatternBuilder<Offset, _OffsetParseBucket>(formatInfo, () => _OffsetParseBucket());
    patternBuilder.parseCustomPattern(zPrefix ? patternText.substring(1) : patternText, _patternCharacterHandlers);
    // No need to validate field combinations here, but we do need to do something a bit special
    // for Z-handling.
    IPartialPattern<Offset> pattern = patternBuilder.build(Offset.hoursAndMinutes(5, 30));
    return zPrefix ? _ZPrefixPattern(pattern) : pattern;
  }

  /// Returns true if the offset is representable just in hours and minutes (no seconds).
  static bool _hasZeroSeconds(Offset offset) => (offset.inSeconds % TimeConstants.secondsPerMinute) == 0;

  /// Returns true if the offset is representable just in hours (no minutes or seconds).
  static bool _hasZeroSecondsAndMinutes(Offset offset) => (offset.inSeconds % TimeConstants.secondsPerHour) == 0;

  // #region Character handlers
  static void _handlePlus(PatternCursor pattern, SteppedPatternBuilder<Offset, _OffsetParseBucket> builder) {
    builder.addField(PatternFields.sign, pattern.current);
    builder.addRequiredSign((bucket, positive) => bucket.isNegative = !positive, (offset) => offset.inMilliseconds >= 0);
  }

  static void _handleMinus(PatternCursor pattern, SteppedPatternBuilder<Offset, _OffsetParseBucket> builder) {
    builder.addField(PatternFields.sign, pattern.current);
    builder.addNegativeOnlySign((bucket, positive) => bucket.isNegative = !positive, (offset) => offset.inMilliseconds >= 0);
  }
// #endregion
}

/// Pattern which optionally delegates to another, but both parses and formats Offset.Zero as 'Z'.
class _ZPrefixPattern implements IPartialPattern<Offset> {
  final IPartialPattern<Offset> _fullPattern;

  _ZPrefixPattern(this._fullPattern);

  @override
  ParseResult<Offset> parse(String text) => text == 'Z' ? ParseResult.forValue<Offset>(Offset.zero) : _fullPattern.parse(text);

  @override
  String format(Offset value) => value == Offset.zero ? 'Z' : _fullPattern.format(value);

  @override
  ParseResult<Offset> parsePartial(ValueCursor cursor) {
    if (cursor.current == 'Z') {
      cursor.moveNext();
      return ParseResult.forValue<Offset>(Offset.zero);
    }
    return _fullPattern.parsePartial(cursor);
  }

  @override
  StringBuffer appendFormat(Offset value, StringBuffer builder) {
    Preconditions.checkNotNull(builder, 'builder');
    return value == Offset.zero ? (builder..write('Z')) : _fullPattern.appendFormat(value, builder);
  }
}

/// Provides a container for the interim parsed pieces of an [Offset] value.
class _OffsetParseBucket extends ParseBucket<Offset> {
  /// The hours in the range [0, 23].
  int hours = 0;

  /// The minutes in the range [0, 59].
  int minutes = 0;

  /// The seconds in the range [0, 59].
  int seconds = 0;

  /// Gets a value indicating whether this instance is negative.
  ///
  /// <value>
  /// `true` if this instance is negative; otherwise, `false`.
  /// </value>
  bool isNegative = false;

  /// Calculates the value from the parsed pieces.
  @override
  ParseResult<Offset> calculateValue(PatternFields usedFields, String text) {
    int totalSeconds = hours * TimeConstants.secondsPerHour + minutes * TimeConstants.secondsPerMinute + seconds;
    if (isNegative) {
      totalSeconds = -totalSeconds;
    }
    return ParseResult.forValue<Offset>(Offset(totalSeconds));
  }
}
