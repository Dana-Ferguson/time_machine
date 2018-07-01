// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:mirrors';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';
import 'package:time_machine/src/text/time_machine_text.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

import '../time_machine_testing.dart';
import 'pattern_test_base.dart';
import 'pattern_test_data.dart';
import 'test_cultures.dart';

// Three zones with a deliberately leading-substring-matching set of names.
// Transition is at 1am local time, going forward an hour.
final SingleTransitionDateTimeZone TestZone1 = new SingleTransitionDateTimeZone.withId(
    new Instant.fromUtc(2010, 1, 1, 0, 0), new Offset.fromHours(1), new Offset.fromHours(2), "ab");

// Transition is at 2am local time, going back an hour.
final SingleTransitionDateTimeZone TestZone2 = new SingleTransitionDateTimeZone.withId(
    new Instant.fromUtc(2010, 1, 1, 0, 0), new Offset.fromHours(2), new Offset.fromHours(1), "abc");
final SingleTransitionDateTimeZone TestZone3 = new SingleTransitionDateTimeZone.withId(
    new Instant.fromUtc(2010, 1, 1, 0, 0), new Offset.fromHours(1), new Offset.fromHours(2), "abcd");


IDateTimeZoneProvider TestProvider;
IDateTimeZoneProvider Tzdb;
DateTimeZone France;
DateTimeZone Athens;
DateTimeZone etcGMT_12;

Future main() async {
  await TimeMachine.initialize();
  
  Tzdb = await DateTimeZoneProviders.tzdb;
  France = await Tzdb["Europe/Paris"];
  Athens = await Tzdb["Europe/Athens"];
  // etcGMT_12 = await Tzdb["Etc/GMT-12"];
  TestProvider = await new FakeDateTimeZoneSourceBuilder([TestZone1, TestZone2, TestZone3]).Build().ToProvider();

  // todo: implement CanonicalIdMap
  etcGMT_12 = new FixedDateTimeZone('Etc/GMT-12', new Offset.fromHours(12), '+12');

  await runTests();
}

@Test()
class ZonedDateTimePatternTest extends PatternTestBase<ZonedDateTime> {
  // @private static final IDateTimeZoneProvider TestProvider =
  // new FakeDateTimeZoneSourceBuilder([TestZone1, TestZone2, TestZone3]).Build().ToProvider();
  @private static final DateTimeZone FixedPlus1 = new FixedDateTimeZone.forOffset(new Offset.fromHours(1));
  @private static final DateTimeZone FixedWithMinutes = new FixedDateTimeZone.forOffset(new Offset.fromHoursAndMinutes(1, 30));
  @private static final DateTimeZone FixedWithSeconds = new FixedDateTimeZone.forOffset(new Offset.fromSeconds(5));
  @private static final DateTimeZone FixedMinus1 = new FixedDateTimeZone.forOffset(new Offset.fromHours(-1));

// todo: @SkipMe.unimplemented()
// @private static final ZonedDateTime SampleZonedDateTimeCoptic = TestLocalDateTimes.SampleLocalDateTimeCoptic.InUtc();

