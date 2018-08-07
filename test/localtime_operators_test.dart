// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

@Test()
void Addition_WithPeriod()
{
  LocalTime start = new LocalTime(3, 30, 0);
  Period period = new Period(hours: 2) + new Period(seconds: 1);
  LocalTime expected = new LocalTime(5, 30, 1);
  expect(expected, start + period);
}

@Test()
void Addition_WrapsAtMidnight()
{
  LocalTime start = new LocalTime(22, 0, 0);
  Period period = new Period(hours: 3);
  LocalTime expected = new LocalTime(1, 0, 0);
  expect(expected, start + period);
}

@Test()
void Addition_WithNullPeriod_ThrowsArgumentNullException()
{
  LocalTime date = new LocalTime(12, 0, 0);
  // Call to ToString just to make it a valid statement
  Period period = null;
  expect(() => (date + period).toString(), throwsArgumentError);
}

@Test()
void Subtraction_WithPeriod()
{
  LocalTime start = new LocalTime(5, 30, 1);
  Period period = new Period(hours: 2) + new Period(seconds: 1);
  LocalTime expected = new LocalTime(3, 30, 0);
  expect(expected, start - period);
}

@Test()
void Subtraction_WrapsAtMidnight()
{
  LocalTime start = new LocalTime(1, 0, 0);
  Period period = new Period(hours: 3);
  LocalTime expected = new LocalTime(22, 0, 0);
  expect(expected, start - period);
}

@Test()
void Subtraction_WithNullPeriod_ThrowsArgumentNullException()
{
  LocalTime date = new LocalTime(12, 0, 0);
  // Call to ToString just to make it a valid statement
  Period period = null;
  expect(() => (date - period).toString(), throwsArgumentError);
}

@Test()
void Addition_PeriodWithDate()
{
  LocalTime time = new LocalTime(20, 30, 0);
  Period period = new Period(days: 1);
  // Use method not operator here to form a valid statement
  expect(() => LocalTime.plus(time, period), throwsArgumentError);
}

@Test()
void Subtraction_PeriodWithTime()
{
  LocalTime time = new LocalTime(20, 30, 0);
  Period period = new Period(days: 1);
  // Use method not operator here to form a valid statement
  expect(() => LocalTime.minus(time, period), throwsArgumentError);
}

@Test()
void PeriodAddition_MethodEquivalents()
{
  LocalTime start = new LocalTime(20, 30, 0);
  Period period = new Period(hours: 3) + new Period(minutes: 10);
  expect(start + period, LocalTime.plus(start, period));
  expect(start + period, start.add(period));
}

@Test()
void PeriodSubtraction_MethodEquivalents()
{
  LocalTime start = new LocalTime(20, 30, 0);
  Period period = new Period(hours: 3) + new Period(minutes: 10);
  LocalTime end = start + period;
  expect(start - period, LocalTime.minus(start, period));
  expect(start - period, start.subtract(period));

  // expect(period, end - start);
  // todo: does not exist
  // expect(period, LocalTime.Subtract(end, start));
  expect(period, end.periodSince(start));
}

@Test()
void ComparisonOperators()
{
  LocalTime time1 = new LocalTime(10, 30, 45);
  LocalTime time2 = new LocalTime(10, 30, 45);
  LocalTime time3 = new LocalTime(10, 30, 50);

  expect(time1 == time2, isTrue);
  expect(time1 == time3, isFalse);
  expect(time1 != time2, isFalse);
  expect(time1 != time3, isTrue);

  expect(time1 < time2, isFalse);
  expect(time1 < time3, isTrue);
  expect(time2 < time1, isFalse);
  expect(time3 < time1, isFalse);

  expect(time1 <= time2, isTrue);
  expect(time1 <= time3, isTrue);
  expect(time2 <= time1, isTrue);
  expect(time3 <= time1, isFalse);

  expect(time1 > time2, isFalse);
  expect(time1 > time3, isFalse);
  expect(time2 > time1, isFalse);
  expect(time3 > time1, isTrue);

  expect(time1 >= time2, isTrue);
  expect(time1 >= time3, isFalse);
  expect(time2 >= time1, isTrue);
  expect(time3 >= time1, isTrue);
}

@Test()
void Comparison_IgnoresOriginalCalendar()
{
  LocalDateTime dateTime1 = new LocalDateTime(1900, 1, 1, 10, 30, 0);
  LocalDateTime dateTime2 = dateTime1.withCalendar(CalendarSystem.julian);

  // Calendar information is propagated into LocalDate, but not into LocalTime
  expect(dateTime1.localDate == dateTime2.localDate, isFalse);
  expect(dateTime1.localTime == dateTime2.localTime, isTrue);
}

@Test()
void CompareTo()
{
  LocalTime time1 = new LocalTime(10, 30, 45);
  LocalTime time2 = new LocalTime(10, 30, 45);
  LocalTime time3 = new LocalTime(10, 30, 50);

  expect(time1.compareTo(time2), 0);
  expect(time1.compareTo(time3),  lessThan(0));
  expect(time3.compareTo(time2),  greaterThan(0));
}

/// IComparable.CompareTo works properly for LocalTime inputs.
@Test()
void IComparableCompareTo()
{
  LocalTime time1 = new LocalTime(10, 30, 45);
  LocalTime time2 = new LocalTime(10, 30, 45);
  LocalTime time3 = new LocalTime(10, 30, 50);

  Comparable i_time1 = time1;
  Comparable i_time3 = time3;

  expect(i_time1.compareTo(time2), 0);
  expect(i_time1.compareTo(time3),  lessThan(0));
  expect(i_time3.compareTo(time2),  greaterThan(0));
}

/// IComparable.CompareTo returns a positive number for a null input.
@Test()
void IComparableCompareTo_Null_Positive()
{
  var instance = new LocalTime(10, 30, 45);
  Comparable i_instance = instance;
  Object arg = null;
  var result = i_instance.compareTo(arg);
  expect(result,  greaterThan(0));
}

/// IComparable.CompareTo throws an ArgumentException for non-null arguments
/// that are not a LocalTime.
@Test()
void IComparableCompareTo_WrongType_ArgumentException()
{
  var instance = new LocalTime(10, 30, 45);
  Comparable i_instance = instance;
  var arg = new LocalDate(2012, 3, 6);
  try {
    expect(() => i_instance.compareTo(arg), throwsA(TestFailure)); // throwsArgumentError);
  } catch (e) {
    expect(e, new TypeMatcher<TestFailure>());
  }
}

