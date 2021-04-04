// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';

/// A time zone source for test purposes.
/// Create instances via [FakeDateTimeZoneSource.Builder].
class FakeDateTimeZoneSource extends DateTimeZoneSource {
  final Map<String, DateTimeZone> _zones;
  // ignore: unused_field
  final Map<String, String> _bclToZoneIds;

  // todo: do we care about bclToZoneIds?
  FakeDateTimeZoneSource._(String versionId, this._zones, this._bclToZoneIds)
      : versionId = Future<String>.value(versionId);

  /// Creates a time zone provider ([DateTimeZoneCache]) from this source.
  ///
  /// Returns: A provider backed by this source.
  Future<DateTimeZoneProvider> ToProvider() => DateTimeZoneCache.getCache(this);

  /// <inheritdoc />
  @override
  Future<Iterable<String>> getIds() => Future.value(_zones.keys);

  /// <inheritdoc />
  @override
  final Future<String> versionId;

  /// <inheritdoc />
  @override
  Future<DateTimeZone> forId(String id) {
    Preconditions.checkNotNull(id, 'id');
    var zone = _zones[id];
    if (zone != null) {
      return Future.value(zone);
    }
    throw ArgumentError('Unknown ID: ' + id);
  }

  // todo: Not a problem for dart... do we have an inheritdoc equivalent?
  // TODO: Work out why inheritdoc doesn't work here. What's special about this method?

  /// Returns this source's ID for the system default time zone.
  ///
  /// The ID for the system default time zone for this source,
  /// or null if the system default time zone has no mapping in this source.
  @override
  String? get systemDefaultId {
    return null;
    //String id = TimeZoneInfo.Local.Id;
    // We don't care about the return value of TryGetValue - if it's false,
    // canonicalId will be null, which is what we want.
    //bclToZoneIds.TryGetValue(id, out String canonicalId);
    //return canonicalId;
  }

  @override
  DateTimeZone forCachedId(String id) {
    Preconditions.checkNotNull(id, 'id');
    var zone = _zones[id];
    if (zone != null) {
      return zone;
    }
    throw ArgumentError('Unknown ID: ' + id);
  }
}

/// Builder for [FakeDateTimeZoneSource], allowing the built object to
/// be immutable, but constructed via object/collection initializers.
class FakeDateTimeZoneSourceBuilder {
  final Map<String, String> _bclIdsToZoneIds = <String, String>{};
  final List<DateTimeZone> _zones = <DateTimeZone>[];

  /// Gets the dictionary mapping BCL [TimeZoneInfo] IDs to the canonical IDs
  /// served within the provider being built.
  ///
  /// <value>The dictionary mapping BCL IDs to the canonical IDs served within the provider
  /// being built.</value>
  Map<String, String> get BclIdsToZoneIds => _bclIdsToZoneIds;

  /// Gets the list of zones, exposed as a property for use when a test needs to set properties as
  /// well as adding zones.
  List<DateTimeZone> get Zones => _zones;

  /// Gets the version ID to advertise; defaults to 'TestZones'.
  late String VersionId;

  /// Creates a new builder.
  FakeDateTimeZoneSourceBuilder([List<DateTimeZone> zones = const []]) {
    VersionId = 'TestZones';
    _zones.addAll(zones);
  }

  /// Adds a time zone to the builder.
  ///
  /// [zone]: The zone to add.
  void Add(DateTimeZone zone) {
    Preconditions.checkNotNull(zone, 'zone');
    _zones.add(zone);
  }

  /// Returns the zones within the builder. This mostly exists
  /// to enable collection initializers.
  ///
  /// Returns: An iterator over the zones in this builder.
  Iterator<DateTimeZone> GetEnumerator() => _zones.iterator;

  /// Builds a time zone source from this builder. The returned
  /// builder will be independent of this builder; further changes
  /// to this builder will not be reflected in the returned source.
  ///
  /// This method performs some sanity checks, and throws exceptions if
  /// they're violated. Those exceptions are not documented here, and you
  /// shouldn't be catching them anyway. (This is aimed at testing...)
  ///
  /// Returns: The newly-built time zone source.
  FakeDateTimeZoneSource Build() {
    var zoneMap = Map<String, DateTimeZone>.fromIterable(_zones, key: (z) => z.id);
    _bclIdsToZoneIds.forEach((key, value) {
      Preconditions.checkNotNull(value, 'value');
      if (!zoneMap.containsKey(value)) {
        throw StateError('Mapping for BCL $key/$value has no corresponding zone.');
      }
    });

    var bclIdMapClone = Map<String, String>.from(_bclIdsToZoneIds);
    return FakeDateTimeZoneSource._(VersionId, zoneMap, bclIdMapClone);
  }
}

