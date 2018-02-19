// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/TimeZoneInfoInterceptor.cs
// 407f018  on Aug 31, 2017

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

// todo: This seems fairly BCL centric -- so it probably doesn't apply to us here

/// <summary>
/// Interception for TimeZoneInfo static methods. These are still represented as
/// static methods in this class, but they're implemented via a replacable shim, which
/// by default delegates to the static methods in TimeZoneInfo.
/// </summary>
@internal abstract class TimeZoneInfoInterceptor
{
  /// <summary>
  /// The shim to use for all the static methods. We don't care about thread safety here,
  /// beyond "it must be correct when used in production" - it's only ever changed in tests,
  /// which are single-threaded anyway.
  /// </summary>
  @internal static ITimeZoneInfoShim Shim = new BclShim();

  @internal static TimeZoneInfo get Local => Shim.Local;
  @internal static TimeZoneInfo FindSystemTimeZoneById(String id) => Shim.FindSystemTimeZoneById(id);
  // ReadOnlyCollection
  @internal static List<TimeZoneInfo> GetSystemTimeZones() => Shim.GetSystemTimeZones();
}

@internal abstract class ITimeZoneInfoShim
{
  TimeZoneInfo get Local;
  TimeZoneInfo FindSystemTimeZoneById(String id);
  // ReadOnlyCollection
  List<TimeZoneInfo> GetSystemTimeZones();
}

/// <summary>
/// Implementation that just delegates in a simple manner.
/// </summary>
@private class BclShim implements ITimeZoneInfoShim
{
  TimeZoneInfo get Local => TimeZoneInfo.Local;

  TimeZoneInfo FindSystemTimeZoneById(String id) => TimeZoneInfo.FindSystemTimeZoneById(id);

  // ReadOnlyCollection
  List<TimeZoneInfo> GetSystemTimeZones() => TimeZoneInfo.GetSystemTimeZones();
}
