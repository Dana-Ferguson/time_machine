import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

//import 'dart:html';
import 'dart:js';

import 'package:time_machine/time_machine.dart';

// {locale: en-US, numberingSystem: latn, calendar: gregory, timeZone: America/New_York, year: numeric, month: numeric, day: numeric}
class TimeMachine {
  final Logger _log = new Logger('TimeMachine');

  DateTimeZone _timeZone;
  String _locale;
  String _numberingSystem;
  // todo: Set actual calendar!
  String _calendar;
  String _yearFormat;
  String _monthFormat;
  String _dayFormat;

  // todo: Set DateFormat class ??? -- I could also use the Intl regular magic it provides!?

  TimeMachine _init() {
    try {
      JsObject options = context['Intl']
          .callMethod('DateTimeFormat')
          .callMethod('resolvedOptions');

      _locale = options['locale'];
      _timeZone = null; // todo: lookup! (based on string)
      _numberingSystem = options['numberingSystem'];
      _calendar = options['calendar'];
      _yearFormat = options['year'];
      _monthFormat = options['month'];
      _dayFormat = options['day'];
    }
    catch (e, s) {
      _log.warning('Failed to get platform local information.\n$e\n$s');
    }

    return this;
  }

  DateTimeZone get timeZone => _timeZone ?? _init().timeZone;
  String get locale => _locale ?? _init()._locale;
}