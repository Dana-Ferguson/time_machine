// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' as io;

import 'dart:typed_data';
import 'package:time_machine/src/time_machine_internal.dart';

import 'platform_io.dart';
import 'dart:isolate' show Isolate;

class _VirtualMachineIO implements PlatformIO {
  @override
  Future<ByteData> getBinary(String path, String? filename) async {
    if (filename == null) return ByteData(0);

    var resource = Uri.parse('package:time_machine/data/$path/$filename');
    final Uri resolved = (await Isolate.resolvePackageUri(resource))!;
    var binary = ByteData.view(Int8List.fromList(await io.File.fromUri(resolved).readAsBytes()).buffer);
    return binary;
  }

  @override
  // may return Map<String, dynamic> or List
  Future getJson(String path, String filename) async {
    var resource = Uri.parse('package:time_machine/data/$path/$filename');
    final Uri resolved = (await Isolate.resolvePackageUri(resource))!;
    return json.decode(await io.File.fromUri(resolved).readAsString());
  }
}

class _FlutterMachineIO implements PlatformIO {
  final dynamic _rootBundle;

  _FlutterMachineIO(this._rootBundle);

  @override
  Future<ByteData> getBinary(String path, String? filename) async {
    if (filename == null) return ByteData(0);

    ByteData byteData = await _rootBundle.load('packages/time_machine/data/$path/$filename');
    return byteData;
  }

  @override
  // may return Map<String, dynamic> or List
  Future getJson(String path, String filename) async {
    String text = await _rootBundle.loadString('packages/time_machine/data/$path/$filename');
    return json.decode(text);
  }
}

Future initialize(Map args) {
  String? timeZoneOverride = args['timeZone'];
  String? cultureOverride = args['culture'];

  if (io.Platform.isIOS || io.Platform.isAndroid || io.Platform.isFuchsia) {
    if (args['rootBundle'] == null) throw Exception("Pass in the rootBundle from 'package:flutter/services.dart';");
    // Map IO functions
    PlatformIO.local = _FlutterMachineIO(args['rootBundle']);
  }
  else {
    // Map IO functions
    PlatformIO.local = _VirtualMachineIO();
  }

  return TimeMachine.initialize(timeZoneOverride, cultureOverride);
}

class TimeMachine  {
  static bool _longIdNames = false;

  // I'm looking to basically use @internal for protection??? <-- what did I mean by this?
  static Future initialize(String? timeZoneOverride, String? cultureOverride) async {
    Platform.startVM();

    ITzdbDateTimeZoneSource.loadAllTimeZoneInformation_SetFlag();
    // todo: we want this for flutter -- do we want this for the VM too?
    ICultures.loadAllCulturesInformation_SetFlag();

    // Default provider
    var tzdb = await DateTimeZoneProviders.tzdb;
    IDateTimeZoneProviders.defaultProvider = tzdb;

    // Default TimeZone
    //var localTimezoneId = await _getTimeZoneId();
    //var local = await tzdb[localTimezoneId];

    var local = timeZoneOverride != null ? await tzdb.getZoneOrNull(timeZoneOverride) : await _figureOutTimeZone(tzdb);
    // todo: cache local more directly? (this is indirect caching)
    TzdbIndex.localId = local!.id;

    // Default Culture
    var cultureId = cultureOverride ?? io.Platform.localeName.split('.').first.replaceAll('_', '-');
    Culture? culture = await Cultures.getCulture(cultureId);
    ICultures.currentCulture = culture!;
    // todo: remove Culture.currentCulture
  }

