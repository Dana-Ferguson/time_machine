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
class LocalDatePatternTest extends PatternTestBase<LocalDate> {
  @private final LocalDate SampleLocalDate = new LocalDate(1976, 6, 19);

  @internal final List<Data> InvalidPatternData = [
    new Data()
      ..Pattern = ""
      ..Message = TextErrorMessages.FormatStringEmpty,
    new Data()
      ..Pattern = "!"
      ..Message = TextErrorMessages.UnknownStandardFormat
      ..Parameters.addAll(['!', 'LocalDate']),
    new Data()
      ..Pattern = "%"
      ..Message = TextErrorMessages.UnknownStandardFormat
      ..Parameters.addAll(['%', 'LocalDate']),
    new Data()
      ..Pattern = "\\"
      ..Message = TextErrorMessages.UnknownStandardFormat
      ..Parameters.addAll(['\\', 'LocalDate']),
    new Data()
      ..Pattern = "%%"
      ..Message = TextErrorMessages.PercentDoubled,
    new Data()
      ..Pattern = "%\\"
      ..Message = TextErrorMessages.EscapeAtEndOfString,
    new Data()
      ..Pattern = "MMMMM"
      ..Message = TextErrorMessages.RepeatCountExceeded
      ..Parameters.addAll(['M', 4]),
    new Data()
      ..Pattern = "ddddd"
      ..Message = TextErrorMessages.RepeatCountExceeded
      ..Parameters.addAll(['d', 4]),
    new Data()
      ..Pattern = "M%"
      ..Message = TextErrorMessages.PercentAtEndOfString,
    new Data()
      ..Pattern = "yyyyy"
      ..Message = TextErrorMessages.RepeatCountExceeded
      ..Parameters.addAll(['y', 4]),
    new Data()
      ..Pattern = "uuuuu"
      ..Message = TextErrorMessages.RepeatCountExceeded
      ..Parameters.addAll(['u', 4]),
    new Data()
      ..Pattern = "ggg"
      ..Message = TextErrorMessages.RepeatCountExceeded
      ..Parameters.addAll(['g', 2]),
    new Data()
      ..Pattern = "'qwe"
      ..Message = TextErrorMessages.MissingEndQuote
      ..Parameters.addAll(['\'']),
    new Data()
      ..Pattern = "'qwe\\"
      ..Message = TextErrorMessages.EscapeAtEndOfString,
    new Data()
      ..Pattern = "'qwe\\'"
      ..Message = TextErrorMessages.MissingEndQuote
      ..Parameters.addAll(['\'']),
    // Note incorrect use of "u" (year) instead of "y" (year of era)
    new Data()
      ..Pattern = "dd MM uuuu gg"
      ..Message = TextErrorMessages.EraWithoutYearOfEra,
    // Era specifier and calendar specifier in the same pattern.
    new Data()
      ..Pattern = "dd MM yyyy gg c"
      ..Message = TextErrorMessages.CalendarAndEra,

    // Invalid patterns directly after the yyyy specifier. This will detect the issue early, but then
    // continue and reject it in the normal path.
    new Data()
      ..Pattern = "yyyy'"
      ..Message = TextErrorMessages.MissingEndQuote
      ..Parameters.addAll(['\'']),
    new Data()
      ..Pattern = "yyyy\\"
      ..Message = TextErrorMessages.EscapeAtEndOfString,

    // Common typo, which is caught in 2.0...
    new Data()
      ..Pattern = "yyyy-mm-dd"
      ..Message = TextErrorMessages.UnquotedLiteral
      ..Parameters.addAll(['m']),
    // T isn't valid in a date pattern
    new Data()
      ..Pattern = "yyyy-MM-ddT00:00:00"
      ..Message = TextErrorMessages.UnquotedLiteral
      ..Parameters.addAll(['T']),

    // These became invalid in v2.0, when we decided that y and yyy weren't sensible.
    new Data()
      ..Pattern = "y M d"
      ..Message = TextErrorMessages.InvalidRepeatCount
      ..Parameters.addAll(['y', 1]),
    new Data()
      ..Pattern = "yyy M d"
      ..Message = TextErrorMessages.InvalidRepeatCount
      ..Parameters.addAll(['y', 3]),
  ];

