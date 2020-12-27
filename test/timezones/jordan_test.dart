// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

import '../time_machine_testing.dart';

late DateTimeZoneProvider tzdb;
late DateTimeZone jordan;

/// As of 2002, Jordan switches to DST at the *end* of the last Thursday of March.
/// This is denoted in the zoneinfo database using lastThu 24:00, which was invalid
/// in our parser.
Future main() async {
  await TimeMachine.initialize();
  await setup();

  await runTests();
}

Future setup() async {
  tzdb = await DateTimeZoneProviders.tzdb;
  jordan = await tzdb['Asia/Amman'];
}

/// If all of these transitions are right, we're probably okay... in particular,
/// checking the 2005 transition occurs on the 1st of April is important.
@Test()
void Transitions2000To2010() {
  // These were fetched with Joda Time 1.6.2, which definitely uses the new rules.
  var expectedDates = [
    LocalDate(2000, 3, 30), // Thursday morning
    LocalDate(2001, 3, 29), // Thursday morning
    LocalDate(2002, 3, 29), // Friday morning from here onwards
    LocalDate(2003, 3, 28),
    LocalDate(2004, 3, 26),
    LocalDate(2005, 4, 1),
    LocalDate(2006, 3, 31),
    LocalDate(2007, 3, 30),
    LocalDate(2008, 3, 28),
    LocalDate(2009, 3, 27),
    LocalDate(2010, 3, 26)
  ];

  for (int year = 2000; year <= 2010; year++) {
    LocalDate summer = LocalDate(year, 6, 1);
    var intervalPair = jordan.mapLocal(summer.atMidnight());
    expect(1, intervalPair.count);
    expect(expectedDates[year - 2000], intervalPair.earlyInterval.isoLocalStart.calendarDate);
  }
}

