// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_timezones.dart';

// Implementation note: this implemented IEquatable<FixedDateTimeZone> for the sake of fitting in with our test infrastructure
// more than anything else...

/// Basic [DateTimeZone] implementation that has a fixed name key and offset i.e.
/// no daylight savings.
///
/// <threadsafety>This type is immutable reference type. See the thread safety section of the user guide for more information.</threadsafety>
// sealed
@internal class FixedDateTimeZone extends DateTimeZone // implements IEquatable<FixedDateTimeZone>
{
@private final ZoneInterval interval;

/// Creates a new fixed time zone.
///
/// The ID and name (for the [ZoneInterval]) are generated based on the offset.
/// [offset]: The [Offset] from UTC.
@internal FixedDateTimeZone.forOffset(Offset offset) : this.forIdOffset(MakeId(offset), offset);

/// Initializes a new instance of the [FixedDateTimeZone] class.
///
/// The name (for the [ZoneInterval]) is deemed to be the same as the ID.
/// [id]: The id.
/// [offset]: The offset.
@internal FixedDateTimeZone.forIdOffset(String id, Offset offset) : this(id, offset, id);

/// Initializes a new instance of the [FixedDateTimeZone] class.
///
/// The name (for the [ZoneInterval]) is deemed to be the same as the ID.
/// [id]: The id.
/// [offset]: The offset.
/// [name]: The name to use in the sole [ZoneInterval] in this zone.
@internal FixedDateTimeZone(String id, Offset offset, String name) :
      interval = new ZoneInterval(name, Instant.beforeMinValue, Instant.afterMaxValue, offset, Offset.zero),
      super(id, true, offset, offset);

/// Makes the id for this time zone. The format is "UTC+/-Offset".
///
/// [offset]: The offset.
/// Returns: The generated id string.
@private static String MakeId(Offset offset) {
  if (offset == Offset.zero) {
    return DateTimeZone.utcId;
  }

  if (csharpMod(offset.seconds, TimeConstants.secondsPerHour) == 0) {
    return '${DateTimeZone.utcId}${offset.seconds > 0 ? '+' : '-'}${(offset.seconds.abs() ~/ TimeConstants.secondsPerHour).toString().padLeft(2, '0')}';
  }

  return DateTimeZone.utcId + OffsetPattern.GeneralInvariant.Format(offset);
}

/// Returns a fixed time zone for the given ID, which must be "UTC" or "UTC[offset]" where "[offset]" can be parsed
/// using the "general" offset pattern.
///
/// [id]: ID 
/// Returns: The parsed time zone, or null if the ID doesn't match.
@internal static DateTimeZone GetFixedZoneOrNull(String id) {
  if (!id.startsWith(DateTimeZone.utcId)) {
    return null;
  }
  if (id == DateTimeZone.utcId) {
    return DateTimeZone.utc;
  }

//print('WARN: WE CAN NOT PARSE DATETIMEZONE IDs AT THIS TIME. SAD FACE.'); // ${StackTrace.current}'); // todo: get real parsing
//return null;

  var parseResult = OffsetPattern.GeneralInvariant.Parse(id.substring(DateTimeZone.utcId.length));
  return parseResult.Success ? new DateTimeZone.forOffset(parseResult.Value) : null;
}

/// Returns the fixed offset for this time zone.
///
/// Returns: The fixed offset for this time zone.
Offset get offset => maxOffset;

/// Returns the name used for the zone interval for this time zone.
///
/// Returns: The name used for the zone interval for this time zone.
String get Name => interval.name;

/// Gets the zone interval for the given instant. This implementation always returns the same interval.
@override ZoneInterval getZoneInterval(Instant instant) => interval;

/// @override for efficiency: we know we'll always have an unambiguous mapping for any LocalDateTime.
@override ZoneLocalMapping mapLocal(LocalDateTime localDateTime) =>
new ZoneLocalMapping(this, localDateTime, interval, interval, 1);

/// Returns the offset from UTC, where a positive duration indicates that local time is later
/// than UTC. In other words, local time = UTC + offset.
///
/// [instant]: The instant for which to calculate the offset.
///
/// The offset from UTC at the specified instant.
@override Offset getUtcOffset(Instant instant) => maxOffset;

/// Writes the time zone to the specified writer.
///
/// [writer]: The writer.
@internal void Write(IDateTimeZoneWriter writer)
{
  throw new UnimplementedError('This feature is not supported.');
//  Preconditions.checkNotNull(writer, 'writer');
//  writer.WriteOffset(Offset);
//  writer.WriteString(Name);
}

/// Reads a fixed time zone from the specified reader.
///
/// [reader]: The reader.
/// [id]: The id.
/// Returns: The fixed time zone.
static DateTimeZone Read(DateTimeZoneReader reader, String id)
{
  Preconditions.checkNotNull(reader, 'reader');
  Preconditions.checkNotNull(id, 'id');
  var offset = reader.readOffsetSeconds();
  var name = reader.hasMoreData ? reader.readString() : id;
  return new FixedDateTimeZone(id, offset, name);
}

/// Indicates whether this instance and a specified object are equal.
///
/// true if [obj] and this instance are the same type and represent the same value; otherwise, false.
///
/// [obj]: Another object to compare to.
/// <filterpriority>2</filterpriority>
/// Returns: True if the specified value is a [FixedDateTimeZone] with the same name, ID and offset; otherwise, false.
// @override bool Equals(object obj) => Equals(obj as FixedDateTimeZone);

bool Equals(FixedDateTimeZone other) =>
  other != null &&
  offset == other.offset &&
  id == other.id &&
  Name == other.Name;

bool operator==(dynamic other) => other is FixedDateTimeZone && Equals(other);

/// Computes the hash code for this instance.
///
/// A 32-bit signed integer that is the hash code for this instance.
///
/// <filterpriority>2</filterpriority>
@override int get hashCode => hash3(offset, id, Name);

/// Returns a [String] that represents this instance.
///
/// A [String] that represents this instance.
@override String toString() => id;
}
