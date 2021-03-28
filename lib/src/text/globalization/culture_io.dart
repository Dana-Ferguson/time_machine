// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:collection';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/platforms/platform_io.dart';

@internal
class CultureLoader {
  static Future<CultureLoader> load() async {
    var map = await _loadCultureMapping();
    return CultureLoader._(HashSet.from(map));
  }

  static Future<CultureLoader> loadAll() async {
    // This won't have any filenames in it.
    // It's just a dummy object that will also give [zoneIds] and [zoneIdExists] functionality
    var cultureIds = HashSet<String>();
    var cache = <String, Culture>{
      Culture.invariantId: Culture.invariant
    };

    var binary = await PlatformIO.local.getBinary('cultures', 'cultures.bin');
    var reader = CultureReader(binary);

    while (reader.isMore) {
      var zone = reader.readCulture();
      cache[zone.name] = zone;
      cultureIds.add(zone.name);
    }

    // todo: this is a good thing to log? (todo: research whether it's ok for libraries in Dart to log)
    // print('Total ${cache.length} zones loaded');

    var index = CultureLoader._(cultureIds);
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
    var list = <String>[];
    for (var item in json) {
      list.add(item as String);
    }
    return list;
  }

  final HashSet<String> _cultureIds;
  final Map<String, Culture> _cache = { };

  Iterable<String> get cultureIds => _cultureIds;
  bool zoneIdExists(String zoneId) => _cultureIds.contains(zoneId);

  Culture _cultureFromBinary(ByteData binary) {
    return CultureReader(binary).readCulture();
  }

  Future<Culture?> getCulture(String? cultureId) async {
    if (cultureId == null) return null;

    if (ICultures.allCulturesLoaded) {
      // todo: I think there is a more graceful way to handle this
      // Perform a quick check to make sure the CultureID exists;
      // see: https://github.com/Dana-Ferguson/time_machine/issues/13
      if (!_cache.containsKey(cultureId)) {
        cultureId = cultureId.split('-').first;
      }

      if (!_cache.containsKey(cultureId)) return null;
    }

    return _cache[cultureId] ??= _cultureFromBinary(await PlatformIO.local.getBinary('cultures', '$cultureId.bin'));
  }

  // static String get locale => Platform.localeName;
}

@internal
class CultureReader extends BinaryReader {
  CultureReader(ByteData binary, [int offset = 0]) : super(binary, offset);

  Culture readCulture() {
    var name = readString();
    var datetimeFormat = readDateTimeFormatInfo();
    return Culture(name, datetimeFormat);
  }

  DateTimeFormat readDateTimeFormatInfo() {
    return (DateTimeFormatBuilder()
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
      ..calendar = CalendarType.values[read7BitEncodedInt()]

      ..fullDateTimePattern = readString()
      ..shortDatePattern = readString()
      ..longDatePattern = readString()
      ..shortTimePattern = readString()
      ..longTimePattern = readString())
      .Build();
  }
}
