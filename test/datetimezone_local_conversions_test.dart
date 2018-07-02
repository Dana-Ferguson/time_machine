// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/text/time_machine_text.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

import 'testing/timezones/single_transition_datetimezone.dart';
import 'time_machine_testing.dart';

/// Tests for aspects of DateTimeZone to do with converting from LocalDateTime and
/// LocalDate to ZonedDateTime.
// TODO: Fix all tests to use SingleTransitionZone.

// Sample time zones for DateTimeZone.AtStartOfDay etc. I didn't want to only test midnight transitions.
DateTimeZone LosAngeles;
DateTimeZone NewZealand;
DateTimeZone Paris;
DateTimeZone NewYork;
DateTimeZone Pacific;

Future main() async {
  await TimeMachine.initialize();
  await setup();

  await runTests();
}

Future setup() async {
  LosAngeles = await (await DateTimeZoneProviders.tzdb)["America/Los_Angeles"];
  NewZealand = await (await DateTimeZoneProviders.tzdb)["Pacific/Auckland"];
  Paris = await (await DateTimeZoneProviders.tzdb)["Europe/Paris"];
  NewYork = await (await DateTimeZoneProviders.tzdb)["America/New_York"];
  Pacific = await (await DateTimeZoneProviders.tzdb)["America/Los_Angeles"];
}

/// Local midnight at the start of the transition (June 1st) becomes 1am.
final DateTimeZone TransitionForwardAtMidnightZone =
new SingleTransitionDateTimeZone(new Instant.fromUtc(2000, 6, 1, 2, 0), new Offset.fromHours(-2), new Offset.fromHours(-1));

/// Local 1am at the start of the transition (June 1st) becomes midnight.
final DateTimeZone TransitionBackwardToMidnightZone =
new SingleTransitionDateTimeZone(new Instant.fromUtc(2000, 6, 1, 3, 0), new Offset.fromHours(-2), new Offset.fromHours(-3));

/// Local 11.20pm at the start of the transition (May 30th) becomes 12.20am of June 1st.
final DateTimeZone TransitionForwardBeforeMidnightZone =
new SingleTransitionDateTimeZone(new Instant.fromUtc(2000, 6, 1, 1, 20), new Offset.fromHours(-2), new Offset.fromHours(-1));

/// Local 12.20am at the start of the transition (June 1st) becomes 11.20pm of the previous day.
final DateTimeZone TransitionBackwardAfterMidnightZone =
new SingleTransitionDateTimeZone(new Instant.fromUtc(2000, 6, 1, 2, 20), new Offset.fromHours(-2), new Offset.fromHours(-3));

final LocalDate TransitionDate = new LocalDate(2000, 6, 1);

@Test()
void AmbiguousStartOfDay_TransitionAtMidnight()
{
  // Occurrence before transition
  var expected = IZonedDateTime.trusted(new LocalDateTime.at(2000, 6, 1, 0, 0).withOffset(new Offset.fromHours(-2)),
      TransitionBackwardToMidnightZone);
  var actual = TransitionBackwardToMidnightZone.atStartOfDay(TransitionDate);
  expect(expected, actual);
  expect(expected, TransitionDate.atStartOfDayInZone(TransitionBackwardToMidnightZone));
}

@Test()
void AmbiguousStartOfDay_TransitionAfterMidnight()
{
  // Occurrence before transition
  var expected = IZonedDateTime.trusted(new LocalDateTime.at(2000, 6, 1, 0, 0).withOffset(new Offset.fromHours(-2)),
      TransitionBackwardAfterMidnightZone);
  var actual = TransitionBackwardAfterMidnightZone.atStartOfDay(TransitionDate);
  expect(expected, actual);
  expect(expected, TransitionDate.atStartOfDayInZone(TransitionBackwardAfterMidnightZone));
}

@Test()
void SkippedStartOfDay_TransitionAtMidnight()
{
  // 1am because of the skip
  var expected = IZonedDateTime.trusted(new LocalDateTime.at(2000, 6, 1, 1, 0).withOffset(new Offset.fromHours(-1)),
      TransitionForwardAtMidnightZone);
  var actual = TransitionForwardAtMidnightZone.atStartOfDay(TransitionDate);
  expect(expected, actual);
  expect(expected, TransitionDate.atStartOfDayInZone(TransitionForwardAtMidnightZone));
}

