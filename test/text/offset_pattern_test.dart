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
class OffsetPatternTest extends PatternTestBase<Offset> {
  /// A non-breaking space.
  static const String Nbsp = "\u00a0";

  /// Test data that can only be used to test formatting.
  @internal final List<Data> FormatOnlyData = [
    new Data.hms(3, 0, 0)
      ..Culture = TestCultures.EnUs
      ..text = ""
      ..Pattern = "%-",
    new Data.hms(5, 0, 0)
      ..Culture = TestCultures.EnUs
      ..text = "+05"
      ..Pattern = "g",
    new Data.hms(5, 12, 0)
      ..Culture = TestCultures.EnUs
      ..text = "+05:12"
      ..Pattern = "g",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.EnUs
      ..text = "+05:12:34"
      ..Pattern = "g",

    // Losing information
    new Data.hms(5, 6, 7)
      ..Culture = TestCultures.EnUs
      ..text = "05"
      ..Pattern = "HH",
    new Data.hms(5, 6, 7)
      ..Culture = TestCultures.EnUs
      ..text = "06"
      ..Pattern = "mm",
    new Data.hms(5, 6, 7)
      ..Culture = TestCultures.EnUs
      ..text = "07"
      ..Pattern = "ss",
    new Data.hms(5, 6, 7)
      ..Culture = TestCultures.EnUs
      ..text = "5"
      ..Pattern = "%H",
    new Data.hms(5, 6, 7)
      ..Culture = TestCultures.EnUs
      ..text = "6"
      ..Pattern = "%m",
    new Data.hms(5, 6, 7)
      ..Culture = TestCultures.EnUs
      ..text = "7"
      ..Pattern = "%s",

    new Data(Offset.maxValue)
      ..Culture = TestCultures.EnUs
      ..text = "+18"
      ..Pattern = "g",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.EnUs
      ..text = "18"
      ..Pattern = "%H",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.EnUs
      ..text = "0"
      ..Pattern = "%m",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.EnUs
      ..text = "0"
      ..Pattern = "%s",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.EnUs
      ..text = "m"
      ..Pattern = "\\m",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.EnUs
      ..text = "m"
      ..Pattern = "'m'",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.EnUs
      ..text = "mmmmmmmmmm"
      ..Pattern = "'mmmmmmmmmm'",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.EnUs
      ..text = "z"
      ..Pattern = "'z'",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.EnUs
      ..text = "zqw"
      ..Pattern = "'zqw'",
    new Data.hms(3, 0, 0, true)
      ..Culture = TestCultures.EnUs
      ..text = "-"
      ..Pattern = "%-",
    new Data.hms(3, 0, 0)
      ..Culture = TestCultures.EnUs
      ..text = "+"
      ..Pattern = "%+",
    new Data.hms(3, 0, 0, true)
      ..Culture = TestCultures.EnUs
      ..text = "-"
      ..Pattern = "%+",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.EnUs
      ..text = "+05"
      ..Pattern = "s",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.EnUs
      ..text = "+05:12"
      ..Pattern = "m",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.EnUs
      ..text = "+05:12:34"
      ..Pattern = "l",
  ];

  /// Test data that can only be used to test successful parsing.
  @internal final List<Data> ParseOnlyData = [
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "*"
      ..Pattern = "%*",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "zqw"
      ..Pattern = "'zqw'",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "-"
      ..Pattern = "%-",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "+"
      ..Pattern = "%+",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "-"
      ..Pattern = "%+",
    new Data.hms(5, 0, 0)
      ..Culture = TestCultures.EnUs
      ..text = "+05"
      ..Pattern = "s",
    new Data.hms(5, 12, 0)
      ..Culture = TestCultures.EnUs
      ..text = "+05:12"
      ..Pattern = "m",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.EnUs
      ..text = "+05:12:34"
      ..Pattern = "l",
    new Data(Offset.zero)
      ..Pattern = "Z+HH:mm"
      ..text = "+00:00" // Lenient when parsing Z-prefixed patterns.
  ];

