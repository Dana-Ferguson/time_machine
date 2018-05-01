// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/LocalDateTest.Conversion.cs
// 63e9065  on Aug 3, 2017

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
void AtMidnight()
{
  LocalDate date = new LocalDate(2011, 6, 29);
  LocalDateTime expected = new LocalDateTime.fromYMDHMS(2011, 6, 29, 0, 0, 0);
  expect(expected, date.AtMidnight);
}

@Test()
void WithCalendar()
{
  LocalDate isoEpoch = new LocalDate(1970, 1, 1);
  LocalDate julianEpoch = isoEpoch.WithCalendar(CalendarSystem.Julian);
  expect(1969, julianEpoch.Year);
  expect(12, julianEpoch.Month);
  expect(19, julianEpoch.Day);
}

@Test()
void WithOffset()
{
  var date = new LocalDate(2011, 6, 29);
  var offset = new Offset.fromHours(5);
  var expected = new OffsetDate(date, offset);
  expect(expected, date.WithOffset(offset));
}

@Test()
void ToDateTimeUnspecified()
{
  LocalDate noda = new LocalDate(2015, 4, 2);
  DateTime bcl = new DateTime(2015, 4, 2, 0, 0, 0); //, DateTimeKind.Unspecified);
  // todo: this needs to be redefined as toDateTimeUtc or toDateTimeLocal or something?
  expect(bcl, noda.toDateTimeUnspecified());
}

//@Test()
//void FromDateTime()
//{
//  var expected = new LocalDate(2011, 08, 18);
//  for (DateTimeKind kind in Enum.GetValues(typeof(DateTimeKind)))
//  {
//  var bcl = new DateTime(2011, 08, 18, 20, 53, 0, kind);
//  var actual = LocalDate.FromDateTime(bcl);
//  expect(expected, actual);
//  }
//}

//@Test()
//void FromDateTime_WithCalendar()
//{
//  // Julian calendar is 13 days behind Gregorian calendar in the 21st century
//  var expected = new LocalDate.forCalendar(2011, 08, 05, CalendarSystem.Julian);
//  foreach (DateTimeKind kind in Enum.GetValues(typeof(DateTimeKind)))
//  {
//  var bcl = new DateTime(2011, 08, 18, 20, 53, 0, kind);
//  var actual = LocalDate.FromDateTime(bcl, CalendarSystem.Julian);
//  expect(expected, actual);
//  }
//}

@Test()
void WithCalendar_OutOfRange()
{
  LocalDate start = new LocalDate(1, 1, 1);
  // Assert.Throws<ArgumentOutOfRangeException>
  expect(() => start.WithCalendar(CalendarSystem.PersianSimple), throwsRangeError);
}