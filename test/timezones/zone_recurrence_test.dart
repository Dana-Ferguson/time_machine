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


// @Test()
// void Constructor_nullName_exception()
// {
//   var yearOffset = ZoneYearOffset(TransitionMode.utc, 10, 31, DayOfWeek.wednesday.value, true, LocalTime.midnight);
//   // Assert.Throws(typeof(ArgumentNullException), () => new ZoneRecurrence(null, Offset.zero, yearOffset, 1971, 2009), 'Null name');
//   expect(() => ZoneRecurrence(null, Offset.zero, yearOffset, 1971, 2009), throwsArgumentError, reason: 'Null name');
// }

// @Test()
// void Constructor_nullYearOffset_exception()
// {
//   // Assert.Throws(typeof(ArgumentNullException), () => new ZoneRecurrence('bob', Offset.zero, null, 1971, 2009), "Null yearOffset");
//   expect(() => ZoneRecurrence('bob', Offset.zero, null, 1971, 2009), throwsArgumentError, reason: "Null yearOffset");
// }

@Test()
void Next_BeforeFirstYear()
{
  var januaryFirstMidnight = ZoneYearOffset(TransitionMode.utc, 1, 1, 0, true, LocalTime.midnight);
  var recurrence = ZoneRecurrence('bob', Offset.zero, januaryFirstMidnight, 1970, 1972);
  Transition actual = recurrence.next(Instant.minValue, Offset.zero, Offset.zero)!;
  Transition expected = Transition(TimeConstants.unixEpoch, Offset.zero);
  expect(expected, actual);
}

@Test()
void Next_FirstYear()
{
  var januaryFirstMidnight = ZoneYearOffset(TransitionMode.utc, 1, 1, 0, true, LocalTime.midnight);
  var recurrence = ZoneRecurrence('bob', Offset.zero, januaryFirstMidnight, 1970, 1972);
  Transition actual = recurrence.next(TimeConstants.unixEpoch, Offset.zero, Offset.zero)!;
  Transition expected = Transition(Instant.utc(1971, 1, 1, 0, 0), Offset.zero);
  expect(expected, actual);
}

@Test()
void NextTwice_FirstYear()
{
  var januaryFirstMidnight = ZoneYearOffset(TransitionMode.utc, 1, 1, 0, true, LocalTime.midnight);
  var recurrence = ZoneRecurrence('bob', Offset.zero, januaryFirstMidnight, 1970, 1972);
  Transition actual = recurrence.next(TimeConstants.unixEpoch, Offset.zero, Offset.zero)!;
  actual = recurrence.next(actual.instant, Offset.zero, Offset.zero)!;
  Transition expected = Transition(Instant.utc(1972, 1, 1, 0, 0), Offset.zero);
  expect(expected, actual);
}

@Test()
void Next_BeyondLastYear_null()
{
  var afterRecurrenceEnd = Instant.utc(1980, 1, 1, 0, 0);
  var januaryFirstMidnight = ZoneYearOffset(TransitionMode.utc, 1, 1, 0, true, LocalTime.midnight);
  var recurrence = ZoneRecurrence('bob', Offset.zero, januaryFirstMidnight, 1970, 1972);
  Transition? actual = recurrence.next(afterRecurrenceEnd, Offset.zero, Offset.zero);
  Transition? expected;
  expect(expected, actual);
}

@Test()
void PreviousOrSame_AfterLastYear()
{
  var januaryFirstMidnight = ZoneYearOffset(TransitionMode.utc, 1, 1, 0, true, LocalTime.midnight);
  var recurrence = ZoneRecurrence('bob', Offset.zero, januaryFirstMidnight, 1970, 1972);
  Transition actual = recurrence.previousOrSame(Instant.maxValue, Offset.zero, Offset.zero)!;
  Transition expected = Transition(Instant.utc(1972, 1, 1, 0, 0), Offset.zero);
  expect(expected, actual);
}

@Test()
void PreviousOrSame_LastYear()
{
  var januaryFirstMidnight = ZoneYearOffset(TransitionMode.utc, 1, 1, 0, true, LocalTime.midnight);
  var recurrence = ZoneRecurrence('bob', Offset.zero, januaryFirstMidnight, 1970, 1972);
  Transition actual = recurrence.previousOrSame(Instant.utc(1971, 1, 1, 0, 0) - Time.epsilon, Offset.zero, Offset.zero)!;
  Transition expected = Transition(TimeConstants.unixEpoch, Offset.zero);
  expect(expected, actual);
}

