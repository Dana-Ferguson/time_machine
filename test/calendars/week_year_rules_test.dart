// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/Calendars/WeekYearRulesTest.cs
// cae7975  on Aug 24, 2017

import 'dart:async';
import 'dart:math' as math;

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import '../time_machine_testing.dart';

Future main() async {
  await runTests();
}

@Test()
void UnsupportedCalendarWeekRule()
{
  // This rule doesn't work in Dart since we can't create an arbitrary enum.
  // expect(() => WeekYearRules.FromCalendarWeekRule(CalendarWeekRule.FirstDay + 1000, DayOfWeek.Monday), throwsArgumentError);
  // expect(() => WeekYearRules.FromCalendarWeekRule(CalendarWeekRule.FirstDay, IsoDayOfWeek.monday), throwsArgumentError);
}
