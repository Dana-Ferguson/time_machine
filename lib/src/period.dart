// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_fields.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_text.dart';

@immutable @private
class DateComponentsBetweenResult {
// @private static LocalDate DateComponentsBetween(LocalDate start, LocalDate end, PeriodUnits units,
//     out int years, out int months, out int weeks, out int days)

  final LocalDate date;
  final int years;
  final int months;
  final int weeks;
  final int days;

  DateComponentsBetweenResult(this.date, this.years, this.months, this.weeks, this.days);
}

// @private static void TimeComponentsBetween(int totalNanoseconds, PeriodUnits units,
// out int hours, out int minutes, out int seconds, out int milliseconds, out int ticks, out int nanoseconds)
@immutable @private
class TimeComponentsBetweenResult {
  int hours;
  int minutes;
  int seconds;
  int milliseconds;
  int ticks;
  int nanoseconds;

  TimeComponentsBetweenResult(this.hours, this.minutes, this.seconds, this.milliseconds, this.ticks, this.nanoseconds);
}


/// Represents a period of time expressed in human chronological terms: hours, days,
/// weeks, months and so on.
///
/// A [Period] contains a set of properties such as [Years], [Months], and so on
/// that return the number of each unit contained within this period. Note that these properties are not normalized in
/// any way by default, and so a [Period] may contain values such as "2 hours and 90 minutes". The
/// [Normalize] method will convert equivalent periods into a standard representation.
///
/// Periods can contain negative units as well as positive units ("+2 hours, -43 minutes, +10 seconds"), but do not
/// differentiate between properties that are zero and those that are absent (i.e. a period created as "10 years"
/// and one created as "10 years, zero months" are equal periods; the [Months] property returns zero in
/// both cases).
///
/// [Period] equality is implemented by comparing each property's values individually.
///
/// Periods operate on calendar-related types such as
/// [LocalDateTime] whereas [Duration] operates on instants
/// on the time line. (Note that although [ZonedDateTime] includes both concepts, it only supports
/// duration-based arithmetic.)
///
/// <threadsafety>This type is immutable reference type. See the thread safety section of the user guide for more information.</threadsafety>
@immutable
class Period // : IEquatable<Period>
    {
// General implementation note: operations such as normalization work out the total number of nanoseconds as an Int64
// value. This can handle +/- 106,751 days, or 292 years. We could move to using BigInteger if we feel that's required,
// but it's unlikely to be an issue. Ideally, we'd switch to use BigInteger after detecting that it could be a problem,
// but without the hit of having to catch the exception...


  /// A period containing only zero-valued properties.
  static const Period Zero = const Period();


/// Returns an equality comparer which compares periods by first normalizing them - so 24 hours is deemed equal to 1 day, and so on.
/// Note that as per the [Normalize] method, years and months are unchanged by normalization - so 12 months does not
/// equal 1 year.
// todo: what to do about this?
// static IEqualityComparer<Period> NormalizingEqualityComparer => NormalizingPeriodEqualityComparer.Instance;

// The fields that make up this period.


  /// Gets the number of nanoseconds within this period.
  ///
  /// This property returns zero both when the property has been explicitly set to zero and when the period does not
  /// contain this property.
  final int Nanoseconds;


  /// Gets the number of ticks within this period.
  ///
  /// This property returns zero both when the property has been explicitly set to zero and when the period does not
  /// contain this property.
  final int Ticks;


  /// Gets the number of milliseconds within this period.
  ///
  /// This property returns zero both when the property has been explicitly set to zero and when the period does not
  /// contain this property.
  final int Milliseconds;


  /// Gets the number of seconds within this period.
  ///
  /// This property returns zero both when the property has been explicitly set to zero and when the period does not
  /// contain this property.
  final int Seconds;


  /// Gets the number of minutes within this period.
  ///
  /// This property returns zero both when the property has been explicitly set to zero and when the period does not
  /// contain this property.
  final int Minutes;


  /// Gets the number of hours within this period.
  ///
  /// This property returns zero both when the property has been explicitly set to zero and when the period does not
  /// contain this property.
  final int Hours;


  /// Gets the number of days within this period.
  ///
  /// This property returns zero both when the property has been explicitly set to zero and when the period does not
  /// contain this property.
  final int Days;


  /// Gets the number of weeks within this period.
  ///
  /// This property returns zero both when the property has been explicitly set to zero and when the period does not
  /// contain this property.
  final int Weeks;


  /// Gets the number of months within this period.
  ///
  /// This property returns zero both when the property has been explicitly set to zero and when the period does not
  /// contain this property.
  final int Months;


  /// Gets the number of years within this period.
  ///
  /// This property returns zero both when the property has been explicitly set to zero and when the period does not
  /// contain this property.
  final int Years;


///// Creates a period with the given date values.
///// 
//@private Period(int years, int months, int weeks, int days)
//{
//  this.Years = years;
//  this.Months = months;
//  this.Weeks = weeks;
//  this.Days = days;
//}
//
//
///// Creates a period with the given time values.
///// 
//@private Period(int hours, int minutes, int seconds, int milliseconds, int ticks, int nanoseconds)
//{
//  this.Hours = hours;
//  this.Minutes = minutes;
//  this.Seconds = seconds;
//  this.Milliseconds = milliseconds;
//  this.Ticks = ticks;
//  this.Nanoseconds = nanoseconds;
//}

  /// Creates a period with the given time values.
  @internal const Period({this.Years: 0, this.Months: 0, this.Weeks: 0, this.Days: 0,
    this.Hours: 0, this.Minutes: 0, this.Seconds: 0,
    this.Milliseconds: 0, this.Ticks: 0, this.Nanoseconds: 0});


///// Creates a new period from the given values.
///// 
//@internal Period(int years, int months, int weeks, int days, int hours, int minutes, int seconds,
//    int milliseconds, int ticks, int nanoseconds)
//{
//  this.Years = years;
//  this.Months = months;
//  this.Weeks = weeks;
//  this.Days = days;
//  this.Hours = hours;
//  this.Minutes = minutes;
//  this.Seconds = seconds;
//  this.Milliseconds = milliseconds;
//  this.Ticks = ticks;
//  this.Nanoseconds = nanoseconds;
//}

// todo: these are all terrible ... remove them ??? ... do they add extra or does tree shaking shank these?

  /// Creates a period representing the specified number of years.
  ///
  /// [years]: The number of years in the new period
  /// Returns: A period consisting of the given number of years.
  factory Period.fromYears(int years) => new Period(Years: years);


  /// Creates a period representing the specified number of months.
  ///
  /// [months]: The number of months in the new period
  /// Returns: A period consisting of the given number of months.
  factory Period.fromMonths(int months) => new Period(Months: months);


/// Creates a period representing the specified number of weeks.
///
/// [weeks]: The number of weeks in the new period
/// Returns: A period consisting of the given number of weeks.

  factory Period.fromWeeks(int weeks) => new Period(Weeks: weeks);


/// Creates a period representing the specified number of days.
///
/// [days]: The number of days in the new period
/// Returns: A period consisting of the given number of days.

  factory Period.fromDays(int days) => new Period(Days: days);


/// Creates a period representing the specified number of hours.
///
/// [hours]: The number of hours in the new period
/// Returns: A period consisting of the given number of hours.

  factory Period.fromHours(int hours) => new Period(Hours: hours);


/// Creates a period representing the specified number of minutes.
///
/// [minutes]: The number of minutes in the new period
/// Returns: A period consisting of the given number of minutes.

  factory Period.fromMinutes(int minutes) => new Period(Minutes: minutes);


/// Creates a period representing the specified number of seconds.
///
/// [seconds]: The number of seconds in the new period
/// Returns: A period consisting of the given number of seconds.

  factory Period.fromSeconds(int seconds) => new Period(Seconds: seconds);


/// Creates a period representing the specified number of milliseconds.
///
/// [milliseconds]: The number of milliseconds in the new period
/// Returns: A period consisting of the given number of milliseconds.

  factory Period.fromMilliseconds(int milliseconds) => new Period(Milliseconds: milliseconds);


/// Creates a period representing the specified number of ticks.
///
/// [ticks]: The number of ticks in the new period
/// Returns: A period consisting of the given number of ticks.

  factory Period.fromTicks(int ticks) => new Period(Ticks: ticks);


/// Creates a period representing the specified number of nanooseconds.
///
/// [nanoseconds]: The number of nanoseconds in the new period
/// Returns: A period consisting of the given number of nanoseconds.

  factory Period.fromNanoseconds(int nanoseconds) => new Period(Nanoseconds: nanoseconds);


/// Adds two periods together, by simply adding the values for each property.
///
/// [left]: The first period to add
/// [right]: The second period to add
/// The sum of the two periods. The units of the result will be the union of those in both
/// periods.

  Period operator +(Period right) {
    Preconditions.checkNotNull(right, 'right');
    return new Period(Years: Years + right.Years,
        Months: Months + right.Months,
        Weeks: Weeks + right.Weeks,
        Days: Days + right.Days,
        Hours: Hours + right.Hours,
        Minutes: Minutes + right.Minutes,
        Seconds: Seconds + right.Seconds,
        Milliseconds: Milliseconds + right.Milliseconds,
        Ticks: Ticks + right.Ticks,
        Nanoseconds: Nanoseconds + right.Nanoseconds);
  }


  /// Creates an [IComparer{T}] for periods, using the given "base" local date/time.
  ///
  /// Certain periods can't naturally be compared without more context - how "one month" compares to
  /// "30 days" depends on where you start. In order to compare two periods, the returned comparer
  /// effectively adds both periods to the "base" specified by [baseDateTime] and compares
  /// the results. In some cases this arithmetic isn't actually required - when two periods can be
  /// converted to durations, the comparer uses that conversion for efficiency.
  ///
  /// [baseDateTime]: The base local date/time to use for comparisons.
  /// Returns: The new comparer.
  // todo: what to do abuot IComparer?
  // static IComparer<Period> CreateComparer(LocalDateTime baseDateTime) => new PeriodComparer(baseDateTime);
  static PeriodComparer CreateComparer(LocalDateTime baseDateTime) => new PeriodComparer(baseDateTime);


/// Subtracts one period from another, by simply subtracting each property value.
///
/// [minuend]: The period to subtract the second operand from
/// [subtrahend]: The period to subtract the first operand from
/// The result of subtracting all the values in the second operand from the values in the first. The
/// units of the result will be the union of both periods, even if the subtraction caused some properties to
/// become zero (so "2 weeks, 1 days" minus "2 weeks" is "zero weeks, 1 days", not "1 days").

  Period operator -(Period subtrahend) {
    Preconditions.checkNotNull(subtrahend, 'subtrahend');
    return new Period(
        Years: Years - subtrahend.Years,
        Months: Months - subtrahend.Months,
        Weeks: Weeks - subtrahend.Weeks,
        Days: Days - subtrahend.Days,
        Hours: Hours - subtrahend.Hours,
        Minutes: Minutes - subtrahend.Minutes,
        Seconds: Seconds - subtrahend.Seconds,
        Milliseconds: Milliseconds - subtrahend.Milliseconds,
        Ticks: Ticks - subtrahend.Ticks,
        Nanoseconds: Nanoseconds - subtrahend.Nanoseconds);
  }
  
/// Returns the exact difference between two date/times or
/// returns the period between a start and an end date/time, using only the given units.
///
/// If [end] is before <paramref name="start" />, each property in the returned period
/// will be negative. If the given set of units cannot exactly reach the end point (e.g. finding
/// the difference between 1am and 3:15am in hours) the result will be such that adding it to [start]
/// will give a value between [start] and [end]. In other words,
/// any rounding is "towards start"; this is true whether the resulting period is negative or positive.
///
/// [start]: Start date/time
/// [end]: End date/time
/// [units]: Units to use for calculations
/// [ArgumentException]: [units] is empty or contained unknown values.
/// [ArgumentException]: [start] and [end] use different calendars.
/// Returns: The period between the given date/times, using the given units.

  static Period Between(LocalDateTime start, LocalDateTime end, [PeriodUnits units = PeriodUnits.dateAndTime]) {
    Preconditions.checkArgument(units != PeriodUnits.none, 'units', "Units must not be empty");
    Preconditions.checkArgument((units.value & ~PeriodUnits.allUnits.value) == 0, 'units', "Units contains an unknown value: $units");
    CalendarSystem calendar = start.Calendar;
    Preconditions.checkArgument(calendar == end.Calendar, 'end', "start and end must use the same calendar system");

    if (start == end) {
      return Zero;
    }

    // Adjust for situations like "days between 5th January 10am and 7th Janary 5am" which should be one
    // day, because if we actually reach 7th January with date fields, we've overshot.
    // The date adjustment will always be valid, because it's just moving it towards start.
    // We need this for all date-based period fields. We could potentially optimize by not doing this
    // in cases where we've only got time fields...
    LocalDate endDate = end.Date;
    if (start < end) {
      if (start.TimeOfDay > end.TimeOfDay) {
        endDate = endDate.plusDays(-1);
      }
    }
    else if (start > end && start.TimeOfDay < end.TimeOfDay) {
      endDate = endDate.plusDays(1);
    }

    // Optimization for single field
    // todo: optimize me?
    Map betweenFunctionMap = {
      PeriodUnits.years:  () => new Period.fromYears(DatePeriodFields.YearsField.UnitsBetween(start.Date, endDate)),
      PeriodUnits.months: () => new Period.fromMonths(DatePeriodFields.MonthsField.UnitsBetween(start.Date, endDate)),
      PeriodUnits.weeks: () => new Period.fromWeeks(DatePeriodFields.WeeksField.UnitsBetween(start.Date, endDate)),
      PeriodUnits.days: () => new Period.fromDays(DaysBetween(start.Date, endDate)),
      PeriodUnits.hours: () => new Period.fromHours(TimePeriodField.Hours.UnitsBetween(start, end)),
      PeriodUnits.minutes: () => new Period.fromMinutes(TimePeriodField.Minutes.UnitsBetween(start, end)),
      PeriodUnits.seconds: () => new Period.fromSeconds(TimePeriodField.Seconds.UnitsBetween(start, end)),
      PeriodUnits.milliseconds: () => new Period.fromMilliseconds(TimePeriodField.Milliseconds.UnitsBetween(start, end)),
      PeriodUnits.ticks: () => new Period.fromTicks(TimePeriodField.Ticks.UnitsBetween(start, end)),
      PeriodUnits.nanoseconds: () => new Period.fromNanoseconds(TimePeriodField.Nanoseconds.UnitsBetween(start, end))
    };
    
    if (betweenFunctionMap.containsKey(units)) return betweenFunctionMap[units]();
    
//    switch (units) {
//      case PeriodUnits.years:
//        return new Period.fromYears(DatePeriodFields.YearsField.UnitsBetween(start.Date, endDate));
//      case PeriodUnits.months:
//        return new Period.fromMonths(DatePeriodFields.MonthsField.UnitsBetween(start.Date, endDate));
//      case PeriodUnits.weeks:
//        return new Period.fromWeeks(DatePeriodFields.WeeksField.UnitsBetween(start.Date, endDate));
//      case PeriodUnits.days:
//        return new Period.fromDays(DaysBetween(start.Date, endDate));
//      case PeriodUnits.hours:
//        return new Period.fromHours(TimePeriodField.Hours.UnitsBetween(start, end));
//      case PeriodUnits.minutes:
//        return new Period.fromMinutes(TimePeriodField.Minutes.UnitsBetween(start, end));
//      case PeriodUnits.seconds:
//        return new Period.fromSeconds(TimePeriodField.Seconds.UnitsBetween(start, end));
//      case PeriodUnits.milliseconds:
//        return new Period.fromMilliseconds(TimePeriodField.Milliseconds.UnitsBetween(start, end));
//      case PeriodUnits.ticks:
//        return new Period.fromTicks(TimePeriodField.Ticks.UnitsBetween(start, end));
//      case PeriodUnits.nanoseconds:
//        return new Period.fromNanoseconds(TimePeriodField.Nanoseconds.UnitsBetween(start, end));
//    }

    // Multiple fields
    LocalDateTime remaining = start;
    int years = 0,
        months = 0,
        weeks = 0,
        days = 0;
    if ((units.value & PeriodUnits.allDateUnits.value) != 0) {
      // LocalDate remainingDate = DateComponentsBetween(
      //  start.Date, endDate, units, out years, out months, out weeks, out days);
      var result = DateComponentsBetween(start.Date, endDate, units);
      years = result.years;
      months = result.months;
      weeks = result.weeks;
      days = result.days;

      var remainingDate = result.date;
      remaining = new LocalDateTime(remainingDate, start.TimeOfDay);
    }
    if ((units.value & PeriodUnits.allTimeUnits.value) == 0) {
      return new Period(Years: years, Months: months, Weeks: weeks, Days: days);
    }

    // The remainder of the computation is with fixed-length units, so we can do it all with
    // Duration instead of Local* values. We don't know for sure that this is small though - we *could*
    // be trying to find the difference between 9998 BC and 9999 CE in nanoseconds...
    // Where we can optimize, do everything with int arithmetic (as we do for Between(LocalTime, LocalTime)).
    // Otherwise (rare case), use duration arithmetic.
    int hours, minutes, seconds, milliseconds, ticks, nanoseconds;
    var duration = end
        .ToLocalInstant()
        .TimeSinceLocalEpoch - remaining
        .ToLocalInstant()
        .TimeSinceLocalEpoch;
    if (duration.IsInt64Representable) {
      var result = TimeComponentsBetween(duration.totalNanoseconds, units);
      hours = result.hours;
      minutes = result.minutes;
      seconds = result.seconds;
      milliseconds = result.milliseconds;
      ticks = result.ticks;
      nanoseconds = result.nanoseconds;
    // throw new UnimplementedError('this is not done.');
    // TimeComponentsBetween(duration.ToInt64Nanoseconds(), units, out hours, out minutes, out seconds, out milliseconds, out ticks, out nanoseconds);
    }
    else {
      int UnitsBetween(PeriodUnits mask, TimePeriodField timeField) {
        if ((mask.value & units.value) == 0) {
          return 0;
        }
        int value = timeField.GetUnitsInDuration(duration);
        duration -= timeField.ToDuration(value);
        return value;
      }

      hours = UnitsBetween(PeriodUnits.hours, TimePeriodField.Hours);
      minutes = UnitsBetween(PeriodUnits.minutes, TimePeriodField.Minutes);
      seconds = UnitsBetween(PeriodUnits.seconds, TimePeriodField.Seconds);
      milliseconds = UnitsBetween(PeriodUnits.milliseconds, TimePeriodField.Milliseconds);
      ticks = UnitsBetween(PeriodUnits.ticks, TimePeriodField.Ticks);
      nanoseconds = UnitsBetween(PeriodUnits.ticks, TimePeriodField.Nanoseconds);
    }
    return new Period(Years: years,
        Months: months,
        Weeks: weeks,
        Days: days,
        Hours: hours,
        Minutes: minutes,
        Seconds: seconds,
        Milliseconds: milliseconds,
        Ticks: ticks,
        Nanoseconds: nanoseconds);
  }


  /// Common code to perform the date parts of the Between methods.
  ///
  /// [start]: Start date
  /// [end]: End date
  /// [units]: Units to compute
  /// [years]: (Out) Year component of result
  /// [months]: (Out) Months component of result
  /// [weeks]: (Out) Weeks component of result
  /// [days]: (Out) Days component of result
  /// The resulting date after adding the result components to [start] (to
  /// allow further computations to be made)
  @private static DateComponentsBetweenResult DateComponentsBetween(LocalDate start, LocalDate end, PeriodUnits units) {
    var result = new OutBox(start);

    /*
  int UnitsBetween(PeriodUnits maskedUnits, /*ref*/ LocalDate startDate, LocalDate endDate, IDatePeriodField dateField)
  {
    if (maskedUnits.value == 0)
    {
      return 0;
    }
    int value = dateField.UnitsBetween(startDate, endDate);
    startDate = dateField.Add(startDate, value);
    return value;
  }
  * */

    // this is PeriodUnits maskedUnits in nodatime... but, it's nicer for dart this way
    int UnitsBetween(int maskedUnits, OutBox<LocalDate> startDate, IDatePeriodField dateField) {
      if (maskedUnits == 0) {
        return 0;
      }

      int value = dateField.UnitsBetween(startDate.value, end);
      startDate.value = dateField.Add(startDate.value, value);
      return value;
    }

    var years = UnitsBetween(units.value & PeriodUnits.years.value, result, DatePeriodFields.YearsField);
    var months = UnitsBetween(units.value & PeriodUnits.months.value, result, DatePeriodFields.MonthsField);
    var weeks = UnitsBetween(units.value & PeriodUnits.weeks.value, result, DatePeriodFields.WeeksField);
    var days = UnitsBetween(units.value & PeriodUnits.days.value, result, DatePeriodFields.DaysField);

    return new DateComponentsBetweenResult(result.value, years, months, weeks, days);
  }


  /// Common code to perform the time parts of the Between methods for long-representable nanos.
  ///
  /// [totalNanoseconds]: Number of nanoseconds to compute the units of
  /// [units]: Units to compute
  /// [hours]: (Out) Hours component of result
  /// [minutes]: (Out) Minutes component of result
  /// [seconds]: (Out) Seconds component of result
  /// [milliseconds]: (Out) Milliseconds component of result
  /// [ticks]: (Out) Ticks component of result
  /// [nanoseconds]: (Out) Nanoseconds component of result
  @private static TimeComponentsBetweenResult TimeComponentsBetween(int totalNanoseconds, PeriodUnits units) {
    int UnitsBetween(PeriodUnits mask, int nanosecondsPerUnit) {
      if ((mask.value & units.value) == 0) {
        return 0;
      }

      int value = totalNanoseconds ~/ nanosecondsPerUnit;
      // This has been tested and found to be faster than using totalNanoseconds %= nanosecondsPerUnit
      // todo: that was tested in dotnet, not dart
      totalNanoseconds -= value * nanosecondsPerUnit;
      return value;
    }

    var hours = UnitsBetween(PeriodUnits.hours, TimeConstants.nanosecondsPerHour);
    var minutes = UnitsBetween(PeriodUnits.minutes, TimeConstants.nanosecondsPerMinute);
    var seconds = UnitsBetween(PeriodUnits.seconds, TimeConstants.nanosecondsPerSecond);
    var milliseconds = UnitsBetween(PeriodUnits.milliseconds, TimeConstants.nanosecondsPerMillisecond);
    var ticks = UnitsBetween(PeriodUnits.ticks, TimeConstants.nanosecondsPerTick);
    var nanoseconds = UnitsBetween(PeriodUnits.nanoseconds, 1);

    return new TimeComponentsBetweenResult(hours, minutes, seconds, milliseconds, ticks, nanoseconds);
  }

