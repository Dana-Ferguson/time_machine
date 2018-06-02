// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/Text/SpanPatternTest.cs
// e81483f  on Sep 15, 2017

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
class SpanPatternTest extends PatternTestBase<Span> {
  /// <summary>
  /// Test data that can only be used to test formatting.
  /// </summary>
  @internal  final List<Data> FormatOnlyData = [
// No sign, so we can't parse it.
    new Data.hm(-1, 0)
      ..Pattern = "HH:mm"
      ..Text = "01:00",

// Loss of nano precision
    new Data.dhmsn(1, 2, 3, 4, 123456789)
      ..Pattern = "D:hh:mm:ss.ffff"
      ..Text = "1:02:03:04.1234",
    new Data.dhmsn(1, 2, 3, 4, 123456789)
      ..Pattern = "D:hh:mm:ss.FFFF"
      ..Text = "1:02:03:04.1234",
  ];

  /// <summary>
  /// Test data that can only be used to test successful parsing.
  /// </summary>
  @internal  final List<Data> ParseOnlyData = [];

  /// <summary>
  /// Test data for invalid patterns
  /// </summary>
  @internal  final List<Data> InvalidPatternData = [
    new Data()
      ..Pattern = ""
      ..Message = TextErrorMessages.FormatStringEmpty,
    new Data()
      ..Pattern = "HH:MM"
      ..Message = TextErrorMessages.MultipleCapitalSpanFields,
    new Data()
      ..Pattern = "HH D"
      ..Message = TextErrorMessages.MultipleCapitalSpanFields,
    new Data()
      ..Pattern = "MM mm"
      ..Message = TextErrorMessages.RepeatedFieldInPattern
      ..Parameters.addAll(['m']),
    new Data()
      ..Pattern = "G"
      ..Message = TextErrorMessages.UnknownStandardFormat
      ..Parameters.addAll(['G', 'Span'])
  ];

  /// <summary>
  /// Tests for parsing failures (of values)
  /// </summary>
  @internal  final List<Data> ParseFailureData = [
    new Data(Span.zero)
      ..Pattern = "H:mm"
      ..Text = "1:60"
      ..Message = TextErrorMessages.FieldValueOutOfRange
      ..Parameters.addAll([60, 'm', 'Span']),
// Total field values out of range
    new Data(Span.minValue)
      ..Pattern = "-D:hh:mm:ss.fffffffff"
      ..Text = "16777217:00:00:00.000000000"
      ..
      Message = TextErrorMessages.FieldValueOutOfRange
      ..Parameters.addAll(["16777217", 'D', 'Span']),
    new Data(Span.minValue)
      ..Pattern = "-H:mm:ss.fffffffff"
      ..Text = "402653185:00:00.000000000"
      ..
      Message = TextErrorMessages.FieldValueOutOfRange
      ..Parameters.addAll(["402653185", 'H', 'Span']),
    new Data(Span.minValue)
      ..Pattern = "-M:ss.fffffffff"
      ..Text = "24159191041:00.000000000"
      ..
      Message = TextErrorMessages.FieldValueOutOfRange
      ..Parameters.addAll(["24159191041", 'M', 'Span']),
    new Data(Span.minValue)
      ..Pattern = "-S.fffffffff"
      ..Text = "1449551462401.000000000"
      ..
      Message = TextErrorMessages.FieldValueOutOfRange
      ..Parameters.addAll(["1449551462401", 'S', 'Span']),

// Each field in range, but overall result out of range
    new Data(Span.minValue)
      ..Pattern = "-D:hh:mm:ss.fffffffff"
      ..Text = "-16777216:00:00:00.000000001"
      ..
      Message = TextErrorMessages.OverallValueOutOfRange
      ..Parameters.addAll(['Span']),
    new Data(Span.maxValue)
      ..Pattern = "-D:hh:mm:ss.fffffffff"
      ..Text = "16777216:00:00:00.000000000"
      ..
      Message = TextErrorMessages.OverallValueOutOfRange
      ..Parameters.addAll(['Span']),
    new Data(Span.minValue)
      ..Pattern = "-H:mm:ss.fffffffff"
      ..Text = "-402653184:00:00.000000001"
      ..
      Message = TextErrorMessages.OverallValueOutOfRange
      ..Parameters.addAll(['Span']),
    new Data(Span.minValue)
      ..Pattern = "-H:mm:ss.fffffffff"
      ..Text = "402653184:00:00.000000000"
      ..
      Message = TextErrorMessages.OverallValueOutOfRange
      ..Parameters.addAll(['Span']),
    new Data(Span.minValue)
      ..Pattern = "-M:ss.fffffffff"
      ..Text = "-24159191040:00.000000001"
      ..
      Message = TextErrorMessages.OverallValueOutOfRange
      ..Parameters.addAll(['Span']),
    new Data(Span.minValue)
      ..Pattern = "-M:ss.fffffffff"
      ..Text = "24159191040:00.000000000"
      ..
      Message = TextErrorMessages.OverallValueOutOfRange
      ..Parameters.addAll(['Span']),
    new Data(Span.minValue)
      ..Pattern = "-S.fffffffff"
      ..Text = "-1449551462400.000000001"
      ..
      Message = TextErrorMessages.OverallValueOutOfRange
      ..Parameters.addAll(['Span']),
    new Data(Span.minValue)
      ..Pattern = "-S.fffffffff"
      ..Text = "1449551462400.000000000"
      ..
      Message = TextErrorMessages.OverallValueOutOfRange
      ..Parameters.addAll(['Span']),
    new Data(Span.minValue)
      ..Pattern = "'x'S"
      ..Text = "x"
      ..Message = TextErrorMessages.MismatchedNumber
      ..Parameters.addAll(["S"])
  ];

