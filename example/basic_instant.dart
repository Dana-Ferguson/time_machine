// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:io';

import 'dart:async';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_timezones.dart';

Future main() async {
  // todo: demonstrate a test clock
  // var clockForTesting = new Clock();
  
  var clock = SystemClock.instance;
  var now = clock.getCurrentInstant();
  print(now);
  
  var locale = Platform.localeName;
  print(locale);
  var x = new DateTime.now();
  // todo: parse out "America/New_York" ??? canonized names?
  print(x.timeZoneName);
  print(x.timeZoneOffset);
  
  // This is where we need the QoL change
  var tzdb = await DateTimeZoneProviders.Tzdb;
  var local = await tzdb["America/New_York"];
  var paris = await tzdb["Europe/Paris"];

  print(now.inZone(local));
  print(now.inZone(paris));
}