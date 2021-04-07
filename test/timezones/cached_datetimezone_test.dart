// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import '../time_machine_testing.dart';

Future main() async {
  await TimeMachine.initialize();
  await setup();

  await runTests();
}

Future setup() async {
  // NB: may be an invalid work if dateTimeZone._isFixed
  timeZone = CachedDateTimeZone.forZone(await (await DateTimeZoneProviders.tzdb)['America/Los_Angeles']) as CachedDateTimeZone;
}

late CachedDateTimeZone timeZone; // = (CachedDateTimeZone) DateTimeZoneProviders.Tzdb['America/Los_Angeles'];
Instant summer = Instant.utc(2010, 6, 1, 0, 0);

@Test()
void GetZoneIntervalInstant_NotNull()
{
  var actual = timeZone.getZoneInterval(summer);
  expect(actual, isNotNull);
}

@Test()
void GetZoneIntervalInstant_RepeatedCallsReturnSameObject()
{
  var actual = timeZone.getZoneInterval(summer);
  for (int i = 0; i < 100; i++)
  {
    var newPeriod = timeZone.getZoneInterval(summer);
    expect(identical(actual, newPeriod), isTrue);
  }
}

@Test()
void GetZoneIntervalInstant_RepeatedCallsReturnSameObjectWithOthersInterspersed()
{
  var actual = timeZone.getZoneInterval(summer);
  expect(timeZone.getZoneInterval(TimeConstants.unixEpoch), isNotNull);
  expect(timeZone.getZoneInterval(TimeConstants.unixEpoch + Time(days: 2000 * 7)), isNotNull);
  expect(timeZone.getZoneInterval(TimeConstants.unixEpoch + Time(days: 3000 * 7)), isNotNull);
  expect(timeZone.getZoneInterval(TimeConstants.unixEpoch + Time(days: 4000 * 7)), isNotNull);
  var newPeriod = timeZone.getZoneInterval(summer);
  expect(identical(actual, newPeriod), isTrue);
}

@Test()
void MinMaxOffsets()
{
  expect(timeZone.timeZone.minOffset, timeZone.minOffset);
  expect(timeZone.timeZone.maxOffset, timeZone.maxOffset);
}

@Test()
void ForZone_Fixed()
{
  var zone = DateTimeZone.forOffset(Offset.hours(1));
  expect(identical(zone, CachedDateTimeZone.forZone(zone)), isTrue);
}

@Test()
void ForZone_AlreadyCached()
{
  expect(identical(timeZone, CachedDateTimeZone.forZone(timeZone)), isTrue);
}


