// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/CachedDateTimeZone.cs
// 16aacad  on Aug 26, 2017

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

/// <summary>
///  Provides a <see cref="DateTimeZone"/> wrapper class that implements a simple cache to
///  speed up the lookup of transitions.
/// </summary>
/// <remarks>
/// <para>
/// The cache supports mulTiple caching strategies which are implemented in nested subclasses of
/// this one. Until we have a better sense of what the usage behavior is, we cannot tune the
/// cache. It is possible that we may support multiple strategies selectable at runtime so the
/// user can tune the performance based on their knowledge of how they are using the system.
/// </para>
/// <para>
/// In fact, only one cache type is currently implemented: an MRU cache existed before
/// the GetZoneIntervalPair call was created in DateTimeZone, but as it wasn't being used, it
/// was more effort than it was worth to update. The mechanism is still available for future
/// expansion though.
/// </para>
/// </remarks>
// sealed
@internal class CachedDateTimeZone extends DateTimeZone {
  @private final IZoneIntervalMap map;

  /// <summary>
  /// Gets the cached time zone.
  /// </summary>
  /// <value>The time zone.</value>
  @internal final DateTimeZone TimeZone;

  /// <summary>
  /// Initializes a new instance of the <see cref="CachedDateTimeZone"/> class.
  /// </summary>
  /// <param name="timeZone">The time zone to cache.</param>
  /// <param name="map">The caching map</param>
  @private CachedDateTimeZone(this.TimeZone, this.map) : super(TimeZone.id, false, TimeZone.minOffset, TimeZone.maxOffset);

  /// <summary>
  /// Returns a cached time zone for the given time zone.
  /// </summary>
  /// <remarks>
  /// If the time zone is already cached or it is fixed then it is returned unchanged.
  /// </remarks>
  /// <param name="timeZone">The time zone to cache.</param>
  /// <returns>The cached time zone.</returns>
  @internal static DateTimeZone ForZone(DateTimeZone timeZone) {
    Preconditions.checkNotNull(timeZone, 'timeZone');
    if (timeZone is CachedDateTimeZone || timeZone.isFixed) {
      return timeZone;
    }
    return new CachedDateTimeZone(timeZone, CachingZoneIntervalMap.CacheMap(timeZone));
  }

  /// <summary>
  /// Delegates fetching a zone interval to the caching map.
  /// </summary>
  @override ZoneInterval GetZoneInterval(Instant instant) {
    return map.GetZoneInterval(instant);
  }
}