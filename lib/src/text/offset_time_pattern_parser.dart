// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';

@internal /*sealed*/ class OffsetTimePatternParser implements IPatternParser<OffsetTime> {
  @private final OffsetTime templateValue;

  @private static final Map<String/*char*/, CharacterHandler<OffsetTime, OffsetTimeParseBucket>> PatternCharacterHandlers =
  {
    '%': SteppedPatternBuilder.handlePercent /**<OffsetTime, OffsetTimeParseBucket>*/,
    '\'': SteppedPatternBuilder.HandleQuote /**<OffsetTime, OffsetTimeParseBucket>*/,
    '\"': SteppedPatternBuilder.HandleQuote /**<OffsetTime, OffsetTimeParseBucket>*/,
    '\\': SteppedPatternBuilder.HandleBackslash /**<OffsetTime, OffsetTimeParseBucket>*/,
    '.': TimePatternHelper.createPeriodHandler<OffsetTime, OffsetTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.Time.FractionalSeconds = value),
    ';': TimePatternHelper.createCommaDotHandler<OffsetTime, OffsetTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.Time.FractionalSeconds = value),
    ':': (pattern, builder) => builder.addLiteral1(builder.formatInfo.timeSeparator, ParseResult.TimeSeparatorMismatch /**<OffsetTime>*/),
    'h': SteppedPatternBuilder.handlePaddedField<OffsetTime, OffsetTimeParseBucket>(
        2, PatternFields.hours12, 1, 12, (value) => value.clockHourOfHalfDay, (bucket, value) => bucket.Time.Hours12 = value),
    'H': SteppedPatternBuilder.handlePaddedField<OffsetTime, OffsetTimeParseBucket>(
        2, PatternFields.hours24, 0, 24, (value) => value.hour, (bucket, value) => bucket.Time.Hours24 = value),
    'm': SteppedPatternBuilder.handlePaddedField<OffsetTime, OffsetTimeParseBucket>(
        2, PatternFields.minutes, 0, 59, (value) => value.minute, (bucket, value) => bucket.Time.Minutes = value),
    's': SteppedPatternBuilder.handlePaddedField<OffsetTime, OffsetTimeParseBucket>(
        2, PatternFields.seconds, 0, 59, (value) => value.second, (bucket, value) => bucket.Time.Seconds = value),
    'f': TimePatternHelper.createFractionHandler<OffsetTime, OffsetTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.Time.FractionalSeconds = value),
    'F': TimePatternHelper.createFractionHandler<OffsetTime, OffsetTimeParseBucket>(
        9, (value) => value.nanosecondOfSecond, (bucket, value) => bucket.Time.FractionalSeconds = value),
    't': TimePatternHelper.createAmPmHandler<OffsetTime, OffsetTimeParseBucket>((time) => time.hour, (bucket, value) => bucket.Time.AmPm = value),
    'o': HandleOffset,
    'l': (cursor, builder) => builder.addEmbeddedTimePattern(cursor.Current, cursor.getEmbeddedPattern(), (bucket) => bucket.Time, (value) => value.timeOfDay),
  };

  @internal OffsetTimePatternParser(this.templateValue);

  // Note: to implement the interface. It does no harm, and it's simpler than using explicit
  // interface implementation.
  IPattern<OffsetTime> parsePattern(String patternText, TimeMachineFormatInfo formatInfo) {
    // Nullity check is performed in OffsetTimePattern.
    if (patternText.length == 0) {
      throw new InvalidPatternError(TextErrorMessages.FormatStringEmpty);
    }

    // Handle standard patterns
    if (patternText.length == 1) {
      switch (patternText[0]) {
        case 'G':
          return OffsetTimePatterns.GeneralIsoPatternImpl;
        case 'o':
          return OffsetTimePatterns.ExtendedIsoPatternImpl;
        default:
          throw new InvalidPatternError.format(TextErrorMessages.UnknownStandardFormat, [patternText[0], 'OffsetTime']);
      }
    }

    var patternBuilder = new SteppedPatternBuilder<OffsetTime, OffsetTimeParseBucket>(formatInfo, () => new OffsetTimeParseBucket(templateValue));
    patternBuilder.parseCustomPattern(patternText, PatternCharacterHandlers);
    patternBuilder.validateUsedFields();
    // Need to reconstruct the template value from the bits...
    return patternBuilder.build(templateValue);
  }

  @private static void HandleOffset(PatternCursor pattern,
      SteppedPatternBuilder<OffsetTime, OffsetTimeParseBucket> builder) {
    builder.addField(PatternFields.embeddedOffset, pattern.Current);
    String embeddedPattern = pattern.getEmbeddedPattern();
    var offsetPattern = OffsetPattern
        .Create(embeddedPattern, builder.formatInfo)
        .UnderlyingPattern;
    builder.addEmbeddedPattern(offsetPattern, (bucket, offset) => bucket.offset = offset, (zdt) => zdt.offset);
  }
}

@private /*sealed*/ class OffsetTimeParseBucket extends ParseBucket<OffsetTime> {
  @internal final /*LocalTimePatternParser.*/LocalTimeParseBucket Time;
  @internal Offset offset;

  @internal OffsetTimeParseBucket(OffsetTime templateValue)
      :Time = new /*LocalTimePatternParser.*/LocalTimeParseBucket(templateValue.timeOfDay),
        offset = templateValue.offset;


  @internal
  @override
  ParseResult<OffsetTime> CalculateValue(PatternFields usedFields, String text) {
    ParseResult<LocalTime> timeResult = Time.CalculateValue(usedFields & PatternFields.allTimeFields, text);
    if (!timeResult.Success) {
      return timeResult.ConvertError<OffsetTime>();
    }
    LocalTime date = timeResult.Value;
    return ParseResult.ForValue<OffsetTime>(date.withOffset(offset));
  }
}

