import 'package:time_machine/src/time_machine_internal.dart';

/// Separate class for parsing zone location data from zone.tab and iso3166.tab.
/// Stateless, simply static methods - only separated from TzdbZoneInfoCompiler to make the
/// organization a little cleaner.
// todo: internal static
abstract class TzdbZoneLocationParser {
  static TzdbZoneLocation parseLocation(String line, Map<String, String> countryMapping) {
    List<String> bits = line.split('\t');
    Preconditions.checkArgument(bits.length == 3 || bits.length == 4, 'line', "Line must have 3 or 4 tab-separated values");
    String countryCode = bits[0];
    String countryName = countryMapping[countryCode]!;
    List<int> latLong = _parseCoordinates(bits[1]);
    String zoneId = bits[2];
    String comment = bits.length == 4 ? bits[3] : '';
    return TzdbZoneLocation(latLong[0], latLong[1], countryName, countryCode, zoneId, comment);
  }

  static TzdbZone1970Location parseEnhancedLocation(String line, Map<String, TzdbZone1970LocationCountry> countryMapping) {
    List<String> bits = line.split('\t');
    Preconditions.checkArgument(bits.length == 3 || bits.length == 4, 'line', "Line must have 3 or 4 tab-separated values");
    String countryCodes = bits[0];
    var countries = countryCodes.split(',').map((code) => countryMapping[code]).toList();
    List<int> latLong = _parseCoordinates(bits[1]);
    String zoneId = bits[2];
    String comment = bits.length == 4 ? bits[3] : '';
    return TzdbZone1970Location(latLong[0], latLong[1], countries, zoneId, comment);
  }

  // Internal for testing
  /// <summary>
  /// Parses a string such as '-7750+16636' or "+484531-0913718" into a pair of Int32
  /// values: the latitude and longitude of the coordinates, in seconds.
  /// </summary>
  static List<int> _parseCoordinates(String text) {
    Preconditions.checkArgument(text.length == 11 || text.length == 15, 'point', "Invalid coordinates");
    int latDegrees;
    int latMinutes;
    int latSeconds = 0;
    int latSign;
    int longDegrees;
    int longMinutes;
    int longSeconds = 0;
    int longSign;

    if (text.length == 11 /* +-DDMM+-DDDMM */) {
      latSign = text[0] == '-' ? -1 : 1;
      latDegrees = int.parse(text.substring(1, 2));
      latMinutes = int.parse(text.substring(3, 2));
      longSign = text[5] == '-' ? -1 : 1;
      longDegrees = int.parse(text.substring(6, 3));
      longMinutes = int.parse(text.substring(9, 2));
    }
    else
      /* +-DDMMSS+-DDDMMSS */ {
      latSign = text[0] == '-' ? -1 : 1;
      latDegrees = int.parse(text.substring(1, 2));
      latMinutes = int.parse(text.substring(3, 2));
      latSeconds = int.parse(text.substring(5, 2));
      longSign = text[7] == '-' ? -1 : 1;
      longDegrees = int.parse(text.substring(8, 3));
      longMinutes = int.parse(text.substring(11, 2));
      longSeconds = int.parse(text.substring(13, 2));
    }
    return [
      latSign * (latDegrees * 3600 + latMinutes * 60 + latSeconds),
      longSign * (longDegrees * 3600 + longMinutes * 60 + longSeconds)
    ];
  }
}
