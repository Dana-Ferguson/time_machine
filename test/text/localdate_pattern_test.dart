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
class LocalDatePatternTest extends PatternTestBase<LocalDate> {
  @private
  final LocalDate SampleLocalDate = LocalDate(1976, 6, 19);

  @internal
  final List<Data> InvalidPatternData = [
    Data()
      ..pattern = ''
      ..message = TextErrorMessages.formatStringEmpty,
    Data()
      ..pattern = '!'
      ..message = TextErrorMessages.unknownStandardFormat
      ..parameters.addAll(['!', 'LocalDate']),
    Data()
      ..pattern = '%'
      ..message = TextErrorMessages.unknownStandardFormat
      ..parameters.addAll(['%', 'LocalDate']),
    Data()
      ..pattern = "\\"
      ..message = TextErrorMessages.unknownStandardFormat
      ..parameters.addAll(['\\', 'LocalDate']),
    Data()
      ..pattern = '%%'
      ..message = TextErrorMessages.percentDoubled,
    Data()
      ..pattern = "%\\"
      ..message = TextErrorMessages.escapeAtEndOfString,
    Data()
      ..pattern = 'MMMMM'
      ..message = TextErrorMessages.repeatCountExceeded
      ..parameters.addAll(['M', 4]),
    Data()
      ..pattern = 'ddddd'
      ..message = TextErrorMessages.repeatCountExceeded
      ..parameters.addAll(['d', 4]),
    Data()
      ..pattern = 'M%'
      ..message = TextErrorMessages.percentAtEndOfString,
    Data()
      ..pattern = 'yyyyy'
      ..message = TextErrorMessages.repeatCountExceeded
      ..parameters.addAll(['y', 4]),
    Data()
      ..pattern = 'uuuuu'
      ..message = TextErrorMessages.repeatCountExceeded
      ..parameters.addAll(['u', 4]),
    Data()
      ..pattern = 'ggg'
      ..message = TextErrorMessages.repeatCountExceeded
      ..parameters.addAll(['g', 2]),
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
    // Note incorrect use of 'u' (year) instead of "y" (year of era)
    Data()
      ..pattern = 'dd MM uuuu gg'
      ..message = TextErrorMessages.eraWithoutYearOfEra,
    // Era specifier and calendar specifier in the same pattern.
    Data()
      ..pattern = 'dd MM yyyy gg c'
      ..message = TextErrorMessages.calendarAndEra,

    // Invalid patterns directly after the yyyy specifier. This will detect the issue early, but then
    // continue and reject it in the normal path.
    Data()
      ..pattern = "yyyy'"
      ..message = TextErrorMessages.missingEndQuote
      ..parameters.addAll(['\'']),
    Data()
      ..pattern = "yyyy\\"
      ..message = TextErrorMessages.escapeAtEndOfString,

    // Common typo, which is caught in 2.0...
    Data()
      ..pattern = 'yyyy-mm-dd'
      ..message = TextErrorMessages.unquotedLiteral
      ..parameters.addAll(['m']),
    // T isn't valid in a date pattern
    Data()
      ..pattern = 'yyyy-MM-ddT00:00:00'
      ..message = TextErrorMessages.unquotedLiteral
      ..parameters.addAll(['T']),

    // These became invalid in v2.0, when we decided that y and yyy weren't sensible.
    Data()
      ..pattern = 'y M d'
      ..message = TextErrorMessages.invalidRepeatCount
      ..parameters.addAll(['y', 1]),
    Data()
      ..pattern = 'yyy M d'
      ..message = TextErrorMessages.invalidRepeatCount
      ..parameters.addAll(['y', 3]),
  ];

