// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/FixedDateTimeZone.cs
// cb92068  on Dec 29, 2016

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

// Implementation note: this implemented IEquatable<FixedDateTimeZone> for the sake of fitting in with our test infrastructure
// more than anything else...

/// <summary>
/// Basic <see cref="DateTimeZone" /> implementation that has a fixed name key and offset i.e.
/// no daylight savings.
/// </summary>
/// <threadsafety>This type is immutable reference type. See the thread safety section of the user guide for more information.</threadsafety>
// sealed
@internal class FixedDateTimeZone extends DateTimeZone // implements IEquatable<FixedDateTimeZone>
{
@private final ZoneInterval interval;

/// <summary>
/// Creates a new fixed time zone.
/// </summary>
/// <remarks>The ID and name (for the <see cref="ZoneInterval"/>) are generated based on the offset.</remarks>
/// <param name="offset">The <see cref="Offset"/> from UTC.</param>
@internal FixedDateTimeZone.forOffset(Offset offset) : this.forIdOffset(MakeId(offset), offset);

/// <summary>
/// Initializes a new instance of the <see cref="FixedDateTimeZone"/> class.
/// </summary>
/// <remarks>The name (for the <see cref="ZoneInterval"/>) is deemed to be the same as the ID.</remarks>
/// <param name="id">The id.</param>
/// <param name="offset">The offset.</param>
@internal FixedDateTimeZone.forIdOffset(String id, Offset offset) : this(id, offset, id);

/// <summary>
/// Initializes a new instance of the <see cref="FixedDateTimeZone"/> class.
/// </summary>
/// <remarks>The name (for the <see cref="ZoneInterval"/>) is deemed to be the same as the ID.</remarks>
/// <param name="id">The id.</param>
/// <param name="offset">The offset.</param>
/// <param name="name">The name to use in the sole <see cref="ZoneInterval"/> in this zone.</param>
@internal FixedDateTimeZone(String id, Offset offset, String name) :
      interval = new ZoneInterval(name, Instant.BeforeMinValue, Instant.AfterMaxValue, offset, Offset.zero),
      this(id, true, offset, offset);

/// <summary>
/// Makes the id for this time zone. The format is "UTC+/-Offset".
/// </summary>
/// <param name="offset">The offset.</param>
/// <returns>The generated id string.</returns>
@private static String MakeId(Offset offset) {
  if (offset == Offset.zero) {
    return UtcId;
  }
  return UtcId + OffsetPattern.GeneralInvariant.Format(offset);
}

/// <summary>
/// Returns a fixed time zone for the given ID, which must be "UTC" or "UTC[offset]" where "[offset]" can be parsed
/// using the "general" offset pattern.
/// </summary>
/// <param name="id">ID </param>
/// <returns>The parsed time zone, or null if the ID doesn't match.</returns>
@internal static DateTimeZone GetFixedZoneOrNull(String id) {
  if (!id.startsWith(UtcId)) {
    return null;
  }
  if (id == UtcId) {
    return Utc;
  }
  var parseResult = OffsetPattern.GeneralInvariant.Parse(id.Substring(UtcId.Length));
  return parseResult.Success ? ForOffset(parseResult.Value) : null;
}

/// <summary>
/// Returns the fixed offset for this time zone.
/// </summary>
/// <returns>The fixed offset for this time zone.</returns>
Offset get offset => maxOffset;

/// <summary>
/// Returns the name used for the zone interval for this time zone.
/// </summary>
/// <returns>The name used for the zone interval for this time zone.</returns>
String get Name => interval.name;

/// <summary>
/// Gets the zone interval for the given instant. This implementation always returns the same interval.
/// </summary>
@override ZoneInterval GetZoneInterval(Instant instant) => interval;

/// <summary>
/// @override for efficiency: we know we'll always have an unambiguous mapping for any LocalDateTime.
/// </summary>
@override ZoneLocalMapping MapLocal(LocalDateTime localDateTime) =>
new ZoneLocalMapping(this, localDateTime, interval, interval, 1);

/// <summary>
/// Returns the offset from UTC, where a positive duration indicates that local time is later
/// than UTC. In other words, local time = UTC + offset.
/// </summary>
/// <param name="instant">The instant for which to calculate the offset.</param>
/// <returns>
/// The offset from UTC at the specified instant.
/// </returns>
@override Offset GetUtcOffset(Instant instant) => maxOffset;

/// <summary>
/// Writes the time zone to the specified writer.
/// </summary>
/// <param name="writer">The writer.</param>
@@internal void Write(IDateTimeZoneWriter writer)
{
  Preconditions.checkNotNull(writer, 'writer');
  writer.WriteOffset(Offset);
  writer.WriteString(Name);
}

/// <summary>
/// Reads a fixed time zone from the specified reader.
/// </summary>
/// <param name="reader">The reader.</param>
/// <param name="id">The id.</param>
/// <returns>The fixed time zone.</returns>
static DateTimeZone Read(IDateTimeZoneReader reader, String id)
{
Preconditions.checkNotNull(reader, 'reader');
Preconditions.checkNotNull(id, 'id');
var offset = reader.ReadOffset();
var name = reader.HasMoreData ? reader.ReadString() : id;
return new FixedDateTimeZone(id, offset, name);
}

/// <summary>
/// Indicates whether this instance and a specified object are equal.
/// </summary>
/// <returns>
/// true if <paramref name="obj"/> and this instance are the same type and represent the same value; otherwise, false.
/// </returns>
/// <param name="obj">Another object to compare to.</param>
/// <filterpriority>2</filterpriority>
/// <returns>True if the specified value is a <see cref="FixedDateTimeZone"/> with the same name, ID and offset; otherwise, false.</returns>
// @override bool Equals(object obj) => Equals(obj as FixedDateTimeZone);

bool Equals(FixedDateTimeZone other) =>
other != null &&
Offset == other.offset &&
id == other.id &&
Name == other.Name;

/// <summary>
/// Computes the hash code for this instance.
/// </summary>
/// <returns>
/// A 32-bit signed integer that is the hash code for this instance.
/// </returns>
/// <filterpriority>2</filterpriority>
@override int get hashCode => hash3(offset, id, Name);

/// <summary>
/// Returns a <see cref="System.String"/> that represents this instance.
/// </summary>
/// <returns>
/// A <see cref="System.String"/> that represents this instance.
/// </returns>
@override String toString() => id;
}