// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/DateTimeZoneTest.LocalConversions.cs
// 2e47e7c  on Mar 24

import 'dart:async';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import 'testing/timezones/single_transition_datetimezone.dart';
import 'testing/timezones/multi_transition_datetimezone.dart';
import 'time_machine_testing.dart';

/// <summary>
/// Tests for aspects of DateTimeZone to do with converting from LocalDateTime and
/// LocalDate to ZonedDateTime.
/// </summary>
// TODO: Fix all tests to use SingleTransitionZone.

// Sample time zones for DateTimeZone.AtStartOfDay etc. I didn't want to only test midnight transitions.
DateTimeZone LosAngeles;
DateTimeZone NewZealand;
DateTimeZone Paris;
DateTimeZone NewYork;
DateTimeZone Pacific;

Future main() async {
  LosAngeles = await (await DateTimeZoneProviders.Tzdb)["America/Los_Angeles"];
  NewZealand = await (await DateTimeZoneProviders.Tzdb)["Pacific/Auckland"];
  Paris = await (await DateTimeZoneProviders.Tzdb)["Europe/Paris"];
  NewYork = await (await DateTimeZoneProviders.Tzdb)["America/New_York"];
  Pacific = await (await DateTimeZoneProviders.Tzdb)["America/Los_Angeles"];

  await runTests();
}

/// <summary>
/// Local midnight at the start of the transition (June 1st) becomes 1am.
/// </summary>
final DateTimeZone TransitionForwardAtMidnightZone =
new SingleTransitionDateTimeZone(new Instant.fromUtc(2000, 6, 1, 2, 0), new Offset.fromHours(-2), new Offset.fromHours(-1));

/// <summary>
/// Local 1am at the start of the transition (June 1st) becomes midnight.
/// </summary>
final DateTimeZone TransitionBackwardToMidnightZone =
new SingleTransitionDateTimeZone(new Instant.fromUtc(2000, 6, 1, 3, 0), new Offset.fromHours(-2), new Offset.fromHours(-3));

/// <summary>
/// Local 11.20pm at the start of the transition (May 30th) becomes 12.20am of June 1st.
/// </summary>
final DateTimeZone TransitionForwardBeforeMidnightZone =
new SingleTransitionDateTimeZone(new Instant.fromUtc(2000, 6, 1, 1, 20), new Offset.fromHours(-2), new Offset.fromHours(-1));

/// <summary>
/// Local 12.20am at the start of the transition (June 1st) becomes 11.20pm of the previous day.
/// </summary>
final DateTimeZone TransitionBackwardAfterMidnightZone =
new SingleTransitionDateTimeZone(new Instant.fromUtc(2000, 6, 1, 2, 20), new Offset.fromHours(-2), new Offset.fromHours(-3));

final LocalDate TransitionDate = new LocalDate(2000, 6, 1);

@Test()
void AmbiguousStartOfDay_TransitionAtMidnight()
{
  // Occurrence before transition
  var expected = new ZonedDateTime.trusted(new LocalDateTime.fromYMDHM(2000, 6, 1, 0, 0).WithOffset(new Offset.fromHours(-2)),
      TransitionBackwardToMidnightZone);
  var actual = TransitionBackwardToMidnightZone.AtStartOfDay(TransitionDate);
  expect(expected, actual);
  expect(expected, TransitionDate.AtStartOfDayInZone(TransitionBackwardToMidnightZone));
}

@Test()
void AmbiguousStartOfDay_TransitionAfterMidnight()
{
  // Occurrence before transition
  var expected = new ZonedDateTime.trusted(new LocalDateTime.fromYMDHM(2000, 6, 1, 0, 0).WithOffset(new Offset.fromHours(-2)),
      TransitionBackwardAfterMidnightZone);
  var actual = TransitionBackwardAfterMidnightZone.AtStartOfDay(TransitionDate);
  expect(expected, actual);
  expect(expected, TransitionDate.AtStartOfDayInZone(TransitionBackwardAfterMidnightZone));
}

@Test()
void SkippedStartOfDay_TransitionAtMidnight()
{
  // 1am because of the skip
  var expected = new ZonedDateTime.trusted(new LocalDateTime.fromYMDHM(2000, 6, 1, 1, 0).WithOffset(new Offset.fromHours(-1)),
      TransitionForwardAtMidnightZone);
  var actual = TransitionForwardAtMidnightZone.AtStartOfDay(TransitionDate);
  expect(expected, actual);
  expect(expected, TransitionDate.AtStartOfDayInZone(TransitionForwardAtMidnightZone));
}

