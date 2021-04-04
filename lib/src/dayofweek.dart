// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';

/// Equates the days of the week with their numerical value according to
/// ISO-8601.
@immutable
class DayOfWeek {
  final int _value;

  int get value => _value;

  static const List<String> _stringRepresentations = [
    'None', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  static const List<DayOfWeek> _isoConstants = [
    none, monday, tuesday, wednesday, thursday, friday, saturday, sunday
  ];

  /// Value indicating no day of the week; this will never be returned
  /// by any IsoDayOfWeek property, and is not valid as an argument to
  /// any method.
  static const DayOfWeek none = DayOfWeek(0);
  /// Value representing Monday (1).
  static const DayOfWeek monday = DayOfWeek(1);
  /// Value representing Tuesday (2).
  static const DayOfWeek tuesday = DayOfWeek(2);
  /// Value representing Wednesday (3).
  static const DayOfWeek wednesday = DayOfWeek(3);
  /// Value representing Thursday (4).
  static const DayOfWeek thursday = DayOfWeek(4);
  /// Value representing Friday (5).
  static const DayOfWeek friday = DayOfWeek(5);
  /// Value representing Saturday (6).
  static const DayOfWeek saturday = DayOfWeek(6);
  /// Value representing Sunday (7).
  static const DayOfWeek sunday = DayOfWeek(7);

  const DayOfWeek(this._value);

  @override int get hashCode => _value.hashCode;
  @override bool operator  ==(Object other) => other is DayOfWeek && other._value == _value || other is int && other == _value;

  bool operator <(DayOfWeek other) => _value < other._value;
  bool operator <=(DayOfWeek other) => _value <= other._value;
  bool operator >(DayOfWeek other) => _value > other._value;
  bool operator >=(DayOfWeek other) => _value >= other._value;

  int operator -(DayOfWeek other) => _value - other._value;
  int operator +(DayOfWeek other) => _value + other._value;

  @override
  String toString() => _stringRepresentations[_value];

  DayOfWeek? parse(String text) {
    var token = text.trim().toLowerCase();
    for (int i = 0; i < _stringRepresentations.length; i++) {
      if (stringOrdinalIgnoreCaseEquals(_stringRepresentations[i], token)) return _isoConstants[i];
    }

    return null;
  }
}
