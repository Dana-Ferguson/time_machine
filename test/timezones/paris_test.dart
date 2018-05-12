// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/TimeZones/ParisTest.cs
// 8d5399d  on Feb 26, 2016

import 'dart:async';
import 'dart:math' as math;

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import '../time_machine_testing.dart';

DateTimeZone Paris;
IDateTimeZoneProvider Tzdb;

// Until 1911, Paris was 9 minutes and 21 seconds off UTC.
Offset InitialOffset = TestObjects.CreatePositiveOffset(0, 9, 21);

/// Tests for the Paris time zone. This exercises functionality within various classes.
/// Paris varies between +1 (standard) and +2 (DST); transitions occur at 2am or 3am wall time,
/// which is always 1am UTC.
/// 2009 fall transition: October 25th
/// 2010 spring transition: March 28th
/// 2010 fall transition: October 31st
/// 2011 spring transition: March 27th
Future main() async {
  Tzdb = await DateTimeZoneProviders.Tzdb;
  // Make sure we deal with the uncached time zone
  Paris = Uncached(await Tzdb["Europe/Paris"]);

  await runTests();
}

@Test()
void FirstTransitions()
{
  // Paris had a name change in 1891, and then moved from +0:09:21 to UTC in 1911
  var nameChangeInstant = new Instant.fromUtc(1891, 3, 14, 23, 51, 39);
  var utcChangeInstant = new Instant.fromUtc(1911, 3, 10, 23, 51, 39);

  var beforeNameChange = Paris.GetZoneInterval(nameChangeInstant - Span.epsilon);
  var afterNameChange = Paris.GetZoneInterval(nameChangeInstant);
  var afterSmallChange = Paris.GetZoneInterval(utcChangeInstant);

  expect("LMT", beforeNameChange.name);
  expect(InitialOffset, beforeNameChange.wallOffset);

  expect("PMT", afterNameChange.name);
  expect(InitialOffset, afterNameChange.wallOffset);

  expect("WET", afterSmallChange.name);
  expect(Offset.zero, afterSmallChange.wallOffset);
}
