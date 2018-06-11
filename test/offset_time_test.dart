// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:math' as math;

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_timezones.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

@Test()
void LocalTimeProperties() {
  /* // todo: equivalent?
  LocalTime local = new LocalTime(5, 23, 45).PlusNanoseconds(987654321);
  Offset offset = new Offset.fromHours(5);

  OffsetTime od = new OffsetTime(local, offset);

  var localTimeProperties = typeof(LocalTime)
      .GetTypeInfo()
      .DeclaredProperties
      .ToDictionary((p) => p.Name);
  var commonProperties = typeof(OffsetTime)
      .GetTypeInfo()
      .DeclaredProperties
      .Where((p) => localTimeProperties.ContainsKey(p.Name));
  for (var property in commonProperties) {
    expect(localTimeProperties[property.Name].GetValue(local, null),
        property.GetValue(od, null));
  }*/
}


@Test()
void ComponentProperties()
{
  var time = new LocalTime(12, 34, 15);
  var offset = new Offset.fromHours(5);

  var offsetDate = new OffsetTime(time, offset);
  expect(offset, offsetDate.offset);
  expect(time, offsetDate.TimeOfDay);
}

@Test()
void Equality()
{
  LocalTime time1 = new LocalTime(4, 56, 23, 123);
  LocalTime time2 = new LocalTime(6, 23, 12, 987);
  Offset offset1 = new Offset.fromHours(1);
  Offset offset2 = new Offset.fromHours(2);

  OffsetTime equal1 = new OffsetTime(time1, offset1);
  OffsetTime equal2 = new OffsetTime(time1, offset1);
  OffsetTime unequalByOffset = new OffsetTime(time1, offset2);
  OffsetTime unequalByLocal = new OffsetTime(time2, offset1);

  TestHelper.TestEqualsStruct(equal1, equal2, [unequalByOffset]);
  TestHelper.TestEqualsStruct(equal1, equal2, [unequalByLocal]);

  TestHelper.TestOperatorEquality(equal1, equal2, unequalByOffset);
  TestHelper.TestOperatorEquality(equal1, equal2, unequalByLocal);
}

@Test()
void On()
{
  var time = new LocalTime(14, 15, 12).PlusNanoseconds(123456789);
  var date = new LocalDate(2012, 6, 19, CalendarSystem.Julian);
  var offset = new Offset.fromHours(5);

  expect(new OffsetTime(time, offset).On(date), time.On(date).WithOffset(offset));
}

@Test()
void WithOffset()
{
  var time = new LocalTime(14, 15, 12).PlusNanoseconds(123456789);
  var initial = new OffsetTime(time, new Offset.fromHours(2));
  var actual = initial.WithOffset(new Offset.fromHours(5));
  var expected = new OffsetTime(time, new Offset.fromHours(5));
  expect(expected, actual);
}

@Test()
void WithAdjuster()
{
  var initial = new OffsetTime(new LocalTime(14, 15, 12), new Offset.fromHours(-5));
  var actual = initial.With(TimeAdjusters.TruncateToHour);
  var expected = new OffsetTime(new LocalTime(14, 0), new Offset.fromHours(-5));
  expect(expected, actual);
}

@Test()
void ToString_WithFormat()
{
  LocalTime time = new LocalTime(14, 15, 12, 123);
  Offset offset = new Offset.fromHours(1);
  OffsetTime offsetDate = new OffsetTime(time, offset);
  expect(offsetDate.toString("HH:mm:ss.fff o<-HH>", CultureInfo.invariantCulture), "14:15:12.123 01");
}

@Test()
void ToString_WithNullFormat()
{
  LocalTime time = new LocalTime(14, 15, 12, 123);
  Offset offset = new Offset.fromHours(1);
  OffsetTime offsetDate = new OffsetTime(time, offset);
  expect(offsetDate.toString(null, CultureInfo.invariantCulture), "14:15:12+01");
}

@Test() @SkipMe("Investigate CultureSaver")
void ToString_NoFormat() {
  LocalTime time = new LocalTime(14, 15, 12, 123);
  Offset offset = new Offset.fromHours(1);
  OffsetTime offsetDate = new OffsetTime(time, offset);

  //using(CultureSaver.SetCultures(CultureInfo.InvariantCulture))
  {
    expect(offsetDate.toString(), "14:15:12+01");
  }
}