  @internal List<Data> ParseFailureData = [
    new Data()
      ..Pattern = "yyyy gg"
      ..Text = "2011 NodaEra"
      ..Message = TextErrorMessages.MismatchedText
      ..Parameters.addAll(['g']),
    new Data()
      ..Pattern = "yyyy uuuu gg"
      ..Text = "0010 0009 B.C."
      ..Message = TextErrorMessages.InconsistentValues2
      ..Parameters.addAll(['g', 'u', 'LocalDate']),
    new Data()
      ..Pattern = "yyyy MM dd dddd"
      ..Text = "2011 10 09 Saturday"
      ..Message = TextErrorMessages.InconsistentDayOfWeekTextValue,
    new Data()
      ..Pattern = "yyyy MM dd ddd"
      ..Text = "2011 10 09 Sat"
      ..Message = TextErrorMessages.InconsistentDayOfWeekTextValue,
    new Data()
      ..Pattern = "yyyy MM dd MMMM"
      ..Text = "2011 10 09 January"
      ..Message = TextErrorMessages.InconsistentMonthTextValue,
    new Data()
      ..Pattern = "yyyy MM dd ddd"
      ..Text = "2011 10 09 FooBar"
      ..Message = TextErrorMessages.MismatchedText
      ..Parameters.addAll(['d']),
    new Data()
      ..Pattern = "yyyy MM dd dddd"
      ..Text = "2011 10 09 FooBar"
      ..Message = TextErrorMessages.MismatchedText
      ..Parameters.addAll(['d']),
    new Data()
      ..Pattern = "yyyy/MM/dd"
      ..Text = "2011/02-29"
      ..Message = TextErrorMessages.DateSeparatorMismatch,
    // Don't match a short name against a long pattern
    new Data()
      ..Pattern = "yyyy MMMM dd"
      ..Text = "2011 Oct 09"
      ..Message = TextErrorMessages.MismatchedText
      ..Parameters.addAll(['M']),
    // Or vice versa... although this time we match the "Oct" and then fail as we're expecting a space
    new Data()
      ..Pattern = "yyyy MMM dd"
      ..Text = "2011 October 09"
      ..Message = TextErrorMessages.MismatchedCharacter
      ..Parameters.addAll([' ']),

    // Invalid year, year-of-era, month, day
    new Data()
      ..Pattern = "yyyy MM dd"
      ..Text = "0000 01 01"
      ..Message = TextErrorMessages.FieldValueOutOfRange
      ..Parameters.addAll([0, 'y', 'LocalDate']),
    new Data()
      ..Pattern = "yyyy MM dd"
      ..Text = "2011 15 29"
      ..Message = TextErrorMessages.MonthOutOfRange
      ..Parameters.addAll([15, 2011]),
    new Data()
      ..Pattern = "yyyy MM dd"
      ..Text = "2011 02 35"
      ..Message = TextErrorMessages.DayOfMonthOutOfRange
      ..Parameters.addAll([35, 2, 2011]),
    // Year of era can't be negative...
    new Data()
      ..Pattern = "yyyy MM dd"
      ..Text = "-15 01 01"
      ..Message = TextErrorMessages.UnexpectedNegative,

    // Invalid leap years
    new Data()
      ..Pattern = "yyyy MM dd"
      ..Text = "2011 02 29"
      ..Message = TextErrorMessages.DayOfMonthOutOfRange
      ..Parameters.addAll([29, 2, 2011]),
    new Data()
      ..Pattern = "yyyy MM dd"
      ..Text = "1900 02 29"
      ..Message = TextErrorMessages.DayOfMonthOutOfRange
      ..Parameters.addAll([29, 2, 1900]),

    // Year of era and two-digit year, but they don't match
    new Data()
      ..Pattern = "uuuu yy"
      ..Text = "2011 10"
      ..Message = TextErrorMessages.InconsistentValues2
      ..Parameters.addAll(['y', 'u', 'LocalDate']),

    // Invalid calendar name
    new Data()
      ..Pattern = "c yyyy MM dd"
      ..Text = "2015 01 01"
      ..Message = TextErrorMessages.NoMatchingCalendarSystem,

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
      ..Text = "1984-00-15"
      ..Message = TextErrorMessages.FieldValueOutOfRange
      ..Parameters.addAll([0, 'M', 'LocalDate']),
    new Data()
      ..Pattern = "M/d/yyyy"
      ..Text = "00/15/1984"
      ..Message = TextErrorMessages.FieldValueOutOfRange
      ..Parameters.addAll([0, 'M', 'LocalDate']),

    // Calendar ID parsing is now ordinal, case-sensitive
    new Data.ymd(2011, 10, 9)
      ..Pattern = "yyyy MM dd c"
      ..Text = "2011 10 09 iso"
      ..Message = TextErrorMessages.NoMatchingCalendarSystem,
  ];

