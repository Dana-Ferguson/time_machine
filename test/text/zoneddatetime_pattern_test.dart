// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

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
final SingleTransitionDateTimeZone TestZone1 = SingleTransitionDateTimeZone.withId(
    Instant.utc(2010, 1, 1, 0, 0), Offset.hours(1), Offset.hours(2), 'ab');

// Transition is at 2am local time, going back an hour.
final SingleTransitionDateTimeZone TestZone2 = SingleTransitionDateTimeZone.withId(
    Instant.utc(2010, 1, 1, 0, 0), Offset.hours(2), Offset.hours(1), 'abc');
final SingleTransitionDateTimeZone TestZone3 = SingleTransitionDateTimeZone.withId(
    Instant.utc(2010, 1, 1, 0, 0), Offset.hours(1), Offset.hours(2), 'abcd');


late DateTimeZoneProvider TestProvider;
late DateTimeZoneProvider tzdb;
late DateTimeZone france;
late DateTimeZone athens;
late DateTimeZone etcGMT_12;
late DateTimeZoneProvider etcGMT_12_tzdb;

Future main() async {
  await TimeMachine.initialize();
  await setup();

  await runTests();
}

Future setup() async {
  tzdb = await DateTimeZoneProviders.tzdb;
  france = await tzdb['Europe/Paris'];
  athens = await tzdb['Europe/Athens'];
  // etcGMT_12 = await tzdb['Etc/GMT-12'];
  TestProvider = await FakeDateTimeZoneSourceBuilder([TestZone1, TestZone2, TestZone3]).Build().ToProvider();

  // todo: implement CanonicalIdMap
  etcGMT_12 = FixedDateTimeZone('Etc/GMT-12', Offset.hours(12), '+12');
  etcGMT_12_tzdb = await FakeDateTimeZoneSourceBuilder([etcGMT_12]).Build().ToProvider();
}

@Test()
class ZonedDateTimePatternTest extends PatternTestBase<ZonedDateTime> {
  // @private static final IDateTimeZoneProvider TestProvider =
  // new FakeDateTimeZoneSourceBuilder([TestZone1, TestZone2, TestZone3]).Build().ToProvider();
  @private static final DateTimeZone FixedPlus1 = FixedDateTimeZone.forOffset(Offset.hours(1));
  @private static final DateTimeZone FixedWithMinutes = FixedDateTimeZone.forOffset(Offset.hoursAndMinutes(1, 30));
  @private static final DateTimeZone FixedWithSeconds = FixedDateTimeZone.forOffset(Offset(5));
  @private static final DateTimeZone FixedMinus1 = FixedDateTimeZone.forOffset(Offset.hours(-1));

// todo: @SkipMe.unimplemented()
// @private static final ZonedDateTime SampleZonedDateTimeCoptic = TestLocalDateTimes.SampleLocalDateTimeCoptic.InUtc();

