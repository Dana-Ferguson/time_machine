//import 'dart:async';
//
//import 'package:time_machine/time_machine.dart';
//import 'package:test/test.dart';
//import 'package:matcher/matcher.dart';
//import 'package:time_machine/time_machine_timezones.dart';

export 'testing/test_fx.dart';
export 'testing/time_matchers.dart';
export 'testing/test_helper.dart';

export 'testing/fake_clock.dart';
export 'testing/timezones/single_transition_datetimezone.dart';
export 'testing/timezones/multi_transition_datetimezone.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';

// From Testing Objects
abstract class TestObjects {
  /// <summary>
  /// Creates a positive offset from the given values.
  /// </summary>
  /// <param name="hours">The number of hours, in the range [0, 24).</param>
  /// <param name="minutes">The number of minutes, in the range [0, 60).</param>
  /// <param name="seconds">The number of seconds, in the range [0, 60).</param>
  /// <returns>A new <see cref="Offset"/> representing the given values.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The result of the operation is outside the range of Offset.</exception>
  static Offset CreatePositiveOffset(int hours, int minutes, int seconds) {
    Preconditions.checkArgumentRange('hours', hours, 0, 23);
    Preconditions.checkArgumentRange('minutes', minutes, 0, 59);
    Preconditions.checkArgumentRange('seconds', seconds, 0, 59);
    seconds += minutes * TimeConstants.secondsPerMinute;
    seconds += hours * TimeConstants.secondsPerHour;
    return new Offset.fromSeconds(seconds);
  }

  /// <summary>
  /// Creates a negative offset from the given values.
  /// </summary>
  /// <param name="hours">The number of hours, in the range [0, 24).</param>
  /// <param name="minutes">The number of minutes, in the range [0, 60).</param>
  /// <param name="seconds">The number of seconds, in the range [0, 60).</param>
  /// <returns>A new <see cref="Offset"/> representing the given values.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The result of the operation is outside the range of Offset.</exception>
  static Offset CreateNegativeOffset(int hours, int minutes, int seconds) {
    return new Offset.fromSeconds(-CreatePositiveOffset(hours, minutes, seconds).seconds);
  }
}