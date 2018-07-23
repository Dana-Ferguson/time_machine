// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';

/// Era calculator for Gregorian and Julian calendar systems, which use BC and AD.
@immutable
@internal
class GJEraCalculator extends EraCalculator {
  final int _maxYearOfBc;
  final int _maxYearOfAd;

  GJEraCalculator(YearMonthDayCalculator ymdCalculator)
      : _maxYearOfBc = 1 - ymdCalculator.minYear,
        // Convert from absolute to year-of-era
        _maxYearOfAd = ymdCalculator.maxYear,
        super([Era.beforeCommon, Era.common]);

  void _validateEra(Era era) {
    if (era != Era.common && era != Era.beforeCommon) {
      Preconditions.checkNotNull(era, 'era');
      Preconditions.checkArgument(false, 'era', "Era ${era.name} is not supported by this calendar; only BC and AD are supported");
    }
  }

  @override
  int getAbsoluteYear(int yearOfEra, Era era) {
    _validateEra(era);
    if (era == Era.common) {
      Preconditions.checkArgumentRange('yearOfEra', yearOfEra, 1, _maxYearOfAd);
      return yearOfEra;
    }
    Preconditions.checkArgumentRange('yearOfEra', yearOfEra, 1, _maxYearOfBc);
    return 1 - yearOfEra;
  }

  @override
  int getYearOfEra(int absoluteYear) {
    return absoluteYear > 0 ? absoluteYear : 1 - absoluteYear;
  }

  @override
  Era getEra(int absoluteYear) => absoluteYear > 0 ? Era.common : Era.beforeCommon;

  @override
  int getMinYearOfEra(Era era) {
    _validateEra(era);
    return 1;
  }

  @override
  int getMaxYearOfEra(Era era) {
    _validateEra(era);
    return era == Era.common ? _maxYearOfAd : _maxYearOfBc;
  }
}
