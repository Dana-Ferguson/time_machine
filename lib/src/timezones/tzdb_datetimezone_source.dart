// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

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
  Future<DateTimeZone> forId(String id) async => (await _tzdbIndexAsync).getTimeZone(id);

  @override
  DateTimeZone forIdSync(String id) => _tzdbIndexSync.getTimeZoneSync(id);

  @override
  Future<Iterable<String>> getIds () async => (await _tzdbIndexAsync).zoneIds;

  @override
  String getSystemDefaultId() => TzdbIndex.locale;

  // TODO: forward version to tzdb_index and then get it in here! (I think nodatime is on 2018e atm?)
  @override
  Future<String> get versionId => new Future.sync(() => 'TZDB: 2018');
}

