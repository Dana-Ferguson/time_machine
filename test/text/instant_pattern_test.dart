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
class InstantPatternTest extends PatternTestBase<Instant> {
  @internal final List<Data> InvalidPatternData = [
    Data()
      ..pattern = ''
      ..message = TextErrorMessages.formatStringEmpty,
    Data()
      ..pattern = '!'
      ..message = TextErrorMessages.unknownStandardFormat
      ..parameters.addAll(['!', 'Instant']),
    Data()
      ..pattern = '%'
      ..message = TextErrorMessages.unknownStandardFormat
      ..parameters.addAll(['%', 'Instant']),
    Data()
      ..pattern = "\\"
      ..message = TextErrorMessages.unknownStandardFormat
      ..parameters.addAll(['\\', 'Instant']),
    // Just a few - these are taken from other tests
    Data()
      ..pattern = '%%'
      ..message = TextErrorMessages.percentDoubled,
    Data()
      ..pattern = "%\\"
      ..message = TextErrorMessages.escapeAtEndOfString,
    Data()
      ..pattern = 'ffffffffff'
      ..message = TextErrorMessages.repeatCountExceeded
      ..parameters.addAll(['f', 9]),
    Data()
      ..pattern = 'FFFFFFFFFF'
      ..message = TextErrorMessages.repeatCountExceeded
      ..parameters.addAll(['F', 9]),
  ];

  @internal List<Data> ParseFailureData = [
    Data()
      ..text = 'rubbish'
      ..pattern = "yyyyMMdd'T'HH:mm:ss"
      ..message = TextErrorMessages.mismatchedNumber
      ..parameters.addAll(['yyyy']),
    Data()
      ..text = '17 6'
      ..pattern = 'HH h'
      ..message = TextErrorMessages.inconsistentValues2
      ..parameters.addAll(['H', 'h', 'LocalTime']),
    Data()
      ..text = '17 AM'
      ..pattern = 'HH tt'
      ..message = TextErrorMessages.inconsistentValues2
      ..parameters.addAll(['H', 't', 'LocalTime']),
  ];

  @internal List<Data> ParseOnlyData = [];

  @internal List<Data> FormatOnlyData = [];

  @Test()
  void IsoHandlesCommas() {
    Instant expected = Instant.utc(2012, 1, 1, 0, 0) + Time.epsilon;
    Instant actual = InstantPattern.extendedIso
        .parse('2012-01-01T00:00:00,000000001Z')
        .value;
    expect(expected, actual);
  }

  @Test()
  void CreateWithCurrentCulture() {
    // using (CultureSaver.SetCultures(TestCultures.DotTimeSeparator))
    Culture.current = TestCultures.DotTimeSeparator;
    {
      var pattern = InstantPattern.createWithCurrentCulture('HH:mm:ss');
      var text = pattern.format(Instant.utc(2000, 1, 1, 12, 34, 56));
      expect('12.34.56', text);
    }
  }

  @Test()
  void Create() {
    var pattern = InstantPattern.createWithCulture('HH:mm:ss', TestCultures.DotTimeSeparator);
    var text = pattern.format(Instant.utc(2000, 1, 1, 12, 34, 56));
    expect('12.34.56', text);
  }

  // @Test()
  // void ParseNull() => AssertParseNull(InstantPattern.general);

  /// Common test data for both formatting and parsing. A test should be placed here unless is truly
  /// cannot be run both ways. This ensures that as many round-trip type tests are performed as possible.
  @internal final List<Data> FormatAndParseData = [
    Data.fromUtc(2012, 1, 31, 17, 36, 45)
      ..text = '2012-01-31T17:36:45'
      ..pattern = "yyyy-MM-dd'T'HH:mm:ss",
    // Check that unquoted T still works.
    Data.fromUtc(2012, 1, 31, 17, 36, 45)
      .. text = '2012-01-31T17:36:45'
      ..pattern = 'yyyy-MM-ddTHH:mm:ss',
    Data.fromUtc(2012, 4, 28, 0, 0, 0)
      .. text = '2012 avr. 28'
      ..pattern = 'yyyy MMM dd'
      ..culture = TestCultures.FrFr,
    Data()
      ..text = ' 1970 '
      ..pattern = ' yyyy ',
    Data(Instant.minValue)
      ..text = '-9998-01-01T00:00:00Z'
      ..pattern = "uuuu-MM-dd'T'HH:mm:ss.FFFFFFFFF'Z'",
    Data(Instant.maxValue)
      ..text = '9999-12-31T23:59:59.999999999Z'
      ..pattern = "uuuu-MM-dd'T'HH:mm:ss.FFFFFFFFF'Z'",

    // General pattern has no standard single character.
    Data.fromUtc(2012, 1, 31, 17, 36, 45)
      ..standardPattern = InstantPattern.general
      ..standardPatternCode = 'InstantPattern.general'
      ..text = '2012-01-31T17:36:45Z'
      ..pattern = "uuuu-MM-ddTHH:mm:ss'Z'",
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);

  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);
}

/// A container for test data for formatting and parsing [LocalTime] objects.
/*sealed*/ class Data extends PatternTestData<Instant> {
/*protected*/ @override Instant get defaultTemplate => TimeConstants.unixEpoch;

  Data([Instant? value]) : super(value ?? TimeConstants.unixEpoch) {
    text = '';
  }

  Data.fromUtc(int year, int month, int day, int hour, int minute, int second)
      : this(Instant.utc(year, month, day, hour, minute, second));

  @internal
  @override
  IPattern<Instant> CreatePattern() =>
      InstantPattern.createWithInvariantCulture(super.pattern).withCulture(culture);
}

