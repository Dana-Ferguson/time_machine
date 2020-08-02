// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
// import 'package:matcher/matcher.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

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

final Instant Transition = Instant.utc(2000, 1, 1, 0, 0);

final Offset Minus5 = Offset.hours(-5);
final Offset Plus10 = Offset.hours(10);

final LocalDateTime NearStartOfTime = LocalDateTime(-9998, 1, 5, 0, 0, 0);
final LocalDateTime NearEndOfTime = LocalDateTime(9999, 12, 25, 0, 0, 0);
final LocalDateTime TransitionMinus5 = Transition.withOffset(Minus5).localDateTime;
final LocalDateTime TransitionPlus10 = Transition.withOffset(Plus10).localDateTime;
final LocalDateTime MidTransition = Transition.withOffset(Offset.zero).localDateTime;

final LocalDateTime YearBeforeTransition = LocalDateTime(1999, 1, 1, 0, 0, 0);
final LocalDateTime YearAfterTransition = LocalDateTime(2001, 1, 1, 0, 0, 0);

final SingleTransitionDateTimeZone ZoneWithGap = SingleTransitionDateTimeZone(Transition, Minus5, Plus10);
final ZoneInterval IntervalBeforeGap = ZoneWithGap.EarlyInterval;
final ZoneInterval IntervalAfterGap = ZoneWithGap.LateInterval;

final SingleTransitionDateTimeZone ZoneWithAmbiguity = SingleTransitionDateTimeZone(Transition, Plus10, Minus5);
final ZoneInterval IntervalBeforeAmbiguity = ZoneWithAmbiguity.EarlyInterval;
final ZoneInterval IntervalAfterAmbiguity = ZoneWithAmbiguity.LateInterval;

// Time zone with an ambiguity
@Test()
void ZoneWithAmbiguity_NearStartOfTime()
{
  var mapping = ZoneWithAmbiguity.mapLocal(LocalDateTime(-9998, 1, 5, 0, 0, 0));
  CheckMapping(mapping, IntervalBeforeAmbiguity, IntervalBeforeAmbiguity, 1);
}

@Test()
void ZoneWithAmbiguity_NearEndOfTime()
{
  var mapping = ZoneWithAmbiguity.mapLocal(NearEndOfTime);
  CheckMapping(mapping, IntervalAfterAmbiguity, IntervalAfterAmbiguity, 1);
}

@Test()
void ZoneWithAmbiguity_WellBeforeTransition()
{
  var mapping = ZoneWithAmbiguity.mapLocal(YearBeforeTransition);
  CheckMapping(mapping, IntervalBeforeAmbiguity, IntervalBeforeAmbiguity, 1);
}

@Test()
void ZoneWithAmbiguity_WellAfterTransition()
{
  var mapping = ZoneWithAmbiguity.mapLocal(YearAfterTransition);
  CheckMapping(mapping, IntervalAfterAmbiguity, IntervalAfterAmbiguity, 1);
}

@Test()
void ZoneWithAmbiguity_JustBeforeAmbiguity()
{
  var mapping = ZoneWithAmbiguity.mapLocal(TransitionMinus5.addNanoseconds(-1));
  CheckMapping(mapping, IntervalBeforeAmbiguity, IntervalBeforeAmbiguity, 1);
}

@Test()
void ZoneWithAmbiguity_JustAfterTransition()
{
  var mapping = ZoneWithAmbiguity.mapLocal(TransitionPlus10.addNanoseconds(1));
  CheckMapping(mapping, IntervalAfterAmbiguity, IntervalAfterAmbiguity, 1);
}

@Test()
void ZoneWithAmbiguity_StartOfTransition()
{
  var mapping = ZoneWithAmbiguity.mapLocal(TransitionMinus5);
  CheckMapping(mapping, IntervalBeforeAmbiguity, IntervalAfterAmbiguity, 2);
}

