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
class AnnualDatePatternTest extends PatternTestBase<AnnualDate> {
  @internal final List<Data> InvalidPatternData = [
    new Data()
      ..Pattern = ""
      ..Message = TextErrorMessages.FormatStringEmpty,
    new Data()
      ..Pattern = "!"
      ..Message = TextErrorMessages.UnknownStandardFormat
      ..Parameters.addAll(['!', 'AnnualDate']),
    new Data()
      ..Pattern = "%"
      ..Message = TextErrorMessages.UnknownStandardFormat
      ..Parameters.addAll([ '%', 'AnnualDate']),
    new Data()
      ..Pattern = "\\"
      ..Message = TextErrorMessages.UnknownStandardFormat
      ..Parameters.addAll([ '\\', 'AnnualDate']),
    new Data()
      ..Pattern = "%%"
      ..Message = TextErrorMessages.PercentDoubled,
    new Data()
      ..Pattern = "%\\"
      ..Message = TextErrorMessages.EscapeAtEndOfString,
    new Data()
      ..Pattern = "MMMMM"
      ..Message = TextErrorMessages.RepeatCountExceeded
      ..Parameters.addAll([ 'M', 4]),
    new Data()
      ..Pattern = "ddd"
      ..Message = TextErrorMessages.RepeatCountExceeded
      ..Parameters.addAll([ 'd', 2]),
    new Data()
      ..Pattern = "M%"
      ..Message = TextErrorMessages.PercentAtEndOfString,
    new Data()
      ..Pattern = "'qwe"
      ..Message = TextErrorMessages.MissingEndQuote
      ..Parameters.addAll([ '\'']),
    new Data()
      ..Pattern = "'qwe\\"
      ..Message = TextErrorMessages.EscapeAtEndOfString,
    new Data()
      ..Pattern = "'qwe\\'"
      ..Message = TextErrorMessages.MissingEndQuote
      ..Parameters.addAll([ '\'']),

    // Common typo (m doesn't mean months)
    new Data()
      ..Pattern = "mm-dd"
      ..Message = TextErrorMessages.UnquotedLiteral
      ..Parameters.addAll([ 'm']),
    // T isn't valid in a date pattern
    new Data()
      ..Pattern = "MM-ddT00:00:00"
      ..Message = TextErrorMessages.UnquotedLiteral
      ..Parameters.addAll([ 'T'])
  ];

  @internal List<Data> ParseFailureData = [
    new Data()
      ..Pattern = "MM dd MMMM"
      ..Text = "10 09 January"
      ..Message = TextErrorMessages.InconsistentMonthTextValue,
    new Data()
      ..Pattern = "MM dd MMMM"
      ..Text = "10 09 FooBar"
      ..Message = TextErrorMessages.MismatchedText
      ..Parameters.addAll(['M']),
    new Data()
      ..Pattern = "MM/dd"
      ..Text = "02-29"
      ..Message = TextErrorMessages.DateSeparatorMismatch,
    // Don't match a short name against a long pattern
    new Data()
      ..Pattern = "MMMM dd"
      ..Text = "Oct 09"
      ..Message = TextErrorMessages.MismatchedText
      ..Parameters.addAll(['M']),
    // Or vice versa... although this time we match the "Oct" and then fail as we're expecting a space
    new Data()
      ..Pattern = "MMM dd"
      ..Text = "October 09"
      ..Message = TextErrorMessages.MismatchedCharacter
      ..Parameters.addAll([' ']),

    // Invalid month, day
    new Data()
      ..Pattern = "MM dd"
      ..Text = "15 29"
      ..Message = TextErrorMessages.IsoMonthOutOfRange
      ..Parameters.addAll([ 15]),
    new Data()
      ..Pattern = "MM dd"
      ..Text = "02 35"
      ..Message = TextErrorMessages.DayOfMonthOutOfRangeNoYear
      ..Parameters.addAll([ 35, 2])
  ];

  @internal List<Data> ParseOnlyData = [
    // Month parsing should be case-insensitive
    new Data.monthDay(10, 3)
      ..Pattern = "MMM dd"
      ..Text = "OcT 03",
    new Data.monthDay(10, 3)
      ..Pattern = "MMMM dd"
      ..Text = "OcToBeR 03",

    // Genitive name is an extension of the non-genitive name; parse longer first.
    new Data.monthDay(1, 10)
      ..Pattern = "MMMM dd"
      ..Text = "MonthName-Genitive 10"
      ..Culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
    new Data.monthDay(1, 10)
      ..Pattern = "MMMM dd"
      ..Text = "MonthName 10"
      ..Culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
    new Data.monthDay(1, 10)
      ..Pattern = "MMM dd"
      ..Text = "MN-Gen 10"
      ..Culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
    new Data.monthDay(1, 10)
      ..Pattern = "MMM dd"
      ..Text = "MN 10"
      ..Culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
  ];

  @internal List<Data> FormatOnlyData = [];

