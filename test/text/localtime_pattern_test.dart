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

@private final List<CultureInfo> _allCultures = [];

Future main() async {
  var sw = new Stopwatch()..start();
  var ids = await Cultures.ids;
  for(var id in ids) {
    _allCultures.add(await Cultures.getCulture(id));
  }
  print('Time to load cultures: ${sw.elapsedMilliseconds} ms;');

  await runTests();
}

@Test()
class LocalTimePatternTest extends PatternTestBase<LocalTime> {
  List<CultureInfo> get Cultures => _allCultures;
  @private static final DateTime SampleDateTime = new DateTime(
      2000,
      1,
      1,
      21,
      13,
      34,
      123); //.AddTicks(4567);
  @private static final LocalTime SampleLocalTime = new LocalTime.fromHourMinuteSecondMillisecondTick(21, 13, 34, 123, 4567);

// No BCL here. (also we'd need ExpectedCharacters to be a string?)
// Characters we expect to work the same in Noda Time as in the BCL.
// @private static const String ExpectedCharacters = "hHms.:fFtT ";

  @private static final CultureInfo AmOnlyCulture = CreateCustomAmPmCulture("am", "");
  @private static final CultureInfo PmOnlyCulture = CreateCustomAmPmCulture("", "pm");
  @private static final CultureInfo NoAmOrPmCulture = CreateCustomAmPmCulture("", "");

  @internal final List<Data> InvalidPatternData = [
    new Data()
      ..Pattern = ""
      ..Message = TextErrorMessages.formatStringEmpty,
    new Data()
      ..Pattern = "!"
      ..Message = TextErrorMessages.unknownStandardFormat
      ..Parameters.addAll(['!', 'LocalTime']),
    new Data()
      ..Pattern = "%"
      ..Message = TextErrorMessages.unknownStandardFormat
      ..Parameters.addAll(['%', 'LocalTime']),
    new Data()
      ..Pattern = "\\"
      ..Message = TextErrorMessages.unknownStandardFormat
      ..Parameters.addAll(['\\', 'LocalTime']),
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
    new Data()
      ..Pattern = "H%"
      ..Message = TextErrorMessages.percentAtEndOfString,
    new Data()
      ..Pattern = "HHH"
      ..Message = TextErrorMessages.repeatCountExceeded
      ..Parameters.addAll(['H', 2]),
    new Data()
      ..Pattern = "mmm"
      ..Message = TextErrorMessages.repeatCountExceeded
      ..Parameters.addAll(['m', 2]),
    new Data()
      ..Pattern = "mmmmmmmmmmmmmmmmmmm"
      ..Message = TextErrorMessages.repeatCountExceeded
      ..Parameters.addAll(['m', 2]),
    new Data()
      ..Pattern = "'qwe"
      ..Message = TextErrorMessages.missingEndQuote
      ..Parameters.addAll(['\'']),
    new Data()
      ..Pattern = "'qwe\\"
      ..Message = TextErrorMessages.escapeAtEndOfString,
    new Data()
      ..Pattern = "'qwe\\'"
      ..Message = TextErrorMessages.missingEndQuote
      ..Parameters.addAll(['\'']),
    new Data()
      ..Pattern = "sss"
      ..Message = TextErrorMessages.repeatCountExceeded
      ..Parameters.addAll(['s', 2]),
    // T isn't valid in a time pattern
    new Data()
      ..Pattern = "1970-01-01THH:mm:ss"
      ..Message = TextErrorMessages.unquotedLiteral
      ..Parameters.addAll(['T'])
  ];

  @internal List<Data> ParseFailureData = [
    new Data()
      ..Text = "17 6"
      ..Pattern = "HH h"
      ..Message = TextErrorMessages.inconsistentValues2
      ..Parameters.addAll(['H', 'h', 'LocalTime']),
    new Data()
      ..Text = "17 AM"
      ..Pattern = "HH tt"
      ..Message = TextErrorMessages.inconsistentValues2
      ..Parameters.addAll(['H', 't', 'LocalTime']),
    new Data()
      ..Text = "5 foo"
      ..Pattern = "h t"
      ..Message = TextErrorMessages.missingAmPmDesignator,
    new Data()
      ..Text = "04."
      ..Pattern = "ss.FF"
      ..Message = TextErrorMessages.mismatchedNumber
      ..Parameters.addAll(["FF"]),
    new Data()
      ..Text = "04."
      ..Pattern = "ss.ff"
      ..Message = TextErrorMessages.mismatchedNumber
      ..Parameters.addAll(["ff"]),
    new Data()
      ..Text = "05 Foo"
      ..Pattern = "HH tt"
      ..Message = TextErrorMessages.missingAmPmDesignator
  ];

