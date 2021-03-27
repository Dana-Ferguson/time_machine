// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
// import 'package:matcher/matcher.dart';

import 'time_machine_testing.dart';

Future main() async {
  await TimeMachine.initialize();
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
  var time = LocalTime(12, 34, 15);
  var offset = Offset.hours(5);

  var offsetDate = OffsetTime(time, offset);
  expect(offset, offsetDate.offset);
  expect(time, offsetDate.clockTime);
}

@Test()
void Equality()
{
  LocalTime time1 = LocalTime(4, 56, 23, ms: 123);
  LocalTime time2 = LocalTime(6, 23, 12, ms: 987);
  Offset offset1 = Offset.hours(1);
  Offset offset2 = Offset.hours(2);

  OffsetTime equal1 = OffsetTime(time1, offset1);
  OffsetTime equal2 = OffsetTime(time1, offset1);
  OffsetTime unequalByOffset = OffsetTime(time1, offset2);
  OffsetTime unequalByLocal = OffsetTime(time2, offset1);

  TestHelper.TestEqualsStruct(equal1, equal2, [unequalByOffset]);
  TestHelper.TestEqualsStruct(equal1, equal2, [unequalByLocal]);

  TestHelper.TestOperatorEquality(equal1, equal2, unequalByOffset);
  TestHelper.TestOperatorEquality(equal1, equal2, unequalByLocal);
}

@Test()
void On()
{
  var time = LocalTime(14, 15, 12).addNanoseconds(123456789);
  var date = LocalDate(2012, 6, 19, CalendarSystem.julian);
  var offset = Offset.hours(5);

  expect(OffsetTime(time, offset).atDate(date), time.atDate(date).withOffset(offset));
}

@Test()
void WithOffset()
{
  var time = LocalTime(14, 15, 12).addNanoseconds(123456789);
  var initial = OffsetTime(time, Offset.hours(2));
  var actual = initial.withOffset(Offset.hours(5));
  var expected = OffsetTime(time, Offset.hours(5));
  expect(expected, actual);
}

@Test()
void WithAdjuster()
{
  var initial = OffsetTime(LocalTime(14, 15, 12), Offset.hours(-5));
  var actual = initial.adjust(TimeAdjusters.truncateToHour);
  var expected = OffsetTime(LocalTime(14, 0, 0), Offset.hours(-5));
  expect(expected, actual);
}

@Test()
void ToString_WithFormat()
{
  LocalTime time = LocalTime(14, 15, 12, ms: 123);
  Offset offset = Offset.hours(1);
  OffsetTime offsetDate = OffsetTime(time, offset);
  expect(offsetDate.toString('HH:mm:ss.fff o<-HH>', Culture.invariant), "14:15:12.123 01");
}

@Test()
void ToString_WithNullFormat()
{
  LocalTime time = LocalTime(14, 15, 12, ms: 123);
  Offset offset = Offset.hours(1);
  OffsetTime offsetDate = OffsetTime(time, offset);
  expect(offsetDate.toString(null, Culture.invariant), '14:15:12+01');
}

@Test()
void ToString_NoFormat() {
  LocalTime time = LocalTime(14, 15, 12, ms: 123);
  Offset offset = Offset.hours(1);
  OffsetTime offsetDate = OffsetTime(time, offset);

  //using(CultureSaver.SetCultures(Culture.invariantCulture))
  ICultures.currentCulture = Cultures.invariantCulture;
  {
    expect(offsetDate.toString(), '14:15:12+01');
  }
}

