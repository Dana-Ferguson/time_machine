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

Future main() async {
  await runTests();
}

@Test()
class OffsetDateTimePatternTest extends PatternTestBase<OffsetDateTime> {
  // The standard example date/time used in all the MSDN samples, which means we can just cut and paste
  // the expected results of the standard patterns. We've got an offset of 1 hour though.
  @private static final OffsetDateTime MsdnStandardExample = TestLocalDateTimes.MsdnStandardExample.withOffset(Offset.hours(1));
  @private static final OffsetDateTime MsdnStandardExampleNoMillis = TestLocalDateTimes.MsdnStandardExampleNoMillis.withOffset(Offset.hours(1));

// todo: @SkipMe().unimplemented
// @private static final OffsetDateTime SampleOffsetDateTimeCoptic = LocalDateTimePatternTest.SampleLocalDateTimeCoptic.WithOffset(Offset.zero);

  @private static final Offset AthensOffset = Offset.hours(3);

  @internal final List<Data> InvalidPatternData = [
    Data()
      ..pattern = ''
      ..message = TextErrorMessages.formatStringEmpty,
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
    Data()
      ..pattern = 'g'
      ..message = TextErrorMessages.unknownStandardFormat
      ..parameters.addAll(['g', 'OffsetDateTime']),
    // Invalid patterns involving embedded values
    Data()
      ..pattern = 'ld<d> yyyy'
      ..message = TextErrorMessages.dateFieldAndEmbeddedDate,
    Data()
      ..pattern = 'l<yyyy-MM-dd HH:mm:ss> dd'
      ..message = TextErrorMessages.dateFieldAndEmbeddedDate,
    Data()
      ..pattern = 'ld<d> ld<f>'
      ..message = TextErrorMessages.repeatedFieldInPattern
      ..parameters.addAll(['l']),
    Data()
      ..pattern = 'lt<T> HH'
      ..message = TextErrorMessages.timeFieldAndEmbeddedTime,
    Data()
      ..pattern = 'l<yyyy-MM-dd HH:mm:ss> HH'
      ..message = TextErrorMessages.timeFieldAndEmbeddedTime,
    Data()
      ..pattern = 'lt<T> lt<t>'
      ..message = TextErrorMessages.repeatedFieldInPattern
      ..parameters.addAll(['l']),
    Data()
      ..pattern = 'ld<d> l<F>'
      ..message = TextErrorMessages.repeatedFieldInPattern
      ..parameters.addAll(['l']),
    Data()
      ..pattern = 'l<F> ld<d>'
      ..message = TextErrorMessages.repeatedFieldInPattern
      ..parameters.addAll(['l']),
    Data()
      ..pattern = 'lt<T> l<F>'
      ..message = TextErrorMessages.repeatedFieldInPattern
      ..parameters.addAll(['l']),
    Data()
      ..pattern = 'l<F> lt<T>'
      ..message = TextErrorMessages.repeatedFieldInPattern
      ..parameters.addAll(['l']),
    Data()
      ..pattern = r"l<\"
      ..message = TextErrorMessages.escapeAtEndOfString,
  ];

  @internal List<Data> ParseFailureData = [
    // Failures copied from LocalDateTimePatternTest
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
      ..template = LocalDateTime(1970, 1, 1, 0, 0, 5).withOffset(Offset.zero)
      ..message = TextErrorMessages.invalidHour24,
    Data()
      ..pattern = 'yyyy-MM-dd HH'
      ..text = '2011-10-19 24'
      ..template = LocalDateTime(1970, 1, 1, 0, 5, 0).withOffset(Offset.zero)
      ..message = TextErrorMessages.invalidHour24,

    Data()
      ..pattern = 'yyyy-MM-dd HH:mm:ss o<+HH>'
      ..text = '2011-10-19 16:02 +15:00'
      ..message = TextErrorMessages.timeSeparatorMismatch,
  ];