@Test()
void PreviousOrSameTwice_LastYear()
{
  var januaryFirstMidnight = ZoneYearOffset(TransitionMode.utc, 1, 1, 0, true, LocalTime.midnight);
  var recurrence = ZoneRecurrence('bob', Offset.zero, januaryFirstMidnight, 1970, 1973);
  Transition actual = recurrence.previousOrSame(Instant.utc(1972, 1, 1, 0, 0) - Time.epsilon, Offset.zero, Offset.zero)!;
  actual = recurrence.previousOrSame(actual.instant - Time.epsilon, Offset.zero, Offset.zero)!;
  Transition expected = Transition(TimeConstants.unixEpoch, Offset.zero);
  expect(expected, actual);
}

@Test()
void PreviousOrSame_OnFirstYear_null()
{
  // Transition is on January 2nd, but we're asking for January 1st.
  var januaryFirstMidnight = ZoneYearOffset(TransitionMode.utc, 1, 2, 0, true, LocalTime.midnight);
  var recurrence = ZoneRecurrence('bob', Offset.zero, januaryFirstMidnight, 1970, 1972);
  Transition? actual = recurrence.previousOrSame(TimeConstants.unixEpoch, Offset.zero, Offset.zero);
  Transition? expected;
  expect(expected, actual);
}

@Test()
void PreviousOrSame_BeforeFirstYear_null()
{
  var januaryFirstMidnight = ZoneYearOffset(TransitionMode.utc, 1, 1, 0, true, LocalTime.midnight);
  var recurrence = ZoneRecurrence('bob', Offset.zero, januaryFirstMidnight, 1970, 1972);
  Transition? actual = recurrence.previousOrSame(TimeConstants.unixEpoch - Time.epsilon, Offset.zero, Offset.zero);
  Transition? expected;
  expect(expected, actual);
}

@Test()
void Next_ExcludesGivenInstant()
{
  var january10thMidnight = ZoneYearOffset(TransitionMode.utc, 1, 10, 0, true, LocalTime.midnight);
  var recurrence = ZoneRecurrence('x', Offset.zero, january10thMidnight, 2000, 3000);
  var transition = Instant.utc(2500, 1, 10, 0, 0);
  var next = recurrence.next(transition, Offset.zero, Offset.zero)!;
  expect(2501, next.instant.inUtc().year);
}

@Test()
void PreviousOrSame_IncludesGivenInstant()
{
  var january10thMidnight = ZoneYearOffset(TransitionMode.utc, 1, 10, 0, true, LocalTime.midnight);
  var recurrence = ZoneRecurrence('x', Offset.zero, january10thMidnight, 2000, 3000);
  var transition = Instant.utc(2500, 1, 10, 0, 0);
  var next = recurrence.previousOrSame(transition, Offset.zero, Offset.zero)!;
  expect(transition, next.instant);
}

@Test()
void NextOrFail_Fail()
{
  var afterRecurrenceEnd = Instant.utc(1980, 1, 1, 0, 0);
  var januaryFirstMidnight = ZoneYearOffset(TransitionMode.utc, 1, 1, 0, true, LocalTime.midnight);
  var recurrence = ZoneRecurrence('bob', Offset.zero, januaryFirstMidnight, 1970, 1972);
  expect(() => recurrence.nextOrFail(afterRecurrenceEnd, Offset.zero, Offset.zero), throwsStateError);
}

@Test()
void PreviousOrSameOrFail_Fail()
{
  var beforeRecurrenceStart = Instant.utc(1960, 1, 1, 0, 0);
  var januaryFirstMidnight = ZoneYearOffset(TransitionMode.utc, 1, 1, 0, true, LocalTime.midnight);
  var recurrence = ZoneRecurrence('bob', Offset.zero, januaryFirstMidnight, 1970, 1972);
  expect(() => recurrence.previousOrSameOrFail(beforeRecurrenceStart, Offset.zero, Offset.zero), throwsStateError);
}

/* todo: serialization equivalent
@Test()
void Serialization()
{
  var dio = DtzIoHelper.CreateNoStringPool();
  var yearOffset = new ZoneYearOffset(TransitionMode.utc, 10, 31, IsoDayOfWeek.wednesday.value, true, LocalTime.Midnight);
  var expected = new ZoneRecurrence('bob', Offset.zero, yearOffset, 1971, 2009);
  dio.TestZoneRecurrence(expected);
}

@Test()
void Serialization_Infinite()
{
  var dio = DtzIoHelper.CreateNoStringPool();
  var yearOffset = new ZoneYearOffset(TransitionMode.utc, 10, 31, IsoDayOfWeek.wednesday.value, true, LocalTime.Midnight);
  var expected = new ZoneRecurrence('bob', Offset.zero, yearOffset, Utility.int32MinValue, Utility.int32MaxValue);
  dio.TestZoneRecurrence(expected);
}*/

