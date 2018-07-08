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

final CalendarSystem JulianCalendar = CalendarSystem.julian;

@Test()
void Construction_DifferentCalendars()
{
  LocalDate start = new LocalDate(1600, 1, 1);
  LocalDate end = new LocalDate(1800, 1, 1, JulianCalendar);
  expect(() => new DateInterval(start, end), throwsArgumentError);
// Assert.Throws<ArgumentException>(() => new DateInterval(start, end));
}

@Test()
void Construction_EndBeforeStart()
{
  LocalDate start = new LocalDate(1600, 1, 1);
  LocalDate end = new LocalDate(1500, 1, 1);
  expect(() => new DateInterval(start, end), throwsArgumentError);
// Assert.Throws<ArgumentException>(() => new DateInterval(start, end));
}

@Test()
void Construction_EqualStartAndEnd()
{
  LocalDate start = new LocalDate(2000, 1, 1);
  // Assert.DoesNotThrow(() => new DateInterval(start, start));
  expect(() => new DateInterval(start, start), isNotNull);
}

@Test()
void Construction_Properties()
{
  LocalDate start = new LocalDate(2000, 1, 1);
  LocalDate end = new LocalDate(2001, 6, 19);
  var interval = new DateInterval(start, end);
  expect(start, interval.start);
  expect(end, interval.end);
}

@Test()
void Equals_SameInstance()
{
  LocalDate start = new LocalDate(2000, 1, 1);
  LocalDate end = new LocalDate(2001, 6, 19);
  var interval = new DateInterval(start, end);

  expect(interval, interval);
  expect(interval.hashCode, interval.hashCode);
  // CS1718: Comparison made to same variable.  This is intentional to test operator ==.
  //#pragma warning disable 1718
  expect(interval == interval, isTrue);
  expect(interval != interval, isFalse);
  //#pragma warning restore 1718
  expect(interval.equals(interval), isTrue); // IEquatable implementation
}

@Test()
void Equals_EqualValues()
{
  LocalDate start = new LocalDate(2000, 1, 1);
  LocalDate end = new LocalDate(2001, 6, 19);
  var interval1 = new DateInterval(start, end);
  var interval2 = new DateInterval(start, end);

  expect(interval1, interval2);
  expect(interval1.hashCode, interval2.hashCode);
  expect(interval1 == interval2, isTrue);
  expect(interval1 != interval2, isFalse);
  expect(interval1.equals(interval2), isTrue); // IEquatable implementation
}

@Test()
void Equals_DifferentCalendars()
{
  LocalDate start1 = new LocalDate(2000, 1, 1);
  LocalDate end1 = new LocalDate(2001, 6, 19);
  // This is a really, really similar calendar to ISO, but we do distinguish.
  LocalDate start2 = start1.withCalendar(CalendarSystem.gregorian);
  LocalDate end2 = end1.withCalendar(CalendarSystem.gregorian);
  var interval1 = new DateInterval(start1, end1);
  var interval2 = new DateInterval(start2, end2);

  expect(interval1, isNot(interval2));
  expect(interval1.hashCode, isNot(interval2.hashCode));
  expect(interval1 == interval2, isFalse);
  expect(interval1 != interval2, isTrue);
  expect(interval1.equals(interval2), isFalse); // IEquatable implementation
}

@Test()
void Equals_DifferentStart()
{
  LocalDate start1 = new LocalDate(2000, 1, 1);
  LocalDate start2 = new LocalDate(2000, 1, 2);
  LocalDate end = new LocalDate(2001, 6, 19);
  var interval1 = new DateInterval(start1, end);
  var interval2 = new DateInterval(start2, end);

  expect(interval1, isNot(interval2));
  expect(interval1.hashCode, isNot(interval2.hashCode));
  expect(interval1 == interval2, isFalse);
  expect(interval1 != interval2, isTrue);
  expect(interval1.equals(interval2), isFalse); // IEquatable implementation
}

@Test()
void Equals_DifferentEnd()
{
  LocalDate start = new LocalDate(2000, 1, 1);
  LocalDate end1 = new LocalDate(2001, 6, 19);
  LocalDate end2 = new LocalDate(2001, 6, 20);
  var interval1 = new DateInterval(start, end1);
  var interval2 = new DateInterval(start, end2);

  expect(interval1, isNot(interval2));
  expect(interval1.hashCode, isNot(interval2.hashCode));
  expect(interval1 == interval2, isFalse);
  expect(interval1 != interval2, isTrue);
  expect(interval1.equals(interval2), isFalse); // IEquatable implementation
}

@Test()
void Equals_DifferentToNull()
{
  LocalDate start = new LocalDate(2000, 1, 1);
  LocalDate end = new LocalDate(2001, 6, 19);
  var interval = new DateInterval(start, end);

  expect(interval.equals(null), isFalse);
}