  @internal List<Data> ParseOnlyData = [
    new Data.hms(0, 0, 0, 400)
      ..Text = "4"
      ..Pattern = "%f",
    new Data.hms(0, 0, 0, 400)
      ..Text = "4"
      ..Pattern = "%F",
    new Data.hms(0, 0, 0, 400)
      ..Text = "4"
      ..Pattern = "FF",
    new Data.hms(0, 0, 0, 400)
      ..Text = "40"
      ..Pattern = "FF",
    new Data.hms(0, 0, 0, 400)
      ..Text = "4"
      ..Pattern = "FFF",
    new Data.hms(0, 0, 0, 400)
      ..Text = "40"
      ..Pattern = "FFF",
    new Data.hms(0, 0, 0, 400)
      ..Text = "400"
      ..Pattern = "FFF",
    new Data.hms(0, 0, 0, 400)
      ..Text = "40"
      ..Pattern = "ff",
    new Data.hms(0, 0, 0, 400)
      ..Text = "400"
      ..Pattern = "fff",
    new Data.hms(0, 0, 0, 400)
      ..Text = "4000"
      ..Pattern = "ffff",
    new Data.hms(0, 0, 0, 400)
      ..Text = "40000"
      ..Pattern = "fffff",
    new Data.hms(0, 0, 0, 400)
      ..Text = "400000"
      ..Pattern = "ffffff",
    new Data.hms(0, 0, 0, 400)
      ..Text = "4000000"
      ..Pattern = "fffffff",
    new Data.hms(0, 0, 0, 400)
      ..Text = "4"
      ..Pattern = "%f",
    new Data.hms(0, 0, 0, 400)
      ..Text = "4"
      ..Pattern = "%F",
    new Data.hms(0, 0, 0, 450)
      ..Text = "45"
      ..Pattern = "ff",
    new Data.hms(0, 0, 0, 450)
      ..Text = "45"
      ..Pattern = "FF",
    new Data.hms(0, 0, 0, 450)
      ..Text = "45"
      ..Pattern = "FFF",
    new Data.hms(0, 0, 0, 450)
      ..Text = "450"
      ..Pattern = "fff",
    new Data.hms(0, 0, 0, 400)
      ..Text = "4"
      ..Pattern = "%f",
    new Data.hms(0, 0, 0, 400)
      ..Text = "4"
      ..Pattern = "%F",
    new Data.hms(0, 0, 0, 450)
      ..Text = "45"
      ..Pattern = "ff",
    new Data.hms(0, 0, 0, 450)
      ..Text = "45"
      ..Pattern = "FF",
    new Data.hms(0, 0, 0, 456)
      ..Text = "456"
      ..Pattern = "fff",
    new Data.hms(0, 0, 0, 456)
      ..Text = "456"
      ..Pattern = "FFF",

    new Data.hms(0, 0, 0, 0)
      ..Text = "0"
      ..Pattern = "%f",
    new Data.hms(0, 0, 0, 0)
      ..Text = "00"
      ..Pattern = "ff",
    new Data.hms(0, 0, 0, 8)
      ..Text = "008"
      ..Pattern = "fff",
    new Data.hms(0, 0, 0, 8)
      ..Text = "008"
      ..Pattern = "FFF",
    new Data.hms(5, 0, 0, 0)
      ..Text = "05"
      ..Pattern = "HH",
    new Data.hms(0, 6, 0, 0)
      ..Text = "06"
      ..Pattern = "mm",
    new Data.hms(0, 0, 7, 0)
      ..Text = "07"
      ..Pattern = "ss",
    new Data.hms(5, 0, 0, 0)
      ..Text = "5"
      ..Pattern = "%H",
    new Data.hms(0, 6, 0, 0)
      ..Text = "6"
      ..Pattern = "%m",
    new Data.hms(0, 0, 7, 0)
      ..Text = "7"
      ..Pattern = "%s",

    // AM/PM designator is case-insensitive for both short and long forms
    new Data.hms(17, 0, 0, 0)
      ..Text = "5 p"
      ..Pattern = "h t",
    new Data.hms(17, 0, 0, 0)
      ..Text = "5 pm"
      ..Pattern = "h tt",

    // Parsing using the semi-colon "comma dot" specifier
    new Data.hms(16, 05, 20, 352)
      ..Pattern = "HH:mm:ss;fff"
      ..Text = "16:05:20,352",
    new Data.hms(16, 05, 20, 352)
      ..Pattern = "HH:mm:ss;FFF"
      ..Text = "16:05:20,352",

    // Empty fractional section
    new Data.hms(0, 0, 4, 0)
      ..Text = "04"
      ..Pattern = "ssFF",
    new Data.hms(0, 0, 4, 0)
      ..Text = "040"
      ..Pattern = "ssFF",
    new Data.hms(0, 0, 4, 0)
      ..Text = "040"
      ..Pattern = "ssFFF",
    new Data.hms(0, 0, 4, 0)
      ..Text = "04"
      ..Pattern = "ss.FF",
  ];

