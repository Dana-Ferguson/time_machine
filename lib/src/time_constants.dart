// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';

/// Useful constants, mostly along the lines of 'number of milliseconds in an hour'.
// https://www.dartlang.org/guides/language/effective-dart/design#avoid-defining-a-class-that-contains-only-static-members
// I invoke example 3.

/// Useful constants, mostly along the lines of 'number of milliseconds in an hour'.
class TimeConstants {
  static const int secondsPerMinute = 60;
  static const int secondsPerHour = secondsPerMinute * minutesPerHour;
  static const int secondsPerDay = secondsPerHour * hoursPerDay;
  static const int secondsPerWeek = secondsPerDay * daysPerWeek;

  static const int minutesPerHour = 60;
  static const int minutesPerDay = minutesPerHour * hoursPerDay;
  static const int minutesPerWeek = minutesPerDay * daysPerWeek;

  static const int hoursPerDay = 24;
  static const int hoursPerWeek = hoursPerDay * daysPerWeek;

  static const int daysPerWeek = 7;

  static const int microsecondsPerMillisecond = 1000;
  static const int microsecondsPerSecond = microsecondsPerMillisecond * millisecondsPerSecond;
  static const int microsecondsPerMinute = microsecondsPerSecond * secondsPerMinute;
  static const int microsecondsPerHour = microsecondsPerMinute * minutesPerHour;
  static const int microsecondsPerDay = microsecondsPerHour * hoursPerDay;
  static const int microsecondsPerWeek = microsecondsPerDay * daysPerWeek;

  static const int millisecondsPerSecond = 1000;
  static const int millisecondsPerMinute = millisecondsPerSecond * secondsPerMinute;
  static const int millisecondsPerHour = millisecondsPerMinute * minutesPerHour;
  static const int millisecondsPerDay = millisecondsPerHour * hoursPerDay;
  static const int millisecondsPerWeek = millisecondsPerDay * daysPerWeek;

  static const int nanosecondsPerMicrosecond = 1000;
  static const int nanosecondsPerSecond = nanosecondsPerMillisecond * millisecondsPerSecond;
  static const int nanosecondsPerMillisecond = nanosecondsPerMicrosecond * microsecondsPerMillisecond;
  static const int nanosecondsPerMinute = nanosecondsPerSecond * secondsPerMinute;
  static const int nanosecondsPerHour = nanosecondsPerMinute * minutesPerHour;
  static const int nanosecondsPerDay = nanosecondsPerHour * hoursPerDay;
  static const int nanosecondsPerWeek = nanosecondsPerDay * daysPerWeek;
  
  static final BigInt nanosecondsPerMillisecondBigInt = BigInt.from(nanosecondsPerMillisecond);

  /// The instant at the Unix epoch of midnight 1st January 1970 UTC.
  static final Instant unixEpoch = Instant();

  /// The instant at the Julian epoch of noon (UTC) January 1st 4713 BCE in the proleptic
  /// Julian calendar, or November 24th 4714 BCE in the proleptic Gregorian calendar.
  static final Instant julianEpoch = Instant.utc(-4713, 11, 24, 12, 0);
}