  /// <summary>
  /// Common test data for both formatting and parsing. A test should be placed here unless is truly
  /// cannot be run both ways. This ensures that as many round-trip type tests are performed as possible.
  /// </summary>
  @internal  final List<Data> FormatAndParseData = [
    new Data.hm(1, 2)
      ..Pattern = "+HH:mm"
      ..Text = "+01:02",
    new Data.hm(-1, -2)
      ..Pattern = "+HH:mm"
      ..Text = "-01:02",
    new Data.hm(1, 2)
      ..Pattern = "-HH:mm"
      ..Text = "01:02",
    new Data.hm(-1, -2)
      ..Pattern = "-HH:mm"
      ..Text = "-01:02",

    new Data.hm(26, 3)
      ..Pattern = "D:h:m"
      ..Text = "1:2:3",
    new Data.hm(26, 3)
      ..Pattern = "DD:hh:mm"
      ..Text = "01:02:03",
    new Data.hm(242, 3)
      ..Pattern = "D:hh:mm"
      ..Text = "10:02:03",

    new Data.hm(2, 3)
      ..Pattern = "H:mm"
      ..Text = "2:03",
    new Data.hm(2, 3)
      ..Pattern = "HH:mm"
      ..Text = "02:03",
    new Data.hm(26, 3)
      ..Pattern = "HH:mm"
      ..Text = "26:03",
    new Data.hm(260, 3)
      ..Pattern = "HH:mm"
      ..Text = "260:03",

    new Data.hms(2, 3, 4)
      ..Pattern = "H:mm:ss"
      ..Text = "2:03:04",

    new Data.dhmsn(1, 2, 3, 4, 123456789)
      ..Pattern = "D:hh:mm:ss.fffffffff"
      ..Text = "1:02:03:04.123456789",
    new Data.dhmsn(1, 2, 3, 4, 123456000)
      ..Pattern = "D:hh:mm:ss.fffffffff"
      ..Text = "1:02:03:04.123456000",
    new Data.dhmsn(1, 2, 3, 4, 123456789)
      ..Pattern = "D:hh:mm:ss.FFFFFFFFF"
      ..Text = "1:02:03:04.123456789",
    new Data.dhmsn(1, 2, 3, 4, 123456000)
      ..Pattern = "D:hh:mm:ss.FFFFFFFFF"
      ..Text = "1:02:03:04.123456",
    new Data.hms(1, 2, 3)
      ..Pattern = "M:ss"
      ..Text = "62:03",
    new Data.hms(1, 2, 3)
      ..Pattern = "MMM:ss"
      ..Text = "062:03",

    new Data.dhmsn(0, 0, 1, 2, 123400000)
      ..Pattern = "SS.FFFF"
      ..Text = "62.1234",

    new Data.dhmsn(1, 2, 3, 4, 123456789)
      ..Pattern = "D:hh:mm:ss.FFFFFFFFF"
      ..Text = "1.02.03.04.123456789"
      ..Culture = TestCultures.DotTimeSeparator,

// Roundtrip pattern is invariant; redundantly specify the culture to validate that it doesn't make a difference.
    new Data.dhmsn(1, 2, 3, 4, 123456789)
      ..StandardPattern = SpanPattern.Roundtrip
      ..Pattern = "o"
      ..Text = "1:02:03:04.123456789"
      ..Culture = TestCultures.DotTimeSeparator,
    new Data.dhmsn(-1, -2, -3, -4, -123456789)
      ..StandardPattern = SpanPattern.Roundtrip
      ..Pattern = "o"
      ..Text = "-1:02:03:04.123456789"
      ..Culture = TestCultures.DotTimeSeparator,

// Extremes...
    new Data(Span.minValue)
      ..Pattern = "-D:hh:mm:ss.fffffffff"
      ..Text = "-16777216:00:00:00.000000000",
    new Data(Span.maxValue)
      ..Pattern = "-D:hh:mm:ss.fffffffff"
      ..Text = "16777215:23:59:59.999999999",
    new Data(Span.minValue)
      ..Pattern = "-H:mm:ss.fffffffff"
      ..Text = "-402653184:00:00.000000000",
    new Data(Span.maxValue)
      ..Pattern = "-H:mm:ss.fffffffff"
      ..Text = "402653183:59:59.999999999",
    new Data(Span.minValue)
      ..Pattern = "-M:ss.fffffffff"
      ..Text = "-24159191040:00.000000000",
    new Data(Span.maxValue)
      ..Pattern = "-M:ss.fffffffff"
      ..Text = "24159191039:59.999999999",
    new Data(Span.minValue)
      ..Pattern = "-S.fffffffff"
      ..Text = "-1449551462400.000000000",
    new Data(Span.maxValue)
      ..Pattern = "-S.fffffffff"
      ..Text = "1449551462399.999999999",
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);
  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);

  @Test()
  void ParseNull() => AssertParseNull(SpanPattern.Roundtrip);

  @Test()
  void WithCulture() {
    var pattern = SpanPattern.CreateWithInvariantCulture("H:mm").WithCulture(TestCultures.DotTimeSeparator);
    var text = pattern.Format(new Span(minutes: 90));
    expect("1.30", text);
  }

  @Test()
  void CreateWithCurrentCulture() {
    CultureInfo.currentCulture = TestCultures.DotTimeSeparator;
    // using (CultureSaver.SetCultures(TestCultures.DotTimeSeparator))
        {
      var pattern = SpanPattern.CreateWithCurrentCulture("H:mm");
      var text = pattern.Format(new Span(minutes: 90));
      expect("1.30", text);
    }
  }
}

/// <summary>
/// A container for test data for formatting and parsing <see cref="Duration" /> objects.
/// </summary>
/*sealed*/ class Data extends PatternTestData<Span> {
// Ignored anyway...
/*protected*/ @override Span get DefaultTemplate => Span.zero;


  Data([Span value = Span.zero]) : super(value);

  Data.hm(int hours, int minutes) : this(new Span(hours: hours) + new Span(minutes: minutes));

  Data.hms(int hours, int minutes, int seconds)
      : this(new Span(hours: hours) + new Span(minutes: minutes) + new Span(seconds: seconds));

  Data.dhmsn(int days, int hours, int minutes, int seconds, int nanoseconds)
      : this(new Span(hours: days * 24 + hours) + new Span(minutes: minutes) + new Span(seconds: seconds) + new Span(nanoseconds: nanoseconds));

  @internal
  @override
  IPattern<Span> CreatePattern() => SpanPattern.Create2(super.Pattern, Culture);
}
