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
class AnnualDatePatternTest extends PatternTestBase<AnnualDate> {
  @internal final List<Data> InvalidPatternData = [
    new Data()
      ..Pattern = ""
      ..Message = TextErrorMessages.formatStringEmpty,
    new Data()
      ..Pattern = "!"
      ..Message = TextErrorMessages.unknownStandardFormat
      ..Parameters.addAll(['!', 'AnnualDate']),
    new Data()
      ..Pattern = "%"
      ..Message = TextErrorMessages.unknownStandardFormat
      ..Parameters.addAll([ '%', 'AnnualDate']),
    new Data()
      ..Pattern = "\\"
      ..Message = TextErrorMessages.unknownStandardFormat
      ..Parameters.addAll([ '\\', 'AnnualDate']),
    new Data()
      ..Pattern = "%%"
      ..Message = TextErrorMessages.percentDoubled,
    new Data()
      ..Pattern = "%\\"
      ..Message = TextErrorMessages.escapeAtEndOfString,
    new Data()
      ..Pattern = "MMMMM"
      ..Message = TextErrorMessages.repeatCountExceeded
      ..Parameters.addAll([ 'M', 4]),
    new Data()
      ..Pattern = "ddd"
      ..Message = TextErrorMessages.repeatCountExceeded
      ..Parameters.addAll([ 'd', 2]),
    new Data()
      ..Pattern = "M%"
      ..Message = TextErrorMessages.percentAtEndOfString,
    new Data()
      ..Pattern = "'qwe"
      ..Message = TextErrorMessages.missingEndQuote
      ..Parameters.addAll([ '\'']),
    new Data()
      ..Pattern = "'qwe\\"
      ..Message = TextErrorMessages.escapeAtEndOfString,
    new Data()
      ..Pattern = "'qwe\\'"
      ..Message = TextErrorMessages.missingEndQuote
      ..Parameters.addAll([ '\'']),

    // Common typo (m doesn't mean months)
    new Data()
      ..Pattern = "mm-dd"
      ..Message = TextErrorMessages.unquotedLiteral
      ..Parameters.addAll([ 'm']),
    // T isn't valid in a date pattern
    new Data()
      ..Pattern = "MM-ddT00:00:00"
      ..Message = TextErrorMessages.unquotedLiteral
      ..Parameters.addAll([ 'T'])
  ];

  @internal List<Data> ParseFailureData = [
    new Data()
      ..Pattern = "MM dd MMMM"
      ..text = "10 09 January"
      ..Message = TextErrorMessages.inconsistentMonthTextValue,
    new Data()
      ..Pattern = "MM dd MMMM"
      ..text = "10 09 FooBar"
      ..Message = TextErrorMessages.mismatchedText
      ..Parameters.addAll(['M']),
    new Data()
      ..Pattern = "MM/dd"
      ..text = "02-29"
      ..Message = TextErrorMessages.dateSeparatorMismatch,
    // Don't match a short name against a long pattern
    new Data()
      ..Pattern = "MMMM dd"
      ..text = "Oct 09"
      ..Message = TextErrorMessages.mismatchedText
      ..Parameters.addAll(['M']),
    // Or vice versa... although this time we match the "Oct" and then fail as we're expecting a space
    new Data()
      ..Pattern = "MMM dd"
      ..text = "October 09"
      ..Message = TextErrorMessages.mismatchedCharacter
      ..Parameters.addAll([' ']),

    // Invalid month, day
    new Data()
      ..Pattern = "MM dd"
      ..text = "15 29"
      ..Message = TextErrorMessages.isoMonthOutOfRange
      ..Parameters.addAll([ 15]),
    new Data()
      ..Pattern = "MM dd"
      ..text = "02 35"
      ..Message = TextErrorMessages.dayOfMonthOutOfRangeNoYear
      ..Parameters.addAll([ 35, 2])
  ];

  @internal List<Data> ParseOnlyData = [
    // Month parsing should be case-insensitive
    new Data.monthDay(10, 3)
      ..Pattern = "MMM dd"
      ..text = "OcT 03",
    new Data.monthDay(10, 3)
      ..Pattern = "MMMM dd"
      ..text = "OcToBeR 03",

    // Genitive name is an extension of the non-genitive name; parse longer first.
    new Data.monthDay(1, 10)
      ..Pattern = "MMMM dd"
      ..text = "MonthName-Genitive 10"
      ..Culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
    new Data.monthDay(1, 10)
      ..Pattern = "MMMM dd"
      ..text = "MonthName 10"
      ..Culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
    new Data.monthDay(1, 10)
      ..Pattern = "MMM dd"
      ..text = "MN-Gen 10"
      ..Culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
    new Data.monthDay(1, 10)
      ..Pattern = "MMM dd"
      ..text = "MN 10"
      ..Culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
  ];