  /// Test data for invalid patterns
  @internal final List<Data> InvalidPatternData = [
    new Data(Offset.zero)
      ..Pattern = ""
      ..Message = TextErrorMessages.formatStringEmpty,
    new Data(Offset.zero)
      ..Pattern = "%Z"
      ..Message = TextErrorMessages.emptyZPrefixedOffsetPattern,
    new Data(Offset.zero)
      ..Pattern = "HH:mmZ"
      ..Message = TextErrorMessages.zPrefixNotAtStartOfPattern,
    new Data(Offset.zero)
      ..Pattern = "%%H"
      ..Message = TextErrorMessages.percentDoubled,
    new Data(Offset.zero)
      ..Pattern = "HH:HH"
      ..Message = TextErrorMessages.repeatedFieldInPattern
      ..Parameters.addAll(['H']),
    new Data(Offset.zero)
      ..Pattern = "mm:mm"
      ..Message = TextErrorMessages.repeatedFieldInPattern
      ..Parameters.addAll(['m']),
    new Data(Offset.zero)
      ..Pattern = "ss:ss"
      ..Message = TextErrorMessages.repeatedFieldInPattern
      ..Parameters.addAll(['s']),
    new Data(Offset.zero)
      ..Pattern = "+HH:-mm"
      ..Message = TextErrorMessages.repeatedFieldInPattern
      ..Parameters.addAll(['-']),
    new Data(Offset.zero)
      ..Pattern = "-HH:+mm"
      ..Message = TextErrorMessages.repeatedFieldInPattern
      ..Parameters.addAll(['+']),
    new Data(Offset.zero)
      ..Pattern = "!"
      ..Message = TextErrorMessages.unknownStandardFormat
      ..Parameters.addAll(['!', 'Offset']),
    new Data(Offset.zero)
      ..Pattern = "%"
      ..Message = TextErrorMessages.unknownStandardFormat
      ..Parameters.addAll(['%', 'Offset']),
    new Data(Offset.zero)
      ..Pattern = "%%"
      ..Message = TextErrorMessages.percentDoubled,
    new Data(Offset.zero)
      ..Pattern = "%\\"
      ..Message = TextErrorMessages.escapeAtEndOfString,
    new Data(Offset.zero)
      ..Pattern = "\\"
      ..Message = TextErrorMessages.unknownStandardFormat
      ..Parameters.addAll(['\\', 'Offset']),
    new Data(Offset.zero)
      ..Pattern = "H%"
      ..Message = TextErrorMessages.percentAtEndOfString,
    new Data(Offset.zero)
      ..Pattern = "hh"
      ..Message = TextErrorMessages.hour12PatternNotSupported
      ..Parameters.addAll(['Offset']),
    new Data(Offset.zero)
      ..Pattern = "HHH"
      ..Message = TextErrorMessages.repeatCountExceeded
      ..Parameters.addAll(['H', 2]),
    new Data(Offset.zero)
      ..Pattern = "mmm"
      ..Message = TextErrorMessages.repeatCountExceeded
      ..Parameters.addAll(['m', 2]),
    new Data(Offset.zero)
      ..Pattern = "mmmmmmmmmmmmmmmmmmm"
      ..Message = TextErrorMessages.repeatCountExceeded
      ..Parameters.addAll(['m', 2]),
    new Data(Offset.zero)
      ..Pattern = "'qwe"
      ..Message = TextErrorMessages.missingEndQuote
      ..Parameters.addAll(['\'']),
    new Data(Offset.zero)
      ..Pattern = "'qwe\\"
      ..Message = TextErrorMessages.escapeAtEndOfString,
    new Data(Offset.zero)
      ..Pattern = "'qwe\\'"
      ..Message = TextErrorMessages.missingEndQuote
      ..Parameters.addAll(['\'']),
    new Data(Offset.zero)
      ..Pattern = "sss"
      ..Message = TextErrorMessages.repeatCountExceeded
      ..Parameters.addAll(['s', 2]),
  ];

