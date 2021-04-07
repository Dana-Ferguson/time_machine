// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

/// Provides an implementation of [DateTimeZoneProvider] that caches results from an
/// [DateTimeZoneSource].
///
/// The process of loading or creating time zones may be an expensive operation. This class implements an
/// unlimited-size non-expiring cache over a time zone source, and adapts an implementation of the
/// `IDateTimeZoneSource` interface to an `IDateTimeZoneProvider`.
///
/// see also: [DateTimeZoneProviders]
@immutable // only; caches are naturally mutable internally.
class DateTimeZoneCache extends DateTimeZoneProvider {
  final DateTimeZoneSource _source;
  final Map<String, DateTimeZone?> _timeZoneMap = <String, DateTimeZone?>{};

  /// Gets the version ID of this provider. This is simply the [DateTimeZoneSource.versionId] returned by
  /// the underlying source.
  @override
  final String versionId;

  /// <inheritdoc />
  // todo:  ReadOnlyCollection<String>
  @override
  final List<String> ids;

  DateTimeZoneCache._(this._source, this.ids, this.versionId);

  // todo: anyway I can make this a regular constructor???
  // note: this is a Static Constructor (against the requirements of the Style guide), because it's a future
  /// Creates a provider backed by the given [DateTimeZoneSource].
  ///
  /// Note that the source will never be consulted for requests for the fixed-offset timezones 'UTC' and
  /// 'UTC+/-Offset' (a standard implementation will be returned instead). This is true even if these IDs are
  /// advertised by the source.
  ///
  /// [source]: The [DateTimeZoneSource] for this provider.
  /// [InvalidDateTimeZoneSourceException]: [source] violates its contract.
  static Future<DateTimeZoneCache> getCache(DateTimeZoneSource source) async {
    Preconditions.checkNotNull(source, 'source');
    var VersionId = await source.versionId;

    if (VersionId == null) {
      throw InvalidDateTimeZoneSourceError('Source-returned version ID was null');
    }

    var providerIds = await source.getIds();
    if (providerIds == null) {
      throw InvalidDateTimeZoneSourceError('Source-returned ID sequence was null');
    }

    var idList = List<String>.from(providerIds);
    // todo: a gentler 'null' okay sorter?
    // idList.sort((a, b) => (a ?? '').compareTo(b ?? '')); // sort(StringComparer.Ordinal);
    idList.sort();
    var ids = List<String>.from(idList);

    var cache = DateTimeZoneCache._(source, ids, VersionId);
    // Populate the dictionary with null values meaning "the ID is valid, we haven't fetched the zone yet".
    for (String id in ids) {
      cache._timeZoneMap[id] = null;
    }
    return cache;
  }

  /// <inheritdoc />
  @override
  Future<DateTimeZone> getSystemDefault() async {
    String? id = _source.systemDefaultId;
    if (id == null) {
      throw DateTimeZoneNotFoundError('System default time zone is unknown to source $versionId');
    }
    return await this[id];
  }

  @override
  DateTimeZone getCachedSystemDefault() {
    String? id = _source.systemDefaultId;
    if (id == null) {
      throw DateTimeZoneNotFoundError('System default time zone is unknown to source $versionId');
    }
    return getDateTimeZoneSync(id);
  }

  /// <inheritdoc />
  @override
  Future<DateTimeZone?> getZoneOrNull(String id) async {
    Preconditions.checkNotNull(id, 'id');
    return (await _getZoneFromSourceOrNull(id)) ?? FixedDateTimeZone.getFixedZoneOrNull(id);
  }

  DateTimeZone? getCachedZoneOrNull(String id) {
    Preconditions.checkNotNull(id, 'id');
    return _getCachedZoneFromSourceOrNull(id) ?? FixedDateTimeZone.getFixedZoneOrNull(id);
  }

  Future<DateTimeZone?> _getZoneFromSourceOrNull(String id) async {
    // if (!timeZoneMap.TryGetValue(id, /*todo:out*/ zone)) {
    // if ((zone = timeZoneMap[id]) == null) {
    if (!_timeZoneMap.containsKey(id)) {
      return null;
    }

    DateTimeZone? zone = _timeZoneMap[id];
    if (zone == null) {
      zone = await _source.forId(id);
      if (zone == null) {
        throw InvalidDateTimeZoneSourceError(
            'Time zone $id is supported by source $versionId but not returned');
      }
      _timeZoneMap[id] = zone;
    }

    return zone;
  }

  // todo: compress this call-chain?
  DateTimeZone? _getCachedZoneFromSourceOrNull(String id) {
    if (!_timeZoneMap.containsKey(id)) {
      return null;
    }

    DateTimeZone? zone = _timeZoneMap[id];
    if (zone == null) {
      zone = _source.forCachedId(id);
      if (zone == null) {
        throw InvalidDateTimeZoneSourceError(
            'Time zone $id is supported by source $versionId but not returned');
      }
      _timeZoneMap[id] = zone;
    }

    return zone;
  }

  @override
  Future<DateTimeZone> operator [](String id) async {
    var zone = await getZoneOrNull(id);
    if (zone == null) {
      throw DateTimeZoneNotFoundError('Time zone $id is unknown to source $versionId');
    }
    return zone;
  }

  @override
  DateTimeZone getDateTimeZoneSync(String id) {
    var zone = getCachedZoneOrNull(id);
    if (zone == null) {
      throw DateTimeZoneNotFoundError('Time zone $id is unknown or unavailable synchronously to source $versionId');
    }
    return zone;
  }
}

