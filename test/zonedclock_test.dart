// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:test/test.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

final DateTimeZone SampleZone = SingleTransitionDateTimeZone.around(TimeConstants.unixEpoch, 1, 2);

@Test()
void GetCurrent()
{
  var julian = CalendarSystem.julian;
  FakeClock underlyingClock = FakeClock(TimeConstants.unixEpoch);
  ZonedClock zonedClock = underlyingClock.inZone(SampleZone, julian);
  expect(TimeConstants.unixEpoch, zonedClock.getCurrentInstant());
  expect(ZonedDateTime(underlyingClock.getCurrentInstant(), SampleZone, julian),
      zonedClock.getCurrentZonedDateTime());
  expect(LocalDateTime(1969, 12, 19, 2, 0, 0, calendar: julian), zonedClock.getCurrentLocalDateTime());
  expect(LocalDateTime(1969, 12, 19, 2, 0, 0, calendar: julian).withOffset(Offset.hours(2)),
      zonedClock.getCurrentOffsetDateTime());
  expect(LocalDate(1969, 12, 19, julian), zonedClock.getCurrentDate());
  expect(LocalTime(2, 0, 0), zonedClock.getCurrentTimeOfDay());
}
