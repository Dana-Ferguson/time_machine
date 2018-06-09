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

// Tests for MapLocal within DateTimeZone.
// We have two zones, each with a single transition at midnight January 1st 2000.
// One goes from -5 to +10, i.e. skips from 7pm Dec 31st to 10am Jan 1st
// The other goes from +10 to -5, i.e. goes from 10am Jan 1st back to 7pm Dec 31st.
// Both zones are tested for the zone interval pairs at:
// - The start of time
// - The end of time
// - A local time well before the transition
// - A local time well after the transition
// - An unambiguous local time shortly before the transition
// - An unambiguous local time shortly after the transition
// - The start of the transition
// - In the middle of the gap / ambiguity
// - The last local instant of the gap / ambiguity
// - The local instant immediately after the gap / ambiguity
Future main() async {
  await runTests();
}

final Instant Transition = new Instant.fromUtc(2000, 1, 1, 0, 0);

final Offset Minus5 = new Offset.fromHours(-5);
final Offset Plus10 = new Offset.fromHours(10);

final LocalDateTime NearStartOfTime = new LocalDateTime.fromYMDHM(-9998, 1, 5, 0, 0);
final LocalDateTime NearEndOfTime = new LocalDateTime.fromYMDHM(9999, 12, 25, 0, 0);
final LocalDateTime TransitionMinus5 = Transition.WithOffset(Minus5).localDateTime;
final LocalDateTime TransitionPlus10 = Transition.WithOffset(Plus10).localDateTime;
final LocalDateTime MidTransition = Transition.WithOffset(Offset.zero).localDateTime;

final LocalDateTime YearBeforeTransition = new LocalDateTime.fromYMDHM(1999, 1, 1, 0, 0);
final LocalDateTime YearAfterTransition = new LocalDateTime.fromYMDHM(2001, 1, 1, 0, 0);

final SingleTransitionDateTimeZone ZoneWithGap = new SingleTransitionDateTimeZone(Transition, Minus5, Plus10);
final ZoneInterval IntervalBeforeGap = ZoneWithGap.EarlyInterval;
final ZoneInterval IntervalAfterGap = ZoneWithGap.LateInterval;

final SingleTransitionDateTimeZone ZoneWithAmbiguity = new SingleTransitionDateTimeZone(Transition, Plus10, Minus5);
final ZoneInterval IntervalBeforeAmbiguity = ZoneWithAmbiguity.EarlyInterval;
final ZoneInterval IntervalAfterAmbiguity = ZoneWithAmbiguity.LateInterval;

// Time zone with an ambiguity
@Test()
void ZoneWithAmbiguity_NearStartOfTime()
{
  var mapping = ZoneWithAmbiguity.MapLocal(new LocalDateTime.fromYMDHM(-9998, 1, 5, 0, 0));
  CheckMapping(mapping, IntervalBeforeAmbiguity, IntervalBeforeAmbiguity, 1);
}

@Test()
void ZoneWithAmbiguity_NearEndOfTime()
{
  var mapping = ZoneWithAmbiguity.MapLocal(NearEndOfTime);
  CheckMapping(mapping, IntervalAfterAmbiguity, IntervalAfterAmbiguity, 1);
}

@Test()
void ZoneWithAmbiguity_WellBeforeTransition()
{
  var mapping = ZoneWithAmbiguity.MapLocal(YearBeforeTransition);
  CheckMapping(mapping, IntervalBeforeAmbiguity, IntervalBeforeAmbiguity, 1);
}

@Test()
void ZoneWithAmbiguity_WellAfterTransition()
{
  var mapping = ZoneWithAmbiguity.MapLocal(YearAfterTransition);
  CheckMapping(mapping, IntervalAfterAmbiguity, IntervalAfterAmbiguity, 1);
}

@Test()
void ZoneWithAmbiguity_JustBeforeAmbiguity()
{
  var mapping = ZoneWithAmbiguity.MapLocal(TransitionMinus5.PlusNanoseconds(-1));
  CheckMapping(mapping, IntervalBeforeAmbiguity, IntervalBeforeAmbiguity, 1);
}

@Test()
void ZoneWithAmbiguity_JustAfterTransition()
{
  var mapping = ZoneWithAmbiguity.MapLocal(TransitionPlus10.PlusNanoseconds(1));
  CheckMapping(mapping, IntervalAfterAmbiguity, IntervalAfterAmbiguity, 1);
}

