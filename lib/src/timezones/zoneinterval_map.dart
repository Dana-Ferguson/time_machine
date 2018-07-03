// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

/// The core part of a DateTimeZone: mapping an Instant to an Interval.
/// Separating this out into an interface allows for flexible caching.
///
/// Benchmarking shows that a delegate may be slightly faster here, but the difference
/// isn't very significant even for very fast calls (cache hits). The interface ends up
/// feeling slightly cleaner elsewhere in the code.
@internal
@interface
abstract class ZoneIntervalMap
{
  ZoneInterval getZoneInterval(Instant instant);
}

// This is slightly ugly, but it allows us to use any time zone as the tail
// zone for PrecalculatedDateTimeZone, which is handy for testing.
@internal
@interface
abstract class ZoneIntervalMapWithMinMax extends ZoneIntervalMap
{
  Offset get minOffset;
  Offset get maxOffset;
}