  @internal List<Data> FormatOnlyData = [
    new Data.hms(5, 6, 7, 8)
      ..Text = ""
      ..Pattern = "%F",
    new Data.hms(5, 6, 7, 8)
      ..Text = ""
      ..Pattern = "FF",
    new Data.hms(1, 1, 1, 400)
      ..Text = "4"
      ..Pattern = "%f",
    new Data.hms(1, 1, 1, 400)
      ..Text = "4"
      ..Pattern = "%F",
    new Data.hms(1, 1, 1, 400)
      ..Text = "4"
      ..Pattern = "FF",
    new Data.hms(1, 1, 1, 400)
      ..Text = "4"
      ..Pattern = "FFF",
    new Data.hms(1, 1, 1, 400)
      ..Text = "40"
      ..Pattern = "ff",
    new Data.hms(1, 1, 1, 400)
      ..Text = "400"
      ..Pattern = "fff",
    new Data.hms(1, 1, 1, 400)
      ..Text = "4000"
      ..Pattern = "ffff",
    new Data.hms(1, 1, 1, 400)
      ..Text = "40000"
      ..Pattern = "fffff",
    new Data.hms(1, 1, 1, 400)
      ..Text = "400000"
      ..Pattern = "ffffff",
    new Data.hms(1, 1, 1, 400)
      ..Text = "4000000"
      ..Pattern = "fffffff",
    new Data.hms(1, 1, 1, 450)
      ..Text = "4"
      ..Pattern = "%f",
    new Data.hms(1, 1, 1, 450)
      ..Text = "4"
      ..Pattern = "%F",
    new Data.hms(1, 1, 1, 450)
      ..Text = "45"
      ..Pattern = "ff",
    new Data.hms(1, 1, 1, 450)
      ..Text = "45"
      ..Pattern = "FF",
    new Data.hms(1, 1, 1, 450)
      ..Text = "45"
      ..Pattern = "FFF",
    new Data.hms(1, 1, 1, 450)
      ..Text = "450"
      ..Pattern = "fff",
    new Data.hms(1, 1, 1, 456)
      ..Text = "4"
      ..Pattern = "%f",
    new Data.hms(1, 1, 1, 456)
      ..Text = "4"
      ..Pattern = "%F",
    new Data.hms(1, 1, 1, 456)
      ..Text = "45"
      ..Pattern = "ff",
    new Data.hms(1, 1, 1, 456)
      ..Text = "45"
      ..Pattern = "FF",
    new Data.hms(1, 1, 1, 456)
      ..Text = "456"
      ..Pattern = "fff",
    new Data.hms(1, 1, 1, 456)
      ..Text = "456"
      ..Pattern = "FFF",
    new Data.hms(0, 0, 0, 0)
      ..Text = ""
      ..Pattern = "FF",

    new Data.hms(5, 6, 7, 8)
      ..Culture = TestCultures.EnUs
      ..Text = "0"
      ..Pattern = "%f",
    new Data.hms(5, 6, 7, 8)
      ..Culture = TestCultures.EnUs
      ..Text = "00"
      ..Pattern = "ff",
    new Data.hms(5, 6, 7, 8)
      ..Culture = TestCultures.EnUs
      ..Text = "008"
      ..Pattern = "fff",
    new Data.hms(5, 6, 7, 8)
      ..Culture = TestCultures.EnUs
      ..Text = "008"
      ..Pattern = "FFF",
    new Data.hms(5, 6, 7, 8)
      ..Culture = TestCultures.EnUs
      ..Text = "05"
      ..Pattern = "HH",
    new Data.hms(5, 6, 7, 8)
      ..Culture = TestCultures.EnUs
      ..Text = "06"
      ..Pattern = "mm",
    new Data.hms(5, 6, 7, 8)
      ..Culture = TestCultures.EnUs
      ..Text = "07"
      ..Pattern = "ss",
    new Data.hms(5, 6, 7, 8)
      ..Culture = TestCultures.EnUs
      ..Text = "5"
      ..Pattern = "%H",
    new Data.hms(5, 6, 7, 8)
      ..Culture = TestCultures.EnUs
      ..Text = "6"
      ..Pattern = "%m",
    new Data.hms(5, 6, 7, 8)
      ..Culture = TestCultures.EnUs
      ..Text = "7"
      ..Pattern = "%s",
  ];

