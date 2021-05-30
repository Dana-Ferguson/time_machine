// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import '../time_machine_testing.dart';
import 'pattern_test_base.dart';
import 'pattern_test_data.dart';
import 'test_cultures.dart';

Future main() async {
  await runTests();
}

@Test()
class OffsetTimePatternTest extends PatternTestBase<OffsetTime> {
  // The standard example date/time used in all the MSDN samples, which means we can just cut and paste
  // the expected results of the standard patterns. We've got an offset of 1 hour though.
  @private static final OffsetTime MsdnStandardExample =
  TestLocalDateTimes.MsdnStandardExample.clockTime.withOffset(Offset.hours(1));
  @private static final OffsetTime MsdnStandardExampleNoMillis =
  TestLocalDateTimes.MsdnStandardExampleNoMillis.clockTime.withOffset(Offset.hours(1));

  @private static final Offset AthensOffset = Offset.hours(3);

  @internal final List<Data> InvalidPatternData = [
    Data()
      ..pattern = ''
      ..message = TextErrorMessages.formatStringEmpty,
    // Invalid patterns involving embedded values
    Data()
      ..pattern = 'l<t> l<T>'
      ..message = TextErrorMessages.repeatedFieldInPattern
      ..parameters.addAll(['l']),
    Data()
      ..pattern = 'l<T> HH'
      ..message = TextErrorMessages.timeFieldAndEmbeddedTime,
    Data()
      ..pattern = 'l<HH:mm:ss> HH'
      ..message = TextErrorMessages.timeFieldAndEmbeddedTime,
    Data()
      ..pattern = r"l<\"
      ..message = TextErrorMessages.escapeAtEndOfString,
    Data()
      ..pattern = 'x'
      ..message = TextErrorMessages.unknownStandardFormat
      ..parameters.addAll(['x', 'OffsetTime']),
  ];

  @internal List<Data> ParseFailureData = [
    // Failures copied from LocalDateTimePatternTest
    Data()
      ..pattern = 'HH:mm:ss'
      ..text = 'Complete mismatch'
      ..message = TextErrorMessages.mismatchedNumber
      ..parameters.addAll(['HH']),

    Data()
      ..pattern = 'HH:mm:ss o<+HH>'
      ..text = '16:02 +15:00'
      ..message = TextErrorMessages.timeSeparatorMismatch,
    // It's not ideal that the type reported is LocalTime rather than OffsetTime, but probably not worth fixing.
    Data()
      ..pattern = 'HH:mm:ss tt o<+HH>'
      ..text = '16:02:00 AM +15:00'
      ..message = TextErrorMessages.inconsistentValues2
      ..parameters.addAll(['H', 't', 'LocalTime']),
  ];

  @internal List<Data> ParseOnlyData = [
    // Parsing using the semi-colon 'comma dot' specifier
    Data.d(16, 05, 20, 352)
      ..pattern = 'HH:mm:ss;fff'
      ..text = '16:05:20,352',
    Data.d(16, 05, 20, 352)
      ..pattern = 'HH:mm:ss;FFF'
      ..text = '16:05:20,352',
  ];

  @internal List<Data> FormatOnlyData = [
    // Our template value has an offset of 0, but the value has an offset of 1.
    // The pattern doesn't include the offset, so that information is lost - no round-trip.
    Data(MsdnStandardExample)
      ..pattern = 'HH:mm:ss.FF'
      ..text = '13:45:30.09',
    // The value includes milliseconds, which aren't formatted.
    Data(MsdnStandardExample)
      ..standardPattern = OffsetTimePattern.generalIso
      ..standardPatternCode = 'OffsetTimePattern.generalIso'
      ..pattern = 'G'
      ..text = '13:45:30+01'
      ..culture = TestCultures.FrFr,
  ];

