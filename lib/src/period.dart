// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
// import 'package:quiver_hashcode/hashcode.dart';
import 'package:time_machine/src/time_machine_internal.dart';

@immutable
class _DateComponentsBetweenResult {
// @private static LocalDate DateComponentsBetween(LocalDate start, LocalDate end, PeriodUnits units,
//     out int years, out int months, out int weeks, out int days)

  final LocalDate date;
  final int years;
  final int months;
  final int weeks;
  final int days;

  const _DateComponentsBetweenResult(this.date, this.years, this.months, this.weeks, this.days);
}

// @private static void TimeComponentsBetween(int totalNanoseconds, PeriodUnits units,
// out int hours, out int minutes, out int seconds, out int milliseconds, out int ticks, out int nanoseconds)
@immutable
class _TimeComponentsBetweenResult {
  final int hours;
  final int minutes;
  final int seconds;
  final int milliseconds;
  final int microseconds;
  final int nanoseconds;

  const _TimeComponentsBetweenResult(this.hours, this.minutes, this.seconds, this.milliseconds, this.microseconds, this.nanoseconds);
}

@internal
abstract class IPeriod {
  static int daysBetween(LocalDate start, LocalDate end) => Period._daysBetween(start, end);

  static Period period({int years = 0, int months = 0, int weeks = 0, int days = 0,
    int hours = 0, int minutes = 0, int seconds = 0,
    int milliseconds = 0, int microseconds = 0, int nanoseconds = 0}) =>
      Period(years: years, months: months, weeks: weeks, days: days, hours: hours, minutes: minutes, seconds: seconds,
          milliseconds: milliseconds, microseconds: microseconds, nanoseconds: nanoseconds);

  static LocalTime addTimeTo(Period period, LocalTime time, int scalar) => period._addTimeTo(time, scalar);

  static LocalDate addDateTo(Period period, LocalDate date, int scalar) => period._addDateTo(date, scalar);

  static LocalDateTime addDateTimeTo(Period period, LocalDate date, LocalTime time, int scalar) => period._addDateTimeTo(date, time, scalar);
}

/// Represents a period of time expressed in human chronological terms: hours, days,
/// weeks, months and so on.
///
/// A [Period] contains a set of properties such as [years], [months], and so on
/// that return the number of each unit contained within this period. Note that these properties are not normalized in
/// any way by default, and so a [Period] may contain values such as '2 hours and 90 minutes'. The
/// [normalize] method will convert equivalent periods into a standard representation.
///
/// Periods can contain negative units as well as positive units ('+2 hours, -43 minutes, +10 seconds'), but do not
/// differentiate between properties that are zero and those that are absent (i.e. a period created as '10 years'
/// and one created as '10 years, zero months' are equal periods; the [months] property returns zero in
/// both cases).
///
/// [Period] equality is implemented by comparing each property's values individually.
///
/// Periods operate on calendar-related types such as
/// [LocalDateTime] whereas [Time] operates on [Instant]s
/// on the time line. (Note that although [ZonedDateTime] includes both concepts, it only supports
/// [Time]-based arithmetic.)
@immutable
class Period {
  // General implementation note: operations such as normalization work out the total number of nanoseconds as an Int64
  // value. This can handle +/- 106,751 days, or 292 years. We could move to using BigInteger if we feel that's required,
  // but it's unlikely to be an issue. Ideally, we'd switch to use BigInteger after detecting that it could be a problem,
  // but without the hit of having to catch the exception...

  /// A period containing only zero-valued properties.
  static const Period zero = Period();


  /// Returns an equality comparer which compares periods by first normalizing them - so 24 hours is deemed equal to 1 day, and so on.
  /// Note that as per the [normalize] method, years and months are unchanged by normalization - so 12 months does not
  /// equal 1 year.
  // todo: what to do about this? .. was: IEqualityComparer
  static dynamic get NormalizingEqualityComparer => NormalizingPeriodEqualityComparer.instance;

  // The fields that make up this period.