  // todo: the issue here is, Dart fails to compute the correct ZoneIntervalID where the offset isn't a whole hour -- CORRECT FOR THIS
  /// [DateTimeZone] provides the zone interval id for a given instant. We can correlate the (zone interval id, instant) pairs
  /// with known timezones and narrow down which timezone the local computer is in.
  ///
  /// note: during testing, bugs were found with dart's zone interval id -- it sometimes does daylight savings when it didn't exist
  static Future<DateTimeZone?> _figureOutTimeZone(DateTimeZoneProvider provider, [bool strict = false]) async {
    var zones = <DateTimeZone>[];
    // load all the timezones; todo: fast_cache method
    for (var id in provider.ids) {
      zones.add(await provider[id]);
    }

    var nowDateTime = DateTime.now();
    Instant nowInstant = Instant.dateTime(nowDateTime);
    var interval = Interval(Instant.utc(1900, 1, 1, 0, 0), nowInstant);
    var allZoneIntervals = <ZoneInterval>[];
    var allSpecialInstants = <Instant>[];

    if (nowDateTime.timeZoneName.length > _maxZoneShortIdLength) {
      _longIdNames = true;
    }

    var lessZones = <DateTimeZone>[];
    for (var zone in zones) {
      // first pass; todo: identify special instants with a high amount of diversity among timezones so we can get a better first pass
      if (_isTheSame(nowDateTime, zone.getZoneInterval(nowInstant))) {
        // todo: test me? ********************************************************************************************************************
        // also: find and link the relevant issue to this!
        allZoneIntervals.addAll(zone.getZoneIntervals(interval).where((z) => z.wallOffset.inSeconds.abs() % TimeConstants.secondsPerHour == 0));
        lessZones.add(zone);
      }
    }

    allSpecialInstants = allZoneIntervals.map((z) => IZoneInterval.rawStart(z)).toList();
    var badZones = HashSet<String>();

    zones = lessZones;
    // print(zones.join("\n"));
    // print('allSpecialInstants: ${allSpecialInstants.length}; ${allZoneIntervals.length}; ${zones.length};');

    // int i = 0;
    // todo: we need a table to convert between abbreviations and long form zone interval id's
    // see: https://en.wikipedia.org/wiki/List_of_time_zone_abbreviations
    for (var instant in allSpecialInstants) {
      if (instant.isValid) {
        var dateTime = instant.toDateTimeLocal();

        for (var zone in zones) {
          var zoneInterval = zone.getZoneInterval(instant);
          if ((_longIdNames ? _zoneIdMap[dateTime.timeZoneName] : dateTime.timeZoneName) != zoneInterval.name
              || dateTime.timeZoneOffset.inSeconds != zoneInterval.wallOffset.inSeconds) {
            // print('${instant}: ${dateTime}: ${zone.id}: dart: ${dateTime.timeZoneName}@${dateTime.timeZoneOffset.inSeconds} vs tzdb: ${zoneInterval.name}@${zoneInterval.wallOffset.seconds};');
            badZones.add(zone.id);
          }
        }

        // i++;
        if (badZones.isNotEmpty) {
          var lastZone = zones.last;

          // print('$i :: $badZones');
          zones.removeWhere((z) => badZones.contains(z.id));
          badZones.clear();

          // There are mistakes in Dart
          // e.g. see: Pacific/Auckland which Dart (on Linux VM) gives `NZDT@46800` in 1868 and `NZDT` didn't start till `1974-11-03`.... so... dat's not good.
          // But the first pass returns, Antartica/McMurdo & Pacific/Auckland, and they are the same timezone and both technically correct.
          if (zones.isEmpty) return lastZone;
        }

        if (!strict && zones.length <= 1) {
          if (zones.length == 1) {
            return zones.first;
          }
          return null;
        }
      }
    }

    // todo: this is a good thing to log
    // Return UTC if we couldn't even figure it out
    if (zones.isEmpty) return DateTimeZone.utc;

    // Ambiguous -- just picking the first result
    return zones.first;
  }

  static bool _isTheSame(DateTime dateTime, ZoneInterval zoneInterval) {
    return (_longIdNames ? _zoneIdMap[dateTime.timeZoneName] : dateTime.timeZoneName) == zoneInterval.name
        && dateTime.timeZoneOffset.inSeconds == zoneInterval.wallOffset.inSeconds;
  }

  // This is slower (on at least one computer) than guessing the timezone
  // Plus, since this type of solution will have a high number of corner cases
  // for the time, the above method is preferred.
  // ignore: unused_element
  static Future<String> _getTimeZoneId() async {
    try {
      if (io.Platform.isFuchsia) {
        //
      }
      else if (io.Platform.isLinux) {
        // e.g. cat /etc/timezone /g --> 'America/New_York\n'
        var id = await io.Process.run('cat', ["/etc/timezone"]);
        return (id.stdout as String).trim();
      }
      else if (io.Platform.isWindows) {
        // todo: Test
        // This returns a CLDR windows timezone see: https://unicode.org/repos/cldr/trunk/common/supplemental/windowsZones.xml
        // We can then convert this to a TZDB timezone.
        // e.g. tzutl /g --> 'Eastern Standard Time'
        var id = await io.Process.run('tzutil', ['/g']);
        return windowsZoneToCldrZone((id.stdout as String).trim());
      }
      else if (io.Platform.isAndroid) {
        //
      }
      else if (io.Platform.isIOS) {
        //
      }
      else if (io.Platform.isMacOS) {
        //
      }
    } catch (e) {
      // todo: custom error type
      throw StateError('LocalTimeZone not found; OS is ${io.Platform.operatingSystem}; Error was $e');
    }

    throw StateError('LocalTimeZone not found; OS is ${io.Platform.operatingSystem}; OS was unsupported.');
  }

  static Map<String, String>? _windowsZones;
  static Future<String> windowsZoneToCldrZone(String id) async {
    if (_windowsZones == null) {
      var file = io.File('${io.Directory.current.path}/lib/data/zones.json');
      _windowsZones = json.decode(await file.readAsString());
    }

    return _windowsZones![id]!;
  }

