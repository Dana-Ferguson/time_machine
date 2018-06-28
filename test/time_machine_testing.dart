// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

//import 'dart:async';
//
//import 'package:time_machine/time_machine_internal.dart';
//import 'package:test/test.dart';
//import 'package:matcher/matcher.dart';
//import 'package:time_machine/time_machine_timezones.dart';

import 'package:time_machine/time_machine.dart' as publicMachine;
import 'testing/test_helper.dart' as helper;

// export 'testing/test_fx.dart';
export 'testing/time_matchers.dart';
export 'testing/test_helper.dart';

export 'testing/fake_clock.dart';
export 'testing/timezones/single_transition_datetimezone.dart';
export 'testing/timezones/multi_transition_datetimezone.dart';
export 'testing/timezones/fake_datetimezone_source.dart';

export 'testing/test_fx_attributes.dart';

import 'dart:async';
import 'package:time_machine/src/time_machine_internal.dart';

import 'testing/test_fx_interface.dart'
  if (dart.library.io) 'testing/test_fx.dart'
as helpingMachine;

Future<dynamic> runTests() => helpingMachine.runTests();

abstract class TimeMachine {
  TimeMachine() { throw new StateError('TimeMachine can not be instantiated.'); }
  static Future initialize([dynamic arg]) async {
    helper.setFunctions();
    await publicMachine.TimeMachine.initialize(arg);
  }
}

// From Testing Objects
abstract class TestObjects {
  /// Creates a positive offset from the given values.
  ///
  /// [hours]: The number of hours, in the range [0, 24).
  /// [minutes]: The number of minutes, in the range [0, 60).
  /// [seconds]: The number of seconds, in the range [0, 60).
  /// Returns: A new [Offset] representing the given values.
  /// [ArgumentOutOfRangeException]: The result of the operation is outside the range of Offset.
  static Offset CreatePositiveOffset(int hours, int minutes, int seconds) {
    Preconditions.checkArgumentRange('hours', hours, 0, 23);
    Preconditions.checkArgumentRange('minutes', minutes, 0, 59);
    Preconditions.checkArgumentRange('seconds', seconds, 0, 59);
    seconds += minutes * TimeConstants.secondsPerMinute;
    seconds += hours * TimeConstants.secondsPerHour;
    return new Offset.fromSeconds(seconds);
  }

  /// Creates a negative offset from the given values.
  ///
  /// [hours]: The number of hours, in the range [0, 24).
  /// [minutes]: The number of minutes, in the range [0, 60).
  /// [seconds]: The number of seconds, in the range [0, 60).
  /// Returns: A new [Offset] representing the given values.
  /// [ArgumentOutOfRangeException]: The result of the operation is outside the range of Offset.
  static Offset CreateNegativeOffset(int hours, int minutes, int seconds) {
    return new Offset.fromSeconds(-CreatePositiveOffset(hours, minutes, seconds).seconds);
  }
}
