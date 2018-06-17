// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_timezones.dart';

/// Easy in Quotes.. since we can't
Future<String> getTimeZoneEasy() async {
  // Getting CLDR timezone from here is the dream.
  var x = new DateTime.now();
  /*
    Linux:
    
    EDT
    -4:00:00.000000
    en_US.UTF-8
    
    Windows: (or Chrome: Linux & Windows)
    
    Eastern Daylight Time
    -4:00:00.000000
    en-US
  */
  print(x.timeZoneName); // <-- this is not a timezone
  print(x.timeZoneOffset);
  print(Platform.localeName);


  return null;
}

// todo: extract to interface for VM, Web
class TimeMachine  {
  // I'm looking to basically use @internal for protection
  static Future initialize() async {
    // todo: for VM, always load everything (happens inside of _figureOutTimeZone)
    // Default provider
    var tzdb = await DateTimeZoneProviders.tzdb;
    DateTimeZoneProviders.defaultProvider = tzdb;

    // Default TimeZone
    //var localTimezoneId = await _getTimeZoneId();
    //var local = await tzdb[localTimezoneId];
    
    var local = await _figureOutTimeZone(tzdb);
    // todo: cache local more directly? (this is indirect caching)
    TzdbIndex.localId = local.id;

    // Default Culture
    var cultureId = Platform.localeName.split('.').first.replaceAll('_', '-');
    var culture = await Cultures.getCulture(cultureId);
    Cultures.currentCulture = culture;
    // todo: remove CultureInfo.currentCulture
  }

  /// [DateTimeZone] provides the zone interval id for a given instant. We can correlate the (zone interval id, instant) pairs
  /// with known timezones and narrow down which timezone the local computer is in.
  ///
  /// note: during testing, bugs were found with dart's zone interval id -- it sometimes does daylight savings when it didn't exist 
  static Future<DateTimeZone> _figureOutTimeZone(IDateTimeZoneProvider provider, [bool strict = false]) async {
    var zones = <DateTimeZone>[];
    // load all the timezones
    for (var id in provider.ids) {
      zones.add(await provider[id]);
    }

    var nowDateTime = new DateTime.now();
    Instant nowInstant = new Instant.fromDateTime(nowDateTime);
    var interval = new Interval(new Instant.fromUtc(1900, 1, 1, 0, 0), nowInstant);
    var allZoneIntervals = <ZoneInterval>[];
    var allSpecialInstants = <Instant>[];

    var lessZones = new List<DateTimeZone>();
    for (var zone in zones) {
      // first pass
      if (_isTheSame(nowDateTime, zone.getZoneInterval(nowInstant))) {
        allZoneIntervals.addAll(zone.getZoneIntervals(interval));
        lessZones.add(zone);
      }
    }

    allSpecialInstants = allZoneIntervals.map((z) => z.rawStart);
    var badZones = new HashSet<String>();

    zones = lessZones;
    // print('allSpecialInstants: ${allSpecialInstants.length}; ${allZoneIntervals.length}; ${zones.length};');

    // int i = 0;
    // todo: we need a table to convert between abbreviations and long form zone interval id's
    // see: https://en.wikipedia.org/wiki/List_of_time_zone_abbreviations
    for (var instant in allSpecialInstants) {
      if (instant.isValid) {
        var dt = instant.toDateTimeLocal();

        for (var zone in zones) {
          var zoneInterval = zone.getZoneInterval(instant);
          if (dt.timeZoneName != zoneInterval.name || dt.timeZoneOffset.inSeconds != zoneInterval.wallOffset.seconds) {
            badZones.add(zone.id);
          }
        }

        // i++;
        if (badZones.length != 0) {
          // print('$i :: $badZones');
          zones.removeWhere((z) => badZones.contains(z.id));
          badZones.clear();
        }

        if (!strict && zones.length <= 1) {
          if (zones.length == 1) {
            return zones.first;
          }
          return null;
        }
      }
    }

    // Ambiguous -- just picking the first result
    return zones.first;
  }

  static bool _isTheSame(DateTime dateTime, ZoneInterval zoneInterval) {
    return dateTime.timeZoneName == zoneInterval.name
        && dateTime.timeZoneOffset.inSeconds == zoneInterval.wallOffset.seconds;
  }

  // This is slower (on at least one computer) than guessing the timezone
  // Plus, since this type of solution will have a high number of corner cases
  // for the time, the above method is preferred.
  static Future<String> _getTimeZoneId() async {
    try {
      if (Platform.isFuchsia) {
        //
      }
      else if (Platform.isLinux) {
        // e.g. cat /etc/timezone /g --> 'America/New_York\n'
        var id = await Process.run("cat", ["/etc/timezone"]);
        return (id.stdout as String).trim();
      }
      else if (Platform.isWindows) {
        // todo: Test
        // This returns a CLDR windows timezone see: https://unicode.org/repos/cldr/trunk/common/supplemental/windowsZones.xml
        // We can then convert this to a TZDB timezone.
        // e.g. tzutl /g --> 'Eastern Standard Time'
        var id = await Process.run("tzutil", ['/g']);
        return windowsZoneToCldrZone((id.stdout as String).trim());
      }
      else if (Platform.isAndroid) {
        //
      }
      else if (Platform.isIOS) {
        //
      }
      else if (Platform.isMacOS) {
        //
      }
    } catch (e) {
      // todo: custom error type
      throw new StateError('LocalTimeZone not found; OS is ${Platform.operatingSystem}; Error was $e');
    }

    throw new StateError('LocalTimeZone not found; OS is ${Platform.operatingSystem}; OS was unsupported.');
  }

  static Map<String, String> _windowsZones;
  static Future windowsZoneToCldrZone(String id) async {
    if (_windowsZones == null) {
      var file = new File('${Directory.current.path}/lib/data/zones.json');
      _windowsZones = JSON.decode(await file.readAsString());
    }

    return _windowsZones[id];
  }
}