  // The standard example date/time used in all the MSDN samples, which means we can just cut and paste
  // the expected results of the standard patterns.
  @private static final ZonedDateTime MsdnStandardExample = TestLocalDateTimes.MsdnStandardExample.inUtc();
  @private static final ZonedDateTime MsdnStandardExampleNoMillis = TestLocalDateTimes.MsdnStandardExampleNoMillis.inUtc();

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
      ..parameters.addAll(['g', 'ZonedDateTime']),
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
  ];

  @internal List<Data> ParseFailureData = [
    // Skipped value
    Data()
      ..pattern = 'yyyy-MM-dd HH:mm z'
      ..text = '2010-01-01 01:30 ab'
      ..message = TextErrorMessages.skippedLocalTime,
    // Ambiguous value
    Data()
      ..pattern = 'yyyy-MM-dd HH:mm z'
      ..text = '2010-01-01 01:30 abc'
      ..message = TextErrorMessages.ambiguousLocalTime,

    // Invalid offset within a skipped time
    Data()
      ..pattern = 'yyyy-MM-dd HH:mm z o<g>'
      ..text = '2010-01-01 01:30 ab +01'
      ..message = TextErrorMessages.invalidOffset,
    // Invalid offset within an ambiguous time (doesn't match either option)
    Data()
      ..pattern = 'yyyy-MM-dd HH:mm z o<g>'
      ..text = '2010-01-01 01:30 abc +05'
      ..message = TextErrorMessages.invalidOffset,
    // Invalid offset for an unambiguous time
    Data()
      ..pattern = 'yyyy-MM-dd HH:mm z o<g>'
      ..text = '2005-01-01 01:30 ab +02'
      ..message = TextErrorMessages.invalidOffset,

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
      ..template = LocalDateTime(1970, 1, 1, 0, 0, 5).inZoneStrictly(TestZone1)
      ..message = TextErrorMessages.invalidHour24,
    Data()
      ..pattern = 'yyyy-MM-dd HH'
      ..text = '2011-10-19 24'
      ..template = LocalDateTime(1970, 1, 1, 0, 5, 0).inZoneStrictly(TestZone1)
      ..message = TextErrorMessages.invalidHour24,

    // Redundant specification of fixed zone but not enough digits - we'll parse UTC+01:00:00 and unexpectedly be left with 00
    Data()
      ..pattern = 'yyyy-MM-dd HH:mm z'
      ..text = '2013-01-13 15:44 UTC+01:00:00.00'
      ..message = TextErrorMessages.extraValueCharacters
      ..parameters.addAll(['.00']),

    // Can't parse a pattern with a time zone abbreviation.
    Data()
      ..pattern = 'yyyy-MM-dd HH:mm x'
      ..text = 'ignored'
      ..message = TextErrorMessages.formatOnlyPattern,

    // Can't parse using a pattern that has no provider
    Data()
      ..ZoneProvider = null
      ..pattern = 'yyyy-MM-dd z'
      ..text = 'ignored'
      // note: ZoneProvider of null becomes the default provider now (for constructor condensation)
      ..message = TextErrorMessages.mismatchedNumber // formatOnlyPattern,
      ..parameters.addAll(['yyyy']),

    // Invalid ID
    Data()
      ..pattern = 'yyyy-MM-dd z'
      ..text = '2017-08-21 LemonCurdIceCream'
      ..message = TextErrorMessages.noMatchingZoneId
  ];

  @internal List<Data> ParseOnlyData = [
    // Template value time zone is from a different provider, but it's not part of the pattern.
    Data.b(2013, 1, 13, 16, 2, france)
      ..pattern = 'yyyy-MM-dd HH:mm'
      ..text = '2013-01-13 16:02'
      ..template = TimeConstants.unixEpoch.inZone(france),

    // Skipped value, resolver returns start of second interval
    Data(TestZone1.Transition.inZone(TestZone1))
      ..pattern = 'yyyy-MM-dd HH:mm z'
      ..text = '2010-01-01 01:30 ab'
      ..Resolver = Resolvers.createMappingResolver(Resolvers.throwWhenAmbiguous, Resolvers.returnStartOfIntervalAfter),

    // Skipped value, resolver returns end of first interval
    Data(TestZone1.Transition.subtract(Time.epsilon).inZone(TestZone1))
      ..pattern = 'yyyy-MM-dd HH:mm z'
      ..text = '2010-01-01 01:30 ab'
      ..Resolver = Resolvers.createMappingResolver(Resolvers.throwWhenAmbiguous, Resolvers.returnEndOfIntervalBefore),

    // Parse-only tests from LocalDateTimeTest.
    Data.c(2011, 10, 19, 16, 05, 20)
      ..pattern = 'dd MM yyyy'
      ..text = '19 10 2011'
      ..template = LocalDateTime(2000, 1, 1, 16, 05, 20).inUtc(),
    Data.c(2011, 10, 19, 16, 05, 20)
      ..pattern = 'HH:mm:ss'
      ..text = '16:05:20'
      ..template = LocalDateTime(2011, 10, 19, 0, 0, 0).inUtc(),

    // Parsing using the semi-colon 'comma dot' specifier
    Data.d(
        2011,
        10,
        19,
        16,
        05,
        20,
        352)
      ..pattern = 'yyyy-MM-dd HH:mm:ss;fff'
      ..text = '2011-10-19 16:05:20,352',
    Data.d(
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
    Data.b(2011, 10, 20, 0, 0, TestZone1)
      ..pattern = 'yyyy-MM-dd HH:mm:ss'
      ..text = '2011-10-19 24:00:00'
      ..template = LocalDateTime(1970, 1, 1, 0, 5, 0).inZoneStrictly(TestZone1),
    Data.a(2011, 10, 20)
      ..pattern = 'yyyy-MM-dd HH:mm'
      ..text = '2011-10-19 24:00',
    Data.a(2011, 10, 20)
      ..pattern = 'yyyy-MM-dd HH'
      ..text = '2011-10-19 24',

    // Redundant specification of offset
    Data.b(2013, 01, 13, 15, 44, FixedPlus1)
      ..pattern = 'yyyy-MM-dd HH:mm z'
      ..text = '2013-01-13 15:44 UTC+01:00',
    Data.b(2013, 01, 13, 15, 44, FixedPlus1)
      ..pattern = 'yyyy-MM-dd HH:mm z'
      ..text = '2013-01-13 15:44 UTC+01:00:00',
  ];

  @internal List<Data> FormatOnlyData = [
    Data.c(2011, 10, 19, 16, 05, 20)
      ..pattern = 'ddd yyyy'
      ..text = 'Wed 2011',

    // Time zone isn't in the provider
    Data.b(2013, 1, 13, 16, 2, france)
      ..pattern = 'yyyy-MM-dd HH:mm z'
      ..text = '2013-01-13 16:02 Europe/Paris',

    // Ambiguous value - would be invalid if parsed with a strict parser.
    Data(TestZone2.Transition.add(Time(minutes: 30)).inZone(TestZone2))
      ..pattern = 'yyyy-MM-dd HH:mm'
      ..text = '2010-01-01 01:30',

    // Winter
    Data.b(2013, 1, 13, 16, 2, france)
      ..pattern = 'yyyy-MM-dd HH:mm x'
      ..text = '2013-01-13 16:02 CET',
    // Summer
    Data.b(2013, 6, 13, 16, 2, france)
      ..pattern = 'yyyy-MM-dd HH:mm x'
      ..text = '2013-06-13 16:02 CEST',

    Data.b(2013, 6, 13, 16, 2, france)
      ..ZoneProvider = null
      ..pattern = 'yyyy-MM-dd HH:mm z'
      ..text = '2013-06-13 16:02 Europe/Paris',

    // Standard patterns without a DateTimeZoneProvider
    Data(MsdnStandardExampleNoMillis)
      ..standardPattern = ZonedDateTimePattern.generalFormatOnlyIso
      ..standardPatternCode = 'ZonedDateTimePattern.generalFormatOnlyIso'
      ..pattern = 'G'
      ..text = '2009-06-15T13:45:30 UTC (+00)'
      ..culture = TestCultures.FrFr
      ..ZoneProvider = null,
    Data(MsdnStandardExample)
      ..standardPattern = ZonedDateTimePattern.extendedFormatOnlyIso
      ..standardPatternCode = 'ZonedDateTimePattern.extendedFormatOnlyIso'
      ..pattern = 'F'
      ..text = '2009-06-15T13:45:30.09 UTC (+00)'
      ..culture = TestCultures.FrFr
      ..ZoneProvider = null,
    // Standard patterns without a resolver
    Data(MsdnStandardExampleNoMillis)
      ..standardPattern = ZonedDateTimePattern.generalFormatOnlyIso
      ..standardPatternCode = 'ZonedDateTimePattern.generalFormatOnlyIso'
      ..pattern = 'G'
      ..text = '2009-06-15T13:45:30 UTC (+00)'
      ..culture = TestCultures.FrFr
      ..Resolver = null,
    Data(MsdnStandardExample)
      ..standardPattern = ZonedDateTimePattern.extendedFormatOnlyIso
      ..standardPatternCode = 'ZonedDateTimePattern.extendedFormatOnlyIso'
      ..pattern = 'F'
      ..text = '2009-06-15T13:45:30.09 UTC (+00)'
      ..culture = TestCultures.FrFr
      ..Resolver = null,
  ];

  @internal List<Data> FormatAndParseData = [

    // Zone ID at the end
    Data.b(2013, 01, 13, 15, 44, TestZone1)
      ..pattern = 'yyyy-MM-dd HH:mm z'
      ..text = '2013-01-13 15:44 ab',
    Data.b(2013, 01, 13, 15, 44, TestZone2)
      ..pattern = 'yyyy-MM-dd HH:mm z'
      ..text = '2013-01-13 15:44 abc',
    Data.b(2013, 01, 13, 15, 44, TestZone3)
      ..pattern = 'yyyy-MM-dd HH:mm z'
      ..text = '2013-01-13 15:44 abcd',
    Data.b(2013, 01, 13, 15, 44, FixedPlus1)
      ..pattern = 'yyyy-MM-dd HH:mm z'
      ..text = '2013-01-13 15:44 UTC+01',
    Data.b(2013, 01, 13, 15, 44, FixedMinus1)
      ..pattern = 'yyyy-MM-dd HH:mm z'
      ..text = '2013-01-13 15:44 UTC-01',
    Data.b(2013, 01, 13, 15, 44, DateTimeZone.utc)
      ..pattern = 'yyyy-MM-dd HH:mm z'
      ..text = '2013-01-13 15:44 UTC',

    // Zone ID at the start
    Data.b(2013, 01, 13, 15, 44, TestZone1)
      ..pattern = 'z yyyy-MM-dd HH:mm'
      ..text = 'ab 2013-01-13 15:44',
    Data.b(2013, 01, 13, 15, 44, TestZone2)
      ..pattern = 'z yyyy-MM-dd HH:mm'
      ..text = 'abc 2013-01-13 15:44',
    Data.b(2013, 01, 13, 15, 44, TestZone3)
      ..pattern = 'z yyyy-MM-dd HH:mm'
      ..text = 'abcd 2013-01-13 15:44',
    Data.b(2013, 01, 13, 15, 44, FixedPlus1)
      ..pattern = 'z yyyy-MM-dd HH:mm'
      ..text = 'UTC+01 2013-01-13 15:44',
    Data.b(2013, 01, 13, 15, 44, FixedMinus1)
      ..pattern = 'z yyyy-MM-dd HH:mm'
      ..text = 'UTC-01 2013-01-13 15:44',
    Data.b(2013, 01, 13, 15, 44, DateTimeZone.utc)
      ..pattern = 'z yyyy-MM-dd HH:mm'
      ..text = 'UTC 2013-01-13 15:44',

    // More precise fixed zones.
    Data.b(2013, 01, 13, 15, 44, FixedWithMinutes)
      ..pattern = 'yyyy-MM-dd HH:mm z'
      ..text = '2013-01-13 15:44 UTC+01:30',
    Data.b(2013, 01, 13, 15, 44, FixedWithSeconds)
      ..pattern = 'yyyy-MM-dd HH:mm z'
      ..text = '2013-01-13 15:44 UTC+00:00:05',

    // Valid offset for an unambiguous time
    Data(LocalDateTime(2005, 1, 1, 1, 30, 0).inZoneStrictly(TestZone1))
      ..pattern = 'yyyy-MM-dd HH:mm z o<g>'
      ..text = '2005-01-01 01:30 ab +01',
    // Valid offset (in the middle of the pattern) for an unambiguous time
    Data(LocalDateTime(2005, 1, 1, 1, 30, 0).inZoneStrictly(TestZone1))
      ..pattern = 'yyyy-MM-dd o<g> HH:mm z'
      ..text = '2005-01-01 +01 01:30 ab',

    // Ambiguous value, resolver returns later value.
    Data(TestZone2.Transition.add(Time(minutes: 30)).inZone(TestZone2))
      ..pattern = 'yyyy-MM-dd HH:mm z'
      ..text = '2010-01-01 01:30 abc'
      ..Resolver = Resolvers.createMappingResolver(Resolvers.returnLater, Resolvers.throwWhenSkipped),

    // Ambiguous value, resolver returns earlier value.
    Data(TestZone2.Transition.add(Time(minutes: -30)).inZone(TestZone2))
      ..pattern = 'yyyy-MM-dd HH:mm z'
      ..text = '2010-01-01 01:30 abc'
      ..Resolver = Resolvers.createMappingResolver(Resolvers.returnEarlier, Resolvers.throwWhenSkipped),

    // Ambiguous local value, but with offset for later value (smaller offset).
    Data(TestZone2.Transition.add(Time(minutes: 30)).inZone(TestZone2))
      ..pattern = 'yyyy-MM-dd HH:mm z o<g>'
      ..text = '2010-01-01 01:30 abc +01',

    // Ambiguous local value, but with offset for earlier value (greater offset).
    Data(TestZone2.Transition.add(Time(minutes: -30)).inZone(TestZone2))
      ..pattern = 'yyyy-MM-dd HH:mm z o<g>'
      ..text = '2010-01-01 01:30 abc +02',

    // Specify the provider
    Data.b(2013, 1, 13, 16, 2, france)
      ..pattern = 'yyyy-MM-dd HH:mm z'
      ..text = '2013-01-13 16:02 Europe/Paris'
      ..ZoneProvider = tzdb,

    // Tests without zones, copied from LocalDateTimePatternTest
    // Calendar patterns are invariant
    Data(MsdnStandardExample)
      ..pattern = "(c) uuuu-MM-dd'T'HH:mm:ss.FFFFFFF"
      ..text = '(ISO) 2009-06-15T13:45:30.09'
      ..culture = TestCultures.FrFr,
    Data(MsdnStandardExample)
      ..pattern = "uuuu-MM-dd(c)'T'HH:mm:ss.FFFFFFF"
      ..text = '2009-06-15(ISO)T13:45:30.09'
      ..culture = TestCultures.EnUs,
// todo: @SkipMe.unimplemented()
//new Data(SampleZonedDateTimeCoptic) ..Pattern = "(c) uuuu-MM-dd'T'HH:mm:ss.FFFFFFFFF"..Text = "(Coptic) 1976-06-19T21:13:34.123456789"..Culture = TestCultures.FrFr ,
//new Data(SampleZonedDateTimeCoptic) ..Pattern = "uuuu-MM-dd'C'c'T'HH:mm:ss.FFFFFFFFF"..Text = "1976-06-19CCopticT21:13:34.123456789"..Culture = TestCultures.EnUs ,

    // Use of the semi-colon 'comma dot' specifier
    Data.d(
        2011,
        10,
        19,
        16,
        05,
        20,
        352)
      ..pattern = 'yyyy-MM-dd HH:mm:ss;fff'
      ..text = '2011-10-19 16:05:20.352',
    Data.d(
        2011,
        10,
        19,
        16,
        05,
        20,
        352)
      ..pattern = 'yyyy-MM-dd HH:mm:ss;FFF'
      ..text = '2011-10-19 16:05:20.352',
    Data.d(
        2011,
        10,
        19,
        16,
        05,
        20,
        352)
      ..pattern = "yyyy-MM-dd HH:mm:ss;FFF 'end'"
      ..text = '2011-10-19 16:05:20.352 end',
    Data.c(2011, 10, 19, 16, 05, 20)
      ..pattern = "yyyy-MM-dd HH:mm:ss;FFF 'end'"
      ..text = '2011-10-19 16:05:20 end',

    // Standard patterns with a time zone provider
    Data.e(
        2013,
        01,
        13,
        15,
        44,
        30,
        0,
        TestZone1)
      ..standardPattern = ZonedDateTimePattern.generalFormatOnlyIso.withZoneProvider(TestProvider)
      ..standardPatternCode = 'ZonedDateTimePattern.generalFormatOnlyIso.withZoneProvider(TestProvider)'
      ..pattern = 'G'
      ..text = '2013-01-13T15:44:30 ab (+02)'
      ..culture = TestCultures.FrFr,
    Data.e(
        2013,
        01,
        13,
        15,
        44,
        30,
        90,
        TestZone1)
      ..standardPattern = ZonedDateTimePattern.extendedFormatOnlyIso.withZoneProvider(TestProvider)
      ..standardPatternCode = 'ZonedDateTimePattern.extendedFormatOnlyIso.withZoneProvider(TestProvider)'
      ..pattern = 'F'
      ..text = '2013-01-13T15:44:30.09 ab (+02)'
      ..culture = TestCultures.FrFr,

    // Custom embedded patterns (or mixture of custom and standard)
    Data.e(
        2015,
        10,
        24,
        11,
        55,
        30,
        0,
        athens)
      ..pattern = "ld<yyyy*MM*dd>'X'lt<HH_mm_ss> z o<g>"
      ..text = '2015*10*24X11_55_30 Europe/Athens +03'
      ..ZoneProvider = tzdb,
    Data.e(
        2015,
        10,
        24,
        11,
        55,
        30,
        0,
        athens)
      ..pattern = "lt<HH_mm_ss>'Y'ld<yyyy*MM*dd> z o<g>"
      ..text = '11_55_30Y2015*10*24 Europe/Athens +03'
      ..ZoneProvider = tzdb,
    Data.e(
        2015,
        10,
        24,
        11,
        55,
        30,
        0,
        athens)
      ..pattern = "l<HH_mm_ss'Y'yyyy*MM*dd> z o<g>"
      ..text = '11_55_30Y2015*10*24 Europe/Athens +03'
      ..ZoneProvider = tzdb,
    Data.e(
        2015,
        10,
        24,
        11,
        55,
        30,
        0,
        athens)
      ..pattern = "ld<d>'X'lt<HH_mm_ss> z o<g>"
      ..text = '10/24/2015X11_55_30 Europe/Athens +03'
      ..ZoneProvider = tzdb,
    Data.e(
        2015,
        10,
        24,
        11,
        55,
        30,
        0,
        athens)
      ..pattern = "ld<yyyy*MM*dd>'X'lt<T> z o<g>"
      ..text = '2015*10*24X11:55:30 Europe/Athens +03'
      ..ZoneProvider = tzdb,

    // Standard embedded patterns. Short time versions have a seconds value of 0 so they can round-trip.
    Data.e(
        2015,
        10,
        24,
        11,
        55,
        30,
        90,
        athens)
      ..pattern = 'ld<D> lt<r> z o<g>'
      ..text = 'Saturday, 24 October 2015 11:55:30.09 Europe/Athens +03'
      ..ZoneProvider = tzdb,
    Data.e(
        2015,
        10,
        24,
        11,
        55,
        0,
        0,
        athens)
      ..pattern = 'l<f> z o<g>'
      ..text = 'Saturday, 24 October 2015 11:55 Europe/Athens +03'
      ..ZoneProvider = tzdb,
    Data.e(
        2015,
        10,
        24,
        11,
        55,
        30,
        0,
        athens)
      ..pattern = 'l<F> z o<g>'
      ..text = 'Saturday, 24 October 2015 11:55:30 Europe/Athens +03'
      ..ZoneProvider = tzdb,
    Data.e(
        2015,
        10,
        24,
        11,
        55,
        0,
        0,
        athens)
      ..pattern = 'l<g> z o<g>'
      ..text = '10/24/2015 11:55 Europe/Athens +03'
      ..ZoneProvider = tzdb,
    Data.e(
        2015,
        10,
        24,
        11,
        55,
        30,
        0,
        athens)
      ..pattern = 'l<G> z o<g>'
      ..text = '10/24/2015 11:55:30 Europe/Athens +03'
      ..ZoneProvider = tzdb,

    // Nested embedded patterns
    Data.e(
        2015,
        10,
        24,
        11,
        55,
        30,
        90,
        athens)
      ..pattern = 'l<ld<D> lt<r>> z o<g>'
      ..text = 'Saturday, 24 October 2015 11:55:30.09 Europe/Athens +03'
      ..ZoneProvider = tzdb,
    Data.e(
        2015,
        10,
        24,
        11,
        55,
        30,
        0,
        athens)
      ..pattern = "l<'X'lt<HH_mm_ss>'Y'ld<yyyy*MM*dd>'X'> z o<g>"
      ..text = 'X11_55_30Y2015*10*24X Europe/Athens +03'
      ..ZoneProvider = tzdb,

    // Check that unquoted T still works.
    Data.c(2012, 1, 31, 17, 36, 45)
      ..text = '2012-01-31T17:36:45'
      ..pattern = 'yyyy-MM-ddTHH:mm:ss',

    // Issue981
    Data.e(
        1906,
        8,
        29,
        20,
        58,
        32,
        0,
        etcGMT_12)
      ..text = '1906-08-29T20:58:32 Etc/GMT-12 (+12)'
      ..pattern = "uuuu'-'MM'-'dd'T'HH':'mm':'ss;FFFFFFFFF z '('o<g>')'"
      ..ZoneProvider = etcGMT_12_tzdb,

    // Fields not otherwise covered (according to tests running on AppVeyor...)
    Data(MsdnStandardExample)
      ..pattern = 'd MMMM yyyy (g) h:mm:ss.FF tt'
      ..text = '15 June 2009 (A.D.) 1:45:30.09 PM',
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);

  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);

  @Test()
  void WithTemplateValue() {
    var pattern = ZonedDateTimePattern.createWithInvariantCulture('yyyy-MM-dd', TestProvider)
        .withTemplateValue(Instant.utc(1970, 1, 1, 11, 30).inZone(TestZone3));
    var parsed = pattern
        .parse('2017-08-23')
        .value;
    expect(identical(TestZone3, parsed.zone), isTrue);
    // TestZone3 is at UTC+1 in 1970, so the template value's *local* time is 12pm.
    // Even though we're parsing a date in 2017, it's the local time from the template value that's used.
    expect(LocalDateTime(2017, 8, 23, 12, 30, 0), parsed.localDateTime);
    expect(Offset.hours(2), parsed.offset);
  }

  @Test()
  void WithCalendar() {
    var pattern = ZonedDateTimePattern.createWithInvariantCulture('yyyy-MM-dd', TestProvider).withCalendar(CalendarSystem.coptic);
    var parsed = pattern
        .parse('0284-08-29')
        .value;
    expect(LocalDateTime(284, 8, 29, 0, 0, 0, calendar: CalendarSystem.coptic), parsed.localDateTime);
  }

  @Test()
  void WithPatternText() {
    var pattern = ZonedDateTimePattern.createWithInvariantCulture('yyyy', TestProvider).withPatternText("yyyy-MM-dd");
    var text = pattern.format(TimeConstants.unixEpoch.inUtc());
    expect('1970-01-01', text);
  }

  @Test()
  void CreateWithCurrentCulture() {
    Culture.current = TestCultures.DotTimeSeparator;
    {
      var pattern = ZonedDateTimePattern.createWithCurrentCulture('HH:mm', null);
      var text = pattern.format(Instant.utc(2000, 1, 1, 19, 30).inUtc());
      expect('19.30', text);
    }
  }

  @Test()
  void WithCulture() {
    var pattern = ZonedDateTimePattern.createWithInvariantCulture('HH:mm', null).withCulture(TestCultures.DotTimeSeparator);
    var text = pattern.format(Instant.utc(2000, 1, 1, 19, 30).inUtc());
    expect('19.30', text);
  }

  // Test to hit each exit condition in the time zone ID parsing part of ZonedDateTimePatternParser
  @Test()
  Future FindLongestZoneId() async {
    DateTimeZone CreateZone(String id) =>
        SingleTransitionDateTimeZone.withId(TimeConstants.unixEpoch - Time(days: 1), Offset.hours(-1), Offset.hours(0), id);

    var source = (FakeDateTimeZoneSourceBuilder(
        [CreateZone('ABC'),
        CreateZone('ABCA'),
        CreateZone('ABCB'),
        CreateZone('ABCBX'),
        CreateZone('ABCD')
        ]
    )).Build();

    var provider = await DateTimeZoneCache.getCache(source);
    var pattern = ZonedDateTimePattern.createWithCulture("z 'x'", Culture.invariant, Resolvers.strictResolver,
        provider, TimeConstants.unixEpoch.inUtc());

    for (var id in provider.ids) {
      var value = pattern
          .parse('$id x')
          .value;
      expect(id, value.zone.id);
    }
  }

  // @Test()
  // void ParseNull() => AssertParseNull(ZonedDateTimePattern.extendedFormatOnlyIso.withZoneProvider(TestProvider));
}

