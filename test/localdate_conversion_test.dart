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
void AtMidnight()
{
  LocalDate date = LocalDate(2011, 6, 29);
  LocalDateTime expected = LocalDateTime(2011, 6, 29, 0, 0, 0);
  expect(date.atMidnight(), expected);
}

@Test()
void WithCalendar()
{
  LocalDate isoEpoch = LocalDate(1970, 1, 1);
  LocalDate julianEpoch = isoEpoch.withCalendar(CalendarSystem.julian);
  expect(1969, julianEpoch.year);
  expect(12, julianEpoch.monthOfYear);
  expect(19, julianEpoch.dayOfMonth);
}

@Test()
void WithOffset()
{
  var date = LocalDate(2011, 6, 29);
  var offset = Offset.hours(5);
  var expected = OffsetDate(date, offset);
  expect(expected, date.withOffset(offset));
}

@Test()
void ToDateTimeUnspecified()
{
  LocalDate noda = LocalDate(2015, 4, 2);
  DateTime bcl = DateTime(2015, 4, 2, 0, 0, 0); //, DateTimeKind.Unspecified);
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
  LocalDate start = LocalDate(1, 1, 1);
  // Assert.Throws<ArgumentOutOfRangeException>
  expect(() => start.withCalendar(CalendarSystem.persianSimple), throwsRangeError);
}
