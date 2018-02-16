import 'package:intl/intl.dart';

//import 'dart:html';
import 'dart:js';

import 'package:time_machine/time_machine.dart';

// todo: rename this file ... it's not wrapping Intl -- it's providing \ organizing system locality functions

bool _systemLocalInit = false;
bool _systemLocalTimeZoneInit = false;

Function initializeSystemLocale;
Function initializeSystemTimezone;

String get systemLocale {
  if (!_systemLocalInit) {
    if (initializeSystemLocale == null) {
      throw new StateError('Platform not set. Unable to determine system locale.');
    }
    _systemLocalInit = true;
  }

  // Intl.DateTimeFormat().resolvedOptions().timeZone;


  // DateFormat.allLocalesWithSymbols().tim
  // need to translate this from short form to long form?
  return Intl.systemLocale;
}

// todo: do I make this a hidden function and provide it only through the DateTimeZone function?
DateTimeZone get systemTimeZone {
  //
}