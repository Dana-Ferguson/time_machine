import 'package:time_machine/src/time_machine_internal.dart';

import 'datetimezone_builder.dart';
import 'rule_line.dart';
import 'zone_line.dart';
import 'cldr_windows_zone_parser.dart';
import 'tzdb_database.dart';

/// <summary>
/// Writes time zone data to a stream in nzd format.
/// </summary>
/// <remarks>
/// <para>The file format consists of four bytes indicating the file format version/type (mostly for
/// future expansion), followed by a number of fields. Each field is identified by a <see cref="TzdbStreamFieldId"/>.
/// The fields are always written in order, and the format of a field consists of its field ID, a 7-bit-encoded
/// integer with the size of the data, and then the data itself.
/// </para>
/// <para>
/// The version number does not need to be increased if new fields are added, as the reader will simply ignore
/// unknown fields. It only needs to be increased for incompatible changes such as a different time zone format,
/// or if old fields are removed.
/// </para>
/// </remarks>
// todo: internal
class TzdbStreamWriter
{
  static const int _version = 0;

  void Write(
      TzdbDatabase database,
      WindowsZones cldrWindowsZones,
      Map<String, String> additionalWindowsNameToIdMappings,
      Stream stream)
  {
    _FieldCollection fields = new _FieldCollection();

    var zones = database.generateDateTimeZones().toList();
    var stringPool = _createOptimizedStringPool(zones, database.zoneLocations, database.zone1970Locations, cldrWindowsZones);

    // First assemble the fields (writing to the string pool as we go)
    for (var zone in zones)
    {
      var zoneField = fields.AddField(TzdbStreamFieldId.TimeZone, stringPool);
      _writeZone(zone, zoneField.Writer);
    }

    fields.AddField(TzdbStreamFieldId.TzdbVersion, null).Writer.WriteString(database.version);

    // Normalize the aliases
    var timeZoneMap = new Map<String, String>();
    for (var key in database.aliases.keys)
    {
      var value = database.aliases[key];
      while (database.aliases.containsKey(value))
      {
        value = database.aliases[value];
      }
      timeZoneMap[key] = value;
    }

    fields.AddField(TzdbStreamFieldId.TzdbIdMap, stringPool).Writer.WriteDictionary(timeZoneMap);

    // Windows mappings
    cldrWindowsZones.write(fields.AddField(TzdbStreamFieldId.CldrSupplementalWindowsZones, stringPool).Writer);
    // Additional names from Windows Standard Name to canonical ID, used in Noda Time 1.x BclDateTimeZone, when we
    // didn't have access to TimeZoneInfo.Id.
    fields.AddField(TzdbStreamFieldId.WindowsAdditionalStandardNameToIdMapping, stringPool).Writer.WriteDictionary
      (additionalWindowsNameToIdMappings.ToDictionary(pair => pair.Key, pair => cldrWindowsZones.PrimaryMapping[pair.Value]));

    // Zone locations, if any.
    var zoneLocations = database.zoneLocations;
    if (zoneLocations != null)
    {
      var field = fields.AddField(TzdbStreamFieldId.ZoneLocations, stringPool);
      field.Writer.WriteCount(zoneLocations.length);
      for (var zoneLocation in zoneLocations)
      {
        zoneLocation.write(field.Writer);
      }
    }

    // Zone 1970 locations, if any.
    var zone1970Locations = database.zone1970Locations;
    if (zone1970Locations != null)
    {
      var field = fields.AddField(TzdbStreamFieldId.Zone1970Locations, stringPool);
      field.Writer.WriteCount(zone1970Locations.length);
      foreach (var zoneLocation in zone1970Locations)
      {
        zoneLocation.Write(field.Writer);
      }
    }

    var stringPoolField = fields.AddField(TzdbStreamFieldId.StringPool, null);
    stringPoolField.Writer.WriteCount(stringPool.length);
    for (String value in stringPool)
    {
      stringPoolField.Writer.WriteString(value);
    }

    // Now write all the fields out, in the right order.
    new BinaryWriter(stream).Write(_version);
    fields.WriteTo(stream);
  }