  @internal
  List<Data> ParseFailureData = [
    Data()
      ..pattern = 'yyyy gg'
      ..text = '2011 NodaEra'
      ..message = TextErrorMessages.mismatchedText
      ..parameters.addAll(['g']),
    Data()
      ..pattern = 'yyyy uuuu gg'
      ..text = '0010 0009 B.C.'
      ..message = TextErrorMessages.inconsistentValues2
      ..parameters.addAll(['g', 'u', 'LocalDate']),
    Data()
      ..pattern = 'yyyy MM dd dddd'
      ..text = '2011 10 09 Saturday'
      ..message = TextErrorMessages.inconsistentDayOfWeekTextValue,
    Data()
      ..pattern = 'yyyy MM dd ddd'
      ..text = '2011 10 09 Sat'
      ..message = TextErrorMessages.inconsistentDayOfWeekTextValue,
    Data()
      ..pattern = 'yyyy MM dd MMMM'
      ..text = '2011 10 09 January'
      ..message = TextErrorMessages.inconsistentMonthTextValue,
    Data()
      ..pattern = 'yyyy MM dd ddd'
      ..text = '2011 10 09 FooBar'
      ..message = TextErrorMessages.mismatchedText
      ..parameters.addAll(['d']),
    Data()
      ..pattern = 'yyyy MM dd dddd'
      ..text = '2011 10 09 FooBar'
      ..message = TextErrorMessages.mismatchedText
      ..parameters.addAll(['d']),
    Data()
      ..pattern = 'yyyy/MM/dd'
      ..text = '2011/02-29'
      ..message = TextErrorMessages.dateSeparatorMismatch,
    // Don't match a short name against a long pattern
    Data()
      ..pattern = 'yyyy MMMM dd'
      ..text = '2011 Oct 09'
      ..message = TextErrorMessages.mismatchedText
      ..parameters.addAll(['M']),
    // Or vice versa... although this time we match the 'Oct' and then fail as we're expecting a space
    Data()
      ..pattern = 'yyyy MMM dd'
      ..text = '2011 October 09'
      ..message = TextErrorMessages.mismatchedCharacter
      ..parameters.addAll([' ']),

    // Invalid year, year-of-era, month, day
    Data()
      ..pattern = 'yyyy MM dd'
      ..text = '0000 01 01'
      ..message = TextErrorMessages.fieldValueOutOfRange
      ..parameters.addAll([0, 'y', 'LocalDate']),
    Data()
      ..pattern = 'yyyy MM dd'
      ..text = '2011 15 29'
      ..message = TextErrorMessages.monthOutOfRange
      ..parameters.addAll([15, 2011]),
    Data()
      ..pattern = 'yyyy MM dd'
      ..text = '2011 02 35'
      ..message = TextErrorMessages.dayOfMonthOutOfRange
      ..parameters.addAll([35, 2, 2011]),
    // Year of era can't be negative...
    Data()
      ..pattern = 'yyyy MM dd'
      ..text = '-15 01 01'
      ..message = TextErrorMessages.unexpectedNegative,

    // Invalid leap years
    Data()
      ..pattern = 'yyyy MM dd'
      ..text = '2011 02 29'
      ..message = TextErrorMessages.dayOfMonthOutOfRange
      ..parameters.addAll([29, 2, 2011]),
    Data()
      ..pattern = 'yyyy MM dd'
      ..text = '1900 02 29'
      ..message = TextErrorMessages.dayOfMonthOutOfRange
      ..parameters.addAll([29, 2, 1900]),

    // Year of era and two-digit year, but they don't match
    Data()
      ..pattern = 'uuuu yy'
      ..text = '2011 10'
      ..message = TextErrorMessages.inconsistentValues2
      ..parameters.addAll(['y', 'u', 'LocalDate']),

    // Invalid calendar name
    Data()
      ..pattern = 'c yyyy MM dd'
      ..text = '2015 01 01'
      ..message = TextErrorMessages.noMatchingCalendarSystem,

    // Invalid year
    /* todo: @SkipMe.unimplemented()
    new Data()
      ..Template = new LocalDate.forCalendar(1, 1, 1, CalendarSystem.IslamicBcl)
      ..Pattern = 'uuuu'
      ..Text = '9999'
      ..Message = TextErrorMessages.FieldValueOutOfRange
      ..Parameters.addAll([9999, 'u', 'LocalDate']),
    new Data()
      ..Template = new LocalDate.forCalendar(1, 1, 1, CalendarSystem.IslamicBcl)
      ..Pattern = 'yyyy'
      ..Text = '9999'
      ..Message = TextErrorMessages.YearOfEraOutOfRange
      ..Parameters.addAll([9999, 'EH', "Hijri"]),*/

    // https://github.com/nodatime/nodatime/issues/414
    Data()
      ..pattern = 'yyyy-MM-dd'
      ..text = '1984-00-15'
      ..message = TextErrorMessages.fieldValueOutOfRange
      ..parameters.addAll([0, 'M', 'LocalDate']),
    Data()
      ..pattern = 'M/d/yyyy'
      ..text = '00/15/1984'
      ..message = TextErrorMessages.fieldValueOutOfRange
      ..parameters.addAll([0, 'M', 'LocalDate']),

    // Calendar ID parsing is now ordinal, case-sensitive
    Data.ymd(2011, 10, 9)
      ..pattern = 'yyyy MM dd c'
      ..text = '2011 10 09 iso'
      ..message = TextErrorMessages.noMatchingCalendarSystem,
  ];

