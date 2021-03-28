// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';

/// Takes responsibility for all era-based calculations for a calendar.
/// YearMonthDay arguments can be assumed to be valid for the relevant calendar,
/// but other arguments should be validated. (Eras should be validated for nullity as well
/// as for the presence of a particular era.)
@internal
abstract class EraCalculator
{
  final Iterable<Era> eras;

  @protected EraCalculator(Iterable<Era> eras) : eras = eras; // new ReadOnlyCollection<Era>(eras);

  int getMinYearOfEra(Era era);
  int getMaxYearOfEra(Era era);
  Era getEra(int absoluteYear);
  int getYearOfEra(int absoluteYear);
  int getAbsoluteYear(int yearOfEra, Era era);
}

