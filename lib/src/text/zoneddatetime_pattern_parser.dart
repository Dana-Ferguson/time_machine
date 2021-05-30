// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/text/patterns/time_machine_patterns.dart';

@internal
class ZonedDateTimePatternParser implements IPatternParser<ZonedDateTime> {
  final ZonedDateTime _templateValue;
  final DateTimeZoneProvider? _zoneProvider;
  final ZoneLocalMappingResolver? _resolver;

  static final Map<String /*char*/, CharacterHandler<ZonedDateTime, _ZonedDateTimeParseBucket>> _patternCharacterHandlers =
  {
    '%': SteppedPatternBuilder.handlePercent /**<ZonedDateTime, ZonedDateTimeParseBucket>*/,
    '\'': SteppedPatternBuilder.handleQuote /**<ZonedDateTime, ZonedDateTimeParseBucket>*/,
    '\"': SteppedPatternBuilder.handleQuote /**<ZonedDateTime, ZonedDateTimeParseBucket>*/,
    '\\': SteppedPatternBuilder.handleBackslash /**<ZonedDateTime, ZonedDateTimeParseBucket>*/,
    '/': (pattern, builder) => builder.addLiteral1(builder.formatInfo.dateSeparator, IParseResult.dateSeparatorMismatch /**<ZonedDateTime>*/),
    'T': (pattern, builder) => builder.addLiteral2('T', IParseResult.mismatchedCharacter /**<ZonedDateTime>*/),
    'y': DatePatternHelper.createYearOfEraHandler<ZonedDateTime, _ZonedDateTimeParseBucket>((value) => value.yearOfEra, (bucket, value) =>
    bucket.date.yearOfEra = value),
    'u': SteppedPatternBuilder.handlePaddedField<ZonedDateTime, _ZonedDateTimeParseBucket>(
        4, PatternFields.year, -9999, 9999, (value) => value.year, (bucket, value) => bucket.date.year = value),
    'M': DatePatternHelper.createMonthOfYearHandler<ZonedDateTime, _ZonedDateTimeParseBucket>((value) => value.monthOfYear, (bucket, value) =>
    bucket.date.monthOfYearText = value, (bucket, value) => bucket.date.monthOfYearNumeric = value),
    'd': DatePatternHelper.createDayHandler<ZonedDateTime, _ZonedDateTimeParseBucket>((value) => value.dayOfMonth, (value) => value.dayOfWeek.value, (bucket, value) =>
    bucket.date.dayOfMonth = value, (bucket, value) => bucket.date.dayOfWeek = value),
    '.': TimePatternHelper.createPeriodHandler<ZonedDateTime, _ZonedDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.time.fractionalSeconds = value),
    ';': TimePatternHelper.createCommaDotHandler<ZonedDateTime, _ZonedDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.time.fractionalSeconds = value),
    ':': (pattern, builder) => builder.addLiteral1(builder.formatInfo.timeSeparator, IParseResult.timeSeparatorMismatch /**<ZonedDateTime>*/),
    'h': SteppedPatternBuilder.handlePaddedField<ZonedDateTime, _ZonedDateTimeParseBucket>(
        2, PatternFields.hours12, 1, 12, (value) => value.hourOf12HourClock, (bucket, value) => bucket.time.hours12 = value),
    'H': SteppedPatternBuilder.handlePaddedField<ZonedDateTime, _ZonedDateTimeParseBucket>(
        2, PatternFields.hours24, 0, 24, (value) => value.hourOfDay, (bucket, value) => bucket.time.hours24 = value),
    'm': SteppedPatternBuilder.handlePaddedField<ZonedDateTime, _ZonedDateTimeParseBucket>(
        2, PatternFields.minutes, 0, 59, (value) => value.minuteOfHour, (bucket, value) => bucket.time.minutes = value),
    's': SteppedPatternBuilder.handlePaddedField<ZonedDateTime, _ZonedDateTimeParseBucket>(
        2, PatternFields.seconds, 0, 59, (value) => value.secondOfMinute, (bucket, value) => bucket.time.seconds = value),
    'f': TimePatternHelper.createFractionHandler<ZonedDateTime, _ZonedDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.time.fractionalSeconds = value),
    'F': TimePatternHelper.createFractionHandler<ZonedDateTime, _ZonedDateTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.time.fractionalSeconds = value),
    't': TimePatternHelper.createAmPmHandler<ZonedDateTime, _ZonedDateTimeParseBucket>((time) => time.hourOfDay, (bucket, value) => bucket.time.amPm = value),
    'c': DatePatternHelper.createCalendarHandler<ZonedDateTime, _ZonedDateTimeParseBucket>((value) => value.localDateTime.calendar, (bucket, value) =>
    bucket.date.calendar = value),
    'g': DatePatternHelper.createEraHandler<ZonedDateTime, _ZonedDateTimeParseBucket>((value) => value.era, (bucket) => bucket.date),
    'z': _handleZone,
    'x': _handleZoneAbbreviation,
    'o': _handleOffset,
    'l': (cursor, builder) => builder.addEmbeddedLocalPartial(
        cursor, (bucket) => bucket.date, (bucket) => bucket.time, (value) => value.calendarDate, (value) => value.clockTime, (value) => value.localDateTime),
  };

  ZonedDateTimePatternParser(this._templateValue, this._resolver, this._zoneProvider);

  // Note: public to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  @override
  IPattern<ZonedDateTime> parsePattern(String patternText, TimeMachineFormatInfo formatInfo) {
    // Nullity check is performed in ZonedDateTimePattern.
    if (patternText.isEmpty) {
      throw InvalidPatternError(TextErrorMessages.formatStringEmpty);
    }

    // Handle standard patterns
    if (patternText.length == 1) {
      switch (patternText[0]) {
        case 'G':
          return ZonedDateTimePatterns.generalFormatOnlyPatternImpl
              .withZoneProvider(_zoneProvider)
              .withResolver(_resolver);
        case 'F':
          return ZonedDateTimePatterns.extendedFormatOnlyPatternImpl
              .withZoneProvider(_zoneProvider)
              .withResolver(_resolver);
        default:
          throw IInvalidPatternError.format(TextErrorMessages.unknownStandardFormat, [patternText[0], 'ZonedDateTime']);
      }
    }

    var patternBuilder = SteppedPatternBuilder<ZonedDateTime, _ZonedDateTimeParseBucket>(formatInfo,
            () => _ZonedDateTimeParseBucket(_templateValue, _resolver, _zoneProvider));
    if (_zoneProvider == null || _resolver == null) {
      patternBuilder.setFormatOnly();
    }
    patternBuilder.parseCustomPattern(patternText, _patternCharacterHandlers);
    patternBuilder.validateUsedFields();
    return patternBuilder.build(_templateValue);
  }

  static void _handleZone(PatternCursor pattern,
      SteppedPatternBuilder<ZonedDateTime, _ZonedDateTimeParseBucket> builder) {
    builder.addField(PatternFields.zone, pattern.current);
    builder.addParseAction(_parseZone);
    builder.addFormatAction((value, sb) => sb.write(value.zone.id));
  }

  static void _handleZoneAbbreviation(PatternCursor pattern,
      SteppedPatternBuilder<ZonedDateTime, _ZonedDateTimeParseBucket> builder) {
    builder.addField(PatternFields.zoneAbbreviation, pattern.current);
    builder.setFormatOnly();
    builder.addFormatAction((value, sb) =>
        sb.write(value
            .getZoneInterval()
            .name));
  }

  static void _handleOffset(PatternCursor pattern,
      SteppedPatternBuilder<ZonedDateTime, _ZonedDateTimeParseBucket> builder) {
    builder.addField(PatternFields.embeddedOffset, pattern.current);
    String embeddedPattern = pattern.getEmbeddedPattern();
    var offsetPattern = OffsetPatterns.underlyingPattern(OffsetPatterns.create(embeddedPattern, builder.formatInfo));
    builder.addEmbeddedPattern<Offset>(offsetPattern, (bucket, offset) => bucket.offset = offset, (zdt) => zdt.offset);
  }

  static ParseResult<ZonedDateTime>? _parseZone(ValueCursor value, _ZonedDateTimeParseBucket bucket) => bucket.parseZone(value);
}

