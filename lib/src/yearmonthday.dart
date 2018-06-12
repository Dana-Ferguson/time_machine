// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';

// todo: YearMonthDay_Calendar packing didn't work on VM (with the masks -- packing actually worked!), I don't think this packing works on JS, we'll need to drop it (or investigate a better solution)
@internal
class YearMonthDay implements Comparable<YearMonthDay> {
// static const int _dayBits = 6; // Up to 64 days in a month.
// static const int _monthBits = 4; // Up to 16 months per year.
// static const int _yearBits = 15; // 32K range; only need -10K to +10K.

  static const int _dayMask = (1 << YearMonthDayCalendar.dayBits) - 1;
  static const int _monthMask = ((1 << YearMonthDayCalendar.monthBits) - 1) << YearMonthDayCalendar.dayBits;

  final int _value;

  @internal
  YearMonthDay.raw(int rawValue) : _value = rawValue;

  @internal
  /// Constructs a new value for the given year, month and day. No validation is performed.
  YearMonthDay(int year, int month, int day) :
        _value = ((year - 1) << (YearMonthDayCalendar.dayBits + YearMonthDayCalendar.monthBits)) | ((month - 1) << YearMonthDayCalendar.dayBits) | (day - 1);

  // todo: + calendar
  @internal
  int get year => (_value >> (YearMonthDayCalendar.dayBits + YearMonthDayCalendar.monthBits)) + 1;

  int get month => ((_value & _monthMask) >> YearMonthDayCalendar.dayBits) + 1;

  int get day => (_value & _dayMask) + 1;

  int get rawValue => _value;

  // Just for testing purposes...
  @internal
  static YearMonthDay parse(String text) {
    // Handle a leading - to negate the year
    if (text.startsWith("-")) {
      var ymd = parse(text.substring(1));
      return new YearMonthDay(-ymd.year, ymd.month, ymd.day);
    }

    var bits = text.split('-');
    // todo: , CultureInfo.InvariantCulture))
    return new YearMonthDay(
        int.parse(bits[0]),
        int.parse(bits[1]),
        int.parse(bits[2]));
  }

  // todo: padding doesn't work well with '-'s)
  @override
  String toString() => '${StringFormatUtilities.zeroPadNumber(year, 4)}-${StringFormatUtilities.zeroPadNumber(month, 2)}-${StringFormatUtilities.zeroPadNumber(day, 2)}';

  @internal
  YearMonthDayCalendar withCalendar(CalendarSystem calendar) =>
      new YearMonthDayCalendar.ymd(this, calendar == null ? 0 : calendar.ordinal);

  @internal
  YearMonthDayCalendar withCalendarOrdinal(CalendarOrdinal calendarOrdinal) =>
      new YearMonthDayCalendar.ymd(this, calendarOrdinal);

  int compareTo(YearMonthDay other) => (other == null) ? 1 : _value.compareTo(other._value);

//bool Equals(YearMonthDay other)
//{
//return _value == other._value;
//}
//
//@override
//bool Equals(dynamic other) => other is YearMonthDay && Equals(other);

  @override
  int get hashCode => _value.hashCode;

  @override
  bool operator ==(dynamic rhs) => rhs is YearMonthDay ? _value == rhs._value : false;

//@override
//bool operator !=(YearMonthDay rhs) => _value != rhs._value;

  bool operator <(YearMonthDay rhs) => rhs == null ? false : _value < rhs._value;

  bool operator <=(YearMonthDay rhs) => rhs == null ? false : _value <= rhs._value;

  bool operator >(YearMonthDay rhs) => rhs == null ? true : _value > rhs._value;

  bool operator >=(YearMonthDay rhs) => rhs == null ? true : _value >= rhs._value;
}

