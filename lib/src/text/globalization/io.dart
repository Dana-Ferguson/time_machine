import 'dart:collection';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_timezones.dart';

import 'dart:typed_data';
import 'dart:convert';

import 'dart:async';
import 'dart:io';

@internal
class CultureLoader {
  static Future<CultureLoader> load() async {
    var map = await _loadCultureMapping();
    return new CultureLoader._(new HashSet.from(map));
  }

  CultureLoader._(this._cultureIds);

  static Future _getJson(String path) async {
    // Keep as much as the repeated path arguments in here as possible
    var file = new File('${Directory.current.path}/lib/data/cultures/$path');
    return JSON.decode(await file.readAsString());
  }

  static Future<List<String>> _loadCultureMapping() async {
    var json = _getJson('cultures.json');
    return json;
  }

  final HashSet<String> _cultureIds;
  final Map<String, CultureInfo> _cache = { };

  Iterable<String> get cultureIds => _cultureIds;
  bool zoneIdExists(String zoneId) => _cultureIds.contains(zoneId);

  Future<ByteData> _getBinary(String zoneId) async {
    var filename = zoneId;
    if (filename == null) return new ByteData(0);

    var file = new File('${Directory.current.path}/lib/data/cultures/$filename.bin');
    // todo: probably a better way to do this
    var binary = new ByteData.view(new Int8List.fromList(await file.readAsBytes()).buffer);
    return binary;
  }

  CultureInfo _cultureFromBinary(ByteData binary) {
    return new CultureReader(binary).readCultureInfo();
  }

  Future<CultureInfo> getCulture(String cultureId) async {
    return _cache[cultureId] ??= _cultureFromBinary(await _getBinary(cultureId));
  }

  static String get locale => Platform.localeName;
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