  @internal List<Data> ParseOnlyData = [
    // Alternative era names
    new Data.ymd(0, 10, 3)
      ..Pattern = "yyyy MM dd gg"
      ..Text = "0001 10 03 BCE",

    // Valid leap years
    new Data.ymd(2000, 2, 29)
      ..Pattern = "yyyy MM dd"
      ..Text = "2000 02 29",
    new Data.ymd(2004, 2, 29)
      ..Pattern = "yyyy MM dd"
      ..Text = "2004 02 29",

    // Month parsing should be case-insensitive
    new Data.ymd(2011, 10, 3)
      ..Pattern = "yyyy MMM dd"
      ..Text = "2011 OcT 03",
    new Data.ymd(2011, 10, 3)
      ..Pattern = "yyyy MMMM dd"
      ..Text = "2011 OcToBeR 03",
    // Day-of-week parsing should be case-insensitive
    new Data.ymd(2011, 10, 9)
      ..Pattern = "yyyy MM dd ddd"
      ..Text = "2011 10 09 sUN",
    new Data.ymd(2011, 10, 9)
      ..Pattern = "yyyy MM dd dddd"
      ..Text = "2011 10 09 SuNDaY",

    // Genitive name is an extension of the non-genitive name; parse longer first.
    new Data.ymd(2011, 1, 10)
      ..Pattern = "yyyy MMMM dd"
      ..Text = "2011 MonthName-Genitive 10"
      ..Culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
    new Data.ymd(2011, 1, 10)
      ..Pattern = "yyyy MMMM dd"
      ..Text = "2011 MonthName 10"
      ..Culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
    new Data.ymd(2011, 1, 10)
      ..Pattern = "yyyy MMM dd"
      ..Text = "2011 MN-Gen 10"
      ..Culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
    new Data.ymd(2011, 1, 10)
      ..Pattern = "yyyy MMM dd"
      ..Text = "2011 MN 10"
      ..Culture = TestCultures.GenitiveNameTestCultureWithLeadingNames,
  ];

  @internal List<Data> FormatOnlyData = [
    // Would parse back to 2011
    new Data.ymd(1811, 7, 3)
      ..Pattern = "yy M d"
      ..Text = "11 7 3",
    // Tests for the documented 2-digit formatting of BC years
    // (Less of an issue since yy became "year of era")
    new Data.ymd(-94, 7, 3)
      ..Pattern = "yy M d"
      ..Text = "95 7 3",
    new Data.ymd(-93, 7, 3)
      ..Pattern = "yy M d"
      ..Text = "94 7 3",
  ];

