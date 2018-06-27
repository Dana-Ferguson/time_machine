// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:math' as math;

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

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

CalendarSystem Iso = CalendarSystem.iso;

@Test()
void FieldsOf_UnixEpoch()
{
  // It's easiest to test this using a LocalDateTime in the ISO calendar system.
  // LocalDateTime just passes everything through anyway.
  LocalDateTime epoch = TimeConstants.unixEpoch.inUtc().localDateTime;

  expect(1970, epoch.year);
  expect(1970, epoch.yearOfEra);
  expect(1970, WeekYearRules.iso.getWeekYear(epoch.date));
  expect(1, WeekYearRules.iso.getWeekOfWeekYear(epoch.date));
  expect(1, epoch.month);
  expect(1, epoch.day);
  expect(1, epoch.dayOfYear);
  expect(IsoDayOfWeek.thursday, epoch.dayOfWeek);
  expect(Era.common, epoch.era);
  expect(0, epoch.hour);
  expect(0, epoch.minute);
  expect(0, epoch.second);
  expect(0, epoch.millisecond);
  expect(0, epoch.tickOfDay);
  expect(0, epoch.tickOfSecond);
}

@Test()
void FieldsOf_GreatAchievement()
{
  // LocalDateTime now = new Instant.fromUnixTimeTicks((TimeOfGreatAchievement.difference(UnixEpochDateTime)).Ticks).InUtc().LocalDateTime;
  LocalDateTime now = new Instant.fromUnixTimeTicks((
      TimeOfGreatAchievement.difference(UnixEpochDateTime))
      .inMicroseconds * TimeConstants.ticksPerMicrosecond).inUtc().localDateTime;

  expect(2009, now.year);
  expect(2009, now.yearOfEra);
  expect(2009, WeekYearRules.iso.getWeekYear(now.date));
  expect(48, WeekYearRules.iso.getWeekOfWeekYear(now.date));
  expect(11, now.month);
  expect(27, now.day);
  // expect(TimeOfGreatAchievement.dayOfYear, now.DayOfYear);
  expect(IsoDayOfWeek.friday, now.dayOfWeek);
  expect(Era.common, now.era);
  expect(18, now.hour);
  expect(38, now.minute);
  expect(25, now.second);
  expect(345, now.millisecond);
  expect(3458760, now.tickOfSecond); // 3458765
  expect(18 * TimeConstants.ticksPerHour +
      38 * TimeConstants.ticksPerMinute +
      25 * TimeConstants.ticksPerSecond +
      3458760, // 3458765
      now.tickOfDay);
}

@Test()
void ConstructLocalInstant_WithAllFields()
{
  LocalInstant localAchievement = new LocalDateTime.at(2009, 11, 27, 18, 38, seconds: 25, milliseconds: 345).plusTicks(extraTicks).toLocalInstant();
  int bclTicks = (TimeOfGreatAchievement.difference(UnixEpochDateTime)).inMicroseconds * TimeConstants.ticksPerMicrosecond;
  int bclDays = (bclTicks ~/ TimeConstants.ticksPerDay);
  int bclTickOfDay = bclTicks % TimeConstants.ticksPerDay;
  expect(bclDays, localAchievement.daysSinceEpoch);
  expect(bclTickOfDay, localAchievement.nanosecondOfDay / TimeConstants.nanosecondsPerTick);
}

@Test()
void IsLeapYear()
{
  expect(CalendarSystem.iso.isLeapYear(2012), isTrue); // 4 year rule
  expect(CalendarSystem.iso.isLeapYear(2011), isFalse); // 4 year rule
  expect(CalendarSystem.iso.isLeapYear(2100), isFalse); // 100 year rule
  expect(CalendarSystem.iso.isLeapYear(2000), isTrue); // 400 year rule
}

@Test()
void GetDaysInMonth()
{
  expect(30, CalendarSystem.iso.getDaysInMonth(2010, 9));
  expect(31, CalendarSystem.iso.getDaysInMonth(2010, 1));
  expect(28, CalendarSystem.iso.getDaysInMonth(2010, 2));
  expect(29, CalendarSystem.iso.getDaysInMonth(2012, 2));
}

@Test()
void BeforeCommonEra()
{
  // Year -1 in absolute terms is 2BCE
  LocalDate localDate = new LocalDate(-1, 1, 1);
  expect(Era.beforeCommon, localDate.era);
  expect(-1, localDate.year);
  expect(2, localDate.yearOfEra);
}

@Test()
void BeforeCommonEra_BySpecifyingEra()
{
  // Year -1 in absolute terms is 2BCE
  LocalDate localDate = new LocalDate.forEra(Era.beforeCommon, 2, 1, 1);
  expect(Era.beforeCommon, localDate.era);
  expect(-1, localDate.year);
  expect(2, localDate.yearOfEra);
}

