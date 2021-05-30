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

@private final List<Culture> _allCultures = [];

Future main() async {
  await TimeMachine.initialize();
  await setup();

  await runTests();
}

Future setup() async {
  var sw = Stopwatch()..start();
  var ids = await Cultures.ids;
  for(var id in ids) {
    Culture? culture = await Cultures.getCulture(id);
    if (culture != null) _allCultures.add(culture);
  }
  print('Time to load cultures: ${sw.elapsedMilliseconds} ms;');
}

@Test()
class LocalTimePatternTest extends PatternTestBase<LocalTime> {
  List<Culture> get Cultures => _allCultures;
  @private static final DateTime SampleDateTime = DateTime(
      2000,
      1,
      1,
      21,
      13,
      34,
      123); //.AddTicks(4567);
  @private static final LocalTime SampleLocalTime = LocalTime(21, 13, 34, ns: 123 * TimeConstants.nanosecondsPerMillisecond + 4567 * 100);

// No BCL here. (also we'd need ExpectedCharacters to be a string?)
// Characters we expect to work the same in Noda Time as in the BCL.
// @private static const String ExpectedCharacters = 'hHms.:fFtT ';

  @private static final Culture AmOnlyCulture = CreateCustomAmPmCulture('am', "");
  @private static final Culture PmOnlyCulture = CreateCustomAmPmCulture('', "pm");
  @private static final Culture NoAmOrPmCulture = CreateCustomAmPmCulture('', "");

  @internal final List<Data> InvalidPatternData = [
    Data()
      ..pattern = ''
      ..message = TextErrorMessages.formatStringEmpty,
    Data()
      ..pattern = '!'
      ..message = TextErrorMessages.unknownStandardFormat
      ..parameters.addAll(['!', 'LocalTime']),
    Data()
      ..pattern = '%'
      ..message = TextErrorMessages.unknownStandardFormat
      ..parameters.addAll(['%', 'LocalTime']),
    Data()
      ..pattern = "\\"
      ..message = TextErrorMessages.unknownStandardFormat
      ..parameters.addAll(['\\', 'LocalTime']),
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
    Data()
      ..pattern = 'H%'
      ..message = TextErrorMessages.percentAtEndOfString,
    Data()
      ..pattern = 'HHH'
      ..message = TextErrorMessages.repeatCountExceeded
      ..parameters.addAll(['H', 2]),
    Data()
      ..pattern = 'mmm'
      ..message = TextErrorMessages.repeatCountExceeded
      ..parameters.addAll(['m', 2]),
    Data()
      ..pattern = 'mmmmmmmmmmmmmmmmmmm'
      ..message = TextErrorMessages.repeatCountExceeded
      ..parameters.addAll(['m', 2]),
    Data()
      ..pattern = "'qwe"
      ..message = TextErrorMessages.missingEndQuote
      ..parameters.addAll(['\'']),
    Data()
      ..pattern = "'qwe\\"
      ..message = TextErrorMessages.escapeAtEndOfString,
    Data()
      ..pattern = "'qwe\\'"
      ..message = TextErrorMessages.missingEndQuote
      ..parameters.addAll(['\'']),
    Data()
      ..pattern = 'sss'
      ..message = TextErrorMessages.repeatCountExceeded
      ..parameters.addAll(['s', 2]),
    // T isn't valid in a time pattern
    Data()
      ..pattern = '1970-01-01THH:mm:ss'
      ..message = TextErrorMessages.unquotedLiteral
      ..parameters.addAll(['T'])
  ];

  @internal List<Data> ParseFailureData = [
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
    Data()
      ..text = '5 foo'
      ..pattern = 'h t'
      ..message = TextErrorMessages.missingAmPmDesignator,
    Data()
      ..text = '04.'
      ..pattern = 'ss.FF'
      ..message = TextErrorMessages.mismatchedNumber
      ..parameters.addAll(['FF']),
    Data()
      ..text = '04.'
      ..pattern = 'ss.ff'
      ..message = TextErrorMessages.mismatchedNumber
      ..parameters.addAll(['ff']),
    Data()
      ..text = '05 Foo'
      ..pattern = 'HH tt'
      ..message = TextErrorMessages.missingAmPmDesignator
  ];

