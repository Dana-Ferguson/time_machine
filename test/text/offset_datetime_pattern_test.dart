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
  @private static final OffsetDateTime MsdnStandardExample = TestLocalDateTimes.MsdnStandardExample.withOffset(new Offset.fromHours(1));
  @private static final OffsetDateTime MsdnStandardExampleNoMillis = TestLocalDateTimes.MsdnStandardExampleNoMillis.withOffset(new Offset.fromHours(1));

// todo: @SkipMe().unimplemented
// @private static final OffsetDateTime SampleOffsetDateTimeCoptic = LocalDateTimePatternTest.SampleLocalDateTimeCoptic.WithOffset(Offset.zero);

  @private static final Offset AthensOffset = new Offset.fromHours(3);

  @internal final List<Data> InvalidPatternData = [
    new Data()
      ..Pattern = ""
      ..Message = TextErrorMessages.formatStringEmpty,
    new Data()
      ..Pattern = "dd MM yyyy HH:MM:SS"
      ..Message = TextErrorMessages.repeatedFieldInPattern
      ..Parameters.addAll(['M']),
    // Note incorrect use of "u" (year) instead of "y" (year of era)
    new Data()
      ..Pattern = "dd MM uuuu HH:mm:ss gg"
      ..Message = TextErrorMessages.eraWithoutYearOfEra,
    // Era specifier and calendar specifier in the same pattern.
    new Data()
      ..Pattern = "dd MM yyyy HH:mm:ss gg c"
      ..Message = TextErrorMessages.calendarAndEra,
    new Data()
      ..Pattern = "g"
      ..Message = TextErrorMessages.unknownStandardFormat
      ..Parameters.addAll(['g', 'OffsetDateTime']),
    // Invalid patterns involving embedded values
    new Data()
      ..Pattern = "ld<d> yyyy"
      ..Message = TextErrorMessages.dateFieldAndEmbeddedDate,
    new Data()
      ..Pattern = "l<yyyy-MM-dd HH:mm:ss> dd"
      ..Message = TextErrorMessages.dateFieldAndEmbeddedDate,
    new Data()
      ..Pattern = "ld<d> ld<f>"
      ..Message = TextErrorMessages.repeatedFieldInPattern
      ..Parameters.addAll(['l']),
    new Data()
      ..Pattern = "lt<T> HH"
      ..Message = TextErrorMessages.timeFieldAndEmbeddedTime,
    new Data()
      ..Pattern = "l<yyyy-MM-dd HH:mm:ss> HH"
      ..Message = TextErrorMessages.timeFieldAndEmbeddedTime,
    new Data()
      ..Pattern = "lt<T> lt<t>"
      ..Message = TextErrorMessages.repeatedFieldInPattern
      ..Parameters.addAll(['l']),
    new Data()
      ..Pattern = "ld<d> l<F>"
      ..Message = TextErrorMessages.repeatedFieldInPattern
      ..Parameters.addAll(['l']),
    new Data()
      ..Pattern = "l<F> ld<d>"
      ..Message = TextErrorMessages.repeatedFieldInPattern
      ..Parameters.addAll(['l']),
    new Data()
      ..Pattern = "lt<T> l<F>"
      ..Message = TextErrorMessages.repeatedFieldInPattern
      ..Parameters.addAll(['l']),
    new Data()
      ..Pattern = "l<F> lt<T>"
      ..Message = TextErrorMessages.repeatedFieldInPattern
      ..Parameters.addAll(['l']),
    new Data()
      ..Pattern = r"l<\"
      ..Message = TextErrorMessages.escapeAtEndOfString,
  ];

  @internal List<Data> ParseFailureData = [
    // Failures copied from LocalDateTimePatternTest
    new Data()
      ..Pattern = "dd MM yyyy HH:mm:ss"
      ..text = "Complete mismatch"
      ..Message = TextErrorMessages.mismatchedNumber
      ..Parameters.addAll(["dd"]),
    new Data()
      ..Pattern = "(c)"
      ..text = "(xxx)"
      ..Message = TextErrorMessages.noMatchingCalendarSystem,
    // 24 as an hour is only valid when the time is midnight
    new Data()
      ..Pattern = "yyyy-MM-dd HH:mm:ss"
      ..text = "2011-10-19 24:00:05"
      ..Message = TextErrorMessages.invalidHour24,
    new Data()
      ..Pattern = "yyyy-MM-dd HH:mm:ss"
      ..text = "2011-10-19 24:01:00"
      ..Message = TextErrorMessages.invalidHour24,
    new Data()
      ..Pattern = "yyyy-MM-dd HH:mm"
      ..text = "2011-10-19 24:01"
      ..Message = TextErrorMessages.invalidHour24,
    new Data()
      ..Pattern = "yyyy-MM-dd HH:mm"
      ..text = "2011-10-19 24:00"
      ..Template = new LocalDateTime.at(1970, 1, 1, 0, 0, seconds: 5).withOffset(Offset.zero)
      ..Message = TextErrorMessages.invalidHour24,
    new Data()
      ..Pattern = "yyyy-MM-dd HH"
      ..text = "2011-10-19 24"
      ..Template = new LocalDateTime.at(1970, 1, 1, 0, 5).withOffset(Offset.zero)
      ..Message = TextErrorMessages.invalidHour24,

    new Data()
      ..Pattern = "yyyy-MM-dd HH:mm:ss o<+HH>"
      ..text = "2011-10-19 16:02 +15:00"
      ..Message = TextErrorMessages.timeSeparatorMismatch,
  ];

  @internal List<Data> ParseOnlyData = [
    // Parse-only tests from LocalDateTimeTest.
    new Data.c(2011, 10, 19, 16, 05, 20)
      ..Pattern = "dd MM yyyy"
      ..text = "19 10 2011"
      ..Template = new LocalDateTime.at(2000, 1, 1, 16, 05, seconds: 20).withOffset(Offset.zero),
    new Data.c(2011, 10, 19, 16, 05, 20)
      ..Pattern = "HH:mm:ss"
      ..text = "16:05:20"
      ..Template = new LocalDateTime.at(2011, 10, 19, 0, 0).withOffset(Offset.zero),

    // Parsing using the semi-colon "comma dot" specifier
    new Data.e(
        2011,
        10,
        19,
        16,
        05,
        20,
        352)
      ..Pattern = "yyyy-MM-dd HH:mm:ss;fff"
      ..text = "2011-10-19 16:05:20,352",
    new Data.e(
        2011,
        10,
        19,
        16,
        05,
        20,
        352)
      ..Pattern = "yyyy-MM-dd HH:mm:ss;FFF"
      ..text = "2011-10-19 16:05:20,352",

    // 24:00 meaning "start of next day"
    new Data.a(2011, 10, 20)
      ..Pattern = "yyyy-MM-dd HH:mm:ss"
      ..text = "2011-10-19 24:00:00",
    new Data.b(2011, 10, 20, 0, 0, new Offset.fromHours(1))
      ..Pattern = "yyyy-MM-dd HH:mm:ss o<+HH>"
      ..text = "2011-10-19 24:00:00 +01"
      ..Template = new LocalDateTime.at(1970, 1, 1, 0, 5).withOffset(new Offset.fromHours(-5)),
    new Data.a(2011, 10, 20)
      ..Pattern = "yyyy-MM-dd HH:mm"
      ..text = "2011-10-19 24:00",
    new Data.a(2011, 10, 20)
      ..Pattern = "yyyy-MM-dd HH"
      ..text = "2011-10-19 24",
  ];

  @internal List<Data> FormatOnlyData = [
    new Data.c(2011, 10, 19, 16, 05, 20)
      ..Pattern = "ddd yyyy"
      ..text = "Wed 2011",

    // Our template value has an offset of 0, but the value has an offset of 1... which is ignored by the pattern
    new Data(MsdnStandardExample)
      ..Pattern = "yyyy-MM-dd HH:mm:ss.FF"
      ..text = "2009-06-15 13:45:30.09"
  ];

  @internal List<Data> FormatAndParseData = [
    // Copied from LocalDateTimePatternTest
    // Calendar patterns are invariant
    new Data(MsdnStandardExample)
      ..Pattern = "(c) uuuu-MM-dd'T'HH:mm:ss.FFFFFFF o<G>"
      ..text = "(ISO) 2009-06-15T13:45:30.09 +01"
      ..Culture = TestCultures.FrFr,
    new Data(MsdnStandardExample)
      ..Pattern = "uuuu-MM-dd(c';'o<g>)'T'HH:mm:ss.FFFFFFF"
      ..text = "2009-06-15(ISO;+01)T13:45:30.09"
      ..Culture = TestCultures.EnUs,

// todo: @SkipMe.unimplemented()
//new Data(SampleOffsetDateTimeCoptic) ..Pattern = "(c) uuuu-MM-dd'T'HH:mm:ss.FFFFFFFFF o<G>"..Text = "(Coptic) 1976-06-19T21:13:34.123456789 Z"..Culture = TestCultures.FrFr ,
//new Data(SampleOffsetDateTimeCoptic) ..Pattern = "uuuu-MM-dd'C'c'T'HH:mm:ss.FFFFFFFFF o<g>"..Text = "1976-06-19CCopticT21:13:34.123456789 +00"..Culture = TestCultures.EnUs ,

    // Standard patterns (all invariant)
    new Data(MsdnStandardExampleNoMillis)
      ..StandardPattern = OffsetDateTimePattern.generalIso
      ..StandardPatternCode = 'OffsetDateTimePattern.generalIso'
      ..Pattern = "G"
      ..text = "2009-06-15T13:45:30+01"
      ..Culture = TestCultures.FrFr,
    new Data(MsdnStandardExample)
      ..StandardPattern = OffsetDateTimePattern.extendedIso
      ..StandardPatternCode = 'OffsetDateTimePattern.extendedIso'
      ..Pattern = "o"
      ..text = "2009-06-15T13:45:30.09+01"
      ..Culture = TestCultures.FrFr,
    new Data(MsdnStandardExample)
      ..StandardPattern = OffsetDateTimePattern.fullRoundtrip
      ..StandardPatternCode = 'OffsetDateTimePattern.fullRoundtrip'
      ..Pattern = "r"
      ..text = "2009-06-15T13:45:30.09+01 (ISO)"
      ..Culture = TestCultures.FrFr,

    // Property-only patterns            
    new Data(MsdnStandardExample)
      ..StandardPattern = OffsetDateTimePattern.rfc3339
      ..StandardPatternCode = 'OffsetDateTimePattern.rfc3339'
      ..Pattern = "uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFFo<Z+HH:mm>"
      ..text = "2009-06-15T13:45:30.09+01:00"
      ..Culture = TestCultures.FrFr,

    // Custom embedded patterns (or mixture of custom and standard)
    new Data.d(
        2015,
        10,
        24,
        11,
        55,
        30,
        AthensOffset)
      ..Pattern = "ld<yyyy*MM*dd>'X'lt<HH_mm_ss> o<g>"
      ..text = "2015*10*24X11_55_30 +03",
    new Data.d(
        2015,
        10,
        24,
        11,
        55,
        30,
        AthensOffset)
      ..Pattern = "lt<HH_mm_ss>'Y'ld<yyyy*MM*dd> o<g>"
      ..text = "11_55_30Y2015*10*24 +03",
    new Data.d(
        2015,
        10,
        24,
        11,
        55,
        30,
        AthensOffset)
      ..Pattern = "l<HH_mm_ss'Y'yyyy*MM*dd> o<g>"
      ..text = "11_55_30Y2015*10*24 +03",
    new Data.d(
        2015,
        10,
        24,
        11,
        55,
        30,
        AthensOffset)
      ..Pattern = "ld<d>'X'lt<HH_mm_ss> o<g>"
      ..text = "10/24/2015X11_55_30 +03",
    new Data.d(
        2015,
        10,
        24,
        11,
        55,
        30,
        AthensOffset)
      ..Pattern = "ld<yyyy*MM*dd>'X'lt<T> o<g>"
      ..text = "2015*10*24X11:55:30 +03",

    // Standard embedded patterns. Short time versions have a seconds value of 0 so they can round-trip.
    new Data.d(
        2015,
        10,
        24,
        11,
        55,
        30,
        AthensOffset)
      ..Pattern = "ld<D> lt<r> o<g>"
      ..text = "Saturday, 24 October 2015 11:55:30 +03",
    new Data.d(
        2015,
        10,
        24,
        11,
        55,
        0,
        AthensOffset)
      ..Pattern = "l<f> o<g>"
      ..text = "Saturday, 24 October 2015 11:55 +03",
    new Data.d(
        2015,
        10,
        24,
        11,
        55,
        30,
        AthensOffset)
      ..Pattern = "l<F> o<g>"
      ..text = "Saturday, 24 October 2015 11:55:30 +03",
    new Data.d(
        2015,
        10,
        24,
        11,
        55,
        0,
        AthensOffset)
      ..Pattern = "l<g> o<g>"
      ..text = "10/24/2015 11:55 +03",
    new Data.d(
        2015,
        10,
        24,
        11,
        55,
        30,
        AthensOffset)
      ..Pattern = "l<G> o<g>"
      ..text = "10/24/2015 11:55:30 +03",

    // Nested embedded patterns
    new Data.d(
        2015,
        10,
        24,
        11,
        55,
        30,
        AthensOffset)
      ..Pattern = "l<ld<D> lt<r>> o<g>"
      ..text = "Saturday, 24 October 2015 11:55:30 +03",
    new Data.d(
        2015,
        10,
        24,
        11,
        55,
        30,
        AthensOffset)
      ..Pattern = "l<'X'lt<HH_mm_ss>'Y'ld<yyyy*MM*dd>'X'> o<g>"
      ..text = "X11_55_30Y2015*10*24X +03",

    // Check that unquoted T still works.
    new Data.c(2012, 1, 31, 17, 36, 45)
      ..text = "2012-01-31T17:36:45"
      ..Pattern = "yyyy-MM-ddTHH:mm:ss",

    // Fields not otherwise covered
    new Data(MsdnStandardExample)
      ..Pattern = "d MMMM yyyy (g) h:mm:ss.FF tt o<g>"
      ..text = "15 June 2009 (A.D.) 1:45:30.09 PM +01",
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);

  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);

  @Test()
  void CreateWithInvariantCulture() {
    var pattern = OffsetDateTimePattern.createWithInvariantCulture("yyyy-MM-dd'T'HH:mm:sso<g>");
    expect(identical(TimeMachineFormatInfo.invariantInfo, OffsetDateTimePatterns.formatInfo(pattern)), isTrue);
    var odt = new LocalDateTime.at(2017, 8, 23, 12, 34, seconds: 56).withOffset(new Offset.fromHours(2));
    expect("2017-08-23T12:34:56+02", pattern.format(odt));
  }

  @Test()
  void CreateWithCurrentCulture() {
    var odt = new LocalDateTime.at(2017, 8, 23, 12, 34, seconds: 56).withOffset(new Offset.fromHours(2));
    CultureInfo.currentCulture = TestCultures.FrFr;
    {
      var pattern = OffsetDateTimePattern.createWithCurrentCulture("l<g> o<g>");
      expect("23/08/2017 12:34 +02", pattern.format(odt));
    }

  // todo: @SkipMe() -- This is the same FrCA we've been seeing (.netCore ICU culture is different than windows culture)
  //    CultureInfo.currentCulture = TestCultures.FrCa;
  //    {
  //      var pattern = OffsetDateTimePattern.CreateWithCurrentCulture("l<g> o<g>");
  //      expect("2017-08-23 12:34 +02", pattern.Format(odt));
  //    }
  }

  @Test()
  void WithCulture() {
    var pattern = OffsetDateTimePattern.createWithInvariantCulture("HH:mm").withCulture(TestCultures.DotTimeSeparator);
    var text = pattern.format(new Instant.fromUtc(2000, 1, 1, 19, 30).withOffset(Offset.zero));
    expect("19.30", text);
  }

  @Test()
  void WithPatternText() {
    var pattern = OffsetDateTimePattern.createWithInvariantCulture("yyyy-MM-dd").withPatternText("HH:mm");
    var value = new Instant.fromUtc(1970, 1, 1, 11, 30).withOffset(new Offset.fromHours(2));
    var text = pattern.format(value);
    expect("13:30", text);
  }

  @Test()
  void WithTemplateValue() {
    var pattern = OffsetDateTimePattern.createWithInvariantCulture("yyyy-MM-dd")
        .withTemplateValue(new Instant.fromUtc(1970, 1, 1, 11, 30).withOffset(new Offset.fromHours(2)));
    var parsed = pattern
        .parse("2017-08-23")
        .value;
    // Local time of template value was 13:30
    expect(new LocalDateTime.at(2017, 8, 23, 13, 30), parsed.localDateTime);
    expect(new Offset.fromHours(2), parsed.offset);
  }

  @Test()
  @SkipMe.unimplemented()
  void WithCalendar() {
    var pattern = OffsetDateTimePattern.createWithInvariantCulture("yyyy-MM-dd")
        .withCalendar(CalendarSystem.coptic);
    var parsed = pattern
        .parse("0284-08-29")
        .value;
    expect(new LocalDateTime.at(284, 8, 29, 0, 0, calendar: CalendarSystem.coptic), parsed.localDateTime);
  }

  @Test()
  void ParseNull() => AssertParseNull(OffsetDateTimePattern.extendedIso);
}

