// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:math' as math;

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import '../time_machine_testing.dart';

IDateTimeZoneProvider Tzdb;

/// Tests for fixed "Etc/GMT+x" zones. These just test that the time zones are built
/// appropriately; FixedDateTimeZoneTest takes care of the rest.
Future main() async {
  Tzdb = await DateTimeZoneProviders.Tzdb;

  await runTests();
}

Offset ZoneOffset = new Offset.fromHours(-8);
FixedDateTimeZone TestZone = new FixedDateTimeZone.forOffset(ZoneOffset);
ZoneInterval FixedPeriod = new ZoneInterval(TestZone.id, Instant.beforeMinValue, Instant.afterMaxValue, ZoneOffset, Offset.zero);

@Test()
void IsFixed_ReturnsTrue()
{
  expect(TestZone.isFixed, isTrue);
}

@Test()
void GetZoneIntervalInstant_ZoneInterval()
{
  var actual = TestZone.getZoneInterval(TimeConstants.unixEpoch);
  expect(FixedPeriod, actual);
}

@Test()
void SimpleProperties_ReturnValuesFromConstructor()
{
  expect(TestZone.id, "UTC-08", reason: "TestZone.id");
  expect(TestZone.getZoneInterval(TimeConstants.unixEpoch).name, "UTC-08");
  expect(TestZone.getUtcOffset(TimeConstants.unixEpoch), ZoneOffset);
  expect(TestZone.minOffset, ZoneOffset);
  expect(TestZone.maxOffset, ZoneOffset);
}

@Test()
void GetZoneIntervals_ReturnsSingleInterval()
{
  var mapping = TestZone.mapLocal(new LocalDateTime.at(2001, 7, 1, 1, 0));
  expect(FixedPeriod, mapping.earlyInterval);
  expect(FixedPeriod, mapping.lateInterval);
  expect(1, mapping.count);
}

@Test()
void For_Id_FixedOffset()
{
  String id = "UTC+05:30";
  DateTimeZone zone = FixedDateTimeZone.getFixedZoneOrNull(id);
  expect(new DateTimeZone.forOffset(new Offset.fromHoursAndMinutes(5, 30)), zone);
  expect(id, zone.id);
}

@Test()
void For_Id_FixedOffset_NonCanonicalId()
{
  String id = "UTC+05:00:00";
  DateTimeZone zone = FixedDateTimeZone.getFixedZoneOrNull(id);
  expect(zone, new DateTimeZone.forOffset(new Offset.fromHours(5)));
  expect("UTC+05", zone.id);
}

@Test()
void For_Id_InvalidFixedOffset()
{
  expect(FixedDateTimeZone.getFixedZoneOrNull("UTC+5Months"), isNull);
}

@Test()
void ExplicitNameAppearsInZoneInterval()
{
  var zone = new FixedDateTimeZone("id", new Offset.fromHours(5), "name");
  var interval = zone.getZoneInterval(TimeConstants.unixEpoch);
  expect("id", zone.id); // Check we don't get this wrong...
  expect("name", interval.name);
  expect("name", zone.name);
}

@Test()
void ZoneIntervalNameDefaultsToZoneId()
{
  var zone = new FixedDateTimeZone.forIdOffset("id", new Offset.fromHours(5));
  var interval = zone.getZoneInterval(TimeConstants.unixEpoch);
  expect("id", interval.name);
  expect("id", zone.name);
}

@Test() @SkipMe.unimplemented()
void Read_NoNameInStream()
{
  // var ioHelper = DtzIoHelper.CreateNoStringPool();
  dynamic ioHelper = null;
  var offset = new Offset.fromHours(5);
  ioHelper.Writer.WriteOffset(offset);
  var zone = FixedDateTimeZone.read(ioHelper.Reader, "id") as FixedDateTimeZone;

  expect("id", zone.id);
  expect(offset, zone.offset);
  expect("id", zone.name);
}

@Test() @SkipMe.unimplemented()
void Read_WithNameInStream()
{
  // var ioHelper = DtzIoHelper.CreateNoStringPool();
  dynamic ioHelper = null;
  var offset = new Offset.fromHours(5);
  ioHelper.Writer.WriteOffset(offset);
  ioHelper.Writer.WriteString("name");
  var zone = FixedDateTimeZone.read(ioHelper.Reader, "id") as FixedDateTimeZone;

  expect("id", zone.id);
  expect(offset, zone.offset);
  expect("name", zone.name);
}

@Test() @SkipMe.unimplemented()
void Roundtrip()
{
  // var ioHelper = DtzIoHelper.CreateNoStringPool();
  dynamic ioHelper = null;
  var oldZone = new FixedDateTimeZone("id", new Offset.fromHours(4), "name");
  oldZone.write(ioHelper.Writer);
  var newZone = FixedDateTimeZone.read(ioHelper.Reader, "id") as FixedDateTimeZone;

  expect(oldZone.id, newZone.id);
  expect(oldZone.offset, newZone.offset);
  expect(oldZone.name, newZone.name);
}

@Test()
void Equals()
{
  TestHelper.TestEqualsClass(new FixedDateTimeZone.forOffset(new Offset.fromSeconds(300)),
      new FixedDateTimeZone.forOffset(new Offset.fromSeconds(300)),
      [new FixedDateTimeZone.forOffset(new Offset.fromSeconds(500))]);

  TestHelper.TestEqualsClass(new FixedDateTimeZone.forIdOffset("Foo", new Offset.fromSeconds(300)),
      new FixedDateTimeZone.forIdOffset("Foo", new Offset.fromSeconds(300)),
      [new FixedDateTimeZone.forIdOffset("Bar", new Offset.fromSeconds(300))]);
}

