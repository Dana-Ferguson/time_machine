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
    Data()
      ..pattern = ''
      ..message = TextErrorMessages.formatStringEmpty,
    Data()
      ..pattern = '!'
      ..message = TextErrorMessages.unknownStandardFormat
      ..parameters.addAll(['!', 'AnnualDate']),
    Data()
      ..pattern = '%'
      ..message = TextErrorMessages.unknownStandardFormat
      ..parameters.addAll([ '%', 'AnnualDate']),
    Data()
      ..pattern = "\\"
      ..message = TextErrorMessages.unknownStandardFormat
      ..parameters.addAll([ '\\', 'AnnualDate']),
    Data()
      ..pattern = '%%'
      ..message = TextErrorMessages.percentDoubled,
    Data()
      ..pattern = "%\\"
      ..message = TextErrorMessages.escapeAtEndOfString,
    Data()
      ..pattern = 'MMMMM'
      ..message = TextErrorMessages.repeatCountExceeded
      ..parameters.addAll([ 'M', 4]),
    Data()
      ..pattern = 'ddd'
      ..message = TextErrorMessages.repeatCountExceeded
      ..parameters.addAll([ 'd', 2]),
    Data()
      ..pattern = 'M%'
      ..message = TextErrorMessages.percentAtEndOfString,
    Data()
      ..pattern = "'qwe"
      ..message = TextErrorMessages.missingEndQuote
      ..parameters.addAll([ '\'']),
    Data()
      ..pattern = "'qwe\\"
      ..message = TextErrorMessages.escapeAtEndOfString,
    Data()
      ..pattern = "'qwe\\'"
      ..message = TextErrorMessages.missingEndQuote
      ..parameters.addAll([ '\'']),

    // Common typo (m doesn't mean months)
    Data()
      ..pattern = 'mm-dd'
      ..message = TextErrorMessages.unquotedLiteral
      ..parameters.addAll([ 'm']),
    // T isn't valid in a date pattern
    Data()
      ..pattern = 'MM-ddT00:00:00'
      ..message = TextErrorMessages.unquotedLiteral
      ..parameters.addAll([ 'T'])
  ];

  @internal List<Data> ParseFailureData = [
    Data()
      ..pattern = 'MM dd MMMM'
      ..text = '10 09 January'
      ..message = TextErrorMessages.inconsistentMonthTextValue,
    Data()
      ..pattern = 'MM dd MMMM'
      ..text = '10 09 FooBar'
      ..message = TextErrorMessages.mismatchedText
      ..parameters.addAll(['M']),
    Data()
      ..pattern = 'MM/dd'
      ..text = '02-29'
      ..message = TextErrorMessages.dateSeparatorMismatch,
    // Don't match a short name against a long pattern
    Data()
      ..pattern = 'MMMM dd'
      ..text = 'Oct 09'
      ..message = TextErrorMessages.mismatchedText
      ..parameters.addAll(['M']),
    // Or vice versa... although this time we match the 'Oct' and then fail as we're expecting a space
    Data()
      ..pattern = 'MMM dd'
      ..text = 'October 09'
      ..message = TextErrorMessages.mismatchedCharacter
      ..parameters.addAll([' ']),

    // Invalid month, day
    Data()
      ..pattern = 'MM dd'
      ..text = '15 29'
      ..message = TextErrorMessages.isoMonthOutOfRange
      ..parameters.addAll([ 15]),
    Data()
      ..pattern = 'MM dd'
      ..text = '02 35'
      ..message = TextErrorMessages.dayOfMonthOutOfRangeNoYear
      ..parameters.addAll([ 35, 2])
  ];

  @internal List<Data> ParseOnlyData = [
    // Month parsing should be case-insensitive
    Data.monthDay(10, 3)
      ..pattern = 'MMM dd'
      ..text = 'OcT 03',
    Data.monthDay(10, 3)
      ..pattern = 'MMMM dd'
      ..text = 'OcToBeR 03',

    // Genitive name is an extension of the non-genitive name; parse longer first.
    Data.monthDay(1, 10)
      ..pattern = 'MMMM dd'
      ..text = 'MonthName-Genitive 10'
      ..culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
    Data.monthDay(1, 10)
      ..pattern = 'MMMM dd'
      ..text = 'MonthName 10'
      ..culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
    Data.monthDay(1, 10)
      ..pattern = 'MMM dd'
      ..text = 'MN-Gen 10'
      ..culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
    Data.monthDay(1, 10)
      ..pattern = 'MMM dd'
      ..text = 'MN 10'
      ..culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
  ];

  @internal List<Data> FormatOnlyData = [];

  @internal List<Data> FormatAndParseData = [
    // Standard patterns
    Data.monthDay(10, 20)
      ..pattern = 'G'
      ..text = '10-20',

    // Custom patterns
    Data.monthDay(10, 3)
      ..pattern = 'MM/dd'
      ..text = '10/03',
    Data.monthDay(10, 3)
      ..pattern = 'MM/dd'
      ..text = '10-03'
      ..culture = TestCultures.FrCa,
    Data.monthDay(10, 3)
      ..pattern = 'MMdd'
      ..text = '1003',
    Data.monthDay(7, 3)
      ..pattern = 'M d'
      ..text = '7 3',

    // Template value provides the month when we only specify the day
    Data.monthDay(5, 10)
      ..pattern = 'dd'
      ..text = '10'
      ..template = AnnualDate(5, 20),
    // Template value provides the day when we only specify the month
    Data.monthDay(10, 20)
      ..pattern = 'MM'
      ..text = '10'
      ..template = AnnualDate(5, 20),

    // When we parse in all of the below tests, we'll use the month and day-of-month if it's provided;
    // the template value is specified to allow simple roundtripping.
    // Non-genitive month name when there's no "day of month"
    Data.monthDay(1, 3)
      ..pattern = 'MMMM'
      ..text = 'FullNonGenName'
      ..culture = TestCultures.GenitiveNameTestCulture
      ..template = AnnualDate(5, 3),
    Data.monthDay(1, 3)
      ..pattern = 'MMM'
      ..text = 'AbbrNonGenName'
      ..culture = TestCultures.GenitiveNameTestCulture
      ..template = AnnualDate(5, 3),
    // Genitive month name when the pattern includes 'day of month'
    Data.monthDay(1, 3)
      ..pattern = 'MMMM dd'
      ..text = 'FullGenName 03'
      ..culture = TestCultures.GenitiveNameTestCulture
      ..template = AnnualDate(5, 3),
    // TODO: Check whether or not this is actually appropriate
    Data.monthDay(1, 3)
      ..pattern = 'MMM dd'
      ..text = 'AbbrGenName 03'
      ..culture = TestCultures.GenitiveNameTestCulture
      ..template = AnnualDate(5, 3),

    // Month handling with both text and numeric
    Data.monthDay(10, 9)
      ..pattern = 'MMMM dd MM'
      ..text = 'October 09 10',
    Data.monthDay(10, 9)
      ..pattern = 'MMM dd MM'
      ..text = 'Oct 09 10',
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);
  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);

  @Test()
  Future CreateWithCurrentCulture() async
  {
    var date = AnnualDate(8, 23);
    // using (CultureSaver.SetTestCultures(TestCultures.FrFr))
    Culture.current = TestCultures.getCulture('fr-FR')!;
    var pattern = AnnualDatePattern.createWithCurrentCulture('MM/dd');
    expect('08/23', pattern.format(date));

    // using (CultureSaver.SetTestCultures(TestCultures.FrCa))
    Culture.current = TestCultures.getCulture('fr-CA')!;
    pattern = AnnualDatePattern.createWithCurrentCulture('MM/dd');
    expect('08-23', pattern.format(date));
  }

  @TestCase(['fr-FR', "08/23"])
  @TestCase(['fr-CA', "08-23"])
  Future CreateWithCulture(String cultureId, String expected) async
  {
    var date = AnnualDate(8, 23);
    var culture = TestCultures.getCulture(cultureId)!;
    var pattern = AnnualDatePattern.createWithCulture('MM/dd', culture);
    expect(expected, pattern.format(date));
  }

  @TestCase(['fr-FR', "08/23"])
  @TestCase(['fr-CA', "08-23"])
  Future CreateWithCultureAndTemplateValue(String cultureId, String expected) async
  {
    var date = AnnualDate(8, 23);
    var template = AnnualDate(5, 3);
    var culture = TestCultures.getCulture(cultureId)!;
    // Check the culture is still used
    var pattern1 = AnnualDatePattern.createWithCulture('MM/dd', culture, template);
    expect(expected, pattern1.format(date));
    // And the template value
    var pattern2 = AnnualDatePattern.createWithCulture('MM', culture, template);
    var parsed = pattern2
        .parse('08')
        .value;
    expect(AnnualDate(8, 3), parsed);
  }

  // @Test()
  // void ParseNull() => AssertParseNull(AnnualDatePattern.iso);
}

class Data extends PatternTestData<AnnualDate> {
  // Default to January 1st
  @override AnnualDate get defaultTemplate => AnnualDatePatterns.defaultTemplateValue;

  /// Initializes a new instance of the [Data] class.
  ///
  /// [value]: The value.
  Data([AnnualDate? value]) : super(value ?? AnnualDatePatterns.defaultTemplateValue);

  Data.monthDay(int month, int day) : super(AnnualDate(month, day));

  @internal
  @override
  IPattern<AnnualDate> CreatePattern() =>
      AnnualDatePattern.createWithInvariantCulture(super.pattern)
          .withTemplateValue(template)
          .withCulture(culture);
}

