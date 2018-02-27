// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/CalendarOrdinal.cs
// f4ced3a  on Dec 7, 2017

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';

//@internal
///// Enumeration of calendar ordinal values. Used for converting between a compact integer representation and a calendar system.
///// We use 7 bits to store the calendar ordinal in YearMonthDayCalendar, so we can have up to 128 calendars.
//enum CalendarOrdinal {
//  Iso, // = 0,
//  Gregorian, // = 1,
//  Julian, // = 2,
//  Coptic, // = 3,
//  HebrewCivil, // = 4,
//  HebrewScriptural, // = 5,
//  PersianSimple, // = 6,
//  PersianArithmetic, // = 7,
//  PersianAstronomical, // = 8,
//  IslamicAstronomicalBase15, // = 9,
//  IslamicAstronomicalBase16, // = 10,
//  IslamicAstronomicalIndian, // = 11,
//  IslamicAstronomicalHabashAlHasib, // = 12,
//  IslamicCivilBase15, // = 13,
//  IslamicCivilBase16, // = 14,
//  IslamicCivilIndian, // = 15,
//  IslamicCivilHabashAlHasib, // = 16,
//  UmAlQura, // = 17,
//  Wondrous, // = 18,
//  // Not a real ordinal; just present to keep a count. Increase this as the number increases...
//  Size // = 19
//}

@internal
/// Enumeration of calendar ordinal values. Used for converting between a compact integer representation and a calendar system.
/// We use 7 bits to store the calendar ordinal in YearMonthDayCalendar, so we can have up to 128 calendars.
class CalendarOrdinal {
  final int _value;
  int get value => _value;

  static const List<String> _stringRepresentations = const [
    'Iso', 'Gregorian', 'Julian', 'Coptic', 'HebrewCivil', 'HebrewScriptural',
    'PersianSimple', 'PersianArithmetic', 'PersianAstronomical',
    'IslamicAstronomicalBase15', 'IslamicAstronomicalBase16', 'IslamicAstronomicalIndian', 'IslamicAstronomicalHabashAlHasib',
    'IslamicCivilBase15', 'IslamicCivilBase16', 'IslamicCivilIndian', 'IslamicAstronomicalHabashAlHasib',
    'UmAlQura', 'Wondrous', 'Size'
  ];

  static const List<CalendarOrdinal> _enumConstants = const [
    Iso, Gregorian, Julian, Coptic, HebrewCivil, HebrewScriptural,
    PersianSimple, PersianArithmetic, PersianAstronomical,
    IslamicAstronomicalBase15, IslamicAstronomicalBase16, IslamicAstronomicalIndian, IslamicAstronomicalHabashAlHasib,
    IslamicCivilBase15, IslamicCivilBase16, IslamicCivilIndian, IslamicAstronomicalHabashAlHasib,
    UmAlQura, Wondrous, Size
  ];

  // todo: lowercase the members IAW dart-style guidelines (atm of porting this file, it crashed the analyzer, bad ... so, we have to do it later)

  /// Value indicating no day of the week; this will never be returned
  /// by any IsoDayOfWeek property, and is not valid as an argument to
  /// any method.
  static const CalendarOrdinal Iso = const CalendarOrdinal(0);
  static const CalendarOrdinal Gregorian = const CalendarOrdinal(1);
  static const CalendarOrdinal Julian = const CalendarOrdinal(2);
  static const CalendarOrdinal Coptic = const CalendarOrdinal(3);
  static const CalendarOrdinal HebrewCivil = const CalendarOrdinal(4);
  static const CalendarOrdinal HebrewScriptural = const CalendarOrdinal(5);
  static const CalendarOrdinal PersianSimple = const CalendarOrdinal(6);
  static const CalendarOrdinal PersianArithmetic = const CalendarOrdinal(7);
  static const CalendarOrdinal PersianAstronomical = const CalendarOrdinal(8);
  static const CalendarOrdinal IslamicAstronomicalBase15 = const CalendarOrdinal(9);
  static const CalendarOrdinal IslamicAstronomicalBase16 = const CalendarOrdinal(10);
  static const CalendarOrdinal IslamicAstronomicalIndian = const CalendarOrdinal(11);
  static const CalendarOrdinal IslamicAstronomicalHabashAlHasib = const CalendarOrdinal(12);
  static const CalendarOrdinal IslamicCivilBase15 = const CalendarOrdinal(13);
  static const CalendarOrdinal IslamicCivilBase16 = const CalendarOrdinal(14);
  static const CalendarOrdinal IslamicCivilIndian = const CalendarOrdinal(15);
  static const CalendarOrdinal IslamicCivilHabashAlHasib = const CalendarOrdinal(16);
  static const CalendarOrdinal UmAlQura = const CalendarOrdinal(17);
  static const CalendarOrdinal Wondrous = const CalendarOrdinal(18);
  // Not a real ordinal; just present to keep a count. Increase this as the number increases...
  static const CalendarOrdinal Size = const CalendarOrdinal(19);

  const CalendarOrdinal(this._value);

  @override get hashCode => _value.hashCode;
  @override operator ==(dynamic other) => other is CalendarOrdinal && other._value == _value || other is int && other == _value;

  bool operator <(CalendarOrdinal other) => _value < other._value;
  bool operator <=(CalendarOrdinal other) => _value <= other._value;
  bool operator >(CalendarOrdinal other) => _value > other._value;
  bool operator >=(CalendarOrdinal other) => _value >= other._value;

  int operator -(CalendarOrdinal other) => _value - other._value;
  int operator +(CalendarOrdinal other) => _value + other._value;

  @override
  String toString() => _stringRepresentations[_value] ?? 'undefined';

  CalendarOrdinal parse(String text) {
    var token = text.trim().toLowerCase();
    for (int i = 0; i < _stringRepresentations.length; i++) {
      if (stringOrdinalIgnoreCaseEquals(_stringRepresentations[i], token)) return _enumConstants[i];
    }

    return null;
  }
}