// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:quiver_hashcode/hashcode.dart';
import 'package:meta/meta.dart';

import 'package:time_machine/time_machine.dart';

// todo: IEquatable<YearMonthDayCalendar>
/// This is a Year - Month - Day - Calendar TUPLE -- this not actually a Calendar
/// Todo: I think I'll change this class name to reflect that, when we're farther along with this port
///   Theoretically this isn't part of the public API + I need to find out if bit packing even makes any sense in this library
///   It might? -- at least on the VM it might
@internal
class YearMonthDayCalendar {
  // These constants are internal so they can be used in YearMonthDay
  @internal static const int calendarBits = 6; // Up to 64 calendars.
  @internal static const int dayBits = 6; // Up to 64 days in a month.
  @internal static const int monthBits = 5; // Up to 32 months per year.
  @internal static const int yearBits = 15; // 32K range; only need -10K to +10K.

  // Just handy constants to use for shifting and masking.
  static const int _calendarDayBits = calendarBits + dayBits;
  static const int _calendarDayMonthBits = _calendarDayBits + monthBits;

  static const int _calendarMask = (1 << calendarBits) - 1;
  static const int _dayMask = ((1 << dayBits) - 1) << calendarBits;
  static const int _monthMask = ((1 << monthBits) - 1) << _calendarDayBits;
  static const int _yearMask = ((1 << yearBits) - 1) << _calendarDayMonthBits;

  @internal final CalendarOrdinal calendarOrdinal;
  // @internal final int _value;
  @internal final YearMonthDay yearMonthDay;

  @internal
  YearMonthDayCalendar.ymd(this.yearMonthDay, this.calendarOrdinal);
// : _value = (yearMonthDay << calendarBits) | calendarOrdinal.value;

  @internal
  /// Constructs a new value for the given year, month, day and calendar. No validation is performed.
  YearMonthDayCalendar(int year, int month, int day, this.calendarOrdinal) :
      yearMonthDay = new YearMonthDay(year, month, day);
//      : _value = ((year - 1) << _calendarDayMonthBits) |
//  ((month - 1) << _calendarDayBits) |
//  ((day - 1) << calendarBits) |
//  calendarOrdinal.value;


// @internal
// CalendarOrdinal get calendarOrdinal => new CalendarOrdinal(_value & _calendarMask);

// @internal
// int get year => ((_value & _yearMask) >> _calendarDayMonthBits) + 1;

// @internal
// int get month => ((_value & _monthMask) >> _calendarDayBits) + 1;

// @internal
// int get day => ((_value & _dayMask) >> calendarBits) + 1;

  @internal
  int get year => yearMonthDay.year;

  @internal
  int get month => yearMonthDay.month;

  @internal
  int get day => yearMonthDay.day;


  // Just for testing purposes...
  @visibleForTesting
  static YearMonthDayCalendar Parse(String text) {
// throw new UnimplementedError('We need to be able to parse the CalendarOrdinal Enum.');

    // Handle a leading - to negate the year
    if (text.startsWith("-")) {
      var ymdc = Parse(text.substring(1));
      return new YearMonthDayCalendar(-ymdc.year, ymdc.month, ymdc.day, ymdc.calendarOrdinal);
    }

    List<String> bits = text.split('-');
    return new YearMonthDayCalendar(
        int.parse(bits[0]), // CultureInfo.InvariantCulture),
        int.parse(bits[1]), // CultureInfo.InvariantCulture),
        int.parse(bits[2]), // CultureInfo.InvariantCulture),
        // bits[3]));
        CalendarOrdinal.parse(bits[3]));
  }

  @internal
  YearMonthDay toYearMonthDay() => yearMonthDay; // new YearMonthDay.raw(_value >> calendarBits);

  @override String toString() => new YearMonthDay(year, month, day).toString() + '-$calendarOrdinal';

// string.Format(CultureInfo.InvariantCulture, "{0:0000}-{1:00}-{2:00}-{3}", Year, Month, Day, CalendarOrdinal);

  @override
  bool operator ==(dynamic rhs) => rhs is YearMonthDayCalendar ? yearMonthDay == rhs.yearMonthDay && calendarOrdinal == rhs.calendarOrdinal : false;

  @override
  int get hashCode => hash2(yearMonthDay.hashCode, calendarOrdinal.hashCode);
}

