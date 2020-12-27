// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

import 'binary_writer.dart';

@internal
class DateTimeZoneWriter implements BinaryWriter, IDateTimeZoneWriter {
  final BinaryWriter _writer;

  DateTimeZoneWriter(this._writer);

  @override
  void writeZoneInterval(ZoneInterval zoneInterval) {
    int flag = 0;
    bool longStartRequired = false;
    bool longEndRequired = false;

    if (zoneInterval.hasStart)
    {
      var longStart = zoneInterval.start.epochSeconds;
      longStartRequired = longStart < Platform.int32MinValue || longStart > Platform.int32MaxValue;

      flag |= 1;
      if (longStartRequired) flag |= 1 << 2;
    }

    if (zoneInterval.hasEnd)
    {
      var longEnd = zoneInterval.end.epochSeconds;
      longEndRequired = longEnd < Platform.int32MinValue || longEnd > Platform.int32MaxValue;

      flag |= 2;
      if (longEndRequired) flag |= 1 << 3;
    }
    _writer.writeUint8(flag);

    if (zoneInterval.hasStart) {
      if (zoneInterval.start.epochNanoseconds % TimeConstants.nanosecondsPerSecond != 0) throw Exception('zoneInterval.Start not seconds.');
      if (longStartRequired) _writer.writeInt64(zoneInterval.start.epochSeconds);
      else _writer.writeInt32(zoneInterval.start.epochSeconds); // .ToUnixTimeMilliseconds());
    }

    if (zoneInterval.hasEnd) {
      if (zoneInterval.end.epochNanoseconds % TimeConstants.nanosecondsPerSecond != 0) throw Exception('zoneInterval.End not seconds.');
      if (longEndRequired) _writer.writeInt64(zoneInterval.end.epochSeconds);
      else _writer.writeInt32(zoneInterval.end.epochSeconds); // .ToUnixTimeMilliseconds());
    }

    _writer.writeInt32(zoneInterval.wallOffset.inSeconds);
    _writer.writeInt32(zoneInterval.savings.inSeconds);
  }

  // todo: this is a bit ugly

  @override
  Future close() => _writer.close();

  @override
  void write7BitEncodedInt(int value) => _writer.write7BitEncodedInt(value);

  @override
  void writeBool(bool value) => _writer.writeBool(value);

  @override
  void writeInt32(int value) => _writer.writeInt32(value);

  @override
  void writeInt64(int value) => _writer.writeInt64(value);

  @override
  void writeOffsetSeconds(Offset value) => _writer.writeOffsetSeconds(value);

  @override
  void writeOffsetSeconds2(Offset value) => _writer.writeOffsetSeconds2(value);

  @override
  void writeString(String value) => _writer.writeString(value);

  @override
  void writeStringList(List<String> list) => _writer.writeStringList(list);

  @override
  void writeUint8(int value) => _writer.writeUint8(value);

  /// Writes the given dictionary of string to string to the stream.
  /// </summary>
  /// <param name='dictionary'>The <see cref="IDictionary{TKey,TValue}" /> to write.</param>
  @override
  void writeDictionary(Map<String, String> map) {
    Preconditions.checkNotNull(map, 'map');

    _writer.write7BitEncodedInt(map.length);
    for (var entry in map.entries) {
      _writer.writeString(entry.key);
      _writer.writeString(entry.value);
    }
  }
}


