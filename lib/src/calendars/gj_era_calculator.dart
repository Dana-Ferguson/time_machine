// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

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
  int getAbsoluteYear(int yearOfEra, Era era) {
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
  int getMinYearOfEra(Era era) {
    ValidateEra(era);
    return 1;
  }

  @internal
  @override
  int getMaxYearOfEra(Era era) {
    ValidateEra(era);
    return era == Era.Common ? maxYearOfAd : maxYearOfBc;
  }
}
