// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/TimeZones/CachedDateTimeZoneTest.cs
// 16aacad  on Aug 26, 2017

import 'dart:async';
import 'dart:math' as math;

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import '../time_machine_testing.dart';

Future main() async {
  timeZone = CachedDateTimeZone.ForZone(await (await DateTimeZoneProviders.Tzdb)["America/Los_Angeles"]);

  await runTests();
}

CachedDateTimeZone timeZone; // = (CachedDateTimeZone) DateTimeZoneProviders.Tzdb["America/Los_Angeles"];
Instant summer = new Instant.fromUtc(2010, 6, 1, 0, 0);

@Test()
void GetZoneIntervalInstant_NotNull()
{
  var actual = timeZone.GetZoneInterval(summer);
  expect(actual, isNotNull);
}

@Test()
void GetZoneIntervalInstant_RepeatedCallsReturnSameObject()
{
  var actual = timeZone.GetZoneInterval(summer);
  for (int i = 0; i < 100; i++)
  {
    var newPeriod = timeZone.GetZoneInterval(summer);
    expect(identical(actual, newPeriod), isTrue);
  }
}

@Test()
void GetZoneIntervalInstant_RepeatedCallsReturnSameObjectWithOthersInterspersed()
{
  var actual = timeZone.GetZoneInterval(summer);
  expect(timeZone.GetZoneInterval(TimeConstants.unixEpoch), isNotNull);
  expect(timeZone.GetZoneInterval(TimeConstants.unixEpoch + new Span(days: 2000 * 7)), isNotNull);
  expect(timeZone.GetZoneInterval(TimeConstants.unixEpoch + new Span(days: 3000 * 7)), isNotNull);
  expect(timeZone.GetZoneInterval(TimeConstants.unixEpoch + new Span(days: 4000 * 7)), isNotNull);
  var newPeriod = timeZone.GetZoneInterval(summer);
  expect(identical(actual, newPeriod), isTrue);
}

@Test()
void MinMaxOffsets()
{
  expect(timeZone.TimeZone.minOffset, timeZone.minOffset);
  expect(timeZone.TimeZone.maxOffset, timeZone.maxOffset);
}

@Test()
void ForZone_Fixed()
{
  var zone = DateTimeZone.ForOffset(new Offset.fromHours(1));
  expect(identical(zone, CachedDateTimeZone.ForZone(zone)), isTrue);
}

@Test()
void ForZone_AlreadyCached()
{
  expect(identical(timeZone, CachedDateTimeZone.ForZone(timeZone)), isTrue);
}

