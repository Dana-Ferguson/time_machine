// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/Calendars/JulianCalendarSystemTest.cs
// 8d5399d  on Feb 26, 2016

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

CalendarSystem Julian = CalendarSystem.Julian;

/// The Unix epoch is equivalent to December 19th 1969 in the Julian calendar.
@Test()
void Epoch()
{
  LocalDateTime julianEpoch = TimeConstants.unixEpoch.InZone_Calendar(DateTimeZone.Utc, Julian).localDateTime;
  expect(1969, julianEpoch.Year);
  expect(12, julianEpoch.Month);
  expect(19, julianEpoch.Day);
}

@Test()
void LeapYears()
{
  expect(Julian.IsLeapYear(1900), isTrue); // No 100 year rule...
  expect(Julian.IsLeapYear(1901), isFalse);
  expect(Julian.IsLeapYear(1904), isTrue);
  expect(Julian.IsLeapYear(2000), isTrue);
  expect(Julian.IsLeapYear(2100), isTrue); // No 100 year rule...
  expect(Julian.IsLeapYear(2400), isTrue);
  // Check 1BC, 5BC etc...
  expect(Julian.IsLeapYear(0), isTrue);
  expect(Julian.IsLeapYear(-4), isTrue);
}
