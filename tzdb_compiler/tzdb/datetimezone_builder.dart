import 'package:time_machine/src/time_machine_internal.dart';

import 'zone_rule_set.dart';
import 'zone_transition.dart';

T? lastOrDefault<T>(Iterable<T> iterable) {
  if (iterable.isEmpty) return null;
  return iterable.last;
}

/// Mutable class with only a static entry point, which converts and ID + sequence of ZoneRuleSet
/// elements into a DateTimeZone.
// todo: internal sealed
class DateTimeZoneBuilder
{
  final List<ZoneInterval> _zoneIntervals = [];
  StandardDaylightAlternatingMap? _tailZone;

  DateTimeZoneBuilder._();

  /// Builds a time zone with the given ID from a sequence of rule sets.
  static DateTimeZone build(String id, List<ZoneRuleSet> ruleSets)
  {
    Preconditions.checkArgument(ruleSets.isNotEmpty, 'ruleSets', 'Cannot create a time zone without any Zone entries');
    var builder = DateTimeZoneBuilder._();
    return builder._buildZone(id, ruleSets);
  }

  DateTimeZone _buildZone(String id, List<ZoneRuleSet> ruleSets)
  {
    // This does most of the work: for each rule set (corresponding to a zone line
    // in the original data) we add some zone intervals.
    for (var ruleSet in ruleSets)
    {
      _addIntervals(ruleSet);
    }

    // Some of the abutting zone intervals from the rule set boundaries may have the
    // same offsets and name, in which case  they can be coalesced.
    _coalesceIntervals();

    // Finally, construct the time zone itself. Usually, we'll end up with a
    // PrecalculatedDateTimeZone here.
    if (_zoneIntervals.length == 1 && _tailZone == null)
    {
      return FixedDateTimeZone(id, _zoneIntervals[0].wallOffset, _zoneIntervals[0].name);
    }
    else
    {
      return PrecalculatedDateTimeZone(id, _zoneIntervals.toList(), _tailZone);
    }
  }

