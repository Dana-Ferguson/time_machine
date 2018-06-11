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
  var mapping = AmbiguousZone.mapLocal(TimeInTransition);
  expect(2, mapping.Count);
  var resolved = Resolvers.returnEarlier(mapping.First(), mapping.Last());
  expect(mapping.First(), resolved);
}

@Test()
void ReturnLater()
{
  var mapping = AmbiguousZone.mapLocal(TimeInTransition);
  expect(2, mapping.Count);
  var resolved = Resolvers.returnLater(mapping.First(), mapping.Last());
  expect(mapping.Last(), resolved);
}

@Test()
void ThrowWhenAmbiguous()
{
  var mapping = AmbiguousZone.mapLocal(TimeInTransition);
  expect(2, mapping.Count);
  expect(() => Resolvers.throwWhenAmbiguous(mapping.First(), mapping.Last()), willThrow<AmbiguousTimeError>());
}

@Test()
void ReturnEndOfIntervalBefore()
{
  var mapping = GapZone.mapLocal(TimeInTransition);
  expect(0, mapping.Count);
  var resolved = Resolvers.returnEndOfIntervalBefore(TimeInTransition, GapZone, mapping.EarlyInterval, mapping.LateInterval);
  expect(GapZone.EarlyInterval.end - Span.epsilon, resolved.ToInstant());
  expect(GapZone, resolved.Zone);
}

@Test()
void ReturnStartOfIntervalAfter()
{
  var mapping = GapZone.mapLocal(TimeInTransition);
  expect(0, mapping.Count);
  var resolved = Resolvers.returnStartOfIntervalAfter(TimeInTransition, GapZone, mapping.EarlyInterval, mapping.LateInterval);
  expect(GapZone.LateInterval.start, resolved.ToInstant());
  expect(GapZone, resolved.Zone);
}

@Test()
void ReturnForwardShifted()
{
  var mapping = GapZone.mapLocal(TimeInTransition);
  expect(0, mapping.Count);
  var resolved = Resolvers.returnForwardShifted(TimeInTransition, GapZone, mapping.EarlyInterval, mapping.LateInterval);

  var gap = mapping.LateInterval.wallOffset.ticks - mapping.EarlyInterval.wallOffset.ticks;
  var expected = TimeInTransition.toLocalInstant().Minus(mapping.LateInterval.wallOffset).plus(new Span(ticks: gap));
  expect(expected, resolved.ToInstant());
  expect(mapping.LateInterval.wallOffset, resolved.offset);
  expect(GapZone, resolved.Zone);
}

@Test()
void ThrowWhenSkipped()
{
  var mapping = GapZone.mapLocal(TimeInTransition);
  expect(0, mapping.Count);
  expect(() => Resolvers.throwWhenSkipped(TimeInTransition, GapZone, mapping.EarlyInterval, mapping.LateInterval), willThrow<SkippedTimeError>());
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
  var resolver = Resolvers.createMappingResolver(ambiguityResolver, skippedTimeResolver);

  LocalDateTime localTime = new LocalDateTime.fromYMDHM(1900, 1, 1, 0, 0);
  var resolved = resolver(GapZone.mapLocal(localTime));
  expect(new ZonedDateTime.trusted(localTime.withOffset(GapZone.EarlyInterval.wallOffset), GapZone), resolved);
}

@Test()
void CreateResolver_Ambiguous() {
  ZonedDateTime zoned = new ZonedDateTime.trusted(TimeInTransition.plusDays(1).withOffset(GapZone.EarlyInterval.wallOffset), GapZone);
  AmbiguousTimeResolver ambiguityResolver = (earlier, later) => zoned;
  SkippedTimeResolver skippedTimeResolver = (local, zone, before, after) {
    /*Assert.Fail*/ throw new StateError("Shouldn't be called");
    return null; /*default(ZonedDateTime);*/
  };
  var resolver = Resolvers.createMappingResolver(ambiguityResolver, skippedTimeResolver);

  var resolved = resolver(AmbiguousZone.mapLocal(TimeInTransition));
  expect(zoned, resolved);
}

@Test()
void CreateResolver_Skipped() {
  ZonedDateTime zoned = new ZonedDateTime.trusted(TimeInTransition.plusDays(1).withOffset(GapZone.EarlyInterval.wallOffset), GapZone);
  AmbiguousTimeResolver ambiguityResolver = (earlier, later) {
    /*Assert.Fail*/ throw new StateError("Shouldn't be called");
    return null; /*default(ZonedDateTime);*/
  };
  SkippedTimeResolver skippedTimeResolver = (local, zone, before, after) => zoned;
  var resolver = Resolvers.createMappingResolver(ambiguityResolver, skippedTimeResolver);

  var resolved = resolver(GapZone.mapLocal(TimeInTransition));
  expect(zoned, resolved);
}


