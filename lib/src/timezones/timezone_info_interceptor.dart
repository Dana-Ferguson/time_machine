// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

/*
import 'dart:math' as math;

import 'package:meta/meta.dart';
// import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/src/time_machine_internal.dart';
*/
// todo: This seems fairly BCL centric -- so it probably doesn't apply to us here
/*
/// Interception for TimeZoneInfo static methods. These are still represented as
/// static methods in this class, but they're implemented via a replacable shim, which
/// by default delegates to the static methods in TimeZoneInfo.
@internal abstract class TimeZoneInfoInterceptor
{
  /// The shim to use for all the static methods. We don't care about thread safety here,
  /// beyond 'it must be correct when used in production' - it's only ever changed in tests,
  /// which are single-threaded anyway.
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

/// Implementation that just delegates in a simple manner.
@private class BclShim implements ITimeZoneInfoShim
{
  TimeZoneInfo get Local => null; // TimeZoneInfo.Local;

  TimeZoneInfo FindSystemTimeZoneById(String id) => TimeZoneInfo.FindSystemTimeZoneById(id);

  // ReadOnlyCollection
  List<TimeZoneInfo> GetSystemTimeZones() => TimeZoneInfo.GetSystemTimeZones();
}
*/
