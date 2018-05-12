// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/TimeZones/ResolversTest.cs
// 8d5399d  on Feb 26, 2016

import 'dart:async';
import 'dart:math' as math;

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import '../time_machine_testing.dart';

Future main() async {
  await runTests();
}


/// Zone where the clocks go back at 1am at the start of the year 2000, back to midnight.
SingleTransitionDateTimeZone AmbiguousZone = new SingleTransitionDateTimeZone.around(new Instant.fromUtc(2000, 1, 1, 0, 0), 1, 0);

/// Zone where the clocks go forward at midnight at the start of the year 2000, to 1am.
SingleTransitionDateTimeZone GapZone = new SingleTransitionDateTimeZone.around(new Instant.fromUtc(2000, 1, 1, 0, 0), 0, 1);

/// Local time which is either skipped or ambiguous, depending on the zones above.
LocalDateTime TimeInTransition = new LocalDateTime.fromYMDHM(2000, 1, 1, 0, 20);

@Test()
void ReturnEarlier()
{
  var mapping = AmbiguousZone.MapLocal(TimeInTransition);
  expect(2, mapping.Count);
  var resolved = Resolvers.ReturnEarlier(mapping.First(), mapping.Last());
  expect(mapping.First(), resolved);
}

@Test()
void ReturnLater()
{
  var mapping = AmbiguousZone.MapLocal(TimeInTransition);
  expect(2, mapping.Count);
  var resolved = Resolvers.ReturnLater(mapping.First(), mapping.Last());
  expect(mapping.Last(), resolved);
}

@Test()
void ThrowWhenAmbiguous()
{
  var mapping = AmbiguousZone.MapLocal(TimeInTransition);
  expect(2, mapping.Count);
  expect(() => Resolvers.ThrowWhenAmbiguous(mapping.First(), mapping.Last()), willThrow<AmbiguousTimeError>());
}

@Test()
void ReturnEndOfIntervalBefore()
{
  var mapping = GapZone.MapLocal(TimeInTransition);
  expect(0, mapping.Count);
  var resolved = Resolvers.ReturnEndOfIntervalBefore(TimeInTransition, GapZone, mapping.EarlyInterval, mapping.LateInterval);
  expect(GapZone.EarlyInterval.end - Span.epsilon, resolved.ToInstant());
  expect(GapZone, resolved.Zone);
}

@Test()
void ReturnStartOfIntervalAfter()
{
  var mapping = GapZone.MapLocal(TimeInTransition);
  expect(0, mapping.Count);
  var resolved = Resolvers.ReturnStartOfIntervalAfter(TimeInTransition, GapZone, mapping.EarlyInterval, mapping.LateInterval);
  expect(GapZone.LateInterval.start, resolved.ToInstant());
  expect(GapZone, resolved.Zone);
}

@Test()
void ReturnForwardShifted()
{
  var mapping = GapZone.MapLocal(TimeInTransition);
  expect(0, mapping.Count);
  var resolved = Resolvers.ReturnForwardShifted(TimeInTransition, GapZone, mapping.EarlyInterval, mapping.LateInterval);

  var gap = mapping.LateInterval.wallOffset.ticks - mapping.EarlyInterval.wallOffset.ticks;
  var expected = TimeInTransition.ToLocalInstant().Minus(mapping.LateInterval.wallOffset).plus(new Span(ticks: gap));
  expect(expected, resolved.ToInstant());
  expect(mapping.LateInterval.wallOffset, resolved.offset);
  expect(GapZone, resolved.Zone);
}

@Test()
void ThrowWhenSkipped()
{
  var mapping = GapZone.MapLocal(TimeInTransition);
  expect(0, mapping.Count);
  expect(() => Resolvers.ThrowWhenSkipped(TimeInTransition, GapZone, mapping.EarlyInterval, mapping.LateInterval), willThrow<SkippedTimeError>());
}

@Test()
void CreateResolver_Unambiguous() {
  AmbiguousTimeResolver ambiguityResolver = (earlier, later) {
    /*Assert.Fail*/ throw new StateError("Shouldn't be called");
    return null; /*default(ZonedDateTime);*/
  };

  SkippedTimeResolver skippedTimeResolver = (local, zone, before, after) {
    /*Assert.Fail*/ throw new StateError("Shouldn't be called");
    return null; /*default(ZonedDateTime);*/
  };
  var resolver = Resolvers.CreateMappingResolver(ambiguityResolver, skippedTimeResolver);

  LocalDateTime localTime = new LocalDateTime.fromYMDHM(1900, 1, 1, 0, 0);
  var resolved = resolver(GapZone.MapLocal(localTime));
  expect(new ZonedDateTime.trusted(localTime.WithOffset(GapZone.EarlyInterval.wallOffset), GapZone), resolved);
}

@Test()
void CreateResolver_Ambiguous() {
  ZonedDateTime zoned = new ZonedDateTime.trusted(TimeInTransition.PlusDays(1).WithOffset(GapZone.EarlyInterval.wallOffset), GapZone);
  AmbiguousTimeResolver ambiguityResolver = (earlier, later) => zoned;
  SkippedTimeResolver skippedTimeResolver = (local, zone, before, after) {
    /*Assert.Fail*/ throw new StateError("Shouldn't be called");
    return null; /*default(ZonedDateTime);*/
  };
  var resolver = Resolvers.CreateMappingResolver(ambiguityResolver, skippedTimeResolver);

  var resolved = resolver(AmbiguousZone.MapLocal(TimeInTransition));
  expect(zoned, resolved);
}

@Test()
void CreateResolver_Skipped() {
  ZonedDateTime zoned = new ZonedDateTime.trusted(TimeInTransition.PlusDays(1).WithOffset(GapZone.EarlyInterval.wallOffset), GapZone);
  AmbiguousTimeResolver ambiguityResolver = (earlier, later) {
    /*Assert.Fail*/ throw new StateError("Shouldn't be called");
    return null; /*default(ZonedDateTime);*/
  };
  SkippedTimeResolver skippedTimeResolver = (local, zone, before, after) => zoned;
  var resolver = Resolvers.CreateMappingResolver(ambiguityResolver, skippedTimeResolver);

  var resolved = resolver(GapZone.MapLocal(TimeInTransition));
  expect(zoned, resolved);
}