  @internal
  List<Data> ParseOnlyData = [
    // Alternative era names
    Data.ymd(0, 10, 3)
      ..pattern = 'yyyy MM dd gg'
      ..text = '0001 10 03 BCE',

    // Valid leap years
    Data.ymd(2000, 2, 29)
      ..pattern = 'yyyy MM dd'
      ..text = '2000 02 29',
    Data.ymd(2004, 2, 29)
      ..pattern = 'yyyy MM dd'
      ..text = '2004 02 29',

    // Month parsing should be case-insensitive
    Data.ymd(2011, 10, 3)
      ..pattern = 'yyyy MMM dd'
      ..text = '2011 OcT 03',
    Data.ymd(2011, 10, 3)
      ..pattern = 'yyyy MMMM dd'
      ..text = '2011 OcToBeR 03',
    // Day-of-week parsing should be case-insensitive
    Data.ymd(2011, 10, 9)
      ..pattern = 'yyyy MM dd ddd'
      ..text = '2011 10 09 sUN',
    Data.ymd(2011, 10, 9)
      ..pattern = 'yyyy MM dd dddd'
      ..text = '2011 10 09 SuNDaY',

    // Genitive name is an extension of the non-genitive name; parse longer first.
    Data.ymd(2011, 1, 10)
      ..pattern = 'yyyy MMMM dd'
      ..text = '2011 MonthName-Genitive 10'
      ..culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
    Data.ymd(2011, 1, 10)
      ..pattern = 'yyyy MMMM dd'
      ..text = '2011 MonthName 10'
      ..culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
    Data.ymd(2011, 1, 10)
      ..pattern = 'yyyy MMM dd'
      ..text = '2011 MN-Gen 10'
      ..culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
    Data.ymd(2011, 1, 10)
      ..pattern = 'yyyy MMM dd'
      ..text = '2011 MN 10'
      ..culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
  ];

  @internal
  List<Data> FormatOnlyData = [
    // Would parse back to 2011
    Data.ymd(1811, 7, 3)
      ..pattern = 'yy M d'
      ..text = '11 7 3',
    // Tests for the documented 2-digit formatting of BC years
    // (Less of an issue since yy became 'year of era')
    Data.ymd(-94, 7, 3)
      ..pattern = 'yy M d'
      ..text = '95 7 3',
    Data.ymd(-93, 7, 3)
      ..pattern = 'yy M d'
      ..text = '94 7 3',
  ];

