// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

// todo: the Internal Classes here make me sad

@internal
abstract class IDateTimeZoneProviders {
  static set defaultProvider(DateTimeZoneProvider provider) => DateTimeZoneProviders._defaultProvider = provider;
}


// todo: I think we need an easy way for library users to inject their own IDateTimeZoneSource
abstract class DateTimeZoneProviders {
  // todo: await ... await ... patterns are so ick.

  static Future<DateTimeZoneProvider>? _tzdb;

  static Future<DateTimeZoneProvider> get tzdb => _tzdb ??= DateTimeZoneCache.getCache(TzdbDateTimeZoneSource());

  static DateTimeZoneProvider? _defaultProvider;
  /// This is the default [DateTimeZoneProvider] for the currently loaded TimeMachine.
  /// It will be used internally where-ever timezone support is needed when no provider is provided,
  static DateTimeZoneProvider? get defaultProvider => _defaultProvider;
}

@internal
class ITzdbDateTimeZoneSource {
  static void loadAllTimeZoneInformation_SetFlag() {
    if (TzdbDateTimeZoneSource._cachedTzdbIndex != null) throw StateError('loadAllTimeZone flag may not be set after TZDB is initalized.');
    TzdbDateTimeZoneSource._loadAllTimeZoneInformation = true;
  }
}

class TzdbDateTimeZoneSource extends DateTimeZoneSource {
  // todo: this is a bandaid ~ we need to rework our infrastructure a bit -- maybe draw some diagrams?
  // This gives us the JS functionality of just minimizing our timezones, and it gives us the VM/Flutter functionality of just loading them all from one file.
  static bool _loadAllTimeZoneInformation = false;

  static Future _init() async {
    if (_cachedTzdbIndex != null) return;

    if (_loadAllTimeZoneInformation) {
      _cachedTzdbIndex = await TzdbIndex.loadAll();
    }
    else {
      _cachedTzdbIndex = await TzdbIndex.load();
    }

    /*
    try {
      DateTimeZoneProviders._defaultProvider ??=
      await DateTimeZoneProviders.tzdb; // (DateTimeZoneProviders._tzdb ?? DateTimeZoneCache.getCache(new TzdbDateTimeZoneSource()));
    }
    catch (e) {
      print(e);
    }*/
  }

  static TzdbIndex? _cachedTzdbIndex;
  static final Future<TzdbIndex> _tzdbIndexAsync = _cachedTzdbIndex != null
      ? Future.value(_cachedTzdbIndex)
      : _init().then((_) => _cachedTzdbIndex!);

  @override
  Future<DateTimeZone> forId(String id) async => (await _tzdbIndexAsync).getTimeZone(id);

  @override
  DateTimeZone forCachedId(String id) => _cachedTzdbIndex!.getTimeZoneSync(id)!;

  @override
  Future<Iterable<String>> getIds() async => (await _tzdbIndexAsync).zoneIds;

  @override
  String get systemDefaultId => TzdbIndex.localId;

  // TODO: forward version to tzdb_index and then get it in here! (I think nodatime is on 2018e atm?)
  @override
  Future<String> get versionId => Future.sync(() => 'TZDB: 2018');
}

