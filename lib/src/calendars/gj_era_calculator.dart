// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Calendars/GJEraCalculator.cs
// 6d738d5  on Aug 13, 2015

import 'package:meta/meta.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

/// Era calculator for Gregorian and Julian calendar systems, which use BC and AD.
// sealed
@internal class GJEraCalculator extends EraCalculator {
  @private final int maxYearOfBc;
  @private final int maxYearOfAd;

  @internal GJEraCalculator(YearMonthDayCalculator ymdCalculator)
      : maxYearOfBc = 1 - ymdCalculator.minYear,
        // Convert from absolute to year-of-era
        maxYearOfAd = ymdCalculator.maxYear,
        super([Era.BeforeCommon, Era.Common]);

  @private void ValidateEra(Era era) {
    if (era != Era.Common && era != Era.BeforeCommon) {
      Preconditions.checkNotNull(era, 'era');
      Preconditions.checkArgument(false, 'era', "Era ${era.name} is not supported by this calendar; only BC and AD are supported");
    }
  }

  @internal
  @override
  int GetAbsoluteYear(int yearOfEra, Era era) {
    ValidateEra(era);
    if (era == Era.Common) {
      Preconditions.checkArgumentRange('yearOfEra', yearOfEra, 1, maxYearOfAd);
      return yearOfEra;
    }
    Preconditions.checkArgumentRange('yearOfEra', yearOfEra, 1, maxYearOfBc);
    return 1 - yearOfEra;
  }

  @internal
  @override
  int GetYearOfEra(int absoluteYear) {
    return absoluteYear > 0 ? absoluteYear : 1 - absoluteYear;
  }

  @internal
  @override
  Era GetEra(int absoluteYear) => absoluteYear > 0 ? Era.Common : Era.BeforeCommon;

  @internal
  @override
  int GetMinYearOfEra(Era era) {
    ValidateEra(era);
    return 1;
  }

  @internal
  @override
  int GetMaxYearOfEra(Era era) {
    ValidateEra(era);
    return era == Era.Common ? maxYearOfAd : maxYearOfBc;
  }
}