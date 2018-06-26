// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';

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
@immutable
@internal
class TimePeriodField
{
  static final TimePeriodField nanoseconds = new TimePeriodField._(1);
  static final TimePeriodField ticks = new TimePeriodField._(TimeConstants.nanosecondsPerTick);
  static final TimePeriodField milliseconds = new TimePeriodField._(TimeConstants.nanosecondsPerMillisecond);
  static final TimePeriodField seconds = new TimePeriodField._(TimeConstants.nanosecondsPerSecond);
  static final TimePeriodField minutes = new TimePeriodField._(TimeConstants.nanosecondsPerMinute);
  static final TimePeriodField hours = new TimePeriodField._(TimeConstants.nanosecondsPerHour);

  final int _unitNanoseconds;
  // The largest number of units (positive or negative) we can multiply unitNanoseconds by without overflowing a long.
  final int _maxLongUnits;
  final int _unitsPerDay;

  TimePeriodField._(this._unitNanoseconds) :
        _maxLongUnits = Utility.intMaxValue ~/ _unitNanoseconds,
        _unitsPerDay = TimeConstants.nanosecondsPerDay ~/ _unitNanoseconds;

  LocalDateTime addDateTime(LocalDateTime start, int units)
  {
    // int extraDays = 0;
    var addTimeResult = addTime(start.time, units, 0);
    // Even though PlusDays optimizes for "value == 0", it's still quicker not to call it.
    LocalDate date = addTimeResult.extraDays == 0 ? start.date :  start.date.plusDays(addTimeResult.extraDays);
    return new LocalDateTime(date, addTimeResult.time);
  }

  // todo: is this actually used anywhere? rename
  LocalTime addTimeSimple(LocalTime localTime, int value)
  {
    // unchecked
    {
      // Arithmetic with a LocalTime wraps round, and every unit divides exactly
      // into a day, so we can make sure we add a value which is less than a day.
      if (value >= 0)
      {
        if (value >= _unitsPerDay)
        {
          value = value % _unitsPerDay;
        }
        int nanosToAdd = value * _unitNanoseconds;
        int newNanos = localTime.nanosecondOfDay + nanosToAdd;
        if (newNanos >= TimeConstants.nanosecondsPerDay)
        {
          newNanos -= TimeConstants.nanosecondsPerDay;
        }
        return ILocalTime.fromNanoseconds(newNanos);
      }
      else
      {
        if (value <= -_unitsPerDay)
        {
          value = -(-value % _unitsPerDay);
        }
        int nanosToAdd = value * _unitNanoseconds;
        int newNanos = localTime.nanosecondOfDay + nanosToAdd;
        if (newNanos < 0)
        {
          newNanos += TimeConstants.nanosecondsPerDay;
        }
        return ILocalTime.fromNanoseconds(newNanos);
      }
    }
  }

  _AddTimeResult addTime(LocalTime localTime, int value, /*ref*/ int extraDays) {
    // if (extraDays == null) return AddTimeSimple(localTime, value);

    // unchecked
    {
      if (value == 0) {
        return new _AddTimeResult(localTime, extraDays);
      }
      int days = 0;
      // It's possible that there are better ways to do this, but this at least feels simple.
      if (value >= 0) {
        if (value >= _unitsPerDay) {
          int longDays = value ~/ _unitsPerDay;
          // If this overflows, that's fine. (An OverflowException is a reasonable outcome.)
          days = /*checked*/ (longDays);
          value = value % _unitsPerDay;
        }
        int nanosToAdd = value * _unitNanoseconds;
        int newNanos = localTime.nanosecondOfDay + nanosToAdd;
        if (newNanos >= TimeConstants.nanosecondsPerDay) {
          newNanos -= TimeConstants.nanosecondsPerDay;
          days = /*checked*/(days + 1);
        }
        extraDays = /*checked*/(extraDays + days);
        return new _AddTimeResult(ILocalTime.fromNanoseconds(newNanos), extraDays);
      }
      else {
        if (value <= -_unitsPerDay) {
          int longDays = value ~/ _unitsPerDay;
          // If this overflows, that's fine. (An OverflowException is a reasonable outcome.)
          days = /*checked*/(longDays);
          value = -(-value % _unitsPerDay);
        }
        int nanosToAdd = value * _unitNanoseconds;
        int newNanos = localTime.nanosecondOfDay + nanosToAdd;
        if (newNanos < 0) {
          newNanos += TimeConstants.nanosecondsPerDay;
          days = /*checked*/(days - 1);
        }
        extraDays = /*checked*/(days + extraDays);
        return new _AddTimeResult(ILocalTime.fromNanoseconds(newNanos), extraDays);
      }
    }
  }

  int unitsBetween(LocalDateTime start, LocalDateTime end)
  {
    LocalInstant startLocalInstant = start.toLocalInstant();
    LocalInstant endLocalInstant = end.toLocalInstant();
    Span span = endLocalInstant.timeSinceLocalEpoch - startLocalInstant.timeSinceLocalEpoch;
    return getUnitsInDuration(span);
  }

  // todo: inspect the use cases here -- this might need special logic (if Span is always under 100 days, it's fine)
  /// Returns the number of units in the given duration, rounding towards zero.
  int getUnitsInDuration(Span span) => span.totalNanoseconds ~/ _unitNanoseconds;
//      span.IsInt64Representable
//          ? span.ToInt64Nanoseconds() / unitNanoseconds
//          : (span.ToDecimalNanoseconds() / unitNanoseconds);

  /// Returns a [Span] representing the given number of units.
  Span toSpan(int units) =>
      units >= -_maxLongUnits && units <= _maxLongUnits
          ? new Span(nanoseconds: units * _unitNanoseconds)
          : new Span(nanoseconds: units * /*(decimal)*/_unitNanoseconds);
}