  /// Gets the number of nanoseconds within this period.
  ///
  /// This property returns zero both when the property has been explicitly set to zero and when the period does not
  /// contain this property.
  final int nanoseconds;


  /// Gets the number of microseconds within this period.
  ///
  /// This property returns zero both when the property has been explicitly set to zero and when the period does not
  /// contain this property.
  final int microseconds;


  /// Gets the number of milliseconds within this period.
  ///
  /// This property returns zero both when the property has been explicitly set to zero and when the period does not
  /// contain this property.
  final int milliseconds;


  /// Gets the number of seconds within this period.
  ///
  /// This property returns zero both when the property has been explicitly set to zero and when the period does not
  /// contain this property.
  final int seconds;


  /// Gets the number of minutes within this period.
  ///
  /// This property returns zero both when the property has been explicitly set to zero and when the period does not
  /// contain this property.
  final int minutes;


  /// Gets the number of hours within this period.
  ///
  /// This property returns zero both when the property has been explicitly set to zero and when the period does not
  /// contain this property.
  final int hours;


  /// Gets the number of days within this period.
  ///
  /// This property returns zero both when the property has been explicitly set to zero and when the period does not
  /// contain this property.
  final int days;


  /// Gets the number of weeks within this period.
  ///
  /// This property returns zero both when the property has been explicitly set to zero and when the period does not
  /// contain this property.
  final int weeks;


  /// Gets the number of months within this period.
  ///
  /// This property returns zero both when the property has been explicitly set to zero and when the period does not
  /// contain this property.
  final int months;


  /// Gets the number of years within this period.
  ///
  /// This property returns zero both when the property has been explicitly set to zero and when the period does not
  /// contain this property.
  final int years;

  /// Creates a period with the given time values.
  const Period({this.years = 0, this.months = 0, this.weeks = 0, this.days = 0,
    this.hours = 0, this.minutes = 0, this.seconds = 0,
    this.milliseconds = 0, this.microseconds = 0, this.nanoseconds = 0});


  /// Adds two periods together, by simply adding the values for each property.
  ///
  /// * [this]: The first period to add
  /// * [other]: The second period to add
  ///
  /// The sum of the two periods. The units of the result will be the union of those in both
  /// periods.
  Period operator +(Period other) {
    Preconditions.checkNotNull(other, 'right');
    return Period(years: years + other.years,
        months: months + other.months,
        weeks: weeks + other.weeks,
        days: days + other.days,
        hours: hours + other.hours,
        minutes: minutes + other.minutes,
        seconds: seconds + other.seconds,
        milliseconds: milliseconds + other.milliseconds,
        microseconds: microseconds + other.microseconds,
        nanoseconds: nanoseconds + other.nanoseconds);
  }


  /// Creates an [Comparer] for periods, using the given 'base' local date/time.
  ///
  /// Certain periods can't naturally be compared without more context - how "one month" compares to
  /// '30 days' depends on where you start. In order to compare two periods, the returned comparer
  /// effectively adds both periods to the 'base' specified by [baseDateTime] and compares
  /// the results. In some cases this arithmetic isn't actually required - when two periods can be
  /// converted to durations, the comparer uses that conversion for efficiency.
  ///
  /// * [baseDateTime]: The base local date/time to use for comparisons.
  ///
  /// Returns: The new comparer.
  // todo: what to do abuot IComparer?
  // static IComparer<Period> CreateComparer(LocalDateTime baseDateTime) => new PeriodComparer(baseDateTime);
  static _PeriodComparer createComparer(LocalDateTime baseDateTime) => _PeriodComparer(baseDateTime);


