// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/TzdbDateTimeZoneSource.cs
// 407f018  on Aug 31, 2017

import 'dart:math' as math;
import 'dart:async';

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

abstract class DateTimeZoneProviders {
  // todo: await ... await ... patterns are so ick.
  static Future<IDateTimeZoneProvider> Tzdb = DateTimeZoneCache.getCache(new TzdbDateTimeZoneSource());
}

class TzdbDateTimeZoneSource extends IDateTimeZoneSource {
  static Future _init() async {
    if (_tzdbIndexSync != null) return;
    _tzdbIndexSync = await TzdbIndex.load();
  }

  static TzdbIndex _tzdbIndexSync;
  static Future<TzdbIndex> _tzdbIndexAsync = _init().then((_) => _tzdbIndexSync);

  @override
  Future<DateTimeZone> ForId(String id) async => (await _tzdbIndexAsync).getTimeZone(id);

  @override
  DateTimeZone ForIdSync(String id) => _tzdbIndexSync.getTimeZoneSync(id);

  @override
  Future<Iterable<String>> GetIds () async => (await _tzdbIndexAsync).zoneIds;

  @override
  String GetSystemDefaultId() => TzdbIndex.locale;

  // TODO: forward version to tzdb_index and then get it in here! (I think nodatime is on 2018e atm?)
  @override
  Future<String> get VersionId => new Future.sync(() => 'TZDB: 2018');
}