  @internal List<Data> ParseOnlyData = [
    // Parse-only tests from LocalDateTimeTest.
    Data.c(2011, 10, 19, 16, 05, 20)
      ..pattern = 'dd MM yyyy'
      ..text = '19 10 2011'
      ..template = LocalDateTime(2000, 1, 1, 16, 05, 20).withOffset(Offset.zero),
    Data.c(2011, 10, 19, 16, 05, 20)
      ..pattern = 'HH:mm:ss'
      ..text = '16:05:20'
      ..template = LocalDateTime(2011, 10, 19, 0, 0, 0).withOffset(Offset.zero),

    // Parsing using the semi-colon 'comma dot' specifier
    Data.e(
        2011,
        10,
        19,
        16,
        05,
        20,
        352)
      ..pattern = 'yyyy-MM-dd HH:mm:ss;fff'
      ..text = '2011-10-19 16:05:20,352',
    Data.e(
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
    Data.a(2011, 10, 20)
      ..pattern = 'yyyy-MM-dd HH:mm:ss'
      ..text = '2011-10-19 24:00:00',
    Data.b(2011, 10, 20, 0, 0, Offset.hours(1))
      ..pattern = 'yyyy-MM-dd HH:mm:ss o<+HH>'
      ..text = '2011-10-19 24:00:00 +01'
      ..template = LocalDateTime(1970, 1, 1, 0, 5, 0).withOffset(Offset.hours(-5)),
    Data.a(2011, 10, 20)
      ..pattern = 'yyyy-MM-dd HH:mm'
      ..text = '2011-10-19 24:00',
    Data.a(2011, 10, 20)
      ..pattern = 'yyyy-MM-dd HH'
      ..text = '2011-10-19 24',
  ];

  @internal List<Data> FormatOnlyData = [
    Data.c(2011, 10, 19, 16, 05, 20)
      ..pattern = 'ddd yyyy'
      ..text = 'Wed 2011',

    // Our template value has an offset of 0, but the value has an offset of 1... which is ignored by the pattern
    Data(MsdnStandardExample)
      ..pattern = 'yyyy-MM-dd HH:mm:ss.FF'
      ..text = '2009-06-15 13:45:30.09'
  ];

  @internal List<Data> FormatAndParseData = [
    // Copied from LocalDateTimePatternTest
    // Calendar patterns are invariant
    Data(MsdnStandardExample)
      ..pattern = "(c) uuuu-MM-dd'T'HH:mm:ss.FFFFFFF o<G>"
      ..text = '(ISO) 2009-06-15T13:45:30.09 +01'
      ..culture = TestCultures.FrFr,
    Data(MsdnStandardExample)
      ..pattern = "uuuu-MM-dd(c';'o<g>)'T'HH:mm:ss.FFFFFFF"
      ..text = '2009-06-15(ISO;+01)T13:45:30.09'
      ..culture = TestCultures.EnUs,

// todo: @SkipMe.unimplemented()
//new Data(SampleOffsetDateTimeCoptic) ..Pattern = "(c) uuuu-MM-dd'T'HH:mm:ss.FFFFFFFFF o<G>"..Text = "(Coptic) 1976-06-19T21:13:34.123456789 Z"..Culture = TestCultures.FrFr ,
//new Data(SampleOffsetDateTimeCoptic) ..Pattern = "uuuu-MM-dd'C'c'T'HH:mm:ss.FFFFFFFFF o<g>"..Text = "1976-06-19CCopticT21:13:34.123456789 +00"..Culture = TestCultures.EnUs ,

    // Standard patterns (all invariant)
    Data(MsdnStandardExampleNoMillis)
      ..standardPattern = OffsetDateTimePattern.generalIso
      ..standardPatternCode = 'OffsetDateTimePattern.generalIso'
      ..pattern = 'G'
      ..text = '2009-06-15T13:45:30+01'
      ..culture = TestCultures.FrFr,
    Data(MsdnStandardExample)
      ..standardPattern = OffsetDateTimePattern.extendedIso
      ..standardPatternCode = 'OffsetDateTimePattern.extendedIso'
      ..pattern = 'o'
      ..text = '2009-06-15T13:45:30.09+01'
      ..culture = TestCultures.FrFr,
    Data(MsdnStandardExample)
      ..standardPattern = OffsetDateTimePattern.fullRoundtrip
      ..standardPatternCode = 'OffsetDateTimePattern.fullRoundtrip'
      ..pattern = 'r'
      ..text = '2009-06-15T13:45:30.09+01 (ISO)'
      ..culture = TestCultures.FrFr,

    // Property-only patterns
    Data(MsdnStandardExample)
      ..standardPattern = OffsetDateTimePattern.rfc3339
      ..standardPatternCode = 'OffsetDateTimePattern.rfc3339'
      ..pattern = "uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFFo<Z+HH:mm>"
      ..text = '2009-06-15T13:45:30.09+01:00'
      ..culture = TestCultures.FrFr,

    // Custom embedded patterns (or mixture of custom and standard)
    Data.d(
        2015,
        10,
        24,
        11,
        55,
        30,
        AthensOffset)
      ..pattern = "ld<yyyy*MM*dd>'X'lt<HH_mm_ss> o<g>"
      ..text = '2015*10*24X11_55_30 +03',
    Data.d(
        2015,
        10,
        24,
        11,
        55,
        30,
        AthensOffset)
      ..pattern = "lt<HH_mm_ss>'Y'ld<yyyy*MM*dd> o<g>"
      ..text = '11_55_30Y2015*10*24 +03',
    Data.d(
        2015,
        10,
        24,
        11,
        55,
        30,
        AthensOffset)
      ..pattern = "l<HH_mm_ss'Y'yyyy*MM*dd> o<g>"
      ..text = '11_55_30Y2015*10*24 +03',
    Data.d(
        2015,
        10,
        24,
        11,
        55,
        30,
        AthensOffset)
      ..pattern = "ld<d>'X'lt<HH_mm_ss> o<g>"
      ..text = '10/24/2015X11_55_30 +03',
    Data.d(
        2015,
        10,
        24,
        11,
        55,
        30,
        AthensOffset)
      ..pattern = "ld<yyyy*MM*dd>'X'lt<T> o<g>"
      ..text = '2015*10*24X11:55:30 +03',

    // Standard embedded patterns. Short time versions have a seconds value of 0 so they can round-trip.
    Data.d(
        2015,
        10,
        24,
        11,
        55,
        30,
        AthensOffset)
      ..pattern = 'ld<D> lt<r> o<g>'
      ..text = 'Saturday, 24 October 2015 11:55:30 +03',
    Data.d(
        2015,
        10,
        24,
        11,
        55,
        0,
        AthensOffset)
      ..pattern = 'l<f> o<g>'
      ..text = 'Saturday, 24 October 2015 11:55 +03',
    Data.d(
        2015,
        10,
        24,
        11,
        55,
        30,
        AthensOffset)
      ..pattern = 'l<F> o<g>'
      ..text = 'Saturday, 24 October 2015 11:55:30 +03',
    Data.d(
        2015,
        10,
        24,
        11,
        55,
        0,
        AthensOffset)
      ..pattern = 'l<g> o<g>'
      ..text = '10/24/2015 11:55 +03',
    Data.d(
        2015,
        10,
        24,
        11,
        55,
        30,
        AthensOffset)
      ..pattern = 'l<G> o<g>'
      ..text = '10/24/2015 11:55:30 +03',

    // Nested embedded patterns
    Data.d(
        2015,
        10,
        24,
        11,
        55,
        30,
        AthensOffset)
      ..pattern = 'l<ld<D> lt<r>> o<g>'
      ..text = 'Saturday, 24 October 2015 11:55:30 +03',
    Data.d(
        2015,
        10,
        24,
        11,
        55,
        30,
        AthensOffset)
      ..pattern = "l<'X'lt<HH_mm_ss>'Y'ld<yyyy*MM*dd>'X'> o<g>"
      ..text = 'X11_55_30Y2015*10*24X +03',

    // Check that unquoted T still works.
    Data.c(2012, 1, 31, 17, 36, 45)
      ..text = '2012-01-31T17:36:45'
      ..pattern = 'yyyy-MM-ddTHH:mm:ss',

    // Fields not otherwise covered
    Data(MsdnStandardExample)
      ..pattern = 'd MMMM yyyy (g) h:mm:ss.FF tt o<g>'
      ..text = '15 June 2009 (A.D.) 1:45:30.09 PM +01',
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);

  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);