  @internal List<Data> ParseOnlyData = [
    Data.hms(0, 0, 0, 400)
      ..text = '4'
      ..pattern = '%f',
    Data.hms(0, 0, 0, 400)
      ..text = '4'
      ..pattern = '%F',
    Data.hms(0, 0, 0, 400)
      ..text = '4'
      ..pattern = 'FF',
    Data.hms(0, 0, 0, 400)
      ..text = '40'
      ..pattern = 'FF',
    Data.hms(0, 0, 0, 400)
      ..text = '4'
      ..pattern = 'FFF',
    Data.hms(0, 0, 0, 400)
      ..text = '40'
      ..pattern = 'FFF',
    Data.hms(0, 0, 0, 400)
      ..text = '400'
      ..pattern = 'FFF',
    Data.hms(0, 0, 0, 400)
      ..text = '40'
      ..pattern = 'ff',
    Data.hms(0, 0, 0, 400)
      ..text = '400'
      ..pattern = 'fff',
    Data.hms(0, 0, 0, 400)
      ..text = '4000'
      ..pattern = 'ffff',
    Data.hms(0, 0, 0, 400)
      ..text = '40000'
      ..pattern = 'fffff',
    Data.hms(0, 0, 0, 400)
      ..text = '400000'
      ..pattern = 'ffffff',
    Data.hms(0, 0, 0, 400)
      ..text = '4000000'
      ..pattern = 'fffffff',
    Data.hms(0, 0, 0, 400)
      ..text = '4'
      ..pattern = '%f',
    Data.hms(0, 0, 0, 400)
      ..text = '4'
      ..pattern = '%F',
    Data.hms(0, 0, 0, 450)
      ..text = '45'
      ..pattern = 'ff',
    Data.hms(0, 0, 0, 450)
      ..text = '45'
      ..pattern = 'FF',
    Data.hms(0, 0, 0, 450)
      ..text = '45'
      ..pattern = 'FFF',
    Data.hms(0, 0, 0, 450)
      ..text = '450'
      ..pattern = 'fff',
    Data.hms(0, 0, 0, 400)
      ..text = '4'
      ..pattern = '%f',
    Data.hms(0, 0, 0, 400)
      ..text = '4'
      ..pattern = '%F',
    Data.hms(0, 0, 0, 450)
      ..text = '45'
      ..pattern = 'ff',
    Data.hms(0, 0, 0, 450)
      ..text = '45'
      ..pattern = 'FF',
    Data.hms(0, 0, 0, 456)
      ..text = '456'
      ..pattern = 'fff',
    Data.hms(0, 0, 0, 456)
      ..text = '456'
      ..pattern = 'FFF',

    Data.hms(0, 0, 0, 0)
      ..text = '0'
      ..pattern = '%f',
    Data.hms(0, 0, 0, 0)
      ..text = '00'
      ..pattern = 'ff',
    Data.hms(0, 0, 0, 8)
      ..text = '008'
      ..pattern = 'fff',
    Data.hms(0, 0, 0, 8)
      ..text = '008'
      ..pattern = 'FFF',
    Data.hms(5, 0, 0, 0)
      ..text = '05'
      ..pattern = 'HH',
    Data.hms(0, 6, 0, 0)
      ..text = '06'
      ..pattern = 'mm',
    Data.hms(0, 0, 7, 0)
      ..text = '07'
      ..pattern = 'ss',
    Data.hms(5, 0, 0, 0)
      ..text = '5'
      ..pattern = '%H',
    Data.hms(0, 6, 0, 0)
      ..text = '6'
      ..pattern = '%m',
    Data.hms(0, 0, 7, 0)
      ..text = '7'
      ..pattern = '%s',

    // AM/PM designator is case-insensitive for both short and long forms
    Data.hms(17, 0, 0, 0)
      ..text = '5 p'
      ..pattern = 'h t',
    Data.hms(17, 0, 0, 0)
      ..text = '5 pm'
      ..pattern = 'h tt',

    // Parsing using the semi-colon 'comma dot' specifier
    Data.hms(16, 05, 20, 352)
      ..pattern = 'HH:mm:ss;fff'
      ..text = '16:05:20,352',
    Data.hms(16, 05, 20, 352)
      ..pattern = 'HH:mm:ss;FFF'
      ..text = '16:05:20,352',

    // Empty fractional section
    Data.hms(0, 0, 4, 0)
      ..text = '04'
      ..pattern = 'ssFF',
    Data.hms(0, 0, 4, 0)
      ..text = '040'
      ..pattern = 'ssFF',
    Data.hms(0, 0, 4, 0)
      ..text = '040'
      ..pattern = 'ssFFF',
    Data.hms(0, 0, 4, 0)
      ..text = '04'
      ..pattern = 'ss.FF',
  ];