@Test()
void SkippedStartOfDay_TransitionBeforeMidnight()
{
  // 12.20am because of the skip
  var expected = new ZonedDateTime.trusted(new LocalDateTime.fromYMDHM(2000, 6, 1, 0, 20).WithOffset(new Offset.fromHours(-1)),
      TransitionForwardBeforeMidnightZone);
  var actual = TransitionForwardBeforeMidnightZone.AtStartOfDay(TransitionDate);
  expect(expected, actual);
  expect(expected, TransitionDate.AtStartOfDayInZone(TransitionForwardBeforeMidnightZone));
}

@Test()
void UnambiguousStartOfDay()
{
  // Just a simple midnight in March.
  var expected = new ZonedDateTime.trusted(new LocalDateTime.fromYMDHM(2000, 3, 1, 0, 0).WithOffset(new Offset.fromHours(-2)),
      TransitionForwardAtMidnightZone);
  var actual = TransitionForwardAtMidnightZone.AtStartOfDay(new LocalDate(2000, 3, 1));
  expect(expected, actual);
  expect(expected, new LocalDate(2000, 3, 1).AtStartOfDayInZone(TransitionForwardAtMidnightZone));
}

T capture<T extends Error>(action()) {
  try {
    action();
  } on T catch (error) {
    return error;
  };

  return null;
}

void AssertImpossible(LocalDateTime localTime, DateTimeZone zone)
{
  var mapping = zone.MapLocal(localTime);
  expect(0, mapping.Count);

  SkippedTimeError e; // = Assert.Throws<SkippedTimeException>(() => mapping.Single());
  expect(e = capture(() => mapping.Single()), new isInstanceOf<SkippedTimeError>());
  expect(localTime, e.localDateTime);
  expect(zone, e.zone);

  // e = Assert.Throws<SkippedTimeException>(() => mapping.First());
  expect(e = capture(() => mapping.First()), new isInstanceOf<SkippedTimeError>());
  expect(localTime, e.localDateTime);
  expect(zone, e.zone);

  // e = Assert.Throws<SkippedTimeException>(() => mapping.Last());
  expect(e = capture(() => mapping.Last()), new isInstanceOf<SkippedTimeError>());
  expect(localTime, e.localDateTime);
  expect(zone, e.zone);
}

void AssertAmbiguous(LocalDateTime localTime, DateTimeZone zone)
{
  ZonedDateTime earlier = zone.MapLocal(localTime).First();
  ZonedDateTime later = zone.MapLocal(localTime).Last();
  expect(localTime, earlier.localDateTime);
  expect(localTime, later.localDateTime);
  expect(earlier.ToInstant(), lessThan(later.ToInstant()));

  var mapping = zone.MapLocal(localTime);
  expect(2, mapping.Count);
  AmbiguousTimeError e; // = Assert.Throws<AmbiguousTimeException>(() => mapping.Single());
  expect(e = capture(() => mapping.Single()), new isInstanceOf<AmbiguousTimeError>());
  expect(localTime, e.localDateTime);
  expect(zone, e.Zone);
  expect(earlier, e.earlierMapping);
  expect(later, e.laterMapping);

  expect(earlier, mapping.First());
  expect(later, mapping.Last());
}

void AssertOffset(int expectedHours, LocalDateTime localTime, DateTimeZone zone)
{
  var mapping = zone.MapLocal(localTime);
  expect(1, mapping.Count);
  var zoned = mapping.Single();
  expect(zoned, mapping.First());
  expect(zoned, mapping.Last());
  int actualHours = zoned.offset.milliseconds ~/ TimeConstants.millisecondsPerHour;
  expect(expectedHours, actualHours);
}

// Los Angeles goes from -7 to -8 on November 7th 2010 at 2am wall time
@Test()
void GetOffsetFromLocal_LosAngelesFallTransition()
{
  var before = new LocalDateTime.fromYMDHM(2010, 11, 7, 0, 30);
  var atTransition = new LocalDateTime.fromYMDHM(2010, 11, 7, 1, 0);
  var ambiguous = new LocalDateTime.fromYMDHM(2010, 11, 7, 1, 30);
  var after = new LocalDateTime.fromYMDHM(2010, 11, 7, 2, 30);
  AssertOffset(-7, before, LosAngeles);
  AssertAmbiguous(atTransition, LosAngeles);
  AssertAmbiguous(ambiguous, LosAngeles);
  AssertOffset(-8, after, LosAngeles);
}

@Test()
void GetOffsetFromLocal_LosAngelesSpringTransition()
{
  var before = new LocalDateTime.fromYMDHM(2010, 3, 14, 1, 30);
  var impossible = new LocalDateTime.fromYMDHM(2010, 3, 14, 2, 30);
  var atTransition = new LocalDateTime.fromYMDHM(2010, 3, 14, 3, 0);
  var after = new LocalDateTime.fromYMDHM(2010, 3, 14, 3, 30);
  AssertOffset(-8, before, LosAngeles);
  AssertImpossible(impossible, LosAngeles);
  AssertOffset(-7, atTransition, LosAngeles);
  AssertOffset(-7, after, LosAngeles);
}

