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
  LocalDate date = TimeConstants.unixEpoch.inUtc().Date;
  expect(1970, date.Year);
  expect(1970, date.YearOfEra);
  expect(1, date.Day);
  expect(IsoDayOfWeek.thursday, date.DayOfWeek);
  expect(1, date.DayOfYear);
  expect(1, date.Month);
}

@Test()
void ArbitraryDateProperties()
{
  DateTime bclDate = new DateTime.utc(2011, 3, 5, 0, 0, 0);
  DateTime bclEpoch = new DateTime.utc(1970, 1, 1, 0, 0, 0);
  int bclMilliseconds = bclDate.millisecondsSinceEpoch - bclEpoch.millisecondsSinceEpoch;
  int bclDays = (bclMilliseconds ~/ TimeConstants.millisecondsPerDay);
  LocalDate date = new LocalDate.fromDaysSinceEpoch_forCalendar(bclDays, CalendarSystem.Iso);
  expect(2011, date.Year);
  expect(2011, date.YearOfEra);
  expect(5, date.Day);
  expect(IsoDayOfWeek.saturday, date.DayOfWeek);
  expect(64, date.DayOfYear);
  expect(3, date.Month);
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
        date.DayOfWeek.value,
        date.AtMidnight.ToDateTimeUnspecified().weekday
        );
    date = date.PlusDays(1);
  }
}
