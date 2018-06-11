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

import '../time_machine_testing.dart';

Future main() async {
  await runTests();
}

// DateTime doesn't do Ticks, so we lose some precision
const int extraTicks = 8760; // 8765;

DateTime UnixEpochDateTime = new DateTime.utc(1970, 1, 1, 0, 0, 0);
// This was when I was writing the tests, having finally made everything work - several thousand lines
// of shockingly untested code.
DateTime TimeOfGreatAchievement = new DateTime.utc(2009, 11, 27, 18, 38, 25, 345)
    .add(new Duration(microseconds: extraTicks ~/ TimeConstants.ticksPerMicrosecond)); // + TimeSpan.FromTicks(8765);

CalendarSystem Iso = CalendarSystem.Iso;

@Test()
void FieldsOf_UnixEpoch()
{
  // It's easiest to test this using a LocalDateTime in the ISO calendar system.
  // LocalDateTime just passes everything through anyway.
  LocalDateTime epoch = TimeConstants.unixEpoch.inUtc().localDateTime;

  expect(1970, epoch.Year);
  expect(1970, epoch.YearOfEra);
  expect(1970, WeekYearRules.Iso.GetWeekYear(epoch.Date));
  expect(1, WeekYearRules.Iso.GetWeekOfWeekYear(epoch.Date));
  expect(1, epoch.Month);
  expect(1, epoch.Day);
  expect(1, epoch.DayOfYear);
  expect(IsoDayOfWeek.thursday, epoch.DayOfWeek);
  expect(Era.Common, epoch.era);
  expect(0, epoch.Hour);
  expect(0, epoch.Minute);
  expect(0, epoch.Second);
  expect(0, epoch.Millisecond);
  expect(0, epoch.TickOfDay);
  expect(0, epoch.TickOfSecond);
}

@Test()
void FieldsOf_GreatAchievement()
{
  // LocalDateTime now = new Instant.fromUnixTimeTicks((TimeOfGreatAchievement.difference(UnixEpochDateTime)).Ticks).InUtc().LocalDateTime;
  LocalDateTime now = new Instant.fromUnixTimeTicks((
      TimeOfGreatAchievement.difference(UnixEpochDateTime))
      .inMicroseconds * TimeConstants.ticksPerMicrosecond).inUtc().localDateTime;

  expect(2009, now.Year);
  expect(2009, now.YearOfEra);
  expect(2009, WeekYearRules.Iso.GetWeekYear(now.Date));
  expect(48, WeekYearRules.Iso.GetWeekOfWeekYear(now.Date));
  expect(11, now.Month);
  expect(27, now.Day);
  // expect(TimeOfGreatAchievement.dayOfYear, now.DayOfYear);
  expect(IsoDayOfWeek.friday, now.DayOfWeek);
  expect(Era.Common, now.era);
  expect(18, now.Hour);
  expect(38, now.Minute);
  expect(25, now.Second);
  expect(345, now.Millisecond);
  expect(3458760, now.TickOfSecond); // 3458765
  expect(18 * TimeConstants.ticksPerHour +
      38 * TimeConstants.ticksPerMinute +
      25 * TimeConstants.ticksPerSecond +
      3458760, // 3458765
      now.TickOfDay);
}

@Test()
void ConstructLocalInstant_WithAllFields()
{
  LocalInstant localAchievement = new LocalDateTime.fromYMDHMSM(2009, 11, 27, 18, 38, 25, 345).PlusTicks(extraTicks).ToLocalInstant();
  int bclTicks = (TimeOfGreatAchievement.difference(UnixEpochDateTime)).inMicroseconds * TimeConstants.ticksPerMicrosecond;
  int bclDays = (bclTicks ~/ TimeConstants.ticksPerDay);
  int bclTickOfDay = bclTicks % TimeConstants.ticksPerDay;
  expect(bclDays, localAchievement.DaysSinceEpoch);
  expect(bclTickOfDay, localAchievement.NanosecondOfDay / TimeConstants.nanosecondsPerTick);
}

@Test()
void IsLeapYear()
{
  expect(CalendarSystem.Iso.IsLeapYear(2012), isTrue); // 4 year rule
  expect(CalendarSystem.Iso.IsLeapYear(2011), isFalse); // 4 year rule
  expect(CalendarSystem.Iso.IsLeapYear(2100), isFalse); // 100 year rule
  expect(CalendarSystem.Iso.IsLeapYear(2000), isTrue); // 400 year rule
}

@Test()
void GetDaysInMonth()
{
  expect(30, CalendarSystem.Iso.GetDaysInMonth(2010, 9));
  expect(31, CalendarSystem.Iso.GetDaysInMonth(2010, 1));
  expect(28, CalendarSystem.Iso.GetDaysInMonth(2010, 2));
  expect(29, CalendarSystem.Iso.GetDaysInMonth(2012, 2));
}

@Test()
void BeforeCommonEra()
{
  // Year -1 in absolute terms is 2BCE
  LocalDate localDate = new LocalDate(-1, 1, 1);
  expect(Era.BeforeCommon, localDate.era);
  expect(-1, localDate.year);
  expect(2, localDate.yearOfEra);
}

@Test()
void BeforeCommonEra_BySpecifyingEra()
{
  // Year -1 in absolute terms is 2BCE
  LocalDate localDate = new LocalDate.forEra(Era.BeforeCommon, 2, 1, 1);
  expect(Era.BeforeCommon, localDate.era);
  expect(-1, localDate.year);
  expect(2, localDate.yearOfEra);
}