@Test()
void SkippedStartOfDay_TransitionBeforeMidnight()
{
  // 12.20am because of the skip
  var expected = IZonedDateTime.trusted(new LocalDateTime.at(2000, 6, 1, 0, 20).withOffset(new Offset.fromHours(-1)),
      TransitionForwardBeforeMidnightZone);
  var actual = TransitionForwardBeforeMidnightZone.atStartOfDay(TransitionDate);
  expect(expected, actual);
  expect(expected, TransitionDate.atStartOfDayInZone(TransitionForwardBeforeMidnightZone));
}

@Test()
void UnambiguousStartOfDay()
{
  // Just a simple midnight in March.
  var expected = IZonedDateTime.trusted(new LocalDateTime.at(2000, 3, 1, 0, 0).withOffset(new Offset.fromHours(-2)),
      TransitionForwardAtMidnightZone);
  var actual = TransitionForwardAtMidnightZone.atStartOfDay(new LocalDate(2000, 3, 1));
  expect(expected, actual);
  expect(expected, new LocalDate(2000, 3, 1).atStartOfDayInZone(TransitionForwardAtMidnightZone));
}

T captureVM<T extends Error>(action()) {
  try {
    action();
  } on T catch (error) {
    return error;
  };

  return null;
}

// DartWeb fails to reify generic types (see above) -- so, type erasure does have its own power.
Object capture(action()) {
  try {
    action();
  } catch (error) {
    return error;
  };

  return null;
}

void AssertImpossible(LocalDateTime localTime, DateTimeZone zone)
{
  var mapping = zone.mapLocal(localTime);
  expect(0, mapping.count);

  SkippedTimeError e; // = Assert.Throws<SkippedTimeException>(() => mapping.Single());
  expect(e = capture(() => mapping.single()), new isInstanceOf<SkippedTimeError>());
  expect(localTime, e.localDateTime);
  expect(zone, e.zone);

  // e = Assert.Throws<SkippedTimeException>(() => mapping.First());
  expect(e = capture(() => mapping.first()), new isInstanceOf<SkippedTimeError>());
  expect(localTime, e.localDateTime);
  expect(zone, e.zone);

  // e = Assert.Throws<SkippedTimeException>(() => mapping.Last());
  expect(e = capture(() => mapping.last()), new isInstanceOf<SkippedTimeError>());
  expect(localTime, e.localDateTime);
  expect(zone, e.zone);
}

void AssertAmbiguous(LocalDateTime localTime, DateTimeZone zone)
{
  ZonedDateTime earlier = zone.mapLocal(localTime).first();
  ZonedDateTime later = zone.mapLocal(localTime).last();
  expect(localTime, earlier.localDateTime);
  expect(localTime, later.localDateTime);
  expect(earlier.toInstant(), lessThan(later.toInstant()));

  var mapping = zone.mapLocal(localTime);
  expect(2, mapping.count);
  AmbiguousTimeError e; // = Assert.Throws<AmbiguousTimeException>(() => mapping.Single());
  expect(e = capture(() => mapping.single()), new isInstanceOf<AmbiguousTimeError>());
  expect(localTime, e.localDateTime);
  expect(zone, e.Zone);
  expect(earlier, e.earlierMapping);
  expect(later, e.laterMapping);

  expect(earlier, mapping.first());
  expect(later, mapping.last());
}

void AssertOffset(int expectedHours, LocalDateTime localTime, DateTimeZone zone)
{
  var mapping = zone.mapLocal(localTime);
  expect(1, mapping.count);
  var zoned = mapping.single();
  expect(zoned, mapping.first());
  expect(zoned, mapping.last());
  int actualHours = zoned.offset.milliseconds ~/ TimeConstants.millisecondsPerHour;
  expect(expectedHours, actualHours);
}

// Los Angeles goes from -7 to -8 on November 7th 2010 at 2am wall time
@Test()
void GetOffsetFromLocal_LosAngelesFallTransition()
{
  var before = new LocalDateTime.at(2010, 11, 7, 0, 30);
  var atTransition = new LocalDateTime.at(2010, 11, 7, 1, 0);
  var ambiguous = new LocalDateTime.at(2010, 11, 7, 1, 30);
  var after = new LocalDateTime.at(2010, 11, 7, 2, 30);
  AssertOffset(-7, before, LosAngeles);
  AssertAmbiguous(atTransition, LosAngeles);
  AssertAmbiguous(ambiguous, LosAngeles);
  AssertOffset(-8, after, LosAngeles);
}

