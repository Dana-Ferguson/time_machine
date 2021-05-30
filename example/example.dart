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
    var paris = await tzdb['Europe/Paris'];

    var now = Instant.now();

    print('Basic');
    print('UTC Time: $now');
    print('Local Time: ${now.inLocalZone()}');
    print('Paris Time: ${now.inZone(paris)}\n');

    print('Formatted');
    print('UTC Time: ${now.toString('dddd yyyy-MM-dd HH:mm')}');
    print('Local Time: ${now.inLocalZone().toString('dddd yyyy-MM-dd HH:mm')}\n');

    var french = (await Cultures.getCulture('fr-FR'))!;
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
  }
  catch (error, stack) {
    print(error);
    print(stack);
  }
}
