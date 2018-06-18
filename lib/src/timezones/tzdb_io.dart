// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.


import 'dart:typed_data';
import 'dart:async';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_timezones.dart';
import 'package:time_machine/src/platforms/platform_io.dart';

@internal
class TzdbIndex {
  static Future<TzdbIndex> load() async {
    var _jsonMap = await _loadIdMapping();
    
    // todo: seek a more elegant mapping of <String, dynamic> to <String, String>
    var map = <String, String>{DateTimeZone.utcId: ''};
    _jsonMap.forEach((key, value){
      map[key] = value;
    });
    
    return new TzdbIndex._(map);
  }

  TzdbIndex._(this._zoneFilenames);

  static Future<Map<String, dynamic>> _loadIdMapping() async {
    var json = await PlatformIO.local.getJson('tzdb', 'tzdb.json');
    return json;
  }

  final Map<String, String> _zoneFilenames;
  final Map<String, DateTimeZone> _cache = { DateTimeZone.utcId: DateTimeZone.utc };

  Iterable<String> get zoneIds => _zoneFilenames.keys;
  bool zoneIdExists(String zoneId) => _zoneFilenames.containsKey(zoneId);
  
  DateTimeZone _zoneFromBinary(ByteData binary) {
    var reader = new DateTimeZoneReader(binary);
    // this should be the same as the index id
    var id = reader.readString();
    var zone = PrecalculatedDateTimeZone.read(reader, id);
    return zone;
  }

  Future<DateTimeZone> getTimeZone(String zoneId) async {
    var filename = _zoneFilenames[zoneId];
    if (filename == null) throw new DateTimeZoneNotFoundError('$zoneId had no associated filename.');
    
    return _cache[zoneId] ??
        (_cache[zoneId] = _zoneFromBinary(await PlatformIO.local.getBinary('tzdb', '$filename.bin')));
  }

  DateTimeZone getTimeZoneSync(String zoneId) {
    return _cache[zoneId]; // ?? null;
  // todo: check to see if we have binary loaded data
  // (_cache[zoneId] = _zoneFromBinary(await _getBinary(zoneId)));
  }

  // Default to UTC if we fail to set a local [DateTimeZone]
  static String localId = DateTimeZone.utcId; // => Platform.localeName;
}

@internal
class DateTimeZoneReader extends BinaryReader {
  DateTimeZoneReader(ByteData binary, [int offset = 0]) : super(binary, offset);

  ZoneInterval readZoneInterval() {
    var name = /*stream.*/readString();
    var flag = /*stream.*/readUint8();
    bool startIsLong = (flag & (1 << 2)) != 0;
    bool endIsLong = (flag & (1 << 3)) != 0;
    bool hasStart = (flag & 1) == 1;
    bool hasEnd = (flag & 2) == 2;
    int startSeconds = null;
    int endSeconds = null;

    if (hasStart) {
      if (startIsLong) startSeconds = readInt64();
      else startSeconds = /*stream.*/readInt32();
    }
    if (hasEnd) {
      if (endIsLong) endSeconds = readInt64();
      else endSeconds = /*stream.*/readInt32();
    }

    Instant start = startSeconds == null ? Instant.beforeMinValue : new Instant.fromUnixTimeSeconds(startSeconds);
    Instant end = endSeconds == null ? Instant.afterMaxValue : new Instant.fromUnixTimeSeconds(endSeconds);

    var wallOffset = /*stream.*/readOffsetSeconds2(); // Offset.fromSeconds(stream.readInt32());
    var savings = /*stream.*/readOffsetSeconds2(); // Offset.fromSeconds(stream.readInt32());
    return new ZoneInterval(name, start, end, wallOffset, savings);
  }
}