@Test()
void IEquatable_Tests()
{
  var yearOffset = ZoneYearOffset(TransitionMode.utc, 10, 31, DayOfWeek.wednesday.value, true, LocalTime.midnight);

  var value = ZoneRecurrence('bob', Offset.zero, yearOffset, 1971, 2009);
  var equalValue = ZoneRecurrence('bob', Offset.zero, yearOffset, 1971, 2009);
  var unequalValue = ZoneRecurrence('foo', Offset.zero, yearOffset, 1971, 2009);

  TestHelper.TestEqualsClass(value, equalValue, [unequalValue]);
}

@Test()
void December31st2400_MaxYear_UtcTransition()
{
  // Each year, the transition is at the midnight at the *end* of December 31st...
  var yearOffset = ZoneYearOffset(TransitionMode.utc, 12, 31, 0, true, LocalTime.midnight, true);
  // ... and the recurrence is valid for the whole of time
  var recurrence = ZoneRecurrence('awkward', Offset.hours(1), yearOffset, GregorianYearMonthDayCalculator.minGregorianYear, GregorianYearMonthDayCalculator.maxGregorianYear);

  var next = recurrence.next(Instant.utc(9999, 6, 1, 0, 0), Offset.zero, Offset.zero)!;
  expect(IInstant.afterMaxValue, next.instant);
}

@Test()
void December31st2400_AskAtNanoBeforeLastTransition()
{
  // The transition occurs after the end of the maximum
  // Each year, the transition is at the midnight at the *end* of December 31st...
  var yearOffset = ZoneYearOffset(TransitionMode.utc, 12, 31, 0, true, LocalTime.midnight, true);
  // ... and the recurrence is valid for the whole of time
  var recurrence = ZoneRecurrence('awkward', Offset.hours(1), yearOffset, 1, 5000);

  // We can find the final transition
  var finalTransition = Instant.utc(5001, 1, 1, 0, 0);
  var next = recurrence.next(finalTransition - Time.epsilon, Offset.zero, Offset.zero);
  Transition expected = Transition(finalTransition, Offset.hours(1));
  expect(expected, next);

  // But we correctly reject anything after that
  expect(recurrence.next(finalTransition, Offset.zero, Offset.zero),  isNull);
}

@Test()
void WithName()
{
  var yearOffset = ZoneYearOffset(TransitionMode.utc, 10, 31, DayOfWeek.wednesday.value, true, LocalTime.midnight);
  var original = ZoneRecurrence('original', Offset.hours(1), yearOffset, 1900, 2000);
  var renamed = original.withName('renamed');
  expect('renamed', renamed.name);
  expect(original.savings, renamed.savings);
  expect(original.yearOffset, renamed.yearOffset);
  expect(original.fromYear, renamed.fromYear);
  expect(original.toYear, renamed.toYear);
}

@Test()
void ForSingleYear()
{
  var yearOffset = ZoneYearOffset(TransitionMode.utc, 10, 31, DayOfWeek.wednesday.value, true, LocalTime.midnight);
  var original = ZoneRecurrence('original', Offset.hours(1), yearOffset, 1900, 2000);
  var singleYear = original.forSingleYear(2017);
  expect(original.name, singleYear.name);
  expect(original.savings, singleYear.savings);
  expect(original.yearOffset, singleYear.yearOffset);
  expect(2017, singleYear.fromYear);
  expect(2017, singleYear.toYear);
}

@Test()
void ZoneRecurrenceToString()
{
  var yearOffset = ZoneYearOffset(TransitionMode.utc, 10, 31, DayOfWeek.wednesday.value, true, LocalTime.midnight);
  var recurrence = ZoneRecurrence('name', Offset.hours(1), yearOffset, 1900, 2000);
  print(recurrence.toString());
  expect(recurrence.toString(),
      'name +01 ZoneYearOffset[mode:Utc monthOfYear:10 dayOfMonth:31 dayOfWeek:3 advance:true timeOfDay:00:00:00 addDay:false] [1900-2000]');
}

