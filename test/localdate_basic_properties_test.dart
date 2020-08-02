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

@Test()
void EpochProperties()
{
  LocalDate date = TimeConstants.unixEpoch.inUtc().calendarDate;
  expect(1970, date.year);
  expect(1970, date.yearOfEra);
  expect(1, date.dayOfMonth);
  expect(DayOfWeek.thursday, date.dayOfWeek);
  expect(1, date.dayOfYear);
  expect(1, date.monthOfYear);
}

@Test()
void ArbitraryDateProperties()
{
  DateTime bclDate = DateTime.utc(2011, 3, 5, 0, 0, 0);
  DateTime bclEpoch = DateTime.utc(1970, 1, 1, 0, 0, 0);
  int bclMilliseconds = bclDate.millisecondsSinceEpoch - bclEpoch.millisecondsSinceEpoch;
  int bclDays = (bclMilliseconds ~/ TimeConstants.millisecondsPerDay);
  LocalDate date = LocalDate.fromEpochDay(bclDays, CalendarSystem.iso);
  expect(2011, date.year);
  expect(2011, date.yearOfEra);
  expect(5, date.dayOfMonth);
  expect(DayOfWeek.saturday, date.dayOfWeek);
  expect(64, date.dayOfYear);
  expect(3, date.monthOfYear);
}

@Test()
void DayOfWeek_AroundEpoch()
{
  // Test about couple of months around the Unix epoch. If that works, I'm confident the rest will.
  LocalDate date = LocalDate(1969, 12, 1);
  for (int i = 0; i < 60; i++)
  {
    // BclConversions.ToIsoDayOfWeek(date.AtMidnight.ToDateTimeUnspecified().DayOfWeek),
    expect(
        date.dayOfWeek.value,
        date.atMidnight().toDateTimeLocal().weekday
        );
    date = date.addDays(1);
  }
}