// New Zealand goes from +13 to +12 on April 4th 2010 at 3am wall time
@Test()
void GetOffsetFromLocal_NewZealandFallTransition()
{
  var before = new LocalDateTime.fromYMDHM(2010, 4, 4, 1, 30);
  var atTransition = new LocalDateTime.fromYMDHM(2010, 4, 4, 2, 0);
  var ambiguous = new LocalDateTime.fromYMDHM(2010, 4, 4, 2, 30);
  var after = new LocalDateTime.fromYMDHM(2010, 4, 4, 3, 30);
  AssertOffset(13, before, NewZealand);
  AssertAmbiguous(atTransition, NewZealand);
  AssertAmbiguous(ambiguous, NewZealand);
  AssertOffset(12, after, NewZealand);
}

// New Zealand goes from +12 to +13 on September 26th 2010 at 2am wall time
@Test()
void GetOffsetFromLocal_NewZealandSpringTransition()
{
  var before = new LocalDateTime.fromYMDHM(2010, 9, 26, 1, 30);
  var impossible = new LocalDateTime.fromYMDHM(2010, 9, 26, 2, 30);
  var atTransition = new LocalDateTime.fromYMDHM(2010, 9, 26, 3, 0);
  var after = new LocalDateTime.fromYMDHM(2010, 9, 26, 3, 30);
  AssertOffset(12, before, NewZealand);
  AssertImpossible(impossible, NewZealand);
  AssertOffset(13, atTransition, NewZealand);
  AssertOffset(13, after, NewZealand);
}

// Paris goes from +1 to +2 on March 28th 2010 at 2am wall time
@Test()
void GetOffsetFromLocal_ParisFallTransition()
{
  var before = new LocalDateTime.fromYMDHM(2010, 10, 31, 1, 30);
  var atTransition = new LocalDateTime.fromYMDHM(2010, 10, 31, 2, 0);
  var ambiguous = new LocalDateTime.fromYMDHM(2010, 10, 31, 2, 30);
  var after = new LocalDateTime.fromYMDHM(2010, 10, 31, 3, 30);
  AssertOffset(2, before, Paris);
  AssertAmbiguous(ambiguous, Paris);
  AssertAmbiguous(atTransition, Paris);
  AssertOffset(1, after, Paris);
}

@Test()
void GetOffsetFromLocal_ParisSpringTransition()
{
  var before = new LocalDateTime.fromYMDHM(2010, 3, 28, 1, 30);
  var impossible = new LocalDateTime.fromYMDHM(2010, 3, 28, 2, 30);
  var atTransition = new LocalDateTime.fromYMDHM(2010, 3, 28, 3, 0);
  var after = new LocalDateTime.fromYMDHM(2010, 3, 28, 3, 30);
  AssertOffset(1, before, Paris);
  AssertImpossible(impossible, Paris);
  AssertOffset(2, atTransition, Paris);
  AssertOffset(2, after, Paris);
}

@Test()
void MapLocalDateTime_UnambiguousDateReturnsUnambiguousMapping()
{
  //2011-11-09 01:30:00 - not ambiguous in America/New York timezone
  var unambigiousTime = new LocalDateTime.fromYMDHM(2011, 11, 9, 1, 30);
  var mapping = NewYork.MapLocal(unambigiousTime);
  expect(1, mapping.Count);
}

@Test()
void MapLocalDateTime_AmbiguousDateReturnsAmbigousMapping()
{
  //2011-11-06 01:30:00 - falls during DST - EST conversion in America/New York timezone
  var ambiguousTime = new LocalDateTime.fromYMDHM(2011, 11, 6, 1, 30);
  var mapping = NewYork.MapLocal(ambiguousTime);
  expect(2, mapping.Count);
}

@Test()
void MapLocalDateTime_SkippedDateReturnsSkippedMapping()
{
  //2011-03-13 02:30:00 - falls during EST - DST conversion in America/New York timezone
  var skippedTime = new LocalDateTime.fromYMDHM(2011, 3, 13, 2, 30);
  var mapping = NewYork.MapLocal(skippedTime);
  expect(0, mapping.Count);
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
  LocalDate badDate = LocalDatePattern.Iso.Parse(localDate).Value;
  DateTimeZone zone = await (await DateTimeZoneProviders.Tzdb)[zoneId];
  SkippedTimeError exception; //  = Assert.Throws<SkippedTimeException>(() => zone.AtStartOfDay(badDate));
  expect(exception = capture(() => zone.AtStartOfDay(badDate)), new isInstanceOf<SkippedTimeError>());

  expect(badDate.At(LocalTime.Midnight), exception.localDateTime);
}

