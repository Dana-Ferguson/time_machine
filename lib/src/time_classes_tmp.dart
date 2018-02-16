import 'package:meta/meta.dart';

import 'package:time_machine/time_machine.dart';

/*
  ** var filename = zone.ZoneId.ToLowerInvariant().Replace('/', '_') + '.bin';

  PrecalculatedDateTimeZone
    Periods: ZoneInterval[]
    TailZone: StandardDaylightAlternatingMap
        standardOffset: Offset
        standardRecurrence: ZoneRecurrence
        dstRecurrence: ZoneRecurrence

  ZoneRecurrence
    ZoneYearOffset
*/

// ALSO SHIT: https://nodatime.org/2.2.x/userguide/calendars
// ****** We need to worry about the leap years ********
// --> are these accounted for in the TZDB (I doubt it)

/*
  Largest number in VM: no end (it transitions between 32bit, 64bit, and bigint)
  Largest number in JS: 2^53
  milliseconds => 285420 years
  microseconds => 285.4 years (1685 to 2255)

  https://caniuse.com/#feat=high-resolution-time (YES)
  Accurate to 5 microseconds; (if not available, millisecond accuracy should be)
 */

enum TransitionMode {
  /// Calculate transitions against UTC. value: 0
  utc,
  /// Calculate transitions against wall offset. value: 1
  wall,
  /// Calculate transitions against standard offset. value: 2
  standard
}

/// An offset from UTC in seconds. A positive value means that the local time is
/// ahead of UTC (e.g. for Europe); a negative value means that the local time is behind
/// UTC (e.g. for America).
class Offset {
  final int seconds;
  Offset(this.seconds);
}

class StandardDaylightAlternatingMap {
  Offset standardOffset;
  ZoneRecurrence standardRecurrence;
  ZoneRecurrence dstRecurrence;
}

class ZoneRecurrence {
  String name;
  Offset savings;
  ZoneYearOffset yearOffset;
  int fromYear;
  int toYear;
  bool isInfinite;
}

class ZoneYearOffset {
  int dayOfMonth;
  int dayOfWeek;
  int monthOfYear;
  bool addDay;

  /// Gets the method by which offsets are added to Instants to get LocalInstants.
  TransitionMode mode;

  /// Gets a value indicating whether [advance day of week].
  bool advanceDayOfWeek;

  /// Gets the time of day when the rule takes effect.
  LocalTime timeOfDay;
}

// todo: Should I use [DateTime] here?
/// LocalTime is represents a time of day, with no reference
/// to a particular calendar, time zone or date.
//class LocalTime {
//  // this is long nanoseconds in nodatime
//  final int milliseconds;
//
//  LocalTime(this.milliseconds);
//}

class PrecalculatedDateTimeZone {
  List<ZoneInterval> periods;
  StandardDaylightAlternatingMap tailZone;
}

class ZoneInterval {
  String name;
  Instant start;
  Instant end;
  Offset wallOffset;
  Offset savings;
}

