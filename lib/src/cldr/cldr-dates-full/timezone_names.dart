import 'package:meta/meta.dart';

import 'package:time_machine/time_machine_cldr.dart';

@immutable
class CldrZone {
  final String key;
  final String exemplarCity;

  CldrZone(this.key, this.exemplarCity);
}

// todo: this is more technically -- just a readonly map -- easier to use ?? var m = new Map.unmodifiable(other);
@immutable
class ExemplarCityMap {
  final Map<String, dynamic> _map;

  ExemplarCityMap(this._map);

  Iterable<String> operator [](List<String> keys) {
    dynamic value = _map;
    for(var key in keys) {
      value = value[key];
      // print('  ${value.runtimeType} -- ${value.keys}');
    }

    if (value is Map<String, dynamic>) {
      if (value.length == 1 && value.keys.first == 'exemplarCity') return value.values;
      return value.keys;
    }
    return const Iterable.empty();
  }

  static Iterable<String> _getExemplarCities(Map<String, dynamic> map) sync* {
    if (map.length == 1 && map.keys.first == 'exemplarCity') {
      yield map.values.first;
    } else {
      for (var value in map.values) {
        if (value is Map<String, dynamic>) {
          yield* _getExemplarCities(value);
        }
      }
    }
  }

  Iterable<String> get cities sync* {
    yield* _getExemplarCities(_map);
  }
}

@immutable
class CldrMetaZoneInfo {
  final String generic;
  final String standard;
  final String daylight;

  CldrMetaZoneInfo._(this.generic, this.standard, this.daylight);
  factory CldrMetaZoneInfo(Map<String, dynamic> map) {
    // assertTotalItems(map, 3);
    assertItemsCount(map, (i) => i <= 3);
    var generic = map['generic'];
    var standard = map['standard'];
    var daylight = map['daylight'];
    return new CldrMetaZoneInfo._(generic, standard, daylight);
  }
}

@immutable
class CldrMetaZone {
  final CldrMetaZoneInfo long;
  final CldrMetaZoneInfo short;

  CldrMetaZone._(this.long, this.short);
  factory CldrMetaZone(Map<String, dynamic> map) {
    CldrMetaZoneInfo long, short;
    if (map.containsKey('long')) long = new CldrMetaZoneInfo(map['long']);
    if (map.containsKey('short')) short = new CldrMetaZoneInfo(map['short']);
    if (map.keys.length > 2) throw new StateError('CldrMetaZone too many keys. Keys = ${map.keys}');

    return new CldrMetaZone._(long, short);
  }
}

@immutable
class DateTimeZoneNames {
  final String id;
  final CldrIdentity identity;

  final String hourFormat;
  final String gmtFormat;
  final String gmtZeroFormat;
  final String regionFormat;
  final String regionFormat_type_daylight;
  final String regionFormat_type_standard;
  final String fallbackFormat;

  // todo: should I call these zone something?
  final ExemplarCityMap exemplarCities;
  // todo: also probably a bad name
  final Map<String, CldrMetaZone> zoneMetas;

  DateTimeZoneNames.from(this.id, this.identity, this.hourFormat, this.gmtFormat, this.gmtZeroFormat,
      this.regionFormat, this.regionFormat_type_daylight, this.regionFormat_type_standard, this.fallbackFormat,
      this.exemplarCities, this.zoneMetas);
  factory DateTimeZoneNames(String id, Map<String, dynamic> json) {
    assertTotalItems(json.keys, 1);

    var main = json['main'];
    assertTotalItems(main.keys, 1);

    var locale = main[id];
    // print(locale.keys);
    assertTotalItems(locale.keys, 2);

    var identity = new CldrIdentity(locale['identity']);
    var dates = locale['dates'];
    assertTotalItems(dates.keys, 1);

    var timeZoneNames = dates['timeZoneNames'];
    assertTotalItems(timeZoneNames.keys, 9);

    var hourFormat = timeZoneNames['hourFormat'];
    var gmtFormat = timeZoneNames['gmtFormat'];
    var gmtZeroFormat = timeZoneNames['gmtZeroFormat'];
    var regionFormat = timeZoneNames['regionFormat'];
    var regionFormat_type_daylight = timeZoneNames['regionFormat-type-daylight'];
    var regionFormat_type_standard = timeZoneNames['regionFormat-type-standard'];
    var fallbackFormat = timeZoneNames['fallbackFormat'];

    var exemplarCities = new ExemplarCityMap(timeZoneNames['zone']);
    Map<String, CldrMetaZone> zoneMetas = {};

    for (String key in timeZoneNames['metazone'].keys) {
      Map<String, dynamic> value = timeZoneNames['metazone'][key];
      zoneMetas[key] = new CldrMetaZone(value);
    }

    return new DateTimeZoneNames.from(id, identity, hourFormat, gmtFormat, gmtZeroFormat, regionFormat,
        regionFormat_type_daylight, regionFormat_type_standard, fallbackFormat, exemplarCities, new Map.unmodifiable(zoneMetas));
  }
}