  @Test()
  void CreateWithInvariantCulture() {
    var pattern = OffsetDateTimePattern.createWithInvariantCulture("yyyy-MM-dd'T'HH:mm:sso<g>");
    expect(identical(TimeMachineFormatInfo.invariantInfo, OffsetDateTimePatterns.formatInfo(pattern)), isTrue);
    var odt = LocalDateTime(2017, 8, 23, 12, 34, 56).withOffset(Offset.hours(2));
    expect('2017-08-23T12:34:56+02', pattern.format(odt));
  }

  @Test()
  void CreateWithCurrentCulture() {
    var odt = LocalDateTime(2017, 8, 23, 12, 34, 56).withOffset(Offset.hours(2));
    Culture.current = TestCultures.FrFr;
    {
      var pattern = OffsetDateTimePattern.createWithCurrentCulture('l<g> o<g>');
      expect('23/08/2017 12:34 +02', pattern.format(odt));
    }

  // todo: @SkipMe() -- This is the same FrCA we've been seeing (.netCore ICU culture is different than windows culture)
  //    Cultures.currentCulture = TestCultures.FrCa;
  //    {
  //      var pattern = OffsetDateTimePattern.CreateWithCurrentCulture('l<g> o<g>');
  //      expect('2017-08-23 12:34 +02', pattern.Format(odt));
  //    }
  }

