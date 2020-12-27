// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

import '../time_machine_testing.dart';

late DateTimeZoneProvider tzdb;

/// Tests for fixed 'Etc/GMT+x' zones. These just test that the time zones are built
/// appropriately; FixedDateTimeZoneTest takes care of the rest.
Future main() async {
  await TimeMachine.initialize();
  tzdb = await DateTimeZoneProviders.tzdb;

  await runTests();
}

Offset ZoneOffset = Offset.hours(-8);
FixedDateTimeZone TestZone = FixedDateTimeZone.forOffset(ZoneOffset);
ZoneInterval FixedPeriod = IZoneInterval.newZoneInterval(TestZone.id, IInstant.beforeMinValue, IInstant.afterMaxValue, ZoneOffset, Offset.zero);

@Test()
void IsFixed_ReturnsTrue()
{
  expect(IDateTimeZone.isFixed(TestZone), isTrue);
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
  expect(TestZone.id, 'UTC-08', reason: "TestZone.id");
  expect(TestZone.getZoneInterval(TimeConstants.unixEpoch).name, 'UTC-08');
  expect(TestZone.getUtcOffset(TimeConstants.unixEpoch), ZoneOffset);
  expect(TestZone.minOffset, ZoneOffset);
  expect(TestZone.maxOffset, ZoneOffset);
}

@Test()
void GetZoneIntervals_ReturnsSingleInterval()
{
  var mapping = TestZone.mapLocal(LocalDateTime(2001, 7, 1, 1, 0, 0));
  expect(FixedPeriod, mapping.earlyInterval);
  expect(FixedPeriod, mapping.lateInterval);
  expect(1, mapping.count);
}

@Test()
void For_Id_FixedOffset()
{
  String id = 'UTC+05:30';
  DateTimeZone zone = FixedDateTimeZone.getFixedZoneOrNull(id)!;
  expect(DateTimeZone.forOffset(Offset.hoursAndMinutes(5, 30)), zone);
  expect(id, zone.id);
}

@Test()
void For_Id_FixedOffset_NonCanonicalId()
{
  String id = 'UTC+05:00:00';
  DateTimeZone zone = FixedDateTimeZone.getFixedZoneOrNull(id)!;
  expect(zone, DateTimeZone.forOffset(Offset.hours(5)));
  expect('UTC+05', zone.id);
}

@Test()
void For_Id_InvalidFixedOffset()
{
  expect(FixedDateTimeZone.getFixedZoneOrNull('UTC+5Months'), isNull);
}

@Test()
void ExplicitNameAppearsInZoneInterval()
{
  var zone = FixedDateTimeZone('id', Offset.hours(5), "name");
  var interval = zone.getZoneInterval(TimeConstants.unixEpoch);
  expect('id', zone.id); // Check we don't get this wrong...
  expect('name', interval.name);
  expect('name', zone.name);
}

@Test()
void ZoneIntervalNameDefaultsToZoneId()
{
  var zone = FixedDateTimeZone.forIdOffset('id', Offset.hours(5));
  var interval = zone.getZoneInterval(TimeConstants.unixEpoch);
  expect('id', interval.name);
  expect('id', zone.name);
}

@Test() @SkipMe.unimplemented()
void Read_NoNameInStream()
{
  // var ioHelper = DtzIoHelper.CreateNoStringPool();
  dynamic ioHelper;
  var offset = Offset.hours(5);
  ioHelper.Writer.WriteOffset(offset);
  var zone = FixedDateTimeZone.read(ioHelper.Reader, 'id') as FixedDateTimeZone;

  expect('id', zone.id);
  expect(offset, zone.offset);
  expect('id', zone.name);
}

@Test() @SkipMe.unimplemented()
void Read_WithNameInStream()
{
  // var ioHelper = DtzIoHelper.CreateNoStringPool();
  dynamic ioHelper;
  var offset = Offset.hours(5);
  ioHelper.Writer.WriteOffset(offset);
  ioHelper.Writer.WriteString('name');
  var zone = FixedDateTimeZone.read(ioHelper.Reader, 'id') as FixedDateTimeZone;

  expect('id', zone.id);
  expect(offset, zone.offset);
  expect('name', zone.name);
}

@Test() @SkipMe.unimplemented()
void Roundtrip()
{
  // var ioHelper = DtzIoHelper.CreateNoStringPool();
  dynamic ioHelper;
  var oldZone = FixedDateTimeZone('id', Offset.hours(4), "name");
  oldZone.write(ioHelper.Writer);
  var newZone = FixedDateTimeZone.read(ioHelper.Reader, 'id') as FixedDateTimeZone;

  expect(oldZone.id, newZone.id);
  expect(oldZone.offset, newZone.offset);
  expect(oldZone.name, newZone.name);
}

@Test()
void Equals()
{
  TestHelper.TestEqualsClass(FixedDateTimeZone.forOffset(Offset(300)),
      FixedDateTimeZone.forOffset(Offset(300)),
      [FixedDateTimeZone.forOffset(Offset(500))]);

  TestHelper.TestEqualsClass(FixedDateTimeZone.forIdOffset('Foo', Offset(300)),
      FixedDateTimeZone.forIdOffset('Foo', Offset(300)),
      [FixedDateTimeZone.forIdOffset('Bar', Offset(300))]);
}