@Test()
void GetOffsetFromLocal_LosAngelesSpringTransition()
{
  var before = new LocalDateTime.at(2010, 3, 14, 1, 30);
  var impossible = new LocalDateTime.at(2010, 3, 14, 2, 30);
  var atTransition = new LocalDateTime.at(2010, 3, 14, 3, 0);
  var after = new LocalDateTime.at(2010, 3, 14, 3, 30);
  AssertOffset(-8, before, LosAngeles);
  AssertImpossible(impossible, LosAngeles);
  AssertOffset(-7, atTransition, LosAngeles);
  AssertOffset(-7, after, LosAngeles);
}

// New Zealand goes from +13 to +12 on April 4th 2010 at 3am wall time
@Test()
void GetOffsetFromLocal_NewZealandFallTransition()
{
  var before = new LocalDateTime.at(2010, 4, 4, 1, 30);
  var atTransition = new LocalDateTime.at(2010, 4, 4, 2, 0);
  var ambiguous = new LocalDateTime.at(2010, 4, 4, 2, 30);
  var after = new LocalDateTime.at(2010, 4, 4, 3, 30);
  AssertOffset(13, before, NewZealand);
  AssertAmbiguous(atTransition, NewZealand);
  AssertAmbiguous(ambiguous, NewZealand);
  AssertOffset(12, after, NewZealand);
}

// New Zealand goes from +12 to +13 on September 26th 2010 at 2am wall time
@Test()
void GetOffsetFromLocal_NewZealandSpringTransition()
{
  var before = new LocalDateTime.at(2010, 9, 26, 1, 30);
  var impossible = new LocalDateTime.at(2010, 9, 26, 2, 30);
  var atTransition = new LocalDateTime.at(2010, 9, 26, 3, 0);
  var after = new LocalDateTime.at(2010, 9, 26, 3, 30);
  AssertOffset(12, before, NewZealand);
  AssertImpossible(impossible, NewZealand);
  AssertOffset(13, atTransition, NewZealand);
  AssertOffset(13, after, NewZealand);
}

// Paris goes from +1 to +2 on March 28th 2010 at 2am wall time
@Test()
void GetOffsetFromLocal_ParisFallTransition()
{
  var before = new LocalDateTime.at(2010, 10, 31, 1, 30);
  var atTransition = new LocalDateTime.at(2010, 10, 31, 2, 0);
  var ambiguous = new LocalDateTime.at(2010, 10, 31, 2, 30);
  var after = new LocalDateTime.at(2010, 10, 31, 3, 30);
  AssertOffset(2, before, Paris);
  AssertAmbiguous(ambiguous, Paris);
  AssertAmbiguous(atTransition, Paris);
  AssertOffset(1, after, Paris);
}

@Test()
void GetOffsetFromLocal_ParisSpringTransition()
{
  var before = new LocalDateTime.at(2010, 3, 28, 1, 30);
  var impossible = new LocalDateTime.at(2010, 3, 28, 2, 30);
  var atTransition = new LocalDateTime.at(2010, 3, 28, 3, 0);
  var after = new LocalDateTime.at(2010, 3, 28, 3, 30);
  AssertOffset(1, before, Paris);
  AssertImpossible(impossible, Paris);
  AssertOffset(2, atTransition, Paris);
  AssertOffset(2, after, Paris);
}

@Test()
void MapLocalDateTime_UnambiguousDateReturnsUnambiguousMapping()
{
  //2011-11-09 01:30:00 - not ambiguous in America/New York timezone
  var unambigiousTime = new LocalDateTime.at(2011, 11, 9, 1, 30);
  var mapping = NewYork.mapLocal(unambigiousTime);
  expect(1, mapping.count);
}

@Test()
void MapLocalDateTime_AmbiguousDateReturnsAmbigousMapping()
{
  //2011-11-06 01:30:00 - falls during DST - EST conversion in America/New York timezone
  var ambiguousTime = new LocalDateTime.at(2011, 11, 6, 1, 30);
  var mapping = NewYork.mapLocal(ambiguousTime);
  expect(2, mapping.count);
}

@Test()
void MapLocalDateTime_SkippedDateReturnsSkippedMapping()
{
  //2011-03-13 02:30:00 - falls during EST - DST conversion in America/New York timezone
  var skippedTime = new LocalDateTime.at(2011, 3, 13, 2, 30);
  var mapping = NewYork.mapLocal(skippedTime);
  expect(0, mapping.count);
}