  @Test()
  void WithCulture() {
    var pattern = OffsetDateTimePattern.createWithInvariantCulture('HH:mm').withCulture(TestCultures.DotTimeSeparator);
    var text = pattern.format(Instant.utc(2000, 1, 1, 19, 30).withOffset(Offset.zero));
    expect('19.30', text);
  }

  @Test()
  void WithPatternText() {
    var pattern = OffsetDateTimePattern.createWithInvariantCulture('yyyy-MM-dd').withPatternText("HH:mm");
    var value = Instant.utc(1970, 1, 1, 11, 30).withOffset(Offset.hours(2));
    var text = pattern.format(value);
    expect('13:30', text);
  }

  @Test()
  void WithTemplateValue() {
    var pattern = OffsetDateTimePattern.createWithInvariantCulture('yyyy-MM-dd')
        .withTemplateValue(Instant.utc(1970, 1, 1, 11, 30).withOffset(Offset.hours(2)));
    var parsed = pattern
        .parse('2017-08-23')
        .value;
    // Local time of template value was 13:30
    expect(LocalDateTime(2017, 8, 23, 13, 30, 0), parsed.localDateTime);
    expect(Offset.hours(2), parsed.offset);
  }

  @Test()
  void WithCalendar() {
    var pattern = OffsetDateTimePattern.createWithInvariantCulture('yyyy-MM-dd')
        .withCalendar(CalendarSystem.coptic);
    var parsed = pattern
        .parse('0284-08-29')
        .value;
    expect(LocalDateTime(284, 8, 29, 0, 0, 0, calendar: CalendarSystem.coptic), parsed.localDateTime);
  }

  // @Test()
  // void ParseNull() => AssertParseNull(OffsetDateTimePattern.extendedIso);
}

@internal /*sealed*/ class Data extends PatternTestData<OffsetDateTime> {
  // Default to the start of the year 2000 UTC
  /*protected*/ @override OffsetDateTime get defaultTemplate => OffsetDateTimePatterns.defaultTemplateValue;

  /// Initializes a new instance of the [Data] class.
  ///
  /// [value]: The value.
  @internal Data([OffsetDateTime? value]) : super(value ?? OffsetDateTimePatterns.defaultTemplateValue);

  @internal Data.a(int year, int month, int day)
      : super(LocalDateTime(year, month, day, 0, 0, 0).withOffset(Offset.zero));

  @internal Data.b(int year, int month, int day, int hour, int minute, Offset offset)
      : super(LocalDateTime(year, month, day, hour, minute, 0).withOffset(offset));

  @internal Data.c(int year, int month, int day, int hour, int minute, int second)
      : super(LocalDateTime(year, month, day, hour, minute, second).withOffset(Offset.zero));

  @internal Data.d(int year, int month, int day, int hour, int minute, int second, Offset offset)
      : super(LocalDateTime(year, month, day, hour, minute, second).withOffset(offset));

  @internal Data.e(int year, int month, int day, int hour, int minute, int second, int millis)
      : super(LocalDateTime(
      year,
      month,
      day,
      hour,
      minute,
      second,
      ms: millis).withOffset(Offset.zero));


  @internal
  @override
  IPattern<OffsetDateTime> CreatePattern() =>
      OffsetDateTimePattern.createWithCulture(super.pattern, super.culture, template);
}

