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
class OffsetDatePatternTest extends PatternTestBase<OffsetDate> {
  // The standard example date/time used in all the MSDN samples, which means we can just cut and paste
  // the expected results of the standard patterns. We've got an offset of 1 hour though.
  @private static final OffsetDate MsdnStandardExample = TestLocalDateTimes.MsdnStandardExample.calendarDate.withOffset(Offset.hours(1));
  @private static final OffsetDate MsdnStandardExampleNoMillis = TestLocalDateTimes.MsdnStandardExampleNoMillis.calendarDate.withOffset(Offset.hours(1));

// todo: @SkipMe.unimplemented()
// @private static final OffsetDate SampleOffsetDateCoptic = LocalDateTimePatternTest.SampleLocalDateTimeCoptic.Date.WithOffset(Offset.zero);

  @private static final Offset AthensOffset = Offset.hours(3);

  @internal final List<Data> InvalidPatternData = [
    Data()
      ..pattern = ''
      ..message = TextErrorMessages.formatStringEmpty,
    // Note incorrect use of 'u' (year) instead of "y" (year of era)
    Data()
      ..pattern = 'dd MM uuuu gg'
      ..message = TextErrorMessages.eraWithoutYearOfEra,
    // Era specifier and calendar specifier in the same pattern.
    Data()
      ..pattern = 'dd MM yyyy gg c'
      ..message = TextErrorMessages.calendarAndEra,
    Data()
      ..pattern = 'g'
      ..message = TextErrorMessages.unknownStandardFormat
      ..parameters.addAll(['g', 'OffsetDate']),
    // Invalid patterns involving embedded values
    Data()
      ..pattern = 'l<d> yyyy'
      ..message = TextErrorMessages.dateFieldAndEmbeddedDate,
    Data()
      ..pattern = 'l<yyyy-MM-dd> dd'
      ..message = TextErrorMessages.dateFieldAndEmbeddedDate,
    Data()
      ..pattern = 'l<d> l<f>'
      ..message = TextErrorMessages.repeatedFieldInPattern
      ..parameters.addAll(['l']),
    Data()
      ..pattern = r"l<\"
      ..message = TextErrorMessages.escapeAtEndOfString,
  ];

  @internal List<Data> ParseFailureData = [
    Data()
      ..pattern = 'dd MM yyyy'
      ..text = 'Complete mismatch'
      ..message = TextErrorMessages.mismatchedNumber
      ..parameters.addAll(['dd']),
    Data()
      ..pattern = 'dd MM yyyy'
      ..text = '29 02 2001'
      ..message = TextErrorMessages.dayOfMonthOutOfRange
      ..parameters.addAll([29, 2, 2001]),
    Data()
      ..pattern = '(c)'
      ..text = '(xxx)'
      ..message = TextErrorMessages.noMatchingCalendarSystem,
  ];

  @internal List<Data> ParseOnlyData = [];

  @internal List<Data> FormatOnlyData = [
    Data.ymdo(2011, 10, 19)
      ..pattern = 'ddd yyyy'
      ..text = 'Wed 2011',

    // Our template value has an offset of 0, but the value has an offset of 1.
    // The pattern doesn't include the offset, so that information is lost - no round-trip.
    Data(MsdnStandardExample)
      ..pattern = 'yyyy-MM-dd'
      ..text = '2009-06-15'
  ];

