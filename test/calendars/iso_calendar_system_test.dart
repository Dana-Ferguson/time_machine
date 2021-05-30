// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import '../time_machine_testing.dart';

Future main() async {
  await runTests();
}

// DateTime doesn't do Ticks -- only Microseconds, so we lose some precision (+ we don't either anymore)
const int extraMicroseconds = 876; // 8765;

DateTime UnixEpochDateTime = DateTime.utc(1970, 1, 1, 0, 0, 0);
// This was when I was writing the tests, having finally made everything work - several thousand lines
// of shockingly untested code.
DateTime TimeOfGreatAchievement = DateTime.utc(2009, 11, 27, 18, 38, 25, 345)
    .add(const Duration(microseconds: extraMicroseconds)); // + TimeSpan.FromTicks(8765);

CalendarSystem Iso = CalendarSystem.iso;

@Test()
void FieldsOf_UnixEpoch()
{
  // It's easiest to test this using a LocalDateTime in the ISO calendar system.
  // LocalDateTime just passes everything through anyway.
  LocalDateTime epoch = TimeConstants.unixEpoch.inUtc().localDateTime;

  expect(1970, epoch.year);
  expect(1970, epoch.yearOfEra);
  expect(1970, WeekYearRules.iso.getWeekYear(epoch.calendarDate));
  expect(1, WeekYearRules.iso.getWeekOfWeekYear(epoch.calendarDate));
  expect(1, epoch.monthOfYear);
  expect(1, epoch.dayOfMonth);
  expect(1, epoch.dayOfYear);
  expect(DayOfWeek.thursday, epoch.dayOfWeek);
  expect(Era.common, epoch.era);
  expect(0, epoch.hourOfDay);
  expect(0, epoch.minuteOfHour);
  expect(0, epoch.secondOfMinute);
  expect(0, epoch.millisecondOfSecond);
  expect(0, epoch.clockTime.timeSinceMidnight.inMicroseconds);
  expect(0, epoch.microsecondOfSecond);
}

@Test()
void FieldsOf_GreatAchievement()
{
  // LocalDateTime now = new Instant.fromUnixTimeTicks((TimeOfGreatAchievement.difference(UnixEpochDateTime)).Ticks).InUtc().LocalDateTime;
  LocalDateTime now = Instant.fromEpochMicroseconds((
      TimeOfGreatAchievement.difference(UnixEpochDateTime))
      .inMicroseconds).inUtc().localDateTime;

  expect(2009, now.year);
  expect(2009, now.yearOfEra);
  expect(2009, WeekYearRules.iso.getWeekYear(now.calendarDate));
  expect(48, WeekYearRules.iso.getWeekOfWeekYear(now.calendarDate));
  expect(11, now.monthOfYear);
  expect(27, now.dayOfMonth);
  // expect(TimeOfGreatAchievement.dayOfYear, now.DayOfYear);
  expect(DayOfWeek.friday, now.dayOfWeek);
  expect(Era.common, now.era);
  expect(18, now.hourOfDay);
  expect(38, now.minuteOfHour);
  expect(25, now.secondOfMinute);
  expect(345, now.millisecondOfSecond);

  // DartWeb only does millisecond precision in dart:core (which TimeOfGreatAchievement is funnelled through)
  if (Platform.isVM) {
    expect(345876, now.microsecondOfSecond); // 3458765
    expect(18 * TimeConstants.microsecondsPerHour +
        38 * TimeConstants.microsecondsPerMinute +
        25 * TimeConstants.microsecondsPerSecond +
        345876, // 3458765
        now.clockTime.timeSinceMidnight.inMicroseconds);
  }
}

@Test()
void ConstructLocalInstant_WithAllFields()
{
  LocalInstant localAchievement = ILocalDateTime.toLocalInstant(LocalDateTime(2009, 11, 27, 18, 38, 25, ms: 345).addMicroseconds(extraMicroseconds));
  int bclMicroseconds = (TimeOfGreatAchievement.difference(UnixEpochDateTime)).inMicroseconds;
  int bclDays = (bclMicroseconds ~/ TimeConstants.microsecondsPerDay);
  int bclMicrosecondOfDay = bclMicroseconds % TimeConstants.microsecondsPerDay;
  expect(bclDays, localAchievement.daysSinceEpoch);
  if (Platform.isVM) {
    expect(bclMicrosecondOfDay, localAchievement.nanosecondOfDay / TimeConstants.nanosecondsPerMicrosecond);
  } else {
    expect(bclMicrosecondOfDay / TimeConstants.microsecondsPerMillisecond, localAchievement.nanosecondOfDay ~/ TimeConstants.nanosecondsPerMillisecond);
  }
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
  LocalDate localDate = LocalDate(-1, 1, 1);
  expect(Era.beforeCommon, localDate.era);
  expect(-1, localDate.year);
  expect(2, localDate.yearOfEra);
}

@Test()
void BeforeCommonEra_BySpecifyingEra()
{
  // Year -1 in absolute terms is 2BCE
  LocalDate localDate = LocalDate(2, 1, 1, CalendarSystem.iso, Era.beforeCommon);
  expect(Era.beforeCommon, localDate.era);
  expect(-1, localDate.year);
  expect(2, localDate.yearOfEra);
}