  /// Adds the intervals from the given rule set to the end of the zone
  /// being built. The rule is deemed to take effect from the end of the previous
  /// zone interval, or the start of time if this is the first rule set (which must
  /// be a fixed one). Intervals are added until the rule set expires, or
  /// until we determine that the rule set continues to the end of time,
  /// possibly with a tail zone - a pair of standard/daylight rules which repeat
  /// forever.
  void _addIntervals(ZoneRuleSet ruleSet) {
    // We use the last zone interval computed so far (if there is one) to work out where to start.
    var lastZoneInterval = _zoneIntervals.isEmpty ? null : _zoneIntervals.last;
    var start = lastZoneInterval?.end ?? IInstant.beforeMinValue;

    // Simple case: a zone line with fixed savings (or - for 0)
    // instead of a rule name. Just a single interval.
    if (ruleSet.isFixed) {
      _zoneIntervals.add(ruleSet.CreateFixedInterval(start));
      return;
    }

    // Work on a copy of the rule set. We eliminate rules from it as they expire,
    // so that we can tell when we're down to an infinite pair which can be represented
    // as a tail zone.
    var activeRules = List<ZoneRecurrence>.from(ruleSet.rules);

    // Surprisingly tricky bit to work out: how to handle the transition from
    // one rule set to another. We know the instant at which the new rule set
    // come in, but not what offsets/name to use from that point onwards: which
    // of the new rules is in force. We find out which rule would have taken
    // effect most recently before or on the transition instant - but using
    // the offsets from the final interval before the transition, instead
    // of the offsets which would have been in force if the new rule set were
    // actually extended backwards forever.
    //
    // It's possible that the most recent transition we find would actually
    // have started before that final interval anyway - but this appears to
    // match what zic produces.
    //
    // If we don't have a zone interval at all, we're starting at the start of
    // time, so there definitely aren't any preceding rules.
    var firstRule = lastZoneInterval == null ? null :
    lastOrDefault((activeRules
        .map((rule) =>
    // todo: object literals??? or something??? looks like a huge Dart Weakness ~ this causes a lot of Type Inference weaknesses
    {
      'rule': rule,
      'prev': rule.previousOrSame(start, lastZoneInterval.standardOffset, lastZoneInterval.savings)
    })
        .where((pair) => pair['prev'] != null).toList()
      ..sort((a, b) => (a['prev'] as Transition).instant.compareTo((b['prev'] as Transition).instant)))
      .map((pair) => pair['rule'] as ZoneRecurrence));

    // .orderBy((pair) => pair.prev.Value.Instant)
    //.select((pair) => pair.rule)
    // .lastOrDefault();

    // Every transition in this rule set will use the same standard offset.
    var standardOffset = ruleSet.standardOffset;

    // previousTransition here is ongoing as we loop through the transitions. It's not like
    // lastZoneInterval, lastStandard and lastSavings, which refer to the last aspects of the
    // previous rule set. When we set it up, this is effectively the *first* transition leading
    // into the period in which the new rule set is
    ZoneTransition previousTransition;
    if (firstRule != null) {
      previousTransition = ZoneTransition(start, firstRule.name, standardOffset, firstRule.savings);
    }
    else {
      // None of the rules in the current set have *any* transitions in the past, apparently.
      // For an example of this, see Europe/Prague (in 2015e, anyway). A zone line with the
      // Czech rule takes effect in 1944, but all the rules are from 1945 onwards.
      // Use standard time until the first transition, regardless of the previous savings,
      // and take the name for this first interval from the first standard time rule.
      var name = activeRules
          .firstWhere((rule) => rule.savings == Offset.zero)
          .name;
      previousTransition = ZoneTransition(start, name, standardOffset, Offset.zero);
    }

    // Main loop - we keep going round until we run out of rules or hit infinity, each of which
    // corresponds with a return statement in the loop.
    while (true) {
      ZoneTransition? bestTransition;
      for (int i = 0; i < activeRules.length; i++) {
        var rule = activeRules[i];
        var nextTransition = rule.next(previousTransition.instant, standardOffset, previousTransition.savings);
        // Once a rule is no longer active, remove it from the list. That way we can tell
        // when we can create a tail zone.
        if (nextTransition == null) {
          activeRules.removeAt(i);
          i--;
          continue;
        }
        var zoneTransition = ZoneTransition(nextTransition.instant, rule.name, standardOffset, rule.savings);
        if (!zoneTransition.isTransitionFrom(previousTransition)) {
          continue;
        }
        if (bestTransition == null || zoneTransition.instant <= bestTransition.instant) {
          bestTransition = zoneTransition;
        }
      }
      Instant currentUpperBound = ruleSet.GetUpperLimit(previousTransition.savings);
      if (bestTransition == null || bestTransition.instant >= currentUpperBound) {
        // No more transitions to find. (We may have run out of rules, or they may be beyond where this rule set expires.)
        // Add a final interval leading up to the upper bound of the rule set, unless the previous transition took us up to
        // this current bound anyway.
        // (This is very rare, but can happen if changing rule brings the upper bound down to the time
        // that the transition occurred. Example: 2008d, Europe/Sofia, April 1945.)
        if (currentUpperBound > previousTransition.instant) {
          _zoneIntervals.add(previousTransition.toZoneInterval(currentUpperBound));
        }
        return;
      }

      // We have a non-final transition. so add an interval from the previous transition to
      // this one.
      _zoneIntervals.add(previousTransition.toZoneInterval(bestTransition.instant));
      previousTransition = bestTransition;

      // Tail zone handling.
      // The final rule set must extend to infinity. There are potentially three ways
      // this can happen:
      // - All rules expire, leaving us with the final real transition, and an upper
      //   bound of infinity. This is handled above.
      // - 1 rule is left, but it cannot create more than one transition in a row,
      //   so again we end up with no transitions to record, and we bail out with
      //   a final infinite interval.
      // - 2 rules are left which would alternate infinitely. This is represented
      //   using a DaylightSavingZone as the tail zone.
      //
      // The code here caters for that last option, but needs to do it in stages.
      // When we first realize we will have a tail zone (an infinite rule set,
      // two rules left, both of which are themselves infinite) we can create the
      // tail zone, but we don't yet know that we're into its regular tick/tock.
      // It's possible that one rule only starts years after our current transition,
      // so we need to hit the first transition of that rule before we can create a
      // 'seam' from the list of precomputed zone intervals to the calculated-on-demand
      // part of history.
      // For an example of why this is necessary, see Asia/Amman in 2013e: in late 2011
      // we hit 'two rules left' but the final rule only starts in 2013 - we don't want
      // to see a bogus transition into that rule in 2012.
      // We could potentially record fewer zone intervals by keeping track of which
      // rules have created at least one transition, but this approach is simpler.
      if (ruleSet.isInfinite && activeRules.length == 2) {
        if (_tailZone != null) {
          // Phase two: both rules must now be active, so we're done.
          return;
        }
        ZoneRecurrence startRule = activeRules[0];
        ZoneRecurrence endRule = activeRules[1];
        if (startRule.isInfinite && endRule.isInfinite) {
          // Phase one: build the zone, so we can go round once again and then return.
          _tailZone = StandardDaylightAlternatingMap(standardOffset, startRule, endRule);
        }
      }
    }
  }


  /// <summary>
  /// Potentially join some abutting zone intervals, usually created
  /// due to the interval at the end of one rule set having the same name and offsets
  /// as the interval at the start of the next rule set.
  /// </summary>
  void _coalesceIntervals()
  {
    for (int i = 0; i < _zoneIntervals.length - 1; i++)
    {
      var current = _zoneIntervals[i];
      var next = _zoneIntervals[i + 1];
      if (current.name == next.name &&
          current.wallOffset == next.wallOffset &&
          current.standardOffset == next.standardOffset)
      {
        _zoneIntervals[i] = IZoneInterval.withEnd(current, IZoneInterval.rawEnd(next))!;
        _zoneIntervals.removeAt(i + 1);
        i--; // We may need to coalesce the next one, too.
      }
    }
  }
}
