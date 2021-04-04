// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

/// The units within a [period]. When a period is created to find the difference between two local values,
/// the caller may specify which units are required - for example, you can ask for the difference between two dates
/// in 'years and weeks'. Units are always applied largest-first in arithmetic.
@immutable
class PeriodUnits {
  final int _value;

  int get value => _value;

  static const List<String> _stringRepresentations = [
    'None', 'Years', 'Months', 'Weeks', 'Days', 'AllDateUnits',
    'YearMonthDay', 'Hours', 'Minutes', 'Seconds', 'Milliseconds',
    'Microseconds', 'Nanoseconds', 'HourMinuteSecond', 'AllTimeUnits',
    'DateAndTime', 'AllUnits'
  ];

  static const List<PeriodUnits> _isoConstants = [
    none, years, months, weeks, days, allDateUnits, yearMonthDay, hours,
    minutes, seconds, milliseconds, microseconds, nanoseconds, hourMinuteSecond, allTimeUnits,
    dateAndTime, allUnits
  ];

  // todo: look at: Constants --> Strings; and then maybe Strings --> Constants ~ but the strings wrapped in a class that doesn't care about case
  //  they'd be really convenient for mask enumerations
  static final Map<PeriodUnits, String> _nameMap = {
    none: 'None', years: 'Years', months: 'Months', weeks: 'Weeks', days: 'Days', allDateUnits: 'AllDateUnits',
    yearMonthDay: 'YearMonthDay', hours: 'Hours', minutes: 'Minutes', seconds: 'Seconds', milliseconds:'Milliseconds',
    microseconds: 'Microseconds', nanoseconds: 'Nanoseconds', hourMinuteSecond:'HourMinuteSecond', allTimeUnits:'AllTimeUnits',
    dateAndTime: 'DateAndTime', allUnits: 'AllUnits'
  };

  static List<PeriodUnits> get values => _isoConstants;


  /// Value indicating no units - an empty period
  static const PeriodUnits none = PeriodUnits(0);
  /// Years element within a [period]
  static const PeriodUnits years = PeriodUnits(1);
  /// Months element within a [period]
  static const PeriodUnits months = PeriodUnits(2);
  /// Weeks element within a [period]
  static const PeriodUnits weeks = PeriodUnits(4);
  /// Days element within a [period]
  static const PeriodUnits days = PeriodUnits(8);
  /// Compound value representing the combination of [years], [months], [weeks] and [days]
  static const PeriodUnits allDateUnits = PeriodUnits(15); // union(const [years, months, weeks, days]);
  /// Compound value representing the combination of [years], [months] and [days]
  static const PeriodUnits yearMonthDay = PeriodUnits(11); // union(const [years, months, days]);
  /// Hours element within a [period]
  static const PeriodUnits hours = PeriodUnits(16);
  /// Minutes element within a [period]
  static const PeriodUnits minutes = PeriodUnits(32);
  /// Seconds element within a [period]
  static const PeriodUnits seconds = PeriodUnits(64);
  /// Milliseconds element within a [period]
  static const PeriodUnits milliseconds = PeriodUnits(128);
  /// Tick element within a [period]
  static const PeriodUnits microseconds = PeriodUnits(256);
  /// Nanoseconds element within a [period]
  static const PeriodUnits nanoseconds = PeriodUnits(512);
  /// Compound value representing the combination of [hours], [minutes] and [seconds]
  static const PeriodUnits hourMinuteSecond = PeriodUnits(112); // union(const [hours, minutes, seconds]);
  /// Compound value representing the combination of all time elements
  static const PeriodUnits allTimeUnits = PeriodUnits(1008); // union(const [hours, minutes, seconds, milliseconds, microseconds, nanoseconds]);
  /// Compound value representing the combination of all possible elements except weeks
  static const PeriodUnits dateAndTime = PeriodUnits(1019); // union(const [years, months, days, hours, minutes, seconds, milliseconds, microseconds, nanoseconds]);
  /// Compound value representing the combination of all possible elements
  static const PeriodUnits allUnits = PeriodUnits(1023); // union(const [years, months, weeks, days, hours, minutes, seconds, milliseconds, microseconds, nanoseconds]);

  @override int get hashCode => _value.hashCode;
  @override bool operator ==(Object other) =>
      (other is PeriodUnits && other._value == _value)
          || (other is int && other == _value);

  const PeriodUnits(this._value);

  bool operator <(PeriodUnits other) => _value < other._value;
  bool operator <=(PeriodUnits other) => _value <= other._value;
  bool operator >(PeriodUnits other) => _value > other._value;
  bool operator >=(PeriodUnits other) => _value >= other._value;

  int operator -(PeriodUnits other) => _value - other._value;
  int operator +(PeriodUnits other) => _value + other._value;

  PeriodUnits operator |(PeriodUnits other) => PeriodUnits(_value | other.value);
  PeriodUnits operator &(PeriodUnits other) => PeriodUnits(_value & other.value);

  @override
  String toString() => _nameMap[this] ?? 'undefined';

  PeriodUnits? parse(String text) {
    var token = text.trim().toLowerCase();
    for (int i = 0; i < _stringRepresentations.length; i++) {
      if (stringOrdinalIgnoreCaseEquals(_stringRepresentations[i], token)) return _isoConstants[i];
    }

    return null;
  }

  // todo: there is probably a more friendly way to incorporate this for mask usage -- so we can have friendly defined constants above
  static PeriodUnits union(Iterable<PeriodUnits> units) {
    int i = 0;
    units.forEach((u) => i = i|u._value);
    return PeriodUnits(i);
  }
}
