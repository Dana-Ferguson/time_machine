// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';

/// A mutable builder class for [Period] values. Each property can
/// be set independently, and then a Period can be created from the result
/// using the [build] method.
class PeriodBuilder {
  /// Gets or sets the number of years within the period.
  int years;

  /// Gets or sets the number of months within the period.
  int months;

  /// Gets or sets the number of weeks within the period.
  int weeks;

  /// Gets or sets the number of days within the period.
  int days;

  /// Gets or sets the number of hours within the period.
  int hours;

  /// Gets or sets the number of minutes within the period.
  int minutes;

  /// Gets or sets the number of seconds within the period.
  int seconds;

  /// Gets or sets the number of milliseconds within the period.
  int milliseconds;

  /// Gets or sets the number of ticks within the period.
  int microseconds;

  /// Gets or sets the number of nanoseconds within the period.
  int nanoseconds;

  /// Creates a new period builder with an initially zero period or
  /// creates a new period builder with the values from an existing
  /// period. Calling this constructor instead of [Period.toBuilder]
  /// allows object initializers to be used.
  ///
  /// * [period]: An existing period to copy values from.
  PeriodBuilder([Period period = Period.zero]) :
    years = period.years,
    months = period.months,
    weeks = period.weeks,
    days = period.days,
    hours = period.hours,
    minutes = period.minutes,
    seconds = period.seconds,
    milliseconds = period.milliseconds,
    microseconds = period.microseconds,
    nanoseconds = period.nanoseconds;

  static final Map<PeriodUnits, int Function(PeriodBuilder)> _indexGetterFunctionMap = {
    PeriodUnits.years: (PeriodBuilder p) => p.years,
    PeriodUnits.months: (PeriodBuilder p) => p.months,
    PeriodUnits.weeks: (PeriodBuilder p) => p.weeks,
    PeriodUnits.days: (PeriodBuilder p) => p.days,
    PeriodUnits.hours: (PeriodBuilder p) => p.hours,
    PeriodUnits.minutes: (PeriodBuilder p) => p.minutes,
    PeriodUnits.seconds: (PeriodBuilder p) => p.seconds,
    PeriodUnits.milliseconds: (PeriodBuilder p) => p.milliseconds,
    PeriodUnits.microseconds: (PeriodBuilder p) => p.microseconds,
    PeriodUnits.nanoseconds: (PeriodBuilder p) => p.nanoseconds
  };

  static final Map<PeriodUnits, Function(PeriodBuilder, int)> _indexSetterFunctionMap = {
    PeriodUnits.years: (PeriodBuilder p, int v) => p.years = v,
    PeriodUnits.months: (PeriodBuilder p, int v) => p.months = v,
    PeriodUnits.weeks: (PeriodBuilder p, int v) => p.weeks = v,
    PeriodUnits.days: (PeriodBuilder p, int v) => p.days = v,
    PeriodUnits.hours: (PeriodBuilder p, int v) => p.hours = v,
    PeriodUnits.minutes: (PeriodBuilder p, int v) => p.minutes = v,
    PeriodUnits.seconds: (PeriodBuilder p, int v) => p.seconds = v,
    PeriodUnits.milliseconds: (PeriodBuilder p, int v) => p.milliseconds = v,
    PeriodUnits.microseconds: (PeriodBuilder p, int v) => p.microseconds = v,
    PeriodUnits.nanoseconds: (PeriodBuilder p, int v) => p.nanoseconds = v
  };

  /// Gets or sets the value of a single unit.
  ///
  /// The type of this indexer is [System.Int64] for uniformity, but any date unit (year, month, week, day) will only ever have a value
  /// in the range of [System.Int32].
  ///
  /// For the [PeriodUnits.nanoseconds] unit, the value is converted to `Int64` when reading from the indexer, causing it to
  /// fail if the value is out of range (around 250 years). To access the values of very large numbers of nanoseconds, use the [nanoseconds]
  /// property directly.
  ///
  /// * [unit]: A single value within the [PeriodUnits] enumeration.
  ///
  /// [ArgumentError]: [unit] is not a single unit, or a value is provided for a date unit which is outside the range of `System.Int32`.
  int operator [](PeriodUnits unit) {
    if (_indexGetterFunctionMap.containsKey(unit)) return _indexGetterFunctionMap[unit]!(this);
    throw ArgumentError('Indexer for PeriodBuilder only takes a single unit');
  }

  // todo: I.O.U. some documentation
  void operator []=(PeriodUnits unit, int value) {
//  if ((unit.value & PeriodUnits.allDateUnits.value) != 0)
//  {
//    Preconditions.checkArgumentRange('value', value, int.MinValue, int.MaxValue);
//  }

    if (_indexSetterFunctionMap.containsKey(unit)) return _indexSetterFunctionMap[unit]!(this, value);
    throw ArgumentError('Indexer for PeriodBuilder only takes a single unit');
  }


  // todo: this doesn't work well with the cascade pattern.. is there a way around that?
  /// Builds a period from the properties in this builder.
  ///
  /// Returns: A period containing the values from this builder.
  Period build() =>
      IPeriod.period(years: years,
          months: months,
          weeks: weeks,
          days: days,
          hours: hours,
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
          microseconds: microseconds,
          nanoseconds: nanoseconds);
}
