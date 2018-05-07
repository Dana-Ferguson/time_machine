// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/PeriodBuilderTest.cs
// cae7975  on Aug 24, 2017

import 'dart:async';
import 'dart:math' as math;

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

@Test()
void Indexer_Getter_ValidUnits() {
  var builder = new PeriodBuilder()
    ..Months = 1
    ..Weeks = 2
    ..Days = 3
    ..Hours = 4
    ..Minutes = 5
    ..Seconds = 6
    ..Milliseconds = 7
    ..Ticks = 8
    ..Nanoseconds = 9;

  expect(0, builder[PeriodUnits.years]);
  expect(1, builder[PeriodUnits.months]);
  expect(2, builder[PeriodUnits.weeks]);
  expect(3, builder[PeriodUnits.days]);
  expect(4, builder[PeriodUnits.hours]);
  expect(5, builder[PeriodUnits.minutes]);
  expect(6, builder[PeriodUnits.seconds]);
  expect(7, builder[PeriodUnits.milliseconds]);
  expect(8, builder[PeriodUnits.ticks]);
  expect(9, builder[PeriodUnits.nanoseconds]);
}

void Call(Object ignored) {}

@Test()
void Index_Getter_InvalidUnits()
{
  var builder = new PeriodBuilder();
  expect(() => Call(builder[new PeriodUnits(0)]), throwsArgumentError);
  expect(() => Call(builder[new PeriodUnits(-1)]), throwsArgumentError);
  expect(() => Call(builder[PeriodUnits.dateAndTime]), throwsArgumentError);
}

@Test()
void Indexer_Setter_ValidUnits() {
  var builder = new PeriodBuilder();
  builder[PeriodUnits.months] = 1;
  builder[PeriodUnits.weeks] = 2;
  builder[PeriodUnits.days] = 3;
  builder[PeriodUnits.hours] = 4;
  builder[PeriodUnits.minutes] = 5;
  builder[PeriodUnits.seconds] = 6;
  builder[PeriodUnits.milliseconds] = 7;
  builder[PeriodUnits.ticks] = 8;
  var expectedBuilder = new PeriodBuilder()
    ..Years = 0
    ..Months = 1
    ..Weeks = 2
    ..Days = 3
    ..Hours = 4
    ..Minutes = 5
    ..Seconds = 6
    ..Milliseconds = 7
    ..Ticks = 8;

  var expected = expectedBuilder.Build();
  expect(expected, builder.Build());
}

@Test()
void Index_Setter_InvalidUnits()
{
  var builder = new PeriodBuilder();
  expect(() => builder[new PeriodUnits(0)] = 1, throwsArgumentError);
  expect(() => builder[new PeriodUnits(-1)] = 1, throwsArgumentError);
  expect(() => builder[PeriodUnits.dateAndTime] = 1, throwsArgumentError);
}

@Test()
void Build_SingleUnit() {
  Period period = (new PeriodBuilder()
    ..Hours = 10).Build();
  Period expected = new Period.fromHours(10);
  expect(expected, period);
}

@Test()
void Build_MultipleUnits() {
  Period period = (new PeriodBuilder()
    ..Days = 5
    ..Minutes = -10).Build();
  Period expected = new Period.fromDays(5) + new Period.fromMinutes(-10);
  expect(expected, period);
}

@Test()
void Build_Zero()
{
  expect(Period.Zero, new PeriodBuilder().Build());
}
