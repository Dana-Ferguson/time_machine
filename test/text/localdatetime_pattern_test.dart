// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import '../time_machine_testing.dart';
import 'pattern_test_base.dart';
import 'pattern_test_data.dart';
import 'test_cultures.dart';

@private final List<String> AllStandardPatterns = [ 'f', "F", "g", "G", "o", "O", "s" ];
@private final List _AllCulturesStandardPatterns = [];

Future main() async {
  await TimeMachine.initialize();

  var sw = Stopwatch()..start();
  var ids = await Cultures.ids;
  var allCultures = <Culture>[];
  for(var id in ids) {
    allCultures.add((await Cultures.getCulture(id))!);
  }
  for(var culture in allCultures) {
    for(var format in AllStandardPatterns) {
      _AllCulturesStandardPatterns.add(TestCaseData([culture, format])..name = '$culture: $format');
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
    Data()
      ..pattern = ''
      ..message = TextErrorMessages.formatStringEmpty,
    Data()
      ..pattern = 'a'
      ..message = TextErrorMessages.unknownStandardFormat
      ..parameters.addAll(['a', 'LocalDateTime']),
    Data()
      ..pattern = 'dd MM yyyy HH:MM:SS'
      ..message = TextErrorMessages.repeatedFieldInPattern
      ..parameters.addAll(['M']),
    // Note incorrect use of 'u' (year) instead of "y" (year of era)
    Data()
      ..pattern = 'dd MM uuuu HH:mm:ss gg'
      ..message = TextErrorMessages.eraWithoutYearOfEra,
    // Era specifier and calendar specifier in the same pattern.
    Data()
      ..pattern = 'dd MM yyyy HH:mm:ss gg c'
      ..message = TextErrorMessages.calendarAndEra,
    // Embedded pattern start without ld or lt
    Data()
      ..pattern = 'yyyy MM dd <'
      ..message = TextErrorMessages.unquotedLiteral
      ..parameters.addAll(['<']),
    // Attempt to use a full embedded date/time pattern (not valid for LocalDateTime)
    Data()
      ..pattern = 'l<yyyy MM dd HH:mm>'
      ..message = TextErrorMessages.invalidEmbeddedPatternType,
    // Invalid nested pattern (local date pattern doesn't know about embedded patterns)
    Data()
      ..pattern = 'ld<<D>>'
      ..message = TextErrorMessages.unquotedLiteral
      ..parameters.addAll(['<']),
  ];

  @internal List<Data> ParseFailureData = [
    Data()
      ..pattern = 'dd MM yyyy HH:mm:ss'
      ..text = 'Complete mismatch'
      ..message = TextErrorMessages.mismatchedNumber
      ..parameters.addAll(['dd']),
    Data()
      ..pattern = '(c)'
      ..text = '(xxx)'
      ..message = TextErrorMessages.noMatchingCalendarSystem,
    // 24 as an hour is only valid when the time is midnight
    Data()
      ..pattern = 'yyyy-MM-dd'
      ..text = '2017-02-30'
      ..message = TextErrorMessages.dayOfMonthOutOfRange
      ..parameters.addAll([30, 2, 2017]),
    Data()
      ..pattern = 'yyyy-MM-dd HH:mm:ss'
      ..text = '2011-10-19 24:00:05'
      ..message = TextErrorMessages.invalidHour24,
    Data()
      ..pattern = 'yyyy-MM-dd HH:mm:ss'
      ..text = '2011-10-19 24:01:00'
      ..message = TextErrorMessages.invalidHour24,
    Data()
      ..pattern = 'yyyy-MM-dd HH:mm'
      ..text = '2011-10-19 24:01'
      ..message = TextErrorMessages.invalidHour24,
    Data()
      ..pattern = 'yyyy-MM-dd HH:mm'
      ..text = '2011-10-19 24:00'
      ..template = LocalDateTime(1970, 1, 1, 0, 0, 5)
      ..message = TextErrorMessages.invalidHour24,
    Data()
      ..pattern = 'yyyy-MM-dd HH'
      ..text = '2011-10-19 24'
      ..template = LocalDateTime(1970, 1, 1, 0, 5, 0)
      ..message = TextErrorMessages.invalidHour24,
  ];

  @internal List<Data> ParseOnlyData = [
    Data.ymd(2011, 10, 19, 16, 05, 20)
      ..pattern = 'dd MM yyyy'
      ..text = '19 10 2011'
      ..template = LocalDateTime(2000, 1, 1, 16, 05, 20),
    Data.ymd(2011, 10, 19, 16, 05, 20)
      ..pattern = 'HH:mm:ss'
      ..text = '16:05:20'
      ..template = LocalDateTime(2011, 10, 19, 0, 0, 0),
    // Parsing using the semi-colon 'comma dot' specifier
    Data.ymd(
        2011,
        10,
        19,
        16,
        05,
        20,
        352)
      ..pattern = 'yyyy-MM-dd HH:mm:ss;fff'
      ..text = '2011-10-19 16:05:20,352',
    Data.ymd(
        2011,
        10,
        19,
        16,
        05,
        20,
        352)
      ..pattern = 'yyyy-MM-dd HH:mm:ss;FFF'
      ..text = '2011-10-19 16:05:20,352',

    // 24:00 meaning 'start of next day'
    Data.ymd(2011, 10, 20)
      ..pattern = 'yyyy-MM-dd HH:mm:ss'
      ..text = '2011-10-19 24:00:00',
    Data.ymd(2011, 10, 20)
      ..pattern = 'yyyy-MM-dd HH:mm:ss'
      ..text = '2011-10-19 24:00:00'
      ..template = LocalDateTime(1970, 1, 1, 0, 5, 0),
    Data.ymd(2011, 10, 20)
      ..pattern = 'yyyy-MM-dd HH:mm'
      ..text = '2011-10-19 24:00',
    Data.ymd(2011, 10, 20)
      ..pattern = 'yyyy-MM-dd HH'
      ..text = '2011-10-19 24',
  ];

  @internal List<Data> FormatOnlyData = [
    Data.ymd(2011, 10, 19, 16, 05, 20)
      ..pattern = 'ddd yyyy'
      ..text = 'Wed 2011',
    // Note trunction of the '89' nanoseconds; o and O are BCL roundtrip patterns, with tick precision.
    Data(SampleLocalDateTime)
      ..pattern = 'o'
      ..text = '1976-06-19T21:13:34.1234567',
    Data(SampleLocalDateTime)
      ..pattern = 'O'
      ..text = '1976-06-19T21:13:34.1234567'
  ];

  @internal List<Data> FormatAndParseData = [
    // Standard patterns (US)
    // Full date/time (short time)
    Data(MsdnStandardExampleNoSeconds)
      ..pattern = 'f'
      ..text = 'Monday, June 15, 2009 1:45 PM'
      ..culture = TestCultures.EnUs,
    // Full date/time (long time)
    Data(MsdnStandardExampleNoMillis)
      ..pattern = 'F'
      ..text = 'Monday, June 15, 2009 1:45:30 PM'
      ..culture = TestCultures.EnUs,
    // General date/time (short time)
    Data(MsdnStandardExampleNoSeconds)
      ..pattern = 'g'
      ..text = '6/15/2009 1:45 PM'
      ..culture = TestCultures.EnUs,
    // General date/time (longtime)
    Data(MsdnStandardExampleNoMillis)
      ..pattern = 'G'
      ..text = '6/15/2009 1:45:30 PM'
      ..culture = TestCultures.EnUs,
    // Round-trip (o and O - same effect)
    Data(MsdnStandardExample)
      ..pattern = 'o'
      ..text = '2009-06-15T13:45:30.0900000'
      ..culture = TestCultures.EnUs,
    Data(MsdnStandardExample)
      ..pattern = 'O'
      ..text = '2009-06-15T13:45:30.0900000'
      ..culture = TestCultures.EnUs,
    Data(MsdnStandardExample)
      ..pattern = 'r'
      ..text = '2009-06-15T13:45:30.090000000 (ISO)'
      ..culture = TestCultures.EnUs,
    /*new Data(SampleLocalDateTimeCoptic) // todo: @SkipMe.unimplemented()
      ..Pattern = 'r'
      ..Text = '1976-06-19T21:13:34.123456789 (Coptic)'
      ..Culture = TestCultures.EnUs,*/
    // Note: No RFC1123, as that requires a time zone.
    // Sortable / ISO8601
    Data(MsdnStandardExampleNoMillis)
      ..pattern = 's'
      ..text = '2009-06-15T13:45:30'
      ..culture = TestCultures.EnUs,

    // Standard patterns (French)
    Data(MsdnStandardExampleNoSeconds)
      ..pattern = 'f'
      ..text = 'lundi 15 juin 2009 13:45'
      ..culture = TestCultures.FrFr,
    Data(MsdnStandardExampleNoMillis)
      ..pattern = 'F'
      ..text = 'lundi 15 juin 2009 13:45:30'
      ..culture = TestCultures.FrFr,
    Data(MsdnStandardExampleNoSeconds)
      ..pattern = 'g'
      ..text = '15/06/2009 13:45'
      ..culture = TestCultures.FrFr,
    Data(MsdnStandardExampleNoMillis)
      ..pattern = 'G'
      ..text = '15/06/2009 13:45:30'
      ..culture = TestCultures.FrFr,
    // Culture has no impact on round-trip or sortable formats
    Data(MsdnStandardExample)
      ..standardPattern = LocalDateTimePattern.roundtrip
      ..standardPatternCode = 'LocalDateTimePattern.bclRoundtrip'
      ..pattern = 'o'
      ..text = '2009-06-15T13:45:30.0900000'
      ..culture = TestCultures.FrFr,
    Data(MsdnStandardExample)
      ..standardPattern = LocalDateTimePattern.roundtrip
      ..standardPatternCode = 'LocalDateTimePattern.bclRoundtrip'
      ..pattern = 'O'
      ..text = '2009-06-15T13:45:30.0900000'
      ..culture = TestCultures.FrFr,
    Data(MsdnStandardExample)
      ..standardPattern = LocalDateTimePattern.fullRoundtripWithoutCalendar
      ..standardPatternCode = 'LocalDateTimePattern.fullRoundtripWithoutCalendar'
      ..pattern = 'R'
      ..text = '2009-06-15T13:45:30.090000000'
      ..culture = TestCultures.FrFr,
    Data(MsdnStandardExample)
      ..standardPattern = LocalDateTimePattern.fullRoundtrip
      ..standardPatternCode = 'LocalDateTimePattern.fullRoundtrip'
      ..pattern = 'r'
      ..text = '2009-06-15T13:45:30.090000000 (ISO)'
      ..culture = TestCultures.FrFr,
    Data(MsdnStandardExampleNoMillis)
      ..standardPattern = LocalDateTimePattern.generalIso
      ..standardPatternCode = 'LocalDateTimePattern.generalIso'
      ..pattern = 's'
      ..text = '2009-06-15T13:45:30'
      ..culture = TestCultures.FrFr,
    Data(SampleLocalDateTime)
      ..standardPattern = LocalDateTimePattern.fullRoundtripWithoutCalendar
      ..standardPatternCode = 'LocalDateTimePattern.fullRoundtripWithoutCalendar'
      ..pattern = 'R'
      ..text = '1976-06-19T21:13:34.123456789'
      ..culture = TestCultures.FrFr,
    Data(SampleLocalDateTime)
      ..standardPattern = LocalDateTimePattern.fullRoundtrip
      ..standardPatternCode = 'LocalDateTimePattern.fullRoundtrip'
      ..pattern = 'r'
      ..text = '1976-06-19T21:13:34.123456789 (ISO)'
      ..culture = TestCultures.FrFr,

    // Calendar patterns are invariant
    Data(MsdnStandardExample)
      ..pattern = "(c) uuuu-MM-dd'T'HH:mm:ss.FFFFFFFFF"
      ..text = '(ISO) 2009-06-15T13:45:30.09'
      ..culture = TestCultures.FrFr,
    Data(MsdnStandardExample)
      ..pattern = "uuuu-MM-dd(c)'T'HH:mm:ss.FFFFFFFFF"
      ..text = '2009-06-15(ISO)T13:45:30.09'
      ..culture = TestCultures.EnUs,
    /*new Data(SampleLocalDateTimeCoptic) // todo: @SkipMe.unimplemented()
      ..Pattern = "(c) uuuu-MM-dd'T'HH:mm:ss.FFFFFFFFF"
      ..Text = '(Coptic) 1976-06-19T21:13:34.123456789'
      ..Culture = TestCultures.FrFr,
    new Data(SampleLocalDateTimeCoptic)
      ..Pattern = "uuuu-MM-dd'C'c'T'HH:mm:ss.FFFFFFFFF"
      ..Text = '1976-06-19CCopticT21:13:34.123456789'
      ..Culture = TestCultures.EnUs,*/

    // Standard invariant patterns with a property but no pattern character
    Data(MsdnStandardExample)
      ..standardPattern = LocalDateTimePattern.extendedIso
      ..standardPatternCode = 'LocalDateTimePattern.extendedIso'
      ..pattern = "uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFF"
      ..text = '2009-06-15T13:45:30.09'
      ..culture = TestCultures.FrFr,

    // Use of the semi-colon 'comma dot' specifier
    Data.ymd(
        2011,
        10,
        19,
        16,
        05,
        20,
        352)
      ..pattern = 'yyyy-MM-dd HH:mm:ss;fff'
      ..text = '2011-10-19 16:05:20.352',
    Data.ymd(
        2011,
        10,
        19,
        16,
        05,
        20,
        352)
      ..pattern = 'yyyy-MM-dd HH:mm:ss;FFF'
      ..text = '2011-10-19 16:05:20.352',
    Data.ymd(
        2011,
        10,
        19,
        16,
        05,
        20,
        352)
      ..pattern = "yyyy-MM-dd HH:mm:ss;FFF 'end'"
      ..text = '2011-10-19 16:05:20.352 end',
    Data.ymd(2011, 10, 19, 16, 05, 20)
      ..pattern = "yyyy-MM-dd HH:mm:ss;FFF 'end'"
      ..text = '2011-10-19 16:05:20 end',

    // When the AM designator is a leading subString of the PM designator...
    Data.ymd(2011, 10, 19, 16, 05, 20)
      ..pattern = 'yyyy-MM-dd h:mm:ss tt'
      ..text = '2011-10-19 4:05:20 FooBar'
      ..culture = TestCultures.AwkwardAmPmDesignatorCulture,
    Data.ymd(2011, 10, 19, 4, 05, 20)
      ..pattern = 'yyyy-MM-dd h:mm:ss tt'
      ..text = '2011-10-19 4:05:20 Foo'
      ..culture = TestCultures.AwkwardAmPmDesignatorCulture,

    // Current culture decimal separator is irrelevant when trimming the dot for truncated fractional settings
    Data.ymd(2011, 10, 19, 4, 5, 6)
      ..pattern = 'yyyy-MM-dd HH:mm:ss.FFF'
      ..text = '2011-10-19 04:05:06'
      ..culture = TestCultures.FrFr,
    Data.ymd(
        2011,
        10,
        19,
        4,
        5,
        6,
        123)
      ..pattern = 'yyyy-MM-dd HH:mm:ss.FFF'
      ..text = '2011-10-19 04:05:06.123'
      ..culture = TestCultures.FrFr,

    // Check that unquoted T still works.
    Data.ymd(2012, 1, 31, 17, 36, 45)
      ..text = '2012-01-31T17:36:45'
      ..pattern = 'yyyy-MM-ddTHH:mm:ss',

    // Custom embedded patterns (or mixture of custom and standard)
    Data.ymd(
        2015,
        10,
        24,
        11,
        55,
        30,
        0)
      ..pattern = "ld<yyyy*MM*dd>'X'lt<HH_mm_ss>"
      ..text = '2015*10*24X11_55_30',
    Data.ymd(
        2015,
        10,
        24,
        11,
        55,
        30,
        0)
      ..pattern = "lt<HH_mm_ss>'Y'ld<yyyy*MM*dd>"
      ..text = '11_55_30Y2015*10*24',
    Data.ymd(
        2015,
        10,
        24,
        11,
        55,
        30,
        0)
      ..pattern = "ld<d>'X'lt<HH_mm_ss>"
      ..text = '10/24/2015X11_55_30',
    Data.ymd(
        2015,
        10,
        24,
        11,
        55,
        30,
        0)
      ..pattern = "ld<yyyy*MM*dd>'X'lt<T>"
      ..text = '2015*10*24X11:55:30',

    // Standard embedded patterns (main use case of embedded patterns). Short time versions have a seconds value of 0 so they can round-trip.
    Data.ymd(
        2015,
        10,
        24,
        11,
        55,
        30,
        90)
      ..pattern = 'ld<D> lt<r>'
      ..text = 'Saturday, 24 October 2015 11:55:30.09',
    Data.ymd(2015, 10, 24, 11, 55, 0)
      ..pattern = 'ld<d> lt<t>'
      ..text = '10/24/2015 11:55',
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);

  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);

  @Test()
  void WithCalendar() {
    var pattern = LocalDateTimePattern.generalIso.withCalendar(CalendarSystem.coptic);
    var value = pattern
        .parse('0284-08-29T12:34:56')
        .value;
    expect(LocalDateTime(
        284,
        8,
        29,
        12,
        34,
        56,
        calendar: CalendarSystem.coptic), value);
  }

  @Test()
  void CreateWithCurrentCulture() {
    var dateTime = LocalDateTime(2017, 8, 23, 12, 34, 56);
    Culture.current = TestCultures.FrFr;
    {
      var pattern = LocalDateTimePattern.createWithCurrentCulture('g');
      expect('23/08/2017 12:34', pattern.format(dateTime));
    }
    /* todo: This test fails under .Net Core
    Culture.currentCulture = TestCultures.FrCa;
    {
      var pattern = LocalDateTimePattern.CreateWithCurrentCulture('g');
      expect('2017-08-23 12:34', pattern.Format(dateTime));
    }*/
  }

  // @Test()
  // void ParseNull() => AssertParseNull(LocalDateTimePattern.extendedIso);

  /*
  @Test()
  @TestCaseSource(#AllCulturesStandardPatterns)
  void BclStandardPatternComparison(Culture culture, String pattern) {
    AssertBclNodaEquality(culture, pattern);
  }*/

  @Test()
  @TestCaseSource(#AllCulturesStandardPatterns)
  void ParseFormattedStandardPattern(Culture culture, String patternText) {
    var pattern = CreatePatternOrNull(patternText, culture, LocalDateTime(2000, 1, 1, 0, 0, 0));
    if (pattern == null) {
      return;
    }

    // If the pattern really can't distinguish between AM and PM (e.g. it's 12 hour with an
    // abbreviated AM/PM designator) then let's let it go.
    if (pattern.format(SampleLocalDateTime) == pattern.format(SampleLocalDateTime.addHours(-12))) {
      return;
    }

    // If the culture doesn't have either AM or PM designators, we'll end up using the template value
    // AM/PM, so let's make sure that's right. (This happens on Mono for a few cultures.)
    if (culture.dateTimeFormat.amDesignator == '' &&
        culture.dateTimeFormat.pmDesignator == '') {
      pattern = pattern.withTemplateValue(LocalDateTime(2000, 1, 1, 12, 0, 0));
    }

    String formatted = pattern.format(SampleLocalDateTime);
    var parseResult = pattern.parse(formatted);
    expect(parseResult.success, isTrue);
    var parsed = parseResult.value;
    expect(parsed, anyOf(SampleLocalDateTime, SampleLocalDateTimeToTicks, SampleLocalDateTimeToMillis, SampleLocalDateTimeToSeconds, SampleLocalDateTimeToMinutes));

    /*Assert.That(parsed, Is.EqualTo(SampleLocalDateTime) |
    Is.EqualTo(SampleLocalDateTimeToTicks) |
    Is.EqualTo(SampleLocalDateTimeToMillis) |
    Is.EqualTo(SampleLocalDateTimeToSeconds) |
    Is.EqualTo(SampleLocalDateTimeToMinutes));*/
  }

  /*
  @private void AssertBclNodaEquality(Culture culture, String patternText) {
    // On Mono, some general patterns include an offset at the end. For the moment, ignore them.
    // TODO(V1.2): Work out what to do in such cases...
    if ((patternText == 'f' && culture.dateTimeFormat.shortTimePattern.endsWith("z")) ||
        (patternText == 'F' && culture.dateTimeFormat.fullDateTimePattern.endsWith("z")) ||
        (patternText == 'g' && culture.dateTimeFormat.shortTimePattern.endsWith("z")) ||
        (patternText == 'G' && culture.dateTimeFormat.longTimePattern.endsWith("z"))) {
      return;
    }

    var pattern = CreatePatternOrNull(patternText, culture, LocalDateTimePattern.DefaultTemplateValue);
    if (pattern == null) {
      return;
    }

    // The BCL never seems to use abbreviated month genitive names.
    // I think it's reasonable that we do. Hmm.
    // See https://github.com/nodatime/nodatime/issues/377
    if ((patternText == 'G' || patternText == "g") &&
        (culture.dateTimeFormat.shortDatePattern.contains('MMM') && !culture.dateTimeFormat.shortDatePattern.contains("MMMM")) &&
        culture.dateTimeFormat.abbreviatedMonthGenitiveNames[SampleLocalDateTime.Month - 1] !=
            culture.dateTimeFormat.abbreviatedMonthNames[SampleLocalDateTime.Month - 1]) {
      return;
    }

    // Formatting a DateTime with an always-invariant pattern (round-trip, sortable) converts to the ISO
    // calendar in .NET (which is reasonable, as there's no associated calendar).
    // We should use the Gregorian calendar for those tests.
    bool alwaysInvariantPattern = 'Oos'.Contains(patternText);
    Calendar calendar = alwaysInvariantPattern ? Culture.invariantCulture.Calendar : culture.Calendar;

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

  // Helper method to make it slightly easier for tests to skip 'bad' cultures.
  @private LocalDateTimePattern? CreatePatternOrNull(String patternText, Culture culture, LocalDateTime templateValue) {
    try {
      return LocalDateTimePattern.createWithCulture(patternText, culture);
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
  /*protected*/ @override LocalDateTime get defaultTemplate => LocalDateTimePatterns.defaultTemplateValue;

  /// Initializes a new instance of the [Data] class.
  ///
  /// [value]: The value.
  Data([LocalDateTime? value])
      : super(value ?? LocalDateTimePatterns.defaultTemplateValue);

  Data.ymd(int year, int month, int day, [int hour = 0, int minute = 0, int second = 0, int millis = 0])
      : super(LocalDateTime(
      year,
      month,
      day,
      hour,
      minute,
      second,
      ms: millis));

  Data.dt(LocalDate date, LocalTime time) : super(date.at(time));


  @internal
  @override
  IPattern<LocalDateTime> CreatePattern() =>
      LocalDateTimePattern.createWithInvariantCulture(super.pattern)
          .withTemplateValue(template)
          .withCulture(culture);
}