class _ZonedDateTimeParseBucket extends ParseBucket<ZonedDateTime> {
  final /*LocalDatePatternParser.*/LocalDateParseBucket date;
  final /*LocalTimePatternParser.*/LocalTimeParseBucket time;
  DateTimeZone _zone;
  late Offset offset;
  final ZoneLocalMappingResolver? _resolver;
  final DateTimeZoneProvider? _zoneProvider;

  _ZonedDateTimeParseBucket(ZonedDateTime templateValue, this._resolver, this._zoneProvider)
      : date = /*LocalDatePatternParser.*/LocalDateParseBucket(templateValue.calendarDate),
        time = /*LocalTimePatternParser.*/LocalTimeParseBucket(templateValue.clockTime),
        _zone = templateValue.zone;


  ParseResult<ZonedDateTime>? parseZone(ValueCursor value) {
    DateTimeZone? zone = _tryParseFixedZone(value) ?? _tryParseProviderZone(value);

    if (zone == null) {
      return IParseResult.noMatchingZoneId<ZonedDateTime>(value);
    }
    _zone = zone;
    return null;
  }

  /// Attempts to parse a fixed time zone from 'UTC' with an optional
  /// offset, expressed as +HH, +HH:mm, +HH:mm:ss or +HH:mm:ss.fff - i.e. the
  /// general format. If it manages, it will move the cursor and return the
  /// zone. Otherwise, it will return null and the cursor will remain where
  /// it was.
  DateTimeZone? _tryParseFixedZone(ValueCursor value) {
    if (value.compareOrdinal(IDateTimeZone.utcId) != 0) {
      return null;
    }
    value.move(value.index + 3);
    var pattern = OffsetPatterns.underlyingPattern(OffsetPattern.generalInvariant);
    var parseResult = pattern.parsePartial(value);
    return parseResult.success ? DateTimeZone.forOffset(parseResult.value) : DateTimeZone.utc;
  }