@Test()
void ZoneWithAmbiguity_MidTransition()
{
  var mapping = ZoneWithAmbiguity.mapLocal(MidTransition);
  CheckMapping(mapping, IntervalBeforeAmbiguity, IntervalAfterAmbiguity, 2);
}

@Test()
void ZoneWithAmbiguity_LastTickOfTransition()
{
  var mapping = ZoneWithAmbiguity.mapLocal(TransitionPlus10.addNanoseconds(-1));
  CheckMapping(mapping, IntervalBeforeAmbiguity, IntervalAfterAmbiguity, 2);
}

@Test()
void ZoneWithAmbiguity_FirstTickAfterTransition()
{
  var mapping = ZoneWithAmbiguity.mapLocal(TransitionPlus10);
  CheckMapping(mapping, IntervalAfterAmbiguity, IntervalAfterAmbiguity, 1);
}

// Time zone with a gap
@Test()
void ZoneWithGap_NearStartOfTime()
{
  var mapping = ZoneWithGap.mapLocal(NearStartOfTime);
  CheckMapping(mapping, IntervalBeforeGap, IntervalBeforeGap, 1);
}

@Test()
void ZoneWithGap_NearEndOfTime()
{
  var mapping = ZoneWithGap.mapLocal(NearEndOfTime);
  CheckMapping(mapping, IntervalAfterGap, IntervalAfterGap, 1);
}

@Test()
void ZoneWithGap_WellBeforeTransition()
{
  var mapping = ZoneWithGap.mapLocal(YearBeforeTransition);
  CheckMapping(mapping, IntervalBeforeGap, IntervalBeforeGap, 1);
}

@Test()
void ZoneWithGap_WellAfterTransition()
{
  var mapping = ZoneWithGap.mapLocal(YearAfterTransition);
  CheckMapping(mapping, IntervalAfterGap, IntervalAfterGap, 1);
}

@Test()
void ZoneWithGap_JustBeforeGap()
{
  var mapping = ZoneWithGap.mapLocal(TransitionMinus5.addNanoseconds(-1));
  CheckMapping(mapping, IntervalBeforeGap, IntervalBeforeGap, 1);
}

@Test()
void ZoneWithGap_JustAfterTransition()
{
  var mapping = ZoneWithGap.mapLocal(TransitionPlus10.addNanoseconds(1));
  CheckMapping(mapping, IntervalAfterGap, IntervalAfterGap, 1);
}

@Test()
void ZoneWithGap_StartOfTransition()
{
  var mapping = ZoneWithGap.mapLocal(TransitionMinus5);
  CheckMapping(mapping, IntervalBeforeGap, IntervalAfterGap, 0);
}

@Test()
void ZoneWithGap_MidTransition()
{
  var mapping = ZoneWithGap.mapLocal(MidTransition);
  CheckMapping(mapping, IntervalBeforeGap, IntervalAfterGap, 0);
}

@Test()
void ZoneWithGap_LastTickOfTransition()
{
  var mapping = ZoneWithGap.mapLocal(TransitionPlus10.addNanoseconds(-1));
  CheckMapping(mapping, IntervalBeforeGap, IntervalAfterGap, 0);
}

@Test()
void ZoneWithGap_FirstTickAfterTransition()
{
  var mapping = ZoneWithGap.mapLocal(TransitionPlus10);
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
  var zone = SingleTransitionDateTimeZone(Transition, Offset.hours(3), Offset.hours(5));
  var mapping = zone.mapLocal(LocalDateTime(2000, 1, 1, 1, 0, 0));
  CheckMapping(mapping, zone.EarlyInterval, zone.EarlyInterval, 1);
}

void CheckMapping(ZoneLocalMapping mapping, ZoneInterval earlyInterval, ZoneInterval lateInterval, int count)
{
  expect(earlyInterval, mapping.earlyInterval);
  expect(lateInterval, mapping.lateInterval);
  expect(count, mapping.count);
}



