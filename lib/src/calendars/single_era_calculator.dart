// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Calendars/SingleEraCalculator.cs
// 6d738d5  on Aug 13, 2015

import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine.dart';

// sealed
/// Implementation of <see cref="EraCalculator"/> for calendars which only have a single era.
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
  int GetAbsoluteYear(int yearOfEra, Era era) {
    _validateEra(era);
    Preconditions.checkArgumentRange('yearOfEra', yearOfEra, _minYear, _maxYear);
    return yearOfEra;
  }

  @internal
  @override
  int GetYearOfEra(int absoluteYear) => absoluteYear;

  @internal
  @override
  int GetMinYearOfEra(Era era) {
    _validateEra(era);
    return _minYear;
  }

  @internal
  @override
  int GetMaxYearOfEra(Era era) {
    _validateEra(era);
    return _maxYear;
  }

  @internal
  @override
  Era GetEra(int absoluteYear) => _era;
}