  @internal List<Data> FormatOnlyData = [
    Data.hms(5, 6, 7, 8)
      ..text = ''
      ..pattern = '%F',
    Data.hms(5, 6, 7, 8)
      ..text = ''
      ..pattern = 'FF',
    Data.hms(1, 1, 1, 400)
      ..text = '4'
      ..pattern = '%f',
    Data.hms(1, 1, 1, 400)
      ..text = '4'
      ..pattern = '%F',
    Data.hms(1, 1, 1, 400)
      ..text = '4'
      ..pattern = 'FF',
    Data.hms(1, 1, 1, 400)
      ..text = '4'
      ..pattern = 'FFF',
    Data.hms(1, 1, 1, 400)
      ..text = '40'
      ..pattern = 'ff',
    Data.hms(1, 1, 1, 400)
      ..text = '400'
      ..pattern = 'fff',
    Data.hms(1, 1, 1, 400)
      ..text = '4000'
      ..pattern = 'ffff',
    Data.hms(1, 1, 1, 400)
      ..text = '40000'
      ..pattern = 'fffff',
    Data.hms(1, 1, 1, 400)
      ..text = '400000'
      ..pattern = 'ffffff',
    Data.hms(1, 1, 1, 400)
      ..text = '4000000'
      ..pattern = 'fffffff',
    Data.hms(1, 1, 1, 450)
      ..text = '4'
      ..pattern = '%f',
    Data.hms(1, 1, 1, 450)
      ..text = '4'
      ..pattern = '%F',
    Data.hms(1, 1, 1, 450)
      ..text = '45'
      ..pattern = 'ff',
    Data.hms(1, 1, 1, 450)
      ..text = '45'
      ..pattern = 'FF',
    Data.hms(1, 1, 1, 450)
      ..text = '45'
      ..pattern = 'FFF',
    Data.hms(1, 1, 1, 450)
      ..text = '450'
      ..pattern = 'fff',
    Data.hms(1, 1, 1, 456)
      ..text = '4'
      ..pattern = '%f',
    Data.hms(1, 1, 1, 456)
      ..text = '4'
      ..pattern = '%F',
    Data.hms(1, 1, 1, 456)
      ..text = '45'
      ..pattern = 'ff',
    Data.hms(1, 1, 1, 456)
      ..text = '45'
      ..pattern = 'FF',
    Data.hms(1, 1, 1, 456)
      ..text = '456'
      ..pattern = 'fff',
    Data.hms(1, 1, 1, 456)
      ..text = '456'
      ..pattern = 'FFF',
    Data.hms(0, 0, 0, 0)
      ..text = ''
      ..pattern = 'FF',

    Data.hms(5, 6, 7, 8)
      ..culture = TestCultures.EnUs
      ..text = '0'
      ..pattern = '%f',
    Data.hms(5, 6, 7, 8)
      ..culture = TestCultures.EnUs
      ..text = '00'
      ..pattern = 'ff',
    Data.hms(5, 6, 7, 8)
      ..culture = TestCultures.EnUs
      ..text = '008'
      ..pattern = 'fff',
    Data.hms(5, 6, 7, 8)
      ..culture = TestCultures.EnUs
      ..text = '008'
      ..pattern = 'FFF',
    Data.hms(5, 6, 7, 8)
      ..culture = TestCultures.EnUs
      ..text = '05'
      ..pattern = 'HH',
    Data.hms(5, 6, 7, 8)
      ..culture = TestCultures.EnUs
      ..text = '06'
      ..pattern = 'mm',
    Data.hms(5, 6, 7, 8)
      ..culture = TestCultures.EnUs
      ..text = '07'
      ..pattern = 'ss',
    Data.hms(5, 6, 7, 8)
      ..culture = TestCultures.EnUs
      ..text = '5'
      ..pattern = '%H',
    Data.hms(5, 6, 7, 8)
      ..culture = TestCultures.EnUs
      ..text = '6'
      ..pattern = '%m',
    Data.hms(5, 6, 7, 8)
      ..culture = TestCultures.EnUs
      ..text = '7'
      ..pattern = '%s',
  ];

  @internal List<Data> DefaultPatternData = [
    // Invariant culture uses HH:mm:ss for the 'long' pattern
    Data.hms(5, 0, 0, 0)
      ..text = '05:00:00',
    Data.hms(5, 12, 0, 0)
      ..text = '05:12:00',
    Data.hms(5, 12, 34, 0)
      ..text = '05:12:34',

    // US uses hh:mm:ss tt for the 'long' pattern
    Data.hms(17, 0, 0, 0)
      ..culture = TestCultures.EnUs
      ..text = '5:00:00 PM',
    Data.hms(5, 0, 0, 0)
      ..culture = TestCultures.EnUs
      ..text = '5:00:00 AM',
    Data.hms(5, 12, 0, 0)
      ..culture = TestCultures.EnUs
      ..text = '5:12:00 AM',
    Data.hms(5, 12, 34, 0)
      ..culture = TestCultures.EnUs
      ..text = '5:12:34 AM',
  ];

