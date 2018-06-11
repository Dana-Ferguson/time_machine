// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

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
  var date = new LocalDate(2012, 1, 2);
  var offset = new Offset.fromHours(5);

  var offsetDate = new OffsetDate(date, offset);
  expect(offset, offsetDate.offset);
  expect(date, offsetDate.date);
}

@Test()
void Equality()
{
  LocalDate date1 = new LocalDate(2012, 10, 6);
  LocalDate date2 = new LocalDate(2012, 9, 5);
  Offset offset1 = new Offset.fromHours(1);
  Offset offset2 = new Offset.fromHours(2);

  OffsetDate equal1 = new OffsetDate(date1, offset1);
  OffsetDate equal2 = new OffsetDate(date1, offset1);
  OffsetDate unequalByOffset = new OffsetDate(date1, offset2);
  OffsetDate unequalByLocal = new OffsetDate(date2, offset1);

  TestHelper.TestEqualsStruct(equal1, equal2, [unequalByOffset]);
  TestHelper.TestEqualsStruct(equal1, equal2, [unequalByLocal]);

  TestHelper.TestOperatorEquality(equal1, equal2, unequalByOffset);
  TestHelper.TestOperatorEquality(equal1, equal2, unequalByLocal);
}

@Test()
void At()
{
  var date = new LocalDate(2012, 6, 19, CalendarSystem.julian);
  var offset = new Offset.fromHours(5);
  var time = new LocalTime(14, 15, 12).plusNanoseconds(123456789);

  expect(new OffsetDate(date, offset).At(time), date.at(time).withOffset(offset));
}

@Test()
void WithOffset()
{
  var date = new LocalDate(2012, 6, 19);
  var initial = new OffsetDate(date, new Offset.fromHours(2));
  var actual = initial.withOffset(new Offset.fromHours(5));
  var expected = new OffsetDate(date, new Offset.fromHours(5));
  expect(expected, actual);
}

@Test()
void WithCalendar()
{
  var julianDate = new LocalDate(2012, 6, 19, CalendarSystem.julian);
  var isoDate = julianDate.withCalendar(CalendarSystem.iso);
  var offset = new Offset.fromHours(5);
  var actual = new OffsetDate(julianDate, offset).WithCalendar(CalendarSystem.iso);
  var expected = new OffsetDate(isoDate, offset);
  expect(expected, actual);
}

@Test()
void WithAdjuster()
{
  var initial = new OffsetDate(new LocalDate(2016, 6, 19), new Offset.fromHours(-5));
  var actual = initial.With(DateAdjusters.startOfMonth);
  var expected = new OffsetDate(new LocalDate(2016, 6, 1), new Offset.fromHours(-5));
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
  expect("2012/10/06 01", offsetDate.toString("yyyy/MM/dd o<-HH>", CultureInfo.InvariantCulture));
}

@Test()
void ToString_WithNullFormat()
{
  LocalDate date = new LocalDate(2012, 10, 6);
  Offset offset = new Offset.fromHours(1);
  OffsetDate offsetDate = new OffsetDate(date, offset);
  expect("2012-10-06+01", offsetDate.toString(null, CultureInfo.InvariantCulture));
}

@Test()
void ToString_NoFormat()
{
  LocalDate date = new LocalDate(2012, 10, 6);
  Offset offset = new Offset.fromHours(1);
  OffsetDate offsetDate = new OffsetDate(date, offset);
  using (CultureSaver.SetCultures(CultureInfo.InvariantCulture))
  {
    expect("2012-10-06+01", offsetDate.toString());
  }
}

*/

