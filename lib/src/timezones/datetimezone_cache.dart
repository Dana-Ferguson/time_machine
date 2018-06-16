// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:math' as math;
import 'dart:async';

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

/// Provides an implementation of [IDateTimeZoneProvider] that caches results from an
/// [IDateTimeZoneSource].
///
/// The process of loading or creating time zones may be an expensive operation. This class implements an
/// unlimited-size non-expiring cache over a time zone source, and adapts an implementation of the
/// `IDateTimeZoneSource` interface to an `IDateTimeZoneProvider`.
///
/// <seealso cref="DateTimeZoneProviders"/>
/// <threadsafety>All members of this type are thread-safe as long as the underlying `IDateTimeZoneSource`
/// implementation is thread-safe.</threadsafety>
@immutable // only; caches are naturally mutable internally.
// sealed
class DateTimeZoneCache extends IDateTimeZoneProvider {
  final IDateTimeZoneSource _source;
  final Map<String, DateTimeZone> _timeZoneMap = new Map<String, DateTimeZone>();

  /// Gets the version ID of this provider. This is simply the [IDateTimeZoneSource.versionId] returned by
  /// the underlying source.
  final String versionId;

  /// <inheritdoc />
  // todo:  ReadOnlyCollection<String>
  final List<String> ids;

  DateTimeZoneCache._(this._source, this.ids, this.versionId);

  // todo: anyway I can make this a regular constructor???
  // note: this is a Static Constructor (against the requirements of the Style guide), because it's a future
  /// Creates a provider backed by the given [IDateTimeZoneSource].
  ///
  /// Note that the source will never be consulted for requests for the fixed-offset timezones "UTC" and
  /// "UTC+/-Offset" (a standard implementation will be returned instead). This is true even if these IDs are
  /// advertised by the source.
  ///
  /// [source]: The [IDateTimeZoneSource] for this provider.
  /// [InvalidDateTimeZoneSourceException]: [source] violates its contract.
  static Future<DateTimeZoneCache> getCache(IDateTimeZoneSource source) async {
    Preconditions.checkNotNull(source, 'source');
    var VersionId = await source.versionId;

    if (VersionId == null) {
      throw new InvalidDateTimeZoneSourceError("Source-returned version ID was null");
    }

    var providerIds = await source.getIds();
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
      cache._timeZoneMap[id] = null;
    }
    return cache;
  }

  /// <inheritdoc />
  Future<DateTimeZone> getSystemDefault() async {
    String id = _source.systemDefaultId;
    if (id == null) {
      throw new DateTimeZoneNotFoundError("System default time zone is unknown to source $versionId");
    }
    return await this[id];
  }

  DateTimeZone getCachedSystemDefault() {
    String id = _source.systemDefaultId;
    if (id == null) {
      throw new DateTimeZoneNotFoundError("System default time zone is unknown to source $versionId");
    }
    return getDateTimeZoneSync(id);
  }

  /// <inheritdoc />
  Future<DateTimeZone> getZoneOrNull(String id) async {
    Preconditions.checkNotNull(id, 'id');
    return (await _getZoneFromSourceOrNull(id)) ?? FixedDateTimeZone.getFixedZoneOrNull(id);
  }

  DateTimeZone getCachedZoneOrNull(String id) {
    Preconditions.checkNotNull(id, 'id');
    return _getCachedZoneFromSourceOrNull(id) ?? FixedDateTimeZone.getFixedZoneOrNull(id);
  }

  Future<DateTimeZone> _getZoneFromSourceOrNull(String id) async {
    // if (!timeZoneMap.TryGetValue(id, /*todo:out*/ zone)) {
    // if ((zone = timeZoneMap[id]) == null) {
    if (!_timeZoneMap.containsKey(id)) {
      return null;
    }

    DateTimeZone zone = _timeZoneMap[id];
    if (zone == null) {
      zone = await _source.forId(id);
      if (zone == null) {
        throw new InvalidDateTimeZoneSourceError(
            "Time zone $id is supported by source $versionId but not returned");
      }
      _timeZoneMap[id] = zone;
    }

    return zone;
  }

  // todo: compress this call-chain?
  DateTimeZone _getCachedZoneFromSourceOrNull(String id) {
    if (!_timeZoneMap.containsKey(id)) {
      return null;
    }

    DateTimeZone zone = _timeZoneMap[id];
    if (zone == null) {
      zone = _source.forCachedId(id);
      if (zone == null) {
        throw new InvalidDateTimeZoneSourceError(
            "Time zone $id is supported by source $versionId but not returned");
      }
      _timeZoneMap[id] = zone;
    }

    return zone;
  }

  Future<DateTimeZone> operator [](String id) async {
    var zone = await getZoneOrNull(id);
    if (zone == null) {
      throw new DateTimeZoneNotFoundError("Time zone $id is unknown to source $versionId");
    }
    return zone;
  }

  DateTimeZone getDateTimeZoneSync(String id) {
    var zone = getCachedZoneOrNull(id);
    if (zone == null) {
      throw new DateTimeZoneNotFoundError("Time zone $id is unknown or unavailable synchronously to source $versionId");
    }
    return zone;
  }
}

