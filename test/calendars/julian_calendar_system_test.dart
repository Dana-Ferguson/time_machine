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

CalendarSystem Julian = CalendarSystem.julian;

/// The Unix epoch is equivalent to December 19th 1969 in the Julian calendar.
@Test()
void Epoch()
{
  LocalDateTime julianEpoch = TimeConstants.unixEpoch.inZone(DateTimeZone.utc, Julian).localDateTime;
  expect(1969, julianEpoch.year);
  expect(12, julianEpoch.monthOfYear);
  expect(19, julianEpoch.dayOfMonth);
}

@Test()
void LeapYears()
{
  expect(Julian.isLeapYear(1900), isTrue); // No 100 year rule...
  expect(Julian.isLeapYear(1901), isFalse);
  expect(Julian.isLeapYear(1904), isTrue);
  expect(Julian.isLeapYear(2000), isTrue);
  expect(Julian.isLeapYear(2100), isTrue); // No 100 year rule...
  expect(Julian.isLeapYear(2400), isTrue);
  // Check 1BC, 5BC etc...
  expect(Julian.isLeapYear(0), isTrue);
  expect(Julian.isLeapYear(-4), isTrue);
}

