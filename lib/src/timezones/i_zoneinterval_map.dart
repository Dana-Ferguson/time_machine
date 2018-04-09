// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/IZoneIntervalMap.cs
// 7f779ce  on Jul 26, 2015

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

/// <summary>
/// The core part of a DateTimeZone: mapping an Instant to an Interval.
/// Separating this out into an interface allows for flexible caching.
/// </summary>
/// <remarks>
/// Benchmarking shows that a delegate may be slightly faster here, but the difference
/// isn't very significant even for very fast calls (cache hits). The interface ends up
/// feeling slightly cleaner elsewhere in the code.
/// </remarks>
@internal abstract class IZoneIntervalMap
{
  ZoneInterval GetZoneInterval(Instant instant);
}

// This is slightly ugly, but it allows us to use any time zone as the tail
// zone for PrecalculatedDateTimeZone, which is handy for testing.
@internal abstract class IZoneIntervalMapWithMinMax extends IZoneIntervalMap
{
  // todo: getters or finals?
  Offset get minOffset; // { get; }
  Offset get maxOffset; // { get; }
}