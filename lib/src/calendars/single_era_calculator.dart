// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine.dart';

// sealed
/// Implementation of [EraCalculator] for calendars which only have a single era.
@internal class SingleEraCalculator extends EraCalculator {
  final Era _era;

  final int _minYear;
  final int _maxYear;

  @internal
  SingleEraCalculator(Era era, YearMonthDayCalculator ymdCalculator)
      :
        _minYear = ymdCalculator.minYear,
        _maxYear = ymdCalculator.maxYear,
        this._era = era,
        super([era]);

  void _validateEra(Era era) {
    if (era != this._era) {
      Preconditions.checkNotNull(era, 'era');
      Preconditions.checkArgument(era == this._era, 'era', "Only supported era is ${this._era.name}; requested era was ${era.name}");
    }
  }

  @internal
  @override
  int getAbsoluteYear(int yearOfEra, Era era) {
    _validateEra(era);
    Preconditions.checkArgumentRange('yearOfEra', yearOfEra, _minYear, _maxYear);
    return yearOfEra;
  }

  @internal
  @override
  int GetYearOfEra(int absoluteYear) => absoluteYear;

  @internal
  @override
  int getMinYearOfEra(Era era) {
    _validateEra(era);
    return _minYear;
  }

  @internal
  @override
  int getMaxYearOfEra(Era era) {
    _validateEra(era);
    return _maxYear;
  }

  @internal
  @override
  Era GetEra(int absoluteYear) => _era;
}