/*sealed*/class Data extends PatternTestData<ZonedDateTime> {
// Default to the start of the year 2000 UTC
/*protected*/ @override ZonedDateTime get defaultTemplate => ZonedDateTimePatterns.defaultTemplateValue;

  @internal ZoneLocalMappingResolver? Resolver;
  @internal DateTimeZoneProvider? ZoneProvider;

  /// Initializes a new instance of the [Data] class.
  ///
  /// [value]: The value.
  Data([ZonedDateTime? value]) : super(value ?? ZonedDateTimePatterns.defaultTemplateValue) {
    Resolver = Resolvers.strictResolver;
    ZoneProvider = TestProvider;
  }

  Data.a(int year, int month, int day)
      : this(LocalDateTime(year, month, day, 0, 0, 0).inUtc());

  // Coincidentally, we don't specify time zones in tests other than the
  // ones which just go down to the date and hour/minute.
  Data.b(int year, int month, int day, int hour, int minute, DateTimeZone zone)
      : this(LocalDateTime(year, month, day, hour, minute, 0).inZoneStrictly(zone));

  Data.c(int year, int month, int day, int hour, int minute, int second)
      : this(LocalDateTime(year, month, day, hour, minute, second).inUtc());

  Data.d(int year, int month, int day, int hour, int minute, int second, int millis)
      : this(LocalDateTime(
      year,
      month,
      day,
      hour,
      minute,
      second,
      ms: millis).inUtc());

  Data.e(int year, int month, int day, int hour, int minute, int second, int millis, DateTimeZone zone)
      : this(LocalDateTime(
      year,
      month,
      day,
      hour,
      minute,
      second,
      ms: millis).inZoneStrictly(zone));

  @internal
  @override
  IPattern<ZonedDateTime> CreatePattern() =>
      ZonedDateTimePattern.createWithCulture(super.pattern, super.culture, Resolver, ZoneProvider, template);
}

