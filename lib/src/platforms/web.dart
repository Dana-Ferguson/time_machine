// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:js';

// import 'package:resource/resource.dart';
import 'dart:html';

import 'package:time_machine/src/time_machine_internal.dart';

import 'platform_io.dart';

/// Resource package currently uses Isolate.resolvePackageUri (see: https://github.com/dart-lang/resource/issues/35)
/// A fix is pending, but it is very slow coming (see: https://github.com/dart-lang/resource/pull/36)

@ddcSupportHack
Uri _resolveUri(Uri uri) {
  if (uri.scheme == 'package') {
    uri = Uri.parse('packages/${uri.path}');
  }
  return Uri.base.resolveUri(uri);
}

@ddcSupportHack
Future<List<int>> _httpGetBytes(Uri uri) {
  return HttpRequest.request(uri.toString(), responseType: 'arraybuffer')
      .then((request) {
    ByteBuffer data = request.response;
    return data.asUint8List();
  });
}

@ddcSupportHack
/// Reads the bytes of a URI as a list of bytes.
Future<List<int>> _readAsBytes(Uri uri) async {
  if (uri.scheme == 'http' || uri.scheme == "https") {
    return _httpGetBytes(uri);
  }
  if (uri.scheme == 'data') {
    return uri.data!.contentAsBytes();
  }
  throw UnsupportedError('Unsupported scheme: $uri');
}

@ddcSupportHack
/// Reads the bytes of a URI as a string.
Future<String> _readAsString(Uri uri, Encoding? encoding) async {
  if (uri.scheme == 'http' || uri.scheme == "https") {
    // Fetch as string if the encoding is expected to be understood,
    // otherwise fetch as bytes and do decoding using the encoding.
    if (encoding != null) {
      return encoding.decode(await _httpGetBytes(uri));
    }
    return HttpRequest.getString(uri.toString());
  }
  if (uri.scheme == 'data') {
    return uri.data!.contentAsString(encoding: encoding);
  }
  throw UnsupportedError('Unsupported scheme: $uri');
}

class _WebMachineIO implements PlatformIO {
  @override
  Future<ByteData> getBinary(String path, String filename) async {

    // var resource = new Resource('packages/time_machine/data/$path/$filename');
    // // todo: probably a better way to do this
    // var binary = new ByteData.view(new Int8List.fromList(await resource.readAsBytes()).buffer);

    var resource = Uri.parse('${Uri.base.origin}/packages/time_machine/data/$path/$filename');
    var binary = ByteData.view(Int8List.fromList(await _readAsBytes(resource)).buffer);

    return binary;
  }

  @override
  Future/**<Map<String, dynamic>>*/ getJson(String path, String filename) async {
    // var resource = new Resource('packages/time_machine/data/$path/$filename');
    // return json.decode(await resource.readAsString());

    var resource = Uri.parse('${Uri.base.origin}/packages/time_machine/data/$path/$filename');
    return json.decode(await _readAsString(_resolveUri(resource), null));
  }
}

Future initialize(Map args) => TimeMachine.initialize();

class TimeMachine {
  // I'm looking to basically use @internal for protection??? <-- what did I mean by this?
  static Future initialize() async {
    Platform.startWeb();

    // Map IO functions
    PlatformIO.local = _WebMachineIO();

    // Default provider
    var tzdb = await DateTimeZoneProviders.tzdb;
    IDateTimeZoneProviders.defaultProvider = tzdb;

    _readIntlObject();

    // Default TimeZone
    var local = await tzdb[_timeZoneId];
    // todo: cache local more directly? (this is indirect caching)
    TzdbIndex.localId = local.id;

    // Default Culture
    var cultureId = _locale;
    var culture = await Cultures.getCulture(cultureId);
    ICultures.currentCulture = culture!;
    // todo: remove Culture.currentCulture

    // todo: set default calendar from [_calendar]
  }

  static late String _timeZoneId;
  static late String _locale;
  // ignore: unused_field
  static late String _numberingSystem;
  // ignore: unused_field
  static late String _calendar;
  // ignore: unused_field
  static late String _yearFormat;
  // ignore: unused_field
  static late String _monthFormat;
  // ignore: unused_field
  static late String _dayFormat;

  // {locale: en-US, numberingSystem: latn, calendar: gregory, timeZone: America/New_York, year: numeric, month: numeric, day: numeric}
  static void _readIntlObject() {
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
      print('Failed to get platform local information.\n$e\n$s');
    }
  }
}
