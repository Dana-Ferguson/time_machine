// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:math' as math;

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

final DateTimeZone SampleZone = new SingleTransitionDateTimeZone.around(TimeConstants.unixEpoch, 1, 2);

@Test()
void GetCurrent()
{
  var julian = CalendarSystem.Julian;
  FakeClock underlyingClock = new FakeClock(TimeConstants.unixEpoch);
  ZonedClock zonedClock = underlyingClock.InZone(SampleZone, julian);
  expect(TimeConstants.unixEpoch, zonedClock.getCurrentInstant());
  expect(new ZonedDateTime.withCalendar(underlyingClock.getCurrentInstant(), SampleZone, julian),
      zonedClock.getCurrentZonedDateTime());
  expect(new LocalDateTime.fromYMDHMC(1969, 12, 19, 2, 0, julian), zonedClock.getCurrentLocalDateTime());
  expect(new LocalDateTime.fromYMDHMC(1969, 12, 19, 2, 0, julian).WithOffset(new Offset.fromHours(2)),
      zonedClock.getCurrentOffsetDateTime());
  expect(new LocalDate(1969, 12, 19, julian), zonedClock.getCurrentDate());
  expect(new LocalTime(2, 0, 0), zonedClock.getCurrentTimeOfDay());
}
