// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';
import 'dart:math' as math;
import 'dart:mirrors';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';
import 'package:time_machine/src/text/patterns/time_machine_patterns.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

import '../time_machine_testing.dart';
import 'pattern_test_base.dart';
import 'pattern_test_data.dart';
import 'test_cultures.dart';
import 'text_cursor_test_base_tests.dart';

Future main() async {
  await runTests();
}

@Test()
class InstantPatternTest extends PatternTestBase<Instant> {
  @internal final List<Data> InvalidPatternData = [
    new Data()
      ..Pattern = ""
      ..Message = TextErrorMessages.formatStringEmpty,
    new Data()
      ..Pattern = "!"
      ..Message = TextErrorMessages.unknownStandardFormat
      ..Parameters.addAll(['!', 'Instant']),
    new Data()
      ..Pattern = "%"
      ..Message = TextErrorMessages.unknownStandardFormat
      ..Parameters.addAll(['%', 'Instant']),
    new Data()
      ..Pattern = "\\"
      ..Message = TextErrorMessages.unknownStandardFormat
      ..Parameters.addAll(['\\', 'Instant']),
    // Just a few - these are taken from other tests
    new Data()
      ..Pattern = "%%"
      ..Message = TextErrorMessages.percentDoubled,
    new Data()
      ..Pattern = "%\\"
      ..Message = TextErrorMessages.escapeAtEndOfString,
    new Data()
      ..Pattern = "ffffffffff"
      ..Message = TextErrorMessages.repeatCountExceeded
      ..Parameters.addAll(['f', 9]),
    new Data()
      ..Pattern = "FFFFFFFFFF"
      ..Message = TextErrorMessages.repeatCountExceeded
      ..Parameters.addAll(['F', 9]),
  ];

  @internal List<Data> ParseFailureData = [
    new Data()
      ..text = "rubbish"
      .. Pattern = "yyyyMMdd'T'HH:mm:ss"
      ..Message = TextErrorMessages.mismatchedNumber
      ..Parameters.addAll(["yyyy"]),
    new Data()
      ..text = "17 6"
      .. Pattern = "HH h"
      ..Message = TextErrorMessages.inconsistentValues2
      ..Parameters.addAll(['H', 'h', 'LocalTime']),
    new Data()
      ..text = "17 AM"
      .. Pattern = "HH tt"
      ..Message = TextErrorMessages.inconsistentValues2
      ..Parameters.addAll(['H', 't', 'LocalTime']),
  ];

  @internal List<Data> ParseOnlyData = [];

  @internal List<Data> FormatOnlyData = [];

  @Test()
  void IsoHandlesCommas() {
    Instant expected = new Instant.fromUtc(2012, 1, 1, 0, 0) + Span.epsilon;
    Instant actual = InstantPattern.extendedIso
        .parse("2012-01-01T00:00:00,000000001Z")
        .value;
    expect(expected, actual);
  }

  @Test()
  void CreateWithCurrentCulture() {
    // using (CultureSaver.SetCultures(TestCultures.DotTimeSeparator))
    CultureInfo.currentCulture = TestCultures.DotTimeSeparator;
    {
      var pattern = InstantPattern.createWithCurrentCulture("HH:mm:ss");
      var text = pattern.format(new Instant.fromUtc(2000, 1, 1, 12, 34, 56));
      expect("12.34.56", text);
    }
  }

  @Test()
  void Create() {
    var pattern = InstantPattern.createWithCulture("HH:mm:ss", TestCultures.DotTimeSeparator);
    var text = pattern.format(new Instant.fromUtc(2000, 1, 1, 12, 34, 56));
    expect("12.34.56", text);
  }

  @Test()
  void ParseNull() => AssertParseNull(InstantPattern.general);

  /// Common test data for both formatting and parsing. A test should be placed here unless is truly
  /// cannot be run both ways. This ensures that as many round-trip type tests are performed as possible.
  @internal final List<Data> FormatAndParseData = [
    new Data.fromUtc(2012, 1, 31, 17, 36, 45)
      ..text = "2012-01-31T17:36:45"
      ..Pattern = "yyyy-MM-dd'T'HH:mm:ss",
    // Check that unquoted T still works.
    new Data.fromUtc(2012, 1, 31, 17, 36, 45)
      .. text = "2012-01-31T17:36:45"
      ..Pattern = "yyyy-MM-ddTHH:mm:ss",
    new Data.fromUtc(2012, 4, 28, 0, 0, 0)
      .. text = "2012 avr. 28"
      ..Pattern = "yyyy MMM dd"
      ..Culture = TestCultures.FrFr,
    new Data()
      ..text = " 1970 "
      ..Pattern = " yyyy ",
    new Data(Instant.minValue)
      ..text = "-9998-01-01T00:00:00Z"
      ..Pattern = "uuuu-MM-dd'T'HH:mm:ss.FFFFFFFFF'Z'",
    new Data(Instant.maxValue)
      ..text = "9999-12-31T23:59:59.999999999Z"
      ..Pattern = "uuuu-MM-dd'T'HH:mm:ss.FFFFFFFFF'Z'",

    // General pattern has no standard single character.
    new Data.fromUtc(2012, 1, 31, 17, 36, 45)
      ..StandardPattern = InstantPattern.general
      ..text = "2012-01-31T17:36:45Z"
      ..Pattern = "uuuu-MM-ddTHH:mm:ss'Z'",
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);

  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);
}

/// A container for test data for formatting and parsing [LocalTime] objects.
/*sealed*/ class Data extends PatternTestData<Instant> {
/*protected*/ @override Instant get DefaultTemplate => TimeConstants.unixEpoch;

  Data([Instant value = null]) : super(value ?? TimeConstants.unixEpoch);

  Data.fromUtc(int year, int month, int day, int hour, int minute, int second)
      : this(new Instant.fromUtc(year, month, day, hour, minute, second));

  @internal
  @override
  IPattern<Instant> CreatePattern() =>
      InstantPattern.createWithInvariantCulture(super.Pattern).withCulture(Culture);
}

