// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// import 'package:quiver_hashcode/hashcode.dart';
import 'package:time_machine/src/time_machine_internal.dart';

// This is a Year - Month - Day - Calendar TUPLE -- this not actually a Calendar;
// todo: test bit packing
@internal
@immutable
class YearMonthDayCalendar {
  // These constants are internal so they can be used in YearMonthDay
  static const int calendarBits = 6; // Up to 64 calendars.
  static const int dayBits = 6; // Up to 64 days in a month.
  static const int monthBits = 5; // Up to 32 months per year.
  static const int yearBits = 15; // 32K range; only need -10K to +10K.

  // Just handy constants to use for shifting and masking.
  //static const int _calendarDayBits = calendarBits + dayBits;
  //static const int _calendarDayMonthBits = _calendarDayBits + monthBits;

  //static const int _calendarMask = (1 << calendarBits) - 1;
  //static const int _dayMask = ((1 << dayBits) - 1) << calendarBits;
  //static const int _monthMask = ((1 << monthBits) - 1) << _calendarDayBits;
  //static const int _yearMask = ((1 << yearBits) - 1) << _calendarDayMonthBits;

  final CalendarOrdinal calendarOrdinal;
  // final int _value;
  final YearMonthDay yearMonthDay;

  const YearMonthDayCalendar.ymd(this.yearMonthDay, this.calendarOrdinal);
// : _value = (yearMonthDay << calendarBits) | calendarOrdinal.value;


  /// Constructs a new value for the given year, month, day and calendar. No validation is performed.
  YearMonthDayCalendar(int year, int month, int day, this.calendarOrdinal) :
      yearMonthDay = YearMonthDay(year, month, day);
  //      : _value = ((year - 1) << _calendarDayMonthBits) |
  //  ((month - 1) << _calendarDayBits) |
  //  ((day - 1) << calendarBits) |
  //  calendarOrdinal.value;

  // CalendarOrdinal get calendarOrdinal => new CalendarOrdinal(_value & _calendarMask);
  // int get year => ((_value & _yearMask) >> _calendarDayMonthBits) + 1;
  // int get month => ((_value & _monthMask) >> _calendarDayBits) + 1;
  // int get day => ((_value & _dayMask) >> calendarBits) + 1;

  int get year => yearMonthDay.year;

  int get month => yearMonthDay.month;

  int get day => yearMonthDay.day;

  @visibleForTesting
  static YearMonthDayCalendar Parse(String text) {
    // Handle a leading - to negate the year
    if (text.startsWith('-')) {
      var ymdc = Parse(text.substring(1));
      return YearMonthDayCalendar(-ymdc.year, ymdc.month, ymdc.day, ymdc.calendarOrdinal);
    }

    List<String> bits = text.split('-');
    return YearMonthDayCalendar(
        int.parse(bits[0]),
        int.parse(bits[1]),
        int.parse(bits[2]),
        // bits[3]));
        CalendarOrdinal.parse(bits[3])!);
  }

  YearMonthDay toYearMonthDay() => yearMonthDay; // new YearMonthDay.raw(_value >> calendarBits);

  @override
  String toString() => YearMonthDay(year, month, day).toString() + '-$calendarOrdinal';

  @override
  bool operator ==(Object rhs) => rhs is YearMonthDayCalendar ? yearMonthDay == rhs.yearMonthDay && calendarOrdinal == rhs.calendarOrdinal : false;

  @override
  int get hashCode => hash2(yearMonthDay.hashCode, calendarOrdinal.hashCode);
}

