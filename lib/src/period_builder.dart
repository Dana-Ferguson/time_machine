// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';

/// A mutable builder class for [Period] values. Each property can
/// be set independently, and then a Period can be created from the result
/// using the [Build] method.
///
/// <threadsafety>
/// This type is not thread-safe without extra synchronization, but has no
/// thread affinity.
/// </threadsafety>
class PeriodBuilder {
  /// Gets or sets the number of years within the period.
  int Years;

  /// Gets or sets the number of months within the period.
  int Months;

  /// Gets or sets the number of weeks within the period.
  int Weeks;

  /// Gets or sets the number of days within the period.
  int Days;

  /// Gets or sets the number of hours within the period.
  int Hours;

  /// Gets or sets the number of minutes within the period.
  int Minutes;

  /// Gets or sets the number of seconds within the period.
  int Seconds;

  /// Gets or sets the number of milliseconds within the period.
  int Milliseconds;

  /// Gets or sets the number of ticks within the period.
  int Ticks;

  /// Gets or sets the number of nanoseconds within the period.
  int Nanoseconds;

  /// Creates a new period builder with an initially zero period or
  /// creates a new period builder with the values from an existing
  /// period. Calling this constructor instead of [Period.ToBuilder]
  /// allows object initializers to be used.
  ///
  /// [period]: An existing period to copy values from.
  PeriodBuilder([Period period = Period.Zero]) {
    Preconditions.checkNotNull(period, 'period');
    Years = period.Years;
    Months = period.Months;
    Weeks = period.Weeks;
    Days = period.Days;
    Hours = period.Hours;
    Minutes = period.Minutes;
    Seconds = period.Seconds;
    Milliseconds = period.Milliseconds;
    Ticks = period.Ticks;
    Nanoseconds = period.Nanoseconds;
  }

  static final Map<PeriodUnits, int Function(PeriodBuilder)> _indexGetterFunctionMap = {
    PeriodUnits.years: (PeriodBuilder p) => p.Years,
    PeriodUnits.months: (PeriodBuilder p) => p.Months,
    PeriodUnits.weeks: (PeriodBuilder p) => p.Weeks,
    PeriodUnits.days: (PeriodBuilder p) => p.Days,
    PeriodUnits.hours: (PeriodBuilder p) => p.Hours,
    PeriodUnits.minutes: (PeriodBuilder p) => p.Minutes,
    PeriodUnits.seconds: (PeriodBuilder p) => p.Seconds,
    PeriodUnits.milliseconds: (PeriodBuilder p) => p.Milliseconds,
    PeriodUnits.ticks: (PeriodBuilder p) => p.Ticks,
    PeriodUnits.nanoseconds: (PeriodBuilder p) => p.Nanoseconds
  };

  static final Map<PeriodUnits, Function(PeriodBuilder, int)> _indexSetterFunctionMap = {
    PeriodUnits.years: (PeriodBuilder p, int v) => p.Years = v,
    PeriodUnits.months: (PeriodBuilder p, int v) => p.Months = v,
    PeriodUnits.weeks: (PeriodBuilder p, int v) => p.Weeks = v,
    PeriodUnits.days: (PeriodBuilder p, int v) => p.Days = v,
    PeriodUnits.hours: (PeriodBuilder p, int v) => p.Hours = v,
    PeriodUnits.minutes: (PeriodBuilder p, int v) => p.Minutes = v,
    PeriodUnits.seconds: (PeriodBuilder p, int v) => p.Seconds = v,
    PeriodUnits.milliseconds: (PeriodBuilder p, int v) => p.Milliseconds = v,
    PeriodUnits.ticks: (PeriodBuilder p, int v) => p.Ticks = v,
    PeriodUnits.nanoseconds: (PeriodBuilder p, int v) => p.Nanoseconds = v
  };

  /// Gets or sets the value of a single unit.
  ///
  /// The type of this indexer is [System.Int64] for uniformity, but any date unit (year, month, week, day) will only ever have a value
  /// in the range of [System.Int32].
  ///
  /// For the [PeriodUnits.nanoseconds] unit, the value is converted to `Int64` when reading from the indexer, causing it to
  /// fail if the value is out of range (around 250 years). To access the values of very large numbers of nanoseconds, use the [Nanoseconds]
  /// property directly.
  ///
  /// [unit]: A single value within the [PeriodUnits] enumeration.
  ///
  /// [ArgumentOutOfRangeException]: [unit] is not a single unit, or a value is provided for a date unit which is outside the range of [System.Int32].
  int operator [](PeriodUnits unit) {
    if (_indexGetterFunctionMap.containsKey(unit)) return _indexGetterFunctionMap[unit](this);
    throw new ArgumentError("Indexer for PeriodBuilder only takes a single unit");
  }

  void operator []=(PeriodUnits unit, int value) {
//  if ((unit.value & PeriodUnits.allDateUnits.value) != 0)
//  {
//    Preconditions.checkArgumentRange('value', value, int.MinValue, int.MaxValue);
//  }

    if (_indexSetterFunctionMap.containsKey(unit)) return _indexSetterFunctionMap[unit](this, value);
    throw new ArgumentError("Indexer for PeriodBuilder only takes a single unit");
  }


  // todo: this doesn't work well with the cascade pattern.. is there a way around that?
  /// Builds a period from the properties in this builder.
  ///
  /// Returns: A period containing the values from this builder.
  Period Build() =>
      new Period(Years: Years,
          Months: Months,
          Weeks: Weeks,
          Days: Days,
          Hours: Hours,
          Minutes: Minutes,
          Seconds: Seconds,
          Milliseconds: Milliseconds,
          Ticks: Ticks,
          Nanoseconds: Nanoseconds);
}