// TODO(optimization): These three methods are only ever used with scalar values of 1 or -1. Unlikely that
// the multiplications are going to be relevant, but may be worth testing. (Easy enough to break out
// code for the two values separately.)


/// Adds the time components of this period to the given time, scaled accordingly.

  @internal LocalTime AddTimeTo(LocalTime time, int scalar) =>
      time.PlusHours(Hours * scalar)
          .PlusMinutes(Minutes * scalar)
          .PlusSeconds(Seconds * scalar)
          .PlusMilliseconds(Milliseconds * scalar)
          .PlusTicks(Ticks * scalar)
          .PlusNanoseconds(Nanoseconds * scalar);


/// Adds the date components of this period to the given time, scaled accordingly.

  @internal LocalDate AddDateTo(LocalDate date, int scalar) =>
      date.plusYears(Years * scalar)
          .plusMonths(Months * scalar)
          .plusWeeks(Weeks * scalar)
          .plusDays(Days * scalar);


  /// Adds the contents of this period to the given date and time, with the given scale (either 1 or -1, usually).
  @internal LocalDateTime AddDateTimeTo(LocalDate date, LocalTime time, int scalar) {
    date = AddDateTo(date, scalar);
    // todo: probably a better way here
    int extraDays = 0;
    var result = TimePeriodField.Hours.AddTime(time, Hours * scalar, /*ref*/ extraDays);
    extraDays = result.extraDays; time = result.time;
    result = TimePeriodField.Minutes.AddTime(time, Minutes * scalar, /*ref*/ extraDays);
    extraDays = result.extraDays; time = result.time;
    result = TimePeriodField.Seconds.AddTime(time, Seconds * scalar, /*ref*/ extraDays);
    extraDays = result.extraDays; time = result.time;
    result = TimePeriodField.Milliseconds.AddTime(time, Milliseconds * scalar, /*ref*/ extraDays);
    extraDays = result.extraDays; time = result.time;
    result = TimePeriodField.Ticks.AddTime(time, Ticks * scalar, /*ref*/ extraDays);
    extraDays = result.extraDays; time = result.time;
    result = TimePeriodField.Nanoseconds.AddTime(time, Nanoseconds * scalar, /*ref*/ extraDays);
    extraDays = result.extraDays; time = result.time;
    // TODO(optimization): Investigate the performance impact of us calling PlusDays twice.
    // Could optimize by including that in a single call...
    return new LocalDateTime(date.plusDays(extraDays), time);
  }

  static Map<PeriodUnits, Period Function(LocalDate, LocalDate)> _functionMapBetweenDates = {
    PeriodUnits.years: (start, end) => new Period.fromYears(DatePeriodFields.YearsField.UnitsBetween(start, end)),
    PeriodUnits.months: (start, end) => new Period.fromMonths(DatePeriodFields.MonthsField.UnitsBetween(start, end)),
    PeriodUnits.weeks: (start, end) => new Period.fromWeeks(DatePeriodFields.WeeksField.UnitsBetween(start, end)),
    PeriodUnits.days: (start, end) => new Period.fromDays(DaysBetween(start, end))
  };

  /// Returns the exact difference between two dates or returns the period between a start and an end date, using only the given units.
  ///
  /// If [end] is before <paramref name="start" />, each property in the returned period
  /// will be negative. If the given set of units cannot exactly reach the end point (e.g. finding
  /// the difference between 12th February and 15th March in months) the result will be such that adding it to [start]
  /// will give a value between [start] and [end]. In other words,
  /// any rounding is "towards start"; this is true whether the resulting period is negative or positive.
  ///
  /// [start]: Start date
  /// [end]: End date
  /// [units]: Units to use for calculations
  /// [ArgumentException]: [units] contains time units, is empty or contains unknown values.
  /// [ArgumentException]: [start] and [end] use different calendars.
  /// Returns: The period between the given dates, using the given units.
  static Period BetweenDates(LocalDate start, LocalDate end, [PeriodUnits units = PeriodUnits.yearMonthDay]) {
    Preconditions.checkArgument((units.value & PeriodUnits.allTimeUnits.value) == 0, 'units', "Units contains time units: $units");
    Preconditions.checkArgument(units.value != 0, 'units', "Units must not be empty");
    Preconditions.checkArgument((units.value & ~PeriodUnits.allUnits.value) == 0, 'units', "Units contains an unknown value: $units");
    CalendarSystem calendar = start.calendar;
    Preconditions.checkArgument(calendar == end.calendar, 'end', "start and end must use the same calendar system");

    if (start == end) {
      return Zero;
    }

    // Optimization for single field
    var singleFieldFunction = _functionMapBetweenDates[units];
    if (singleFieldFunction != null) return singleFieldFunction(start, end);

    // Multiple fields todo: if these result_type functions are just used to make periods, we can simply them
    var result = DateComponentsBetween(start, end, units);
    return new Period(Years: result.years, Months: result.months, Weeks: result.weeks, Days: result.days);
  }

  static Map<PeriodUnits, Period Function(int)> _functionMapBetweenTimes = {
    PeriodUnits.hours: (remaining) => new Period.fromHours(remaining ~/ TimeConstants.nanosecondsPerHour),
    PeriodUnits.minutes: (remaining) => new Period.fromMinutes(remaining ~/ TimeConstants.nanosecondsPerMinute),
    PeriodUnits.seconds: (remaining) => new Period.fromSeconds(remaining ~/ TimeConstants.nanosecondsPerSecond),
    PeriodUnits.milliseconds: (remaining) => new Period.fromMilliseconds(remaining ~/ TimeConstants.nanosecondsPerMillisecond),
    PeriodUnits.ticks: (remaining) => new Period.fromTicks(remaining ~/ TimeConstants.nanosecondsPerTick),
    PeriodUnits.nanoseconds: (remaining) => new Period.fromNanoseconds(remaining)
  };

  /// Returns the exact difference between two times or returns the period between a start and an end time, using only the given units.
  ///
  /// If [end] is before <paramref name="start" />, each property in the returned period
  /// will be negative. If the given set of units cannot exactly reach the end point (e.g. finding
  /// the difference between 3am and 4.30am in hours) the result will be such that adding it to [start]
  /// will give a value between [start] and [end]. In other words,
  /// any rounding is "towards start"; this is true whether the resulting period is negative or positive.
  ///
  /// [start]: Start time
  /// [end]: End time
  /// [units]: Units to use for calculations
  /// [ArgumentException]: [units] contains date units, is empty or contains unknown values.
  /// [ArgumentException]: [start] and [end] use different calendars.
  /// Returns: The period between the given times, using the given units.
  static Period BetweenTimes(LocalTime start, LocalTime end, [PeriodUnits units = PeriodUnits.allTimeUnits]) {
    Preconditions.checkArgument((units.value & PeriodUnits.allDateUnits.value) == 0, 'units', "Units contains date units: $units");
    Preconditions.checkArgument(units.value != 0, 'units', "Units must not be empty");
    Preconditions.checkArgument((units.value & ~PeriodUnits.allUnits.value) == 0, 'units', "Units contains an unknown value: $units");

// We know that the difference is in the range of +/- 1 day, which is a relatively small
// number of nanoseconds. All the operations can be done with simple int division/remainder ops,
// so we don't need to delegate to TimePeriodField.

    int remaining = (end.NanosecondOfDay - start.NanosecondOfDay);

    // Optimization for a single unit
    var singleFieldFunction = _functionMapBetweenTimes[units];
    if (singleFieldFunction != null) return singleFieldFunction(remaining);

    var result = TimeComponentsBetween(remaining, units);
    return new Period(Hours: result.hours,
        Minutes: result.minutes,
        Seconds: result.seconds,
        Milliseconds: result.milliseconds,
        Ticks: result.ticks,
        Nanoseconds: result.nanoseconds);
  }

  /// Returns the number of days between two dates. This allows optimizations in DateInterval,
  /// and for date calculations which just use days - we don't need state or a virtual method invocation.
  @internal static int DaysBetween(LocalDate start, LocalDate end) {
    // We already assume the calendars are the same.
    if (start.yearMonthDay == end.yearMonthDay) {
      return 0;
    }
    // Note: I've experimented with checking for the dates being in the same year and optimizing that.
    // It helps a little if they're in the same month, but just that test has a cost for other situations.
    // Being able to find the day of year if they're in the same year but different months doesn't help,
    // somewhat surprisingly.
    int startDays = start.daysSinceEpoch;
    int endDays = end.daysSinceEpoch;
    return endDays - startDays;
  }


  /// Returns whether or not this period contains any non-zero-valued time-based properties (hours or lower).
  bool get HasTimeComponent => Hours != 0 || Minutes != 0 || Seconds != 0 || Milliseconds != 0 || Ticks != 0 || Nanoseconds != 0;


  /// Returns whether or not this period contains any non-zero date-based properties (days or higher).
  bool get HasDateComponent => Years != 0 || Months != 0 || Weeks != 0 || Days != 0;