  @internal
  List<Data> FormatAndParseData = [
    // Standard patterns
    // Invariant culture uses the crazy MM/dd/yyyy format. Blech.
    Data.ymd(2011, 10, 20)
      ..pattern = 'd'
      ..text = '10/20/2011',
    Data.ymd(2011, 10, 20)
      ..pattern = 'D'
      ..text = 'Thursday, 20 October 2011',

    // Custom patterns
    Data.ymd(2011, 10, 3)
      ..pattern = 'yyyy/MM/dd'
      ..text = '2011/10/03',
    Data.ymd(2011, 10, 3)
      ..pattern = 'yyyy/MM/dd'
      ..text = '2011-10-03'
      ..culture = TestCultures.FrCa,
    Data.ymd(2011, 10, 3)
      ..pattern = 'yyyyMMdd'
      ..text = '20111003',
    Data.ymd(2001, 7, 3)
      ..pattern = 'yy M d'
      ..text = '01 7 3',
    Data.ymd(2011, 7, 3)
      ..pattern = 'yy M d'
      ..text = '11 7 3',
    Data.ymd(2030, 7, 3)
      ..pattern = 'yy M d'
      ..text = '30 7 3',
    // Cutoff defaults to 30 (at the moment...)
    Data.ymd(1931, 7, 3)
      ..pattern = 'yy M d'
      ..text = '31 7 3',
    Data.ymd(1976, 7, 3)
      ..pattern = 'yy M d'
      ..text = '76 7 3',

    // In the first century, we don't skip back a century for "high" two-digit year numbers.
    Data.ymd(25, 7, 3)
      ..pattern = 'yy M d'
      ..text = '25 7 3'
      ..template = LocalDate(50, 1, 1),
    Data.ymd(35, 7, 3)
      ..pattern = 'yy M d'
      ..text = '35 7 3'
      ..template = LocalDate(50, 1, 1),

    Data.ymd(2000, 10, 3)
      ..pattern = 'MM/dd'
      ..text = '10/03',
    Data.ymd(1885, 10, 3)
      ..pattern = 'MM/dd'
      ..text = '10/03'
      ..template = LocalDate(1885, 10, 3),

    // When we parse in all of the below tests, we'll use the month and day-of-month if it's provided;
    // the template value is specified to allow simple roundtripping. (Day of week doesn't affect what value is parsed; it just validates.)
    // Non-genitive month name when there's no "day of month", even if there's a "day of week"
    Data.ymd(2011, 1, 3)
      ..pattern = 'MMMM'
      ..text = 'FullNonGenName'
      ..culture = TestCultures.GenitiveNameTestCulture
      ..template = LocalDate(2011, 5, 3),
    Data.ymd(2011, 1, 3)
      ..pattern = 'MMMM dddd'
      ..text = 'FullNonGenName Monday'
      ..culture = TestCultures.GenitiveNameTestCulture
      ..template = LocalDate(2011, 5, 3),
    Data.ymd(2011, 1, 3)
      ..pattern = 'MMM'
      ..text = 'AbbrNonGenName'
      ..culture = TestCultures.GenitiveNameTestCulture
      ..template = LocalDate(2011, 5, 3),
    Data.ymd(2011, 1, 3)
      ..pattern = 'MMM ddd'
      ..text = 'AbbrNonGenName Mon'
      ..culture = TestCultures.GenitiveNameTestCulture
      ..template = LocalDate(2011, 5, 3),
    // Genitive month name when the pattern includes 'day of month'
    Data.ymd(2011, 1, 3)
      ..pattern = 'MMMM dd'
      ..text = 'FullGenName 03'
      ..culture = TestCultures.GenitiveNameTestCulture
      ..template = LocalDate(2011, 5, 3),
    // TODO: Check whether or not this is actually appropriate
    Data.ymd(2011, 1, 3)
      ..pattern = 'MMM dd'
      ..text = 'AbbrGenName 03'
      ..culture = TestCultures.GenitiveNameTestCulture
      ..template = LocalDate(2011, 5, 3),

    // Era handling
    Data.ymd(2011, 1, 3)
      ..pattern = 'yyyy MM dd gg'
      ..text = '2011 01 03 A.D.',
    Data.ymd(2011, 1, 3)
      ..pattern = 'uuuu yyyy MM dd gg'
      ..text = '2011 2011 01 03 A.D.',
    Data.ymd(-1, 1, 3)
      ..pattern = 'yyyy MM dd gg'
      ..text = '0002 01 03 B.C.',

    // Day of week handling
    Data.ymd(2011, 10, 9)
      ..pattern = 'yyyy MM dd dddd'
      ..text = '2011 10 09 Sunday',
    Data.ymd(2011, 10, 9)
      ..pattern = 'yyyy MM dd ddd'
      ..text = '2011 10 09 Sun',

    // Month handling
    Data.ymd(2011, 10, 9)
      ..pattern = 'yyyy MMMM dd'
      ..text = '2011 October 09',
    Data.ymd(2011, 10, 9)
      ..pattern = 'yyyy MMM dd'
      ..text = '2011 Oct 09',

    // Year and two-digit year-of-era in the same format. Note that the year
    // gives the full year information, so we're not stuck in the 20th/21st century
    Data.ymd(1825, 10, 9)
      ..pattern = 'uuuu yy MM/dd'
      ..text = '1825 25 10/09',

    // Negative years
    Data.ymd(-43, 3, 15)
      ..pattern = 'uuuu MM dd'
      ..text = '-0043 03 15',

    // Calendar handling
    Data.ymd(2011, 10, 9)
      ..pattern = 'c yyyy MM dd'
      ..text = 'ISO 2011 10 09',
    Data.ymd(2011, 10, 9)
      ..pattern = 'yyyy MM dd c'
      ..text = '2011 10 09 ISO',
    /* todo: @SkipMe.unimplemented()
    new Data.ymdc(2011, 10, 9, CalendarSystem.Coptic)
      ..Pattern = 'c uuuu MM dd'
      ..Text = 'Coptic 2011 10 09',
    new Data.ymdc(2011, 10, 9, CalendarSystem.Coptic)
      ..Pattern = 'uuuu MM dd c'
      ..Text = '2011 10 09 Coptic',

    new Data.ymdc(180, 15, 19, CalendarSystem.Badi)
      ..Pattern = 'uuuu MM dd c'
      ..Text = '0180 15 19 Badi',*/

    // Awkward day-of-week handling
    // December 14th 2012 was a Friday. Friday is 'Foo' or "FooBar" in AwkwardDayOfWeekCulture.
    Data.ymd(2012, 12, 14)
      ..pattern = 'ddd yyyy MM dd'
      ..text = 'Foo 2012 12 14'
      ..culture = TestCultures.AwkwardDayOfWeekCulture,
    Data.ymd(2012, 12, 14)
      ..pattern = 'dddd yyyy MM dd'
      ..text = 'FooBar 2012 12 14'
      ..culture = TestCultures.AwkwardDayOfWeekCulture,
    // December 13th 2012 was a Thursday. Friday is 'FooBaz' or "FooBa" in AwkwardDayOfWeekCulture.
    Data.ymd(2012, 12, 13)
      ..pattern = 'ddd yyyy MM dd'
      ..text = 'FooBaz 2012 12 13'
      ..culture = TestCultures.AwkwardDayOfWeekCulture,
    Data.ymd(2012, 12, 13)
      ..pattern = 'dddd yyyy MM dd'
      ..text = 'FooBa 2012 12 13'
      ..culture = TestCultures.AwkwardDayOfWeekCulture,

    // 3 digit year patterns (odd, but valid)
    Data.ymd(12, 1, 2)
      ..pattern = 'uuu MM dd'
      ..text = '012 01 02',
    Data.ymd(-12, 1, 2)
      ..pattern = 'uuu MM dd'
      ..text = '-012 01 02',
    Data.ymd(123, 1, 2)
      ..pattern = 'uuu MM dd'
      ..text = '123 01 02',
    Data.ymd(-123, 1, 2)
      ..pattern = 'uuu MM dd'
      ..text = '-123 01 02',
    Data.ymd(1234, 1, 2)
      ..pattern = 'uuu MM dd'
      ..text = '1234 01 02',
    Data.ymd(-1234, 1, 2)
      ..pattern = 'uuu MM dd'
      ..text = '-1234 01 02',
  ];