  @internal List<Data> FormatAndParseData = [
    // Standard patterns
    // Invariant culture uses the crazy MM/dd/yyyy format. Blech.
    new Data.ymd(2011, 10, 20)
      ..Pattern = "d"
      ..Text = "10/20/2011",
    new Data.ymd(2011, 10, 20)
      ..Pattern = "D"
      ..Text = "Thursday, 20 October 2011",

    // Custom patterns
    new Data.ymd(2011, 10, 3)
      ..Pattern = "yyyy/MM/dd"
      ..Text = "2011/10/03",
    new Data.ymd(2011, 10, 3)
      ..Pattern = "yyyy/MM/dd"
      ..Text = "2011-10-03"
      ..Culture = TestCultures.FrCa,
    new Data.ymd(2011, 10, 3)
      ..Pattern = "yyyyMMdd"
      ..Text = "20111003",
    new Data.ymd(2001, 7, 3)
      ..Pattern = "yy M d"
      ..Text = "01 7 3",
    new Data.ymd(2011, 7, 3)
      ..Pattern = "yy M d"
      ..Text = "11 7 3",
    new Data.ymd(2030, 7, 3)
      ..Pattern = "yy M d"
      ..Text = "30 7 3",
    // Cutoff defaults to 30 (at the moment...)
    new Data.ymd(1931, 7, 3)
      ..Pattern = "yy M d"
      ..Text = "31 7 3",
    new Data.ymd(1976, 7, 3)
      ..Pattern = "yy M d"
      ..Text = "76 7 3",

    // In the first century, we don't skip back a century for "high" two-digit year numbers.
    new Data.ymd(25, 7, 3)
      ..Pattern = "yy M d"
      ..Text = "25 7 3"
      ..Template = new LocalDate(50, 1, 1),
    new Data.ymd(35, 7, 3)
      ..Pattern = "yy M d"
      ..Text = "35 7 3"
      ..Template = new LocalDate(50, 1, 1),

    new Data.ymd(2000, 10, 3)
      ..Pattern = "MM/dd"
      ..Text = "10/03",
    new Data.ymd(1885, 10, 3)
      ..Pattern = "MM/dd"
      ..Text = "10/03"
      ..Template = new LocalDate(1885, 10, 3),

    // When we parse in all of the below tests, we'll use the month and day-of-month if it's provided;
    // the template value is specified to allow simple roundtripping. (Day of week doesn't affect what value is parsed; it just validates.)
    // Non-genitive month name when there's no "day of month", even if there's a "day of week"
    new Data.ymd(2011, 1, 3)
      ..Pattern = "MMMM"
      ..Text = "FullNonGenName"
      ..Culture = TestCultures.GenitiveNameTestCulture
      ..Template = new LocalDate(2011, 5, 3),
    new Data.ymd(2011, 1, 3)
      ..Pattern = "MMMM dddd"
      ..Text = "FullNonGenName Monday"
      ..Culture = TestCultures.GenitiveNameTestCulture
      ..Template = new LocalDate(2011, 5, 3),
    new Data.ymd(2011, 1, 3)
      ..Pattern = "MMM"
      ..Text = "AbbrNonGenName"
      ..Culture = TestCultures.GenitiveNameTestCulture
      ..Template = new LocalDate(2011, 5, 3),
    new Data.ymd(2011, 1, 3)
      ..Pattern = "MMM ddd"
      ..Text = "AbbrNonGenName Mon"
      ..Culture = TestCultures.GenitiveNameTestCulture
      ..Template = new LocalDate(2011, 5, 3),
    // Genitive month name when the pattern includes "day of month"
    new Data.ymd(2011, 1, 3)
      ..Pattern = "MMMM dd"
      ..Text = "FullGenName 03"
      ..Culture = TestCultures.GenitiveNameTestCulture
      ..Template = new LocalDate(2011, 5, 3),
    // TODO: Check whether or not this is actually appropriate
    new Data.ymd(2011, 1, 3)
      ..Pattern = "MMM dd"
      ..Text = "AbbrGenName 03"
      ..Culture = TestCultures.GenitiveNameTestCulture
      ..Template = new LocalDate(2011, 5, 3),

    // Era handling
    new Data.ymd(2011, 1, 3)
      ..Pattern = "yyyy MM dd gg"
      ..Text = "2011 01 03 A.D.",
    new Data.ymd(2011, 1, 3)
      ..Pattern = "uuuu yyyy MM dd gg"
      ..Text = "2011 2011 01 03 A.D.",
    new Data.ymd(-1, 1, 3)
      ..Pattern = "yyyy MM dd gg"
      ..Text = "0002 01 03 B.C.",

    // Day of week handling
    new Data.ymd(2011, 10, 9)
      ..Pattern = "yyyy MM dd dddd"
      ..Text = "2011 10 09 Sunday",
    new Data.ymd(2011, 10, 9)
      ..Pattern = "yyyy MM dd ddd"
      ..Text = "2011 10 09 Sun",

    // Month handling
    new Data.ymd(2011, 10, 9)
      ..Pattern = "yyyy MMMM dd"
      ..Text = "2011 October 09",
    new Data.ymd(2011, 10, 9)
      ..Pattern = "yyyy MMM dd"
      ..Text = "2011 Oct 09",

    // Year and two-digit year-of-era in the same format. Note that the year
    // gives the full year information, so we're not stuck in the 20th/21st century
    new Data.ymd(1825, 10, 9)
      ..Pattern = "uuuu yy MM/dd"
      ..Text = "1825 25 10/09",

    // Negative years
    new Data.ymd(-43, 3, 15)
      ..Pattern = "uuuu MM dd"
      ..Text = "-0043 03 15",

    // Calendar handling
    new Data.ymd(2011, 10, 9)
      ..Pattern = "c yyyy MM dd"
      ..Text = "ISO 2011 10 09",
    new Data.ymd(2011, 10, 9)
      ..Pattern = "yyyy MM dd c"
      ..Text = "2011 10 09 ISO",
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
      ..Text = "Foo 2012 12 14"
      ..Culture = TestCultures.AwkwardDayOfWeekCulture,
    new Data.ymd(2012, 12, 14)
      ..Pattern = "dddd yyyy MM dd"
      ..Text = "FooBar 2012 12 14"
      ..Culture = TestCultures.AwkwardDayOfWeekCulture,
    // December 13th 2012 was a Thursday. Friday is "FooBaz" or "FooBa" in AwkwardDayOfWeekCulture.
    new Data.ymd(2012, 12, 13)
      ..Pattern = "ddd yyyy MM dd"
      ..Text = "FooBaz 2012 12 13"
      ..Culture = TestCultures.AwkwardDayOfWeekCulture,
    new Data.ymd(2012, 12, 13)
      ..Pattern = "dddd yyyy MM dd"
      ..Text = "FooBa 2012 12 13"
      ..Culture = TestCultures.AwkwardDayOfWeekCulture,

    // 3 digit year patterns (odd, but valid)
    new Data.ymd(12, 1, 2)
      ..Pattern = "uuu MM dd"
      ..Text = "012 01 02",
    new Data.ymd(-12, 1, 2)
      ..Pattern = "uuu MM dd"
      ..Text = "-012 01 02",
    new Data.ymd(123, 1, 2)
      ..Pattern = "uuu MM dd"
      ..Text = "123 01 02",
    new Data.ymd(-123, 1, 2)
      ..Pattern = "uuu MM dd"
      ..Text = "-123 01 02",
    new Data.ymd(1234, 1, 2)
      ..Pattern = "uuu MM dd"
      ..Text = "1234 01 02",
    new Data.ymd(-1234, 1, 2)
      ..Pattern = "uuu MM dd"
      ..Text = "-1234 01 02",
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
    var pattern = LocalDatePattern.Iso.WithCalendar(CalendarSystem.coptic);
    var value = pattern
        .parse("0284-08-29")
        .Value;
    expect(new LocalDate(284, 8, 29, CalendarSystem.coptic), value);
  }