@internal /*sealed*/ class Data extends PatternTestData<OffsetDateTime> {
  // Default to the start of the year 2000 UTC
  /*protected*/ @override OffsetDateTime get DefaultTemplate => OffsetDateTimePatterns.defaultTemplateValue;

  /// Initializes a new instance of the [Data] class.
  ///
  /// [value]: The value.
  @internal Data([OffsetDateTime value = null]) : super(value ?? OffsetDateTimePatterns.defaultTemplateValue);

  @internal Data.a(int year, int month, int day)
      : super(new LocalDateTime.at(year, month, day, 0, 0).withOffset(Offset.zero));

  @internal Data.b(int year, int month, int day, int hour, int minute, Offset offset)
      : super(new LocalDateTime.at(year, month, day, hour, minute).withOffset(offset));

  @internal Data.c(int year, int month, int day, int hour, int minute, int second)
      : super(new LocalDateTime.at(year, month, day, hour, minute, seconds: second).withOffset(Offset.zero));

  @internal Data.d(int year, int month, int day, int hour, int minute, int second, Offset offset)
      : super(new LocalDateTime.at(year, month, day, hour, minute, seconds: second).withOffset(offset));

  @internal Data.e(int year, int month, int day, int hour, int minute, int second, int millis)
      : super(new LocalDateTime.at(
      year,
      month,
      day,
      hour,
      minute,
      seconds: second,
      milliseconds: millis).withOffset(Offset.zero));


  @internal
  @override
  IPattern<OffsetDateTime> CreatePattern() =>
      OffsetDateTimePattern.createWithCulture(super.Pattern, super.Culture, Template);
}

