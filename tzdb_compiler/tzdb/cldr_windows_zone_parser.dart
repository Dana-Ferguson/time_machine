import 'dart:io' as io;

import 'package:xml/xml.dart' as xml;
import 'package:meta/meta.dart';
// import 'package:xml2json/xml2json.dart';

import 'package:time_machine/src/time_machine_internal.dart';

// import 'zone_rule_set.dart';
// import 'zone_transition.dart';

// todo: TimeZones/Cldr/MapZone.dart
/// <summary>
/// Represents a single <c>&lt;mapZone&gt;</c> element in the CLDR Windows zone mapping file.
/// </summary>
/// <threadsafety>This type is immutable reference type. See the thread safety section of the user guide for more information.</threadsafety>
@immutable
class MapZone // : IEquatable<MapZone>
    {
  /// <summary>
  /// Identifier used for the primary territory of each Windows time zone. A zone mapping with
  /// this territory will always have a single entry. The value of this constant is '001'.
  /// </summary>
  static const String primaryTerritory = '001';

  /// <summary>
  /// Identifier used for the 'fixed offset' territory. A zone mapping with
  /// this territory will always have a single entry. The value of this constant is 'ZZ'.
  /// </summary>
  static const String fixedOffsetTerritory = 'ZZ';

  /// <summary>
  /// Gets the Windows system time zone identifier for this mapping, such as 'Central Standard Time'.
  /// </summary>
  /// <remarks>
  /// <para>
  /// Most Windows system time zone identifiers use the name for the 'standard' part of the zone as
  /// the overall identifier. Don't be fooled: just because a time zone includes "standard" in its identifier
  /// doesn't mean that it doesn't observe daylight saving time.
  /// </para>
  /// </remarks>
  /// <value>The Windows system time zone identifier for this mapping, such as 'Central Standard Time'.</value>
  final String windowsId;

  /// <summary>
  /// Gets the territory code for this mapping.
  /// </summary>
  /// <remarks>
  /// This is typically either '001' to indicate that it's the primary territory for this ID, or
  /// 'ZZ' to indicate a fixed-offset ID, or a different two-character capitalized code
  /// which indicates the geographical territory.
  /// </remarks>
  /// <value>The territory code for this mapping.</value>
  final String territory;

  /// <summary>
  /// Gets a read-only non-empty collection of TZDB zone identifiers for this mapping, such as
  /// 'America/Chicago' and "America/Matamoros" (both of which are TZDB zones associated with the "Central Standard Time"
  /// Windows system time zone).
  /// </summary>
  /// <remarks>
  /// For the primary and fixed-offset territory IDs ('001' and "ZZ") this always
  /// contains exactly one time zone ID.
  /// </remarks>
  /// <value>A read-only non-empty collection of TZDB zone identifiers for this mapping.</value>
// todo: IList -- should be readonly
  final List<String> tzdbIds;

  /// <summary>
  /// Creates a new mapping entry.
  /// </summary>
  /// <remarks>
  /// This constructor is only public for the sake of testability.
  /// </remarks>
  /// <param name='windowsId'>Windows system time zone identifier. Must not be null.</param>
  /// <param name='territory'>Territory code. Must not be null.</param>
  /// <param name='tzdbIds'>List of territory codes. Must not be null, and must not
  /// contains null values.</param>
  factory MapZone(String windowsId, String territory, /*I*/List<String> tzdbIds)
  {
    Preconditions.checkNotNull(windowsId, 'windowsId');
    Preconditions.checkNotNull(territory, 'territory');
    Preconditions.checkNotNull(tzdbIds, 'tzdbIds');

    return MapZone._(windowsId, territory, tzdbIds);
  }

  /// <summary>
  /// Private constructor to avoid unnecessary list copying (and validation) when deserializing.
  /// </summary>
  const MapZone._(this.windowsId, this.territory, this.tzdbIds);

  /// <summary>
  /// Reads a mapping from a reader.
  /// </summary>
// todo: internal
  static MapZone read(/*I*/DateTimeZoneReader reader) {
    String windowsId = reader.readString();
    String territory = reader.readString();

    int count = reader.read7BitEncodedInt(); //readCount();
    var tzdbIds = List<String>.generate(count, (int i) => reader.readString());
    return MapZone(windowsId, territory, tzdbIds);
  }

  /// <summary>
  /// Writes this mapping to a writer.
  /// </summary>
  /// <param name='writer'></param>
// todo: internal
  void write(IDateTimeZoneWriter writer) {
    writer.writeString(windowsId);
    writer.writeString(territory);
    writer.write7BitEncodedInt(tzdbIds.length);

    for (String id in tzdbIds) {
      writer.writeString(id);
    }
  }

  @override bool operator ==(Object other) {
    if (other is MapZone &&
        windowsId == other.windowsId &&
        territory == other.territory) {
      // SequenceEqual
      for (int i = 0; i <= tzdbIds.length; i++) {
        if (tzdbIds[i] != other.tzdbIds[i]) return false;
      }
      return true;
    }

    return false;
  }

  /// <inheritdoc />
  @override int get hashCode =>
      hashObjects([windowsId, windowsId, ...tzdbIds]);

  /// <inheritdoc />
  @override String toString() =>
      'Windows ID: $windowsId; Territory: $territory; TzdbIds: $tzdbIds';
}