  @internal List<Data> FormatAndParseData = [
// Copied from LocalDateTimePatternTest

    // Standard patterns (all invariant)
    Data(MsdnStandardExampleNoMillis)
      ..standardPattern = OffsetTimePattern.generalIso
      ..standardPatternCode = 'OffsetTimePattern.generalIso'
      ..pattern = 'G'
      ..text = '13:45:30+01'
      ..culture = TestCultures.FrFr,
    Data(MsdnStandardExample)
      ..standardPattern = OffsetTimePattern.extendedIso
      ..standardPatternCode = 'OffsetTimePattern.extendedIso'
      ..pattern = 'o'
      ..text = '13:45:30.09+01'
      ..culture = TestCultures.FrFr,

    // Property-only patterns
    Data(MsdnStandardExample)
      ..standardPattern = OffsetTimePattern.rfc3339
      ..standardPatternCode = 'OffsetTimePattern.rfc3339'
      ..pattern = "HH':'mm':'ss;FFFFFFFFFo<Z+HH:mm>"
      ..text = '13:45:30.09+01:00'
      ..culture = TestCultures.FrFr,

    // Embedded patterns
    Data.c(11, 55, 30, AthensOffset)
      ..pattern = 'l<HH_mm_ss> o<g>'
      ..text = '11_55_30 +03',
    Data.c(11, 55, 30, AthensOffset)
      ..pattern = 'l<T> o<g>'
      ..text = '11:55:30 +03',

    // Fields not otherwise covered
    Data(MsdnStandardExample)
      ..pattern = 'h:mm:ss.FF tt o<g>'
      ..text = '1:45:30.09 PM +01',
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);

  @internal Iterable<Data> get FormatData =>
      [FormatOnlyData, FormatAndParseData].expand((x) => x
      );

  @Test()
  void CreateWithInvariantCulture() {
    var pattern = OffsetTimePattern.createWithInvariantCulture('HH:mm:sso<g>');
    expect(identical(TimeMachineFormatInfo.invariantInfo, OffsetTimePatterns.formatInfo(pattern)), isTrue);
    var ot = LocalTime(12, 34, 56).withOffset(Offset.hours(2));
    expect('12:34:56+02', pattern.format(ot));
  }

  @Test()
  void CreateWithCurrentCulture() {
    var ot = LocalTime(12, 34, 56).withOffset(Offset.hours(2));
    Culture.current = TestCultures.FrFr;
    {
      var pattern = OffsetTimePattern.createWithCurrentCulture('l<t> o<g>');
      expect('12:34 +02', pattern.format(ot));
    }
    Culture.current = TestCultures.DotTimeSeparator;
    {
      var pattern = OffsetTimePattern.createWithCurrentCulture('l<t> o<g>');
      expect('12.34 +02', pattern.format(ot));
    }
  }

  @Test()
  void WithCulture() {
    var pattern = OffsetTimePattern.createWithInvariantCulture('HH:mm').withCulture(TestCultures.DotTimeSeparator);
    var text = pattern.format(LocalTime(19, 30, 0).withOffset(Offset.zero));
    expect('19.30', text);
  }

  @Test()
  void WithPatternText() {
    var pattern = OffsetTimePattern.createWithInvariantCulture('HH:mm:ss').withPatternText("HH:mm");
    var value = LocalTime(13, 30, 0).withOffset(Offset.hours(2));
    var text = pattern.format(value);
    expect('13:30', text);
  }

  @Test()
  void WithTemplateValue() {
    var pattern = OffsetTimePattern.createWithInvariantCulture('o<G>')
        .withTemplateValue(LocalTime(13, 30, 0).withOffset(Offset.zero));
    var parsed = pattern
        .parse('+02')
        .value;
    // Local time is taken from the template value; offset is from the text
    expect(LocalTime(13, 30, 0), parsed.clockTime);
    expect(Offset.hours(2), parsed.offset);
  }

  // @Test()
  // void ParseNull() => AssertParseNull(OffsetTimePattern.extendedIso);
}

@internal /*sealed*/class Data extends PatternTestData<OffsetTime> {
  // Default to the start of the year 2000 UTC
  /*protected*/ @override OffsetTime get defaultTemplate => OffsetTimePatterns.defaultTemplateValue;

  /// Initializes a new instance of the [Data] class.
  ///
  /// [value]: The value.
  @internal Data([OffsetTime? value]) : super(value ?? OffsetTimePatterns.defaultTemplateValue);

  @internal Data.a(int hour, int minute, Offset offset) : this.c(hour, minute, 0, offset);

  @internal Data.b(int hour, int minute, int second) : this.d(hour, minute, second, 0);

  @internal Data.c(int hour, int minute, int second, Offset offset)
      : this.e(hour, minute, second, 0, offset);

  @internal Data.d(int hour, int minute, int second, int millis)
      : this.e(hour, minute, second, millis, Offset.zero);

  @internal Data.e(int hour, int minute, int second, int millis, Offset offset)
      : this(LocalTime(hour, minute, second, ms: millis).withOffset(offset));

  @internal
  @override
  IPattern<OffsetTime> CreatePattern() =>
      OffsetTimePattern.createWithCulture(super.pattern, super.culture, template);
}