  /// Tests for parsing failures (of values)
  @internal final List<Data> ParseFailureData = [
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = ""
      ..Pattern = "g"
      ..Message = TextErrorMessages.valueStringEmpty,
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "1"
      ..Pattern = "HH"
      ..Message = TextErrorMessages.mismatchedNumber
      ..Parameters.addAll(["HH"]),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "1"
      ..Pattern = "mm"
      ..Message = TextErrorMessages.mismatchedNumber
      ..Parameters.addAll(["mm"]),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "1"
      ..Pattern = "ss"
      ..Message = TextErrorMessages.mismatchedNumber
      ..Parameters.addAll(["ss"]),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "12:34 "
      ..Pattern = "HH:mm"
      ..Message = TextErrorMessages.extraValueCharacters
      ..Parameters.addAll([" "]),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "1a"
      ..Pattern = "H "
      ..Message = TextErrorMessages.mismatchedCharacter
      ..Parameters.addAll([' ']),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "2:"
      ..Pattern = "%H"
      ..Message = TextErrorMessages.extraValueCharacters
      ..Parameters.addAll([":"]),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "a"
      ..Pattern = "%."
      ..Message = TextErrorMessages.mismatchedCharacter
      ..Parameters.addAll(['.']),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "a"
      ..Pattern = "%:"
      ..Message = TextErrorMessages.timeSeparatorMismatch,
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "a"
      ..Pattern = "%H"
      ..Message = TextErrorMessages.mismatchedNumber
      ..Parameters.addAll(["H"]),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "a"
      ..Pattern = "%m"
      ..Message = TextErrorMessages.mismatchedNumber
      ..Parameters.addAll(["m"]),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "a"
      ..Pattern = "%s"
      ..Message = TextErrorMessages.mismatchedNumber
      ..Parameters.addAll(["s"]),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "a"
      ..Pattern = ".H"
      ..Message = TextErrorMessages.mismatchedCharacter
      ..Parameters.addAll(['.']),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "a"
      ..Pattern = "\\'"
      ..Message = TextErrorMessages.escapedCharacterMismatch
      ..Parameters.addAll(['\'']),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "axc"
      ..Pattern = "'abc'"
      ..Message = TextErrorMessages.quotedStringMismatch,
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "z"
      ..Pattern = "%*"
      ..Message = TextErrorMessages.mismatchedCharacter
      ..Parameters.addAll(['*']),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "24"
      ..Pattern = "HH"
      ..Message = TextErrorMessages.fieldValueOutOfRange
      ..Parameters.addAll([24, 'H', 'Offset']),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "60"
      ..Pattern = "mm"
      ..Message = TextErrorMessages.fieldValueOutOfRange
      ..Parameters.addAll([60, 'm', 'Offset']),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "60"
      ..Pattern = "ss"
      ..Message = TextErrorMessages.fieldValueOutOfRange
      ..Parameters.addAll([60, 's', 'Offset']),
    new Data(Offset.zero)
      ..text = "+12"
      ..Pattern = "-HH"
      ..Message = TextErrorMessages.positiveSignInvalid,
  ];

