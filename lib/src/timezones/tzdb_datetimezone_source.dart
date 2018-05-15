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
  static Future<TzdbIndex> _tzdbIndex = TzdbIndex.load();

  @override
  Future<DateTimeZone> ForId(String id) async => (await _tzdbIndex).getTimeZone(id);

  @override
  Future<Iterable<String>> GetIds () async => (await _tzdbIndex).zoneIds;

  @override
  String GetSystemDefaultId() => TzdbIndex.locale;

  // TODO: forward version to tzdb_index and then get it in here!
  @override
  Future<String> get VersionId => new Future.sync(() => 'version_super!');
}