  /// Subtracts one period from another, by simply subtracting each property value.
  ///
  /// * [this]: The period to subtract the second operand from
  /// * [other]: The period to subtract the first operand from
  ///
  /// The result of subtracting all the values in the second operand from the values in the first. The
  /// units of the result will be the union of both periods, even if the subtraction caused some properties to
  /// become zero (so '2 weeks, 1 days' minus "2 weeks" is "zero weeks, 1 days", not "1 days").
  Period operator -(Period other) {
    Preconditions.checkNotNull(other, 'other');
    return Period(
        years: years - other.years,
        months: months - other.months,
        weeks: weeks - other.weeks,
        days: days - other.days,
        hours: hours - other.hours,
        minutes: minutes - other.minutes,
        seconds: seconds - other.seconds,
        milliseconds: milliseconds - other.milliseconds,
        microseconds: microseconds - other.microseconds,
        nanoseconds: nanoseconds - other.nanoseconds);
  }

  /// Returns the exact difference between two date/times or
  /// returns the period between a start and an end date/time, using only the given units.
  ///
  /// If [end] is before [start], each property in the returned period
  /// will be negative. If the given set of units cannot exactly reach the end point (e.g. finding
  /// the difference between 1am and 3:15am in hours) the result will be such that adding it to [start]
  /// will give a value between [start] and [end]. In other words,
  /// any rounding is 'towards start'; this is true whether the resulting period is negative or positive.
  ///
  /// * [start]: Start date/time
  /// * [end]: End date/time
  /// * [units]: Units to use for calculations
  ///
  /// Returns: The period between the given date/times, using the given units.
  ///
  /// * [ArgumentError]: [units] is empty or contained unknown values.
  /// * [ArgumentError]: [start] and [end] use different calendars.
  static Period differenceBetweenDateTime(LocalDateTime start, LocalDateTime end, [PeriodUnits units = PeriodUnits.dateAndTime]) {
    Preconditions.checkArgument(units != PeriodUnits.none, 'units', "Units must not be empty");
    Preconditions.checkArgument((units.value & ~PeriodUnits.allUnits.value) == 0, 'units', "Units contains an unknown value: $units");
    CalendarSystem calendar = start.calendar;
    Preconditions.checkArgument(calendar == end.calendar, 'end', "start and end must use the same calendar system");

    if (start == end) {
      return zero;
    }

    // Adjust for situations like 'days between 5th January 10am and 7th Janary 5am' which should be one
    // day, because if we actually reach 7th January with date fields, we've overshot.
    // The date adjustment will always be valid, because it's just moving it towards start.
    // We need this for all date-based period fields. We could potentially optimize by not doing this
    // in cases where we've only got time fields...
    LocalDate endDate = end.calendarDate;
    if (start < end) {
      if (start.clockTime > end.clockTime) {
        endDate = endDate.addDays(-1);
      }
    }
    else if (start > end && start.clockTime < end.clockTime) {
      endDate = endDate.addDays(1);
    }

    // Optimization for single field
    // todo: optimize me?
    Map _betweenFunctionMap = {
      PeriodUnits.years:  () => Period(years: DatePeriodFields.yearsField.unitsBetween(start.calendarDate, endDate)),
      PeriodUnits.months: () => Period(months: DatePeriodFields.monthsField.unitsBetween(start.calendarDate, endDate)),
      PeriodUnits.weeks: () => Period(weeks: DatePeriodFields.weeksField.unitsBetween(start.calendarDate, endDate)),
      PeriodUnits.days: () => Period(days: _daysBetween(start.calendarDate, endDate)),
      PeriodUnits.hours: () => Period(hours: TimePeriodField.hours.unitsBetween(start, end)),
      PeriodUnits.minutes: () => Period(minutes: TimePeriodField.minutes.unitsBetween(start, end)),
      PeriodUnits.seconds: () => Period(seconds: TimePeriodField.seconds.unitsBetween(start, end)),
      PeriodUnits.milliseconds: () => Period(milliseconds: TimePeriodField.milliseconds.unitsBetween(start, end)),
      PeriodUnits.microseconds: () => Period(microseconds: TimePeriodField.microseconds.unitsBetween(start, end)),
      PeriodUnits.nanoseconds: () => Period(nanoseconds: TimePeriodField.nanoseconds.unitsBetween(start, end))
    };

    if (_betweenFunctionMap.containsKey(units)) return _betweenFunctionMap[units]();

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
      var result = _dateComponentsBetween(start.calendarDate, endDate, units);
      years = result.years;
      months = result.months;
      weeks = result.weeks;
      days = result.days;

      var remainingDate = result.date;
      remaining = LocalDateTime.localDateAtTime(remainingDate, start.clockTime);
    }
    if ((units.value & PeriodUnits.allTimeUnits.value) == 0) {
      return Period(years: years, months: months, weeks: weeks, days: days);
    }

