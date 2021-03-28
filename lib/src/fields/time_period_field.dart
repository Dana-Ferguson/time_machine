// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';

class AddTimeCalc {
  LocalTime localTime;
  int extraDays;

  AddTimeCalc(this.localTime, this.extraDays);

  void addTimeAndDays(TimePeriodField field, int value) {
    // if (extraDays == null) return AddTimeSimple(localTime, value);

    if (value == 0) return;

    int days = 0;
    // It's possible that there are better ways to do this, but this at least feels simple.
    if (value >= 0) {
      if (value >= field._unitsPerDay) {
        int longDays = value ~/ field._unitsPerDay;
        // If this overflows, that's fine. (An OverflowException is a reasonable outcome.)
        days = longDays;
        value = value % field._unitsPerDay;
      }
      int nanosToAdd = value * field._unitNanoseconds;
      int newNanos = localTime.timeSinceMidnight.inNanoseconds + nanosToAdd;
      if (newNanos >= TimeConstants.nanosecondsPerDay) {
        newNanos -= TimeConstants.nanosecondsPerDay;
        days = (days + 1);
      }
      extraDays += days;
      localTime = ILocalTime.trustedNanoseconds(newNanos);
    }
    else {
      if (value <= -field._unitsPerDay) {
        int longDays = value ~/ field._unitsPerDay;
        // If this overflows, that's fine. (An OverflowException is a reasonable outcome.)
        days = longDays;
        value = -(-value % field._unitsPerDay);
      }
      int nanosToAdd = value * field._unitNanoseconds;
      int newNanos = localTime.timeSinceMidnight.inNanoseconds + nanosToAdd;
      if (newNanos < 0) {
        newNanos += TimeConstants.nanosecondsPerDay;
        days = days - 1;
      }
      extraDays += days;
      localTime = ILocalTime.trustedNanoseconds(newNanos);
    }
  }
}

/// Period field class representing a field with a fixed duration regardless of when it occurs.
///
/// NodaTime: 2014-06-29: Tried optimizing time period calculations by making these static methods accepting
/// the number of ticks. I'd expected that to be really significant, given that it would avoid
/// finding the object etc. It turned out to make about 10% difference, at the cost of quite a bit
/// of code elegance.
@immutable
@internal
class TimePeriodField
{
  static final TimePeriodField nanoseconds = TimePeriodField._(1);
  static final TimePeriodField microseconds = TimePeriodField._(TimeConstants.nanosecondsPerMicrosecond);
  static final TimePeriodField milliseconds = TimePeriodField._(TimeConstants.nanosecondsPerMillisecond);
  static final TimePeriodField seconds = TimePeriodField._(TimeConstants.nanosecondsPerSecond);
  static final TimePeriodField minutes = TimePeriodField._(TimeConstants.nanosecondsPerMinute);
  static final TimePeriodField hours = TimePeriodField._(TimeConstants.nanosecondsPerHour);

  final int _unitNanoseconds;
  // The largest number of units (positive or negative) we can multiply unitNanoseconds by without overflowing a long.
  final int _maxLongUnits;
  final int _unitsPerDay;

  TimePeriodField._(this._unitNanoseconds) :
        _maxLongUnits = Platform.intMaxValue ~/ _unitNanoseconds,
        _unitsPerDay = TimeConstants.nanosecondsPerDay ~/ _unitNanoseconds;

  LocalDateTime addDateTime(LocalDateTime start, int units)
  {
    var calc = AddTimeCalc(start.clockTime, 0);
    calc.addTimeAndDays(this, units);

    // Even though PlusDays optimizes for 'value == 0', it's still quicker not to call it.
    LocalDate date = calc.extraDays == 0 ? start.calendarDate :  start.calendarDate.addDays(calc.extraDays);
    return LocalDateTime.localDateAtTime(date, calc.localTime);
  }

  LocalTime addTime(LocalTime localTime, int value)
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
      int newNanos = localTime.timeSinceMidnight.inNanoseconds + nanosToAdd;
      if (newNanos >= TimeConstants.nanosecondsPerDay)
      {
        newNanos -= TimeConstants.nanosecondsPerDay;
      }
      return ILocalTime.trustedNanoseconds(newNanos);
    }
    else
    {
      if (value <= -_unitsPerDay)
      {
        value = -(-value % _unitsPerDay);
      }
      int nanosToAdd = value * _unitNanoseconds;
      int newNanos = localTime.timeSinceMidnight.inNanoseconds + nanosToAdd;
      if (newNanos < 0)
      {
        newNanos += TimeConstants.nanosecondsPerDay;
      }
      return ILocalTime.trustedNanoseconds(newNanos);
    }
  }

  int unitsBetween(LocalDateTime start, LocalDateTime end)
  {
    LocalInstant startLocalInstant = ILocalDateTime.toLocalInstant(start);
    LocalInstant endLocalInstant = ILocalDateTime.toLocalInstant(end);
    Time span = endLocalInstant.timeSinceLocalEpoch - startLocalInstant.timeSinceLocalEpoch;
    return getUnitsInDuration(span);
  }

  // todo: inspect the use cases here -- this might need special logic (if Span is always under 100 days, it's fine)
  /// Returns the number of units in the given duration, rounding towards zero.
  int getUnitsInDuration(Time span) {
    if (span.canNanosecondsBeInteger) {
      return span.totalNanoseconds ~/ _unitNanoseconds;
    }
    else {
      var units = span.inNanosecondsAsBigInt ~/ BigInt.from(_unitNanoseconds);
      if (units >= Platform.bigIntMinValue && units <= Platform.bigIntMaxValue) {
        return units.toInt();
      }
      throw RangeError('$units out of range of integer: [${Platform.intMinValue}, ${Platform.intMaxValue}]');
    }
  }

  /// Returns a [Time] representing the given number of units.
  Time toSpan(int units) =>
      units >= -_maxLongUnits && units <= _maxLongUnits
          ? Time(nanoseconds: units * _unitNanoseconds)
          : _toSpanSafely(units);

  Time _toSpanSafely(int units) {
    var maxLongUnitsMS = _maxLongUnits * TimeConstants.nanosecondsPerMillisecond;
    if (units >= -maxLongUnitsMS && units <= maxLongUnitsMS) {
      var milliseconds = units * (_unitNanoseconds ~/ 1000000);
      var nanoseconds = units * (_unitNanoseconds % 1000000);
      return Time(milliseconds: milliseconds, nanoseconds: nanoseconds);
    }
    else {
      var bigNanoseconds = BigInt.from(_unitNanoseconds);
      var bigUnits = BigInt.from(units);
      return Time.bigIntNanoseconds(bigNanoseconds * bigUnits);
    }
  }
}
