// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';

import '../time_machine_testing.dart';
import 'pattern_test_base.dart';
import 'pattern_test_data.dart';
import 'test_cultures.dart';

Future main() async {
  await runTests();
}

@Test()
class SpanPatternTest extends PatternTestBase<Time> {
  /// Test data that can only be used to test formatting.
  @internal  final List<Data> FormatOnlyData = [
    // No sign, so we can't parse it.
    Data.hm(-1, 0)
      ..pattern = 'HH:mm'
      ..text = '01:00',

    // Loss of nano precision
    Data.dhmsn(1, 2, 3, 4, 123456789)
      ..pattern = 'D:hh:mm:ss.ffff'
      ..text = '1:02:03:04.1234',
    Data.dhmsn(1, 2, 3, 4, 123456789)
      ..pattern = 'D:hh:mm:ss.FFFF'
      ..text = '1:02:03:04.1234',
  ];

  /// Test data that can only be used to test successful parsing.
  @internal  final List<Data> ParseOnlyData = [];

  /// Test data for invalid patterns
  @internal  final List<Data> InvalidPatternData = [
    Data()
      ..pattern = ''
      ..message = TextErrorMessages.formatStringEmpty,
    Data()
      ..pattern = 'HH:MM'
      ..message = TextErrorMessages.multipleCapitalSpanFields,
    Data()
      ..pattern = 'HH D'
      ..message = TextErrorMessages.multipleCapitalSpanFields,
    Data()
      ..pattern = 'MM mm'
      ..message = TextErrorMessages.repeatedFieldInPattern
      ..parameters.addAll(['m']),
    Data()
      ..pattern = 'G'
      ..message = TextErrorMessages.unknownStandardFormat
      ..parameters.addAll(['G', 'Time'])
  ];

  /// Tests for parsing failures (of values)
  @internal  final List<Data> ParseFailureData = [
    Data(Time.zero)
      ..pattern = 'H:mm'
      ..text = '1:60'
      ..message = TextErrorMessages.fieldValueOutOfRange
      ..parameters.addAll([60, 'm', 'Time']),
    // Total field values out of range
    Data(Time.minValue)
      ..pattern = '-D:hh:mm:ss.fffffffff'
      ..text = '16777217:00:00:00.000000000'
      ..
      message = TextErrorMessages.fieldValueOutOfRange
      ..parameters.addAll(['16777217', 'D', 'Time']),
    Data(Time.minValue)
      ..pattern = '-H:mm:ss.fffffffff'
      ..text = '402653185:00:00.000000000'
      ..
      message = TextErrorMessages.fieldValueOutOfRange
      ..parameters.addAll(['402653185', 'H', 'Time']),
    Data(Time.minValue)
      ..pattern = '-M:ss.fffffffff'
      ..text = '24159191041:00.000000000'
      ..
      message = TextErrorMessages.fieldValueOutOfRange
      ..parameters.addAll(['24159191041', 'M', 'Time']),
    Data(Time.minValue)
      ..pattern = '-S.fffffffff'
      ..text = '1449551462401.000000000'
      ..
      message = TextErrorMessages.fieldValueOutOfRange
      ..parameters.addAll(['1449551462401', 'S', 'Time']),

  /* note: In Dart we don't go out of range -- todo: evaluate -- should we?
    // Each field in range, but overall result out of range
    new Data(Span.minValue)
      ..Pattern = '-D:hh:mm:ss.fffffffff'
      ..Text = '-16777216:00:00:00.000000001'
      ..Message = TextErrorMessages.OverallValueOutOfRange
      ..Parameters.addAll(['Time']),
    new Data(Span.maxValue)
      ..Pattern = '-D:hh:mm:ss.fffffffff'
      ..Text = '16777216:00:00:00.000000000'
      ..Message = TextErrorMessages.OverallValueOutOfRange
      ..Parameters.addAll(['Time']),
    new Data(Span.minValue)
      ..Pattern = '-H:mm:ss.fffffffff'
      ..Text = '-402653184:00:00.000000001'
      ..Message = TextErrorMessages.OverallValueOutOfRange
      ..Parameters.addAll(['Time']),
    new Data(Span.minValue)
      ..Pattern = '-H:mm:ss.fffffffff'
      ..Text = '402653184:00:00.000000000'
      ..Message = TextErrorMessages.OverallValueOutOfRange
      ..Parameters.addAll(['Time']),
    new Data(Span.minValue)
      ..Pattern = '-M:ss.fffffffff'
      ..Text = '-24159191040:00.000000001'
      ..Message = TextErrorMessages.OverallValueOutOfRange
      ..Parameters.addAll(['Time']),
    new Data(Span.minValue)
      ..Pattern = '-M:ss.fffffffff'
      ..Text = '24159191040:00.000000000'
      ..Message = TextErrorMessages.OverallValueOutOfRange
      ..Parameters.addAll(['Time']),
    new Data(Span.minValue)
      ..Pattern = '-S.fffffffff'
      ..Text = '-1449551462400.000000001'
      ..Message = TextErrorMessages.OverallValueOutOfRange
      ..Parameters.addAll(['Time']),
    new Data(Span.minValue)
      ..Pattern = '-S.fffffffff'
      ..Text = '1449551462400.000000000'
      ..Message = TextErrorMessages.OverallValueOutOfRange
      ..Parameters.addAll(['Time']),*/
    Data(Time.minValue)
      ..pattern = "'x'S"
      ..text = 'x'
      ..message = TextErrorMessages.mismatchedNumber
      ..parameters.addAll(['S'])
  ];