// todo: from TimeZones/Cldr/WindowsZones.dart
/// Representation of the <c>&lt;windowsZones&gt;</c> element of CLDR supplemental data.
///
/// See <a href='http://cldr.unicode.org/development/development-process/design-proposals/extended-windows-olson-zid-mapping'>the CLDR design proposal</a>
/// for more details of the structure of the file from which data is taken.
@immutable
class WindowsZones {
  /// <summary>
  /// Gets the version of the Windows zones mapping data read from the original file.
  /// </summary>
  /// <remarks>
  /// As with other IDs, this should largely be treated as an opaque string, but the current method for
  /// generating this from the mapping file extracts a number from an element such as <c>&lt;version number='$Revision: 7825 $'/&gt;</c>.
  /// This is a Subversion revision number, but that association should only be used for diagnostic curiosity, and never
  /// assumed in code.
  /// </remarks>
  /// <value>The version of the Windows zones mapping data read from the original file.</value>
  final String version;

  /// <summary>
  /// Gets the TZDB version this Windows zone mapping data was created from.
  /// </summary>
  /// <remarks>
  /// The CLDR mapping file usually lags behind the TZDB file somewhat - partly because the
  /// mappings themselves don't always change when the time zone data does. For example, it's entirely
  /// reasonable for a <see cref='TzdbDateTimeZoneSource'/> with a <see cref="TzdbDateTimeZoneSource.TzdbVersion">TzdbVersion</see> of
  /// '2013b' to be supply a <c>WindowsZones</c> object with a <c>TzdbVersion</c> of "2012f".
  /// </remarks>
  /// <value>The TZDB version this Windows zone mapping data was created from.</value>
  final String tzdbVersion;

  /// <summary>
  /// Gets the Windows time zone database version this Windows zone mapping data was created from.
  /// </summary>
  /// <remarks>
  /// At the time of this writing, this is populated (by CLDR) from the registry key
  /// HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones\TzVersion,
  /// so '7dc0101' for example.
  /// </remarks>
  /// <value>The Windows time zone database version this Windows zone mapping data was created from.</value>
  final String windowsVersion;

  /// <summary>
  /// Gets an immutable collection of mappings from Windows system time zones to
  /// TZDB time zones.
  /// </summary>
  /// <remarks>
  /// <para>
  /// Each mapping consists of a single Windows time zone ID and a single
  /// territory to potentially multiple TZDB IDs that are broadly equivalent to that Windows zone/territory
  /// pair.
  /// </para>
  /// <para>
  /// Mappings for a single Windows system time zone can appear multiple times
  /// in this list, in different territories. For example, 'Central Standard Time'
  /// maps to different TZDB zones in different countries (the US, Canada, Mexico) and
  /// even within a single territory there can be multiple zones. Every Windows system time zone covered within
  /// this collection has a 'primary' entry with a territory code of "001" (which is the value of
  /// <see cref='MapZone.PrimaryTerritory'/>) and a single corresponding TZDB zone.
  /// </para>
  /// <para>This collection is not guaranteed to cover every Windows time zone. Some zones may be unmappable
  /// (such as 'Mid-Atlantic Standard Time') and there can be a delay between a new Windows time zone being introduced
  /// and it appearing in CLDR, ready to be used by Noda Time. (There's also bound to be a delay between it appearing
  /// in CLDR and being used in your production system.) In practice however, you're unlikely to wish to use a time zone
  /// which isn't covered here.</para>
  /// </remarks>
  /// <value>An immutable collection of mappings from Windows system time zones to
  /// TZDB time zones.</value>
  // todo: was IList - this should be a readonly List
  final List<MapZone> mapZones;

