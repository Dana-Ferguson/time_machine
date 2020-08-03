// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';

/// The epoch to use when constructing an Islamic calendar.
///
/// The Islamic, or Hijri, calendar can either be constructed
/// starting on July 15th 622CE (in the Julian calendar) or on the following day.
/// The former is the 'astronomical' or "Thursday" epoch; the latter is the "civil" or "Friday" epoch.
///
/// [CalendarSystem.getIslamicCalendar]
enum IslamicEpoch
{
  /// Epoch beginning on July 15th 622CE (Julian), which is July 18th 622 CE in the Gregorian calendar.
  /// This is the epoch used by the BCL HijriCalendar.
  astronomical, // = 1,

  /// Epoch beginning on July 16th 622CE (Julian), which is July 19th 622 CE in the Gregorian calendar.
  civil // = 2
}