@Test()
void Equals_DifferentToOtherType()
{
  LocalDate start = new LocalDate(2000, 1, 1);
  LocalDate end = new LocalDate(2001, 6, 19);
  var interval = new DateInterval(start, end);
  // expect(interval.equals(new Instant.fromUnixTimeTicks(0)), isFalse);
  // ignore: unrelated_type_equality_checks
  expect(interval == new Instant.fromUnixTimeMicroseconds(0), isFalse);
}

@Test()
void StringRepresentation()
{
  LocalDate start = new LocalDate(2000, 1, 1);
  LocalDate end = new LocalDate(2001, 6, 19);
  var interval = new DateInterval(start, end);
  expect(interval.toString(), "[2000-01-01, 2001-06-19]");
}

@Test()
void Length()
{
  LocalDate start = new LocalDate(2000, 1, 1);
  LocalDate end = new LocalDate(2000, 2, 10);
  var interval = new DateInterval(start, end);
  expect(41, interval.length);
}

@Test()
void Calendar()
{
  var calendar = CalendarSystem.julian;
  LocalDate start = new LocalDate(2000, 1, 1, calendar);
  LocalDate end = new LocalDate(2000, 2, 10, calendar);
  var interval = new DateInterval(start, end);
  expect(calendar, interval.calendar);
}

@Test()
@TestCase(const ["1999-12-31", false], "Before start")
@TestCase(const ["2000-01-01", true], "On start")
@TestCase(const ["2005-06-06", true], "In middle")
@TestCase(const ["2014-06-30", true], "On end")
@TestCase(const ["2014-07-01", false], "After end")
void Contains(String candidateText, bool expected)
{
  var start = new LocalDate(2000, 1, 1);
  var end = new LocalDate(2014, 06, 30);
  var candidate = LocalDatePattern.iso.parse(candidateText).value;
  var interval = new DateInterval(start, end);
  expect(expected, interval.contains(candidate));
}

@Test()
void Contains_DifferentCalendar()
{
  var start = new LocalDate(2000, 1, 1);
  var end = new LocalDate(2014, 06, 30);
  var interval = new DateInterval(start, end);
  var candidate = new LocalDate(2000, 1, 1, JulianCalendar);
  // Assert.Throws<ArgumentException>(() => interval.Contains(candidate));
  expect(() => interval.contains(candidate), throwsArgumentError);
}

//@Test()
//void Deconstruction()
//{
//  var start = new LocalDate(2017, 11, 6);
//  var end = new LocalDate(2017, 11, 10);
//  var value = new DateInterval(start, end);
//
//  var (actualStart, actualEnd) = value;
//
//Assert.Multiple(() {
//  expect(start, actualStart);
//  expect(end, actualEnd);
//  });
//}

@Test()
void Contains_NullInterval_Throws()
{
  var start = new LocalDate(2017, 11, 6);
  var end = new LocalDate(2017, 11, 10);
  var value = new DateInterval(start, end);

  // Assert.Throws<ArgumentNullException>(() => value.Contains(null));
  expect(() => value.contains(null), throwsArgumentError);
}

@Test() @SkipMe.unimplemented()
void Contains_IntervalWithinAnotherCalendar_Throws()
{
  var value = new DateInterval(
      new LocalDate(2017, 11, 6, CalendarSystem.gregorian),
      new LocalDate(2017, 11, 10, CalendarSystem.gregorian));

  var other = new DateInterval(
      new LocalDate(2017, 11, 6, CalendarSystem.coptic),
      new LocalDate(2017, 11, 10, CalendarSystem.coptic));

  // Assert.Throws<ArgumentException>(() => value.Contains(other));
  expect(() => value.containsInterval(other), throwsArgumentError);
}

@TestCase(const ["2014-03-07,2014-03-07", "2014-03-07,2014-03-07", true])
@TestCase(const ["2014-03-07,2014-03-10", "2015-01-01,2015-04-01", false])
@TestCase(const ["2015-01-01,2015-04-01", "2014-03-07,2014-03-10", false])
@TestCase(const ["2014-03-07,2014-03-31", "2014-03-07,2014-03-15", true])
@TestCase(const ["2014-03-07,2014-03-31", "2014-03-10,2014-03-31", true])
@TestCase(const ["2014-03-07,2014-03-31", "2014-03-10,2014-03-15", true])
@TestCase(const ["2014-03-07,2014-03-31", "2014-03-05,2014-03-09", false])
@TestCase(const ["2014-03-07,2014-03-31", "2014-03-20,2014-04-07", false])
@TestCase(const ["2014-11-01,2014-11-30", "2014-01-01,2014-12-31", false])
void Contains_IntervalOverload(String firstInterval, String secondInterval, bool expectedResult)
{
  DateInterval value = ParseInterval(firstInterval);
  DateInterval other = ParseInterval(secondInterval);
  expect(expectedResult, value.containsInterval(other));
}