  @internal final List<Data> TemplateValueData = [
    // Pattern specifies nothing - template value is passed through
    Data(LocalTime(1, 2, 3, ns: 4 * TimeConstants.nanosecondsPerMillisecond + 5 * 100))
      ..culture = TestCultures.EnUs
      ..text = 'X'
      ..pattern = "'X'"
      ..template = LocalTime(1, 2, 3, ns: 4 * TimeConstants.nanosecondsPerMillisecond + 5 * 100),
    // Tests for each individual field being propagated
    Data(LocalTime(1, 6, 7, ns: 8 * TimeConstants.nanosecondsPerMillisecond + 9 * 100))
      ..culture = TestCultures.EnUs
      ..text = '06:07.0080009'
      ..pattern = 'mm:ss.FFFFFFF'
      ..template = LocalTime(1, 2, 3, ns: 4 * TimeConstants.nanosecondsPerMillisecond + 5 * 100),
    Data(LocalTime(6, 2, 7, ns: 8 * TimeConstants.nanosecondsPerMillisecond + 9 * 100))
      ..culture = TestCultures.EnUs
      ..text = '06:07.0080009'
      ..pattern = 'HH:ss.FFFFFFF'
      ..template = LocalTime(1, 2, 3, ns: 4 * TimeConstants.nanosecondsPerMillisecond + 5 * 100),
    Data(LocalTime(6, 7, 3, ns: 8 * TimeConstants.nanosecondsPerMillisecond + 9 * 100))
      ..culture = TestCultures.EnUs
      ..text = '06:07.0080009'
      ..pattern = 'HH:mm.FFFFFFF'
      ..template = LocalTime(1, 2, 3, ns: 4 * TimeConstants.nanosecondsPerMillisecond + 5 * 100),
    Data(LocalTime(6, 7, 8, ns: 4 * TimeConstants.nanosecondsPerMillisecond + 5 * 100))
      ..culture = TestCultures.EnUs
      ..text = '06:07:08'
      ..pattern = 'HH:mm:ss'
      ..template = LocalTime(1, 2, 3, ns: 4 * TimeConstants.nanosecondsPerMillisecond + 5 * 100),

    // Hours are tricky because of the ways they can be specified
    Data(LocalTime(6, 2, 3))
      ..culture = TestCultures.EnUs
      ..text = '6'
      ..pattern = '%h'
      ..template = LocalTime(1, 2, 3),
    Data(LocalTime(18, 2, 3))
      ..culture = TestCultures.EnUs
      ..text = '6'
      ..pattern = '%h'
      ..template = LocalTime(14, 2, 3),
    Data(LocalTime(2, 2, 3))
      ..culture = TestCultures.EnUs
      ..text = 'AM'
      ..pattern = 'tt'
      ..template = LocalTime(14, 2, 3),
    Data(LocalTime(14, 2, 3))
      ..culture = TestCultures.EnUs
      ..text = 'PM'
      ..pattern = 'tt'
      ..template = LocalTime(14, 2, 3),
    Data(LocalTime(2, 2, 3))
      ..culture = TestCultures.EnUs
      ..text = 'AM'
      ..pattern = 'tt'
      ..template = LocalTime(2, 2, 3),
    Data(LocalTime(14, 2, 3))
      ..culture = TestCultures.EnUs
      ..text = 'PM'
      ..pattern = 'tt'
      ..template = LocalTime(2, 2, 3),
    Data(LocalTime(17, 2, 3))
      ..culture = TestCultures.EnUs
      ..text = '5 PM'
      ..pattern = 'h tt'
      ..template = LocalTime(1, 2, 3),
  ];

