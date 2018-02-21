// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/PartialZoneIntervalMap.cs
// 747ec41  on Feb 26, 2017

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

/// <summary>
/// Like ZoneIntervalMap, representing just part of the time line. The intervals returned by this map
/// are clamped to the portion of the time line being represented, to make it easier to work with.
/// </summary>
// sealed 
@internal class PartialZoneIntervalMap
{
  @private final IZoneIntervalMap map;

  /// <summary>
  /// Start of the interval during which this map is valid.
  /// </summary>
  @internal final Instant Start;

  /// <summary>
  /// End (exclusive) of the interval during which this map is valid.
  /// </summary>
  @internal final Instant End;

  @internal PartialZoneIntervalMap(this.Start, this.End, this.map)
  {
    // Allowing empty maps makes life simpler.
    // TODO(misc): Does it really? It's a pain in some places...
    Preconditions.debugCheckArgument(Start <= End, 'end',
        "Invalid start/end combination: $Start - $End");
  }

  /// <summary>
  /// Builds a PartialZoneIntervalMap for a single zone interval with the given name, start, end, wall offset and daylight savings.
  /// </summary>
  @internal static PartialZoneIntervalMap ForZoneInterval_NewZone(String name, Instant start, Instant end, Offset wallOffset, Offset savings) =>
      ForZoneInterval(new ZoneInterval(name, start, end, wallOffset, savings));

  /// <summary>
  /// Builds a PartialZoneIntervalMap wrapping the given zone interval, taking its start and end as the start and end of
  /// the portion of the time line handled by the partial map.
  /// </summary> // todo: name?
  @internal static PartialZoneIntervalMap ForZoneInterval(ZoneInterval interval) =>
      new PartialZoneIntervalMap(interval.RawStart, interval.RawEnd, new SingleZoneIntervalMap(interval));

  @internal ZoneInterval GetZoneInterval(Instant instant)
  {
    Preconditions.debugCheckArgument(instant >= Start && instant < End, 'instant',
        "Value $instant was not in the range [$Start, $End)");
    var interval = map.GetZoneInterval(instant);
    // Clamp the interval for the sake of sanity. Checking this every time isn't very efficient,
    // but we're not expecting this to be called too often, due to caching.
    if (interval.RawStart < Start)
    {
      interval = interval.WithStart(Start);
    }
    if (interval.RawEnd > End)
    {
      interval = interval.WithEnd(End);
    }
    return interval;
  }

  /// <summary>
  /// Returns true if this map only contains a single interval; that is, if the first interval includes the end of the map.
  /// </summary>
  @private bool get IsSingleInterval => map.GetZoneInterval(Start).RawEnd >= End;

  /// <summary>
  /// Returns a partial zone interval map equivalent to this one, but with the given start point.
  /// </summary>
  @internal PartialZoneIntervalMap WithStart(Instant start)
  {
    return new PartialZoneIntervalMap(start, this.End, this.map);
  }

  /// <summary>
  /// Returns a partial zone interval map equivalent to this one, but with the given end point.
  /// </summary>
  @internal PartialZoneIntervalMap WithEnd(Instant end)
  {
    return new PartialZoneIntervalMap(this.Start, end, this.map);
  }

  /// <summary>
  /// Converts a sequence of PartialZoneIntervalMaps covering the whole time line into an IZoneIntervalMap.
  /// The partial maps are expected to be in order, with the start of the first map being Instant.BeforeMinValue,
  /// the end of the last map being Instant.AfterMaxValue, and each adjacent pair of maps abutting (i.e. current.End == next.Start).
  /// Zone intervals belonging to abutting maps but which are equivalent in terms of offset and name
  /// are coalesced in the resulting map.
  /// </summary>
  @internal static IZoneIntervalMap ConvertToFullMap(Iterable<PartialZoneIntervalMap> maps)
  {
    var coalescedMaps = new List<PartialZoneIntervalMap>();
    PartialZoneIntervalMap current = null;
    for (var next in maps)
    {
      if (current == null)
      {
        current = next;
        Preconditions.debugCheckArgument(current.Start == Instant.beforeMinValue, "maps", "First partial map must start at the beginning of time");
        continue;
      }
      Preconditions.debugCheckArgument(current.End == next.Start, "maps", "Maps must abut");

      if (next.Start == next.End)
      {
        continue;
      }

      var lastIntervalOfCurrent = current.GetZoneInterval(current.End - Span.epsilon);
      var firstIntervalOfNext = next.GetZoneInterval(next.Start);

      if (!lastIntervalOfCurrent.EqualIgnoreBounds(firstIntervalOfNext))
      {
        // There's a genuine transition at the boundary of the partial maps. Add the current one, and move on
        // to the next.
        coalescedMaps.add(current);
        current = next;
      }
      else
      {
        // The boundary belongs to a single zone interval crossing the two maps. Some coalescing to do.

        // If both the current and the next map are single zone interval maps, we can just make the current one
        // go on until the end of the next one instead.
        if (current.IsSingleInterval && next.IsSingleInterval)
        {
          current = ForZoneInterval(lastIntervalOfCurrent.WithEnd(next.End));
        }
        else if (current.IsSingleInterval)
        {
          // The next map has at least one transition. Add a single new map for the portion of time from the
          // start of current to the first transition in next, then continue on with the next map, starting at the first transition.
          coalescedMaps.add(ForZoneInterval(lastIntervalOfCurrent.WithEnd(firstIntervalOfNext.end)));
          current = next.WithStart(firstIntervalOfNext.end);
        }
        else if (next.IsSingleInterval)
        {
          // The current map as at least one transition. Add a version of that, clamped to end at the final transition,
          // then continue with a new map which takes in the last portion of the current and the whole of next.
          coalescedMaps.add(current.WithEnd(lastIntervalOfCurrent.start));
          current = ForZoneInterval(firstIntervalOfNext.WithStart(lastIntervalOfCurrent.start));
        }
        else
        {
          // Transitions in both maps. Add the part of current before the last transition, and a single map containing
          // the coalesced interval across the boundary, then continue with the next map, starting at the first transition.
          coalescedMaps.add(current.WithEnd(lastIntervalOfCurrent.start));
          coalescedMaps.add(ForZoneInterval(lastIntervalOfCurrent.WithEnd(firstIntervalOfNext.end)));
          current = next.WithStart(firstIntervalOfNext.end);
        }
      }
    }
    Preconditions.debugCheckArgument(current != null, "maps", "Collection of maps must not be empty");
    Preconditions.debugCheckArgument(current.End == Instant.afterMaxValue, "maps", "Collection of maps must end at the end of time");

    // We're left with a map extending to the end of time, which couldn't have been coalesced with its predecessors.
    coalescedMaps.add(current);
    return new _CombinedPartialZoneIntervalMap(coalescedMaps.toList());
  }
}

/// <summary>
/// Implementation of IZoneIntervalMap used by ConvertToFullMap
/// </summary>
class _CombinedPartialZoneIntervalMap implements IZoneIntervalMap {
  @private final List<PartialZoneIntervalMap> partialMaps;

  @internal _CombinedPartialZoneIntervalMap(this.partialMaps);

  ZoneInterval GetZoneInterval(Instant instant) {
    // We assume the maps are ordered, and start with "beginning of time"
    // which means we only need to find the first partial map which ends after
    // the instant we're interested in. This is just a linear search - a binary search
    // would be feasible, but we're not expecting very many entries.
    for (var partialMap in partialMaps) {
      if (instant < partialMap.End) {
        return partialMap.GetZoneInterval(instant);
      }
    }
    throw new StateError("Instant not contained in any map");
  }
}