  // The standard example date/time used in all the MSDN samples, which means we can just cut and paste
  // the expected results of the standard patterns.
  @private static final ZonedDateTime MsdnStandardExample = TestLocalDateTimes.MsdnStandardExample.inUtc();
  @private static final ZonedDateTime MsdnStandardExampleNoMillis = TestLocalDateTimes.MsdnStandardExampleNoMillis.inUtc();

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
      ..Parameters.addAll(['g', 'ZonedDateTime']),
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
  ];

  @internal List<Data> ParseFailureData = [
    // Skipped value
    new Data()
      ..Pattern = "yyyy-MM-dd HH:mm z"
      ..text = "2010-01-01 01:30 ab"
      ..Message = TextErrorMessages.skippedLocalTime,
    // Ambiguous value
    new Data()
      ..Pattern = "yyyy-MM-dd HH:mm z"
      ..text = "2010-01-01 01:30 abc"
      ..Message = TextErrorMessages.ambiguousLocalTime,

    // Invalid offset within a skipped time
    new Data()
      ..Pattern = "yyyy-MM-dd HH:mm z o<g>"
      ..text = "2010-01-01 01:30 ab +01"
      ..Message = TextErrorMessages.invalidOffset,
    // Invalid offset within an ambiguous time (doesn't match either option)
    new Data()
      ..Pattern = "yyyy-MM-dd HH:mm z o<g>"
      ..text = "2010-01-01 01:30 abc +05"
      ..Message = TextErrorMessages.invalidOffset,
    // Invalid offset for an unambiguous time
    new Data()
      ..Pattern = "yyyy-MM-dd HH:mm z o<g>"
      ..text = "2005-01-01 01:30 ab +02"
      ..Message = TextErrorMessages.invalidOffset,

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
      ..Template = new LocalDateTime.at(1970, 1, 1, 0, 0, seconds: 5).inZoneStrictly(TestZone1)
      ..Message = TextErrorMessages.invalidHour24,
    new Data()
      ..Pattern = "yyyy-MM-dd HH"
      ..text = "2011-10-19 24"
      ..Template = new LocalDateTime.at(1970, 1, 1, 0, 5).inZoneStrictly(TestZone1)
      ..Message = TextErrorMessages.invalidHour24,

    // Redundant specification of fixed zone but not enough digits - we'll parse UTC+01:00:00 and unexpectedly be left with 00
    new Data()
      ..Pattern = "yyyy-MM-dd HH:mm z"
      ..text = "2013-01-13 15:44 UTC+01:00:00.00"
      ..Message = TextErrorMessages.extraValueCharacters
      ..Parameters.addAll([".00"]),

    // Can't parse a pattern with a time zone abbreviation.
    new Data()
      ..Pattern = "yyyy-MM-dd HH:mm x"
      ..text = "ignored"
      ..Message = TextErrorMessages.formatOnlyPattern,

    // Can't parse using a pattern that has no provider
    new Data()
      ..ZoneProvider = null
      ..Pattern = "yyyy-MM-dd z"
      ..text = "ignored"
      // note: ZoneProvider of null becomes the default provider now (for constructor condensation)
      ..Message = TextErrorMessages.mismatchedNumber // formatOnlyPattern,
      ..Parameters.addAll(["yyyy"]),

    // Invalid ID
    new Data()
      ..Pattern = "yyyy-MM-dd z"
      ..text = "2017-08-21 LemonCurdIceCream"
      ..Message = TextErrorMessages.noMatchingZoneId
  ];

  @internal List<Data> ParseOnlyData = [
    // Template value time zone is from a different provider, but it's not part of the pattern.
    new Data.b(2013, 1, 13, 16, 2, France)
      ..Pattern = "yyyy-MM-dd HH:mm"
      ..text = "2013-01-13 16:02"
      ..Template = TimeConstants.unixEpoch.inZone(France),

    // Skipped value, resolver returns start of second interval
    new Data(TestZone1.Transition.inZone(TestZone1))
      ..Pattern = "yyyy-MM-dd HH:mm z"
      ..text = "2010-01-01 01:30 ab"
      ..Resolver = Resolvers.createMappingResolver(Resolvers.throwWhenAmbiguous, Resolvers.returnStartOfIntervalAfter),

    // Skipped value, resolver returns end of first interval
    new Data(TestZone1.Transition.minus(Span.epsilon).inZone(TestZone1))
      ..Pattern = "yyyy-MM-dd HH:mm z"
      ..text = "2010-01-01 01:30 ab"
      ..Resolver = Resolvers.createMappingResolver(Resolvers.throwWhenAmbiguous, Resolvers.returnEndOfIntervalBefore),

    // Parse-only tests from LocalDateTimeTest.
    new Data.c(2011, 10, 19, 16, 05, 20)
      ..Pattern = "dd MM yyyy"
      ..text = "19 10 2011"
      ..Template = new LocalDateTime.at(2000, 1, 1, 16, 05, seconds: 20).inUtc(),
    new Data.c(2011, 10, 19, 16, 05, 20)
      ..Pattern = "HH:mm:ss"
      ..text = "16:05:20"
      ..Template = new LocalDateTime.at(2011, 10, 19, 0, 0).inUtc(),

    // Parsing using the semi-colon "comma dot" specifier
    new Data.d(
        2011,
        10,
        19,
        16,
        05,
        20,
        352)
      ..Pattern = "yyyy-MM-dd HH:mm:ss;fff"
      ..text = "2011-10-19 16:05:20,352",
    new Data.d(
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
    new Data.b(2011, 10, 20, 0, 0, TestZone1)
      ..Pattern = "yyyy-MM-dd HH:mm:ss"
      ..text = "2011-10-19 24:00:00"
      ..Template = new LocalDateTime.at(1970, 1, 1, 0, 5).inZoneStrictly(TestZone1),
    new Data.a(2011, 10, 20)
      ..Pattern = "yyyy-MM-dd HH:mm"
      ..text = "2011-10-19 24:00",
    new Data.a(2011, 10, 20)
      ..Pattern = "yyyy-MM-dd HH"
      ..text = "2011-10-19 24",

    // Redundant specification of offset
    new Data.b(2013, 01, 13, 15, 44, FixedPlus1)
      ..Pattern = "yyyy-MM-dd HH:mm z"
      ..text = "2013-01-13 15:44 UTC+01:00",
    new Data.b(2013, 01, 13, 15, 44, FixedPlus1)
      ..Pattern = "yyyy-MM-dd HH:mm z"
      ..text = "2013-01-13 15:44 UTC+01:00:00",
  ];

  @internal List<Data> FormatOnlyData = [
    new Data.c(2011, 10, 19, 16, 05, 20)
      ..Pattern = "ddd yyyy"
      ..text = "Wed 2011",

    // Time zone isn't in the provider
    new Data.b(2013, 1, 13, 16, 2, France)
      ..Pattern = "yyyy-MM-dd HH:mm z"
      ..text = "2013-01-13 16:02 Europe/Paris",

    // Ambiguous value - would be invalid if parsed with a strict parser.
    new Data(TestZone2.Transition.plus(new Span(minutes: 30)).inZone(TestZone2))
      ..Pattern = "yyyy-MM-dd HH:mm"
      ..text = "2010-01-01 01:30",

    // Winter
    new Data.b(2013, 1, 13, 16, 2, France)
      ..Pattern = "yyyy-MM-dd HH:mm x"
      ..text = "2013-01-13 16:02 CET",
    // Summer
    new Data.b(2013, 6, 13, 16, 2, France)
      ..Pattern = "yyyy-MM-dd HH:mm x"
      ..text = "2013-06-13 16:02 CEST",

    new Data.b(2013, 6, 13, 16, 2, France)
      ..ZoneProvider = null
      ..Pattern = "yyyy-MM-dd HH:mm z"
      ..text = "2013-06-13 16:02 Europe/Paris",

    // Standard patterns without a DateTimeZoneProvider
    new Data(MsdnStandardExampleNoMillis)
      ..StandardPattern = ZonedDateTimePattern.generalFormatOnlyIso
      ..StandardPatternCode = 'ZonedDateTimePattern.generalFormatOnlyIso'
      ..Pattern = "G"
      ..text = "2009-06-15T13:45:30 UTC (+00)"
      ..Culture = TestCultures.FrFr
      ..ZoneProvider = null,
    new Data(MsdnStandardExample)
      ..StandardPattern = ZonedDateTimePattern.extendedFormatOnlyIso
      ..StandardPatternCode = 'ZonedDateTimePattern.extendedFormatOnlyIso'
      ..Pattern = "F"
      ..text = "2009-06-15T13:45:30.09 UTC (+00)"
      ..Culture = TestCultures.FrFr
      ..ZoneProvider = null,
    // Standard patterns without a resolver
    new Data(MsdnStandardExampleNoMillis)
      ..StandardPattern = ZonedDateTimePattern.generalFormatOnlyIso
      ..StandardPatternCode = 'ZonedDateTimePattern.generalFormatOnlyIso'
      ..Pattern = "G"
      ..text = "2009-06-15T13:45:30 UTC (+00)"
      ..Culture = TestCultures.FrFr
      ..Resolver = null,
    new Data(MsdnStandardExample)
      ..StandardPattern = ZonedDateTimePattern.extendedFormatOnlyIso
      ..StandardPatternCode = 'ZonedDateTimePattern.extendedFormatOnlyIso'
      ..Pattern = "F"
      ..text = "2009-06-15T13:45:30.09 UTC (+00)"
      ..Culture = TestCultures.FrFr
      ..Resolver = null,
  ];

  @internal List<Data> FormatAndParseData = [

    // Zone ID at the end
    new Data.b(2013, 01, 13, 15, 44, TestZone1)
      ..Pattern = "yyyy-MM-dd HH:mm z"
      ..text = "2013-01-13 15:44 ab",
    new Data.b(2013, 01, 13, 15, 44, TestZone2)
      ..Pattern = "yyyy-MM-dd HH:mm z"
      ..text = "2013-01-13 15:44 abc",
    new Data.b(2013, 01, 13, 15, 44, TestZone3)
      ..Pattern = "yyyy-MM-dd HH:mm z"
      ..text = "2013-01-13 15:44 abcd",
    new Data.b(2013, 01, 13, 15, 44, FixedPlus1)
      ..Pattern = "yyyy-MM-dd HH:mm z"
      ..text = "2013-01-13 15:44 UTC+01",
    new Data.b(2013, 01, 13, 15, 44, FixedMinus1)
      ..Pattern = "yyyy-MM-dd HH:mm z"
      ..text = "2013-01-13 15:44 UTC-01",
    new Data.b(2013, 01, 13, 15, 44, DateTimeZone.utc)
      ..Pattern = "yyyy-MM-dd HH:mm z"
      ..text = "2013-01-13 15:44 UTC",

    // Zone ID at the start
    new Data.b(2013, 01, 13, 15, 44, TestZone1)
      ..Pattern = "z yyyy-MM-dd HH:mm"
      ..text = "ab 2013-01-13 15:44",
    new Data.b(2013, 01, 13, 15, 44, TestZone2)
      ..Pattern = "z yyyy-MM-dd HH:mm"
      ..text = "abc 2013-01-13 15:44",
    new Data.b(2013, 01, 13, 15, 44, TestZone3)
      ..Pattern = "z yyyy-MM-dd HH:mm"
      ..text = "abcd 2013-01-13 15:44",
    new Data.b(2013, 01, 13, 15, 44, FixedPlus1)
      ..Pattern = "z yyyy-MM-dd HH:mm"
      ..text = "UTC+01 2013-01-13 15:44",
    new Data.b(2013, 01, 13, 15, 44, FixedMinus1)
      ..Pattern = "z yyyy-MM-dd HH:mm"
      ..text = "UTC-01 2013-01-13 15:44",
    new Data.b(2013, 01, 13, 15, 44, DateTimeZone.utc)
      ..Pattern = "z yyyy-MM-dd HH:mm"
      ..text = "UTC 2013-01-13 15:44",

    // More precise fixed zones.
    new Data.b(2013, 01, 13, 15, 44, FixedWithMinutes)
      ..Pattern = "yyyy-MM-dd HH:mm z"
      ..text = "2013-01-13 15:44 UTC+01:30",
    new Data.b(2013, 01, 13, 15, 44, FixedWithSeconds)
      ..Pattern = "yyyy-MM-dd HH:mm z"
      ..text = "2013-01-13 15:44 UTC+00:00:05",

    // Valid offset for an unambiguous time
    new Data(new LocalDateTime.at(2005, 1, 1, 1, 30).inZoneStrictly(TestZone1))
      ..Pattern = "yyyy-MM-dd HH:mm z o<g>"
      ..text = "2005-01-01 01:30 ab +01",
    // Valid offset (in the middle of the pattern) for an unambiguous time
    new Data(new LocalDateTime.at(2005, 1, 1, 1, 30).inZoneStrictly(TestZone1))
      ..Pattern = "yyyy-MM-dd o<g> HH:mm z"
      ..text = "2005-01-01 +01 01:30 ab",

    // Ambiguous value, resolver returns later value.
    new Data(TestZone2.Transition.plus(new Span(minutes: 30)).inZone(TestZone2))
      ..Pattern = "yyyy-MM-dd HH:mm z"
      ..text = "2010-01-01 01:30 abc"
      ..Resolver = Resolvers.createMappingResolver(Resolvers.returnLater, Resolvers.throwWhenSkipped),

    // Ambiguous value, resolver returns earlier value.
    new Data(TestZone2.Transition.plus(new Span(minutes: -30)).inZone(TestZone2))
      ..Pattern = "yyyy-MM-dd HH:mm z"
      ..text = "2010-01-01 01:30 abc"
      ..Resolver = Resolvers.createMappingResolver(Resolvers.returnEarlier, Resolvers.throwWhenSkipped),

    // Ambiguous local value, but with offset for later value (smaller offset).
    new Data(TestZone2.Transition.plus(new Span(minutes: 30)).inZone(TestZone2))
      ..Pattern = "yyyy-MM-dd HH:mm z o<g>"
      ..text = "2010-01-01 01:30 abc +01",

    // Ambiguous local value, but with offset for earlier value (greater offset).
    new Data(TestZone2.Transition.plus(new Span(minutes: -30)).inZone(TestZone2))
      ..Pattern = "yyyy-MM-dd HH:mm z o<g>"
      ..text = "2010-01-01 01:30 abc +02",

    // Specify the provider
    new Data.b(2013, 1, 13, 16, 2, France)
      ..Pattern = "yyyy-MM-dd HH:mm z"
      ..text = "2013-01-13 16:02 Europe/Paris"
      ..ZoneProvider = Tzdb,

    // Tests without zones, copied from LocalDateTimePatternTest
    // Calendar patterns are invariant
    new Data(MsdnStandardExample)
      ..Pattern = "(c) uuuu-MM-dd'T'HH:mm:ss.FFFFFFF"
      ..text = "(ISO) 2009-06-15T13:45:30.09"
      ..Culture = TestCultures.FrFr,
    new Data(MsdnStandardExample)
      ..Pattern = "uuuu-MM-dd(c)'T'HH:mm:ss.FFFFFFF"
      ..text = "2009-06-15(ISO)T13:45:30.09"
      ..Culture = TestCultures.EnUs,
// todo: @SkipMe.unimplemented()
//new Data(SampleZonedDateTimeCoptic) ..Pattern = "(c) uuuu-MM-dd'T'HH:mm:ss.FFFFFFFFF"..Text = "(Coptic) 1976-06-19T21:13:34.123456789"..Culture = TestCultures.FrFr ,
//new Data(SampleZonedDateTimeCoptic) ..Pattern = "uuuu-MM-dd'C'c'T'HH:mm:ss.FFFFFFFFF"..Text = "1976-06-19CCopticT21:13:34.123456789"..Culture = TestCultures.EnUs ,

    // Use of the semi-colon "comma dot" specifier
    new Data.d(
        2011,
        10,
        19,
        16,
        05,
        20,
        352)
      ..Pattern = "yyyy-MM-dd HH:mm:ss;fff"
      ..text = "2011-10-19 16:05:20.352",
    new Data.d(
        2011,
        10,
        19,
        16,
        05,
        20,
        352)
      ..Pattern = "yyyy-MM-dd HH:mm:ss;FFF"
      ..text = "2011-10-19 16:05:20.352",
    new Data.d(
        2011,
        10,
        19,
        16,
        05,
        20,
        352)
      ..Pattern = "yyyy-MM-dd HH:mm:ss;FFF 'end'"
      ..text = "2011-10-19 16:05:20.352 end",
    new Data.c(2011, 10, 19, 16, 05, 20)
      ..Pattern = "yyyy-MM-dd HH:mm:ss;FFF 'end'"
      ..text = "2011-10-19 16:05:20 end",

    // Standard patterns with a time zone provider
    new Data.e(
        2013,
        01,
        13,
        15,
        44,
        30,
        0,
        TestZone1)
      ..StandardPattern = ZonedDateTimePattern.generalFormatOnlyIso.withZoneProvider(TestProvider)
      ..StandardPatternCode = 'ZonedDateTimePattern.generalFormatOnlyIso.withZoneProvider(TestProvider)'
      ..Pattern = "G"
      ..text = "2013-01-13T15:44:30 ab (+02)"
      ..Culture = TestCultures.FrFr,
    new Data.e(
        2013,
        01,
        13,
        15,
        44,
        30,
        90,
        TestZone1)
      ..StandardPattern = ZonedDateTimePattern.extendedFormatOnlyIso.withZoneProvider(TestProvider)
      ..StandardPatternCode = 'ZonedDateTimePattern.extendedFormatOnlyIso.withZoneProvider(TestProvider)'
      ..Pattern = "F"
      ..text = "2013-01-13T15:44:30.09 ab (+02)"
      ..Culture = TestCultures.FrFr,

    // Custom embedded patterns (or mixture of custom and standard)
    new Data.e(
        2015,
        10,
        24,
        11,
        55,
        30,
        0,
        Athens)
      ..Pattern = "ld<yyyy*MM*dd>'X'lt<HH_mm_ss> z o<g>"
      ..text = "2015*10*24X11_55_30 Europe/Athens +03"
      ..ZoneProvider = Tzdb,
    new Data.e(
        2015,
        10,
        24,
        11,
        55,
        30,
        0,
        Athens)
      ..Pattern = "lt<HH_mm_ss>'Y'ld<yyyy*MM*dd> z o<g>"
      ..text = "11_55_30Y2015*10*24 Europe/Athens +03"
      ..ZoneProvider = Tzdb,
    new Data.e(
        2015,
        10,
        24,
        11,
        55,
        30,
        0,
        Athens)
      ..Pattern = "l<HH_mm_ss'Y'yyyy*MM*dd> z o<g>"
      ..text = "11_55_30Y2015*10*24 Europe/Athens +03"
      ..ZoneProvider = Tzdb,
    new Data.e(
        2015,
        10,
        24,
        11,
        55,
        30,
        0,
        Athens)
      ..Pattern = "ld<d>'X'lt<HH_mm_ss> z o<g>"
      ..text = "10/24/2015X11_55_30 Europe/Athens +03"
      ..ZoneProvider = Tzdb,
    new Data.e(
        2015,
        10,
        24,
        11,
        55,
        30,
        0,
        Athens)
      ..Pattern = "ld<yyyy*MM*dd>'X'lt<T> z o<g>"
      ..text = "2015*10*24X11:55:30 Europe/Athens +03"
      ..ZoneProvider = Tzdb,

    // Standard embedded patterns. Short time versions have a seconds value of 0 so they can round-trip.
    new Data.e(
        2015,
        10,
        24,
        11,
        55,
        30,
        90,
        Athens)
      ..Pattern = "ld<D> lt<r> z o<g>"
      ..text = "Saturday, 24 October 2015 11:55:30.09 Europe/Athens +03"
      ..ZoneProvider = Tzdb,
    new Data.e(
        2015,
        10,
        24,
        11,
        55,
        0,
        0,
        Athens)
      ..Pattern = "l<f> z o<g>"
      ..text = "Saturday, 24 October 2015 11:55 Europe/Athens +03"
      ..ZoneProvider = Tzdb,
    new Data.e(
        2015,
        10,
        24,
        11,
        55,
        30,
        0,
        Athens)
      ..Pattern = "l<F> z o<g>"
      ..text = "Saturday, 24 October 2015 11:55:30 Europe/Athens +03"
      ..ZoneProvider = Tzdb,
    new Data.e(
        2015,
        10,
        24,
        11,
        55,
        0,
        0,
        Athens)
      ..Pattern = "l<g> z o<g>"
      ..text = "10/24/2015 11:55 Europe/Athens +03"
      ..ZoneProvider = Tzdb,
    new Data.e(
        2015,
        10,
        24,
        11,
        55,
        30,
        0,
        Athens)
      ..Pattern = "l<G> z o<g>"
      ..text = "10/24/2015 11:55:30 Europe/Athens +03"
      ..ZoneProvider = Tzdb,

    // Nested embedded patterns
    new Data.e(
        2015,
        10,
        24,
        11,
        55,
        30,
        90,
        Athens)
      ..Pattern = "l<ld<D> lt<r>> z o<g>"
      ..text = "Saturday, 24 October 2015 11:55:30.09 Europe/Athens +03"
      ..ZoneProvider = Tzdb,
    new Data.e(
        2015,
        10,
        24,
        11,
        55,
        30,
        0,
        Athens)
      ..Pattern = "l<'X'lt<HH_mm_ss>'Y'ld<yyyy*MM*dd>'X'> z o<g>"
      ..text = "X11_55_30Y2015*10*24X Europe/Athens +03"
      ..ZoneProvider = Tzdb,

    // Check that unquoted T still works.
    new Data.c(2012, 1, 31, 17, 36, 45)
      ..text = "2012-01-31T17:36:45"
      ..Pattern = "yyyy-MM-ddTHH:mm:ss",

    // Issue981
    new Data.e(
        1906,
        8,
        29,
        20,
        58,
        32,
        0,
        etcGMT_12)
      ..text = "1906-08-29T20:58:32 Etc/GMT-12 (+12)"
      ..Pattern = "uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFF z '('o<g>')'"
      ..ZoneProvider = Tzdb,

    // Fields not otherwise covered (according to tests running on AppVeyor...)
    new Data(MsdnStandardExample)
      ..Pattern = "d MMMM yyyy (g) h:mm:ss.FF tt"
      ..text = "15 June 2009 (A.D.) 1:45:30.09 PM",
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);

  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);

  @Test()
  void WithTemplateValue() {
    var pattern = ZonedDateTimePattern.createWithInvariantCulture("yyyy-MM-dd", TestProvider)
        .withTemplateValue(new Instant.fromUtc(1970, 1, 1, 11, 30).inZone(TestZone3));
    var parsed = pattern
        .parse("2017-08-23")
        .value;
    expect(identical(TestZone3, parsed.zone), isTrue);
    // TestZone3 is at UTC+1 in 1970, so the template value's *local* time is 12pm.
    // Even though we're parsing a date in 2017, it's the local time from the template value that's used.
    expect(new LocalDateTime.at(2017, 8, 23, 12, 30), parsed.localDateTime);
    expect(new Offset.fromHours(2), parsed.offset);
  }

  @Test()
  @SkipMe.unimplemented()
  void WithCalendar() {
    var pattern = ZonedDateTimePattern.createWithInvariantCulture("yyyy-MM-dd", TestProvider).withCalendar(CalendarSystem.coptic);
    var parsed = pattern
        .parse("0284-08-29")
        .value;
    expect(new LocalDateTime.at(284, 8, 29, 0, 0, calendar: CalendarSystem.coptic), parsed.localDateTime);
  }

  @Test()
  void WithPatternText() {
    var pattern = ZonedDateTimePattern.createWithInvariantCulture("yyyy", TestProvider).withPatternText("yyyy-MM-dd");
    var text = pattern.format(TimeConstants.unixEpoch.inUtc());
    expect("1970-01-01", text);
  }

  @Test()
  void CreateWithCurrentCulture() {
    CultureInfo.currentCulture = TestCultures.DotTimeSeparator;
    {
      var pattern = ZonedDateTimePattern.createWithCurrentCulture("HH:mm", null);
      var text = pattern.format(new Instant.fromUtc(2000, 1, 1, 19, 30).inUtc());
      expect("19.30", text);
    }
  }

  @Test()
  void WithCulture() {
    var pattern = ZonedDateTimePattern.createWithInvariantCulture("HH:mm", null).withCulture(TestCultures.DotTimeSeparator);
    var text = pattern.format(new Instant.fromUtc(2000, 1, 1, 19, 30).inUtc());
    expect("19.30", text);
  }

  // Test to hit each exit condition in the time zone ID parsing part of ZonedDateTimePatternParser
  @Test()
  Future FindLongestZoneId() async {
    DateTimeZone CreateZone(String id) =>
        new SingleTransitionDateTimeZone.withId(TimeConstants.unixEpoch - new Span(days: 1), new Offset.fromHours(-1), new Offset.fromHours(0), id);

    var source = (new FakeDateTimeZoneSourceBuilder(
        [CreateZone("ABC"),
        CreateZone("ABCA"),
        CreateZone("ABCB"),
        CreateZone("ABCBX"),
        CreateZone("ABCD")
        ]
    )).Build();

    var provider = await DateTimeZoneCache.getCache(source);
    var pattern = ZonedDateTimePattern.createWithCulture("z 'x'", CultureInfo.invariantCulture, Resolvers.strictResolver,
        provider, TimeConstants.unixEpoch.inUtc());

    for (var id in provider.ids) {
      var value = pattern
          .parse("$id x")
          .value;
      expect(id, value.zone.id);
    }
  }

  @Test()
  void ParseNull() => AssertParseNull(ZonedDateTimePattern.extendedFormatOnlyIso.withZoneProvider(TestProvider));
}

