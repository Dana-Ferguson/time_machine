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

final Iterable<String> SupportedIds = CalendarSystem.ids.toList();
final List<CalendarSystem> SupportedCalendars = SupportedIds.map(CalendarSystem.forId).toList();

@Test()
@TestCaseSource(Symbol('SupportedCalendars'))
void MaxDate(CalendarSystem calendar)
{
  // Construct the largest LocalDate we can, and validate that all the properties can be fetched without
  // issues.
  ValidateProperties(calendar, ICalendarSystem.maxDays(calendar), calendar.maxYear);
}

@Test()
@TestCaseSource(Symbol('SupportedCalendars'))
void MinDate(CalendarSystem calendar)
{
  // Construct the smallest LocalDate we can, and validate that all the properties can be fetched without
  // issues.
  ValidateProperties(calendar, ICalendarSystem.minDays(calendar), calendar.minYear);
}

void ValidateProperties(CalendarSystem calendar, int daysSinceEpoch, int expectedYear)
{
  var localDate = LocalDate.fromEpochDay(daysSinceEpoch, calendar);
  expect(localDate.year, expectedYear);

// todo: investigate test and replicate
//  for (var property in typeof(LocalDate).GetTypeInfo().DeclaredProperties)
//  {
//    property.GetValue(localDate, null);
//  }
}
