// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_timezones.dart';

// todo: I think we need an easy way for library users to inject their own IDateTimeZoneSource
abstract class DateTimeZoneProviders {
  // todo: await ... await ... patterns are so ick.

  static Future<IDateTimeZoneProvider> _tzdb;

  static Future<IDateTimeZoneProvider> get tzdb => _tzdb ??= DateTimeZoneCache.getCache(new TzdbDateTimeZoneSource());

  static IDateTimeZoneProvider _defaultProvider;
  /// This is the default [IDateTimeZoneProvider] for the currently loaded TimeMachine.
  /// It will be used internally where-ever timezone support is needed when no provider is provided,
  static IDateTimeZoneProvider get defaultProvider => _defaultProvider;
  
  @internal
  static void set defaultProvider(IDateTimeZoneProvider provider) => _defaultProvider = provider;
}

class TzdbDateTimeZoneSource extends IDateTimeZoneSource {
  static Future _init() async {
    if (_cachedTzdbIndex != null) return;
    _cachedTzdbIndex = await TzdbIndex.load();

    /*
    try {
      DateTimeZoneProviders._defaultProvider ??=
      await DateTimeZoneProviders.tzdb; // (DateTimeZoneProviders._tzdb ?? DateTimeZoneCache.getCache(new TzdbDateTimeZoneSource()));
    }
    catch (e) {
      print(e);
    }*/
  }

  static TzdbIndex _cachedTzdbIndex;
  static Future<TzdbIndex> _tzdbIndexAsync = _cachedTzdbIndex != null
      ? new Future.value(_cachedTzdbIndex)
      : _init().then((_) => _cachedTzdbIndex);

  @override
  Future<DateTimeZone> forId(String id) async => (await _tzdbIndexAsync).getTimeZone(id);

  @override
  DateTimeZone forCachedId(String id) => _cachedTzdbIndex.getTimeZoneSync(id);

  @override
  Future<Iterable<String>> getIds() async => (await _tzdbIndexAsync).zoneIds;

  @override
  String get systemDefaultId => TzdbIndex.localId;

  // TODO: forward version to tzdb_index and then get it in here! (I think nodatime is on 2018e atm?)
  @override
  Future<String> get versionId => new Future.sync(() => 'TZDB: 2018');
}

