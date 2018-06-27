// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';
import 'dart:math' as math;
import 'dart:mirrors';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_patterns.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import '../time_machine_testing.dart';
import 'pattern_test_base.dart';
import 'pattern_test_data.dart';
import 'test_cultures.dart';
import 'text_cursor_test_base_tests.dart';

Future main() async {
  await runTests();
}

@Test()
class OffsetTimePatternTest extends PatternTestBase<OffsetTime> {
  // The standard example date/time used in all the MSDN samples, which means we can just cut and paste
  // the expected results of the standard patterns. We've got an offset of 1 hour though.
  @private static final OffsetTime MsdnStandardExample =
  TestLocalDateTimes.MsdnStandardExample.time.withOffset(new Offset.fromHours(1));
  @private static final OffsetTime MsdnStandardExampleNoMillis =
  TestLocalDateTimes.MsdnStandardExampleNoMillis.time.withOffset(new Offset.fromHours(1));

  @private static final Offset AthensOffset = new Offset.fromHours(3);

  @internal final List<Data> InvalidPatternData = [
    new Data()
      ..Pattern = ""
      ..Message = TextErrorMessages.formatStringEmpty,
    // Invalid patterns involving embedded values
    new Data()
      ..Pattern = "l<t> l<T>"
      ..Message = TextErrorMessages.repeatedFieldInPattern
      ..Parameters.addAll(['l']),
    new Data()
      ..Pattern = "l<T> HH"
      ..Message = TextErrorMessages.timeFieldAndEmbeddedTime,
    new Data()
      ..Pattern = "l<HH:mm:ss> HH"
      ..Message = TextErrorMessages.timeFieldAndEmbeddedTime,
    new Data()
      ..Pattern = r"l<\"
      ..Message = TextErrorMessages.escapeAtEndOfString,
    new Data()
      ..Pattern = "x"
      ..Message = TextErrorMessages.unknownStandardFormat
      ..Parameters.addAll(['x', 'OffsetTime']),
  ];

  @internal List<Data> ParseFailureData = [
    // Failures copied from LocalDateTimePatternTest
    new Data()
      ..Pattern = "HH:mm:ss"
      ..text = "Complete mismatch"
      ..Message = TextErrorMessages.mismatchedNumber
      ..Parameters.addAll(["HH"]),

    new Data()
      ..Pattern = "HH:mm:ss o<+HH>"
      ..text = "16:02 +15:00"
      ..Message = TextErrorMessages.timeSeparatorMismatch,
    // It's not ideal that the type reported is LocalTime rather than OffsetTime, but probably not worth fixing.
    new Data()
      ..Pattern = "HH:mm:ss tt o<+HH>"
      ..text = "16:02:00 AM +15:00"
      ..Message = TextErrorMessages.inconsistentValues2
      ..Parameters.addAll(['H', 't', 'LocalTime']),
  ];

  @internal List<Data> ParseOnlyData = [
    // Parsing using the semi-colon "comma dot" specifier
    new Data.d(16, 05, 20, 352)
      ..Pattern = "HH:mm:ss;fff"
      ..text = "16:05:20,352",
    new Data.d(16, 05, 20, 352)
      ..Pattern = "HH:mm:ss;FFF"
      ..text = "16:05:20,352",
  ];

  @internal List<Data> FormatOnlyData = [
    // Our template value has an offset of 0, but the value has an offset of 1.
    // The pattern doesn't include the offset, so that information is lost - no round-trip.
    new Data(MsdnStandardExample)
      ..Pattern = "HH:mm:ss.FF"
      ..text = "13:45:30.09",
    // The value includes milliseconds, which aren't formatted.
    new Data(MsdnStandardExample)
      ..StandardPattern = OffsetTimePattern.generalIso
      ..Pattern = "G"
      ..text = "13:45:30+01"
      ..Culture = TestCultures.FrFr,
  ];