  @Test()
  void CreateWithCurrentCulture() {
    var date = new LocalDate(2017, 8, 23);
    CultureInfo.currentCulture = TestCultures.FrFr;
    var pattern = LocalDatePattern.CreateWithCurrentCulture("d");
    expect("23/08/2017", pattern.format(date));

    CultureInfo.currentCulture = TestCultures.FrCa;
    pattern = LocalDatePattern.CreateWithCurrentCulture("d");
    expect("2017-08-23", pattern.format(date));
  }

  @Test()
  void ParseNull() => AssertParseNull(LocalDatePattern.Iso);

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

/*sealed*/ class Data extends PatternTestData<LocalDate>
  {
// Default to the start of the year 2000.
/*protected*/ @override LocalDate get DefaultTemplate => LocalDatePattern.DefaultTemplateValue;

  /// Initializes a new instance of the [Data] class.
  ///
  /// [value]: The value.
  Data([LocalDate value = null]) : super(value ?? LocalDatePattern.DefaultTemplateValue);

  Data.ymd(int year, int month, int day) : super(new LocalDate(year, month, day));

  Data.ymdc(int year, int month, int day, CalendarSystem calendar)
      : super(new LocalDate(year, month, day, calendar));

  @internal @override IPattern<LocalDate> CreatePattern() =>
  LocalDatePattern.CreateWithInvariantCulture(super.Pattern)
      .WithTemplateValue(Template)
      .WithCulture(Culture);
  }