  static void _writeZone(DateTimeZone zone, IDateTimeZoneWriter writer)
  {
    writer.WriteString(zone.id);
    // For cached zones, simply uncache first.
    var cachedZone = zone as CachedDateTimeZone;
    if (cachedZone != null)
    {
      zone = cachedZone.timeZone;
    }
    var fixedZone = zone as FixedDateTimeZone;
    if (fixedZone != null)
    {
      writer.WriteByte((byte) DateTimeZoneWriter.DateTimeZoneType.Fixed);
      fixedZone.write(writer);
    }
    else
    {
      var precalculatedZone = zone as PrecalculatedDateTimeZone;
      if (precalculatedZone != null)
      {
        writer.WriteByte((byte) DateTimeZoneWriter.DateTimeZoneType.Precalculated);
        precalculatedZone.write(writer);
      }
      else
      {
        throw new ArgumentError("Unserializable DateTimeZone type ${zone.runtimeType}");
      }
    }
  }

  /// <summary>
  /// Creates a string pool which contains the most commonly-used strings within the given set
  /// of zones first. This will allow them to be more efficiently represented when we write them out for real.
  /// </summary>
  static List<String> _createOptimizedStringPool(
      Iterable<DateTimeZone> zones,
      Iterable<TzdbZoneLocation> zoneLocations,
      Iterable<TzdbZone1970Location> zone1970Locations,
      WindowsZones cldrWindowsZones)
  {
    var optimizingWriter = new _StringPoolOptimizingFakeWriter();
    for (var zone in zones)
    {
      optimizingWriter.WriteString(zone.id);
      _writeZone(zone, optimizingWriter);
    }
    if (zoneLocations != null)
    {
      for (var location in zoneLocations)
      {
        location.write(optimizingWriter);
      }
    }
    if (zone1970Locations != null)
    {
      for (var location in zone1970Locations)
      {
        location.write(optimizingWriter);
      }
    }
    cldrWindowsZones.write(optimizingWriter);
    return optimizingWriter.CreatePool();
  }
}

/// <summary>
/// Writer which only cares about strings. It builds a complete list of all strings written for the given
/// zones, then creates a distinct list in most-prevalent-first order. This allows the most frequently-written
/// strings to be the ones which are cheapest to write.
/// </summary>
class _StringPoolOptimizingFakeWriter implements IDateTimeZoneWriter
{
  final List<String> _allStrings = new List<String>();

  List<String> CreatePool() => _allStrings.GroupBy(x => x)
      .OrderByDescending(g => g.Count())
      .Select(g => g.Key)
      .ToList();

  void WriteString(String value)
  {
    _allStrings.add(value);
  }

  void WriteMilliseconds(int millis) { }
  void WriteOffset(Offset offset) {}
  void WriteCount(int count) { }
  void WriteByte(byte value) { }
  void WriteSignedCount(int count) { }
  void WriteZoneIntervalTransition(Instant previous, Instant value) {}

  void WriteDictionary(Map<String, String> dictionary)
  {
    dictionary.forEach((key, value) {
      WriteString(key);
      WriteString(value);
    });
  }
}

/// <summary>
/// The data for a field, including the field number itself.
/// </summary>
class _FieldData {
  // todo: private
  final MemoryStream stream;

  _FieldData(this.fieldId, List<String> stringPool) {
    this.stream = new MemoryStream();
    this.Writer = new DateTimeZoneWriter(stream, stringPool);
  }

  final IDateTimeZoneWriter Writer;
  final TzdbStreamFieldId fieldId;

  void WriteTo(Stream output) {
    output.writeByte((byte)fieldId);
    int length = (int) stream.Length;
    // We've got a 7-bit-encoding routine... might as well use it.
    new DateTimeZoneWriter(output, null).WriteCount(length);
    stream.WriteTo(output);
  }
}

class _FieldCollection
{
  final List<_FieldData> fields = [];

  _FieldData AddField(TzdbStreamFieldId fieldNumber, List<String> stringPool)
  {
    var ret = new _FieldData(fieldNumber, stringPool);
    fields.add(ret);
    return ret;
  }

  void WriteTo(Stream stream)
  {
    for (var field in fields..sort((a, b) => a.fieldId.compareTo(b.fieldId)))
    {
    field.WriteTo(stream);
    }
  }
}