  @internal List<Data> FormatOnlyData = [];

  @internal List<Data> FormatAndParseData = [
    // Standard patterns
    new Data.monthDay(10, 20)
      ..Pattern = "G"
      ..text = "10-20",

    // Custom patterns
    new Data.monthDay(10, 3)
      ..Pattern = "MM/dd"
      ..text = "10/03",
    new Data.monthDay(10, 3)
      ..Pattern = "MM/dd"
      ..text = "10-03"
      ..Culture = TestCultures.FrCa,
    new Data.monthDay(10, 3)
      ..Pattern = "MMdd"
      ..text = "1003",
    new Data.monthDay(7, 3)
      ..Pattern = "M d"
      ..text = "7 3",

    // Template value provides the month when we only specify the day
    new Data.monthDay(5, 10)
      ..Pattern = "dd"
      ..text = "10"
      ..Template = new AnnualDate(5, 20),
    // Template value provides the day when we only specify the month
    new Data.monthDay(10, 20)
      ..Pattern = "MM"
      ..text = "10"
      ..Template = new AnnualDate(5, 20),

    // When we parse in all of the below tests, we'll use the month and day-of-month if it's provided;
    // the template value is specified to allow simple roundtripping.
    // Non-genitive month name when there's no "day of month"
    new Data.monthDay(1, 3)
      ..Pattern = "MMMM"
      ..text = "FullNonGenName"
      ..Culture = TestCultures.GenitiveNameTestCulture
      ..Template = new AnnualDate(5, 3),
    new Data.monthDay(1, 3)
      ..Pattern = "MMM"
      ..text = "AbbrNonGenName"
      ..Culture = TestCultures.GenitiveNameTestCulture
      ..Template = new AnnualDate(5, 3),
    // Genitive month name when the pattern includes "day of month"
    new Data.monthDay(1, 3)
      ..Pattern = "MMMM dd"
      ..text = "FullGenName 03"
      ..Culture = TestCultures.GenitiveNameTestCulture
      ..Template = new AnnualDate(5, 3),
    // TODO: Check whether or not this is actually appropriate
    new Data.monthDay(1, 3)
      ..Pattern = "MMM dd"
      ..text = "AbbrGenName 03"
      ..Culture = TestCultures.GenitiveNameTestCulture
      ..Template = new AnnualDate(5, 3),

    // Month handling with both text and numeric
    new Data.monthDay(10, 9)
      ..Pattern = "MMMM dd MM"
      ..text = "October 09 10",
    new Data.monthDay(10, 9)
      ..Pattern = "MMM dd MM"
      ..text = "Oct 09 10",
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);
  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);

  @Test()
  Future CreateWithCurrentCulture() async
  {
    var date = new AnnualDate(8, 23);
    // using (CultureSaver.SetTestCultures(TestCultures.FrFr))
    CultureInfo.currentCulture = TestCultures.getCulture('fr-FR');
    var pattern = AnnualDatePattern.createWithCurrentCulture("MM/dd");
    expect("08/23", pattern.format(date));

    // using (CultureSaver.SetTestCultures(TestCultures.FrCa))
    CultureInfo.currentCulture = TestCultures.getCulture('fr-CA');
    pattern = AnnualDatePattern.createWithCurrentCulture("MM/dd");
    expect("08-23", pattern.format(date));
  }

  @TestCase(const ["fr-FR", "08/23"])
  @TestCase(const ["fr-CA", "08-23"])
  Future CreateWithCulture(String cultureId, String expected) async
  {
    var date = new AnnualDate(8, 23);
    var culture = TestCultures.getCulture(cultureId);
    var pattern = AnnualDatePattern.createWithCulture("MM/dd", culture);
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
    var pattern1 = AnnualDatePattern.createWithCulture("MM/dd", culture, template);
    expect(expected, pattern1.format(date));
    // And the template value
    var pattern2 = AnnualDatePattern.createWithCulture("MM", culture, template);
    var parsed = pattern2
        .parse("08")
        .value;
    expect(new AnnualDate(8, 3), parsed);
  }

  @Test()
  void ParseNull() => AssertParseNull(AnnualDatePattern.iso);
}

class Data extends PatternTestData<AnnualDate> {
  // Default to January 1st
  @override AnnualDate get DefaultTemplate => AnnualDatePatterns.defaultTemplateValue;

  /// Initializes a new instance of the [Data] class.
  ///
  /// [value]: The value.
  Data([AnnualDate value = null]) : super(value ?? AnnualDatePatterns.defaultTemplateValue)
  {
  }

  Data.monthDay(int month, int day) : super(new AnnualDate(month, day));

  @internal
  @override
  IPattern<AnnualDate> CreatePattern() =>
      AnnualDatePattern.createWithInvariantCulture(super.Pattern)
          .withTemplateValue(Template)
          .withCulture(Culture);
}