@Test()
void ZoneWithAmbiguity_StartOfTransition()
{
  var mapping = ZoneWithAmbiguity.MapLocal(TransitionMinus5);
  CheckMapping(mapping, IntervalBeforeAmbiguity, IntervalAfterAmbiguity, 2);
}

@Test()
void ZoneWithAmbiguity_MidTransition()
{
  var mapping = ZoneWithAmbiguity.MapLocal(MidTransition);
  CheckMapping(mapping, IntervalBeforeAmbiguity, IntervalAfterAmbiguity, 2);
}

@Test()
void ZoneWithAmbiguity_LastTickOfTransition()
{
  var mapping = ZoneWithAmbiguity.MapLocal(TransitionPlus10.PlusNanoseconds(-1));
  CheckMapping(mapping, IntervalBeforeAmbiguity, IntervalAfterAmbiguity, 2);
}

@Test()
void ZoneWithAmbiguity_FirstTickAfterTransition()
{
  var mapping = ZoneWithAmbiguity.MapLocal(TransitionPlus10);
  CheckMapping(mapping, IntervalAfterAmbiguity, IntervalAfterAmbiguity, 1);
}

// Time zone with a gap
@Test()
void ZoneWithGap_NearStartOfTime()
{
  var mapping = ZoneWithGap.MapLocal(NearStartOfTime);
  CheckMapping(mapping, IntervalBeforeGap, IntervalBeforeGap, 1);
}

@Test()
void ZoneWithGap_NearEndOfTime()
{
  var mapping = ZoneWithGap.MapLocal(NearEndOfTime);
  CheckMapping(mapping, IntervalAfterGap, IntervalAfterGap, 1);
}

@Test()
void ZoneWithGap_WellBeforeTransition()
{
  var mapping = ZoneWithGap.MapLocal(YearBeforeTransition);
  CheckMapping(mapping, IntervalBeforeGap, IntervalBeforeGap, 1);
}

@Test()
void ZoneWithGap_WellAfterTransition()
{
  var mapping = ZoneWithGap.MapLocal(YearAfterTransition);
  CheckMapping(mapping, IntervalAfterGap, IntervalAfterGap, 1);
}

@Test()
void ZoneWithGap_JustBeforeGap()
{
  var mapping = ZoneWithGap.MapLocal(TransitionMinus5.PlusNanoseconds(-1));
  CheckMapping(mapping, IntervalBeforeGap, IntervalBeforeGap, 1);
}

@Test()
void ZoneWithGap_JustAfterTransition()
{
  var mapping = ZoneWithGap.MapLocal(TransitionPlus10.PlusNanoseconds(1));
  CheckMapping(mapping, IntervalAfterGap, IntervalAfterGap, 1);
}

@Test()
void ZoneWithGap_StartOfTransition()
{
  var mapping = ZoneWithGap.MapLocal(TransitionMinus5);
  CheckMapping(mapping, IntervalBeforeGap, IntervalAfterGap, 0);
}

@Test()
void ZoneWithGap_MidTransition()
{
  var mapping = ZoneWithGap.MapLocal(MidTransition);
  CheckMapping(mapping, IntervalBeforeGap, IntervalAfterGap, 0);
}

@Test()
void ZoneWithGap_LastTickOfTransition()
{
  var mapping = ZoneWithGap.MapLocal(TransitionPlus10.PlusNanoseconds(-1));
  CheckMapping(mapping, IntervalBeforeGap, IntervalAfterGap, 0);
}

@Test()
void ZoneWithGap_FirstTickAfterTransition()
{
  var mapping = ZoneWithGap.MapLocal(TransitionPlus10);
  CheckMapping(mapping, IntervalAfterGap, IntervalAfterGap, 1);
}

/// Case added to cover everything: we want our initial guess to hit the
/// *later* zone, which doesn't actually include the local instant. However,
/// we want the *earlier* zone to include it. So, we want a zone with two
/// positive offsets.
@Test()
void TrickyCase()
{
  // 1am occurs unambiguously in the early zone.
  var zone = new SingleTransitionDateTimeZone(Transition, new Offset.fromHours(3), new Offset.fromHours(5));
  var mapping = zone.MapLocal(new LocalDateTime.fromYMDHM(2000, 1, 1, 1, 0));
  CheckMapping(mapping, zone.EarlyInterval, zone.EarlyInterval, 1);
}

void CheckMapping(ZoneLocalMapping mapping, ZoneInterval earlyInterval, ZoneInterval lateInterval, int count)
{
  expect(earlyInterval, mapping.EarlyInterval);
  expect(lateInterval, mapping.LateInterval);
  expect(count, mapping.Count);
}