  /// <summary>
  /// Gets an immutable dictionary of primary mappings, from Windows system time zone ID
  /// to TZDB zone ID. This corresponds to the '001' territory which is present for every zone
  /// within the mapping file.
  /// </summary>
  /// <remarks>
  /// <para>
  /// Each value in the dictionary is a canonical ID in CLDR, but it may not be canonical
  /// in TZDB. For example, the ID corresponding to 'India Standard Time' is "Asia/Calcutta", which
  /// is canonical in CLDR but is an alias in TZDB for 'Asia/Kolkata'. To obtain a canonical TZDB
  /// ID, use <see cref='TzdbDateTimeZoneSource.CanonicalIdMap'/>.
  /// </para>
  /// </remarks>
  /// <value>An immutable dictionary of primary mappings, from Windows system time zone ID
  /// to TZDB zone ID.</value>
  // todo: was IDictionary - this should be a readonly Dictionary
  final Map<String, String> primaryMapping;

  // todo: internal
  factory WindowsZones(String version, String tzdbVersion,
      String windowsVersion, List<MapZone> mapZones)
  {
    Preconditions.checkNotNull(version, 'version');
    Preconditions.checkNotNull(tzdbVersion, 'tzdbVersion');
    Preconditions.checkNotNull(windowsVersion, 'windowsVersion');
    Preconditions.checkNotNull(mapZones, 'mapZones');

    return WindowsZones._(version, tzdbVersion, windowsVersion, mapZones);
  }

  WindowsZones._(this.version, this.tzdbVersion, this.windowsVersion,
      this.mapZones) :
        primaryMapping = {
          for (var z in mapZones.where((z) => z.territory == MapZone.primaryTerritory))
            z.windowsId : z.tzdbIds.single
        };

  // todo: internal
  static WindowsZones read(DateTimeZoneReader reader) {
    String version = reader.readString();
    String tzdbVersion = reader.readString();
    String windowsVersion = reader.readString();
    int count = reader.read7BitEncodedInt(); // ReadCount();
    var mapZones = List<MapZone>.generate(count, (int i) => MapZone.read(reader));
    return WindowsZones(version, tzdbVersion, windowsVersion,
        // todo: to readonly?
        mapZones);
  }

  // todo: internal
  void write(IDateTimeZoneWriter writer) {
    writer.writeString(version);
    writer.writeString(tzdbVersion);
    writer.writeString(windowsVersion);
    writer.write7BitEncodedInt(mapZones.length);
    for(var mapZone in mapZones)
    {
      mapZone.write(writer);
    }
  }
}

// todo: internal
class CldrWindowsZonesParser
{
  static WindowsZones parse(xml.XmlDocument document)
  {
    var mapZones = _mapZones(document);
    var windowsZonesVersion = _findVersion(document);
    var tzdbVersion = document.findElements('windowsZones').first.findElements('mapTimezones').first.getAttribute('typeVersion') ?? '';
    // todo: var _tzdbVersion = document.rootElement.('windowsZones')?.Element("mapTimezones")?.Attribute("typeVersion")?.Value ?? "";
    var windowsVersion = document.findElements('windowsZones').first.findElements('mapTimezones').first.getAttribute('typeVersion') ?? '';
    // todo: var windowsVersion = document.Root.Element('windowsZones')?.Element("mapTimezones")?.Attribute("otherVersion")?.Value ?? "";
    return WindowsZones(windowsZonesVersion, tzdbVersion, windowsVersion, mapZones);
  }

  // todo: internal
  static WindowsZones parseFile(String file) =>
      parse(_loadFile(file));

  static xml.XmlDocument _loadFile(String file) =>
      xml.XmlDocument.parse(io.File(file).readAsStringSync());

  static String _findVersion(xml.XmlDocument document)
  {
    // String revision = document.Root.Element('version')?.Attribute("number");
    String? revision = document.findElements('version').first.getAttribute('number');
    if (revision == null)
    {
      return '';
    }
    String prefix = r'$Revision: ';
    if (revision.startsWith(prefix))
    {
      revision = revision.substring(prefix.length);
    }
    String suffix = r' $';
    if (revision.endsWith(suffix))
    {
      revision = revision.substring(0, revision.length - suffix.length);
    }
    return revision;
  }

  /*
  static List<MapZone> _mapZones2(XmlDocument document) =>
      document.Root
          .Element('windowsZones')
          .Element('mapTimezones')
          .Elements('mapZone')
          .Select((x) => new MapZone(x.Attribute('other').Value,
  x.Attribute('territory').Value,
  x.Attribute('type').Value.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries)))
      .ToList();*/

  /// <summary>
  /// Reads the input XML file for the windows mappings.
  /// </summary>
  /// <returns>A lookup of Windows time zone mappings</returns>
  static List<MapZone> _mapZones(xml.XmlDocument document) =>
      document
          .findElements('windowsZones').first
          .findElements('mapTimezones').first
          .findElements('mapZone')
          .map((x) => MapZone(x.getAttribute('other')!,
          x.getAttribute('territory')!,
          x.getAttribute('type')!.split(r'\\s+')))
          .toList();
}
