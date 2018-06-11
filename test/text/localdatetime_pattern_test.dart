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

@private final List<String> AllStandardPatterns = [ "f", "F", "g", "G", "o", "O", "s" ];
@private final List _AllCulturesStandardPatterns = [];

Future main() async {
  var sw = new Stopwatch()..start();
  var ids = await Cultures.ids;
  var allCultures = new List<CultureInfo>();
  for(var id in ids) {
    allCultures.add(await Cultures.getCulture(id));
  }
  for(var culture in allCultures) {
    for(var format in AllStandardPatterns) {
      _AllCulturesStandardPatterns.add(new TestCaseData([culture, format])..name = '$culture: $format');
    }
  }
  print('Time to load cultures: ${sw.elapsedMilliseconds} ms;');

  await runTests();
}

@Test()
class LocalDateTimePatternTest extends PatternTestBase<LocalDateTime> {
  List get AllCulturesStandardPatterns => _AllCulturesStandardPatterns;

  @private static final LocalDateTime SampleLocalDateTime = TestLocalDateTimes.SampleLocalDateTime;
  @private static final LocalDateTime SampleLocalDateTimeToTicks = TestLocalDateTimes.SampleLocalDateTimeToTicks;
  @private static final LocalDateTime SampleLocalDateTimeToMillis = TestLocalDateTimes.SampleLocalDateTimeToMillis;
  @private static final LocalDateTime SampleLocalDateTimeToSeconds = TestLocalDateTimes.SampleLocalDateTimeToSeconds;
  @private static final LocalDateTime SampleLocalDateTimeToMinutes = TestLocalDateTimes.SampleLocalDateTimeToMinutes;
  /*@internal static final LocalDateTime SampleLocalDateTimeCoptic = new LocalDateTime.fromYMDHMSC(
      1976,
      6,
      19,
      21,
      13,
      34,
      CalendarSystem.Coptic).PlusNanoseconds(123456789);*/

  // The standard example date/time used in all the MSDN samples, which means we can just cut and paste
  // the expected results of the standard patterns.
  @internal static final LocalDateTime MsdnStandardExample = TestLocalDateTimes.MsdnStandardExample;
  @internal static final LocalDateTime MsdnStandardExampleNoMillis = TestLocalDateTimes.MsdnStandardExampleNoMillis;
  @private static final LocalDateTime MsdnStandardExampleNoSeconds = TestLocalDateTimes.MsdnStandardExampleNoSeconds;

  @internal final List<Data> InvalidPatternData = [
    new Data()
      ..Pattern = ""
      ..Message = TextErrorMessages.FormatStringEmpty,
    new Data()
      ..Pattern = "a"
      ..Message = TextErrorMessages.UnknownStandardFormat
      ..Parameters.addAll(['a', 'LocalDateTime']),
    new Data()
      ..Pattern = "dd MM yyyy HH:MM:SS"
      ..Message = TextErrorMessages.RepeatedFieldInPattern
      ..Parameters.addAll(['M']),
    // Note incorrect use of "u" (year) instead of "y" (year of era)
    new Data()
      ..Pattern = "dd MM uuuu HH:mm:ss gg"
      ..Message = TextErrorMessages.EraWithoutYearOfEra,
    // Era specifier and calendar specifier in the same pattern.
    new Data()
      ..Pattern = "dd MM yyyy HH:mm:ss gg c"
      ..Message = TextErrorMessages.CalendarAndEra,
    // Embedded pattern start without ld or lt
    new Data()
      ..Pattern = "yyyy MM dd <"
      ..Message = TextErrorMessages.UnquotedLiteral
      ..Parameters.addAll(['<']),
    // Attempt to use a full embedded date/time pattern (not valid for LocalDateTime)
    new Data()
      ..Pattern = "l<yyyy MM dd HH:mm>"
      ..Message = TextErrorMessages.InvalidEmbeddedPatternType,
    // Invalid nested pattern (local date pattern doesn't know about embedded patterns)
    new Data()
      ..Pattern = "ld<<D>>"
      ..Message = TextErrorMessages.UnquotedLiteral
      ..Parameters.addAll(['<']),
  ];

