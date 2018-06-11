// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
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

final Iterable<String> SupportedIds = CalendarSystem.Ids.toList();
final List<CalendarSystem> SupportedCalendars = SupportedIds.map(CalendarSystem.ForId).toList();

@Test()
@TestCaseSource(const Symbol('SupportedCalendars'))
void MaxDate(CalendarSystem calendar)
{
  // Construct the largest LocalDate we can, and validate that all the properties can be fetched without
  // issues.
  ValidateProperties(calendar, calendar.maxDays, calendar.maxYear);
}

@Test()
@TestCaseSource(const Symbol('SupportedCalendars'))
void MinDate(CalendarSystem calendar)
{
  // Construct the smallest LocalDate we can, and validate that all the properties can be fetched without
  // issues.
  ValidateProperties(calendar, calendar.minDays, calendar.minYear);
}

void ValidateProperties(CalendarSystem calendar, int daysSinceEpoch, int expectedYear)
{
  var localDate = new LocalDate.fromDaysSinceEpoch(daysSinceEpoch, calendar);
  expect(localDate.year, expectedYear);

// todo: investigate test and replicate
//  for (var property in typeof(LocalDate).GetTypeInfo().DeclaredProperties)
//  {
//    property.GetValue(localDate, null);
//  }
}