/*sealed*/class Data extends PatternTestData<ZonedDateTime> {
// Default to the start of the year 2000 UTC
/*protected*/ @override ZonedDateTime get DefaultTemplate => ZonedDateTimePatterns.defaultTemplateValue;

  @internal ZoneLocalMappingResolver Resolver;
  @internal IDateTimeZoneProvider ZoneProvider;

  /// Initializes a new instance of the [Data] class.
  ///
  /// [value]: The value.
  Data([ZonedDateTime value = null]) : super(value ?? ZonedDateTimePatterns.defaultTemplateValue) {
    Resolver = Resolvers.strictResolver;
    ZoneProvider = TestProvider;
  }

  Data.a(int year, int month, int day)
      : this(new LocalDateTime.at(year, month, day, 0, 0).inUtc());

  // Coincidentally, we don't specify time zones in tests other than the
  // ones which just go down to the date and hour/minute.
  Data.b(int year, int month, int day, int hour, int minute, DateTimeZone zone)
      : this(new LocalDateTime.at(year, month, day, hour, minute).inZoneStrictly(zone));

  Data.c(int year, int month, int day, int hour, int minute, int second)
      : this(new LocalDateTime.at(year, month, day, hour, minute, seconds: second).inUtc());

  Data.d(int year, int month, int day, int hour, int minute, int second, int millis)
      : this(new LocalDateTime.at(
      year,
      month,
      day,
      hour,
      minute,
      seconds: second,
      milliseconds: millis).inUtc());

  Data.e(int year, int month, int day, int hour, int minute, int second, int millis, DateTimeZone zone)
      : this(new LocalDateTime.at(
      year,
      month,
      day,
      hour,
      minute,
      seconds: second,
      milliseconds: millis).inZoneStrictly(zone));

  @internal
  @override
  IPattern<ZonedDateTime> CreatePattern() =>
      ZonedDateTimePattern.createWithCulture(super.Pattern, super.Culture, Resolver, ZoneProvider, Template);
}