    // The remainder of the computation is with fixed-length units, so we can do it all with
    // Duration instead of Local* values. We don't know for sure that this is small though - we *could*
    // be trying to find the difference between 9998 BC and 9999 CE in nanoseconds...
    // Where we can optimize, do everything with int arithmetic (as we do for Between(LocalTime, LocalTime)).
    // Otherwise (rare case), use duration arithmetic.
    int hours, minutes, seconds, milliseconds, microseconds, nanoseconds;
    var span = ILocalDateTime.toLocalInstant(end).timeSinceLocalEpoch
        - ILocalDateTime.toLocalInstant(remaining).timeSinceLocalEpoch;
    if (span.canNanosecondsBeInteger) {
      var result = _timeComponentsBetween(span.inNanoseconds, units);
      hours = result.hours;
      minutes = result.minutes;
      seconds = result.seconds;
      milliseconds = result.milliseconds;
      microseconds = result.microseconds;
      nanoseconds = result.nanoseconds;

      // TimeComponentsBetween(duration.ToInt64Nanoseconds(), units, out hours, out minutes, out seconds, out milliseconds, out ticks, out nanoseconds);
    }
    else {
      int unitsBetween(PeriodUnits mask, TimePeriodField timeField) {
        if ((mask.value & units.value) == 0) {
          return 0;
        }
        int value = timeField.getUnitsInDuration(span);
        span -= timeField.toSpan(value);
        return value;
      }

      hours = unitsBetween(PeriodUnits.hours, TimePeriodField.hours);
      minutes = unitsBetween(PeriodUnits.minutes, TimePeriodField.minutes);
      seconds = unitsBetween(PeriodUnits.seconds, TimePeriodField.seconds);
      milliseconds = unitsBetween(PeriodUnits.milliseconds, TimePeriodField.milliseconds);
      microseconds = unitsBetween(PeriodUnits.microseconds, TimePeriodField.microseconds);
      nanoseconds = unitsBetween(PeriodUnits.microseconds, TimePeriodField.nanoseconds);
    }

