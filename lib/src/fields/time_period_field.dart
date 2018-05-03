// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Fields/TimePeriodField.cs
// 6b4af41  on Jun 10, 2017

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_fields.dart';

class _AddTimeResult {
  final LocalTime time;
  final int extraDays;

  _AddTimeResult(this.time, this.extraDays);
}

/// <summary>
/// Period field class representing a field with a fixed duration regardless of when it occurs.
/// </summary>
/// <remarks>
/// 2014-06-29: Tried optimizing time period calculations by making these static methods accepting
/// the number of ticks. I'd expected that to be really significant, given that it would avoid
/// finding the object etc. It turned out to make about 10% difference, at the cost of quite a bit
/// of code elegance.
/// </remarks>
@internal /*sealed*/ class TimePeriodField
{
  @internal static final TimePeriodField Nanoseconds = new TimePeriodField(1);
  @internal static final TimePeriodField Ticks = new TimePeriodField(TimeConstants.nanosecondsPerTick);
  @internal static final TimePeriodField Milliseconds = new TimePeriodField(TimeConstants.nanosecondsPerMillisecond);
  @internal static final TimePeriodField Seconds = new TimePeriodField(TimeConstants.nanosecondsPerSecond);
  @internal static final TimePeriodField Minutes = new TimePeriodField(TimeConstants.nanosecondsPerMinute);
  @internal static final TimePeriodField Hours = new TimePeriodField(TimeConstants.nanosecondsPerHour);

  @private final int unitNanoseconds;
  // The largest number of units (positive or negative) we can multiply unitNanoseconds by without overflowing a long.
  @private final int maxLongUnits;
  @private final int unitsPerDay;

  // TODO: THIS APPEARS TO ABUSE UNCHECKED BEHAVIOR TO ROLLAROUND -- THIS WILL NOT WORK FOR US AT ALL
  @private TimePeriodField(this.unitNanoseconds) :
        maxLongUnits = Utility.intMaxValue ~/ unitNanoseconds,
        unitsPerDay = TimeConstants.nanosecondsPerDay ~/ unitNanoseconds;

  @internal LocalDateTime AddDateTime(LocalDateTime start, int units)
  {
    // int extraDays = 0;
    var addTimeResult = AddTime(start.TimeOfDay, units, 0);
    // Even though PlusDays optimizes for "value == 0", it's still quicker not to call it.
    LocalDate date = addTimeResult.extraDays == 0 ? start.Date :  start.Date.PlusDays(addTimeResult.extraDays);
    return new LocalDateTime(date, addTimeResult.time);
  }

  // todo: is this actually used anywhere?
  @internal LocalTime AddTimeSimple(LocalTime localTime, int value)
  {
    // unchecked
    {
      // Arithmetic with a LocalTime wraps round, and every unit divides exactly
      // into a day, so we can make sure we add a value which is less than a day.
      if (value >= 0)
      {
        if (value >= unitsPerDay)
        {
          value = value % unitsPerDay;
        }
        int nanosToAdd = value * unitNanoseconds;
        int newNanos = localTime.NanosecondOfDay + nanosToAdd;
        if (newNanos >= TimeConstants.nanosecondsPerDay)
        {
          newNanos -= TimeConstants.nanosecondsPerDay;
        }
        return new LocalTime.fromNanoseconds(newNanos);
      }
      else
      {
        if (value <= -unitsPerDay)
        {
          value = -value % unitsPerDay * -1;
        }
        int nanosToAdd = value * unitNanoseconds;
        int newNanos = localTime.NanosecondOfDay + nanosToAdd;
        if (newNanos < 0)
        {
          newNanos += TimeConstants.nanosecondsPerDay;
        }
        return new LocalTime.fromNanoseconds(newNanos);
      }
    }
  }

  @internal _AddTimeResult AddTime(LocalTime localTime, int value, /*ref*/ int extraDays) {
    // if (extraDays == null) return AddTimeSimple(localTime, value);

    // unchecked
    {
      if (value == 0) {
        return new _AddTimeResult(localTime, extraDays);
      }
      int days = 0;
      // It's possible that there are better ways to do this, but this at least feels simple.
      if (value >= 0) {
        if (value >= unitsPerDay) {
          int longDays = value ~/ unitsPerDay;
          // If this overflows, that's fine. (An OverflowException is a reasonable outcome.)
          days = /*checked*/ (longDays);
          value = value % unitsPerDay;
        }
        int nanosToAdd = value * unitNanoseconds;
        int newNanos = localTime.NanosecondOfDay + nanosToAdd;
        if (newNanos >= TimeConstants.nanosecondsPerDay) {
          newNanos -= TimeConstants.nanosecondsPerDay;
          days = /*checked*/(days + 1);
        }
        extraDays = /*checked*/(extraDays + days);
        return new _AddTimeResult(new LocalTime.fromNanoseconds(newNanos), extraDays);
      }
      else {
        if (value <= -unitsPerDay) {
          int longDays = value ~/ unitsPerDay;
          // If this overflows, that's fine. (An OverflowException is a reasonable outcome.)
          days = /*checked*/(longDays);
          value = -value % unitsPerDay * -1; //value.sign;
        }
        int nanosToAdd = value * unitNanoseconds;
        int newNanos = localTime.NanosecondOfDay + nanosToAdd;
        if (newNanos < 0) {
          newNanos += TimeConstants.nanosecondsPerDay;
          days = /*checked*/(days - 1);
        }
        extraDays = /*checked*/(days + extraDays);
        return new _AddTimeResult(new LocalTime.fromNanoseconds(newNanos), extraDays);
      }
    }
  }

  @internal int UnitsBetween(LocalDateTime start, LocalDateTime end)
  {
    LocalInstant startLocalInstant = start.ToLocalInstant();
    LocalInstant endLocalInstant = end.ToLocalInstant();
    Span span = endLocalInstant.TimeSinceLocalEpoch - startLocalInstant.TimeSinceLocalEpoch;
    return GetUnitsInDuration(span);
  }

  // todo: inspect the use cases here -- this might need special logic (if Span is always under 100 days, it's fine)
  /// Returns the number of units in the given duration, rounding towards zero.
  @internal int GetUnitsInDuration(Span span) => span.totalNanoseconds ~/ unitNanoseconds;
//      span.IsInt64Representable
//          ? span.ToInt64Nanoseconds() / unitNanoseconds
//          : (span.ToDecimalNanoseconds() / unitNanoseconds);

  /// <summary>
  /// Returns a <see cref="Duration"/> representing the given number of units.
  /// </summary>
  @internal Span ToDuration(int units) =>
      units >= -maxLongUnits && units <= maxLongUnits
          ? new Span(nanoseconds: units * unitNanoseconds)
          : new Span(nanoseconds: units * /*(decimal)*/unitNanoseconds);
}