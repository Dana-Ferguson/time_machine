// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/DateTimeZoneCache.cs
// 95327c5 on Apr 10, 2017

import 'dart:math' as math;
import 'dart:async';

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

/// <summary>
/// Provides an implementation of <see cref="IDateTimeZoneProvider"/> that caches results from an
/// <see cref="IDateTimeZoneSource"/>.
/// </summary>
/// <remarks>
/// The process of loading or creating time zones may be an expensive operation. This class implements an
/// unlimited-size non-expiring cache over a time zone source, and adapts an implementation of the
/// <c>IDateTimeZoneSource</c> interface to an <c>IDateTimeZoneProvider</c>.
/// </remarks>
/// <seealso cref="DateTimeZoneProviders"/>
/// <threadsafety>All members of this type are thread-safe as long as the underlying <c>IDateTimeZoneSource</c>
/// implementation is thread-safe.</threadsafety>
@immutable // only; caches are naturally mutable internally.
// sealed
class DateTimeZoneCache implements IDateTimeZoneProvider {
  @private final Object accessLock = new Object();
  @private final IDateTimeZoneSource source;
  @private final Map<String, DateTimeZone> timeZoneMap = new Map<String, DateTimeZone>();

  /// <summary>
  /// Gets the version ID of this provider. This is simply the <see cref="IDateTimeZoneSource.VersionId"/> returned by
  /// the underlying source.
  /// </summary>
  /// <value>The version ID of this provider.</value>
  final String VersionId;

  /// <inheritdoc />
  // todo:  ReadOnlyCollection<String>
  final List<String> Ids;

  DateTimeZoneCache._(this.source, this.Ids, this.VersionId);

  // todo: anyway I can make this a regular constructor???
  /// <summary>
  /// Creates a provider backed by the given <see cref="IDateTimeZoneSource"/>.
  /// </summary>
  /// <remarks>
  /// Note that the source will never be consulted for requests for the fixed-offset timezones "UTC" and
  /// "UTC+/-Offset" (a standard implementation will be returned instead). This is true even if these IDs are
  /// advertised by the source.
  /// </remarks>
  /// <param name="source">The <see cref="IDateTimeZoneSource"/> for this provider.</param>
  /// <exception cref="InvalidDateTimeZoneSourceException"><paramref name="source"/> violates its contract.</exception>
  static Future<DateTimeZoneCache> getCache(IDateTimeZoneSource source) async {
    Preconditions.checkNotNull(source, 'source');
    var VersionId = await source.VersionId;

    if (VersionId == null) {
      throw new InvalidDateTimeZoneSourceError("Source-returned version ID was null");
    }

    var providerIds = await source.GetIds();
    if (providerIds == null) {
      throw new InvalidDateTimeZoneSourceError("Source-returned ID sequence was null");
    }

    var idList = new List<String>.from(providerIds);
    idList.sort((a, b) => a.compareTo(b)); // sort(StringComparer.Ordinal);
    var ids = new List<String>.from(idList);

    var cache = new DateTimeZoneCache._(source, ids, VersionId);
    // Populate the dictionary with null values meaning "the ID is valid, we haven't fetched the zone yet".
    for (String id in ids) {
      if (id == null) {
        throw new InvalidDateTimeZoneSourceError("Source-returned ID sequence contained a null reference");
      }
      cache.timeZoneMap[id] = null;
    }
    return cache;
  }

  /// <inheritdoc />
  Future<DateTimeZone> GetSystemDefault() async {
    String id = source.GetSystemDefaultId();
    if (id == null) {
      throw new DateTimeZoneNotFoundException("System default time zone is unknown to source $VersionId");
    }
    return await this[id];
  }

  /// <inheritdoc />
  Future<DateTimeZone> GetZoneOrNull(String id) async {
    Preconditions.checkNotNull(id, 'id');
    return (await GetZoneFromSourceOrNull(id)) ?? FixedDateTimeZone.GetFixedZoneOrNull(id);
  }

  @private Future<DateTimeZone> GetZoneFromSourceOrNull(String id) async {
    // if (!timeZoneMap.TryGetValue(id, /*todo:out*/ zone)) {
    // if ((zone = timeZoneMap[id]) == null) {
    if (!timeZoneMap.containsKey(id)) {
      return null;
    }

    DateTimeZone zone = timeZoneMap[id];
    if (zone == null) {
      zone = await source.ForId(id);
      if (zone == null) {
        throw new InvalidDateTimeZoneSourceError(
            "Time zone $id is supported by source #VersionId but not returned");
      }
      timeZoneMap[id] = zone;
    }

    return zone;
  }

  Future<DateTimeZone> operator [](String id) async {
    var zone = await GetZoneOrNull(id);
    if (zone == null) {
      throw new DateTimeZoneNotFoundException("Time zone $id is unknown to source $VersionId");
    }
    return zone;
  }
}