    return Period(years: years,
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


  /// Common code to perform the date parts of the Between methods.
  ///
  /// * [start]: Start date
  /// * [end]: End date
  /// * [units]: Units to compute
  /// * [years]: (Out) Year component of result
  /// * [months]: (Out) Months component of result
  /// * [weeks]: (Out) Weeks component of result
  /// * [days]: (Out) Days component of result
  ///
  /// The resulting date after adding the result components to [start] (to
  /// allow further computations to be made)
  static _DateComponentsBetweenResult _dateComponentsBetween(LocalDate start, LocalDate end, PeriodUnits units) {
    // var result = new OutBox(start);
    LocalDate startDate = start;

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
    int unitsBetween(int maskedUnits, /*OutBox<LocalDate> startDate,*/ IDatePeriodField dateField) {
      if (maskedUnits == 0) {
        return 0;
      }

      int value = dateField.unitsBetween(startDate, end);
      startDate = dateField.add(startDate, value);
      return value;
    }

    var years = unitsBetween(units.value & PeriodUnits.years.value, DatePeriodFields.yearsField);
    var months = unitsBetween(units.value & PeriodUnits.months.value, DatePeriodFields.monthsField);
    var weeks = unitsBetween(units.value & PeriodUnits.weeks.value, DatePeriodFields.weeksField);
    var days = unitsBetween(units.value & PeriodUnits.days.value, DatePeriodFields.daysField);

    return _DateComponentsBetweenResult(startDate, years, months, weeks, days);
  }


  /// Common code to perform the time parts of the Between methods for long-representable nanos.
  ///
  /// * [totalNanoseconds]: Number of nanoseconds to compute the units of
  /// * [units]: Units to compute
  /// * [hours]: (Out) Hours component of result
  /// * [minutes]: (Out) Minutes component of result
  /// * [seconds]: (Out) Seconds component of result
  /// * [milliseconds]: (Out) Milliseconds component of result
  /// * [ticks]: (Out) Ticks component of result
  /// * [nanoseconds]: (Out) Nanoseconds component of result
  static _TimeComponentsBetweenResult _timeComponentsBetween(int totalNanoseconds, PeriodUnits units) {
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
    var microseconds = UnitsBetween(PeriodUnits.microseconds, TimeConstants.nanosecondsPerMicrosecond);
    var nanoseconds = UnitsBetween(PeriodUnits.nanoseconds, 1);

    return _TimeComponentsBetweenResult(hours, minutes, seconds, milliseconds, microseconds, nanoseconds);
  }

// TODO(optimization): These three methods are only ever used with scalar values of 1 or -1. Unlikely that
// the multiplications are going to be relevant, but may be worth testing. (Easy enough to break out
// code for the two values separately.)


  /// Adds the time components of this period to the given time, scaled accordingly.
  LocalTime _addTimeTo(LocalTime time, int scalar) =>
      time.addHours(hours * scalar)
          .addMinutes(minutes * scalar)
          .addSeconds(seconds * scalar)
          .addMilliseconds(milliseconds * scalar)
          .addMicroseconds(microseconds * scalar)
          .addNanoseconds(nanoseconds * scalar);


  /// Adds the date components of this period to the given time, scaled accordingly.
  LocalDate _addDateTo(LocalDate date, int scalar) =>
      date.addYears(years * scalar)
          .addMonths(months * scalar)
          .addWeeks(weeks * scalar)
          .addDays(days * scalar);


  /// Adds the contents of this period to the given date and time, with the given scale (either 1 or -1, usually).
  LocalDateTime _addDateTimeTo(LocalDate date, LocalTime time, int scalar) {
    date = _addDateTo(date, scalar);

    var calc = AddTimeCalc(time, 0);
    calc.addTimeAndDays(TimePeriodField.hours, hours*scalar);
    calc.addTimeAndDays(TimePeriodField.minutes, minutes*scalar);
    calc.addTimeAndDays(TimePeriodField.seconds, seconds*scalar);
    calc.addTimeAndDays(TimePeriodField.milliseconds, milliseconds*scalar);
    calc.addTimeAndDays(TimePeriodField.microseconds, microseconds*scalar);
    calc.addTimeAndDays(TimePeriodField.nanoseconds, nanoseconds*scalar);

    // TODO(optimization): Investigate the performance impact of us calling PlusDays twice.
    // Could optimize by including that in a single call...
    return LocalDateTime.localDateAtTime(date.addDays(calc.extraDays), calc.localTime);
  }

  static final Map<PeriodUnits, Period Function(LocalDate, LocalDate)> _functionMapBetweenDates = {
    PeriodUnits.years: (start, end) => Period(years: DatePeriodFields.yearsField.unitsBetween(start, end)),
    PeriodUnits.months: (start, end) => Period(months: DatePeriodFields.monthsField.unitsBetween(start, end)),
    PeriodUnits.weeks: (start, end) => Period(weeks: DatePeriodFields.weeksField.unitsBetween(start, end)),
    PeriodUnits.days: (start, end) => Period(days: _daysBetween(start, end))
  };

  /// Returns the exact difference between two dates or returns the period between a start and an end date, using only the given units.
  ///
  /// If [end] is before <paramref name='start' />, each property in the returned period
  /// will be negative. If the given set of units cannot exactly reach the end point (e.g. finding
  /// the difference between 12th February and 15th March in months) the result will be such that adding it to [start]
  /// will give a value between [start] and [end]. In other words,
  /// any rounding is 'towards start'; this is true whether the resulting period is negative or positive.
  ///
  /// * [start]: Start date
  /// * [end]: End date
  /// * [units]: Units to use for calculations
  ///
  /// Returns: The period between the given dates, using the given units.
  ///
  /// * [ArgumentError]: [units] contains time units, is empty or contains unknown values.
  /// * [ArgumentError]: [start] and [end] use different calendars.
  static Period differenceBetweenDates(LocalDate start, LocalDate end, [PeriodUnits units = PeriodUnits.yearMonthDay]) {
    Preconditions.checkArgument((units.value & PeriodUnits.allTimeUnits.value) == 0, 'units', "Units contains time units: $units");
    Preconditions.checkArgument(units.value != 0, 'units', "Units must not be empty");
    Preconditions.checkArgument((units.value & ~PeriodUnits.allUnits.value) == 0, 'units', "Units contains an unknown value: $units");
    CalendarSystem calendar = start.calendar;
    Preconditions.checkArgument(calendar == end.calendar, 'end', "start and end must use the same calendar system");

    if (start == end) {
      return zero;
    }

    // Optimization for single field
    var singleFieldFunction = _functionMapBetweenDates[units];
    if (singleFieldFunction != null) return singleFieldFunction(start, end);

    // Multiple fields todo: if these result_type functions are just used to make periods, we can simply them
    var result = _dateComponentsBetween(start, end, units);
    return Period(years: result.years, months: result.months, weeks: result.weeks, days: result.days);
  }

  static final Map<PeriodUnits, Period Function(int)> _functionMapBetweenTimes = {
    PeriodUnits.hours: (remaining) => Period(hours: remaining ~/ TimeConstants.nanosecondsPerHour),
    PeriodUnits.minutes: (remaining) => Period(minutes: remaining ~/ TimeConstants.nanosecondsPerMinute),
    PeriodUnits.seconds: (remaining) => Period(seconds: remaining ~/ TimeConstants.nanosecondsPerSecond),
    PeriodUnits.milliseconds: (remaining) => Period(milliseconds: remaining ~/ TimeConstants.nanosecondsPerMillisecond),
    PeriodUnits.microseconds: (remaining) => Period(microseconds: remaining ~/ TimeConstants.nanosecondsPerMicrosecond),
    PeriodUnits.nanoseconds: (remaining) => Period(nanoseconds: remaining)
  };

  /// Returns the exact difference between two times or returns the period between a start and an end time, using only the given units.
  ///
  /// If [end] is before <paramref name='start' />, each property in the returned period
  /// will be negative. If the given set of units cannot exactly reach the end point (e.g. finding
  /// the difference between 3am and 4.30am in hours) the result will be such that adding it to [start]
  /// will give a value between [start] and [end]. In other words,
  /// any rounding is 'towards start'; this is true whether the resulting period is negative or positive.
  ///
  /// * [start]: Start time
  /// * [end]: End time
  /// * [units]: Units to use for calculations
  ///
  /// Returns: The period between the given times, using the given units.
  ///
  /// * [ArgumentError]: [units] contains date units, is empty or contains unknown values.
  /// * [ArgumentError]: [start] and [end] use different calendars.
  static Period differenceBetweenTimes(LocalTime start, LocalTime end, [PeriodUnits units = PeriodUnits.allTimeUnits]) {
    Preconditions.checkArgument((units.value & PeriodUnits.allDateUnits.value) == 0, 'units', "Units contains date units: $units");
    Preconditions.checkArgument(units.value != 0, 'units', "Units must not be empty");
    Preconditions.checkArgument((units.value & ~PeriodUnits.allUnits.value) == 0, 'units', "Units contains an unknown value: $units");

    // We know that the difference is in the range of +/- 1 day, which is a relatively small
    // number of nanoseconds. All the operations can be done with simple int division/remainder ops,
    // so we don't need to delegate to TimePeriodField.
    int remaining = (end.timeSinceMidnight.inNanoseconds - start.timeSinceMidnight.inNanoseconds);

    // Optimization for a single unit
    var singleFieldFunction = _functionMapBetweenTimes[units];
    if (singleFieldFunction != null) return singleFieldFunction(remaining);

    var result = _timeComponentsBetween(remaining, units);
    return Period(hours: result.hours,
        minutes: result.minutes,
        seconds: result.seconds,
        milliseconds: result.milliseconds,
        microseconds: result.microseconds,
        nanoseconds: result.nanoseconds);
  }

  /// Returns the number of days between two dates. This allows optimizations in DateInterval,
  /// and for date calculations which just use days - we don't need state or a virtual method invocation.
  static int _daysBetween(LocalDate start, LocalDate end) {
    // We already assume the calendars are the same.
    if (ILocalDate.yearMonthDay(start) == ILocalDate.yearMonthDay(end)) {
      return 0;
    }
    // Note: I've experimented with checking for the dates being in the same year and optimizing that.
    // It helps a little if they're in the same month, but just that test has a cost for other situations.
    // Being able to find the day of year if they're in the same year but different months doesn't help,
    // somewhat surprisingly.
    int startDays = start.epochDay;
    int endDays = end.epochDay;
    return endDays - startDays;
  }

  /// Returns whether or not this period contains any non-zero-valued time-based properties (hours or lower).
  bool get hasTimeComponent => hours != 0 || minutes != 0 || seconds != 0 || milliseconds != 0 || microseconds != 0 || nanoseconds != 0;

  /// Returns whether or not this period contains any non-zero date-based properties (days or higher).
  bool get hasDateComponent => years != 0 || months != 0 || weeks != 0 || days != 0;

  // todo: verify Overflow

  /// For periods that do not contain a non-zero number of years or months, returns a duration for this period
  /// assuming a standard 7-day week, 24-hour day, 60-minute hour etc.
  ///
  /// Returns: The duration of the period.
  ///
  /// * [StateError]: The month or year property in the period is non-zero.
  /// * [OverflowException]: The period doesn't have years or months, but the calculation
  /// overflows the bounds of [Time]. In some cases this may occur even though the theoretical
  /// result would be valid due to balancing positive and negative values, but for simplicity there is
  /// no attempt to work around this - in realistic periods, it shouldn't be a problem.
  Time toTime() {
    if (months != 0 || years != 0) {
      // we can't do this because months and years have undefined amounts of times.
      throw StateError('Cannot construct span of period with non-zero months or years.');
    }
    return Time(nanoseconds: _totalNanoseconds);
  }

  /// Gets the total number of nanoseconds duration for the 'standard' properties (all bar years and months).
  int get _totalNanoseconds =>
      nanoseconds +
          microseconds * TimeConstants.nanosecondsPerMicrosecond +
          milliseconds * TimeConstants.nanosecondsPerMillisecond +
          seconds * TimeConstants.nanosecondsPerSecond +
          minutes * TimeConstants.nanosecondsPerMinute +
          hours * TimeConstants.nanosecondsPerHour +
          days * TimeConstants.nanosecondsPerDay +
          weeks * TimeConstants.nanosecondsPerWeek;

  /// Creates a [PeriodBuilder] from this instance. The new builder
  /// is populated with the values from this period, but is then detached from it:
  /// changes made to the builder are not reflected in this period.
  ///
  /// Returns: A builder with the same values and units as this period.
  PeriodBuilder toBuilder() => PeriodBuilder(this);

  /// Returns a normalized version of this period, such that equivalent (but potentially non-equal) periods are
  /// changed to the same representation.
  ///
  /// Months and years are unchanged
  /// (as they can vary in length), but weeks are multiplied by 7 and added to the
  /// Days property, and all time properties are normalized to their natural range.
  /// Subsecond values are normalized to millisecond and 'nanosecond within millisecond' values.
  /// So for example, a period of 25 hours becomes a period of 1 day
  /// and 1 hour. A period of 1,500,750,000 nanoseconds becomes 1 second, 500 milliseconds and
  /// 750,000 nanoseconds. Aside from months and years, either all the properties
  /// end up positive, or they all end up negative. 'Week' and "tick" units in the returned period are always 0.
  ///
  /// [OverflowException]: The period doesn't have years or months, but it contains more than
  /// `Int.maxValue` nanoseconds when the combined weeks/days/time portions are considered. This is
  /// over 292 years, so unlikely to be a problem in normal usage.
  /// In some cases this may occur even though the theoretical result would be valid due to balancing positive and
  /// negative values, but for simplicity there is no attempt to work around this.
  ///
  /// Returns: The normalized period.
  ///
  /// see: [NormalizingEqualityComparer]
  Period normalize() {
    // Simplest way to normalize: grab all the fields up to 'week' and
    // sum them.
    int totalNanoseconds = _totalNanoseconds;
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
      hours = arithmeticMod((totalNanoseconds ~/ TimeConstants.nanosecondsPerHour), TimeConstants.hoursPerDay);
      minutes = arithmeticMod((totalNanoseconds ~/ TimeConstants.nanosecondsPerMinute), TimeConstants.minutesPerHour);
      seconds = arithmeticMod((totalNanoseconds ~/ TimeConstants.nanosecondsPerSecond), TimeConstants.secondsPerMinute);
      milliseconds = arithmeticMod((totalNanoseconds ~/ TimeConstants.nanosecondsPerMillisecond), TimeConstants.millisecondsPerSecond);
      nanoseconds = arithmeticMod(totalNanoseconds, TimeConstants.nanosecondsPerMillisecond);
    }

    return Period(years: years,
        months: months,
        weeks: 0 /* weeks */,
        days: days,
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
        microseconds: 0 /* ticks */,
        nanoseconds: nanoseconds);
  }