// Some zones skipped dates by changing from UTC-lots to UTC+lots. For example, Samoa (Pacific/Apia)
// skipped December 30th 2011, going from  23:59:59 December 29th local time UTC-10
// to 00:00:00 December 31st local time UTC+14
@Test()
@TestCase(const ["Pacific/Apia", "2011-12-30"])
@TestCase(const ["Pacific/Enderbury", "1994-12-31"])
@TestCase(const ["Pacific/Kiritimati", "1994-12-31"])
@TestCase(const ["Pacific/Kwajalein", "1993-08-20"])
Future AtStartOfDay_DayDoesntExist(String zoneId, String localDate) async
{
  LocalDate badDate = LocalDatePattern.iso.parse(localDate).value;
  DateTimeZone zone = await (await DateTimeZoneProviders.tzdb)[zoneId];
  SkippedTimeError exception; //  = Assert.Throws<SkippedTimeException>(() => zone.AtStartOfDay(badDate));
  expect(exception = capture(() => zone.atStartOfDay(badDate)), new isInstanceOf<SkippedTimeError>());
  expect(badDate.at(LocalTime.midnight), exception.localDateTime);
}

@Test()
void AtStrictly_InWinter()
{
  var when = Pacific.atStrictly(new LocalDateTime.at(2009, 12, 22, 21, 39, seconds: 30));

  expect(2009, when.year);
  expect(12, when.month);
  expect(22, when.day);
  expect(DayOfWeek.tuesday, when.dayOfWeek);
  expect(21, when.hour);
  expect(39, when.minute);
  expect(30, when.second);
  expect(new Offset.fromHours(-8), when.offset);
}

@Test()
void AtStrictly_InSummer()
{
  var when = Pacific.atStrictly(new LocalDateTime.at(2009, 6, 22, 21, 39, seconds: 30));

  expect(2009, when.year);
  expect(6, when.month);
  expect(22, when.day);
  expect(21, when.hour);
  expect(39, when.minute);
  expect(30, when.second);
  expect(new Offset.fromHours(-7), when.offset);
}

/// Pacific time changed from -7 to -8 at 2am wall time on November 2nd 2009,
/// so 2am became 1am.
@Test()
void AtStrictly_ThrowsWhenAmbiguous()
{
  // Assert.Throws<AmbiguousTimeException>(() => Pacific.AtStrictly(new LocalDateTime.fromYMDHMS(2009, 11, 1, 1, 30, 0)));
  expect(() => Pacific.atStrictly(new LocalDateTime.at(2009, 11, 1, 1, 30)), willThrow<AmbiguousTimeError>());
}

/// Pacific time changed from -8 to -7 at 2am wall time on March 8th 2009,
/// so 2am became 3am. This means that 2.30am doesn't exist on that day.
@Test()
void AtStrictly_ThrowsWhenSkipped()
{
  // Assert.Throws<SkippedTimeException>(() => Pacific.AtStrictly(new LocalDateTime.fromYMDHMS(2009, 3, 8, 2, 30, 0)));
  expect(() => Pacific.atStrictly(new LocalDateTime.at(2009, 3, 8, 2, 30)), willThrow<SkippedTimeError>());
}

/// Pacific time changed from -7 to -8 at 2am wall time on November 2nd 2009,
/// so 2am became 1am. We'll return the earlier result, i.e. with the offset of -7
@Test()
void AtLeniently_AmbiguousTime_ReturnsEarlierMapping()
{
  var local = new LocalDateTime.at(2009, 11, 1, 1, 30);
  var zoned = Pacific.atLeniently(local);
  expect(zoned.localDateTime, local);
  expect(zoned.offset, new Offset.fromHours(-7));
}

/// Pacific time changed from -8 to -7 at 2am wall time on March 8th 2009,
/// so 2am became 3am. This means that 2:30am doesn't exist on that day.
/// We'll return 3:30am, the forward-shifted value.
@Test()
void AtLeniently_ReturnsForwardShiftedValue()
{
  var local = new LocalDateTime.at(2009, 3, 8, 2, 30);
  var zoned = Pacific.atLeniently(local);
  expect(new LocalDateTime.at(2009, 3, 8, 3, 30), zoned.localDateTime);
  expect(new Offset.fromHours(-7), zoned.offset);
}

@Test()
void ResolveLocal()
{
  // Don't need much for this - it only delegates.
  var ambiguous = new LocalDateTime.at(2009, 11, 1, 1, 30);
  var skipped = new LocalDateTime.at(2009, 3, 8, 2, 30);
  expect(Pacific.atLeniently(ambiguous), Pacific.resolveLocal(ambiguous, Resolvers.lenientResolver));
  expect(Pacific.atLeniently(skipped), Pacific.resolveLocal(skipped, Resolvers.lenientResolver));
}