  /// Common test data for both formatting and parsing. A test should be placed here unless is truly
  /// cannot be run both ways. This ensures that as many round-trip type tests are performed as possible.
  @internal final List<Data> FormatAndParseData = [
/*XXX*/ new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "."
      ..Pattern = "%.", // decimal separator
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = ":"
      ..Pattern = "%:", // date separator
/*XXX*/ new Data(Offset.zero)
      ..Culture = TestCultures.DotTimeSeparator
      ..text = "."
      ..Pattern = "%.", // decimal separator (always period)
    new Data(Offset.zero)
      ..Culture = TestCultures.DotTimeSeparator
      ..text = "."
      ..Pattern = "%:", // date separator
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "H"
      ..Pattern = "\\H",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "HHss"
      ..Pattern = "'HHss'",
    new Data.hms(0, 0, 12)
      ..Culture = TestCultures.EnUs
      ..text = "12"
      ..Pattern = "%s",
    new Data.hms(0, 0, 12)
      ..Culture = TestCultures.EnUs
      ..text = "12"
      ..Pattern = "ss",
    new Data.hms(0, 0, 2)
      ..Culture = TestCultures.EnUs
      ..text = "2"
      ..Pattern = "%s",
    new Data.hms(0, 12, 0)
      ..Culture = TestCultures.EnUs
      ..text = "12"
      ..Pattern = "%m",
    new Data.hms(0, 12, 0)
      ..Culture = TestCultures.EnUs
      ..text = "12"
      ..Pattern = "mm",
    new Data.hms(0, 2, 0)
      ..Culture = TestCultures.EnUs
      ..text = "2"
      ..Pattern = "%m",

    new Data.hms(12, 0, 0)
      ..Culture = TestCultures.EnUs
      ..text = "12"
      ..Pattern = "%H",
    new Data.hms(12, 0, 0)
      ..Culture = TestCultures.EnUs
      ..text = "12"
      ..Pattern = "HH",
    new Data.hms(2, 0, 0)
      ..Culture = TestCultures.EnUs
      ..text = "2"
      ..Pattern = "%H",
    new Data.hms(2, 0, 0)
      ..Culture = TestCultures.EnUs
      ..text = "2"
      ..Pattern = "%H",

    // Standard patterns with punctuation...
    new Data.hms(5, 0, 0)
      ..Culture = TestCultures.EnUs
      ..text = "+05"
      ..Pattern = "G",
    new Data.hms(5, 12, 0)
      ..Culture = TestCultures.EnUs
      ..text = "+05:12"
      ..Pattern = "G",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.EnUs
      ..text = "+05:12:34"
      ..Pattern = "G",
    new Data.hms(5, 0, 0)
      ..Culture = TestCultures.EnUs
      ..text = "+05"
      ..Pattern = "g",
    new Data.hms(5, 12, 0)
      ..Culture = TestCultures.EnUs
      ..text = "+05:12"
      ..Pattern = "g",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.EnUs
      ..text = "+05:12:34"
      ..Pattern = "g",
    new Data(Offset.minValue)
      ..Culture = TestCultures.EnUs
      ..text = "-18"
      ..Pattern = "g",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "Z"
      ..Pattern = "G",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "+00"
      ..Pattern = "g",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "+00"
      ..Pattern = "s",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "+00:00"
      ..Pattern = "m",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "+00:00:00"
      ..Pattern = "l",
    new Data.hms(5, 0, 0)
      ..Culture = TestCultures.FrFr
      ..text = "+05"
      ..Pattern = "g",
    new Data.hms(5, 12, 0)
      ..Culture = TestCultures.FrFr
      ..text = "+05:12"
      ..Pattern = "g",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.FrFr
      ..text = "+05:12:34"
      ..Pattern = "g",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.FrFr
      ..text = "+18"
      ..Pattern = "g",
    new Data(Offset.minValue)
      ..Culture = TestCultures.FrFr
      ..text = "-18"
      ..Pattern = "g",
    new Data.hms(5, 0, 0)
      ..Culture = TestCultures.DotTimeSeparator
      ..text = "+05"
      ..Pattern = "g",
    new Data.hms(5, 12, 0)
      ..Culture = TestCultures.DotTimeSeparator
      ..text = "+05.12"
      ..Pattern = "g",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.DotTimeSeparator
      ..text = "+05.12.34"
      ..Pattern = "g",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.DotTimeSeparator
      ..text = "+18"
      ..Pattern = "g",
    new Data(Offset.minValue)
      ..Culture = TestCultures.DotTimeSeparator
      ..text = "-18"
      ..Pattern = "g",

    // Standard patterns without punctuation
    new Data.hms(5, 0, 0)
      ..Culture = TestCultures.EnUs
      ..text = "+05"
      ..Pattern = "I",
    new Data.hms(5, 12, 0)
      ..Culture = TestCultures.EnUs
      ..text = "+0512"
      ..Pattern = "I",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.EnUs
      ..text = "+051234"
      ..Pattern = "I",
    new Data.hms(5, 0, 0)
      ..Culture = TestCultures.EnUs
      ..text = "+05"
      ..Pattern = "i",
    new Data.hms(5, 12, 0)
      ..Culture = TestCultures.EnUs
      ..text = "+0512"
      ..Pattern = "i",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.EnUs
      ..text = "+051234"
      ..Pattern = "i",
    new Data(Offset.minValue)
      ..Culture = TestCultures.EnUs
      ..text = "-18"
      ..Pattern = "i",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "Z"
      ..Pattern = "I",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "+00"
      ..Pattern = "i",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "+00"
      ..Pattern = "S",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "+0000"
      ..Pattern = "M",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..text = "+000000"
      ..Pattern = "L",
    new Data.hms(5, 0, 0)
      ..Culture = TestCultures.FrFr
      ..text = "+05"
      ..Pattern = "i",
    new Data.hms(5, 12, 0)
      ..Culture = TestCultures.FrFr
      ..text = "+0512"
      ..Pattern = "i",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.FrFr
      ..text = "+051234"
      ..Pattern = "i",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.FrFr
      ..text = "+18"
      ..Pattern = "i",
    new Data(Offset.minValue)
      ..Culture = TestCultures.FrFr
      ..text = "-18"
      ..Pattern = "i",
    new Data.hms(5, 0, 0)
      ..Culture = TestCultures.DotTimeSeparator
      ..text = "+05"
      ..Pattern = "i",
    new Data.hms(5, 12, 0)
      ..Culture = TestCultures.DotTimeSeparator
      ..text = "+0512"
      ..Pattern = "i",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.DotTimeSeparator
      ..text = "+051234"
      ..Pattern = "i",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.DotTimeSeparator
      ..text = "+18"
      ..Pattern = "i",
    new Data(Offset.minValue)
      ..Culture = TestCultures.DotTimeSeparator
      ..text = "-18"
      ..Pattern = "i",

    // Explicit patterns
    new Data.hms(0, 30, 0, true)
      ..Culture = TestCultures.EnUs
      ..text = "-00:30"
      ..Pattern = "+HH:mm",
    new Data.hms(0, 30, 0, true)
      ..Culture = TestCultures.EnUs
      ..text = "-00:30"
      ..Pattern = "-HH:mm",
    new Data.hms(0, 30, 0, false)
      ..Culture = TestCultures.EnUs
      ..text = "00:30"
      ..Pattern = "-HH:mm",

    // Z-prefixes
    new Data(Offset.zero)
      ..text = "Z"
      ..Pattern = "Z+HH:mm:ss",
    new Data.hms(5, 12, 34)
      ..text = "+05:12:34"
      ..Pattern = "Z+HH:mm:ss",
    new Data.hms(5, 12)
      ..text = "+05:12"
      ..Pattern = "Z+HH:mm",
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);

  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);

  @Test()
  @TestCaseSource(#ParseData)
  void ParsePartial(PatternTestData<Offset> data) {
    data.TestParsePartial();
  }

  @Test()
  void ParseNull() => AssertParseNull(OffsetPattern.generalInvariant);

  /* -- It is very ignored here -- not even ported.
  @Test()
  void NumberFormatIgnored()
  {
    // var builder = new DateTimeFormatInfoBuilder(TestCultures.EnUs.dateTimeFormat);
    // builder.NumberFormat.PositiveSign = "P";
    var culture = TestCultures.EnUs;
    culture.NumberFormat.PositiveSign = "P";
    culture.NumberFormat.NegativeSign = "N";
    var pattern = OffsetPattern.Create("+HH:mm", culture);

    expect("+05:00", pattern.Format(new Offset.fromHours(5)));
    expect("-05:00", pattern.Format(new Offset.fromHours(-5)));
  }*/

  @Test()
  void CreateWithCurrentCulture() {
    // using (CultureSaver.SetCultures(TestCultures.DotTimeSeparator))
    CultureInfo.currentCulture = TestCultures.DotTimeSeparator;
    {
      var pattern = OffsetPattern.createWithCurrentCulture("H:mm");
      var text = pattern.format(new Offset.fromHoursAndMinutes(1, 30));
      expect("1.30", text);
    }
  }
}