  /// Returns this string formatted according to the [PeriodPattern.roundtrip].
  @override String toString() => PeriodPattern.roundtrip.format(this);

  /// Returns the hash code for this period.
  @override int get hashCode => hashObjects([years, months, weeks, days, hours, minutes, seconds, milliseconds, microseconds, nanoseconds]);

  /// Compares the given period for equality with this one.
  ///
  /// Periods are equal if they contain the same values for the same properties.
  /// However, no normalization takes place, so 'one hour' is not equal to "sixty minutes".
  ///
  /// [other]: The period to compare this one with.
  /// Returns: True if this period has the same values for the same properties as the one specified.
  bool equals(Period other) =>
          years == other.years &&
          months == other.months &&
          weeks == other.weeks &&
          days == other.days &&
          hours == other.hours &&
          minutes == other.minutes &&
          seconds == other.seconds &&
          milliseconds == other.milliseconds &&
          microseconds == other.microseconds &&
          nanoseconds == other.nanoseconds;

  @override
  bool operator==(Object other) => other is Period && equals(other);
}

// todo: why is this private, it's used in period_tests?
/// Equality comparer which simply normalizes periods before comparing them.
@private class NormalizingPeriodEqualityComparer {
  @internal static final NormalizingPeriodEqualityComparer instance = NormalizingPeriodEqualityComparer._();

  NormalizingPeriodEqualityComparer._();

  bool equals(Period x, Period y) {
    if (identical(x, y)) {
      return true;
    }
    return x.normalize().equals(y.normalize());
  }

  int getHashCode(Period obj) =>
      Preconditions
          .checkNotNull(obj, 'obj')
          .normalize()
          .hashCode;
}

// todo: implements Comparer
class _PeriodComparer // implements Comparer<Period>
    {
  final LocalDateTime _baseDateTime;

  _PeriodComparer(this._baseDateTime);

  int compare(Period? x, Period? y) {
    if (identical(x, y)) {
      return 0;
    }
    if (x == null) {
      return -1;
    }
    if (y == null) {
      return 1;
    }
    if (x.months == 0 && y.months == 0 &&
        x.years == 0 && y.years == 0) {
      // Note: this *could* throw an OverflowException when the normal approach
      // wouldn't, but it's highly unlikely
      return x.toTime().compareTo(y.toTime());
    }
    return (_baseDateTime.add(x)).compareTo(_baseDateTime.add(y));
  }
}