  /// Tries to parse a time zone ID from the provider. Returns the zone
  /// on success (after moving the cursor to the end of the ID) or null on failure
  /// (leaving the cursor where it was).
  DateTimeZone? _tryParseProviderZone(ValueCursor value) {
    // The IDs from the provider are guaranteed to be in order (using ordinal comparisons).
    // Use a binary search to find a match, then make sure it's the longest possible match.
    var ids = _zoneProvider!.ids;
    int lowerBound = 0; // Inclusive
    int upperBound = ids.length; // Exclusive
    while (lowerBound < upperBound) {
      int guess = (lowerBound + upperBound) ~/ 2;
      int result = value.compareOrdinal(ids[guess]);
      if (result < 0) {
        // Guess is later than our text: lower the upper bound
        upperBound = guess;
      }
      else if (result > 0) {
        // Guess is earlier than our text: raise the lower bound
        lowerBound = guess + 1;
      }
      else {
        // We've found a match! But it may not be as long as it
        // could be. Keep track of a 'longest match so far' (starting with the match we've found),
        // and keep looking through the IDs until we find an ID which doesn't start with that "longest
        // match so far", at which point we know we're done.
        //
        // We can't just look through all the IDs from "guess" to "lowerBound" and stop when we hit
        // a non-match against 'value', because of situations like this:
        // value=Etc/GMT-12
        // guess=Etc/GMT-1
        // IDs includes { Etc/GMT-1, Etc/GMT-10, Etc/GMT-11, Etc/GMT-12, Etc/GMT-13 }
        // We can't stop when we hit Etc/GMT-10, because otherwise we won't find Etc/GMT-12.
        // We *can* stop when we get to Etc/GMT-13, because by then our longest match so far will
        // be Etc/GMT-12, and we know that anything beyond Etc/GMT-13 won't match that.
        // We can also stop when we hit upperBound, without any more comparisons.
        String longestSoFar = ids[guess];
        for (int i = guess + 1; i < upperBound; i++) {
          String candidate = ids[i];
          if (candidate.length < longestSoFar.length) {
            break;
          }
          if (stringOrdinalCompare(longestSoFar, 0, candidate, 0, longestSoFar.length) != 0) {
            break;
          }
          if (value.compareOrdinal(candidate) == 0) {
            longestSoFar = candidate;
          }
        }
        value.move(value.index + longestSoFar.length);
        return _zoneProvider!.getDateTimeZoneSync(longestSoFar); // [longestSoFar];
      }
    }
    return null;
  }

  @override
  ParseResult<ZonedDateTime> calculateValue(PatternFields usedFields, String text) {
    var localResult = /*LocalDateTimePatternParser.*/LocalDateTimeParseBucket.combineBuckets(usedFields, date, time, text);
    if (!localResult.success) {
      return localResult.convertError<ZonedDateTime>();
    }

    var localDateTime = localResult.value;

    // No offset - so just use the resolver
    if ((usedFields & PatternFields.embeddedOffset).value == 0) {
      try {
        return ParseResult.forValue<ZonedDateTime>(ZonedDateTime.resolve(localDateTime, _zone, _resolver!));
      }
      on SkippedTimeError {
        return IParseResult.skippedLocalTime<ZonedDateTime>(text);
      }
      on AmbiguousTimeError {
        return IParseResult.ambiguousLocalTime<ZonedDateTime>(text);
      }
    }

    // We were given an offset, so we can resolve and validate using that
    var mapping = _zone.mapLocal(localDateTime);
    ZonedDateTime result;
    switch (mapping.count) {
      // If the local time was skipped, the offset has to be invalid.
      case 0:
        return IParseResult.invalidOffset<ZonedDateTime>(text);
      case 1:
        result = mapping.first(); // We'll validate in a minute
        break;
      case 2:
        result = mapping
            .first()
            .offset == offset ? mapping.first() : mapping.last();
        break;
      default:
        throw /*InvalidOperationException*/ StateError('Mapping has count outside range 0-2; should not happen.');
    }
    if (result.offset != offset) {
      return IParseResult.invalidOffset<ZonedDateTime>(text);
    }
    return ParseResult.forValue<ZonedDateTime>(result);
  }
}