  @internal List<Data> FormatAndParseData = [
    // Copied from LocalDateTimePatternTest
    // Calendar patterns are invariant
    Data(MsdnStandardExample)
      ..pattern = '(c) uuuu-MM-dd o<G>'
      ..text = '(ISO) 2009-06-15 +01'
      ..culture = TestCultures.FrFr,
    Data(MsdnStandardExample)
      ..pattern = "uuuu-MM-dd(c';'o<g>)"
      ..text = '2009-06-15(ISO;+01)'
      ..culture = TestCultures.EnUs,
//new Data(SampleOffsetDateCoptic) ..Pattern = '(c) uuuu-MM-dd o<G>'..Text = "(Coptic) 1976-06-19 Z"..Culture = TestCultures.FrFr ,
//new Data(SampleOffsetDateCoptic) ..Pattern = "uuuu-MM-dd'C'c o<g>"..Text = "1976-06-19CCoptic +00"..Culture = TestCultures.EnUs ,

    // Standard patterns (all invariant)
    Data(MsdnStandardExampleNoMillis)
      ..standardPattern = OffsetDatePattern.generalIso
      ..standardPatternCode = 'OffsetDatePattern.generalIso'
      ..pattern = 'G'
      ..text = '2009-06-15+01'
      ..culture = TestCultures.FrFr,
    Data(MsdnStandardExample)
      ..standardPattern = OffsetDatePattern.fullRoundtrip
      ..standardPatternCode = 'OffsetDatePattern.fullRoundtrip'
      ..pattern = 'r'
      ..text = '2009-06-15+01 (ISO)'
      ..culture = TestCultures.FrFr,

    // Custom embedded patterns (or mixture of custom and standard)
    Data.ymdo(2015, 10, 24, AthensOffset)
      ..pattern = "l<yyyy*MM*dd>'X'o<g>"
      ..text = '2015*10*24X+03',
    Data.ymdo(2015, 10, 24, AthensOffset)
      ..pattern = "l<d>'X'o<g>"
      ..text = '10/24/2015X+03',

    // Standard embedded patterns.
    Data.ymdo(2015, 10, 24, AthensOffset)
      ..pattern = 'l<D> o<g>'
      ..text = 'Saturday, 24 October 2015 +03',
    Data.ymdo(2015, 10, 24, AthensOffset)
      ..pattern = 'l<d> o<g>'
      ..text = '10/24/2015 +03',

    // Fields not otherwise covered
    Data(MsdnStandardExample)
      ..pattern = 'd MMMM yyyy (g) o<g>'
      ..text = '15 June 2009 (A.D.) +01',
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);

  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);

  @Test()
  void CreateWithInvariantCulture() {
    var pattern = OffsetDatePattern.createWithInvariantCulture('yyyy-MM-ddo<g>');
    // Assert.AreSame(NodaFormatInfo.InvariantInfo, pattern.FormatInfo);
    expect(identical(TimeMachineFormatInfo.invariantInfo, OffsetDatePatterns.formatInfo(pattern)), isTrue);
    var od = LocalDate(2017, 8, 23).withOffset(Offset.hours(2));
    expect('2017-08-23+02', pattern.format(od));
  }

  @Test()
  void CreateWithCurrentCulture() {
    var od = LocalDate(2017, 8, 23).withOffset(Offset.hours(2));
    Culture.current = TestCultures.FrFr;
    {
      var pattern = OffsetDatePattern.createWithCurrentCulture('l<d> o<g>');
      expect('23/08/2017 +02', pattern.format(od));
    }
    Culture.current = TestCultures.FrCa;
    {
      var pattern = OffsetDatePattern.createWithCurrentCulture('l<d> o<g>');
      expect('2017-08-23 +02', pattern.format(od));
    }
  }

  @Test()
  void WithCulture() {
    var pattern = OffsetDatePattern.createWithInvariantCulture('yyyy/MM/dd o<G>').withCulture(TestCultures.FrCa);
    var text = pattern.format(LocalDate(2000, 1, 1).withOffset(Offset.hours(1)));
    expect('2000-01-01 +01', text);
  }

  @Test()
  void WithPatternText() {
    var pattern = OffsetDatePattern.createWithInvariantCulture('yyyy-MM-dd').withPatternText("dd MM yyyy o<g>");
    var value = LocalDate(1970, 1, 1).withOffset(Offset.hours(2));
    var text = pattern.format(value);
    expect('01 01 1970 +02', text);
  }

  @Test()
  void WithTemplateValue() {
    var pattern = OffsetDatePattern.createWithInvariantCulture('MM-dd')
        .withTemplateValue(LocalDate(1970, 1, 1).withOffset(Offset.hours(2)));
    var parsed = pattern
        .parse('08-23')
        .value;
    expect(LocalDate(1970, 8, 23), parsed.calendarDate);
    expect(Offset.hours(2), parsed.offset);
  }

  @Test()
  void WithCalendar() {
    var pattern = OffsetDatePattern.createWithInvariantCulture('yyyy-MM-dd')
        .withCalendar(CalendarSystem.coptic);
    var parsed = pattern
        .parse('0284-08-29')
        .value;
    expect(LocalDate(284, 8, 29, CalendarSystem.coptic), parsed.calendarDate);
  }

  // @Test()
  // void ParseNull() => AssertParseNull(OffsetDatePattern.generalIso);
}

@internal /*sealed*/ class Data extends PatternTestData<OffsetDate>
{
// Default to the start of the year 2000 UTC
/*protected*/ @override OffsetDate get defaultTemplate => OffsetDatePatterns.defaultTemplateValue;

/// Initializes a new instance of the [Data] class.
///
/// [value]: The value.
@internal Data([OffsetDate? value]) : super(value ?? OffsetDatePatterns.defaultTemplateValue);

@internal Data.ymdo(int year, int month, int day, [Offset? offset])
    : super(LocalDate(year, month, day).withOffset(offset ?? Offset.zero));

@internal @override IPattern<OffsetDate> CreatePattern() =>
    OffsetDatePattern.createWithCulture(super.pattern, super.culture, template);
}


