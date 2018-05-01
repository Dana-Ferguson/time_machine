// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/LocalDateTest.PeriodArithmetic.cs
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
void Addition_WithPeriod()
{
  LocalDate start = new LocalDate(2010, 6, 19);
  Period period = new Period.fromMonths(3) + new Period.fromDays(10);
  LocalDate expected = new LocalDate(2010, 9, 29);
  expect(expected, start + period);
}

@Test()
void Addition_TruncatesOnShortMonth()
{
  LocalDate start = new LocalDate(2010, 1, 30);
  Period period = new Period.fromMonths(1);
  LocalDate expected = new LocalDate(2010, 2, 28);
  expect(expected, start + period);
}

@Test()
void Addition_WithNullPeriod_ThrowsArgumentNullException()
{
  LocalDate date = new LocalDate(2010, 1, 1);
  // Call to ToString just to make it a valid statement
  // Assert.Throws<ArgumentNullException>
  Period p = null;
  expect(() => (date + p).toString(), throwsArgumentError);
}

@Test()
void Subtraction_WithPeriod()
{
  LocalDate start = new LocalDate(2010, 9, 29);
  Period period = new Period.fromMonths(3) + new Period.fromDays(10);
  LocalDate expected = new LocalDate(2010, 6, 19);
  expect(expected, start - period);
}

@Test()
void Subtraction_TruncatesOnShortMonth()
{
  LocalDate start = new LocalDate(2010, 3, 30);
  Period period = new Period.fromMonths(1);
  LocalDate expected = new LocalDate(2010, 2, 28);
  expect(expected, start - period);
}

@Test()
void Subtraction_WithNullPeriod_ThrowsArgumentNullException()
{
  LocalDate date = new LocalDate(2010, 1, 1);
  // Call to ToString just to make it a valid statement
  // Assert.Throws<ArgumentNullException>
  Period p = null;
  expect(() => (date - p).toString(), throwsStateError);
}

@Test()
void Addition_PeriodWithTime()
{
  LocalDate date = new LocalDate(2010, 1, 1);
  Period period = new Period.fromHours(1);
  // Use method not operator here to form a valid statement
  // Assert.Throws<ArgumentException>
  expect(() => LocalDate.Add(date, period), throwsArgumentError);
}

@Test()
void Subtraction_PeriodWithTime()
{
  LocalDate date = new LocalDate(2010, 1, 1);
  Period period = new Period.fromHours(1);
  // Use method not operator here to form a valid statement
  // Assert.Throws<ArgumentException>
  expect(() => LocalDate.Subtract(date, period), throwsArgumentError);
}

@Test()
void PeriodAddition_MethodEquivalents()
{
  LocalDate start = new LocalDate(2010, 6, 19);
  Period period = new Period.fromMonths(3) + new Period.fromDays(10);
  expect(start + period, LocalDate.Add(start, period));
  expect(start + period, start.Plus(period));
}

@Test()
void PeriodSubtraction_MethodEquivalents()
{
  LocalDate start = new LocalDate(2010, 6, 19);
  Period period = new Period.fromMonths(3) + new Period.fromDays(10);
  LocalDate end = start + period;
  print('Period: $period;');
  print('End: $end;');
  print('Start: $start;');
  print('End - Start: ${end - start};');
  expect(start - period, LocalDate.Subtract(start, period));
  expect(start - period, start.MinusPeriod(period));
  expect(period, end - start);
  expect(period, LocalDate.Between(end, start)); // LocalDate.Minus(end, start)
  expect(period, end.MinusDate(start));
}