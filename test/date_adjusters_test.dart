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
void StartOfMonth()
{
  var start = new LocalDate(2014, 6, 27);
  var end = new LocalDate(2014, 6, 1);
  expect(end, DateAdjusters.startOfMonth(start));
}

@Test()
void EndOfMonth()
{
  var start = new LocalDate(2014, 6, 27);
  var end = new LocalDate(2014, 6, 30);
  expect(end, DateAdjusters.endOfMonth(start));
}

@Test()
void DayOfMonth()
{
  var start = new LocalDate(2014, 6, 27);
  var end = new LocalDate(2014, 6, 19);
  var adjuster = DateAdjusters.dayOfMonth(19);
  expect(end, adjuster(start));
}

@Test()
@TestCase(const [2014, 8, 18, DayOfWeek.monday, 2014, 8, 18], "Same day-of-week")
@TestCase(const [2014, 8, 18, DayOfWeek.tuesday, 2014, 8, 19])
@TestCase(const [2014, 8, 18, DayOfWeek.sunday, 2014, 8, 24])
@TestCase(const [2014, 8, 31, DayOfWeek.monday, 2014, 9, 1], "Wrap month")
void NextOrSame(
    int year, int month, int day, DayOfWeek dayOfWeek,
    int expectedYear, int expectedMonth, int expectedDay)
{
  LocalDate start = new LocalDate(year, month, day);
  LocalDate actual = start.adjust(DateAdjusters.nextOrSame(dayOfWeek));
  LocalDate expected = new LocalDate(expectedYear, expectedMonth, expectedDay);
  expect(expected, actual);
}

@Test()
@TestCase(const [2014, 8, 18, DayOfWeek.monday, 2014, 8, 18], "Same day-of-week")
@TestCase(const [2014, 8, 18, DayOfWeek.tuesday, 2014, 8, 12])
@TestCase(const [2014, 8, 18, DayOfWeek.sunday, 2014, 8, 17])
@TestCase(const [2014, 8, 1, DayOfWeek.thursday, 2014, 7, 31], "Wrap month")
void PreviousOrSame(
    int year, int month, int day, DayOfWeek dayOfWeek,
    int expectedYear, int expectedMonth, int expectedDay)
{
  LocalDate start = new LocalDate(year, month, day);
  LocalDate actual = start.adjust(DateAdjusters.previousOrSame(dayOfWeek));
  LocalDate expected = new LocalDate(expectedYear, expectedMonth, expectedDay);
  expect(expected, actual);
}

@Test()
@TestCase(const [2014, 8, 18, DayOfWeek.monday, 2014, 8, 25], "Same day-of-week")
@TestCase(const [2014, 8, 18, DayOfWeek.tuesday, 2014, 8, 19])
@TestCase(const [2014, 8, 18, DayOfWeek.sunday, 2014, 8, 24])
@TestCase(const [2014, 8, 31, DayOfWeek.monday, 2014, 9, 1], "Wrap month")
void Next(
    int year, int month, int day, DayOfWeek dayOfWeek,
    int expectedYear, int expectedMonth, int expectedDay)
{
  LocalDate start = new LocalDate(year, month, day);
  LocalDate actual = start.adjust(DateAdjusters.next(dayOfWeek));
  LocalDate expected = new LocalDate(expectedYear, expectedMonth, expectedDay);
  expect(expected, actual);
}

@Test()
@TestCase(const [2014, 8, 18, DayOfWeek.monday, 2014, 8, 11], "Same day-of-week")
@TestCase(const [2014, 8, 18, DayOfWeek.tuesday, 2014, 8, 12])
@TestCase(const [2014, 8, 18, DayOfWeek.sunday, 2014, 8, 17])
@TestCase(const [2014, 8, 1, DayOfWeek.thursday, 2014, 7, 31], "Wrap month")
void Previous(
    int year, int month, int day, DayOfWeek dayOfWeek,
    int expectedYear, int expectedMonth, int expectedDay)
{
  LocalDate start = new LocalDate(year, month, day);
  LocalDate actual = start.adjust(DateAdjusters.previous(dayOfWeek));
  LocalDate expected = new LocalDate(expectedYear, expectedMonth, expectedDay);
  expect(expected, actual);
}

@Test()
void Month_Valid()
{
  var adjuster = DateAdjusters.month(2);
  var start = new LocalDate(2017, 8, 21, CalendarSystem.julian);
  var actual = start.adjust(adjuster);
  var expected = new LocalDate(2017, 2, 21, CalendarSystem.julian);
  expect(expected, actual);
}

@Test()
void Month_InvalidAdjustment()
{
  var adjuster = DateAdjusters.month(2);
  var start = new LocalDate(2017, 8, 30, CalendarSystem.julian);
  // Assert.Throws<ArgumentOutOfRangeException>(() => start.With(adjuster));
  expect(() => start.adjust(adjuster), throwsRangeError);
}

@Test()
void IsoDayOfWeekAdjusters_Invalid()
{
  var invalid = new DayOfWeek (10); //IsoDayOfWeek) 10;
  //Assert.Throws<ArgumentOutOfRangeException>(() => DateAdjusters.Next(invalid));
  //Assert.Throws<ArgumentOutOfRangeException>(() => DateAdjusters.NextOrSame(invalid));
  //Assert.Throws<ArgumentOutOfRangeException>(() => DateAdjusters.Previous(invalid));
  //Assert.Throws<ArgumentOutOfRangeException>(() => DateAdjusters.PreviousOrSame(invalid));
  expect(() => DateAdjusters.next(invalid), throwsRangeError);
  expect(() => DateAdjusters.nextOrSame(invalid), throwsRangeError);
  expect(() => DateAdjusters.previous(invalid), throwsRangeError);
  expect(() => DateAdjusters.previousOrSame(invalid), throwsRangeError);
}