/// For periods that do not contain a non-zero number of years or months, returns a duration for this period
/// assuming a standard 7-day week, 24-hour day, 60-minute hour etc.
///
/// [InvalidOperationException]: The month or year property in the period is non-zero.
/// [OverflowException]: The period doesn't have years or months, but the calculation
/// overflows the bounds of [Duration]. In some cases this may occur even though the theoretical
/// result would be valid due to balancing positive and negative values, but for simplicity there is
/// no attempt to work around this - in realistic periods, it shouldn't be a problem.
/// Returns: The duration of the period.

  Span ToSpan() {
    if (Months != 0 || Years != 0) {
      // todo: does this apply to us?
      throw new StateError("Cannot construct span of period with non-zero months or years.");
    }
    return new Span(nanoseconds: TotalNanoseconds);
  }


  /// Gets the total number of nanoseconds duration for the 'standard' properties (all bar years and months).
  @private int get TotalNanoseconds =>
      Nanoseconds +
          Ticks * TimeConstants.nanosecondsPerTick +
          Milliseconds * TimeConstants.nanosecondsPerMillisecond +
          Seconds * TimeConstants.nanosecondsPerSecond +
          Minutes * TimeConstants.nanosecondsPerMinute +
          Hours * TimeConstants.nanosecondsPerHour +
          Days * TimeConstants.nanosecondsPerDay +
          Weeks * TimeConstants.nanosecondsPerWeek;


  /// Creates a [PeriodBuilder] from this instance. The new builder
  /// is populated with the values from this period, but is then detached from it:
  /// changes made to the builder are not reflected in this period.
  ///
  /// Returns: A builder with the same values and units as this period.
  PeriodBuilder ToBuilder() => new PeriodBuilder(this);


  /// Returns a normalized version of this period, such that equivalent (but potentially non-equal) periods are
  /// changed to the same representation.
  ///
  /// Months and years are unchanged
  /// (as they can vary in length), but weeks are multiplied by 7 and added to the
  /// Days property, and all time properties are normalized to their natural range.
  /// Subsecond values are normalized to millisecond and "nanosecond within millisecond" values.
  /// So for example, a period of 25 hours becomes a period of 1 day
  /// and 1 hour. A period of 1,500,750,000 nanoseconds becomes 1 second, 500 milliseconds and
  /// 750,000 nanoseconds. Aside from months and years, either all the properties
  /// end up positive, or they all end up negative. "Week" and "tick" units in the returned period are always 0.
  ///
  /// [OverflowException]: The period doesn't have years or months, but it contains more than
  /// [Int64.MaxValue] nanoseconds when the combined weeks/days/time portions are considered. This is
  /// over 292 years, so unlikely to be a problem in normal usage.
  /// In some cases this may occur even though the theoretical result would be valid due to balancing positive and
  /// negative values, but for simplicity there is no attempt to work around this.
  /// Returns: The normalized period.
  /// <seealso cref="NormalizingEqualityComparer"/>
  Period Normalize() {
    // Simplest way to normalize: grab all the fields up to "week" and
    // sum them.
    int totalNanoseconds = TotalNanoseconds;
    int days = (totalNanoseconds ~/ TimeConstants.nanosecondsPerDay);

    int hours, minutes, seconds, milliseconds, nanoseconds;

    if (totalNanoseconds >= 0) {
      hours = (totalNanoseconds ~/ TimeConstants.nanosecondsPerHour) % TimeConstants.hoursPerDay;
      minutes = (totalNanoseconds ~/ TimeConstants.nanosecondsPerMinute) % TimeConstants.minutesPerHour;
      seconds = (totalNanoseconds ~/ TimeConstants.nanosecondsPerSecond) % TimeConstants.secondsPerMinute;
      milliseconds = (totalNanoseconds ~/ TimeConstants.nanosecondsPerMillisecond) % TimeConstants.millisecondsPerSecond;
      nanoseconds = totalNanoseconds % TimeConstants.nanosecondsPerMillisecond;
    }
    else {
      hours = csharpMod((totalNanoseconds ~/ TimeConstants.nanosecondsPerHour), TimeConstants.hoursPerDay);
      minutes = csharpMod((totalNanoseconds ~/ TimeConstants.nanosecondsPerMinute), TimeConstants.minutesPerHour);
      seconds = csharpMod((totalNanoseconds ~/ TimeConstants.nanosecondsPerSecond), TimeConstants.secondsPerMinute);
      milliseconds = csharpMod((totalNanoseconds ~/ TimeConstants.nanosecondsPerMillisecond), TimeConstants.millisecondsPerSecond);
      nanoseconds = csharpMod(totalNanoseconds, TimeConstants.nanosecondsPerMillisecond);
    }

    return new Period(Years: this.Years,
        Months: this.Months,
        Weeks: 0 /* weeks */,
        Days: days,
        Hours: hours,
        Minutes: minutes,
        Seconds: seconds,
        Milliseconds: milliseconds,
        Ticks: 0 /* ticks */,
        Nanoseconds: nanoseconds);
  }

  /// Returns this string formatted according to the [PeriodPattern.Roundtrip].
  ///
  /// Returns: A formatted representation of this period.
  @override String toString() => PeriodPattern.Roundtrip.Format(this);

  /// Returns the hash code for this period, consistent with [Equals(Period)].
  ///
  /// Returns: The hash code for this period.
  @override int get hashCode => hashObjects([Years, Months, Weeks, Days, Hours, Minutes, Seconds, Milliseconds, Ticks, Nanoseconds]);

  /// Compares the given period for equality with this one.
  ///
  /// Periods are equal if they contain the same values for the same properties.
  /// However, no normalization takes place, so "one hour" is not equal to "sixty minutes".
  ///
  /// [other]: The period to compare this one with.
  /// Returns: True if this period has the same values for the same properties as the one specified.
  bool Equals(Period other) =>
      other != null &&
          Years == other.Years &&
          Months == other.Months &&
          Weeks == other.Weeks &&
          Days == other.Days &&
          Hours == other.Hours &&
          Minutes == other.Minutes &&
          Seconds == other.Seconds &&
          Milliseconds == other.Milliseconds &&
          Ticks == other.Ticks &&
          Nanoseconds == other.Nanoseconds;

  bool operator==(dynamic other) => other is Period && Equals(other);
}