  /// Common test data for both formatting and parsing. A test should be placed here unless is truly
  /// cannot be run both ways. This ensures that as many round-trip type tests are performed as possible.
  @internal final List<Data> FormatAndParseData = [
    Data(LocalTime.midnight)
      ..culture = TestCultures.EnUs
      ..text = '.'
      ..pattern = '%.',
    Data(LocalTime.midnight)
      ..culture = TestCultures.EnUs
      ..text = ':'
      ..pattern = '%:',
    Data(LocalTime.midnight)
      ..culture = TestCultures.DotTimeSeparator
      ..text = '.'
      ..pattern = '%.',
    Data(LocalTime.midnight)
      ..culture = TestCultures.DotTimeSeparator
      ..text = '.'
      ..pattern = '%:',
    Data(LocalTime.midnight)
      ..culture = TestCultures.EnUs
      ..text = 'H'
      ..pattern = "\\H",
    Data(LocalTime.midnight)
      ..culture = TestCultures.EnUs
      ..text = 'HHss'
      ..pattern = "'HHss'",
    Data.hms(0, 0, 0, 100)
      ..culture = TestCultures.EnUs
      ..text = '1'
      ..pattern = '%f',
    Data.hms(0, 0, 0, 100)
      ..culture = TestCultures.EnUs
      ..text = '1'
      ..pattern = '%F',
    Data.hms(0, 0, 0, 100)
      ..culture = TestCultures.EnUs
      ..text = '1'
      ..pattern = 'FF',
    Data.hms(0, 0, 0, 100)
      ..culture = TestCultures.EnUs
      ..text = '1'
      ..pattern = 'FFF',
    Data.hms(0, 0, 0, 100)
      ..culture = TestCultures.EnUs
      ..text = '100000000'
      ..pattern = 'fffffffff',
    Data.hms(0, 0, 0, 100)
      ..culture = TestCultures.EnUs
      ..text = '1'
      ..pattern = 'FFFFFFFFF',
    Data.hms(0, 0, 0, 120)
      ..culture = TestCultures.EnUs
      ..text = '12'
      ..pattern = 'ff',
    Data.hms(0, 0, 0, 120)
      ..culture = TestCultures.EnUs
      ..text = '12'
      ..pattern = 'FF',
    Data.hms(0, 0, 0, 120)
      ..culture = TestCultures.EnUs
      ..text = '12'
      ..pattern = 'FFF',
    Data.hms(0, 0, 0, 123)
      ..culture = TestCultures.EnUs
      ..text = '123'
      ..pattern = 'fff',
    Data.hms(0, 0, 0, 123)
      ..culture = TestCultures.EnUs
      ..text = '123'
      ..pattern = 'FFF',
    Data.hms(0, 0, 0, 123, 4000)
      ..culture = TestCultures.EnUs
      ..text = '1234'
      ..pattern = 'ffff',
    Data.hms(0, 0, 0, 123, 4000)
      ..culture = TestCultures.EnUs
      ..text = '1234'
      ..pattern = 'FFFF',
    Data.hms(0, 0, 0, 123, 4500)
      ..culture = TestCultures.EnUs
      ..text = '12345'
      ..pattern = 'fffff',
    Data.hms(0, 0, 0, 123, 4500)
      ..culture = TestCultures.EnUs
      ..text = '12345'
      ..pattern = 'FFFFF',
    Data.hms(0, 0, 0, 123, 4560)
      ..culture = TestCultures.EnUs
      ..text = '123456'
      ..pattern = 'ffffff',
    Data.hms(0, 0, 0, 123, 4560)
      ..culture = TestCultures.EnUs
      ..text = '123456'
      ..pattern = 'FFFFFF',
    Data.hms(0, 0, 0, 123, 4567)
      ..culture = TestCultures.EnUs
      ..text = '1234567'
      ..pattern = 'fffffff',
    Data.hms(0, 0, 0, 123, 4567)
      ..culture = TestCultures.EnUs
      ..text = '1234567'
      ..pattern = 'FFFFFFF',
    Data.nano(0, 0, 0, 123456780 /*L*/)
      ..culture = TestCultures.EnUs
      ..text = '12345678'
      ..pattern = 'ffffffff',
    Data.nano(0, 0, 0, 123456780 /*L*/)
      ..culture = TestCultures.EnUs
      ..text = '12345678'
      ..pattern = 'FFFFFFFF',
    Data.nano(0, 0, 0, 123456789 /*L*/)
      ..culture = TestCultures.EnUs
      ..text = '123456789'
      ..pattern = 'fffffffff',
    Data.nano(0, 0, 0, 123456789 /*L*/)
      ..culture = TestCultures.EnUs
      ..text = '123456789'
      ..pattern = 'FFFFFFFFF',
    Data.hms(0, 0, 0, 600)
      ..culture = TestCultures.EnUs
      ..text = '.6'
      ..pattern = '.f',
    Data.hms(0, 0, 0, 600)
      ..culture = TestCultures.EnUs
      ..text = '.6'
      ..pattern = '.F',
    Data.hms(0, 0, 0, 600)
      ..culture = TestCultures.EnUs
      ..text = '.6'
      ..pattern = '.FFF', // Elided fraction
    Data.hms(0, 0, 0, 678)
      ..culture = TestCultures.EnUs
      ..text = '.678'
      ..pattern = '.fff',
    Data.hms(0, 0, 0, 678)
      ..culture = TestCultures.EnUs
      ..text = '.678'
      ..pattern = '.FFF',
    Data.hms(0, 0, 12, 0)
      ..culture = TestCultures.EnUs
      ..text = '12'
      ..pattern = '%s',
    Data.hms(0, 0, 12, 0)
      ..culture = TestCultures.EnUs
      ..text = '12'
      ..pattern = 'ss',
    Data.hms(0, 0, 2, 0)
      ..culture = TestCultures.EnUs
      ..text = '2'
      ..pattern = '%s',
    Data.hms(0, 12, 0, 0)
      ..culture = TestCultures.EnUs
      ..text = '12'
      ..pattern = '%m',
    Data.hms(0, 12, 0, 0)
      ..culture = TestCultures.EnUs
      ..text = '12'
      ..pattern = 'mm',
    Data.hms(0, 2, 0, 0)
      ..culture = TestCultures.EnUs
      ..text = '2'
      ..pattern = '%m',
    Data.hms(1, 0, 0, 0)
      ..culture = TestCultures.EnUs
      ..text = '1'
      ..pattern = 'H.FFF', // Missing fraction
    Data.hms(12, 0, 0, 0)
      ..culture = TestCultures.EnUs
      ..text = '12'
      ..pattern = '%H',
    Data.hms(12, 0, 0, 0)
      ..culture = TestCultures.EnUs
      ..text = '12'
      ..pattern = 'HH',
    Data.hms(2, 0, 0, 0)
      ..culture = TestCultures.EnUs
      ..text = '2'
      ..pattern = '%H',
    Data.hms(2, 0, 0, 0)
      ..culture = TestCultures.EnUs
      ..text = '2'
      ..pattern = '%H',
    Data.hms(0, 0, 12, 340)
      ..culture = TestCultures.EnUs
      ..text = '12.34'
      ..pattern = 'ss.FFF',

    Data.hms(14, 15, 16)
      ..culture = TestCultures.EnUs
      ..text = '14:15:16'
      ..pattern = 'r',
    Data.hms(14, 15, 16, 700)
      ..culture = TestCultures.EnUs
      ..text = '14:15:16.7'
      ..pattern = 'r',
    Data.hms(14, 15, 16, 780)
      ..culture = TestCultures.EnUs
      ..text = '14:15:16.78'
      ..pattern = 'r',
    Data.hms(14, 15, 16, 789)
      ..culture = TestCultures.EnUs
      ..text = '14:15:16.789'
      ..pattern = 'r',
    Data.hms(14, 15, 16, 789, 1000)
      ..culture = TestCultures.EnUs
      ..text = '14:15:16.7891'
      ..pattern = 'r',
    Data.hms(14, 15, 16, 789, 1200)
      ..culture = TestCultures.EnUs
      ..text = '14:15:16.78912'
      ..pattern = 'r',
    Data.hms(14, 15, 16, 789, 1230)
      ..culture = TestCultures.EnUs
      ..text = '14:15:16.789123'
      ..pattern = 'r',
    Data.hms(14, 15, 16, 789, 1234)
      ..culture = TestCultures.EnUs
      ..text = '14:15:16.7891234'
      ..pattern = 'r',
    Data.hms(14, 15, 16, 700)
      ..culture = TestCultures.DotTimeSeparator
      ..text = '14.15.16.7'
      ..pattern = 'r',
    Data.hms(14, 15, 16, 780)
      ..culture = TestCultures.DotTimeSeparator
      ..text = '14.15.16.78'
      ..pattern = 'r',
    Data.hms(14, 15, 16, 789)
      ..culture = TestCultures.DotTimeSeparator
      ..text = '14.15.16.789'
      ..pattern = 'r',
    Data.hms(14, 15, 16, 789, 1000)
      ..culture = TestCultures.DotTimeSeparator
      ..text = '14.15.16.7891'
      ..pattern = 'r',
    Data.hms(14, 15, 16, 789, 1200)
      ..culture = TestCultures.DotTimeSeparator
      ..text = '14.15.16.78912'
      ..pattern = 'r',
    Data.hms(14, 15, 16, 789, 1230)
      ..culture = TestCultures.DotTimeSeparator
      ..text = '14.15.16.789123'
      ..pattern = 'r',
    Data.hms(14, 15, 16, 789, 1234)
      ..culture = TestCultures.DotTimeSeparator
      ..text = '14.15.16.7891234'
      ..pattern = 'r',
    Data.nano(14, 15, 16, 789123456 /*L*/)
      ..culture = TestCultures.DotTimeSeparator
      ..text = '14.15.16.789123456'
      ..pattern = 'r',

    // ------------ Template value tests ----------
    // Mixtures of 12 and 24 hour times
    Data.hms(18, 0, 0)
      ..culture = TestCultures.EnUs
      ..text = '18 6 PM'
      ..pattern = 'HH h tt',
    Data.hms(18, 0, 0)
      ..culture = TestCultures.EnUs
      ..text = '18 6'
      ..pattern = 'HH h',
    Data.hms(18, 0, 0)
      ..culture = TestCultures.EnUs
      ..text = '18 PM'
      ..pattern = 'HH tt',
    Data.hms(18, 0, 0)
      ..culture = TestCultures.EnUs
      ..text = '6 PM'
      ..pattern = 'h tt',
    Data.hms(6, 0, 0)
      ..culture = TestCultures.EnUs
      ..text = '6'
      ..pattern = '%h',
    Data.hms(0, 0, 0)
      ..culture = TestCultures.EnUs
      ..text = 'AM'
      ..pattern = 'tt',
    Data.hms(12, 0, 0)
      ..culture = TestCultures.EnUs
      ..text = 'PM'
      ..pattern = 'tt',
    Data.hms(0, 0, 0)
      ..culture = TestCultures.EnUs
      ..text = 'A'
      ..pattern = '%t',
    Data.hms(12, 0, 0)
      ..culture = TestCultures.EnUs
      ..text = 'P'
      ..pattern = '%t',

    // Pattern specifies nothing - template value is passed through
    Data(LocalTime(1, 2, 3, ns: 4 * TimeConstants.nanosecondsPerMillisecond + 5 * 100))
      ..culture = TestCultures.EnUs
      ..text = '*'
      ..pattern = '%*'
      ..template = LocalTime(1, 2, 3, ns: 4 * TimeConstants.nanosecondsPerMillisecond + 5 * 100),
    // Tests for each individual field being propagated
    Data(LocalTime(1, 6, 7, ns: 8 * TimeConstants.nanosecondsPerMillisecond + 9 * 100))
      ..culture = TestCultures.EnUs
      ..text = '06:07.0080009'
      ..pattern = 'mm:ss.FFFFFFF'
      ..template = LocalTime(1, 2, 3, ns: 4 * TimeConstants.nanosecondsPerMillisecond + 5 * 100),
    Data(LocalTime(6, 2, 7, ns: 8 * TimeConstants.nanosecondsPerMillisecond + 9 * 100))
      ..culture = TestCultures.EnUs
      ..text = '06:07.0080009'
      ..pattern = 'HH:ss.FFFFFFF'
      ..template = LocalTime(1, 2, 3, ns: 4 * TimeConstants.nanosecondsPerMillisecond + 5 * 100),
    Data(LocalTime(6, 7, 3, ns: 8 * TimeConstants.nanosecondsPerMillisecond + 9 * 100))
      ..culture = TestCultures.EnUs
      ..text = '06:07.0080009'
      ..pattern = 'HH:mm.FFFFFFF'
      ..template = LocalTime(1, 2, 3, ns: 4 * TimeConstants.nanosecondsPerMillisecond + 5 * 100),
    Data(LocalTime(6, 7, 3, ns: 8 * TimeConstants.nanosecondsPerMillisecond + 9 * 100))
      ..culture = TestCultures.EnUs
      ..text = '06:07.0080009'
      ..pattern = 'HH:mm.FFFFFFF'
      ..template = LocalTime(1, 2, 3, ns: 4 * TimeConstants.nanosecondsPerMillisecond + 5 * 100),
    Data(LocalTime(6, 7, 8, ns: 4 * TimeConstants.nanosecondsPerMillisecond + 5 * 100))
      ..culture = TestCultures.EnUs
      ..text = '06:07:08'
      ..pattern = 'HH:mm:ss'
      ..template = LocalTime(1, 2, 3, ns: 4 * TimeConstants.nanosecondsPerMillisecond + 5 * 100),

    // Hours are tricky because of the ways they can be specified
    Data(LocalTime(6, 2, 3))
      ..culture = TestCultures.EnUs
      ..text = '6'
      ..pattern = '%h'
      ..template = LocalTime(1, 2, 3),
    Data(LocalTime(18, 2, 3))
      ..culture = TestCultures.EnUs
      ..text = '6'
      ..pattern = '%h'
      ..template = LocalTime(14, 2, 3),
    Data(LocalTime(2, 2, 3))
      ..culture = TestCultures.EnUs
      ..text = 'AM'
      ..pattern = 'tt'
      ..template = LocalTime(14, 2, 3),
    Data(LocalTime(14, 2, 3))
      ..culture = TestCultures.EnUs
      ..text = 'PM'
      ..pattern = 'tt'
      ..template = LocalTime(14, 2, 3),
    Data(LocalTime(2, 2, 3))
      ..culture = TestCultures.EnUs
      ..text = 'AM'
      ..pattern = 'tt'
      ..template = LocalTime(2, 2, 3),
    Data(LocalTime(14, 2, 3))
      ..culture = TestCultures.EnUs
      ..text = 'PM'
      ..pattern = 'tt'
      ..template = LocalTime(2, 2, 3),
    Data(LocalTime(17, 2, 3))
      ..culture = TestCultures.EnUs
      ..text = '5 PM'
      ..pattern = 'h tt'
      ..template = LocalTime(1, 2, 3),
// --------------- end of template value tests ----------------------

    // Only one of the AM/PM designator is present. We should still be able to work out what is meant, by the presence
    // or absense of the non-empty one.
    Data.hms(5, 0, 0)
      ..culture = AmOnlyCulture
      ..text = '5 am'
      ..pattern = 'h tt',
    Data.hms(15, 0, 0)
      ..culture = AmOnlyCulture
      ..text = '3 '
      ..pattern = 'h tt'
      ..description = 'Implicit PM',
    Data.hms(5, 0, 0)
      ..culture = AmOnlyCulture
      ..text = '5 a'
      ..pattern = 'h t',
    Data.hms(15, 0, 0)
      ..culture = AmOnlyCulture
      ..text = '3 '
      ..pattern = 'h t'
      ..description = 'Implicit PM',

    Data.hms(5, 0, 0)
      ..culture = PmOnlyCulture
      ..text = '5 '
      ..pattern = 'h tt',
    Data.hms(15, 0, 0)
      ..culture = PmOnlyCulture
      ..text = '3 pm'
      ..pattern = 'h tt',
    Data.hms(5, 0, 0)
      ..culture = PmOnlyCulture
      ..text = '5 '
      ..pattern = 'h t',
    Data.hms(15, 0, 0)
      ..culture = PmOnlyCulture
      ..text = '3 p'
      ..pattern = 'h t',

    // AM / PM designators are both empty strings. The parsing side relies on the AM/PM value being correct on the
    // template value. (The template value is for the wrong actual hour, but in the right side of noon.)
    Data.hms(5, 0, 0)
      ..culture = NoAmOrPmCulture
      ..text = '5 '
      ..pattern = 'h tt'
      ..template = LocalTime(2, 0, 0),
    Data.hms(15, 0, 0)
      ..culture = NoAmOrPmCulture
      ..text = '3 '
      ..pattern = 'h tt'
      ..template = LocalTime(14, 0, 0),
    Data.hms(5, 0, 0)
      ..culture = NoAmOrPmCulture
      ..text = '5 '
      ..pattern = 'h t'
      ..template = LocalTime(2, 0, 0),
    Data.hms(15, 0, 0)
      ..culture = NoAmOrPmCulture
      ..text = '3 '
      ..pattern = 'h t'
      ..template = LocalTime(14, 0, 0),

    // Use of the semi-colon 'comma dot' specifier
    Data.hms(16, 05, 20, 352)
      ..pattern = 'HH:mm:ss;fff'
      ..text = '16:05:20.352',
    Data.hms(16, 05, 20, 352)
      ..pattern = 'HH:mm:ss;FFF'
      ..text = '16:05:20.352',
    Data.hms(16, 05, 20, 352)
      ..pattern = "HH:mm:ss;FFF 'end'"
      ..text = '16:05:20.352 end',
    Data.hms(16, 05, 20)
      ..pattern = "HH:mm:ss;FFF 'end'"
      ..text = '16:05:20 end',

    // Patterns obtainable by properties but not single character standard patterns
    Data.nano(1, 2, 3, 123456700 /*L*/)
      ..standardPattern = LocalTimePattern.extendedIso
      ..standardPatternCode = 'LocalTimePattern.extendedIso'
      ..culture = TestCultures.EnUs
      ..text = '01:02:03.1234567'
      ..pattern = "HH':'mm':'ss;FFFFFFF",
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);

  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);

  @private static Culture CreateCustomAmPmCulture(String amDesignator, String pmDesignator) {
    return Culture('ampmDesignators'/*Culture.invariantCultureId*/, (
        DateTimeFormatBuilder.invariant()
          ..amDesignator = amDesignator
          ..pmDesignator = pmDesignator).Build());
  }

  // @Test()
  // void ParseNull() => AssertParseNull(LocalTimePattern.extendedIso);

  /*
  @Test()
  @TestCaseSource(#Cultures, 'AllCultures')
  void BclLongTimePatternIsValidNodaPattern(Culture culture) {
    if (culture == null) {
      return;
    }
    AssertValidNodaPattern(culture, culture.dateTimeFormat.longTimePattern);
  }

  @Test()
  @TestCaseSource(#Cultures, 'AllCultures')
  void BclShortTimePatternIsValidNodaPattern(Culture culture) {
    AssertValidNodaPattern(culture, culture.dateTimeFormat.shortTimePattern);
  }*/

