// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/CachingZoneIntervalMap.cs
// 16aacad  on Aug 26, 2017

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

/// <summary>
/// Helper methods for creating IZoneIntervalMaps which cache results.
/// </summary>
@internal abstract class CachingZoneIntervalMap
{
  // Currently the only implementation is HashArrayCache. This container class is mostly for historical
  // reasons; it's not really necessary but it does no harm.

  /// <summary>
  /// Returns a caching map for the given input map.
  /// </summary>
  @internal static IZoneIntervalMap CacheMap(IZoneIntervalMap map)
  {
    return new HashArrayCache(map);
  }
}

// #region Nested type: HashArrayCache
/// <summary>
/// This provides a simple cache based on two hash tables (one for local instants, another
/// for instants).
/// </summary>
/// <remarks>
/// Each hash table entry is either entry or contains a node with enough
/// information for a particular "period" of 32 days - so multiple calls for time
/// zone information within the same few years are likely to hit the cache. Note that
/// a single "period" may include a daylight saving change (or conceivably more than one);
/// a node therefore has to contain enough intervals to completely represent that period.
///
/// If another call is made which maps to the same cache entry number but is for a different
/// period, the existing hash entry is simply overridden.
/// </remarks>
// sealed
@private class HashArrayCache implements IZoneIntervalMap {
  // Currently we have no need or way to create hash cache zones with
  // different cache sizes. But the cache size should always be a power of 2 to get the
  // "period to cache entry" conversion simply as a bitmask operation.
  @private static const int CacheSize = 512;

  // Mask to AND the period number with in order to get the cache entry index. The
  // result will always be in the range [0, CacheSize).
  @private static const int CachePeriodMask = CacheSize - 1;

  /// <summary>
  /// Defines the number of bits to shift an instant's "days since epoch" to get the period. This
  /// converts an instant into a number of 32 day periods.
  /// </summary>
  @private static const int PeriodShift = 5;

  @private final List<HashCacheNode> instantCache = new List<HashCacheNode>(CacheSize);
  @private final IZoneIntervalMap map;

  @internal HashArrayCache(this.map) {
    Preconditions.checkNotNull(map, 'map');
    // instantCache = new HashCacheNode[CacheSize];
  }

  /// <summary>
  /// Gets the zone offset period for the given instant. Null is returned if no period is
  /// defined by the time zone for the given instant.
  /// </summary>
  /// <param name="instant">The Instant to test.</param>
  /// <returns>The defined ZoneOffsetPeriod or null.</returns>
  ZoneInterval GetZoneInterval(Instant instant) {
    int period = instant.daysSinceEpoch >> PeriodShift;
    int index = period & CachePeriodMask;
    var node = instantCache[index];
    if (node == null || node.Period != period) {
      node = HashCacheNode.CreateNode(period, map);
      instantCache[index] = node;
    }

    // Note: moving this code into an instance method in HashCacheNode makes a surprisingly
    // large performance difference.
    while (node.Previous != null && node.Interval.RawStart > instant) {
      node = node.Previous;
    }
    return node.Interval;
  }
}

// #region Nested type: HashCacheNode
// Note: I (Jon) have tried optimizing this as a struct containing two ZoneIntervals
// and a list of zone intervals (normally null) for the rare case where there are more
// than two zone intervals in a period. It halved the performance...
// sealed
@private class HashCacheNode {
  @internal final ZoneInterval Interval;

  @internal final int Period;

  @internal final HashCacheNode Previous;

  /// <summary>
  /// Creates a hash table node with all the information for this period.
  /// We start off by finding the interval for the start of the period, and
  /// then repeatedly check whether that interval ends after the end of the
  /// period - at which point we're done. If not, find the next interval, create
  /// a new node referring to that interval and the previous interval, and keep going.
  /// </summary>
  @internal static HashCacheNode CreateNode(int period, IZoneIntervalMap map) {
    var days = period << PeriodShift;
    var periodStart = new Instant.untrusted(new Span(days: math.max(days, Instant.minDays)));
    var nextPeriodStartDays = days + (1 << PeriodShift);

    var interval = map.GetZoneInterval(periodStart);
    var node = new HashCacheNode(interval, period, null);

    // Keep going while the current interval ends before the period.
    // (We only need to check the days, as every period lands on a
    // day boundary.)
    // If the raw end is the end of time, the condition will definitely
    // evaluate to false.
    while (interval.RawEnd.daysSinceEpoch < nextPeriodStartDays) {
      interval = map.GetZoneInterval(interval.end);
      node = new HashCacheNode(interval, period, node);
    }

    return node;
  }

  /// <summary>
  /// Initializes a new instance of the <see cref="HashCacheNode"/> class.
  /// </summary>
  /// <param name="interval">The zone interval.</param>
  /// <param name="period"></param>
  /// <param name="previous">The previous <see cref="HashCacheNode"/> node.</param>
  @private HashCacheNode(this.Interval, this.Period, this.Previous);
}
