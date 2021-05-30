// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';
import 'package:time_machine/src/time_machine_internal.dart';

/// Implementation of [EraCalculator] for calendars which only have a single era.
@internal 
class SingleEraCalculator extends EraCalculator {
  final Era _era;

  final int _minYear;
  final int _maxYear;

  SingleEraCalculator(Era era, YearMonthDayCalculator ymdCalculator)
      :
        _minYear = ymdCalculator.minYear,
        _maxYear = ymdCalculator.maxYear,
        _era = era,
        super([era]);

  void _validateEra(Era era) {
    if (era != _era) {
      Preconditions.checkNotNull(era, 'era');
      Preconditions.checkArgument(era == _era, 'era', "Only supported era is ${_era.name}; requested era was ${era.name}");
    }
  }

  @override
  int getAbsoluteYear(int yearOfEra, Era era) {
    _validateEra(era);
    Preconditions.checkArgumentRange('yearOfEra', yearOfEra, _minYear, _maxYear);
    return yearOfEra;
  }

  @override
  int getYearOfEra(int absoluteYear) => absoluteYear;

  @override
  int getMinYearOfEra(Era era) {
    _validateEra(era);
    return _minYear;
  }

  @override
  int getMaxYearOfEra(Era era) {
    _validateEra(era);
    return _maxYear;
  }

  @override
  Era getEra(int absoluteYear) => _era;
}
