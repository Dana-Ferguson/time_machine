// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:html';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:js';

import 'package:logging/logging.dart';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_timezones.dart';

import 'io.dart';

class _VirtualMachineIO implements PlatformIO {
  @override
  Future<ByteData> getBinary(String path, String filename) async {
    if (filename == null) return new ByteData(0);

    HttpRequest file = await HttpRequest.request('../lib/data/$path/$filename', responseType: 'blob', mimeType: 'application/octet-stream');

    // todo: probably a better way to do this
    var binary = new ByteData.view(new Int8List.fromList(file.response.bodyBytes).buffer);
    return binary;
  }

  @override
  Future getJson(String path, String filename) async {
    var file = await HttpRequest.getString('../lib/data/$path/$filename');
    return JSON.decode(file);
  }
}

class TimeMachine {
  // todo: is it okay to have a Logger in a library... can this be 'tree-shaken out' for users who aren't logging?
  static final Logger _log = new Logger('TimeMachine');
  
  // I'm looking to basically use @internal for protection??? <-- what did I mean by this?
  static Future initialize() async {
    // Default provider
    var tzdb = await DateTimeZoneProviders.tzdb;
    DateTimeZoneProviders.defaultProvider = tzdb;
    
    _readIntlObject();

    // Default TimeZone
    var local = await tzdb[_timeZoneId];
    // todo: cache local more directly? (this is indirect caching)
    TzdbIndex.localId = local.id;

    // Default Culture
    var cultureId = _locale;
    var culture = await Cultures.getCulture(cultureId);
    Cultures.currentCulture = culture;
    // todo: remove CultureInfo.currentCulture
    
    // todo: set default calendar from [_calendar]
  }

  static String _timeZoneId;
  static String _locale;
  static String _numberingSystem;
  static String _calendar;
  static String _yearFormat;
  static String _monthFormat;
  static String _dayFormat;

  // {locale: en-US, numberingSystem: latn, calendar: gregory, timeZone: America/New_York, year: numeric, month: numeric, day: numeric}
  static _readIntlObject() {
    try {
      JsObject options = context['Intl']
          .callMethod('DateTimeFormat')
          .callMethod('resolvedOptions');

      _locale = options['locale'];
      _timeZoneId = options['timeZone'];
      _numberingSystem = options['numberingSystem'];
      _calendar = options['calendar'];
      _yearFormat = options['year'];
      _monthFormat = options['month'];
      _dayFormat = options['day'];
    }
    catch (e, s) {
      _log.warning('Failed to get platform local information.\n$e\n$s');
    }
  }
}