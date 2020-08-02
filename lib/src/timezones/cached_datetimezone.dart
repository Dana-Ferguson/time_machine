// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

///  Provides a [DateTimeZone] wrapper class that implements a simple cache to
///  speed up the lookup of transitions.
///
/// The cache supports mulTiple caching strategies which are implemented in nested subclasses of
/// this one. Until we have a better sense of what the usage behavior is, we cannot tune the
/// cache. It is possible that we may support multiple strategies selectable at runtime so the
/// user can tune the performance based on their knowledge of how they are using the system.
///
/// In fact, only one cache type is currently implemented: an MRU cache existed before
/// the GetZoneIntervalPair call was created in DateTimeZone, but as it wasn't being used, it
/// was more effort than it was worth to update. The mechanism is still available for future
/// expansion though.
// sealed
@internal
class CachedDateTimeZone extends DateTimeZone {
  final ZoneIntervalMap _map;

  /// Gets the cached time zone.
  final DateTimeZone timeZone;

  /// Initializes a new instance of the [CachedDateTimeZone] class.
  ///
  /// [timeZone]: The time zone to cache.
  /// [map]: The caching map
  CachedDateTimeZone._(this.timeZone, this._map) : super(timeZone.id, false, timeZone.minOffset, timeZone.maxOffset);

  /// Returns a cached time zone for the given time zone.
  ///
  /// If the time zone is already cached or it is fixed then it is returned unchanged.
  ///
  /// [timeZone]: The time zone to cache.
  /// Returns: The cached time zone.
  static DateTimeZone forZone(DateTimeZone timeZone) {
    // todo: move this as a factory method on DateTimeZone?
    Preconditions.checkNotNull(timeZone, 'timeZone');
    if (timeZone is CachedDateTimeZone || IDateTimeZone.isFixed(timeZone)) {
      return timeZone;
    }
    return CachedDateTimeZone._(timeZone, CachingZoneIntervalMap.cacheMap(timeZone));
  }

  /// Delegates fetching a zone interval to the caching map.
  @override ZoneInterval getZoneInterval(Instant instant) {
    return _map.getZoneInterval(instant);
  }
}