  @internal List<Data> ParseFailureData = [
    new Data()
      ..Pattern = "dd MM yyyy HH:mm:ss"
      ..Text = "Complete mismatch"
      ..Message = TextErrorMessages.MismatchedNumber
      ..Parameters.addAll(["dd"]),
    new Data()
      ..Pattern = "(c)"
      ..Text = "(xxx)"
      ..Message = TextErrorMessages.NoMatchingCalendarSystem,
    // 24 as an hour is only valid when the time is midnight
    new Data()
      ..Pattern = "yyyy-MM-dd"
      ..Text = "2017-02-30"
      ..Message = TextErrorMessages.DayOfMonthOutOfRange
      ..Parameters.addAll([30, 2, 2017]),
    new Data()
      ..Pattern = "yyyy-MM-dd HH:mm:ss"
      ..Text = "2011-10-19 24:00:05"
      ..Message = TextErrorMessages.InvalidHour24,
    new Data()
      ..Pattern = "yyyy-MM-dd HH:mm:ss"
      ..Text = "2011-10-19 24:01:00"
      ..Message = TextErrorMessages.InvalidHour24,
    new Data()
      ..Pattern = "yyyy-MM-dd HH:mm"
      ..Text = "2011-10-19 24:01"
      ..Message = TextErrorMessages.InvalidHour24,
    new Data()
      ..Pattern = "yyyy-MM-dd HH:mm"
      ..Text = "2011-10-19 24:00"
      ..Template = new LocalDateTime.fromYMDHMS(1970, 1, 1, 0, 0, 5)
      ..Message = TextErrorMessages.InvalidHour24,
    new Data()
      ..Pattern = "yyyy-MM-dd HH"
      ..Text = "2011-10-19 24"
      ..Template = new LocalDateTime.fromYMDHMS(1970, 1, 1, 0, 5, 0)
      ..Message = TextErrorMessages.InvalidHour24,
  ];

  @internal List<Data> ParseOnlyData = [
    new Data.ymd(2011, 10, 19, 16, 05, 20)
      ..Pattern = "dd MM yyyy"
      ..Text = "19 10 2011"
      ..Template = new LocalDateTime.fromYMDHMS(2000, 1, 1, 16, 05, 20),
    new Data.ymd(2011, 10, 19, 16, 05, 20)
      ..Pattern = "HH:mm:ss"
      ..Text = "16:05:20"
      ..Template = new LocalDateTime.fromYMDHMS(2011, 10, 19, 0, 0, 0),
    // Parsing using the semi-colon "comma dot" specifier
    new Data.ymd(
        2011,
        10,
        19,
        16,
        05,
        20,
        352)
      ..Pattern = "yyyy-MM-dd HH:mm:ss;fff"
      ..Text = "2011-10-19 16:05:20,352",
    new Data.ymd(
        2011,
        10,
        19,
        16,
        05,
        20,
        352)
      ..Pattern = "yyyy-MM-dd HH:mm:ss;FFF"
      ..Text = "2011-10-19 16:05:20,352",

    // 24:00 meaning "start of next day"
    new Data.ymd(2011, 10, 20)
      ..Pattern = "yyyy-MM-dd HH:mm:ss"
      ..Text = "2011-10-19 24:00:00",
    new Data.ymd(2011, 10, 20)
      ..Pattern = "yyyy-MM-dd HH:mm:ss"
      ..Text = "2011-10-19 24:00:00"
      ..Template = new LocalDateTime.fromYMDHMS(1970, 1, 1, 0, 5, 0),
    new Data.ymd(2011, 10, 20)
      ..Pattern = "yyyy-MM-dd HH:mm"
      ..Text = "2011-10-19 24:00",
    new Data.ymd(2011, 10, 20)
      ..Pattern = "yyyy-MM-dd HH"
      ..Text = "2011-10-19 24",
  ];

  @internal List<Data> FormatOnlyData = [
    new Data.ymd(2011, 10, 19, 16, 05, 20)
      ..Pattern = "ddd yyyy"
      ..Text = "Wed 2011",
    // Note trunction of the "89" nanoseconds; o and O are BCL roundtrip patterns, with tick precision.
    new Data(SampleLocalDateTime)
      ..Pattern = "o"
      ..Text = "1976-06-19T21:13:34.1234567",
    new Data(SampleLocalDateTime)
      ..Pattern = "O"
      ..Text = "1976-06-19T21:13:34.1234567"
  ];

