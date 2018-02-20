// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/IsoDayOfWeek.cs
// a209e60  on Mar 18, 2015

import 'package:time_machine/time_machine_utilities.dart';

///// Equates the days of the week with their numerical value according to
///// ISO-8601. This corresponds with System.DayOfWeek except for Sunday, which
///// is 7 in the ISO numbering and 0 in System.DayOfWeek.
//enum IsoDayOfWeek {
//  /// Value indicating no day of the week; this will never be returned
//  /// by any IsoDayOfWeek property, and is not valid as an argument to
//  /// any method.
//  none,
//
//  /// Value representing Monday (1).
//  monday,
//
//  /// Value representing Tuesday (2).
//  tuesday,
//
//  /// Value representing Wednesday (3).
//  wednesday,
//
//  /// Value representing Thursday (4).
//  thursday,
//
//  /// Value representing Friday (5).
//  friday,
//
//  /// Value representing Saturday (6).
//  saturday,
//
//  /// Value representing Sunday (7).
//  sunday
//}

// todo: I might want to write a code generator for enums?

// todo: IsoDayOfWeek is called that because 'DayOfWeek' is a BCL enumeration -- I don't think it is here, so we can steal it back?

/// Equates the days of the week with their numerical value according to
/// ISO-8601. This corresponds with System.DayOfWeek except for Sunday, which
/// is 7 in the ISO numbering and 0 in System.DayOfWeek.
class IsoDayOfWeek {
  final int _value;

  int get value => _value;

  static const List<String> _stringRepresentations = const [
    'None', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  static const List<IsoDayOfWeek> _isoConstants = const [
    none, monday, tuesday, wednesday, thursday, friday, saturday, sunday
  ];

  /// Value indicating no day of the week; this will never be returned
  /// by any IsoDayOfWeek property, and is not valid as an argument to
  /// any method.
  static const IsoDayOfWeek none = const IsoDayOfWeek(0);
  /// Value representing Monday (1).
  static const IsoDayOfWeek monday = const IsoDayOfWeek(1);
  /// Value representing Tuesday (2).
  static const IsoDayOfWeek tuesday = const IsoDayOfWeek(2);
  /// Value representing Wednesday (3).
  static const IsoDayOfWeek wednesday = const IsoDayOfWeek(3);
  /// Value representing Thursday (4).
  static const IsoDayOfWeek thursday = const IsoDayOfWeek(4);
  /// Value representing Friday (5).
  static const IsoDayOfWeek friday = const IsoDayOfWeek(5);
  /// Value representing Saturday (6).
  static const IsoDayOfWeek saturday = const IsoDayOfWeek(6);
  /// Value representing Sunday (7).
  static const IsoDayOfWeek sunday = const IsoDayOfWeek(7);

  const IsoDayOfWeek(this._value);

  bool operator <(IsoDayOfWeek other) => _value < other._value;
  bool operator <=(IsoDayOfWeek other) => _value <= other._value;
  bool operator >(IsoDayOfWeek other) => _value > other._value;
  bool operator >=(IsoDayOfWeek other) => _value >= other._value;

  int operator -(IsoDayOfWeek other) => _value - other._value;
  int operator +(IsoDayOfWeek other) => _value + other._value;

  @override
  String toString() => _stringRepresentations[_value] ?? 'undefined';

  IsoDayOfWeek parse(String text) {
    var token = text.trim().toLowerCase();
    for (int i = 0; i < _stringRepresentations.length; i++) {
      if (ordinalIgnoreCaseStringEquals(_stringRepresentations[i], token)) return _isoConstants[i];
    }

    return null;
  }
}