@Test()
void Intersection_NullInterval_Throws()
{
  var value = new DateInterval(ILocalDate.fromDaysSinceEpoch(100), ILocalDate.fromDaysSinceEpoch(200));
  // Assert.Throws<ArgumentNullException>(() => value.Intersection(null));
  expect(() => value.intersection(null), throwsArgumentError);
}

@Test() @SkipMe.unimplemented()
void Intersection_IntervalInDifferentCalendar_Throws()
{
  var value = new DateInterval(
      new LocalDate(2017, 11, 6, CalendarSystem.gregorian),
      new LocalDate(2017, 11, 10, CalendarSystem.gregorian));

  var other = new DateInterval(
      new LocalDate(2017, 11, 6, CalendarSystem.coptic),
      new LocalDate(2017, 11, 10, CalendarSystem.coptic));

  // Assert.Throws<ArgumentException>(() => value.Intersection(other));
  expect(() => value.intersection(other), throwsArgumentError);
}

@TestCase(const ["2014-03-07,2014-03-07", "2014-03-07,2014-03-07", "2014-03-07,2014-03-07"])
@TestCase(const ["2014-03-07,2014-03-10", "2015-01-01,2015-04-01", null])
@TestCase(const ["2015-01-01,2015-04-01", "2014-03-07,2014-03-10", null])
@TestCase(const ["2014-03-07,2014-03-31", "2014-03-07,2014-03-15", "2014-03-07,2014-03-15"])
@TestCase(const ["2014-03-07,2014-03-31", "2014-03-10,2014-03-31", "2014-03-10,2014-03-31"])
@TestCase(const ["2014-03-07,2014-03-31", "2014-03-10,2014-03-15", "2014-03-10,2014-03-15"])
@TestCase(const ["2014-03-07,2014-03-31", "2014-03-05,2014-03-09", "2014-03-07,2014-03-09"])
@TestCase(const ["2014-03-07,2014-03-31", "2014-03-20,2014-04-07", "2014-03-20,2014-03-31"])
@TestCase(const ["2014-11-01,2014-11-30", "2014-01-01,2014-12-31", "2014-11-01,2014-11-30"])
void Intersection(String firstInterval, String secondInterval, String expectedInterval)
{
  var value = ParseInterval(firstInterval);
  var other = ParseInterval(secondInterval);
  var expectedResult = ParseInterval(expectedInterval);
  expect(expectedResult, value.intersection(other));
}

@Test()
void Union_NullInterval_Throws()
{
  var value = new DateInterval(ILocalDate.fromDaysSinceEpoch(100), ILocalDate.fromDaysSinceEpoch(200));
  // Assert.Throws<ArgumentNullException>(() => value.Union(null));
  expect(() => value.union(null), throwsArgumentError);
}

@Test() @SkipMe.unimplemented()
void Union_DifferentCalendar_Throws()
{
  var value = new DateInterval(
      new LocalDate(2017, 11, 6, CalendarSystem.gregorian),
      new LocalDate(2017, 11, 10, CalendarSystem.gregorian));

  var other = new DateInterval(
      new LocalDate(2017, 11, 6, CalendarSystem.coptic),
      new LocalDate(2017, 11, 10, CalendarSystem.coptic));

  // Assert.Throws<ArgumentException>(() => value.Union(other));
  expect(() => value.union(other), throwsArgumentError);
}

@TestCase(const ["2014-03-07,2014-03-20", "2015-03-07,2015-03-20", null], "Disjointed intervals")
@TestCase(const ["2014-03-07,2014-03-20", "2014-03-21,2014-03-30", "2014-03-07,2014-03-30"], "Abutting intervals")
@TestCase(const ["2014-03-07,2014-03-20", "2014-03-07,2014-03-20", "2014-03-07,2014-03-20"], "Equal intervals")
@TestCase(const ["2014-03-07,2014-03-20", "2014-03-15,2014-03-23", "2014-03-07,2014-03-23"], "Overlapping intervals")
@TestCase(const ["2014-03-07,2014-03-20", "2014-03-10,2014-03-15", "2014-03-07,2014-03-20"], "Interval completely contained in another")
void Union(String first, String second, String expected)
{
  DateInterval firstInterval = ParseInterval(first);
  DateInterval secondInterval = ParseInterval(second);
  DateInterval expectedResult = ParseInterval(expected);

  expect(expectedResult, firstInterval.union(secondInterval), reason: "First union failed.");
  expect(expectedResult, secondInterval.union(firstInterval), reason: "Second union failed.");
}

DateInterval ParseInterval(String textualInterval)
{
  if (textualInterval == null)
  {
    return null;
  }

  var parts = textualInterval.split(','); //new char[] { ',' });
  var start = LocalDatePattern.iso.parse(parts[0]).value;
  var end = LocalDatePattern.iso.parse(parts[1]).value;

  return new DateInterval(start, end);
}
