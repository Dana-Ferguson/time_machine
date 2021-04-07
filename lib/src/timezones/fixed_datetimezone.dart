// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
// import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

// Implementation note: this implemented IEquatable<FixedDateTimeZone> for the sake of fitting in with our test infrastructure
// more than anything else...

/// Basic [DateTimeZone] implementation that has a fixed name key and offset i.e.
/// no daylight savings.
@immutable
@internal
class FixedDateTimeZone extends DateTimeZone {
  final ZoneInterval _interval;

  /// Creates a new fixed time zone.
  ///
  /// The ID and name (for the [ZoneInterval]) are generated based on the offset.
  /// [offset]: The [Offset] from UTC.
  FixedDateTimeZone.forOffset(Offset offset) : this.forIdOffset(_makeId(offset), offset);
  // todo: consider merging these constructors?

  /// Initializes a new instance of the [FixedDateTimeZone] class.
  ///
  /// The name (for the [ZoneInterval]) is deemed to be the same as the ID.
  /// [id]: The id.
  /// [offset]: The offset.
  FixedDateTimeZone.forIdOffset(String id, Offset offset) : this(id, offset, id);

  /// Initializes a new instance of the [FixedDateTimeZone] class.
  ///
  /// The name (for the [ZoneInterval]) is deemed to be the same as the ID.
  /// [id]: The id.
  /// [offset]: The offset.
  /// [name]: The name to use in the sole [ZoneInterval] in this zone.
  FixedDateTimeZone(String id, Offset offset, String name)
      : _interval = IZoneInterval.newZoneInterval(name, IInstant.beforeMinValue, IInstant.afterMaxValue, offset, Offset.zero),
        super(id, true, offset, offset);

  /// Makes the id for this time zone. The format is 'UTC+/-Offset'.
  ///
  /// [offset]: The offset.
  /// Returns: The generated id string.
  static String _makeId(Offset offset) {
    if (offset == Offset.zero) {
      return IDateTimeZone.utcId;
    }

    if (arithmeticMod(offset.inSeconds, TimeConstants.secondsPerHour) == 0) {
      return '${IDateTimeZone.utcId}${offset.inSeconds > 0 ? '+' : '-'}${(offset.inSeconds.abs() ~/ TimeConstants.secondsPerHour).toString().padLeft(2, '0')}';
    }

    return IDateTimeZone.utcId + OffsetPattern.generalInvariant.format(offset);
  }

  /// Returns a fixed time zone for the given ID, which must be 'UTC' or "UTC[offset]" where "[offset]" can be parsed
  /// using the 'general' offset pattern.
  ///
  /// [id]: ID
  /// Returns: The parsed time zone, or null if the ID doesn't match.
  static DateTimeZone? getFixedZoneOrNull(String id) {
    if (!id.startsWith(IDateTimeZone.utcId)) {
      return null;
    }
    if (id == IDateTimeZone.utcId) {
      return DateTimeZone.utc;
    }

    var parseResult = OffsetPattern.generalInvariant.parse(id.substring(IDateTimeZone.utcId.length));
    return parseResult.success ? DateTimeZone.forOffset(parseResult.value) : null;
  }

  /// Returns the fixed offset for this time zone.
  ///
  /// Returns: The fixed offset for this time zone.
  Offset get offset => maxOffset;

  /// Returns the name used for the zone interval for this time zone.
  ///
  /// Returns: The name used for the zone interval for this time zone.
  String get name => _interval.name;

  /// Gets the zone interval for the given instant. This implementation always returns the same interval.
  @override ZoneInterval getZoneInterval(Instant instant) => _interval;

  /// @override for efficiency: we know we'll always have an unambiguous mapping for any LocalDateTime.
  @override ZoneLocalMapping mapLocal(LocalDateTime localDateTime) =>
      IZoneLocalMapping.newZoneLocalMapping(this, localDateTime, _interval, _interval, 1);

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
  void write(IDateTimeZoneWriter writer) {
    Preconditions.checkNotNull(writer, 'writer');
    writer.writeOffsetSeconds(offset);
    // todo: I think we can just make this null if name == id -- see below
    writer.writeString(name);
  }

  /// Reads a fixed time zone from the specified reader.
  ///
  /// [reader]: The reader.
  /// [id]: The id.
  /// Returns: The fixed time zone.
  static DateTimeZone read(DateTimeZoneReader reader, String id) {
    Preconditions.checkNotNull(reader, 'reader');
    Preconditions.checkNotNull(id, 'id');
    var offset = reader.readOffsetSeconds();
    var name = reader.hasMoreData ? reader.readString() : id;
    return FixedDateTimeZone(id, offset, name);
  }

  /// Indicates whether this instance and a specified object are equal.
  ///
  /// true if [other] and this instance are the same type and represent the same value; otherwise, false.
  ///
  /// [other]: Another object to compare to.
  ///
  /// Returns: True if the specified value is a [FixedDateTimeZone] with the same name, ID and offset; otherwise, false.
  bool equals(FixedDateTimeZone other) =>
          offset == other.offset &&
          id == other.id &&
          name == other.name;

  @override
  bool operator ==(Object other) => other is FixedDateTimeZone && equals(other);

  /// Computes the hash code for this instance.
  ///
  /// A 32-bit signed integer that is the hash code for this instance.
  @override int get hashCode => hash3(offset, id, name);

  /// Returns a [String] that represents this instance.
  @override String toString() => id;
}
