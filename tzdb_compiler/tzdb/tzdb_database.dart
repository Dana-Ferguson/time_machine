import 'package:time_machine/src/time_machine_internal.dart';

import 'datetimezone_builder.dart';
import 'rule_line.dart';
import 'zone_line.dart';
// import 'cldr_windows_zone_parser.dart';
// import 'tzdb_stream_writer.dart';
// import 'utility/binary_writer.dart';

/// Provides a container for the definitions parsed from the TZDB zone info files.
class TzdbDatabase {
  /// Returns the zone lists. This is only available for the sake of testing.
  final Map<String, List<ZoneLine>> zones = {};

  /// Returns the version of the TZDB data represented.
  final String version;

  /// Returns the (mutable) map of links from alias to canonical ID.
  final Map<String, String> aliases = {};

  /// Mapping from rule name to the zone rules for that name. This is only available for the sake of testing.
  final Map<String, List<RuleLine>> rules = {};

  /// A list of the zone locations known to this database from zone.tab.
  List<TzdbZoneLocation>? zoneLocations;

  /// A list of the zone locations known to this database from zone1970.tab.
  List<TzdbZone1970Location>? zone1970Locations;

  /// Initializes a new instance of the [TzdbDatabase] class.
  TzdbDatabase(this.version);

  /// Returns the data in this database as a [TzdbDateTimeZoneSource] with no
  /// Windows mappings.
  // TzdbDateTimeZoneSource ToTzdbDateTimeZoneSource() {
  //   var ms = MemoryStream();
  //   var writer = TzdbStreamWriter();
  //   writer.write(this,
  //       WindowsZones('n/a', version, "n/a", <MapZone>[]), // No Windows mappings,
  //       <String, String>{}, // No additional name-to-id mappings
  //       BinaryWriter(ms));
  //   ms.position = 0;
  //   return TzdbDateTimeZoneSource.FromStream(ms);
  // }

  /// Adds the given zone alias to the database.
  ///
  /// <param name='original'>The existing zone ID to map the alias to.</param>
  /// <param name='alias'>The zone alias to add.</param>
  void addAlias(String existing, String alias) {
    aliases[alias] = existing;
  }

  /// Adds the given rule to the appropriate rule set. If there is no existing
  /// rule set, one is created and added to the database.
  ///
  /// <param name='rule'>The rule to add.</param>
  void addRule(RuleLine rule) {
    rules.putIfAbsent(rule.name, () => []);
    rules[rule.name]!.add(rule);
  }

  /// Adds the given zone line to the database, creating a new list for
  /// that zone ID if necessary.
  ///
  /// <param name='zone'>The zone to add.</param>
  void addZone(ZoneLine zone) {
    zones.putIfAbsent(zone.name, () => []);
    zones[zone.name]!.add(zone);
  }

  /// Converts a single zone into a DateTimeZone. As well as for testing purposes,
  /// this can be used to resolve aliases.
  ///
  /// <param name='zoneId'>The ID of the zone to convert.</param>
  DateTimeZone generateDateTimeZone(String zoneId) {
    String zoneListKey = zoneId;
    // Recursively resolve aliases
    while (aliases.containsKey(zoneListKey)) {
      zoneListKey = aliases[zoneListKey]!;
    }
    return _createTimeZone(zoneId, zones[zoneListKey]!);
  }

  /// Converts each zone in the database into a DateTimeZone.
  Iterable<DateTimeZone> generateDateTimeZones() sync* {
    var zoneKeys = zones.keys.toList()..sort();
    for(var key in zoneKeys) {
      yield _createTimeZone(key, zones[key]!);
    }
  }

  /// Returns a newly created [DateTimeZone] built from the given time zone data.
  ///
  /// <param name='zoneList'>The time zone definition parts to add.</param>
  DateTimeZone _createTimeZone(String id, List<ZoneLine> zoneList) {
    var ruleSets = zoneList.map((zone) => zone.resolveRules(rules)).toList();
    return DateTimeZoneBuilder.build(id, ruleSets);
  }

  /// Writes various informational counts to the log.
  void logCounts() {
    print('=======================================');
    print('Rule sets:    ${rules.length}');
    print('Zones:        ${zones.length}');
    print('Aliases:      ${aliases.length}');
    print('Zone locations: ${zoneLocations?.length ?? 0}');
    print('Zone1970 locations: ${zone1970Locations?.length ?? 0}');
    print('=======================================');
  }
}
