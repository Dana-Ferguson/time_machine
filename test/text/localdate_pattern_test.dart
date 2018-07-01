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
  @private final LocalDate SampleLocalDate = new LocalDate(1976, 6, 19);

  @internal final List<Data> InvalidPatternData = [
    new Data()
      ..Pattern = ""
      ..Message = TextErrorMessages.formatStringEmpty,
    new Data()
      ..Pattern = "!"
      ..Message = TextErrorMessages.unknownStandardFormat
      ..Parameters.addAll(['!', 'LocalDate']),
    new Data()
      ..Pattern = "%"
      ..Message = TextErrorMessages.unknownStandardFormat
      ..Parameters.addAll(['%', 'LocalDate']),
    new Data()
      ..Pattern = "\\"
      ..Message = TextErrorMessages.unknownStandardFormat
      ..Parameters.addAll(['\\', 'LocalDate']),
    new Data()
      ..Pattern = "%%"
      ..Message = TextErrorMessages.percentDoubled,
    new Data()
      ..Pattern = "%\\"
      ..Message = TextErrorMessages.escapeAtEndOfString,
    new Data()
      ..Pattern = "MMMMM"
      ..Message = TextErrorMessages.repeatCountExceeded
      ..Parameters.addAll(['M', 4]),
    new Data()
      ..Pattern = "ddddd"
      ..Message = TextErrorMessages.repeatCountExceeded
      ..Parameters.addAll(['d', 4]),
    new Data()
      ..Pattern = "M%"
      ..Message = TextErrorMessages.percentAtEndOfString,
    new Data()
      ..Pattern = "yyyyy"
      ..Message = TextErrorMessages.repeatCountExceeded
      ..Parameters.addAll(['y', 4]),
    new Data()
      ..Pattern = "uuuuu"
      ..Message = TextErrorMessages.repeatCountExceeded
      ..Parameters.addAll(['u', 4]),
    new Data()
      ..Pattern = "ggg"
      ..Message = TextErrorMessages.repeatCountExceeded
      ..Parameters.addAll(['g', 2]),
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
    // Note incorrect use of "u" (year) instead of "y" (year of era)
    new Data()
      ..Pattern = "dd MM uuuu gg"
      ..Message = TextErrorMessages.eraWithoutYearOfEra,
    // Era specifier and calendar specifier in the same pattern.
    new Data()
      ..Pattern = "dd MM yyyy gg c"
      ..Message = TextErrorMessages.calendarAndEra,

    // Invalid patterns directly after the yyyy specifier. This will detect the issue early, but then
    // continue and reject it in the normal path.
    new Data()
      ..Pattern = "yyyy'"
      ..Message = TextErrorMessages.missingEndQuote
      ..Parameters.addAll(['\'']),
    new Data()
      ..Pattern = "yyyy\\"
      ..Message = TextErrorMessages.escapeAtEndOfString,

    // Common typo, which is caught in 2.0...
    new Data()
      ..Pattern = "yyyy-mm-dd"
      ..Message = TextErrorMessages.unquotedLiteral
      ..Parameters.addAll(['m']),
    // T isn't valid in a date pattern
    new Data()
      ..Pattern = "yyyy-MM-ddT00:00:00"
      ..Message = TextErrorMessages.unquotedLiteral
      ..Parameters.addAll(['T']),

    // These became invalid in v2.0, when we decided that y and yyy weren't sensible.
    new Data()
      ..Pattern = "y M d"
      ..Message = TextErrorMessages.invalidRepeatCount
      ..Parameters.addAll(['y', 1]),
    new Data()
      ..Pattern = "yyy M d"
      ..Message = TextErrorMessages.invalidRepeatCount
      ..Parameters.addAll(['y', 3]),
  ];

  @internal List<Data> ParseFailureData = [
    new Data()
      ..Pattern = "yyyy gg"
      ..text = "2011 NodaEra"
      ..Message = TextErrorMessages.mismatchedText
      ..Parameters.addAll(['g']),
    new Data()
      ..Pattern = "yyyy uuuu gg"
      ..text = "0010 0009 B.C."
      ..Message = TextErrorMessages.inconsistentValues2
      ..Parameters.addAll(['g', 'u', 'LocalDate']),
    new Data()
      ..Pattern = "yyyy MM dd dddd"
      ..text = "2011 10 09 Saturday"
      ..Message = TextErrorMessages.inconsistentDayOfWeekTextValue,
    new Data()
      ..Pattern = "yyyy MM dd ddd"
      ..text = "2011 10 09 Sat"
      ..Message = TextErrorMessages.inconsistentDayOfWeekTextValue,
    new Data()
      ..Pattern = "yyyy MM dd MMMM"
      ..text = "2011 10 09 January"
      ..Message = TextErrorMessages.inconsistentMonthTextValue,
    new Data()
      ..Pattern = "yyyy MM dd ddd"
      ..text = "2011 10 09 FooBar"
      ..Message = TextErrorMessages.mismatchedText
      ..Parameters.addAll(['d']),
    new Data()
      ..Pattern = "yyyy MM dd dddd"
      ..text = "2011 10 09 FooBar"
      ..Message = TextErrorMessages.mismatchedText
      ..Parameters.addAll(['d']),
    new Data()
      ..Pattern = "yyyy/MM/dd"
      ..text = "2011/02-29"
      ..Message = TextErrorMessages.dateSeparatorMismatch,
    // Don't match a short name against a long pattern
    new Data()
      ..Pattern = "yyyy MMMM dd"
      ..text = "2011 Oct 09"
      ..Message = TextErrorMessages.mismatchedText
      ..Parameters.addAll(['M']),
    // Or vice versa... although this time we match the "Oct" and then fail as we're expecting a space
    new Data()
      ..Pattern = "yyyy MMM dd"
      ..text = "2011 October 09"
      ..Message = TextErrorMessages.mismatchedCharacter
      ..Parameters.addAll([' ']),

    // Invalid year, year-of-era, month, day
    new Data()
      ..Pattern = "yyyy MM dd"
      ..text = "0000 01 01"
      ..Message = TextErrorMessages.fieldValueOutOfRange
      ..Parameters.addAll([0, 'y', 'LocalDate']),
    new Data()
      ..Pattern = "yyyy MM dd"
      ..text = "2011 15 29"
      ..Message = TextErrorMessages.monthOutOfRange
      ..Parameters.addAll([15, 2011]),
    new Data()
      ..Pattern = "yyyy MM dd"
      ..text = "2011 02 35"
      ..Message = TextErrorMessages.dayOfMonthOutOfRange
      ..Parameters.addAll([35, 2, 2011]),
    // Year of era can't be negative...
    new Data()
      ..Pattern = "yyyy MM dd"
      ..text = "-15 01 01"
      ..Message = TextErrorMessages.unexpectedNegative,

    // Invalid leap years
    new Data()
      ..Pattern = "yyyy MM dd"
      ..text = "2011 02 29"
      ..Message = TextErrorMessages.dayOfMonthOutOfRange
      ..Parameters.addAll([29, 2, 2011]),
    new Data()
      ..Pattern = "yyyy MM dd"
      ..text = "1900 02 29"
      ..Message = TextErrorMessages.dayOfMonthOutOfRange
      ..Parameters.addAll([29, 2, 1900]),

    // Year of era and two-digit year, but they don't match
    new Data()
      ..Pattern = "uuuu yy"
      ..text = "2011 10"
      ..Message = TextErrorMessages.inconsistentValues2
      ..Parameters.addAll(['y', 'u', 'LocalDate']),

    // Invalid calendar name
    new Data()
      ..Pattern = "c yyyy MM dd"
      ..text = "2015 01 01"
      ..Message = TextErrorMessages.noMatchingCalendarSystem,

  // Invalid year
  /* todo: @SkipMe.unimplemented()
    new Data()
      ..Template = new LocalDate.forCalendar(1, 1, 1, CalendarSystem.IslamicBcl)
      ..Pattern = "uuuu"
      ..Text = "9999"
      ..Message = TextErrorMessages.FieldValueOutOfRange
      ..Parameters.addAll([9999, 'u', 'LocalDate']),
    new Data()
      ..Template = new LocalDate.forCalendar(1, 1, 1, CalendarSystem.IslamicBcl)
      ..Pattern = "yyyy"
      ..Text = "9999"
      ..Message = TextErrorMessages.YearOfEraOutOfRange
      ..Parameters.addAll([9999, "EH", "Hijri"]),*/

    // https://github.com/nodatime/nodatime/issues/414
    new Data()
      ..Pattern = "yyyy-MM-dd"
      ..text = "1984-00-15"
      ..Message = TextErrorMessages.fieldValueOutOfRange
      ..Parameters.addAll([0, 'M', 'LocalDate']),
    new Data()
      ..Pattern = "M/d/yyyy"
      ..text = "00/15/1984"
      ..Message = TextErrorMessages.fieldValueOutOfRange
      ..Parameters.addAll([0, 'M', 'LocalDate']),

    // Calendar ID parsing is now ordinal, case-sensitive
    new Data.ymd(2011, 10, 9)
      ..Pattern = "yyyy MM dd c"
      ..text = "2011 10 09 iso"
      ..Message = TextErrorMessages.noMatchingCalendarSystem,
  ];

  @internal List<Data> ParseOnlyData = [
    // Alternative era names
    new Data.ymd(0, 10, 3)
      ..Pattern = "yyyy MM dd gg"
      ..text = "0001 10 03 BCE",

    // Valid leap years
    new Data.ymd(2000, 2, 29)
      ..Pattern = "yyyy MM dd"
      ..text = "2000 02 29",
    new Data.ymd(2004, 2, 29)
      ..Pattern = "yyyy MM dd"
      ..text = "2004 02 29",

    // Month parsing should be case-insensitive
    new Data.ymd(2011, 10, 3)
      ..Pattern = "yyyy MMM dd"
      ..text = "2011 OcT 03",
    new Data.ymd(2011, 10, 3)
      ..Pattern = "yyyy MMMM dd"
      ..text = "2011 OcToBeR 03",
    // Day-of-week parsing should be case-insensitive
    new Data.ymd(2011, 10, 9)
      ..Pattern = "yyyy MM dd ddd"
      ..text = "2011 10 09 sUN",
    new Data.ymd(2011, 10, 9)
      ..Pattern = "yyyy MM dd dddd"
      ..text = "2011 10 09 SuNDaY",

    // Genitive name is an extension of the non-genitive name; parse longer first.
    new Data.ymd(2011, 1, 10)
      ..Pattern = "yyyy MMMM dd"
      ..text = "2011 MonthName-Genitive 10"
      ..Culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
    new Data.ymd(2011, 1, 10)
      ..Pattern = "yyyy MMMM dd"
      ..text = "2011 MonthName 10"
      ..Culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
    new Data.ymd(2011, 1, 10)
      ..Pattern = "yyyy MMM dd"
      ..text = "2011 MN-Gen 10"
      ..Culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
    new Data.ymd(2011, 1, 10)
      ..Pattern = "yyyy MMM dd"
      ..text = "2011 MN 10"
      ..Culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
  ];

  @internal List<Data> FormatOnlyData = [
    // Would parse back to 2011
    new Data.ymd(1811, 7, 3)
      ..Pattern = "yy M d"
      ..text = "11 7 3",
    // Tests for the documented 2-digit formatting of BC years
    // (Less of an issue since yy became "year of era")
    new Data.ymd(-94, 7, 3)
      ..Pattern = "yy M d"
      ..text = "95 7 3",
    new Data.ymd(-93, 7, 3)
      ..Pattern = "yy M d"
      ..text = "94 7 3",
  ];

  @internal List<Data> FormatAndParseData = [
    // Standard patterns
    // Invariant culture uses the crazy MM/dd/yyyy format. Blech.
    new Data.ymd(2011, 10, 20)
      ..Pattern = "d"
      ..text = "10/20/2011",
    new Data.ymd(2011, 10, 20)
      ..Pattern = "D"
      ..text = "Thursday, 20 October 2011",

    // Custom patterns
    new Data.ymd(2011, 10, 3)
      ..Pattern = "yyyy/MM/dd"
      ..text = "2011/10/03",
    new Data.ymd(2011, 10, 3)
      ..Pattern = "yyyy/MM/dd"
      ..text = "2011-10-03"
      ..Culture = TestCultures.FrCa,
    new Data.ymd(2011, 10, 3)
      ..Pattern = "yyyyMMdd"
      ..text = "20111003",
    new Data.ymd(2001, 7, 3)
      ..Pattern = "yy M d"
      ..text = "01 7 3",
    new Data.ymd(2011, 7, 3)
      ..Pattern = "yy M d"
      ..text = "11 7 3",
    new Data.ymd(2030, 7, 3)
      ..Pattern = "yy M d"
      ..text = "30 7 3",
    // Cutoff defaults to 30 (at the moment...)
    new Data.ymd(1931, 7, 3)
      ..Pattern = "yy M d"
      ..text = "31 7 3",
    new Data.ymd(1976, 7, 3)
      ..Pattern = "yy M d"
      ..text = "76 7 3",

    // In the first century, we don't skip back a century for "high" two-digit year numbers.
    new Data.ymd(25, 7, 3)
      ..Pattern = "yy M d"
      ..text = "25 7 3"
      ..Template = new LocalDate(50, 1, 1),
    new Data.ymd(35, 7, 3)
      ..Pattern = "yy M d"
      ..text = "35 7 3"
      ..Template = new LocalDate(50, 1, 1),

    new Data.ymd(2000, 10, 3)
      ..Pattern = "MM/dd"
      ..text = "10/03",
    new Data.ymd(1885, 10, 3)
      ..Pattern = "MM/dd"
      ..text = "10/03"
      ..Template = new LocalDate(1885, 10, 3),

    // When we parse in all of the below tests, we'll use the month and day-of-month if it's provided;
    // the template value is specified to allow simple roundtripping. (Day of week doesn't affect what value is parsed; it just validates.)
    // Non-genitive month name when there's no "day of month", even if there's a "day of week"
    new Data.ymd(2011, 1, 3)
      ..Pattern = "MMMM"
      ..text = "FullNonGenName"
      ..Culture = TestCultures.GenitiveNameTestCulture
      ..Template = new LocalDate(2011, 5, 3),
    new Data.ymd(2011, 1, 3)
      ..Pattern = "MMMM dddd"
      ..text = "FullNonGenName Monday"
      ..Culture = TestCultures.GenitiveNameTestCulture
      ..Template = new LocalDate(2011, 5, 3),
    new Data.ymd(2011, 1, 3)
      ..Pattern = "MMM"
      ..text = "AbbrNonGenName"
      ..Culture = TestCultures.GenitiveNameTestCulture
      ..Template = new LocalDate(2011, 5, 3),
    new Data.ymd(2011, 1, 3)
      ..Pattern = "MMM ddd"
      ..text = "AbbrNonGenName Mon"
      ..Culture = TestCultures.GenitiveNameTestCulture
      ..Template = new LocalDate(2011, 5, 3),
    // Genitive month name when the pattern includes "day of month"
    new Data.ymd(2011, 1, 3)
      ..Pattern = "MMMM dd"
      ..text = "FullGenName 03"
      ..Culture = TestCultures.GenitiveNameTestCulture
      ..Template = new LocalDate(2011, 5, 3),
    // TODO: Check whether or not this is actually appropriate
    new Data.ymd(2011, 1, 3)
      ..Pattern = "MMM dd"
      ..text = "AbbrGenName 03"
      ..Culture = TestCultures.GenitiveNameTestCulture
      ..Template = new LocalDate(2011, 5, 3),

    // Era handling
    new Data.ymd(2011, 1, 3)
      ..Pattern = "yyyy MM dd gg"
      ..text = "2011 01 03 A.D.",
    new Data.ymd(2011, 1, 3)
      ..Pattern = "uuuu yyyy MM dd gg"
      ..text = "2011 2011 01 03 A.D.",
    new Data.ymd(-1, 1, 3)
      ..Pattern = "yyyy MM dd gg"
      ..text = "0002 01 03 B.C.",

    // Day of week handling
    new Data.ymd(2011, 10, 9)
      ..Pattern = "yyyy MM dd dddd"
      ..text = "2011 10 09 Sunday",
    new Data.ymd(2011, 10, 9)
      ..Pattern = "yyyy MM dd ddd"
      ..text = "2011 10 09 Sun",

    // Month handling
    new Data.ymd(2011, 10, 9)
      ..Pattern = "yyyy MMMM dd"
      ..text = "2011 October 09",
    new Data.ymd(2011, 10, 9)
      ..Pattern = "yyyy MMM dd"
      ..text = "2011 Oct 09",

    // Year and two-digit year-of-era in the same format. Note that the year
    // gives the full year information, so we're not stuck in the 20th/21st century
    new Data.ymd(1825, 10, 9)
      ..Pattern = "uuuu yy MM/dd"
      ..text = "1825 25 10/09",

    // Negative years
    new Data.ymd(-43, 3, 15)
      ..Pattern = "uuuu MM dd"
      ..text = "-0043 03 15",

    // Calendar handling
    new Data.ymd(2011, 10, 9)
      ..Pattern = "c yyyy MM dd"
      ..text = "ISO 2011 10 09",
    new Data.ymd(2011, 10, 9)
      ..Pattern = "yyyy MM dd c"
      ..text = "2011 10 09 ISO",
  /* todo: @SkipMe.unimplemented()
    new Data.ymdc(2011, 10, 9, CalendarSystem.Coptic)
      ..Pattern = "c uuuu MM dd"
      ..Text = "Coptic 2011 10 09",
    new Data.ymdc(2011, 10, 9, CalendarSystem.Coptic)
      ..Pattern = "uuuu MM dd c"
      ..Text = "2011 10 09 Coptic",

    new Data.ymdc(180, 15, 19, CalendarSystem.Badi)
      ..Pattern = "uuuu MM dd c"
      ..Text = "0180 15 19 Badi",*/

    // Awkward day-of-week handling
    // December 14th 2012 was a Friday. Friday is "Foo" or "FooBar" in AwkwardDayOfWeekCulture.
    new Data.ymd(2012, 12, 14)
      ..Pattern = "ddd yyyy MM dd"
      ..text = "Foo 2012 12 14"
      ..Culture = TestCultures.AwkwardDayOfWeekCulture,
    new Data.ymd(2012, 12, 14)
      ..Pattern = "dddd yyyy MM dd"
      ..text = "FooBar 2012 12 14"
      ..Culture = TestCultures.AwkwardDayOfWeekCulture,
    // December 13th 2012 was a Thursday. Friday is "FooBaz" or "FooBa" in AwkwardDayOfWeekCulture.
    new Data.ymd(2012, 12, 13)
      ..Pattern = "ddd yyyy MM dd"
      ..text = "FooBaz 2012 12 13"
      ..Culture = TestCultures.AwkwardDayOfWeekCulture,
    new Data.ymd(2012, 12, 13)
      ..Pattern = "dddd yyyy MM dd"
      ..text = "FooBa 2012 12 13"
      ..Culture = TestCultures.AwkwardDayOfWeekCulture,

    // 3 digit year patterns (odd, but valid)
    new Data.ymd(12, 1, 2)
      ..Pattern = "uuu MM dd"
      ..text = "012 01 02",
    new Data.ymd(-12, 1, 2)
      ..Pattern = "uuu MM dd"
      ..text = "-012 01 02",
    new Data.ymd(123, 1, 2)
      ..Pattern = "uuu MM dd"
      ..text = "123 01 02",
    new Data.ymd(-123, 1, 2)
      ..Pattern = "uuu MM dd"
      ..text = "-123 01 02",
    new Data.ymd(1234, 1, 2)
      ..Pattern = "uuu MM dd"
      ..text = "1234 01 02",
    new Data.ymd(-1234, 1, 2)
      ..Pattern = "uuu MM dd"
      ..text = "-1234 01 02",
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);

  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);

  /*
@Test()
[TestCaseSource(typeof(Cultures), nameof(TestCultures.AllCultures))]
void BclLongDatePatternGivesSameResultsInNoda(CultureInfo culture)
{
AssertBclNodaEquality(culture, culture.DateTimeFormat.LongDatePattern);
}

@Test()
[TestCaseSource(typeof(Cultures), nameof(TestCultures.AllCultures))]
void BclShortDatePatternGivesSameResultsInNoda(CultureInfo culture)
{
AssertBclNodaEquality(culture, culture.DateTimeFormat.ShortDatePattern);
}*/

  @Test()
  @SkipMe.unimplemented()
  void WithCalendar() {
    var pattern = LocalDatePattern.iso.withCalendar(CalendarSystem.coptic);
    var value = pattern
        .parse("0284-08-29")
        .value;
    expect(new LocalDate(284, 8, 29, CalendarSystem.coptic), value);
  }

  @Test()
  void CreateWithCurrentCulture() {
    var date = new LocalDate(2017, 8, 23);
    CultureInfo.currentCulture = TestCultures.FrFr;
    var pattern = LocalDatePattern.createWithCurrentCulture("d");
    expect("23/08/2017", pattern.format(date));

    CultureInfo.currentCulture = TestCultures.FrCa;
    pattern = LocalDatePattern.createWithCurrentCulture("d");
    expect("2017-08-23", pattern.format(date));
  }

  @Test()
  void ParseNull() => AssertParseNull(LocalDatePattern.iso);

  /* ~ No BCL ~ todo: equivalent?
  @private void AssertBclNodaEquality(CultureInfo culture, String patternText) {
    // The BCL never seems to use abbreviated month genitive names.
    // I think it's reasonable that we do. Hmm.
    // See https://github.com/nodatime/nodatime/issues/377
    if (patternText.contains("MMM") && !patternText.contains("MMMM") &&
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
  @override LocalDate get DefaultTemplate => ILocalDatePattern.defaultTemplateValue;

  /// Initializes a new instance of the [Data] class.
  ///
  /// [value]: The value.
  Data([LocalDate value = null]) : super(value ?? ILocalDatePattern.defaultTemplateValue);

  Data.ymd(int year, int month, int day) : super(new LocalDate(year, month, day));

  Data.ymdc(int year, int month, int day, CalendarSystem calendar)
      : super(new LocalDate(year, month, day, calendar));

  @internal
  @override
  IPattern<LocalDate> CreatePattern() =>
      LocalDatePattern.createWithInvariantCulture(super.Pattern)
          .withTemplateValue(Template)
          .withCulture(Culture);
}


