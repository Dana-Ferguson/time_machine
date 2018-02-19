// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/SingleZoneIntervalMap.cs
// a209e60  on Mar 18, 2015

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

/// <summary>
/// Implementation of IZoneIntervalMap which just returns a single interval (provided on construction) regardless of
/// the instant requested.
/// </summary>
@internal /*sealed*/ class SingleZoneIntervalMap implements IZoneIntervalMap {
  final ZoneInterval _interval;

  @internal SingleZoneIntervalMap(this._interval);

  ZoneInterval GetZoneInterval(Instant instant) => _interval;
}
