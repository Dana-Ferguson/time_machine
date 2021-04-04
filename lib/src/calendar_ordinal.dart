// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';

@internal
@immutable
/// Enumeration of calendar ordinal values. Used for converting between a compact integer representation and a calendar system.
/// We use 7 bits to store the calendar ordinal in YearMonthDayCalendar, so we can have up to 128 calendars.
class CalendarOrdinal {
  final int _value;
  int get value => _value;

  static const List<String> _stringRepresentations = [
    'Iso', 'Gregorian', 'Julian', 'Coptic', 'HebrewCivil', 'HebrewScriptural',
    'PersianSimple', 'PersianArithmetic', 'PersianAstronomical',
    'IslamicAstronomicalBase15', 'IslamicAstronomicalBase16', 'IslamicAstronomicalIndian', 'IslamicAstronomicalHabashAlHasib',
    'IslamicCivilBase15', 'IslamicCivilBase16', 'IslamicCivilIndian', 'IslamicAstronomicalHabashAlHasib',
    'UmAlQura', 'Wondrous', 'Size'
  ];

  static const List<CalendarOrdinal> _enumConstants = [
    iso, gregorian, julian, coptic, hebrewCivil, hebrewScriptural,
    persianSimple, persianArithmetic, persianAstronomical,
    islamicAstronomicalBase15, islamicAstronomicalBase16, islamicAstronomicalIndian, islamicAstronomicalHabashAlHasib,
    islamicCivilBase15, islamicCivilBase16, islamicCivilIndian, islamicAstronomicalHabashAlHasib,
    umAlQura, badi, size
  ];

  /// Value indicating no day of the week; this will never be returned
  /// by any IsoDayOfWeek property, and is not valid as an argument to
  /// any method.
  static const CalendarOrdinal iso = CalendarOrdinal(0);
  static const CalendarOrdinal gregorian = CalendarOrdinal(1);
  static const CalendarOrdinal julian = CalendarOrdinal(2);
  static const CalendarOrdinal coptic = CalendarOrdinal(3);
  static const CalendarOrdinal hebrewCivil = CalendarOrdinal(4);
  static const CalendarOrdinal hebrewScriptural = CalendarOrdinal(5);
  static const CalendarOrdinal persianSimple = CalendarOrdinal(6);
  static const CalendarOrdinal persianArithmetic = CalendarOrdinal(7);
  static const CalendarOrdinal persianAstronomical = CalendarOrdinal(8);
  static const CalendarOrdinal islamicAstronomicalBase15 = CalendarOrdinal(9);
  static const CalendarOrdinal islamicAstronomicalBase16 = CalendarOrdinal(10);
  static const CalendarOrdinal islamicAstronomicalIndian = CalendarOrdinal(11);
  static const CalendarOrdinal islamicAstronomicalHabashAlHasib = CalendarOrdinal(12);
  static const CalendarOrdinal islamicCivilBase15 = CalendarOrdinal(13);
  static const CalendarOrdinal islamicCivilBase16 = CalendarOrdinal(14);
  static const CalendarOrdinal islamicCivilIndian = CalendarOrdinal(15);
  static const CalendarOrdinal islamicCivilHabashAlHasib = CalendarOrdinal(16);
  static const CalendarOrdinal umAlQura = CalendarOrdinal(17);
  static const CalendarOrdinal badi = CalendarOrdinal(18);
  // Not a real ordinal; just present to keep a count. Increase this as the number increases...
  static const CalendarOrdinal size = CalendarOrdinal(19);

  const CalendarOrdinal(this._value);

  @override int get hashCode => _value.hashCode;
  @override bool operator ==(Object other) => other is CalendarOrdinal && other._value == _value || other is int && other == _value;

  bool operator <(CalendarOrdinal other) => _value < other._value;
  bool operator <=(CalendarOrdinal other) => _value <= other._value;
  bool operator >(CalendarOrdinal other) => _value > other._value;
  bool operator >=(CalendarOrdinal other) => _value >= other._value;

  int operator -(CalendarOrdinal other) => _value - other._value;
  int operator +(CalendarOrdinal other) => _value + other._value;

  @override
  String toString() => _stringRepresentations.length > _value ? _stringRepresentations[_value] : 'undefined';

  static CalendarOrdinal? parse(String text) {
    var token = text.trim().toLowerCase();
    for (int i = 0; i < _stringRepresentations.length; i++) {
      if (stringOrdinalIgnoreCaseEquals(_stringRepresentations[i], token)) return _enumConstants[i];
    }

    return null;
  }
}
