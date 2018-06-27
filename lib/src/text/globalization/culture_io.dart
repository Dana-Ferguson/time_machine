// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:collection';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/platforms/platform_io.dart';

@internal
class CultureLoader {
  static Future<CultureLoader> load() async {
    var map = await _loadCultureMapping();
    return new CultureLoader._(new HashSet.from(map));
  }

  static Future<CultureLoader> loadAll() async {
    // This won't have any filenames in it.
    // It's just a dummy object that will also give [zoneIds] and [zoneIdExists] functionality
    var cultureIds = new HashSet<String>();
    var cache = <String, CultureInfo>{};

    var binary = await PlatformIO.local.getBinary('cultures', 'cultures.bin');
    var reader = new CultureReader(binary);

    while (reader.isMore) {
      var zone = reader.readCultureInfo();
      cache[zone.name] = zone;
      cultureIds.add(zone.name);
    }

    // todo: this is a good thing to log? (todo: research whether it's ok for libraries in Dart to log)
    // print('Total ${cache.length} zones loaded');

    var index = new CultureLoader._(cultureIds);
    cache.forEach((id, zone) => index._cache[id] = zone);
    return index;
  }

  CultureLoader._(this._cultureIds);
  
  static Future<List<String>> _loadCultureMapping() async {
    var json = await PlatformIO.local.getJson('cultures', 'cultures.json');
    // todo: replace with .cast<String> in Dart 2.0
    // #hack: Flutter is very angry about making sure this is a 100% List<String>
    // map((x) => x as String)
    // return json.toList<String>();
    var list = new List<String>();
    for (var item in json) {
      list.add(item as String);
    }
    return list;
  }

  final HashSet<String> _cultureIds;
  final Map<String, CultureInfo> _cache = { };

  Iterable<String> get cultureIds => _cultureIds;
  bool zoneIdExists(String zoneId) => _cultureIds.contains(zoneId);
  
  CultureInfo _cultureFromBinary(ByteData binary) {
    return new CultureReader(binary).readCultureInfo();
  }

  Future<CultureInfo> getCulture(String cultureId) async {
    return _cache[cultureId] ??= _cultureFromBinary(await PlatformIO.local.getBinary('cultures', '$cultureId.bin'));
  }

  // static String get locale => Platform.localeName;
}

@internal
class CultureReader extends BinaryReader {
  CultureReader(ByteData binary, [int offset = 0]) : super(binary, offset);

  CultureInfo readCultureInfo() {
    var name = readString();
    var datetimeFormat = readDateTimeFormatInfo();
    return new CultureInfo(name, datetimeFormat);
  }

  DateTimeFormatInfo readDateTimeFormatInfo() {
    return (new DateTimeFormatInfoBuilder()
      ..amDesignator = readString()
      ..pmDesignator = readString()
      ..timeSeparator = readString()
      ..dateSeparator = readString()

      ..abbreviatedDayNames = readStringList()
      ..dayNames = readStringList()
      ..monthNames = readStringList()
      ..abbreviatedMonthNames = readStringList()
      ..monthGenitiveNames = readStringList()
      ..abbreviatedMonthGenitiveNames = readStringList()

      ..eraNames = readStringList()
      ..calendar = BclCalendarType.values[read7BitEncodedInt()]

      ..fullDateTimePattern = readString()
      ..shortDatePattern = readString()
      ..longDatePattern = readString()
      ..shortTimePattern = readString()
      ..longTimePattern = readString())
      .Build();
  }
}