/*
@Test()
@TestCaseSource(#Cultures, 'AllCultures')
void BclLongTimePatternGivesSameResultsInNoda(Culture culture)
{
AssertBclNodaEquality(culture, culture.DateTimeFormat.LongTimePattern);
}

@Test()
@TestCaseSource(#Cultures, 'AllCultures')
void BclShortTimePatternGivesSameResultsInNoda(Culture culture)
{
AssertBclNodaEquality(culture, culture.DateTimeFormat.ShortTimePattern);
}*/

  // @Test()
  // void CreateWithInvariantCulture_NullPatternText() {
  //   expect(() => LocalTimePattern.createWithInvariantCulture(null), throwsArgumentError);
  // }

  // @Test()
  // void Create_NullFormatInfo() {
  //   expect(() => LocalTimePattern.createWithCulture('HH', null), throwsArgumentError);
  // }

  @Test()
  void TemplateValue_DefaultsToMidnight() {
    var pattern = LocalTimePattern.createWithInvariantCulture('HH');
    expect(LocalTime.midnight, pattern.templateValue);
  }

  @Test()
  void CreateWithCurrentCulture() {
    // using (CultureSaver.SetCultures(TestCultures.DotTimeSeparator))
    Culture.current = TestCultures.DotTimeSeparator;
    {
      var pattern = LocalTimePattern.createWithCurrentCulture('HH:mm');
      var text = pattern.format(LocalTime(13, 45, 0));
      expect('13.45', text);
    }
  }

  @Test()
  void WithTemplateValue_PropertyFetch() {
    LocalTime newValue = LocalTime(1, 23, 45);
    var pattern = LocalTimePattern.createWithInvariantCulture('HH').withTemplateValue(newValue);
    expect(newValue, pattern.templateValue);
  }

