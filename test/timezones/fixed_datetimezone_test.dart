// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/TimeZones/FixedDateTimeZoneTest.cs
// b9ee218  on Dec 22, 2016

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
  var actual = TestZone.GetZoneInterval(TimeConstants.unixEpoch);
  expect(FixedPeriod, actual);
}

@Test()
void SimpleProperties_ReturnValuesFromConstructor()
{
  expect(TestZone.id, "UTC-08", reason: "TestZone.id");
  expect(TestZone.GetZoneInterval(TimeConstants.unixEpoch).name, "UTC-08");
  expect(TestZone.GetUtcOffset(TimeConstants.unixEpoch), ZoneOffset);
  expect(TestZone.minOffset, ZoneOffset);
  expect(TestZone.maxOffset, ZoneOffset);
}

@Test()
void GetZoneIntervals_ReturnsSingleInterval()
{
  var mapping = TestZone.MapLocal(new LocalDateTime.fromYMDHMS(2001, 7, 1, 1, 0, 0));
  expect(FixedPeriod, mapping.EarlyInterval);
  expect(FixedPeriod, mapping.LateInterval);
  expect(1, mapping.Count);
}

@Test()
void For_Id_FixedOffset()
{
  String id = "UTC+05:30";
  DateTimeZone zone = FixedDateTimeZone.GetFixedZoneOrNull(id);
  expect(DateTimeZone.ForOffset(new Offset.fromHoursAndMinutes(5, 30)), zone);
  expect(id, zone.id);
}

@Test()
void For_Id_FixedOffset_NonCanonicalId()
{
  String id = "UTC+05:00:00";
  DateTimeZone zone = FixedDateTimeZone.GetFixedZoneOrNull(id);
  expect(zone, DateTimeZone.ForOffset(new Offset.fromHours(5)));
  expect("UTC+05", zone.id);
}

@Test()
void For_Id_InvalidFixedOffset()
{
  expect(FixedDateTimeZone.GetFixedZoneOrNull("UTC+5Months"), isNull);
}

@Test()
void ExplicitNameAppearsInZoneInterval()
{
  var zone = new FixedDateTimeZone("id", new Offset.fromHours(5), "name");
  var interval = zone.GetZoneInterval(TimeConstants.unixEpoch);
  expect("id", zone.id); // Check we don't get this wrong...
  expect("name", interval.name);
  expect("name", zone.Name);
}

@Test()
void ZoneIntervalNameDefaultsToZoneId()
{
  var zone = new FixedDateTimeZone.forIdOffset("id", new Offset.fromHours(5));
  var interval = zone.GetZoneInterval(TimeConstants.unixEpoch);
  expect("id", interval.name);
  expect("id", zone.Name);
}

@Test()
void Read_NoNameInStream()
{
  var ioHelper = DtzIoHelper.CreateNoStringPool();
  var offset = new Offset.fromHours(5);
  ioHelper.Writer.WriteOffset(offset);
  var zone = FixedDateTimeZone.Read(ioHelper.Reader, "id") as FixedDateTimeZone;

  expect("id", zone.id);
  expect(offset, zone.offset);
  expect("id", zone.Name);
}

@Test()
void Read_WithNameInStream()
{
  var ioHelper = DtzIoHelper.CreateNoStringPool();
  var offset = new Offset.fromHours(5);
  ioHelper.Writer.WriteOffset(offset);
  ioHelper.Writer.WriteString("name");
  var zone = FixedDateTimeZone.Read(ioHelper.Reader, "id") as FixedDateTimeZone;

  expect("id", zone.id);
  expect(offset, zone.offset);
  expect("name", zone.Name);
}

@Test()
void Roundtrip()
{
  var ioHelper = DtzIoHelper.CreateNoStringPool();
  var oldZone = new FixedDateTimeZone("id", new Offset.fromHours(4), "name");
  oldZone.Write(ioHelper.Writer);
  var newZone = FixedDateTimeZone.Read(ioHelper.Reader, "id") as FixedDateTimeZone;

  expect(oldZone.id, newZone.id);
  expect(oldZone.offset, newZone.offset);
  expect(oldZone.Name, newZone.Name);
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
