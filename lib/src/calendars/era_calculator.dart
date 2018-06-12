// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';

/// Takes responsibility for all era-based calculations for a calendar.
/// YearMonthDay arguments can be assumed to be valid for the relevant calendar,
/// but other arguments should be validated. (Eras should be validated for nullity as well
/// as for the presence of a particular era.)
@internal abstract class EraCalculator
{
  // todo: technically it's the efficient iterable
  @internal final Iterable<Era> eras;

  @protected EraCalculator(Iterable<Era> eras) : eras = eras; // new ReadOnlyCollection<Era>(eras);

  @internal int getMinYearOfEra(Era era);
  @internal int getMaxYearOfEra(Era era);
  @internal Era getEra(int absoluteYear);
  @internal int getYearOfEra(int absoluteYear);
  @internal int getAbsoluteYear(int yearOfEra, Era era);
}

