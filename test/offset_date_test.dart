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
void LocalDateProperties()
{
// todo: determine equivalent of this test
//  LocalDate local = new LocalDate.forCalendar(2012, 6, 19, CalendarSystem.Julian);
//  Offset offset = new Offset.fromHours(5);
//
//  OffsetDate od = new OffsetDate(local, offset);
//
//  var localDateProperties = typeof(LocalDate).GetTypeInfo()
//      .DeclaredProperties
//      .ToDictionary(p => p.Name);
//  var commonProperties = typeof(OffsetDate).GetTypeInfo()
//      .DeclaredProperties
//      .Where(p => localDateProperties.ContainsKey(p.Name));
//for (var property in commonProperties)
//  {
//  expect(localDateProperties[property.Name].GetValue(local, null),
//  property.GetValue(od, null));
//  }
}

@Test()
void ComponentProperties()
{
  var date = LocalDate(2012, 1, 2);
  var offset = Offset.hours(5);

  var offsetDate = OffsetDate(date, offset);
  expect(offset, offsetDate.offset);
  expect(date, offsetDate.calendarDate);
}

@Test()
void Equality()
{
  LocalDate date1 = LocalDate(2012, 10, 6);
  LocalDate date2 = LocalDate(2012, 9, 5);
  Offset offset1 = Offset.hours(1);
  Offset offset2 = Offset.hours(2);

  OffsetDate equal1 = OffsetDate(date1, offset1);
  OffsetDate equal2 = OffsetDate(date1, offset1);
  OffsetDate unequalByOffset = OffsetDate(date1, offset2);
  OffsetDate unequalByLocal = OffsetDate(date2, offset1);

  TestHelper.TestEqualsStruct(equal1, equal2, [unequalByOffset]);
  TestHelper.TestEqualsStruct(equal1, equal2, [unequalByLocal]);

  TestHelper.TestOperatorEquality(equal1, equal2, unequalByOffset);
  TestHelper.TestOperatorEquality(equal1, equal2, unequalByLocal);
}

@Test()
void At()
{
  var date = LocalDate(2012, 6, 19, CalendarSystem.julian);
  var offset = Offset.hours(5);
  var time = LocalTime(14, 15, 12).addNanoseconds(123456789);

  expect(OffsetDate(date, offset).at(time), date.at(time).withOffset(offset));
}

@Test()
void WithOffset()
{
  var date = LocalDate(2012, 6, 19);
  var initial = OffsetDate(date, Offset.hours(2));
  var actual = initial.withOffset(Offset.hours(5));
  var expected = OffsetDate(date, Offset.hours(5));
  expect(expected, actual);
}

@Test()
void WithCalendar()
{
  var julianDate = LocalDate(2012, 6, 19, CalendarSystem.julian);
  var isoDate = julianDate.withCalendar(CalendarSystem.iso);
  var offset = Offset.hours(5);
  var actual = OffsetDate(julianDate, offset).withCalendar(CalendarSystem.iso);
  var expected = OffsetDate(isoDate, offset);
  expect(expected, actual);
}

@Test()
void WithAdjuster()
{
  var initial = OffsetDate(LocalDate(2016, 6, 19), Offset.hours(-5));
  var actual = initial.adjust(DateAdjusters.startOfMonth);
  var expected = OffsetDate(LocalDate(2016, 6, 1), Offset.hours(-5));
  expect(expected, actual);
}

// todo: determine CLDR toString equivalents (whatever that means)
/*
@Test()
void ToString_WithFormat()
{
  LocalDate date = new LocalDate(2012, 10, 6);
  Offset offset = new Offset.fromHours(1);
  OffsetDate offsetDate = new OffsetDate(date, offset);
  expect('2012/10/06 01', offsetDate.toString("yyyy/MM/dd o<-HH>", Culture.invariantCulture));
}

@Test()
void ToString_WithNullFormat()
{
  LocalDate date = new LocalDate(2012, 10, 6);
  Offset offset = new Offset.fromHours(1);
  OffsetDate offsetDate = new OffsetDate(date, offset);
  expect('2012-10-06+01', offsetDate.toString(null, Culture.invariantCulture));
}

@Test()
void ToString_NoFormat()
{
  LocalDate date = new LocalDate(2012, 10, 6);
  Offset offset = new Offset.fromHours(1);
  OffsetDate offsetDate = new OffsetDate(date, offset);
  using (CultureSaver.SetCultures(Culture.invariantCulture))
  {
    expect('2012-10-06+01', offsetDate.toString());
  }
}

*/