  // ignore: unused_field
  static const int _minZoneLongIdLength = 9;
  static const int _maxZoneShortIdLength = 5;
  static const Map<String, String> _zoneIdMap = {
    'Australian Central Daylight Savings Time': "ACDT",
    'Australian Central Standard Time': "ACST",
    'Acre Time': "ACT",
    'ASEAN Common Time': "ACT",
    //  (unofficial)
    'Australian Central Western Standard Time': "ACWST",
    'Atlantic Daylight Time': "ADT",
    'Australian Eastern Daylight Savings Time': "AEDT",
    'Australian Eastern Standard Time': "AEST",
    'Afghanistan Time': "AFT",
    'Alaska Daylight Time': "AKDT",
    'Alaska Standard Time': "AKST",
    //  (Brazil)
    'Amazon Summer Time': "AMST",
    // (Brazil)
    'Amazon Time': "AMT",
    'Armenia Time': "AMT",
    'Argentina Time': "ART",
    'Arabia Standard Time': "AST",
    'Atlantic Standard Time': "AST",
    'Australian Western Standard Time': "AWST",
    'Azores Summer Time': "AZOST",
    'Azores Standard Time': "AZOT",
    'Azerbaijan Time': "AZT",
    'Brunei Time': "BDT",
    'British Indian Ocean Time': "BIOT",
    'Baker Island Time': "BIT",
    'Bolivia Time': "BOT",
    'Brasília Summer Time': "BRST",
    'Brasilia Time': "BRT",
    'Bangladesh Standard Time': "BST",
    'Bougainville Standard Time': "BST",
    // (British Standard Time from Feb 1968 to Oct 1971)
    'British Summer Time': "BST",
    'Bhutan Time': "BTT",
    'Central Africa Time': "CAT",
    'Cocos Islands Time': "CCT",
    // (North America)
    'Central Daylight Time': "CDT",
    'Cuba Daylight Time': "CDT",
    // (Cf. HAEC)
    'Central European Summer Time': "CEST",
    'Central European Time': "CET",
    'Chatham Daylight Time': "CHADT",
    'Chatham Standard Time': "CHAST",
    'Choibalsan Standard Time': "CHOT",
    'Choibalsan Summer Time': "CHOST",
    'Chamorro Standard Time': "CHST",
    'Chuuk Time': "CHUT",
    'Clipperton Island Standard Time': "CIST",
    'Central Indonesia Time': "CIT",
    'Cook Island Time': "CKT",
    'Chile Summer Time': "CLST",
    'Chile Standard Time': "CLT",
    'Colombia Summer Time': "COST",
    'Colombia Time': "COT",
    // (North America)
    'Central Standard Time': "CST",
    'China Standard Time': "CST",
    'Cuba Standard Time': "CST",
    'China Time': "CT",
    'Cape Verde Time': "CVT",
    // (Australia) unofficial
    'Central Western Standard Time': "CWST",
    'Christmas Island Time': "CXT",
    'Davis Time': "DAVT",
    "Dumont d'Urville Time": "DDUT",
    // AIX-specific equivalent of
    //'Central European Time': "DFT",
    'Easter Island Summer Time': "EASST",
    'Easter Island Standard Time': "EAST",
    'East Africa Time': "EAT",
    // (does not recognise DST)
    'Eastern Caribbean Time': "ECT",
    'Ecuador Time': "ECT",
    // (North America)
    'Eastern Daylight Time': "EDT",
    'Eastern European Summer Time': "EEST",
    'Eastern European Time': "EET",
    'Eastern Greenland Summer Time': "EGST",
    'Eastern Greenland Time': "EGT",
    'Eastern Indonesian Time': "EIT",
    // (North America)
    'Eastern Standard Time': "EST",
    'Further-eastern European Time': "FET",
    'Fiji Time': "FJT",
    'Falkland Islands Summer Time': "FKST",
    'Falkland Islands Time': "FKT",
    'Fernando de Noronha Time': "FNT",
    'Galápagos Time': "GALT",
    'Gambier Islands Time': "GAMT",
    'Georgia Standard Time': "GET",
    'French Guiana Time': "GFT",
    'Gilbert Island Time': "GILT",
    'Gambier Island Time': "GIT",
    'Greenwich Mean Time': "GMT",
    'South Georgia and the South Sandwich Islands Time': "GST",
    'Gulf Standard Time': "GST",
    'Guyana Time': "GYT",
    'Hawaii–Aleutian Daylight Time': "HDT",
    // French-language name for CEST
    "Heure Avancée d'Europe Centrale": "HAEC",
    'Hawaii–Aleutian Standard Time': "HST",
    'Hong Kong Time': "HKT",
    'Heard and McDonald Islands Time': "HMT",
    'Khovd Summer Time': "HOVST",
    'Khovd Standard Time': "HOVT",
    'Indochina Time': "ICT",
    'International Day Line West time zone': "IDLW",
    'Israel Daylight Time': "IDT",
    'Indian Ocean Time': "IOT",
    'Iran Daylight Time': "IRDT",
    'Irkutsk Time': "IRKT",
    'Iran Standard Time': "IRST",
    'Indian Standard Time': "IST",
    'Irish Standard Time': "IST",
    'Israel Standard Time': "IST",
    'Japan Standard Time': "JST",
    'Kaliningrad Time': "KALT",
    'Kyrgyzstan Time': "KGT",
    'Kosrae Time': "KOST",
    'Krasnoyarsk Time': "KRAT",
    'Korea Standard Time': "KST",
    'Lord Howe Standard Time': "LHST",
    'Lord Howe Summer Time': "LHST",
    'Line Islands Time': "LINT",
    'Magadan Time': "MAGT",
    // 'Marquesas Islands Time': "MART",
    'Mawson Station Time': "MAWT",
    //  (North America)
    'Mountain Daylight Time': "MDT",
    //  Same zone as CET
    'Middle European Time': "MET",
    // Same zone as CEST
    'Middle European Summer Time': "MEST",
    'Marshall Islands Time': "MHT",
    'Macquarie Island Station Time': "MIST",
    'Marquesas Islands Time': "MIT",
    'Myanmar Standard Time': "MMT",
    'Moscow Time': "MSK",
    'Malaysia Standard Time': "MST",
    // (North America)
    'Mountain Standard Time': "MST",
    'Mauritius Time': "MUT",
    'Maldives Time': "MVT",
    'Malaysia Time': "MYT",
    'New Caledonia Time': "NCT",
    'Newfoundland Daylight Time': "NDT",
    'Norfolk Island Time': "NFT",
    'Nepal Time': "NPT",
    'Newfoundland Standard Time': "NST",
    'Newfoundland Time': "NT",
    'Niue Time': "NUT",
    'New Zealand Daylight Time': "NZDT",
    'New Zealand Standard Time': "NZST",
    'Omsk Time': "OMST",
    'Oral Time': "ORAT",
    // (North America)
    'Pacific Daylight Time': "PDT",
    'Peru Time': "PET",
    'Kamchatka Time': "PETT",
    'Papua New Guinea Time': "PGT",
    'Phoenix Island Time': "PHOT",
    'Philippine Time': "PHT",
    'Pakistan Standard Time': "PKT",
    'Saint Pierre and Miquelon Daylight Time': "PMDT",
    'Saint Pierre and Miquelon Standard Time': "PMST",
    'Pohnpei Standard Time': "PONT",
    // (North America)
    'Pacific Standard Time': "PST",
    'Philippine Standard Time': "PST",
    'Paraguay Summer Time': "PYST",
    'Paraguay Time]': "PYT",
    'Réunion Time': "RET",
    'Rothera Research Station Time': "ROTT",
    'Sakhalin Island Time': "SAKT",
    'Samara Time': "SAMT",
    'South African Standard Time': "SAST",
    'Solomon Islands Time': "SBT",
    'Seychelles Time': "SCT",
    'Samoa Daylight Time': "SDT",
    'Singapore Time': "SGT",
    'Sri Lanka Standard Time': "SLST",
    'Srednekolymsk Time': "SRET",
    'Suriname Time': "SRT",
    'Samoa Standard Time': "SST",
    'Singapore Standard Time': "SST",
    'Showa Station Time': "SYOT",
    'Tahiti Time': "TAHT",
    'Thailand Standard Time': "THA",
    'Indian/Kerguelen': "TFT",
    'Tajikistan Time': "TJT",
    'Tokelau Time': "TKT",
    'Timor Leste Time': "TLT",
    'Turkmenistan Time': "TMT",
    'Turkey Time': "TRT",
    'Tonga Time': "TOT",
    'Tuvalu Time': "TVT",
    'Ulaanbaatar Summer Time': "ULAST",
    'Ulaanbaatar Standard Time': "ULAT",
    'Coordinated Universal Time': "UTC",
    'Uruguay Summer Time': "UYST",
    'Uruguay Standard Time': "UYT",
    'Uzbekistan Time': "UZT",
    'Venezuelan Standard Time': "VET",
    'Vladivostok Time': "VLAT",
    'Volgograd Time': "VOLT",
    'Vostok Station Time': "VOST",
    'Vanuatu Time': "VUT",
    'Wake Island Time': "WAKT",
    'West Africa Summer Time': "WAST",
    'West Africa Time': "WAT",
    'Western European Summer Time': "WEST",
    'Western European Time': "WET",
    'Western Indonesian Time': "WIT",
    'Western Standard Time': "WST",
    'Yakutsk Time': "YAKT",
    'Yekaterinburg Time': "YEKT"
  };
}