  @internal
  Iterable<Data> get ParseData =>
      [ParseOnlyData, FormatAndParseData].expand((x) => x);

  @internal
  Iterable<Data> get FormatData =>
      [FormatOnlyData, FormatAndParseData].expand((x) => x);

  /*
@Test()
[TestCaseSource(typeof(Cultures), nameof(TestCultures.AllCultures))]
void BclLongDatePatternGivesSameResultsInNoda(Culture culture)
{
AssertBclNodaEquality(culture, culture.DateTimeFormat.LongDatePattern);
}

@Test()
[TestCaseSource(typeof(Cultures), nameof(TestCultures.AllCultures))]
void BclShortDatePatternGivesSameResultsInNoda(Culture culture)
{
AssertBclNodaEquality(culture, culture.DateTimeFormat.ShortDatePattern);
}*/

  @Test()
  void WithCalendar() {
    var pattern = LocalDatePattern.iso.withCalendar(CalendarSystem.coptic);
    var value = pattern.parse('0284-08-29').value;
    expect(LocalDate(284, 8, 29, CalendarSystem.coptic), value);
  }

  @Test()
  void CreateWithCurrentCulture() {
    var date = LocalDate(2017, 8, 23);
    Culture.current = TestCultures.FrFr;
    var pattern = LocalDatePattern.createWithCurrentCulture('d');
    expect('23/08/2017', pattern.format(date));

    Culture.current = TestCultures.FrCa;
    pattern = LocalDatePattern.createWithCurrentCulture('d');
    expect('2017-08-23', pattern.format(date));
  }

