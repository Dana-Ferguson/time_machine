// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/Text/OffsetDatePatternTest.cs
// 41dc54e  on Nov 8, 2017
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

class LocalDateTimePatternTest {
@private static final LocalDateTime SampleLocalDateTime = new LocalDateTime.fromYMDHMS(1976, 6, 19, 21, 13, 34).PlusNanoseconds(123456789);
@private static final LocalDateTime SampleLocalDateTimeToTicks = new LocalDateTime.fromYMDHMS(1976, 6, 19, 21, 13, 34).PlusNanoseconds(123456700);
@private static final LocalDateTime SampleLocalDateTimeToMillis = new LocalDateTime.fromYMDHMSM(
1976,
6,
19,
21,
13,
34,
123);
@private static final LocalDateTime SampleLocalDateTimeToSeconds = new LocalDateTime.fromYMDHMS(1976, 6, 19, 21, 13, 34);
@private static final LocalDateTime SampleLocalDateTimeToMinutes = new LocalDateTime.fromYMDHM(1976, 6, 19, 21, 13);
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
@internal static final LocalDateTime MsdnStandardExample = new LocalDateTime.fromYMDHMSM(
2009,
06,
15,
13,
45,
30,
90);
@internal static final LocalDateTime MsdnStandardExampleNoMillis = new LocalDateTime.fromYMDHMS(2009, 06, 15, 13, 45, 30);
@private static final LocalDateTime MsdnStandardExampleNoSeconds = new LocalDateTime.fromYMDHM(2009, 06, 15, 13, 45);
}

@Test()
class OffsetDatePatternTest extends PatternTestBase<OffsetDate> {
// The standard example date/time used in all the MSDN samples, which means we can just cut and paste
// the expected results of the standard patterns. We've got an offset of 1 hour though.
  @private static final OffsetDate MsdnStandardExample = LocalDateTimePatternTest.MsdnStandardExample.Date.WithOffset(new Offset.fromHours(1));
  @private static final OffsetDate MsdnStandardExampleNoMillis = LocalDateTimePatternTest.MsdnStandardExampleNoMillis.Date.WithOffset(new Offset.fromHours(1));

// todo: @SkipMe.unimplemented()
// @private static final OffsetDate SampleOffsetDateCoptic = LocalDateTimePatternTest.SampleLocalDateTimeCoptic.Date.WithOffset(Offset.zero);

  @private static final Offset AthensOffset = new Offset.fromHours(3);

  @internal final List<Data> InvalidPatternData = [
    new Data()
      ..Pattern = ""
      ..Message = TextErrorMessages.FormatStringEmpty,
// Note incorrect use of "u" (year) instead of "y" (year of era)
    new Data()
      ..Pattern = "dd MM uuuu gg"
      ..Message = TextErrorMessages.EraWithoutYearOfEra,
// Era specifier and calendar specifier in the same pattern.
    new Data()
      ..Pattern = "dd MM yyyy gg c"
      ..Message = TextErrorMessages.CalendarAndEra,
    new Data()
      ..Pattern = "g"
      ..Message = TextErrorMessages.UnknownStandardFormat
      ..Parameters.addAll(['g', 'OffsetDate']),
// Invalid patterns involving embedded values
    new Data()
      ..Pattern = "l<d> yyyy"
      ..Message = TextErrorMessages.DateFieldAndEmbeddedDate,
    new Data()
      ..Pattern = "l<yyyy-MM-dd> dd"
      ..Message = TextErrorMessages.DateFieldAndEmbeddedDate,
    new Data()
      ..Pattern = "l<d> l<f>"
      ..Message = TextErrorMessages.RepeatedFieldInPattern
      ..Parameters.addAll(['l']),
    new Data()
      ..Pattern = r"l<\"
      ..Message = TextErrorMessages.EscapeAtEndOfString,
  ];

  @internal List<Data> ParseFailureData = [
    new Data()
      ..Pattern = "dd MM yyyy"
      ..Text = "Complete mismatch"
      ..Message = TextErrorMessages.MismatchedNumber
      ..Parameters.addAll(["dd"]),
    new Data()
      ..Pattern = "dd MM yyyy"
      ..Text = "29 02 2001"
      ..Message = TextErrorMessages.DayOfMonthOutOfRange
      ..Parameters.addAll([29, 2, 2001]),
    new Data()
      ..Pattern = "(c)"
      ..Text = "(xxx)"
      ..Message = TextErrorMessages.NoMatchingCalendarSystem,
  ];

  @internal List<Data> ParseOnlyData = [];

  @internal List<Data> FormatOnlyData = [
    new Data.ymdo(2011, 10, 19)
      ..Pattern = "ddd yyyy"
      ..Text = "Wed 2011",

// Our template value has an offset of 0, but the value has an offset of 1.
// The pattern doesn't include the offset, so that information is lost - no round-trip.
    new Data(MsdnStandardExample)
      ..Pattern = "yyyy-MM-dd"
      ..Text = "2009-06-15"
  ];