  @internal List<Data> FormatAndParseData = [
    // Standard patterns (US)
    // Full date/time (short time)
    new Data(MsdnStandardExampleNoSeconds)
      ..Pattern = "f"
      ..Text = "Monday, June 15, 2009 1:45 PM"
      ..Culture = TestCultures.EnUs,
    // Full date/time (long time)
    new Data(MsdnStandardExampleNoMillis)
      ..Pattern = "F"
      ..Text = "Monday, June 15, 2009 1:45:30 PM"
      ..Culture = TestCultures.EnUs,
    // General date/time (short time)
    new Data(MsdnStandardExampleNoSeconds)
      ..Pattern = "g"
      ..Text = "6/15/2009 1:45 PM"
      ..Culture = TestCultures.EnUs,
    // General date/time (longtime)
    new Data(MsdnStandardExampleNoMillis)
      ..Pattern = "G"
      ..Text = "6/15/2009 1:45:30 PM"
      ..Culture = TestCultures.EnUs,
    // Round-trip (o and O - same effect)
    new Data(MsdnStandardExample)
      ..Pattern = "o"
      ..Text = "2009-06-15T13:45:30.0900000"
      ..Culture = TestCultures.EnUs,
    new Data(MsdnStandardExample)
      ..Pattern = "O"
      ..Text = "2009-06-15T13:45:30.0900000"
      ..Culture = TestCultures.EnUs,
    new Data(MsdnStandardExample)
      ..Pattern = "r"
      ..Text = "2009-06-15T13:45:30.090000000 (ISO)"
      ..Culture = TestCultures.EnUs,
    /*new Data(SampleLocalDateTimeCoptic) // todo: @SkipMe.unimplemented()
      ..Pattern = "r"
      ..Text = "1976-06-19T21:13:34.123456789 (Coptic)"
      ..Culture = TestCultures.EnUs,*/
    // Note: No RFC1123, as that requires a time zone.
    // Sortable / ISO8601
    new Data(MsdnStandardExampleNoMillis)
      ..Pattern = "s"
      ..Text = "2009-06-15T13:45:30"
      ..Culture = TestCultures.EnUs,

    // Standard patterns (French)
    new Data(MsdnStandardExampleNoSeconds)
      ..Pattern = "f"
      ..Text = "lundi 15 juin 2009 13:45"
      ..Culture = TestCultures.FrFr,
    new Data(MsdnStandardExampleNoMillis)
      ..Pattern = "F"
      ..Text = "lundi 15 juin 2009 13:45:30"
      ..Culture = TestCultures.FrFr,
    new Data(MsdnStandardExampleNoSeconds)
      ..Pattern = "g"
      ..Text = "15/06/2009 13:45"
      ..Culture = TestCultures.FrFr,
    new Data(MsdnStandardExampleNoMillis)
      ..Pattern = "G"
      ..Text = "15/06/2009 13:45:30"
      ..Culture = TestCultures.FrFr,
    // Culture has no impact on round-trip or sortable formats
    new Data(MsdnStandardExample)
      ..StandardPattern = LocalDateTimePattern.BclRoundtrip
      ..Pattern = "o"
      ..Text = "2009-06-15T13:45:30.0900000"
      ..Culture = TestCultures.FrFr,
    new Data(MsdnStandardExample)
      ..StandardPattern = LocalDateTimePattern.BclRoundtrip
      ..Pattern = "O"
      ..Text = "2009-06-15T13:45:30.0900000"
      ..Culture = TestCultures.FrFr,
    new Data(MsdnStandardExample)
      ..StandardPattern = LocalDateTimePattern.FullRoundtripWithoutCalendar
      ..Pattern = "R"
      ..Text = "2009-06-15T13:45:30.090000000"
      ..Culture = TestCultures.FrFr,
    new Data(MsdnStandardExample)
      ..StandardPattern = LocalDateTimePattern.FullRoundtrip
      ..Pattern = "r"
      ..Text = "2009-06-15T13:45:30.090000000 (ISO)"
      ..Culture = TestCultures.FrFr,
    new Data(MsdnStandardExampleNoMillis)
      ..StandardPattern = LocalDateTimePattern.GeneralIso
      ..Pattern = "s"
      ..Text = "2009-06-15T13:45:30"
      ..Culture = TestCultures.FrFr,
    new Data(SampleLocalDateTime)
      ..StandardPattern = LocalDateTimePattern.FullRoundtripWithoutCalendar
      ..Pattern = "R"
      ..Text = "1976-06-19T21:13:34.123456789"
      ..Culture = TestCultures.FrFr,
    new Data(SampleLocalDateTime)
      ..StandardPattern = LocalDateTimePattern.FullRoundtrip
      ..Pattern = "r"
      ..Text = "1976-06-19T21:13:34.123456789 (ISO)"
      ..Culture = TestCultures.FrFr,

    // Calendar patterns are invariant
    new Data(MsdnStandardExample)
      ..Pattern = "(c) uuuu-MM-dd'T'HH:mm:ss.FFFFFFFFF"
      ..Text = "(ISO) 2009-06-15T13:45:30.09"
      ..Culture = TestCultures.FrFr,
    new Data(MsdnStandardExample)
      ..Pattern = "uuuu-MM-dd(c)'T'HH:mm:ss.FFFFFFFFF"
      ..Text = "2009-06-15(ISO)T13:45:30.09"
      ..Culture = TestCultures.EnUs,
    /*new Data(SampleLocalDateTimeCoptic) // todo: @SkipMe.unimplemented()
      ..Pattern = "(c) uuuu-MM-dd'T'HH:mm:ss.FFFFFFFFF"
      ..Text = "(Coptic) 1976-06-19T21:13:34.123456789"
      ..Culture = TestCultures.FrFr,
    new Data(SampleLocalDateTimeCoptic)
      ..Pattern = "uuuu-MM-dd'C'c'T'HH:mm:ss.FFFFFFFFF"
      ..Text = "1976-06-19CCopticT21:13:34.123456789"
      ..Culture = TestCultures.EnUs,*/

    // Standard invariant patterns with a property but no pattern character
    new Data(MsdnStandardExample)
      ..StandardPattern = LocalDateTimePattern.ExtendedIso
      ..Pattern = "uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFF"
      ..Text = "2009-06-15T13:45:30.09"
      ..Culture = TestCultures.FrFr,

    // Use of the semi-colon "comma dot" specifier
    new Data.ymd(
        2011,
        10,
        19,
        16,
        05,
        20,
        352)
      ..Pattern = "yyyy-MM-dd HH:mm:ss;fff"
      ..Text = "2011-10-19 16:05:20.352",
    new Data.ymd(
        2011,
        10,
        19,
        16,
        05,
        20,
        352)
      ..Pattern = "yyyy-MM-dd HH:mm:ss;FFF"
      ..Text = "2011-10-19 16:05:20.352",
    new Data.ymd(
        2011,
        10,
        19,
        16,
        05,
        20,
        352)
      ..Pattern = "yyyy-MM-dd HH:mm:ss;FFF 'end'"
      ..Text = "2011-10-19 16:05:20.352 end",
    new Data.ymd(2011, 10, 19, 16, 05, 20)
      ..Pattern = "yyyy-MM-dd HH:mm:ss;FFF 'end'"
      ..Text = "2011-10-19 16:05:20 end",

    // When the AM designator is a leading subString of the PM designator...
    new Data.ymd(2011, 10, 19, 16, 05, 20)
      ..Pattern = "yyyy-MM-dd h:mm:ss tt"
      ..Text = "2011-10-19 4:05:20 FooBar"
      ..Culture = TestCultures.AwkwardAmPmDesignatorCulture,
    new Data.ymd(2011, 10, 19, 4, 05, 20)
      ..Pattern = "yyyy-MM-dd h:mm:ss tt"
      ..Text = "2011-10-19 4:05:20 Foo"
      ..Culture = TestCultures.AwkwardAmPmDesignatorCulture,

    // Current culture decimal separator is irrelevant when trimming the dot for truncated fractional settings
    new Data.ymd(2011, 10, 19, 4, 5, 6)
      ..Pattern = "yyyy-MM-dd HH:mm:ss.FFF"
      ..Text = "2011-10-19 04:05:06"
      ..Culture = TestCultures.FrFr,
    new Data.ymd(
        2011,
        10,
        19,
        4,
        5,
        6,
        123)
      ..Pattern = "yyyy-MM-dd HH:mm:ss.FFF"
      ..Text = "2011-10-19 04:05:06.123"
      ..Culture = TestCultures.FrFr,

    // Check that unquoted T still works.
    new Data.ymd(2012, 1, 31, 17, 36, 45)
      ..Text = "2012-01-31T17:36:45"
      ..Pattern = "yyyy-MM-ddTHH:mm:ss",

    // Custom embedded patterns (or mixture of custom and standard)
    new Data.ymd(
        2015,
        10,
        24,
        11,
        55,
        30,
        0)
      ..Pattern = "ld<yyyy*MM*dd>'X'lt<HH_mm_ss>"
      ..Text = "2015*10*24X11_55_30",
    new Data.ymd(
        2015,
        10,
        24,
        11,
        55,
        30,
        0)
      ..Pattern = "lt<HH_mm_ss>'Y'ld<yyyy*MM*dd>"
      ..Text = "11_55_30Y2015*10*24",
    new Data.ymd(
        2015,
        10,
        24,
        11,
        55,
        30,
        0)
      ..Pattern = "ld<d>'X'lt<HH_mm_ss>"
      ..Text = "10/24/2015X11_55_30",
    new Data.ymd(
        2015,
        10,
        24,
        11,
        55,
        30,
        0)
      ..Pattern = "ld<yyyy*MM*dd>'X'lt<T>"
      ..Text = "2015*10*24X11:55:30",

    // Standard embedded patterns (main use case of embedded patterns). Short time versions have a seconds value of 0 so they can round-trip.
    new Data.ymd(
        2015,
        10,
        24,
        11,
        55,
        30,
        90)
      ..Pattern = "ld<D> lt<r>"
      ..Text = "Saturday, 24 October 2015 11:55:30.09",
    new Data.ymd(2015, 10, 24, 11, 55, 0)
      ..Pattern = "ld<d> lt<t>"
      ..Text = "10/24/2015 11:55",
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);

  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);

  @Test() @SkipMe.unimplemented()
  void WithCalendar() {
    var pattern = LocalDateTimePattern.GeneralIso.WithCalendar(CalendarSystem.Coptic);
    var value = pattern
        .Parse("0284-08-29T12:34:56")
        .Value;
    expect(new LocalDateTime.fromYMDHMSC(
        284,
        8,
        29,
        12,
        34,
        56,
        CalendarSystem.Coptic), value);
  }

  @Test()
  void CreateWithCurrentCulture() {
    var dateTime = new LocalDateTime.fromYMDHMS(2017, 8, 23, 12, 34, 56);
    CultureInfo.currentCulture = TestCultures.FrFr;
    {
      var pattern = LocalDateTimePattern.CreateWithCurrentCulture("g");
      expect("23/08/2017 12:34", pattern.Format(dateTime));
    }
    /* todo: This test fails under .Net Core
    CultureInfo.currentCulture = TestCultures.FrCa;
    {
      var pattern = LocalDateTimePattern.CreateWithCurrentCulture("g");
      expect("2017-08-23 12:34", pattern.Format(dateTime));
    }*/
  }

  @Test()
  void ParseNull() => AssertParseNull(LocalDateTimePattern.ExtendedIso);

  /*
  @Test()
  @TestCaseSource(#AllCulturesStandardPatterns)
  void BclStandardPatternComparison(CultureInfo culture, String pattern) {
    AssertBclNodaEquality(culture, pattern);
  }*/

  @Test()
  @TestCaseSource(#AllCulturesStandardPatterns)
  void ParseFormattedStandardPattern(CultureInfo culture, String patternText) {
    var pattern = CreatePatternOrNull(patternText, culture, new LocalDateTime.fromYMDHM(2000, 1, 1, 0, 0));
    if (pattern == null) {
      return;
    }

    // If the pattern really can't distinguish between AM and PM (e.g. it's 12 hour with an
    // abbreviated AM/PM designator) then let's let it go.
    if (pattern.Format(SampleLocalDateTime) == pattern.Format(SampleLocalDateTime.PlusHours(-12))) {
      return;
    }

    // If the culture doesn't have either AM or PM designators, we'll end up using the template value
    // AM/PM, so let's make sure that's right. (This happens on Mono for a few cultures.)
    if (culture.dateTimeFormat.amDesignator == "" &&
        culture.dateTimeFormat.pmDesignator == "") {
      pattern = pattern.WithTemplateValue(new LocalDateTime.fromYMDHM(2000, 1, 1, 12, 0));
    }

    String formatted = pattern.Format(SampleLocalDateTime);
    var parseResult = pattern.Parse(formatted);
    expect(parseResult.Success, isTrue);
    var parsed = parseResult.Value;
    expect(parsed, anyOf(SampleLocalDateTime, SampleLocalDateTimeToTicks, SampleLocalDateTimeToMillis, SampleLocalDateTimeToSeconds, SampleLocalDateTimeToMinutes));

    /*Assert.That(parsed, Is.EqualTo(SampleLocalDateTime) |
    Is.EqualTo(SampleLocalDateTimeToTicks) |
    Is.EqualTo(SampleLocalDateTimeToMillis) |
    Is.EqualTo(SampleLocalDateTimeToSeconds) |
    Is.EqualTo(SampleLocalDateTimeToMinutes));*/
  }

  /*
  @private void AssertBclNodaEquality(CultureInfo culture, String patternText) {
    // On Mono, some general patterns include an offset at the end. For the moment, ignore them.
    // TODO(V1.2): Work out what to do in such cases...
    if ((patternText == "f" && culture.dateTimeFormat.shortTimePattern.endsWith("z")) ||
        (patternText == "F" && culture.dateTimeFormat.fullDateTimePattern.endsWith("z")) ||
        (patternText == "g" && culture.dateTimeFormat.shortTimePattern.endsWith("z")) ||
        (patternText == "G" && culture.dateTimeFormat.longTimePattern.endsWith("z"))) {
      return;
    }

    var pattern = CreatePatternOrNull(patternText, culture, LocalDateTimePattern.DefaultTemplateValue);
    if (pattern == null) {
      return;
    }

    // The BCL never seems to use abbreviated month genitive names.
    // I think it's reasonable that we do. Hmm.
    // See https://github.com/nodatime/nodatime/issues/377
    if ((patternText == "G" || patternText == "g") &&
        (culture.dateTimeFormat.shortDatePattern.contains("MMM") && !culture.dateTimeFormat.shortDatePattern.contains("MMMM")) &&
        culture.dateTimeFormat.abbreviatedMonthGenitiveNames[SampleLocalDateTime.Month - 1] !=
            culture.dateTimeFormat.abbreviatedMonthNames[SampleLocalDateTime.Month - 1]) {
      return;
    }

    // Formatting a DateTime with an always-invariant pattern (round-trip, sortable) converts to the ISO
    // calendar in .NET (which is reasonable, as there's no associated calendar).
    // We should use the Gregorian calendar for those tests.
    bool alwaysInvariantPattern = "Oos".Contains(patternText);
    Calendar calendar = alwaysInvariantPattern ? CultureInfo.invariantCulture.Calendar : culture.Calendar;

    var calendarSystem = BclCalendars.CalendarSystemForCalendar(calendar);
    if (calendarSystem == null) {
      // We can't map this calendar system correctly yet; the test would be invalid.
      return;
    }

    // Use the sample date/time, but in the target culture's calendar system, as near as we can get.
    // We need to specify the right calendar system so that the days of week align properly.
    var inputValue = SampleLocalDateTime.WithCalendar(calendarSystem);
    expect(inputValue.ToDateTimeUnspecified().toString(patternText, culture),
        pattern.Format(inputValue));
  }*/

  // Helper method to make it slightly easier for tests to skip "bad" cultures.
  @private LocalDateTimePattern CreatePatternOrNull(String patternText, CultureInfo culture, LocalDateTime templateValue) {
    try {
      return LocalDateTimePattern.Create3(patternText, culture);
    }
    catch (InvalidPatternException) {
      // The Malta long date/time pattern in Mono 3.0 is invalid (not just wrong; invalid due to the wrong number of quotes).
      // Skip it :(
      // See https://bugzilla.xamarin.com/show_bug.cgi?id=11363
      return null;
    }
  }
}

  /*sealed*/ class Data extends PatternTestData<LocalDateTime> {
  // Default to the start of the year 2000.
  /*protected*/ @override LocalDateTime get DefaultTemplate => LocalDateTimePattern.DefaultTemplateValue;

  /// Initializes a new instance of the [Data] class.
  ///
  /// [value]: The value.
  Data([LocalDateTime value = null])
      : super(value ?? LocalDateTimePattern.DefaultTemplateValue);

  Data.ymd(int year, int month, int day, [int hour = 0, int minute = 0, int second = 0, int millis = 0])
      : super(new LocalDateTime.fromYMDHMSM(
      year,
      month,
      day,
      hour,
      minute,
      second,
      millis));

  Data.dt(LocalDate date, LocalTime time) : super(date.at(time));


  @internal
  @override
  IPattern<LocalDateTime> CreatePattern() =>
      LocalDateTimePattern.CreateWithInvariantCulture(super.Pattern)
          .WithTemplateValue(Template)
          .WithCulture(Culture);
}


