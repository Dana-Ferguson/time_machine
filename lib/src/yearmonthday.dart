// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// import 'package:quiver_hashcode/hashcode.dart';
import 'package:time_machine/src/time_machine_internal.dart';

// todo: bit packing didn't work on JS -- I feel like it should though (getting the class functional now, will investigate later)
@internal
@immutable
class YearMonthDay implements Comparable<YearMonthDay> {
  final int year;
  final int month;
  final int day;

  /// Constructs a new value for the given year, month and day. No validation is performed.
  const YearMonthDay(this.year, this.month, this.day);

  // Just for testing purposes...
  static YearMonthDay parse(String text) {
    // Handle a leading - to negate the year
    if (text.startsWith('-')) {
      var ymd = parse(text.substring(1));
      return YearMonthDay(-ymd.year, ymd.month, ymd.day);
    }

    var bits = text.split('-');
    return YearMonthDay(
        int.parse(bits[0]),
        int.parse(bits[1]),
        int.parse(bits[2]));
  }

  // todo: padding doesn't work well with '-'s)
  @override
  String toString() => '${StringFormatUtilities.zeroPadNumber(year, 4)}-${StringFormatUtilities.zeroPadNumber(month, 2)}-${StringFormatUtilities.zeroPadNumber(day, 2)}';

  YearMonthDayCalendar withCalendar(CalendarSystem calendar) =>
      YearMonthDayCalendar.ymd(this, ICalendarSystem.ordinal(calendar));

  YearMonthDayCalendar withCalendarOrdinal(CalendarOrdinal calendarOrdinal) =>
      YearMonthDayCalendar.ymd(this, calendarOrdinal);


  @override
  int compareTo(YearMonthDay? other) {
    if (other == null) return 1;

    int comparison;
    if ((comparison = year.compareTo(other.year)) != 0) return comparison;
    if ((comparison = month.compareTo(other.month)) != 0) return comparison;
    return day.compareTo(other.day);
  }

  @override
  int get hashCode => hash3(year, month, day);

  @override
  bool operator==(Object other) => other is YearMonthDay ? (year == other.year && month == other.month && day == other.day) : false;

  bool operator <(YearMonthDay? other) {
    if (other == null) return false;

    if (year < other.year) return true;
    if (year > other.year) return false;

    if (month < other.month) return true;
    if (month > other.month) return false;

    if (day < other.day) return true;
    return false;
  }

  bool operator <=(YearMonthDay? other) {
    if (other == null) return false;

    if (year < other.year) return true;
    if (year > other.year) return false;

    if (month < other.month) return true;
    if (month > other.month) return false;

    if (day <= other.day) return true;
    return false;
  }

  bool operator >(YearMonthDay? other) {
    if (other == null) return false;

    if (year > other.year) return true;
    if (year < other.year) return false;

    if (month > other.month) return true;
    if (month < other.month) return false;

    if (day > other.day) return true;
    return false;
  }

  bool operator >=(YearMonthDay? other) {
    if (other == null) return false;

    if (year > other.year) return true;
    if (year < other.year) return false;

    if (month > other.month) return true;
    if (month < other.month) return false;

    if (day >= other.day) return true;
    return false;
  }
}

// This works on the VM, but does not work on JS
// TODO: investigate, can I still get some version of this working on JS?
/*@internal
class YearMonthDayVM implements Comparable<YearMonthDay> {
  // static const int _dayBits = 6; // Up to 64 days in a month.
  // static const int _monthBits = 4; // Up to 16 months per year.
  // static const int _yearBits = 15; // 32K range; only need -10K to +10K.

  static const int _dayMask = (1 << YearMonthDayCalendar.dayBits) - 1;
  static const int _monthMask = ((1 << YearMonthDayCalendar.monthBits) - 1) << YearMonthDayCalendar.dayBits;

  final int _value;

  YearMonthDayVM.raw(int rawValue) : _value = rawValue;

  /// Constructs a new value for the given year, month and day. No validation is performed.
  YearMonthDayVM(int year, int month, int day) :
        _value = ((year - 1) << (YearMonthDayCalendar.dayBits + YearMonthDayCalendar.monthBits)) | ((month - 1) << YearMonthDayCalendar.dayBits) | (day - 1);

  // todo: + calendar
  int get year => (_value >> (YearMonthDayCalendar.dayBits + YearMonthDayCalendar.monthBits)) + 1;

  int get month => ((_value & _monthMask) >> YearMonthDayCalendar.dayBits) + 1;

  int get day => (_value & _dayMask) + 1;

  int get rawValue => _value;

  // Just for testing purposes...
  static YearMonthDay parse(String text) {
    // Handle a leading - to negate the year
    if (text.startsWith('-')) {
      var ymd = parse(text.substring(1));
      return new YearMonthDay(-ymd.year, ymd.month, ymd.day);
    }

    var bits = text.split('-');
    // todo: , Culture.invariantCulture))
    return new YearMonthDay(
        int.parse(bits[0]),
        int.parse(bits[1]),
        int.parse(bits[2]));
  }

  // todo: padding doesn't work well with '-'s)
  @override
  String toString() => '${StringFormatUtilities.zeroPadNumber(year, 4)}-${StringFormatUtilities.zeroPadNumber(month, 2)}-${StringFormatUtilities.zeroPadNumber(day, 2)}';

  YearMonthDayCalendar withCalendar(CalendarSystem calendar) =>
      new YearMonthDayCalendar.ymd(this, calendar == null ? 0 : calendar.ordinal);

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

  int get hashCode => _value.hashCode;

  bool operator ==(Object rhs) => rhs is YearMonthDay ? _value == rhs._value : false;

//@override
//bool operator !=(YearMonthDay rhs) => _value != rhs._value;

  bool operator <(YearMonthDay rhs) => rhs == null ? false : _value < rhs._value;

  bool operator <=(YearMonthDay rhs) => rhs == null ? false : _value <= rhs._value;

  bool operator >(YearMonthDay rhs) => rhs == null ? true : _value > rhs._value;

  bool operator >=(YearMonthDay rhs) => rhs == null ? true : _value >= rhs._value;
}
*/
