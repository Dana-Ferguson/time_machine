// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Testing/TimeZones/FakeDateTimeZoneSource.cs
// 10dbf36  on Apr 23

import 'dart:async';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_timezones.dart';
import 'package:time_machine/time_machine_utilities.dart';

/// <summary>
/// A time zone source for test purposes.
/// Create instances via <see cref="FakeDateTimeZoneSource.Builder"/>.
/// </summary>
/*sealed*/class FakeDateTimeZoneSource extends IDateTimeZoneSource {
  @private final Map<String, DateTimeZone> zones;
  @private final Map<String, String> bclToZoneIds;

  // todo: do we care about bclToZoneIds?
  @private FakeDateTimeZoneSource(String versionId, this.zones, this.bclToZoneIds)
  : VersionId = new Future<String>.value(versionId);

  /// <summary>
  /// Creates a time zone provider (<see cref="DateTimeZoneCache"/>) from this source.
  /// </summary>
  /// <returns>A provider backed by this source.</returns>
  Future<IDateTimeZoneProvider> ToProvider() => DateTimeZoneCache.getCache(this);

  /// <inheritdoc />
  Future<Iterable<String>> GetIds() => new Future.value(zones.keys);

  /// <inheritdoc />
  final Future<String> VersionId;

  /// <inheritdoc />
  Future<DateTimeZone> ForId(String id) {
    Preconditions.checkNotNull(id, 'id');
    var zone = zones[id];
    if (zone != null) {
      return new Future.value(zone);
    }
    throw new ArgumentError("Unknown ID: " + id);
  }

  // todo: Not a problem for dart... do we have an inheritdoc equivlanet?
// TODO: Work out why inheritdoc doesn't work here. What's special about this method?

  /// <summary>
  /// Returns this source's ID for the system default time zone.
  /// </summary>
  /// <returns>
  /// The ID for the system default time zone for this source,
  /// or null if the system default time zone has no mapping in this source.
  /// </returns>
  String GetSystemDefaultId() {
    return null;
    //String id = TimeZoneInfo.Local.Id;
    // We don't care about the return value of TryGetValue - if it's false,
    // canonicalId will be null, which is what we want.
    //bclToZoneIds.TryGetValue(id, out String canonicalId);
    //return canonicalId;
  }

  @override
  DateTimeZone ForIdSync(String id) {
    Preconditions.checkNotNull(id, 'id');
    var zone = zones[id];
    if (zone != null) {
      return zone;
    }
    throw new ArgumentError("Unknown ID: " + id);
  }
}

/// <summary>
/// Builder for <see cref="FakeDateTimeZoneSource"/>, allowing the built object to
/// be immutable, but constructed via object/collection initializers.
/// </summary>
/*sealed*/class FakeDateTimeZoneSourceBuilder // : IEnumerable<DateTimeZone>
    {
  @private final Map<String, String> bclIdsToZoneIds = new Map<String, String>();
  @private final List<DateTimeZone> zones = new List<DateTimeZone>();

  /// <summary>
  /// Gets the dictionary mapping BCL <see cref="TimeZoneInfo"/> IDs to the canonical IDs
  /// served within the provider being built.
  /// </summary>
  /// <value>The dictionary mapping BCL IDs to the canonical IDs served within the provider
  /// being built.</value>
  Map<String, String> get BclIdsToZoneIds => bclIdsToZoneIds;

  /// <summary>
  /// Gets the list of zones, exposed as a property for use when a test needs to set properties as
  /// well as adding zones.
  /// </summary>
  /// <value>The list of zones within the provider being built.</value>
  List<DateTimeZone> get Zones => zones;

  /// <summary>
  /// Gets the version ID to advertise; defaults to "TestZones".
  /// </summary>
  /// <value>The version ID to advertise; defaults to "TestZones".</value>
  String VersionId;

  /// <summary>
  /// Creates a new builder.
  /// </summary>
  FakeDateTimeZoneSourceBuilder([List<DateTimeZone> zones = const []]) {
    VersionId = "TestZones";
    this.zones.addAll(zones);
  }

  /// <summary>
  /// Adds a time zone to the builder.
  /// </summary>
  /// <param name="zone">The zone to add.</param>
  void Add(DateTimeZone zone) {
    Preconditions.checkNotNull(zone, 'zone');
    zones.add(zone);
  }

  /// <summary>
  /// Returns the zones within the builder. This mostly exists
  /// to enable collection initializers.
  /// </summary>
  /// <returns>An iterator over the zones in this builder.</returns>
  Iterator<DateTimeZone> GetEnumerator() => zones.iterator;

  /// <summary>
  /// Builds a time zone source from this builder. The returned
  /// builder will be independent of this builder; further changes
  /// to this builder will not be reflected in the returned source.
  /// </summary>
  /// <remarks>
  /// This method performs some sanity checks, and throws exceptions if
  /// they're violated. Those exceptions are not documented here, and you
  /// shouldn't be catching them anyway. (This is aimed at testing...)
  /// </remarks>
  /// <returns>The newly-built time zone source.</returns>
  FakeDateTimeZoneSource Build() {
    var zoneMap = new Map.fromIterable(zones, key: (z) => z.id);
    bclIdsToZoneIds.forEach((key, value) {
      Preconditions.checkNotNull(value, "value");
      if (!zoneMap.containsKey(value)) {
        throw new StateError("Mapping for BCL ${key}/${value} has no corresponding zone.");
      }
    });

    var bclIdMapClone = new Map<String, String>.from(bclIdsToZoneIds);
    return new FakeDateTimeZoneSource(VersionId, zoneMap, bclIdMapClone);
  }
}