  @internal List<Data> FormatAndParseData = [
    // Standard patterns
    new Data.monthDay(10, 20)
      ..Pattern = "G"
      ..Text = "10-20",

    // Custom patterns
    new Data.monthDay(10, 3)
      ..Pattern = "MM/dd"
      ..Text = "10/03",
    new Data.monthDay(10, 3)
      ..Pattern = "MM/dd"
      ..Text = "10-03"
      ..Culture = TestCultures.FrCa,
    new Data.monthDay(10, 3)
      ..Pattern = "MMdd"
      ..Text = "1003",
    new Data.monthDay(7, 3)
      ..Pattern = "M d"
      ..Text = "7 3",

    // Template value provides the month when we only specify the day
    new Data.monthDay(5, 10)
      ..Pattern = "dd"
      ..Text = "10"
      ..Template = new AnnualDate(5, 20),
    // Template value provides the day when we only specify the month
    new Data.monthDay(10, 20)
      ..Pattern = "MM"
      ..Text = "10"
      ..Template = new AnnualDate(5, 20),

    // When we parse in all of the below tests, we'll use the month and day-of-month if it's provided;
    // the template value is specified to allow simple roundtripping.
    // Non-genitive month name when there's no "day of month"
    new Data.monthDay(1, 3)
      ..Pattern = "MMMM"
      ..Text = "FullNonGenName"
      ..Culture = TestCultures.GenitiveNameTestCulture
      ..Template = new AnnualDate(5, 3),
    new Data.monthDay(1, 3)
      ..Pattern = "MMM"
      ..Text = "AbbrNonGenName"
      ..Culture = TestCultures.GenitiveNameTestCulture
      ..Template = new AnnualDate(5, 3),
    // Genitive month name when the pattern includes "day of month"
    new Data.monthDay(1, 3)
      ..Pattern = "MMMM dd"
      ..Text = "FullGenName 03"
      ..Culture = TestCultures.GenitiveNameTestCulture
      ..Template = new AnnualDate(5, 3),
    // TODO: Check whether or not this is actually appropriate
    new Data.monthDay(1, 3)
      ..Pattern = "MMM dd"
      ..Text = "AbbrGenName 03"
      ..Culture = TestCultures.GenitiveNameTestCulture
      ..Template = new AnnualDate(5, 3),

    // Month handling with both text and numeric
    new Data.monthDay(10, 9)
      ..Pattern = "MMMM dd MM"
      ..Text = "October 09 10",
    new Data.monthDay(10, 9)
      ..Pattern = "MMM dd MM"
      ..Text = "Oct 09 10",
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);
  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);

  @Test()
  Future CreateWithCurrentCulture() async
  {
    var date = new AnnualDate(8, 23);
    // using (CultureSaver.SetTestCultures(TestCultures.FrFr))
    CultureInfo.currentCulture = TestCultures.getCulture('fr-FR');
    var pattern = AnnualDatePattern.CreateWithCurrentCulture("MM/dd");
    expect("08/23", pattern.format(date));

    // using (CultureSaver.SetTestCultures(TestCultures.FrCa))
    CultureInfo.currentCulture = TestCultures.getCulture('fr-CA');
    pattern = AnnualDatePattern.CreateWithCurrentCulture("MM/dd");
    expect("08-23", pattern.format(date));
  }

  @TestCase(const ["fr-FR", "08/23"])
  @TestCase(const ["fr-CA", "08-23"])
  Future CreateWithCulture(String cultureId, String expected) async
  {
    var date = new AnnualDate(8, 23);
    var culture = TestCultures.getCulture(cultureId);
    var pattern = AnnualDatePattern.Create3("MM/dd", culture);
    expect(expected, pattern.format(date));
  }

  @TestCase(const ["fr-FR", "08/23"])
  @TestCase(const ["fr-CA", "08-23"])
  Future CreateWithCultureAndTemplateValue(String cultureId, String expected) async
  {
    var date = new AnnualDate(8, 23);
    var template = new AnnualDate(5, 3);
    var culture = TestCultures.getCulture(cultureId);
    // Check the culture is still used
    var pattern1 = AnnualDatePattern.Create2("MM/dd", culture, template);
    expect(expected, pattern1.format(date));
    // And the template value
    var pattern2 = AnnualDatePattern.Create2("MM", culture, template);
    var parsed = pattern2
        .parse("08")
        .Value;
    expect(new AnnualDate(8, 3), parsed);
  }

  @Test()
  void ParseNull() => AssertParseNull(AnnualDatePattern.Iso);
}

/*sealed*/ class Data extends PatternTestData<AnnualDate> {
  // Default to January 1st
  @override AnnualDate get DefaultTemplate => AnnualDatePattern.DefaultTemplateValue;

  /// Initializes a new instance of the [Data] class.
  ///
  /// [value]: The value.
  Data([AnnualDate value = null]) : super(value ?? AnnualDatePattern.DefaultTemplateValue)
  {
  }

  Data.monthDay(int month, int day) : super(new AnnualDate(month, day));

  @internal
  @override
  IPattern<AnnualDate> CreatePattern() =>
      AnnualDatePattern.CreateWithInvariantCulture(super.Pattern)
          .WithTemplateValue(Template)
          .WithCulture(Culture);
}

