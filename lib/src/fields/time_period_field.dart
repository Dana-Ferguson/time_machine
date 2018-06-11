// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

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

/// Period field class representing a field with a fixed duration regardless of when it occurs.
///
/// 2014-06-29: Tried optimizing time period calculations by making these static methods accepting
/// the number of ticks. I'd expected that to be really significant, given that it would avoid
/// finding the object etc. It turned out to make about 10% difference, at the cost of quite a bit
/// of code elegance.
@internal /*sealed*/ class TimePeriodField
{
  @internal static final TimePeriodField nanoseconds = new TimePeriodField(1);
  @internal static final TimePeriodField ticks = new TimePeriodField(TimeConstants.nanosecondsPerTick);
  @internal static final TimePeriodField milliseconds = new TimePeriodField(TimeConstants.nanosecondsPerMillisecond);
  @internal static final TimePeriodField seconds = new TimePeriodField(TimeConstants.nanosecondsPerSecond);
  @internal static final TimePeriodField minutes = new TimePeriodField(TimeConstants.nanosecondsPerMinute);
  @internal static final TimePeriodField hours = new TimePeriodField(TimeConstants.nanosecondsPerHour);

  @private final int unitNanoseconds;
  // The largest number of units (positive or negative) we can multiply unitNanoseconds by without overflowing a long.
  @private final int maxLongUnits;
  @private final int unitsPerDay;

  @private TimePeriodField(this.unitNanoseconds) :
        maxLongUnits = Utility.intMaxValue ~/ unitNanoseconds,
        unitsPerDay = TimeConstants.nanosecondsPerDay ~/ unitNanoseconds;

  @internal LocalDateTime addDateTime(LocalDateTime start, int units)
  {
    // int extraDays = 0;
    var addTimeResult = addTime(start.time, units, 0);
    // Even though PlusDays optimizes for "value == 0", it's still quicker not to call it.
    LocalDate date = addTimeResult.extraDays == 0 ? start.date :  start.date.plusDays(addTimeResult.extraDays);
    return new LocalDateTime(date, addTimeResult.time);
  }

  // todo: is this actually used anywhere?
  @internal LocalTime addTimeSimple(LocalTime localTime, int value)
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
        int newNanos = localTime.nanosecondOfDay + nanosToAdd;
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
          value = -(-value % unitsPerDay);
        }
        int nanosToAdd = value * unitNanoseconds;
        int newNanos = localTime.nanosecondOfDay + nanosToAdd;
        if (newNanos < 0)
        {
          newNanos += TimeConstants.nanosecondsPerDay;
        }
        return new LocalTime.fromNanoseconds(newNanos);
      }
    }
  }

  @internal _AddTimeResult addTime(LocalTime localTime, int value, /*ref*/ int extraDays) {
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
        int newNanos = localTime.nanosecondOfDay + nanosToAdd;
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
          value = -(-value % unitsPerDay);
        }
        int nanosToAdd = value * unitNanoseconds;
        int newNanos = localTime.nanosecondOfDay + nanosToAdd;
        if (newNanos < 0) {
          newNanos += TimeConstants.nanosecondsPerDay;
          days = /*checked*/(days - 1);
        }
        extraDays = /*checked*/(days + extraDays);
        return new _AddTimeResult(new LocalTime.fromNanoseconds(newNanos), extraDays);
      }
    }
  }

  @internal int unitsBetween(LocalDateTime start, LocalDateTime end)
  {
    LocalInstant startLocalInstant = start.toLocalInstant();
    LocalInstant endLocalInstant = end.toLocalInstant();
    Span span = endLocalInstant.TimeSinceLocalEpoch - startLocalInstant.TimeSinceLocalEpoch;
    return getUnitsInDuration(span);
  }

  // todo: inspect the use cases here -- this might need special logic (if Span is always under 100 days, it's fine)
  /// Returns the number of units in the given duration, rounding towards zero.
  @internal int getUnitsInDuration(Span span) => span.totalNanoseconds ~/ unitNanoseconds;
//      span.IsInt64Representable
//          ? span.ToInt64Nanoseconds() / unitNanoseconds
//          : (span.ToDecimalNanoseconds() / unitNanoseconds);

  /// Returns a [Span] representing the given number of units.
  @internal Span toSpan(int units) =>
      units >= -maxLongUnits && units <= maxLongUnits
          ? new Span(nanoseconds: units * unitNanoseconds)
          : new Span(nanoseconds: units * /*(decimal)*/unitNanoseconds);
}
