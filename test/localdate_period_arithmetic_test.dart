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
void Addition_WithPeriod()
{
  LocalDate start = LocalDate(2010, 6, 19);
  Period period = const Period(months: 3) + const Period(days: 10);
  LocalDate expected = LocalDate(2010, 9, 29);
  expect(expected, start + period);
}

@Test()
void Addition_TruncatesOnShortMonth()
{
  LocalDate start = LocalDate(2010, 1, 30);
  Period period = const Period(months: 1);
  LocalDate expected = LocalDate(2010, 2, 28);
  expect(expected, start + period);
}

// @Test()
// void Addition_WithNullPeriod_ThrowsArgumentNullException()
// {
//   LocalDate date = LocalDate(2010, 1, 1);
//   // Call to ToString just to make it a valid statement
//   // Assert.Throws<ArgumentNullException>
//   Period p;
//   expect(() => (date + p).toString(), throwsArgumentError);
// }

@Test()
void Subtraction_WithPeriod()
{
  LocalDate start = LocalDate(2010, 9, 29);
  Period period = const Period(months: 3) + const Period(days: 10);
  LocalDate expected = LocalDate(2010, 6, 19);
  expect(expected, start - period);
}

@Test()
void Subtraction_TruncatesOnShortMonth()
{
  LocalDate start = LocalDate(2010, 3, 30);
  Period period = const Period(months: 1);
  LocalDate expected = LocalDate(2010, 2, 28);
  expect(expected, start - period);
}

// @Test()
// void Subtraction_WithNullPeriod_ThrowsArgumentNullException()
// {
//   LocalDate date = LocalDate(2010, 1, 1);
//   // Call to ToString just to make it a valid statement
//   // Assert.Throws<ArgumentNullException>
//   Period p;
//   expect(() => (date - p).toString(), willThrow<ArgumentError>());
// }

@Test()
void Addition_PeriodWithTime()
{
  LocalDate date = LocalDate(2010, 1, 1);
  Period period = const Period(hours: 1);
  // Use method not operator here to form a valid statement
  // Assert.Throws<ArgumentException>
  expect(() => LocalDate.plus(date, period), throwsArgumentError);
}

@Test()
void Subtraction_PeriodWithTime()
{
  LocalDate date = LocalDate(2010, 1, 1);
  Period period = const Period(hours: 1);
  // Use method not operator here to form a valid statement
  // Assert.Throws<ArgumentException>
  expect(() => LocalDate.minus(date, period), throwsArgumentError);
}

@Test()
void PeriodAddition_MethodEquivalents()
{
  LocalDate start = LocalDate(2010, 6, 19);
  Period period = const Period(months: 3) + const Period(days: 10);
  expect(start + period, LocalDate.plus(start, period));
  expect(start + period, start.add(period));
}

@Test()
void PeriodSubtraction_MethodEquivalents()
{
  LocalDate start = LocalDate(2010, 6, 19);
  Period period = const Period(months: 3) + const Period(days: 10);
  LocalDate end = start + period;
  expect(start - period, LocalDate.minus(start, period));
  expect(start - period, start.subtract(period));
  // expect(period, end - start);
  expect(period, LocalDate.difference(end, start)); // LocalDate.Minus(end, start)
  expect(period, end.periodSince(start));
}