  @internal List<Data> FormatAndParseData = [
// Copied from LocalDateTimePatternTest
// Calendar patterns are invariant
    new Data(MsdnStandardExample)
      ..Pattern = "(c) uuuu-MM-dd o<G>"
      ..Text = "(ISO) 2009-06-15 +01"
      ..Culture = TestCultures.FrFr,
    new Data(MsdnStandardExample)
      ..Pattern = "uuuu-MM-dd(c';'o<g>)"
      ..Text = "2009-06-15(ISO;+01)"
      ..Culture = TestCultures.EnUs,
//new Data(SampleOffsetDateCoptic) ..Pattern = "(c) uuuu-MM-dd o<G>"..Text = "(Coptic) 1976-06-19 Z"..Culture = TestCultures.FrFr ,
//new Data(SampleOffsetDateCoptic) ..Pattern = "uuuu-MM-dd'C'c o<g>"..Text = "1976-06-19CCoptic +00"..Culture = TestCultures.EnUs ,

// Standard patterns (all invariant)
    new Data(MsdnStandardExampleNoMillis)
      ..StandardPattern = OffsetDatePattern.GeneralIso
      ..Pattern = "G"
      ..Text = "2009-06-15+01"
      ..Culture = TestCultures.FrFr,
    new Data(MsdnStandardExample)
      ..StandardPattern = OffsetDatePattern.FullRoundtrip
      ..Pattern = "r"
      ..Text = "2009-06-15+01 (ISO)"
      ..Culture = TestCultures.FrFr,

// Custom embedded patterns (or mixture of custom and standard)
    new Data.ymdo(2015, 10, 24, AthensOffset)
      ..Pattern = "l<yyyy*MM*dd>'X'o<g>"
      ..Text = "2015*10*24X+03",
    new Data.ymdo(2015, 10, 24, AthensOffset)
      ..Pattern = "l<d>'X'o<g>"
      ..Text = "10/24/2015X+03",

// Standard embedded patterns.
    new Data.ymdo(2015, 10, 24, AthensOffset)
      ..Pattern = "l<D> o<g>"
      ..Text = "Saturday, 24 October 2015 +03",
    new Data.ymdo(2015, 10, 24, AthensOffset)
      ..Pattern = "l<d> o<g>"
      ..Text = "10/24/2015 +03",

// Fields not otherwise covered
    new Data(MsdnStandardExample)
      ..Pattern = "d MMMM yyyy (g) o<g>"
      ..Text = "15 June 2009 (A.D.) +01",
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);

  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);

  @Test()
  void CreateWithInvariantCulture() {
    var pattern = OffsetDatePattern.CreateWithInvariantCulture("yyyy-MM-ddo<g>");
// Assert.AreSame(NodaFormatInfo.InvariantInfo, pattern.FormatInfo);
    expect(identical(NodaFormatInfo.InvariantInfo, pattern.FormatInfo), isTrue);
    var od = new LocalDate(2017, 8, 23).WithOffset(new Offset.fromHours(2));
    expect("2017-08-23+02", pattern.Format(od));
  }

  @Test()
  void CreateWithCurrentCulture() {
    var od = new LocalDate(2017, 8, 23).WithOffset(new Offset.fromHours(2));
    CultureInfo.currentCulture = TestCultures.FrFr;
    {
      var pattern = OffsetDatePattern.CreateWithCurrentCulture("l<d> o<g>");
      expect("23/08/2017 +02", pattern.Format(od));
    }
    CultureInfo.currentCulture = TestCultures.FrCa;
    {
      var pattern = OffsetDatePattern.CreateWithCurrentCulture("l<d> o<g>");
      expect("2017-08-23 +02", pattern.Format(od));
    }
  }

  @Test()
  void WithCulture() {
    var pattern = OffsetDatePattern.CreateWithInvariantCulture("yyyy/MM/dd o<G>").WithCulture(TestCultures.FrCa);
    var text = pattern.Format(new LocalDate(2000, 1, 1).WithOffset(new Offset.fromHours(1)));
    expect("2000-01-01 +01", text);
  }

  @Test()
  void WithPatternText() {
    var pattern = OffsetDatePattern.CreateWithInvariantCulture("yyyy-MM-dd").WithPatternText("dd MM yyyy o<g>");
    var value = new LocalDate(1970, 1, 1).WithOffset(new Offset.fromHours(2));
    var text = pattern.Format(value);
    expect("01 01 1970 +02", text);
  }

  @Test()
  void WithTemplateValue() {
    var pattern = OffsetDatePattern.CreateWithInvariantCulture("MM-dd")
        .WithTemplateValue(new LocalDate(1970, 1, 1).WithOffset(new Offset.fromHours(2)));
    var parsed = pattern
        .Parse("08-23")
        .Value;
    expect(new LocalDate(1970, 8, 23), parsed.date);
    expect(new Offset.fromHours(2), parsed.offset);
  }

  @Test()
  @SkipMe.unimplemented()
  void WithCalendar() {
    var pattern = OffsetDatePattern.CreateWithInvariantCulture("yyyy-MM-dd")
        .WithCalendar(CalendarSystem.Coptic);
    var parsed = pattern
        .Parse("0284-08-29")
        .Value;
    expect(new LocalDate.forCalendar(284, 8, 29, CalendarSystem.Coptic), parsed.date);
  }

  @Test()
  void ParseNull() => AssertParseNull(OffsetDatePattern.GeneralIso);
}

@internal /*sealed*/ class Data extends PatternTestData<OffsetDate>
{
// Default to the start of the year 2000 UTC
/*protected*/ @override OffsetDate get DefaultTemplate => OffsetDatePattern.DefaultTemplateValue;

/// <summary>
/// Initializes a new instance of the <see cref="Data" /> class.
/// </summary>
/// <param name="value">The value.</param>
@internal Data([OffsetDate value = null]) : super(value ?? OffsetDatePattern.DefaultTemplateValue)
{
}

@internal Data.ymdo(int year, int month, int day, [Offset offset = null])
    : super(new LocalDate(year, month, day).WithOffset(offset ?? Offset.zero));

@internal @override IPattern<OffsetDate> CreatePattern() =>
    OffsetDatePattern.Create2(super.Pattern, super.Culture, Template);
}

