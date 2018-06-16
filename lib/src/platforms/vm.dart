// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
    // todo: for VM, always load everything
    // Default provider
    var tzdb = await DateTimeZoneProviders.tzdb;
    DateTimeZoneProviders.defaultProvider = tzdb;

    // Default TimeZone
    var localTimezoneId = await _getTimeZoneId();
    var local = await tzdb[localTimezoneId];
    // We don't actually cache local at all right here
    TzdbIndex.localId = localTimezoneId;

    // Default Culture
    var cultureId = Platform.localeName.split('.').first.replaceAll('_', '-');
    var culture = await Cultures.getCulture(cultureId);
    Cultures.currentCulture = culture;
    // todo: remove CultureInfo.currentCulture
  }

  /*
    static final bool isFuchsia = (_operatingSystem == "fuchsia");
    static final bool isLinux = (_operatingSystem == "linux");
    static final bool isWindows = (_operatingSystem == "windows");
    static final bool isAndroid = (_operatingSystem == "android");
    static final bool isIOS = (_operatingSystem == "ios");
    static final bool isMacOS = (_operatingSystem == "macos");
  */
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
