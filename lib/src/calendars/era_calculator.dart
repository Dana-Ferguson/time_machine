// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Calendars/EraCalculator.cs
// 6d738d5  on Aug 13, 2015

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

  @internal int GetMinYearOfEra(Era era);
  @internal int GetMaxYearOfEra(Era era);
  @internal Era GetEra(int absoluteYear);
  @internal int GetYearOfEra(int absoluteYear);
  @internal int GetAbsoluteYear(int yearOfEra, Era era);
}