/*
@private void AssertBclNodaEquality(Culture culture, String patternText)
{
// On Mono, some general patterns include an offset at the end.
// https://github.com/nodatime/nodatime/issues/98
// For the moment, ignore them.
// TODO(V1.2): Work out what to do in such cases...
if (patternText.endsWith('z'))
{
return;
}
var pattern = LocalTimePattern.Create3(patternText, culture);

expect(SampleDateTime.toString(patternText, culture), pattern.Format(SampleLocalTime));
}*/

/*
  @private static void AssertValidNodaPattern(Culture culture, String pattern) {
    PatternCursor cursor = new PatternCursor(pattern);
    while (cursor.MoveNext()) {
      if (cursor.Current == '\'') {
        cursor.GetQuotedString('\'');
      }
      else {
        // We'll never do anything "special" with non-ascii characters anyway,
        // so we don't mind if they're not quoted.
        if (cursor.Current.codeUnitAt(0) < 0x80) {
          expect(ExpectedCharacters.contains(cursor.Current),
              "Pattern '" + pattern + "' contains unquoted, unexpected characters");
        }
      }
    }
    // Check that the pattern parses
    LocalTimePattern.Create3(pattern, culture);
  }*/
}

/// A container for test data for formatting and parsing [LocalTime] objects.
/*sealed*/ class Data extends PatternTestData<LocalTime>
{
  // Default to midnight
  /*protected*/ @override LocalTime get defaultTemplate => LocalTime.midnight;

  Data([LocalTime? value]) : super(value ?? LocalTime.midnight);

  Data.hms(int hours, int minutes, int seconds, [int milliseconds = 0, int ticksWithinMillisecond = 0])
      : super(LocalTime(hours, minutes, seconds, ns: milliseconds * TimeConstants.nanosecondsPerMillisecond + ticksWithinMillisecond * 100));

  Data.nano(int hours, int minutes, int seconds, int /*long*/ nanoOfSecond)
      : super(LocalTime(hours, minutes, seconds).addNanoseconds(nanoOfSecond));


  @internal @override IPattern<LocalTime> CreatePattern() =>
  LocalTimePattern.createWithInvariantCulture(super.pattern)
      .withTemplateValue(template)
      .withCulture(culture);
}

