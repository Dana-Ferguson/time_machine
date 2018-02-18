// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/PeriodBuilder.cs
// 24fdeef  on Apr 10, 2017

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';

/// A mutable builder class for <see cref="Period"/> values. Each property can
/// be set independently, and then a Period can be created from the result
/// using the <see cref="Build"/> method.
/// </summary>
/// <threadsafety>
/// This type is not thread-safe without extra synchronization, but has no
/// thread affinity.
/// </threadsafety>
class PeriodBuilder {
  /// <summary>
  /// Gets or sets the number of years within the period.
  /// </summary>
  /// <value>The number of years within the period.</value>
  int Years;

  /// <summary>
  /// Gets or sets the number of months within the period.
  /// </summary>
  /// <value>The number of months within the period.</value>
  int Months;

  /// <summary>
  /// Gets or sets the number of weeks within the period.
  /// </summary>
  /// <value>The number of weeks within the period.</value>
  int Weeks;

  /// <summary>
  /// Gets or sets the number of days within the period.
  /// </summary>
  /// <value>The number of days within the period.</value>
  int Days;

  /// <summary>
  /// Gets or sets the number of hours within the period.
  /// </summary>
  /// <value>The number of hours within the period.</value>
  int Hours;

  /// <summary>
  /// Gets or sets the number of minutes within the period.
  /// </summary>
  /// <value>The number of minutes within the period.</value>
  int Minutes;

  /// <summary>
  /// Gets or sets the number of seconds within the period.
  /// </summary>
  /// <value>The number of seconds within the period.</value>
  int Seconds;

  /// <summary>
  /// Gets or sets the number of milliseconds within the period.
  /// </summary>
  /// <value>The number of milliseconds within the period.</value>
  int Milliseconds;

  /// <summary>
  /// Gets or sets the number of ticks within the period.
  /// </summary>
  /// <value>The number of ticks within the period.</value>
  int Ticks;

  /// <summary>
  /// Gets or sets the number of nanoseconds within the period.
  /// </summary>
  /// <value>The number of nanoseconds within the period.</value>
  int Nanoseconds;

  /// <summary>
  /// Creates a new period builder with an initially zero period or
  /// creates a new period builder with the values from an existing
  /// period. Calling this constructor instead of <see cref="Period.ToBuilder"/>
  /// allows object initializers to be used.
  /// </summary>
  /// <param name="period">An existing period to copy values from.</param>
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

  Map<PeriodUnits, int Function(PeriodBuilder)> _indexGetterFunctionMap = {
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

  Map<PeriodUnits, Function(PeriodBuilder, int)> _indexSetterFunctionMap = {
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


  /// <summary>
  /// Gets or sets the value of a single unit.
  /// </summary>
  /// <remarks>
  /// <para>
  /// The type of this indexer is <see cref="System.Int64"/> for uniformity, but any date unit (year, month, week, day) will only ever have a value
  /// in the range of <see cref="System.Int32"/>.
  /// </para>
  /// <para>
  /// For the <see cref="PeriodUnits.Nanoseconds"/> unit, the value is converted to <c>Int64</c> when reading from the indexer, causing it to
  /// fail if the value is out of range (around 250 years). To access the values of very large numbers of nanoseconds, use the <see cref="Nanoseconds"/>
  /// property directly.
  /// </para>
  /// </remarks>
  /// <param name="unit">A single value within the <see cref="PeriodUnits"/> enumeration.</param>
  /// <value>The value of the given unit within this period builder, or zero if the unit is unset.</value>
  /// <exception cref="ArgumentOutOfRangeException"><paramref name="unit"/> is not a single unit, or a value is provided for a date unit which is outside the range of <see cref="System.Int32"/>.</exception>
  int operator [](PeriodUnits unit) {
    if (_indexGetterFunctionMap.containsKey(unit)) return _indexGetterFunctionMap[unit](this);
    throw new ArgumentError("Indexer for PeriodBuilder only takes a single unit");
  }

  void operator []=(PeriodUnits unit, int value) {
//  if ((unit.value & PeriodUnits.allDateUnits.value) != 0)
//  {
//    Preconditions.checkArgumentRange('value', value, int.MinValue, int.MaxValue);
//  }

    if (_indexSetterFunctionMap.containsKey(unit)) _indexSetterFunctionMap[unit](this, value);
    throw new ArgumentError("Indexer for PeriodBuilder only takes a single unit");
  }


  /// <summary>
  /// Builds a period from the properties in this builder.
  /// </summary>
  /// <returns>A period containing the values from this builder.</returns>
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