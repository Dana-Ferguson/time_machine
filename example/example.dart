// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:meta/meta.dart';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_timezones.dart';

/// Easy in Quotes.. since we can't
Future<String> getTimeZoneEasy() async {
  // Getting CLDR timezone from here is the dream.
  var x = new DateTime.now();
  var wtfZone = x.timeZoneName;
  
  // EDT on Linux, 'Eastern Daylight Time' in browser and in Windows ... but, is there a standard mapping to CLDR?
  
  // Can we use the offset to form a better guess?
  // x.timeZoneOffset

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
  print(x.timeZoneName);
  print(x.timeZoneOffset);
  print(Platform.localeName);


  return null;
}

/*
/// Functions for getting the current timeZone, culture, and functions to load data
abstract class iTimeMachine {
  // Tzdb.GetSystemDefaultTimeZone();
  DateTimeZone get localTimeZone;
  // CultureInfo.currentCulture;
  CultureInfo get localCulture;
  
  Clock get clock;
}

@immutable
abstract class TimeMachine {
  TimeMachine._();
  
  static CultureInfo get localCulture => _instance.localCulture;
  static DateTimeZone get localTimeZone => _instance.localTimeZone;

  static Clock get clock => SystemClock.instance;

  static iTimeMachine _instance;
  static iTimeMachine get instance => _instance;
  static set instance(iTimeMachine machine) {
    _instance ??= machine;
  }
}

// may also have machines for different mobile platforms?
class WebTimeMachine  /*extends TimeMachine*/ {
  //
}

/// A TimeMachine that exists for testing
class FakeTimeMachine  /*extends TimeMachine*/ {
  //
}

class VirtualTimeMachine extends iTimeMachine {
  @override
  // CultureInfo get culture => null;
  final CultureInfo localCulture;

  @override
  // DateTimeZone get timeZone => null;
  final DateTimeZone localTimeZone;

  @override
  Clock get clock => SystemClock.instance;
  
  // IDateTimeZoneProvider timeZones

  VirtualTimeMachine._(this.localTimeZone, this.localCulture) {
    TimeMachine.instance = this;
  }
  
  static Future<iTimeMachine> construct() async {
    // todo: for VM, always load everything
    // Default provider
    var tzdb = await DateTimeZoneProviders.tzdb;
    
    // Default TimeZone
    var localTimezone = await _getTimeZoneId();
    var local = await tzdb[localTimezone];

    // Default Culture
    var cultureId = Platform.localeName.split('.').first.replaceAll('_', '-');
    var culture = await Cultures.getCulture(cultureId);

    return new VirtualTimeMachine._(local, culture);
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
*/

class VirtualTimeMachine2 /*extends iTimeMachine*/ {
  // I'm looking to basically use @internal for protection
  static Future construct() async {
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

/// Do we consolidate everything into a Global Static???
/// Do we have TimeMachine, Cultures, Tzdb???
/// TimeMachine sets up Cultures, TimeZones, and Clock? and then you use them all separately?
/// ^^^ I'm leaning towards this last one.
/// DateTimeZones.
/// Cultures.
/// Clocks.
///
/// Or .. from the Class it's related to
/// Clock.system
/// Culture(Info).current
/// DateTimeZone.local
///
/// Then what about DateTimeZoneProviders.Tzdb???
/// DateTimeZone['id'] --> DateTimeZoneProviders.default --> which then pushes back to DateTimeZoneProviders.Tzdb 
/// and getting Cultures???
///
/// Culture(Info).load(id) --> Future<Culture> :: Culture.get(id) --> Culture (sync route?) 
/// DateTimeZone['id']
Future main() async {
  // todo: demonstrate a test clock
  // var clockForTesting = new FakeClock();

  try {
    await VirtualTimeMachine2.construct();
    print('Hello, ${DateTimeZone.local} from the Dart Time Machine!');

    var tzdb = await DateTimeZoneProviders.tzdb;
    var paris = await tzdb["Europe/Paris"];

    var now = SystemClock.instance.getCurrentInstant();

    print('\nBasic');
    print('UTC Time: $now');
    // todo: supply no timezone and have it default to our local timezone
    print('Local Time: ${now.inLocalZone()}');
    print('Paris Time: ${now.inZone(paris)}');

    print('\nFormatted');
    print('UTC Time: ${now.toString('dddd yyyy-MM-dd HH:mm')}');
    print('Local Time: ${now.inLocalZone().toString('dddd yyyy-MM-dd HH:mm')}');

    print('\nFormatted and French');
    var culture = await Cultures.getCulture('fr-FR');
    print('UTC Time: ${now.toString('dddd yyyy-MM-dd HH:mm', culture)}');
    print('Local Time: ${now.inLocalZone().toString('dddd yyyy-MM-dd HH:mm', culture)}');

    print('\nParse Formatted and Zoned French');
    // without the 'z' parsing will be forced to interpret the timezone as UTC
    var localText = now.inLocalZone().toString('dddd yyyy-MM-dd HH:mm z', culture);

    // todo: show you can create a reusable pattern
    // var localClone = ZonedDateTimePattern.createWithCurrentCulture('dddd yyyy-MM-dd HH:mm z'/*, tzdb*/).parse(localText);
    var localClone = ZonedDateTimePattern.createWithCulture('dddd yyyy-MM-dd HH:mm z', culture).parse(localText);
    print(localClone.value);
  }
  catch (error, stack) {
    print(error);
    print(stack);
  }
}