@Test()
void AtStrictly_InWinter()
{
  var when = Pacific.AtStrictly(new LocalDateTime.fromYMDHMS(2009, 12, 22, 21, 39, 30));

  expect(2009, when.Year);
  expect(12, when.Month);
  expect(22, when.Day);
  expect(IsoDayOfWeek.tuesday, when.DayOfWeek);
  expect(21, when.Hour);
  expect(39, when.Minute);
  expect(30, when.Second);
  expect(new Offset.fromHours(-8), when.offset);
}

@Test()
void AtStrictly_InSummer()
{
  var when = Pacific.AtStrictly(new LocalDateTime.fromYMDHMS(2009, 6, 22, 21, 39, 30));

  expect(2009, when.Year);
  expect(6, when.Month);
  expect(22, when.Day);
  expect(21, when.Hour);
  expect(39, when.Minute);
  expect(30, when.Second);
  expect(new Offset.fromHours(-7), when.offset);
}

/// <summary>
/// Pacific time changed from -7 to -8 at 2am wall time on November 2nd 2009,
/// so 2am became 1am.
/// </summary>
@Test()
void AtStrictly_ThrowsWhenAmbiguous()
{
  // Assert.Throws<AmbiguousTimeException>(() => Pacific.AtStrictly(new LocalDateTime.fromYMDHMS(2009, 11, 1, 1, 30, 0)));
  expect(() => Pacific.AtStrictly(new LocalDateTime.fromYMDHMS(2009, 11, 1, 1, 30, 0)), throwsA(AmbiguousTimeError));
}

/// <summary>
/// Pacific time changed from -8 to -7 at 2am wall time on March 8th 2009,
/// so 2am became 3am. This means that 2.30am doesn't exist on that day.
/// </summary>
@Test()
void AtStrictly_ThrowsWhenSkipped()
{
  // Assert.Throws<SkippedTimeException>(() => Pacific.AtStrictly(new LocalDateTime.fromYMDHMS(2009, 3, 8, 2, 30, 0)));
  expect(() => Pacific.AtStrictly(new LocalDateTime.fromYMDHMS(2009, 3, 8, 2, 30, 0)), throwsA(SkippedTimeError));
}

/// <summary>
/// Pacific time changed from -7 to -8 at 2am wall time on November 2nd 2009,
/// so 2am became 1am. We'll return the earlier result, i.e. with the offset of -7
/// </summary>
@Test()
void AtLeniently_AmbiguousTime_ReturnsEarlierMapping()
{
  var local = new LocalDateTime.fromYMDHMS(2009, 11, 1, 1, 30, 0);
  // Our Pacific is a PrecalculatedDateTimeZone
  // Noda's Pacific is a CachedDateTimeZone or a PrecalculatedDateTimeZone
  //  --> the 'firstGuess' produced by each library differ

  // firstTailZoneInterval
  //  RawStart is the same, RawEnd is different
  //  localEnd is different (our's is off by 7 hours!) ?? loading issue ?? missed offset application?

  // other _localEnds's are off in the periods list (MORE LOADING ERRORS!)
  var zoned = Pacific.AtLeniently(local);
  expect(zoned.localDateTime, local);
  // Offset.fromHours(-8) is what we're getting
  expect(zoned.offset, new Offset.fromHours(-7));
}

/// <summary>
/// Pacific time changed from -8 to -7 at 2am wall time on March 8th 2009,
/// so 2am became 3am. This means that 2:30am doesn't exist on that day.
/// We'll return 3:30am, the forward-shifted value.
/// </summary>
@Test()
void AtLeniently_ReturnsForwardShiftedValue()
{
  var local = new LocalDateTime.fromYMDHMS(2009, 3, 8, 2, 30, 0);
  var zoned = Pacific.AtLeniently(local);
  expect(new LocalDateTime.fromYMDHMS(2009, 3, 8, 3, 30, 0), zoned.localDateTime);
  expect(new Offset.fromHours(-7), zoned.offset);
}

@Test()
void ResolveLocal()
{
  // Don't need much for this - it only delegates.
  var ambiguous = new LocalDateTime.fromYMDHMS(2009, 11, 1, 1, 30, 0);
  var skipped = new LocalDateTime.fromYMDHMS(2009, 3, 8, 2, 30, 0);
  expect(Pacific.AtLeniently(ambiguous), Pacific.ResolveLocal(ambiguous, Resolvers.LenientResolver));
  expect(Pacific.AtLeniently(skipped), Pacific.ResolveLocal(skipped, Resolvers.LenientResolver));
}