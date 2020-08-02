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
void JulianEpoch()
{
  // Compute the Julian epoch using the Julian calendar, instead of the
  // Gregorian version.
  var localEpoch = LocalDateTime(-4712, 1, 1, 12, 0, 0, calendar: CalendarSystem.julian);
  var epoch = localEpoch.inZoneStrictly(DateTimeZone.utc).toInstant();
  expect(epoch, TimeConstants.julianEpoch);
}

//@Test()
//void BclTicksAtEpoch()
//{
//  expect(
//      new DateTime.utc(1970, 1, 1, 0, 0, 0).millisecondsSinceEpoch,
//      TimeConstants.BclTicksAtUnixEpoch ~/ TimeConstants.ticksPerMillisecond);
//}
//
//@Test()
//void BclDaysAtEpoch()
//{
//  expect(
//      new DateTime.utc(1970, 1, 1, 0, 0, 0).millisecondsSinceEpoch,
//      TimeConstants.millisecondsPerDay * TimeConstants.BclDaysAtUnixEpoch);
//}