  /// Common test data for both formatting and parsing. A test should be placed here unless is truly
  /// cannot be run both ways. This ensures that as many round-trip type tests are performed as possible.
  @internal  final List<Data> FormatAndParseData = [
    Data.hm(1, 2)
      ..pattern = '+HH:mm'
      ..text = '+01:02',
    Data.hm(-1, -2)
      ..pattern = '+HH:mm'
      ..text = '-01:02',
    Data.hm(1, 2)
      ..pattern = '-HH:mm'
      ..text = '01:02',
    Data.hm(-1, -2)
      ..pattern = '-HH:mm'
      ..text = '-01:02',

    Data.hm(26, 3)
      ..pattern = 'D:h:m'
      ..text = '1:2:3',
    Data.hm(26, 3)
      ..pattern = 'DD:hh:mm'
      ..text = '01:02:03',
    Data.hm(242, 3)
      ..pattern = 'D:hh:mm'
      ..text = '10:02:03',

    Data.hm(2, 3)
      ..pattern = 'H:mm'
      ..text = '2:03',
    Data.hm(2, 3)
      ..pattern = 'HH:mm'
      ..text = '02:03',
    Data.hm(26, 3)
      ..pattern = 'HH:mm'
      ..text = '26:03',
    Data.hm(260, 3)
      ..pattern = 'HH:mm'
      ..text = '260:03',

    Data.hms(2, 3, 4)
      ..pattern = 'H:mm:ss'
      ..text = '2:03:04',

    Data.dhmsn(1, 2, 3, 4, 123456789)
      ..pattern = 'D:hh:mm:ss.fffffffff'
      ..text = '1:02:03:04.123456789',
    Data.dhmsn(1, 2, 3, 4, 123456000)
      ..pattern = 'D:hh:mm:ss.fffffffff'
      ..text = '1:02:03:04.123456000',
    Data.dhmsn(1, 2, 3, 4, 123456789)
      ..pattern = 'D:hh:mm:ss.FFFFFFFFF'
      ..text = '1:02:03:04.123456789',
    Data.dhmsn(1, 2, 3, 4, 123456000)
      ..pattern = 'D:hh:mm:ss.FFFFFFFFF'
      ..text = '1:02:03:04.123456',
    Data.hms(1, 2, 3)
      ..pattern = 'M:ss'
      ..text = '62:03',
    Data.hms(1, 2, 3)
      ..pattern = 'MMM:ss'
      ..text = '062:03',

    Data.dhmsn(0, 0, 1, 2, 123400000)
      ..pattern = 'SS.FFFF'
      ..text = '62.1234',

    Data.dhmsn(1, 2, 3, 4, 123456789)
      ..pattern = 'D:hh:mm:ss.FFFFFFFFF'
      ..text = '1.02.03.04.123456789'
      ..culture = TestCultures.DotTimeSeparator,

    // Roundtrip pattern is invariant; redundantly specify the culture to validate that it doesn't make a difference.
    Data.dhmsn(1, 2, 3, 4, 123456789)
      ..standardPattern = TimePattern.roundtrip
      ..standardPatternCode = 'SpanPattern.roundtrip'
      ..pattern = 'o'
      ..text = '1:02:03:04.123456789'
      ..culture = TestCultures.DotTimeSeparator,
    Data.dhmsn(-1, -2, -3, -4, -123456789)
      ..standardPattern = TimePattern.roundtrip
      ..standardPatternCode = 'SpanPattern.roundtrip'
      ..pattern = 'o'
      ..text = '-1:02:03:04.123456789'
      ..culture = TestCultures.DotTimeSeparator,

  // Extremes...
  /* todo: our extremes are different (could be different based on platform?)
    new Data(Span.minValue)
      ..Pattern = '-D:hh:mm:ss.fffffffff'
      ..Text = '-16777216:00:00:00.000000000',
    new Data(Span.maxValue)
      ..Pattern = '-D:hh:mm:ss.fffffffff'
      ..Text = '16777215:23:59:59.999999999',
    new Data(Span.minValue)
      ..Pattern = '-H:mm:ss.fffffffff'
      ..Text = '-402653184:00:00.000000000',
    new Data(Span.maxValue)
      ..Pattern = '-H:mm:ss.fffffffff'
      ..Text = '402653183:59:59.999999999',
    new Data(Span.minValue)
      ..Pattern = '-M:ss.fffffffff'
      ..Text = '-24159191040:00.000000000',
    new Data(Span.maxValue)
    new Data(Span.maxValue)
      ..Pattern = '-M:ss.fffffffff'
      ..Text = '24159191039:59.999999999',
    new Data(Span.minValue)
      ..Pattern = '-S.fffffffff'
      ..Text = '-1449551462400.000000000',
    new Data(Span.maxValue)
      ..Pattern = '-S.fffffffff'
      ..Text = '1449551462399.999999999',*/
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);
  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);

  // @Test()
  // void ParseNull() => AssertParseNull(TimePattern.roundtrip);

  @Test()
  void WithCulture() {
    var pattern = TimePattern.createWithInvariantCulture('H:mm').withCulture(TestCultures.DotTimeSeparator);
    var text = pattern.format(Time(minutes: 90));
    expect('1.30', text);
  }

  @Test()
  void CreateWithCurrentCulture() {
    Culture.current = TestCultures.DotTimeSeparator;
        // using (CultureSaver.SetCultures(TestCultures.DotTimeSeparator))
        {
      var pattern = TimePattern.createWithCurrentCulture('H:mm');
      var text = pattern.format(Time(minutes: 90));
      expect('1.30', text);
    }
  }
}

/// A container for test data for formatting and parsing [Duration] objects.
/*sealed*/ class Data extends PatternTestData<Time> {
// Ignored anyway...
/*protected*/ @override Time get defaultTemplate => Time.zero;


  Data([Time value = Time.zero]) : super(value);

  Data.hm(int hours, int minutes) : this(Time(hours: hours) + Time(minutes: minutes));

  Data.hms(int hours, int minutes, int seconds)
      : this(Time(hours: hours) + Time(minutes: minutes) + Time(seconds: seconds));

  Data.dhmsn(int days, int hours, int minutes, int seconds, int nanoseconds)
      : this(Time(hours: days * 24 + hours) + Time(minutes: minutes) + Time(seconds: seconds) + Time(nanoseconds: nanoseconds));

  @internal
  @override
  IPattern<Time> CreatePattern() => TimePattern.createWithCulture(super.pattern, culture);
}