  @internal List<Data> DefaultPatternData = [
    // Invariant culture uses HH:mm:ss for the "long" pattern
    new Data.hms(5, 0, 0, 0)
      ..Text = "05:00:00",
    new Data.hms(5, 12, 0, 0)
      ..Text = "05:12:00",
    new Data.hms(5, 12, 34, 0)
      ..Text = "05:12:34",

    // US uses hh:mm:ss tt for the "long" pattern
    new Data.hms(17, 0, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "5:00:00 PM",
    new Data.hms(5, 0, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "5:00:00 AM",
    new Data.hms(5, 12, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "5:12:00 AM",
    new Data.hms(5, 12, 34, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "5:12:34 AM",
  ];

  @internal final List<Data> TemplateValueData = [
    // Pattern specifies nothing - template value is passed through
    new Data(new LocalTime.fromHourMinuteSecondMillisecondTick(1, 2, 3, 4, 5))
      ..Culture = TestCultures.EnUs
      ..Text = "X"
      ..Pattern = "'X'"
      ..Template = new LocalTime.fromHourMinuteSecondMillisecondTick(1, 2, 3, 4, 5),
    // Tests for each individual field being propagated
    new Data(new LocalTime.fromHourMinuteSecondMillisecondTick(1, 6, 7, 8, 9))
      ..Culture = TestCultures.EnUs
      ..Text = "06:07.0080009"
      ..Pattern = "mm:ss.FFFFFFF"
      ..Template = new LocalTime.fromHourMinuteSecondMillisecondTick(1, 2, 3, 4, 5),
    new Data(new LocalTime.fromHourMinuteSecondMillisecondTick(6, 2, 7, 8, 9))
      ..Culture = TestCultures.EnUs
      ..Text = "06:07.0080009"
      ..Pattern = "HH:ss.FFFFFFF"
      ..Template = new LocalTime.fromHourMinuteSecondMillisecondTick(1, 2, 3, 4, 5),
    new Data(new LocalTime.fromHourMinuteSecondMillisecondTick(6, 7, 3, 8, 9))
      ..Culture = TestCultures.EnUs
      ..Text = "06:07.0080009"
      ..Pattern = "HH:mm.FFFFFFF"
      ..Template = new LocalTime.fromHourMinuteSecondMillisecondTick(1, 2, 3, 4, 5),
    new Data(new LocalTime.fromHourMinuteSecondMillisecondTick(6, 7, 8, 4, 5))
      ..Culture = TestCultures.EnUs
      ..Text = "06:07:08"
      ..Pattern = "HH:mm:ss"
      ..Template = new LocalTime.fromHourMinuteSecondMillisecondTick(1, 2, 3, 4, 5),

    // Hours are tricky because of the ways they can be specified
    new Data(new LocalTime(6, 2, 3))
      ..Culture = TestCultures.EnUs
      ..Text = "6"
      ..Pattern = "%h"
      ..Template = new LocalTime(1, 2, 3),
    new Data(new LocalTime(18, 2, 3))
      ..Culture = TestCultures.EnUs
      ..Text = "6"
      ..Pattern = "%h"
      ..Template = new LocalTime(14, 2, 3),
    new Data(new LocalTime(2, 2, 3))
      ..Culture = TestCultures.EnUs
      ..Text = "AM"
      ..Pattern = "tt"
      ..Template = new LocalTime(14, 2, 3),
    new Data(new LocalTime(14, 2, 3))
      ..Culture = TestCultures.EnUs
      ..Text = "PM"
      ..Pattern = "tt"
      ..Template = new LocalTime(14, 2, 3),
    new Data(new LocalTime(2, 2, 3))
      ..Culture = TestCultures.EnUs
      ..Text = "AM"
      ..Pattern = "tt"
      ..Template = new LocalTime(2, 2, 3),
    new Data(new LocalTime(14, 2, 3))
      ..Culture = TestCultures.EnUs
      ..Text = "PM"
      ..Pattern = "tt"
      ..Template = new LocalTime(2, 2, 3),
    new Data(new LocalTime(17, 2, 3))
      ..Culture = TestCultures.EnUs
      ..Text = "5 PM"
      ..Pattern = "h tt"
      ..Template = new LocalTime(1, 2, 3),
  ];

  /// Common test data for both formatting and parsing. A test should be placed here unless is truly
  /// cannot be run both ways. This ensures that as many round-trip type tests are performed as possible.
  @internal final List<Data> FormatAndParseData = [
    new Data(LocalTime.midnight)
      ..Culture = TestCultures.EnUs
      ..Text = "."
      ..Pattern = "%.",
    new Data(LocalTime.midnight)
      ..Culture = TestCultures.EnUs
      ..Text = ":"
      ..Pattern = "%:",
    new Data(LocalTime.midnight)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "."
      ..Pattern = "%.",
    new Data(LocalTime.midnight)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "."
      ..Pattern = "%:",
    new Data(LocalTime.midnight)
      ..Culture = TestCultures.EnUs
      ..Text = "H"
      ..Pattern = "\\H",
    new Data(LocalTime.midnight)
      ..Culture = TestCultures.EnUs
      ..Text = "HHss"
      ..Pattern = "'HHss'",
    new Data.hms(0, 0, 0, 100)
      ..Culture = TestCultures.EnUs
      ..Text = "1"
      ..Pattern = "%f",
    new Data.hms(0, 0, 0, 100)
      ..Culture = TestCultures.EnUs
      ..Text = "1"
      ..Pattern = "%F",
    new Data.hms(0, 0, 0, 100)
      ..Culture = TestCultures.EnUs
      ..Text = "1"
      ..Pattern = "FF",
    new Data.hms(0, 0, 0, 100)
      ..Culture = TestCultures.EnUs
      ..Text = "1"
      ..Pattern = "FFF",
    new Data.hms(0, 0, 0, 100)
      ..Culture = TestCultures.EnUs
      ..Text = "100000000"
      ..Pattern = "fffffffff",
    new Data.hms(0, 0, 0, 100)
      ..Culture = TestCultures.EnUs
      ..Text = "1"
      ..Pattern = "FFFFFFFFF",
    new Data.hms(0, 0, 0, 120)
      ..Culture = TestCultures.EnUs
      ..Text = "12"
      ..Pattern = "ff",
    new Data.hms(0, 0, 0, 120)
      ..Culture = TestCultures.EnUs
      ..Text = "12"
      ..Pattern = "FF",
    new Data.hms(0, 0, 0, 120)
      ..Culture = TestCultures.EnUs
      ..Text = "12"
      ..Pattern = "FFF",
    new Data.hms(0, 0, 0, 123)
      ..Culture = TestCultures.EnUs
      ..Text = "123"
      ..Pattern = "fff",
    new Data.hms(0, 0, 0, 123)
      ..Culture = TestCultures.EnUs
      ..Text = "123"
      ..Pattern = "FFF",
    new Data.hms(0, 0, 0, 123, 4000)
      ..Culture = TestCultures.EnUs
      ..Text = "1234"
      ..Pattern = "ffff",
    new Data.hms(0, 0, 0, 123, 4000)
      ..Culture = TestCultures.EnUs
      ..Text = "1234"
      ..Pattern = "FFFF",
    new Data.hms(0, 0, 0, 123, 4500)
      ..Culture = TestCultures.EnUs
      ..Text = "12345"
      ..Pattern = "fffff",
    new Data.hms(0, 0, 0, 123, 4500)
      ..Culture = TestCultures.EnUs
      ..Text = "12345"
      ..Pattern = "FFFFF",
    new Data.hms(0, 0, 0, 123, 4560)
      ..Culture = TestCultures.EnUs
      ..Text = "123456"
      ..Pattern = "ffffff",
    new Data.hms(0, 0, 0, 123, 4560)
      ..Culture = TestCultures.EnUs
      ..Text = "123456"
      ..Pattern = "FFFFFF",
    new Data.hms(0, 0, 0, 123, 4567)
      ..Culture = TestCultures.EnUs
      ..Text = "1234567"
      ..Pattern = "fffffff",
    new Data.hms(0, 0, 0, 123, 4567)
      ..Culture = TestCultures.EnUs
      ..Text = "1234567"
      ..Pattern = "FFFFFFF",
    new Data.nano(0, 0, 0, 123456780 /*L*/)
      ..Culture = TestCultures.EnUs
      ..Text = "12345678"
      ..Pattern = "ffffffff",
    new Data.nano(0, 0, 0, 123456780 /*L*/)
      ..Culture = TestCultures.EnUs
      ..Text = "12345678"
      ..Pattern = "FFFFFFFF",
    new Data.nano(0, 0, 0, 123456789 /*L*/)
      ..Culture = TestCultures.EnUs
      ..Text = "123456789"
      ..Pattern = "fffffffff",
    new Data.nano(0, 0, 0, 123456789 /*L*/)
      ..Culture = TestCultures.EnUs
      ..Text = "123456789"
      ..Pattern = "FFFFFFFFF",
    new Data.hms(0, 0, 0, 600)
      ..Culture = TestCultures.EnUs
      ..Text = ".6"
      ..Pattern = ".f",
    new Data.hms(0, 0, 0, 600)
      ..Culture = TestCultures.EnUs
      ..Text = ".6"
      ..Pattern = ".F",
    new Data.hms(0, 0, 0, 600)
      ..Culture = TestCultures.EnUs
      ..Text = ".6"
      ..Pattern = ".FFF", // Elided fraction
    new Data.hms(0, 0, 0, 678)
      ..Culture = TestCultures.EnUs
      ..Text = ".678"
      ..Pattern = ".fff",
    new Data.hms(0, 0, 0, 678)
      ..Culture = TestCultures.EnUs
      ..Text = ".678"
      ..Pattern = ".FFF",
    new Data.hms(0, 0, 12, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "12"
      ..Pattern = "%s",
    new Data.hms(0, 0, 12, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "12"
      ..Pattern = "ss",
    new Data.hms(0, 0, 2, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "2"
      ..Pattern = "%s",
    new Data.hms(0, 12, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "12"
      ..Pattern = "%m",
    new Data.hms(0, 12, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "12"
      ..Pattern = "mm",
    new Data.hms(0, 2, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "2"
      ..Pattern = "%m",
    new Data.hms(1, 0, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "1"
      ..Pattern = "H.FFF", // Missing fraction
    new Data.hms(12, 0, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "12"
      ..Pattern = "%H",
    new Data.hms(12, 0, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "12"
      ..Pattern = "HH",
    new Data.hms(2, 0, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "2"
      ..Pattern = "%H",
    new Data.hms(2, 0, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "2"
      ..Pattern = "%H",
    new Data.hms(0, 0, 12, 340)
      ..Culture = TestCultures.EnUs
      ..Text = "12.34"
      ..Pattern = "ss.FFF",

    new Data.hms(14, 15, 16)
      ..Culture = TestCultures.EnUs
      ..Text = "14:15:16"
      ..Pattern = "r",
    new Data.hms(14, 15, 16, 700)
      ..Culture = TestCultures.EnUs
      ..Text = "14:15:16.7"
      ..Pattern = "r",
    new Data.hms(14, 15, 16, 780)
      ..Culture = TestCultures.EnUs
      ..Text = "14:15:16.78"
      ..Pattern = "r",
    new Data.hms(14, 15, 16, 789)
      ..Culture = TestCultures.EnUs
      ..Text = "14:15:16.789"
      ..Pattern = "r",
    new Data.hms(14, 15, 16, 789, 1000)
      ..Culture = TestCultures.EnUs
      ..Text = "14:15:16.7891"
      ..Pattern = "r",
    new Data.hms(14, 15, 16, 789, 1200)
      ..Culture = TestCultures.EnUs
      ..Text = "14:15:16.78912"
      ..Pattern = "r",
    new Data.hms(14, 15, 16, 789, 1230)
      ..Culture = TestCultures.EnUs
      ..Text = "14:15:16.789123"
      ..Pattern = "r",
    new Data.hms(14, 15, 16, 789, 1234)
      ..Culture = TestCultures.EnUs
      ..Text = "14:15:16.7891234"
      ..Pattern = "r",
    new Data.hms(14, 15, 16, 700)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "14.15.16.7"
      ..Pattern = "r",
    new Data.hms(14, 15, 16, 780)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "14.15.16.78"
      ..Pattern = "r",
    new Data.hms(14, 15, 16, 789)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "14.15.16.789"
      ..Pattern = "r",
    new Data.hms(14, 15, 16, 789, 1000)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "14.15.16.7891"
      ..Pattern = "r",
    new Data.hms(14, 15, 16, 789, 1200)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "14.15.16.78912"
      ..Pattern = "r",
    new Data.hms(14, 15, 16, 789, 1230)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "14.15.16.789123"
      ..Pattern = "r",
    new Data.hms(14, 15, 16, 789, 1234)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "14.15.16.7891234"
      ..Pattern = "r",
    new Data.nano(14, 15, 16, 789123456 /*L*/)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "14.15.16.789123456"
      ..Pattern = "r",

    // ------------ Template value tests ----------
    // Mixtures of 12 and 24 hour times
    new Data.hms(18, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "18 6 PM"
      ..Pattern = "HH h tt",
    new Data.hms(18, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "18 6"
      ..Pattern = "HH h",
    new Data.hms(18, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "18 PM"
      ..Pattern = "HH tt",
    new Data.hms(18, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "6 PM"
      ..Pattern = "h tt",
    new Data.hms(6, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "6"
      ..Pattern = "%h",
    new Data.hms(0, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "AM"
      ..Pattern = "tt",
    new Data.hms(12, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "PM"
      ..Pattern = "tt",
    new Data.hms(0, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "A"
      ..Pattern = "%t",
    new Data.hms(12, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "P"
      ..Pattern = "%t",

    // Pattern specifies nothing - template value is passed through
    new Data(new LocalTime.fromHourMinuteSecondMillisecondTick(1, 2, 3, 4, 5))
      ..Culture = TestCultures.EnUs
      ..Text = "*"
      ..Pattern = "%*"
      ..Template = new LocalTime.fromHourMinuteSecondMillisecondTick(1, 2, 3, 4, 5),
    // Tests for each individual field being propagated
    new Data(new LocalTime.fromHourMinuteSecondMillisecondTick(1, 6, 7, 8, 9))
      ..Culture = TestCultures.EnUs
      ..Text = "06:07.0080009"
      ..Pattern = "mm:ss.FFFFFFF"
      ..Template = new LocalTime.fromHourMinuteSecondMillisecondTick(1, 2, 3, 4, 5),
    new Data(new LocalTime.fromHourMinuteSecondMillisecondTick(6, 2, 7, 8, 9))
      ..Culture = TestCultures.EnUs
      ..Text = "06:07.0080009"
      ..Pattern = "HH:ss.FFFFFFF"
      ..Template = new LocalTime.fromHourMinuteSecondMillisecondTick(1, 2, 3, 4, 5),
    new Data(new LocalTime.fromHourMinuteSecondMillisecondTick(6, 7, 3, 8, 9))
      ..Culture = TestCultures.EnUs
      ..Text = "06:07.0080009"
      ..Pattern = "HH:mm.FFFFFFF"
      ..Template = new LocalTime.fromHourMinuteSecondMillisecondTick(1, 2, 3, 4, 5),
    new Data(new LocalTime.fromHourMinuteSecondMillisecondTick(6, 7, 3, 8, 9))
      ..Culture = TestCultures.EnUs
      ..Text = "06:07.0080009"
      ..Pattern = "HH:mm.FFFFFFF"
      ..Template = new LocalTime.fromHourMinuteSecondMillisecondTick(1, 2, 3, 4, 5),
    new Data(new LocalTime.fromHourMinuteSecondMillisecondTick(6, 7, 8, 4, 5))
      ..Culture = TestCultures.EnUs
      ..Text = "06:07:08"
      ..Pattern = "HH:mm:ss"
      ..Template = new LocalTime.fromHourMinuteSecondMillisecondTick(1, 2, 3, 4, 5),

    // Hours are tricky because of the ways they can be specified
    new Data(new LocalTime(6, 2, 3))
      ..Culture = TestCultures.EnUs
      ..Text = "6"
      ..Pattern = "%h"
      ..Template = new LocalTime(1, 2, 3),
    new Data(new LocalTime(18, 2, 3))
      ..Culture = TestCultures.EnUs
      ..Text = "6"
      ..Pattern = "%h"
      ..Template = new LocalTime(14, 2, 3),
    new Data(new LocalTime(2, 2, 3))
      ..Culture = TestCultures.EnUs
      ..Text = "AM"
      ..Pattern = "tt"
      ..Template = new LocalTime(14, 2, 3),
    new Data(new LocalTime(14, 2, 3))
      ..Culture = TestCultures.EnUs
      ..Text = "PM"
      ..Pattern = "tt"
      ..Template = new LocalTime(14, 2, 3),
    new Data(new LocalTime(2, 2, 3))
      ..Culture = TestCultures.EnUs
      ..Text = "AM"
      ..Pattern = "tt"
      ..Template = new LocalTime(2, 2, 3),
    new Data(new LocalTime(14, 2, 3))
      ..Culture = TestCultures.EnUs
      ..Text = "PM"
      ..Pattern = "tt"
      ..Template = new LocalTime(2, 2, 3),
    new Data(new LocalTime(17, 2, 3))
      ..Culture = TestCultures.EnUs
      ..Text = "5 PM"
      ..Pattern = "h tt"
      ..Template = new LocalTime(1, 2, 3),
// --------------- end of template value tests ----------------------

    // Only one of the AM/PM designator is present. We should still be able to work out what is meant, by the presence
    // or absense of the non-empty one.
    new Data.hms(5, 0, 0)
      ..Culture = AmOnlyCulture
      ..Text = "5 am"
      ..Pattern = "h tt",
    new Data.hms(15, 0, 0)
      ..Culture = AmOnlyCulture
      ..Text = "3 "
      ..Pattern = "h tt"
      ..Description = "Implicit PM",
    new Data.hms(5, 0, 0)
      ..Culture = AmOnlyCulture
      ..Text = "5 a"
      ..Pattern = "h t",
    new Data.hms(15, 0, 0)
      ..Culture = AmOnlyCulture
      ..Text = "3 "
      ..Pattern = "h t"
      ..Description = "Implicit PM",

    new Data.hms(5, 0, 0)
      ..Culture = PmOnlyCulture
      ..Text = "5 "
      ..Pattern = "h tt",
    new Data.hms(15, 0, 0)
      ..Culture = PmOnlyCulture
      ..Text = "3 pm"
      ..Pattern = "h tt",
    new Data.hms(5, 0, 0)
      ..Culture = PmOnlyCulture
      ..Text = "5 "
      ..Pattern = "h t",
    new Data.hms(15, 0, 0)
      ..Culture = PmOnlyCulture
      ..Text = "3 p"
      ..Pattern = "h t",

    // AM / PM designators are both empty strings. The parsing side relies on the AM/PM value being correct on the
    // template value. (The template value is for the wrong actual hour, but in the right side of noon.)
    new Data.hms(5, 0, 0)
      ..Culture = NoAmOrPmCulture
      ..Text = "5 "
      ..Pattern = "h tt"
      ..Template = new LocalTime(2, 0, 0),
    new Data.hms(15, 0, 0)
      ..Culture = NoAmOrPmCulture
      ..Text = "3 "
      ..Pattern = "h tt"
      ..Template = new LocalTime(14, 0, 0),
    new Data.hms(5, 0, 0)
      ..Culture = NoAmOrPmCulture
      ..Text = "5 "
      ..Pattern = "h t"
      ..Template = new LocalTime(2, 0, 0),
    new Data.hms(15, 0, 0)
      ..Culture = NoAmOrPmCulture
      ..Text = "3 "
      ..Pattern = "h t"
      ..Template = new LocalTime(14, 0, 0),

    // Use of the semi-colon "comma dot" specifier
    new Data.hms(16, 05, 20, 352)
      ..Pattern = "HH:mm:ss;fff"
      ..Text = "16:05:20.352",
    new Data.hms(16, 05, 20, 352)
      ..Pattern = "HH:mm:ss;FFF"
      ..Text = "16:05:20.352",
    new Data.hms(16, 05, 20, 352)
      ..Pattern = "HH:mm:ss;FFF 'end'"
      ..Text = "16:05:20.352 end",
    new Data.hms(16, 05, 20)
      ..Pattern = "HH:mm:ss;FFF 'end'"
      ..Text = "16:05:20 end",

    // Patterns obtainable by properties but not single character standard patterns
    new Data.nano(1, 2, 3, 123456700 /*L*/)
      ..StandardPattern = LocalTimePattern.ExtendedIso
      ..Culture = TestCultures.EnUs
      ..Text = "01:02:03.1234567"
      ..Pattern = "HH':'mm':'ss;FFFFFFF",
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);

  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);

  @private static CultureInfo CreateCustomAmPmCulture(String amDesignator, String pmDesignator) {
    return new CultureInfo(CultureInfo.invariantCultureId, (
        new DateTimeFormatInfoBuilder.invariantCulture()
          ..amDesignator = amDesignator
          ..pmDesignator = pmDesignator).Build());
  }

  @Test()
  void ParseNull() => AssertParseNull(LocalTimePattern.ExtendedIso);

  /*
  @Test()
  @TestCaseSource(#Cultures, 'AllCultures')
  void BclLongTimePatternIsValidNodaPattern(CultureInfo culture) {
    if (culture == null) {
      return;
    }
    AssertValidNodaPattern(culture, culture.dateTimeFormat.longTimePattern);
  }

  @Test()
  @TestCaseSource(#Cultures, 'AllCultures')
  void BclShortTimePatternIsValidNodaPattern(CultureInfo culture) {
    AssertValidNodaPattern(culture, culture.dateTimeFormat.shortTimePattern);
  }*/

/*
@Test()
@TestCaseSource(#Cultures, 'AllCultures')
void BclLongTimePatternGivesSameResultsInNoda(CultureInfo culture)
{
AssertBclNodaEquality(culture, culture.DateTimeFormat.LongTimePattern);
}

@Test()
@TestCaseSource(#Cultures, 'AllCultures')
void BclShortTimePatternGivesSameResultsInNoda(CultureInfo culture)
{
AssertBclNodaEquality(culture, culture.DateTimeFormat.ShortTimePattern);
}*/

  @Test()
  void CreateWithInvariantCulture_NullPatternText() {
    expect(() => LocalTimePattern.CreateWithInvariantCulture(null), throwsArgumentError);
  }

  @Test()
  void Create_NullFormatInfo() {
    expect(() => LocalTimePattern.Create3("HH", null), throwsArgumentError);
  }

  @Test()
  void TemplateValue_DefaultsToMidnight() {
    var pattern = LocalTimePattern.CreateWithInvariantCulture("HH");
    expect(LocalTime.midnight, pattern.TemplateValue);
  }

  @Test()
  void CreateWithCurrentCulture() {
    // using (CultureSaver.SetCultures(TestCultures.DotTimeSeparator))
    CultureInfo.currentCulture = TestCultures.DotTimeSeparator;
    {
      var pattern = LocalTimePattern.CreateWithCurrentCulture("HH:mm");
      var text = pattern.format(new LocalTime(13, 45));
      expect("13.45", text);
    }
  }

  @Test()
  void WithTemplateValue_PropertyFetch() {
    LocalTime newValue = new LocalTime(1, 23, 45);
    var pattern = LocalTimePattern.CreateWithInvariantCulture("HH").WithTemplateValue(newValue);
    expect(newValue, pattern.TemplateValue);
  }

/*
@private void AssertBclNodaEquality(CultureInfo culture, String patternText)
{
// On Mono, some general patterns include an offset at the end.
// https://github.com/nodatime/nodatime/issues/98
// For the moment, ignore them.
// TODO(V1.2): Work out what to do in such cases...
if (patternText.endsWith("z"))
{
return;
}
var pattern = LocalTimePattern.Create3(patternText, culture);

expect(SampleDateTime.toString(patternText, culture), pattern.Format(SampleLocalTime));
}*/

/*
  @private static void AssertValidNodaPattern(CultureInfo culture, String pattern) {
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
  /*protected*/ @override LocalTime get DefaultTemplate => LocalTime.midnight;

  Data([LocalTime value = null]) : super(value ?? LocalTime.midnight);

  Data.hms(int hours, int minutes, int seconds, [int milliseconds = 0, int ticksWithinMillisecond = 0])
      : super(new LocalTime.fromHourMinuteSecondMillisecondTick(hours, minutes, seconds, milliseconds, ticksWithinMillisecond));

  Data.nano(int hours, int minutes, int seconds, int /*long*/ nanoOfSecond)
      : super(new LocalTime(hours, minutes, seconds).plusNanoseconds(nanoOfSecond))
  {
  }


  @internal @override IPattern<LocalTime> CreatePattern() =>
  LocalTimePattern.CreateWithInvariantCulture(super.Pattern)
      .WithTemplateValue(Template)
      .WithCulture(Culture);
}

