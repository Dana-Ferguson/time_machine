// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_timezones.dart';
import 'package:time_machine/time_machine_utilities.dart';

/// A time zone source for test purposes.
/// Create instances via [FakeDateTimeZoneSource.Builder].
class FakeDateTimeZoneSource extends IDateTimeZoneSource {
  final Map<String, DateTimeZone> _zones;
  final Map<String, String> _bclToZoneIds;

  // todo: do we care about bclToZoneIds?
  FakeDateTimeZoneSource._(String versionId, this._zones, this._bclToZoneIds)
      : versionId = new Future<String>.value(versionId);

  /// Creates a time zone provider ([DateTimeZoneCache]) from this source.
  ///
  /// Returns: A provider backed by this source.
  Future<IDateTimeZoneProvider> ToProvider() => DateTimeZoneCache.getCache(this);

  /// <inheritdoc />
  Future<Iterable<String>> getIds() => new Future.value(_zones.keys);

  /// <inheritdoc />
  final Future<String> versionId;

  /// <inheritdoc />
  Future<DateTimeZone> forId(String id) {
    Preconditions.checkNotNull(id, 'id');
    var zone = _zones[id];
    if (zone != null) {
      return new Future.value(zone);
    }
    throw new ArgumentError("Unknown ID: " + id);
  }

  // todo: Not a problem for dart... do we have an inheritdoc equivalent?
  // TODO: Work out why inheritdoc doesn't work here. What's special about this method?

  /// Returns this source's ID for the system default time zone.
  ///
  /// The ID for the system default time zone for this source,
  /// or null if the system default time zone has no mapping in this source.
  String getSystemDefaultId() {
    return null;
    //String id = TimeZoneInfo.Local.Id;
    // We don't care about the return value of TryGetValue - if it's false,
    // canonicalId will be null, which is what we want.
    //bclToZoneIds.TryGetValue(id, out String canonicalId);
    //return canonicalId;
  }

  @override
  DateTimeZone forIdSync(String id) {
    Preconditions.checkNotNull(id, 'id');
    var zone = _zones[id];
    if (zone != null) {
      return zone;
    }
    throw new ArgumentError("Unknown ID: " + id);
  }
}

/// Builder for [FakeDateTimeZoneSource], allowing the built object to
/// be immutable, but constructed via object/collection initializers.
class FakeDateTimeZoneSourceBuilder {
  final Map<String, String> _bclIdsToZoneIds = new Map<String, String>();
  final List<DateTimeZone> _zones = new List<DateTimeZone>();

  /// Gets the dictionary mapping BCL [TimeZoneInfo] IDs to the canonical IDs
  /// served within the provider being built.
  ///
  /// <value>The dictionary mapping BCL IDs to the canonical IDs served within the provider
  /// being built.</value>
  Map<String, String> get BclIdsToZoneIds => _bclIdsToZoneIds;

  /// Gets the list of zones, exposed as a property for use when a test needs to set properties as
  /// well as adding zones.
  List<DateTimeZone> get Zones => _zones;

  /// Gets the version ID to advertise; defaults to "TestZones".
  String VersionId;

  /// Creates a new builder.
  FakeDateTimeZoneSourceBuilder([List<DateTimeZone> zones = const []]) {
    VersionId = "TestZones";
    this._zones.addAll(zones);
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
    var zoneMap = new Map.fromIterable(_zones, key: (z) => z.id);
    _bclIdsToZoneIds.forEach((key, value) {
      Preconditions.checkNotNull(value, "value");
      if (!zoneMap.containsKey(value)) {
        throw new StateError("Mapping for BCL ${key}/${value} has no corresponding zone.");
      }
    });

    var bclIdMapClone = new Map<String, String>.from(_bclIdsToZoneIds);
    return new FakeDateTimeZoneSource._(VersionId, zoneMap, bclIdMapClone);
  }
}