/// Equality comparer which simply normalizes periods before comparing them.
@private class NormalizingPeriodEqualityComparer // : EqualityComparer<Period>
    {
  @internal static final NormalizingPeriodEqualityComparer Instance = new NormalizingPeriodEqualityComparer();

  @private NormalizingPeriodEqualityComparer() {
  }

  @override bool Equals(Period x, Period y) {
    // todo: ReferenceEquals?
    if (identical(x, y)) {
      return true;
    }
    if (x == null || y == null) {
      return false;
    }
    return x.Normalize().Equals(y.Normalize());
  }

  @override int getHashCode(Period obj) =>
      Preconditions
          .checkNotNull(obj, 'obj')
          .Normalize()
          .hashCode;
}

// todo: implements Comparer
@private class PeriodComparer // implements Comparer<Period>
    {
  @private final LocalDateTime baseDateTime;

  @internal PeriodComparer(this.baseDateTime);

  @override int Compare(Period x, Period y) {
    if (identical(x, y)) {
      return 0;
    }
    if (x == null) {
      return -1;
    }
    if (y == null) {
      return 1;
    }
    if (x.Months == 0 && y.Months == 0 &&
        x.Years == 0 && y.Years == 0) {
      // Note: this *could* throw an OverflowException when the normal approach
      // wouldn't, but it's highly unlikely
      return x.ToSpan().compareTo(y.ToSpan());
    }
    return (baseDateTime.Plus(x)).compareTo(baseDateTime.Plus(y));
  }
}
