// Copyright 2018 The Time Machine Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_text_patterns.dart';

Future main() async {
  try {
    // Sets up timezone and culture information
    await TimeMachine.initialize();
    print('Hello, ${DateTimeZone.local} from the Dart Time Machine!\n');

    var tzdb = await DateTimeZoneProviders.tzdb;
    var paris = await tzdb["Europe/Paris"];

    var now = Instant.now();

    print('Basic');
    print('UTC Time: $now');
    print('Local Time: ${now.inLocalZone()}');
    print('Paris Time: ${now.inZone(paris)}\n');

    print('Formatted');
    print('UTC Time: ${now.toString('dddd yyyy-MM-dd HH:mm')}');
    print('Local Time: ${now.inLocalZone().toString('dddd yyyy-MM-dd HH:mm')}\n');

    var french = await Cultures.getCulture('fr-FR');
    print('Formatted and French ($french)');
    print('UTC Time: ${now.toString('dddd yyyy-MM-dd HH:mm', french)}');
    print('Local Time: ${now.inLocalZone().toString('dddd yyyy-MM-dd HH:mm', french)}\n');

    print('Parse French Formatted ZonedDateTime');

    // without the 'z' parsing will be forced to interpret the timezone as UTC
    var localText = now
        .inLocalZone()
        .toString('dddd yyyy-MM-dd HH:mm z', french);

    var localClone = ZonedDateTimePattern
        .createWithCulture('dddd yyyy-MM-dd HH:mm z', french)
        .parse(localText);

    print(localClone.value);

    var t = Time(days: -1, microseconds: -1);
    // print(t.floorDays);
    print(t.totalDays.floor());

    /*
    for (int i = 24 * 3600 * 1000 * -2; i < 24 * 3600 * 1000 * 2; i++) {
      var instant = TimeConstants.unixEpoch.subtract(Time(microseconds: i));
      // toUnixTimeSeconds
      // print('$time -- ${time.epochDay} -- ${time.epochTimeOfDay} -- ${time.localTimeOfEpochDay}');
      var a = instant.epochMicroseconds;
      var b = instant.timeSinceEpoch.totalMicroseconds.floor();
      if (a != b) {
        print('$instant -- $i -- $a -- $b');
      }
    }*/

    print(TimeConstants.nanosecondsPerDay);
    print(TimeConstants.nanosecondsPerDay / TimeConstants.nanosecondsPerMillisecond);
    print(TimeConstants.millisecondsPerDay);
    print(1 / TimeConstants.millisecondsPerDay);
    /*
    for (int i = 36 * -1; i < 36 * 1; i++) {
      var instant = TimeConstants.unixEpoch.add(Time(seconds: i));
      print('$instant -- $i -- t: ${instant.timeSinceEpoch.secondsOfMinute} -- i: ${instant.epochTimeOfDay.secondsOfMinute}');
    }*/

    print(Instant.utc(2011, 08, 18, 20, 53).toDateTimeLocal());
    print(new DateTime.utc(2011, 08, 18, 20, 53, 0).toLocal());
  }
  catch (error, stack) {
    print(error);
    print(stack);
  }
}