// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:math' as math;

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

/// Helper methods for creating IZoneIntervalMaps which cache results.
@internal
abstract class CachingZoneIntervalMap
{
// Currently the only implementation is HashArrayCache. This container class is mostly for historical
// reasons; it's not really necessary but it does no harm.

  /// Returns a caching map for the given input map.
  static ZoneIntervalMap cacheMap(ZoneIntervalMap map)
  {
    return _HashArrayCache(map);
  }
}

// #region Nested type: HashArrayCache
/// This provides a simple cache based on two hash tables (one for local instants, another
/// for instants).
///
/// Each hash table entry is either entry or contains a node with enough
/// information for a particular 'period' of 32 days - so multiple calls for time
/// zone information within the same few years are likely to hit the cache. Note that
/// a single 'period' may include a daylight saving change (or conceivably more than one);
/// a node therefore has to contain enough intervals to completely represent that period.
///
/// If another call is made which maps to the same cache entry number but is for a different
/// period, the existing hash entry is simply overridden.
// sealed
class _HashArrayCache implements ZoneIntervalMap {
  // Currently we have no need or way to create hash cache zones with
  // different cache sizes. But the cache size should always be a power of 2 to get the
  // 'period to cache entry' conversion simply as a bitmask operation.
  static const int _cacheSize = 512;

  // Mask to AND the period number with in order to get the cache entry index. The
  // result will always be in the range [0, CacheSize).
  static const int _cachePeriodMask = _cacheSize - 1;

  /// Defines the number of bits to shift an instant's "days since epoch" to get the period. This
  /// converts an instant into a number of 32 day periods.
  static const int _periodShift = 5;

  final List<_HashCacheNode?> _instantCache = List<_HashCacheNode?>.filled(_cacheSize, null);
  final ZoneIntervalMap _map;

  _HashArrayCache(this._map) {
    Preconditions.checkNotNull(_map, 'map');
  // instantCache = new HashCacheNode[CacheSize];
  }

  /// Gets the zone offset period for the given instant. Null is returned if no period is
  /// defined by the time zone for the given instant.
  ///
  /// [instant]: The Instant to test.
  /// Returns: The defined ZoneOffsetPeriod or null.
  @override
  ZoneInterval getZoneInterval(Instant instant) {
    int period = safeRightShift(instant.epochDay, _periodShift);
    int index = period & _cachePeriodMask;
    _HashCacheNode? cachedNode = _instantCache[index];
    _HashCacheNode node;
    if (cachedNode == null || cachedNode.period != period) {
      node = _HashCacheNode.createNode(period, _map);
      _instantCache[index] = node;
    } else {
      node = cachedNode;
    }

    // Note: moving this code into an instance method in HashCacheNode makes a surprisingly
    // large performance difference.
    while (node.previous != null && IZoneInterval.rawStart(node.interval) > instant) {
      node = node.previous!;
    }
    return node.interval;
  }
}

// #region Nested type: HashCacheNode
// Note: I (Jon) have tried optimizing this as a struct containing two ZoneIntervals
// and a list of zone intervals (normally null) for the rare case where there are more
// than two zone intervals in a period. It halved the performance...
// sealed
class _HashCacheNode {
  final ZoneInterval interval;

  final int period;

  final _HashCacheNode? previous;

  /// Creates a hash table node with all the information for this period.
  /// We start off by finding the interval for the start of the period, and
  /// then repeatedly check whether that interval ends after the end of the
  /// period - at which point we're done. If not, find the next interval, create
  /// a new node referring to that interval and the previous interval, and keep going.
  static _HashCacheNode createNode(int period, ZoneIntervalMap map) {
    // todo: does this need to be a safe shift?
    var days = period << _HashArrayCache._periodShift;
    var periodStart = IInstant.untrusted(Time(days: math.max(days, IInstant.minDays)));
    var nextPeriodStartDays = days + (1 << _HashArrayCache._periodShift);

    var interval = map.getZoneInterval(periodStart);
    var node = _HashCacheNode(interval, period, null);

    // Keep going while the current interval ends before the period.
    // (We only need to check the days, as every period lands on a
    // day boundary.)
    // If the raw end is the end of time, the condition will definitely
    // evaluate to false.
    while (IZoneInterval.rawEnd(interval).epochDay < nextPeriodStartDays) {
      interval = map.getZoneInterval(interval.end);
      node = _HashCacheNode(interval, period, node);
    }

    return node;
  }

  /// Initializes a new instance of the [_HashCacheNode] class.
  ///
  /// [interval]: The zone interval.
  /// [period]:
  /// [previous]: The previous [_HashCacheNode] node.
  _HashCacheNode(this.interval, this.period, this.previous);
}

