// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import '../time_machine_testing.dart';

/// Tests for the Coptic calendar system.
Future main() async {
  await runTests();
}

@Test()
void CopticEpoch()
{
  CalendarSystem coptic = CalendarSystem.coptic;
  LocalDateTime copticEpoch = LocalDateTime(1, 1, 1, 0, 0, 0, calendar: coptic);

  CalendarSystem julian = CalendarSystem.julian;
  LocalDateTime converted = copticEpoch.withCalendar(julian);

  LocalDateTime expected = LocalDateTime(284, 8, 29, 0, 0, 0, calendar: julian);
  expect(expected, converted);
}

@Test()
void UnixEpoch()
{
  CalendarSystem coptic = CalendarSystem.coptic;
  // note: printing `unixEpoch` will call YearMonthDayCalculator.getStartOfYearInDays(int year) for -9998 and 10000 for VM, but not on JS -- and it appears to be a redundant call
  // todo: investigatge
  // print(TimeConstants.unixEpoch);
  LocalDateTime unixEpochInCopticCalendar = TimeConstants.unixEpoch.inZone(DateTimeZone.utc, coptic).localDateTime;
  LocalDateTime expected = LocalDateTime(1686, 4, 23, 0, 0, 0, calendar: coptic);
  expect(expected, unixEpochInCopticCalendar);
}

@Test()
void SampleDate()
{
  CalendarSystem copticCalendar = CalendarSystem.coptic;
  LocalDateTime iso = LocalDateTime(2004, 6, 9, 0, 0, 0);
  LocalDateTime coptic = iso.withCalendar(copticCalendar);

  expect(Era.annoMartyrum, coptic.era);
  expect(1720, coptic.yearOfEra);

  expect(1720, coptic.year);
  expect(copticCalendar.isLeapYear(1720), isFalse);

  expect(10, coptic.monthOfYear);
  expect(2, coptic.dayOfMonth);

  expect(DayOfWeek.wednesday, coptic.dayOfWeek);

  expect(9 * 30 + 2, coptic.dayOfYear);

  expect(0, coptic.hourOfDay);
  expect(0, coptic.minuteOfHour);
  expect(0, coptic.secondOfMinute);
  expect(0, coptic.millisecondOfSecond);
}

// Really testing SingleEraCalculator...
@Test()
void InvalidEra()
{
  // expect(() => CalendarSystem.coptic.getAbsoluteYear(1720, null), throwsArgumentError);
  expect(() => CalendarSystem.coptic.getAbsoluteYear(1720, Era.annoHegirae), throwsArgumentError);
}