  // @Test()
  // void ParseNull() => AssertParseNull(LocalDatePattern.iso);

  /* ~ No BCL ~ todo: equivalent?
  @private void AssertBclNodaEquality(Culture culture, String patternText) {
    // The BCL never seems to use abbreviated month genitive names.
    // I think it's reasonable that we do. Hmm.
    // See https://github.com/nodatime/nodatime/issues/377
    if (patternText.contains('MMM') && !patternText.contains("MMMM") &&
        culture.dateTimeFormat.abbreviatedMonthGenitiveNames[SampleLocalDate.Month - 1] !=
            culture.dateTimeFormat.abbreviatedMonthNames[SampleLocalDate.Month - 1]) {
      return;
    }

    var pattern = LocalDatePattern.Create3(patternText, culture);
    var calendarSystem = BclCalendars.CalendarSystemForCalendar(culture.Calendar);
    if (calendarSystem == null) {
      // We can't map this calendar system correctly yet; the test would be invalid.
      return;
    }

    var sampleDateInCalendar = SampleLocalDate.WithCalendar(calendarSystem);
    // To construct a DateTime, we need a time... let's give a non-midnight one to catch
    // any unexpected uses of time within the date patterns.
    DateTime sampleDateTime = (SampleLocalDate + new LocalTime(2, 3, 5)).ToDateTimeUnspecified();
    expect(sampleDateTime.toString(patternText, culture), pattern.Format(sampleDateInCalendar));
  }*/
}

class Data extends PatternTestData<LocalDate> {
// Default to the start of the year 2000.
  @override
  LocalDate get defaultTemplate => LocalDatePatterns.defaultTemplateValue;

  /// Initializes a new instance of the [Data] class.
  ///
  /// [value]: The value.
  Data([LocalDate? value])
      : super(value ?? LocalDatePatterns.defaultTemplateValue) {
    text = '';
  }

  Data.ymd(int year, int month, int day) : super(LocalDate(year, month, day)) {
    text = '';
  }

  Data.ymdc(int year, int month, int day, CalendarSystem calendar)
      : super(LocalDate(year, month, day, calendar)) {
    text = '';
  }

  @internal
  @override
  IPattern<LocalDate> CreatePattern() =>
      LocalDatePattern.createWithInvariantCulture(super.pattern)
          .withTemplateValue(template)
          .withCulture(culture);
}