/// A container for test data for formatting and parsing [Offset] objects.
/*sealed*/class Data extends PatternTestData<Offset> {
  // Ignored anyway...
  /*protected*/ @override Offset get DefaultTemplate => Offset.zero;

  Data(Offset value) : super(value);

  Data.hms(int hours, int minutes, [int seconds = 0, bool negative = false]) // : this(Offset.FromHoursAndMinutes(hours, minutes))
      : this(negative ? TestObjects.CreateNegativeOffset(hours, minutes, seconds) :
  TestObjects.CreatePositiveOffset(hours, minutes, seconds));

  /*
  Data(int hours, int minutes, int seconds)
      : this(TestObjects.CreatePositiveOffset(hours, minutes, seconds))
  {
  }

  Data(int hours, int minutes, int seconds, bool negative)
      : this(negative ? TestObjects.CreateNegativeOffset(hours, minutes, seconds) :
  TestObjects.CreatePositiveOffset(hours, minutes, seconds))
  {
  }*/

  @internal
  @override
  IPattern<Offset> CreatePattern() =>
      OffsetPattern.createWithInvariantCulture(super.Pattern)
          .withCulture(Culture);

  @internal
  @override
  IPartialPattern<Offset> CreatePartialPattern() =>
      OffsetPatterns.underlyingPattern(
      OffsetPattern
          .createWithInvariantCulture(super.Pattern)
          .withCulture(Culture));
}



