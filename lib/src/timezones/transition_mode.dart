// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/TransitionMode.cs
// a209e60  on Mar 18, 2015

import 'package:time_machine/time_machine_utilities.dart';

/// Specifies how transitions are calculated. Whether relative to UTC, the time zones standard
/// offset, or the wall (or daylight savings) offset.
class TransitionMode {
  final int _value;

  int get value => _value;

  static const List<String> _stringRepresentations = const [
    'Utc', 'Wall', 'Standard'
  ];

  static const List<TransitionMode> _isoConstants = const [
    utc, wall, standard
  ];

  /// Calculate transitions against UTC.
  static const TransitionMode utc = const TransitionMode(0);
  /// Calculate transitions against wall offset.
  static const TransitionMode wall = const TransitionMode(1);
  /// Calculate transitions against standard offset.
  static const TransitionMode standard = const TransitionMode(2);

  const TransitionMode(this._value);

  bool operator <(TransitionMode other) => _value < other._value;
  bool operator <=(TransitionMode other) => _value <= other._value;
  bool operator >(TransitionMode other) => _value > other._value;
  bool operator >=(TransitionMode other) => _value >= other._value;

  int operator -(TransitionMode other) => _value - other._value;
  int operator +(TransitionMode other) => _value + other._value;

  bool operator ==(dynamic other) => other is TransitionMode && other._value == _value;
  int get hashCode => _value.hashCode;

  @override
  String toString() => _value < _stringRepresentations.length ?
    _stringRepresentations[_value] : 'undefined:$_value';

  TransitionMode parse(String text) {
    var token = text.trim().toLowerCase();
    for (int i = 0; i < _stringRepresentations.length; i++) {
      if (stringOrdinalIgnoreCaseEquals(_stringRepresentations[i], token)) return _isoConstants[i];
    }

    return null;
  }
}