  @internal List<Data> FormatAndParseData = [
// Copied from LocalDateTimePatternTest

    // Standard patterns (all invariant)
    new Data(MsdnStandardExampleNoMillis)
      ..StandardPattern = OffsetTimePattern.generalIso
      ..Pattern = "G"
      ..text = "13:45:30+01"
      ..Culture = TestCultures.FrFr,
    new Data(MsdnStandardExample)
      ..StandardPattern = OffsetTimePattern.extendedIso
      ..Pattern = "o"
      ..text = "13:45:30.09+01"
      ..Culture = TestCultures.FrFr,

    // Property-only patterns
    new Data(MsdnStandardExample)
      ..StandardPattern = OffsetTimePattern.rfc3339
      ..Pattern = "HH':'mm':'ss;FFFFFFFFFo<Z+HH:mm>"
      ..text = "13:45:30.09+01:00"
      ..Culture = TestCultures.FrFr,

    // Embedded patterns
    new Data.c(11, 55, 30, AthensOffset)
      ..Pattern = "l<HH_mm_ss> o<g>"
      ..text = "11_55_30 +03",
    new Data.c(11, 55, 30, AthensOffset)
      ..Pattern = "l<T> o<g>"
      ..text = "11:55:30 +03",

    // Fields not otherwise covered
    new Data(MsdnStandardExample)
      ..Pattern = "h:mm:ss.FF tt o<g>"
      ..text = "1:45:30.09 PM +01",
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);

  @internal Iterable<Data> get FormatData =>
      [FormatOnlyData, FormatAndParseData].expand((x) => x
      );

  @Test()
  void CreateWithInvariantCulture() {
    var pattern = OffsetTimePattern.createWithInvariantCulture("HH:mm:sso<g>");
    expect(identical(TimeMachineFormatInfo.invariantInfo, OffsetTimePatterns.formatInfo(pattern)), isTrue);
    var ot = new LocalTime(12, 34, 56).withOffset(new Offset.fromHours(2));
    expect("12:34:56+02", pattern.format(ot));
  }

  @Test()
  void CreateWithCurrentCulture() {
    var ot = new LocalTime(12, 34, 56).withOffset(new Offset.fromHours(2));
    CultureInfo.currentCulture = TestCultures.FrFr;
    {
      var pattern = OffsetTimePattern.createWithCurrentCulture("l<t> o<g>");
      expect("12:34 +02", pattern.format(ot));
    }
    CultureInfo.currentCulture = TestCultures.DotTimeSeparator;
    {
      var pattern = OffsetTimePattern.createWithCurrentCulture("l<t> o<g>");
      expect("12.34 +02", pattern.format(ot));
    }
  }

  @Test()
  void WithCulture() {
    var pattern = OffsetTimePattern.createWithInvariantCulture("HH:mm").withCulture(TestCultures.DotTimeSeparator);
    var text = pattern.format(new LocalTime(19, 30).withOffset(Offset.zero));
    expect("19.30", text);
  }

  @Test()
  void WithPatternText() {
    var pattern = OffsetTimePattern.createWithInvariantCulture("HH:mm:ss").withPatternText("HH:mm");
    var value = new LocalTime(13, 30).withOffset(new Offset.fromHours(2));
    var text = pattern.format(value);
    expect("13:30", text);
  }

  @Test()
  void WithTemplateValue() {
    var pattern = OffsetTimePattern.createWithInvariantCulture("o<G>")
        .withTemplateValue(new LocalTime(13, 30).withOffset(Offset.zero));
    var parsed = pattern
        .parse("+02")
        .value;
    // Local time is taken from the template value; offset is from the text
    expect(new LocalTime(13, 30), parsed.timeOfDay);
    expect(new Offset.fromHours(2), parsed.offset);
  }

  @Test()
  void ParseNull() => AssertParseNull(OffsetTimePattern.extendedIso);
}

@internal /*sealed*/class Data extends PatternTestData<OffsetTime> {
  // Default to the start of the year 2000 UTC
  /*protected*/ @override OffsetTime get DefaultTemplate => OffsetTimePatterns.defaultTemplateValue;

  /// Initializes a new instance of the [Data] class.
  ///
  /// [value]: The value.
  @internal Data([OffsetTime value = null]) : super(value ?? OffsetTimePatterns.defaultTemplateValue);

  @internal Data.a(int hour, int minute, Offset offset) : this.c(hour, minute, 0, offset);

  @internal Data.b(int hour, int minute, int second) : this.d(hour, minute, second, 0);

  @internal Data.c(int hour, int minute, int second, Offset offset)
      : this.e(hour, minute, second, 0, offset);

  @internal Data.d(int hour, int minute, int second, int millis)
      : this.e(hour, minute, second, millis, Offset.zero);

  @internal Data.e(int hour, int minute, int second, int millis, Offset offset)
      : this(new LocalTime(hour, minute, second, millis).withOffset(offset));

  @internal
  @override
  IPattern<OffsetTime> CreatePattern() =>
      OffsetTimePattern.createWithCulture(super.Pattern, super.Culture, Template);
}



