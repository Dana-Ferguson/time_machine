// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

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

@Test()
void EpochProperties()
{
  LocalDate date = TimeConstants.unixEpoch.inUtc().date;
  expect(1970, date.year);
  expect(1970, date.yearOfEra);
  expect(1, date.day);
  expect(IsoDayOfWeek.thursday, date.dayOfWeek);
  expect(1, date.dayOfYear);
  expect(1, date.month);
}

@Test()
void ArbitraryDateProperties()
{
  DateTime bclDate = new DateTime.utc(2011, 3, 5, 0, 0, 0);
  DateTime bclEpoch = new DateTime.utc(1970, 1, 1, 0, 0, 0);
  int bclMilliseconds = bclDate.millisecondsSinceEpoch - bclEpoch.millisecondsSinceEpoch;
  int bclDays = (bclMilliseconds ~/ TimeConstants.millisecondsPerDay);
  LocalDate date = new LocalDate.fromDaysSinceEpoch(bclDays, CalendarSystem.iso);
  expect(2011, date.year);
  expect(2011, date.yearOfEra);
  expect(5, date.day);
  expect(IsoDayOfWeek.saturday, date.dayOfWeek);
  expect(64, date.dayOfYear);
  expect(3, date.month);
}

@Test()
void DayOfWeek_AroundEpoch()
{
  // Test about couple of months around the Unix epoch. If that works, I'm confident the rest will.
  LocalDate date = new LocalDate(1969, 12, 1);
  for (int i = 0; i < 60; i++)
  {
    // BclConversions.ToIsoDayOfWeek(date.AtMidnight.ToDateTimeUnspecified().DayOfWeek),
    expect(
        date.dayOfWeek.value,
        date.atMidnight().toDateTimeLocal().weekday
        );
    date = date.plusDays(1);
  }
}
