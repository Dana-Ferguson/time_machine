// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/Text/OffsetPatternTest.cs
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
class OffsetPatternTest extends PatternTestBase<Offset> {
  /// <summary>
  /// A non-breaking space.
  /// </summary>
  static const String Nbsp = "\u00a0";

  /// <summary>
  /// Test data that can only be used to test formatting.
  /// </summary>
  @internal final List<Data> FormatOnlyData = [
    new Data.hms(3, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = ""
      ..Pattern = "%-",
    new Data.hms(5, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "+05"
      ..Pattern = "g",
    new Data.hms(5, 12, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "+05:12"
      ..Pattern = "g",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.EnUs
      ..Text = "+05:12:34"
      ..Pattern = "g",

    // Losing information
    new Data.hms(5, 6, 7)
      ..Culture = TestCultures.EnUs
      ..Text = "05"
      ..Pattern = "HH",
    new Data.hms(5, 6, 7)
      ..Culture = TestCultures.EnUs
      ..Text = "06"
      ..Pattern = "mm",
    new Data.hms(5, 6, 7)
      ..Culture = TestCultures.EnUs
      ..Text = "07"
      ..Pattern = "ss",
    new Data.hms(5, 6, 7)
      ..Culture = TestCultures.EnUs
      ..Text = "5"
      ..Pattern = "%H",
    new Data.hms(5, 6, 7)
      ..Culture = TestCultures.EnUs
      ..Text = "6"
      ..Pattern = "%m",
    new Data.hms(5, 6, 7)
      ..Culture = TestCultures.EnUs
      ..Text = "7"
      ..Pattern = "%s",

    new Data(Offset.maxValue)
      ..Culture = TestCultures.EnUs
      ..Text = "+18"
      ..Pattern = "g",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.EnUs
      ..Text = "18"
      ..Pattern = "%H",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.EnUs
      ..Text = "0"
      ..Pattern = "%m",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.EnUs
      ..Text = "0"
      ..Pattern = "%s",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.EnUs
      ..Text = "m"
      ..Pattern = "\\m",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.EnUs
      ..Text = "m"
      ..Pattern = "'m'",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.EnUs
      ..Text = "mmmmmmmmmm"
      ..Pattern = "'mmmmmmmmmm'",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.EnUs
      ..Text = "z"
      ..Pattern = "'z'",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.EnUs
      ..Text = "zqw"
      ..Pattern = "'zqw'",
    new Data.hms(3, 0, 0, true)
      ..Culture = TestCultures.EnUs
      ..Text = "-"
      ..Pattern = "%-",
    new Data.hms(3, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "+"
      ..Pattern = "%+",
    new Data.hms(3, 0, 0, true)
      ..Culture = TestCultures.EnUs
      ..Text = "-"
      ..Pattern = "%+",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.EnUs
      ..Text = "+05"
      ..Pattern = "s",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.EnUs
      ..Text = "+05:12"
      ..Pattern = "m",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.EnUs
      ..Text = "+05:12:34"
      ..Pattern = "l",
  ];

  /// <summary>
  /// Test data that can only be used to test successful parsing.
  /// </summary>
  @internal final List<Data> ParseOnlyData = [
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "*"
      ..Pattern = "%*",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "zqw"
      ..Pattern = "'zqw'",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "-"
      ..Pattern = "%-",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "+"
      ..Pattern = "%+",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "-"
      ..Pattern = "%+",
    new Data.hms(5, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "+05"
      ..Pattern = "s",
    new Data.hms(5, 12, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "+05:12"
      ..Pattern = "m",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.EnUs
      ..Text = "+05:12:34"
      ..Pattern = "l",
    new Data(Offset.zero)
      ..Pattern = "Z+HH:mm"
      ..Text = "+00:00" // Lenient when parsing Z-prefixed patterns.
  ];

  /// <summary>
  /// Test data for invalid patterns
  /// </summary>
  @internal final List<Data> InvalidPatternData = [
    new Data(Offset.zero)
      ..Pattern = ""
      ..Message = TextErrorMessages.FormatStringEmpty,
    new Data(Offset.zero)
      ..Pattern = "%Z"
      ..Message = TextErrorMessages.EmptyZPrefixedOffsetPattern,
    new Data(Offset.zero)
      ..Pattern = "HH:mmZ"
      ..Message = TextErrorMessages.ZPrefixNotAtStartOfPattern,
    new Data(Offset.zero)
      ..Pattern = "%%H"
      ..Message = TextErrorMessages.PercentDoubled,
    new Data(Offset.zero)
      ..Pattern = "HH:HH"
      ..Message = TextErrorMessages.RepeatedFieldInPattern
      ..Parameters.addAll(['H']),
    new Data(Offset.zero)
      ..Pattern = "mm:mm"
      ..Message = TextErrorMessages.RepeatedFieldInPattern
      ..Parameters.addAll(['m']),
    new Data(Offset.zero)
      ..Pattern = "ss:ss"
      ..Message = TextErrorMessages.RepeatedFieldInPattern
      ..Parameters.addAll(['s']),
    new Data(Offset.zero)
      ..Pattern = "+HH:-mm"
      ..Message = TextErrorMessages.RepeatedFieldInPattern
      ..Parameters.addAll(['-']),
    new Data(Offset.zero)
      ..Pattern = "-HH:+mm"
      ..Message = TextErrorMessages.RepeatedFieldInPattern
      ..Parameters.addAll(['+']),
    new Data(Offset.zero)
      ..Pattern = "!"
      ..Message = TextErrorMessages.UnknownStandardFormat
      ..Parameters.addAll(['!', 'Offset']),
    new Data(Offset.zero)
      ..Pattern = "%"
      ..Message = TextErrorMessages.UnknownStandardFormat
      ..Parameters.addAll(['%', 'Offset']),
    new Data(Offset.zero)
      ..Pattern = "%%"
      ..Message = TextErrorMessages.PercentDoubled,
    new Data(Offset.zero)
      ..Pattern = "%\\"
      ..Message = TextErrorMessages.EscapeAtEndOfString,
    new Data(Offset.zero)
      ..Pattern = "\\"
      ..Message = TextErrorMessages.UnknownStandardFormat
      ..Parameters.addAll(['\\', 'Offset']),
    new Data(Offset.zero)
      ..Pattern = "H%"
      ..Message = TextErrorMessages.PercentAtEndOfString,
    new Data(Offset.zero)
      ..Pattern = "hh"
      ..Message = TextErrorMessages.Hour12PatternNotSupported
      ..Parameters.addAll(['Offset']),
    new Data(Offset.zero)
      ..Pattern = "HHH"
      ..Message = TextErrorMessages.RepeatCountExceeded
      ..Parameters.addAll(['H', 2]),
    new Data(Offset.zero)
      ..Pattern = "mmm"
      ..Message = TextErrorMessages.RepeatCountExceeded
      ..Parameters.addAll(['m', 2]),
    new Data(Offset.zero)
      ..Pattern = "mmmmmmmmmmmmmmmmmmm"
      ..Message = TextErrorMessages.RepeatCountExceeded
      ..Parameters.addAll(['m', 2]),
    new Data(Offset.zero)
      ..Pattern = "'qwe"
      ..Message = TextErrorMessages.MissingEndQuote
      ..Parameters.addAll(['\'']),
    new Data(Offset.zero)
      ..Pattern = "'qwe\\"
      ..Message = TextErrorMessages.EscapeAtEndOfString,
    new Data(Offset.zero)
      ..Pattern = "'qwe\\'"
      ..Message = TextErrorMessages.MissingEndQuote
      ..Parameters.addAll(['\'']),
    new Data(Offset.zero)
      ..Pattern = "sss"
      ..Message = TextErrorMessages.RepeatCountExceeded
      ..Parameters.addAll(['s', 2]),
  ];

  /// <summary>
  /// Tests for parsing failures (of values)
  /// </summary>
  @internal final List<Data> ParseFailureData = [
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = ""
      ..Pattern = "g"
      ..Message = TextErrorMessages.ValueStringEmpty,
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "1"
      ..Pattern = "HH"
      ..Message = TextErrorMessages.MismatchedNumber
      ..Parameters.addAll(["HH"]),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "1"
      ..Pattern = "mm"
      ..Message = TextErrorMessages.MismatchedNumber
      ..Parameters.addAll(["mm"]),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "1"
      ..Pattern = "ss"
      ..Message = TextErrorMessages.MismatchedNumber
      ..Parameters.addAll(["ss"]),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "12:34 "
      ..Pattern = "HH:mm"
      ..Message = TextErrorMessages.ExtraValueCharacters
      ..Parameters.addAll([" "]),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "1a"
      ..Pattern = "H "
      ..Message = TextErrorMessages.MismatchedCharacter
      ..Parameters.addAll([' ']),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "2:"
      ..Pattern = "%H"
      ..Message = TextErrorMessages.ExtraValueCharacters
      ..Parameters.addAll([":"]),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "a"
      ..Pattern = "%."
      ..Message = TextErrorMessages.MismatchedCharacter
      ..Parameters.addAll(['.']),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "a"
      ..Pattern = "%:"
      ..Message = TextErrorMessages.TimeSeparatorMismatch,
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "a"
      ..Pattern = "%H"
      ..Message = TextErrorMessages.MismatchedNumber
      ..Parameters.addAll(["H"]),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "a"
      ..Pattern = "%m"
      ..Message = TextErrorMessages.MismatchedNumber
      ..Parameters.addAll(["m"]),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "a"
      ..Pattern = "%s"
      ..Message = TextErrorMessages.MismatchedNumber
      ..Parameters.addAll(["s"]),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "a"
      ..Pattern = ".H"
      ..Message = TextErrorMessages.MismatchedCharacter
      ..Parameters.addAll(['.']),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "a"
      ..Pattern = "\\'"
      ..Message = TextErrorMessages.EscapedCharacterMismatch
      ..Parameters.addAll(['\'']),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "axc"
      ..Pattern = "'abc'"
      ..Message = TextErrorMessages.QuotedStringMismatch,
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "z"
      ..Pattern = "%*"
      ..Message = TextErrorMessages.MismatchedCharacter
      ..Parameters.addAll(['*']),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "24"
      ..Pattern = "HH"
      ..Message = TextErrorMessages.FieldValueOutOfRange
      ..Parameters.addAll([24, 'H', 'Offset']),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "60"
      ..Pattern = "mm"
      ..Message = TextErrorMessages.FieldValueOutOfRange
      ..Parameters.addAll([60, 'm', 'Offset']),
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "60"
      ..Pattern = "ss"
      ..Message = TextErrorMessages.FieldValueOutOfRange
      ..Parameters.addAll([60, 's', 'Offset']),
    new Data(Offset.zero)
      ..Text = "+12"
      ..Pattern = "-HH"
      ..Message = TextErrorMessages.PositiveSignInvalid,
  ];

  /// <summary>
  /// Common test data for both formatting and parsing. A test should be placed here unless is truly
  /// cannot be run both ways. This ensures that as many round-trip type tests are performed as possible.
  /// </summary>
  @internal final List<Data> FormatAndParseData = [
/*XXX*/ new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "."
      ..Pattern = "%.", // decimal separator
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = ":"
      ..Pattern = "%:", // date separator
/*XXX*/ new Data(Offset.zero)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "."
      ..Pattern = "%.", // decimal separator (always period)
    new Data(Offset.zero)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "."
      ..Pattern = "%:", // date separator
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "H"
      ..Pattern = "\\H",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "HHss"
      ..Pattern = "'HHss'",
    new Data.hms(0, 0, 12)
      ..Culture = TestCultures.EnUs
      ..Text = "12"
      ..Pattern = "%s",
    new Data.hms(0, 0, 12)
      ..Culture = TestCultures.EnUs
      ..Text = "12"
      ..Pattern = "ss",
    new Data.hms(0, 0, 2)
      ..Culture = TestCultures.EnUs
      ..Text = "2"
      ..Pattern = "%s",
    new Data.hms(0, 12, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "12"
      ..Pattern = "%m",
    new Data.hms(0, 12, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "12"
      ..Pattern = "mm",
    new Data.hms(0, 2, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "2"
      ..Pattern = "%m",

    new Data.hms(12, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "12"
      ..Pattern = "%H",
    new Data.hms(12, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "12"
      ..Pattern = "HH",
    new Data.hms(2, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "2"
      ..Pattern = "%H",
    new Data.hms(2, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "2"
      ..Pattern = "%H",

    // Standard patterns with punctuation...
    new Data.hms(5, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "+05"
      ..Pattern = "G",
    new Data.hms(5, 12, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "+05:12"
      ..Pattern = "G",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.EnUs
      ..Text = "+05:12:34"
      ..Pattern = "G",
    new Data.hms(5, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "+05"
      ..Pattern = "g",
    new Data.hms(5, 12, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "+05:12"
      ..Pattern = "g",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.EnUs
      ..Text = "+05:12:34"
      ..Pattern = "g",
    new Data(Offset.minValue)
      ..Culture = TestCultures.EnUs
      ..Text = "-18"
      ..Pattern = "g",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "Z"
      ..Pattern = "G",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "+00"
      ..Pattern = "g",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "+00"
      ..Pattern = "s",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "+00:00"
      ..Pattern = "m",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "+00:00:00"
      ..Pattern = "l",
    new Data.hms(5, 0, 0)
      ..Culture = TestCultures.FrFr
      ..Text = "+05"
      ..Pattern = "g",
    new Data.hms(5, 12, 0)
      ..Culture = TestCultures.FrFr
      ..Text = "+05:12"
      ..Pattern = "g",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.FrFr
      ..Text = "+05:12:34"
      ..Pattern = "g",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.FrFr
      ..Text = "+18"
      ..Pattern = "g",
    new Data(Offset.minValue)
      ..Culture = TestCultures.FrFr
      ..Text = "-18"
      ..Pattern = "g",
    new Data.hms(5, 0, 0)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "+05"
      ..Pattern = "g",
    new Data.hms(5, 12, 0)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "+05.12"
      ..Pattern = "g",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "+05.12.34"
      ..Pattern = "g",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "+18"
      ..Pattern = "g",
    new Data(Offset.minValue)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "-18"
      ..Pattern = "g",

    // Standard patterns without punctuation
    new Data.hms(5, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "+05"
      ..Pattern = "I",
    new Data.hms(5, 12, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "+0512"
      ..Pattern = "I",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.EnUs
      ..Text = "+051234"
      ..Pattern = "I",
    new Data.hms(5, 0, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "+05"
      ..Pattern = "i",
    new Data.hms(5, 12, 0)
      ..Culture = TestCultures.EnUs
      ..Text = "+0512"
      ..Pattern = "i",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.EnUs
      ..Text = "+051234"
      ..Pattern = "i",
    new Data(Offset.minValue)
      ..Culture = TestCultures.EnUs
      ..Text = "-18"
      ..Pattern = "i",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "Z"
      ..Pattern = "I",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "+00"
      ..Pattern = "i",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "+00"
      ..Pattern = "S",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "+0000"
      ..Pattern = "M",
    new Data(Offset.zero)
      ..Culture = TestCultures.EnUs
      ..Text = "+000000"
      ..Pattern = "L",
    new Data.hms(5, 0, 0)
      ..Culture = TestCultures.FrFr
      ..Text = "+05"
      ..Pattern = "i",
    new Data.hms(5, 12, 0)
      ..Culture = TestCultures.FrFr
      ..Text = "+0512"
      ..Pattern = "i",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.FrFr
      ..Text = "+051234"
      ..Pattern = "i",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.FrFr
      ..Text = "+18"
      ..Pattern = "i",
    new Data(Offset.minValue)
      ..Culture = TestCultures.FrFr
      ..Text = "-18"
      ..Pattern = "i",
    new Data.hms(5, 0, 0)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "+05"
      ..Pattern = "i",
    new Data.hms(5, 12, 0)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "+0512"
      ..Pattern = "i",
    new Data.hms(5, 12, 34)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "+051234"
      ..Pattern = "i",
    new Data(Offset.maxValue)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "+18"
      ..Pattern = "i",
    new Data(Offset.minValue)
      ..Culture = TestCultures.DotTimeSeparator
      ..Text = "-18"
      ..Pattern = "i",

    // Explicit patterns
    new Data.hms(0, 30, 0, true)
      ..Culture = TestCultures.EnUs
      ..Text = "-00:30"
      ..Pattern = "+HH:mm",
    new Data.hms(0, 30, 0, true)
      ..Culture = TestCultures.EnUs
      ..Text = "-00:30"
      ..Pattern = "-HH:mm",
    new Data.hms(0, 30, 0, false)
      ..Culture = TestCultures.EnUs
      ..Text = "00:30"
      ..Pattern = "-HH:mm",

    // Z-prefixes
    new Data(Offset.zero)
      ..Text = "Z"
      ..Pattern = "Z+HH:mm:ss",
    new Data.hms(5, 12, 34)
      ..Text = "+05:12:34"
      ..Pattern = "Z+HH:mm:ss",
    new Data.hms(5, 12)
      ..Text = "+05:12"
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
  void ParseNull() => AssertParseNull(OffsetPattern.GeneralInvariant);

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
      var pattern = OffsetPattern.CreateWithCurrentCulture("H:mm");
      var text = pattern.Format(new Offset.fromHoursAndMinutes(1, 30));
      expect("1.30", text);
    }
  }
}

/// <summary>
/// A container for test data for formatting and parsing <see cref="Offset" /> objects.
/// </summary>
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
      OffsetPattern.CreateWithInvariantCulture(super.Pattern)
          .WithCulture(Culture);

  @internal
  @override
  IPartialPattern<Offset> CreatePartialPattern() =>
      OffsetPattern
          .CreateWithInvariantCulture(super.Pattern)
          .WithCulture(Culture)
          .UnderlyingPattern;
}


