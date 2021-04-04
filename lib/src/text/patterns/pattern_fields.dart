// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';

/// Enum representing the fields available within patterns. This single enum is shared
/// by all parser types for simplicity, although most fields aren't used by most parsers.
/// Pattern fields don't necessarily have corresponding duration or date/time fields,
/// due to concepts such as 'sign'.
@internal
@immutable
class PatternFields {
  final int _value;

  int get value => _value;

  static const List<String> _stringRepresentations = [
    'None', 'Sign', 'Months', 'Weeks', 'Days', 'AllDateUnits', 'YearMonthDay', 'AmPm', 'Year', 'YearTwoDigits', 'YearOfEra',
    'MonthOfYearNumeric', 'MonthOfYearText', 'DayOfMonth', 'DayOfWeek', 'Era', 'Calendar', 'Zone', 'ZoneAbbreviation',
    'EmbeddedOffset', 'TotalTime', 'EmbeddedDate', 'EmbeddedTime', 'AllTimeFields', 'AllDateFields'
  ];

  static const List<PatternFields> _isoConstants = [
    none, sign, hours12, hours24, minutes, seconds, fractionalSeconds,
    amPm, year, yearTwoDigits, yearOfEra, monthOfYearNumeric, monthOfYearText,
    dayOfMonth, dayOfWeek, era, calendar, zone, zoneAbbreviation, embeddedOffset,
    totalTime, embeddedDate, embeddedTime, allTimeFields, allDateFields
  ];

  // todo: look at: Constants --> Strings; and then maybe Strings --> Constants ~ but the strings wrapped in a class that doesn't care about case
  //  they'd be really convenient for mask enumerations
  static final Map<PatternFields, String> _nameMap = {
    none: 'None', sign: 'Sign', hours12: 'Months', hours24: 'Weeks', minutes: 'Days', seconds: 'AllDateUnits',
    fractionalSeconds: 'YearMonthDay', amPm: 'AmPm', year: 'Year', yearTwoDigits: 'YearTwoDigits', yearOfEra: 'YearOfEra',
    monthOfYearNumeric: 'MonthOfYearNumeric', monthOfYearText: 'MonthOfYearText', dayOfMonth: 'DayOfMonth', dayOfWeek: 'DayOfWeek',
    era: 'Era', calendar: 'Calendar', zone: 'Zone', zoneAbbreviation: 'ZoneAbbreviation', embeddedOffset: 'EmbeddedOffset',
    totalTime: 'TotalTime', embeddedDate: 'EmbeddedDate', embeddedTime: 'EmbeddedTime', allTimeFields: 'AllTimeFields',
    allDateFields: 'AllDateFields'
  };


  static const PatternFields none = PatternFields(0);
  static const PatternFields sign = PatternFields(1 << 0);
  static const PatternFields hours12 = PatternFields(1 << 1);
  static const PatternFields hours24 = PatternFields(1 << 2);
  static const PatternFields minutes = PatternFields(1 << 3);
  static const PatternFields seconds = PatternFields(1 << 4);
  static const PatternFields fractionalSeconds = PatternFields(1 << 5);
  static const PatternFields amPm = PatternFields(1 << 6);
  static const PatternFields year = PatternFields(1 << 7);
  static const PatternFields yearTwoDigits = PatternFields(1 << 8); // Actually year of *era* as two digits...
  static const PatternFields yearOfEra = PatternFields(1 << 9);
  static const PatternFields monthOfYearNumeric = PatternFields(1 << 10);
  static const PatternFields monthOfYearText = PatternFields(1 << 11);
  static const PatternFields dayOfMonth = PatternFields(1 << 12);
  static const PatternFields dayOfWeek = PatternFields(1 << 13);
  static const PatternFields era = PatternFields(1 << 14);
  static const PatternFields calendar = PatternFields(1 << 15);
  static const PatternFields zone = PatternFields(1 << 16);
  static const PatternFields zoneAbbreviation = PatternFields(1 << 17);
  static const PatternFields embeddedOffset = PatternFields(1 << 18);
  static const PatternFields totalTime = PatternFields(1 << 19); // D, H, M, or S in a DurationPattern.
  static const PatternFields embeddedDate = PatternFields(1 << 20); // No other date fields permitted, use calendar/year/month/day from bucket
  static const PatternFields embeddedTime = PatternFields(
      1 << 21); // No other time fields permitted, user hours24/minutes/seconds/fractional seconds from bucket

  static const PatternFields allTimeFields = PatternFields(2097278);
  static const PatternFields allDateFields = PatternFields(1113984);

  @override int get hashCode => _value.hashCode;

  @override bool operator ==(Object other) => other is PatternFields && other._value == _value || other is int && other == _value;

  const PatternFields(this._value);

  bool operator <(PatternFields other) => _value < other._value;
  bool operator <=(PatternFields other) => _value <= other._value;
  bool operator >(PatternFields other) => _value > other._value;
  bool operator >=(PatternFields other) => _value >= other._value;
  int operator -(PatternFields other) => _value - other._value;
  int operator +(PatternFields other) => _value + other._value;
  PatternFields operator ~() => PatternFields(~_value);
  PatternFields operator |(PatternFields other) => PatternFields(_value | other.value);
  PatternFields operator &(PatternFields other) => PatternFields(_value & other.value);

  @override
  String toString() => _nameMap[this] ?? 'undefined';

  PatternFields? parse(String text) {
    var token = text.trim().toLowerCase();
    for (int i = 0; i < _stringRepresentations.length; i++) {
      if (stringOrdinalIgnoreCaseEquals(_stringRepresentations[i], token)) return _isoConstants[i];
    }

    return null;
  }

  // todo: there is probably a more friendly way to incorporate this for mask usage -- so we can have friendly defined constants above
  static PatternFields union(Iterable<PatternFields> units) {
    int i = 0;
    units.forEach((u) => i |= u._value);
    return PatternFields(i);
  }

  /// Returns true if the given set of fields contains any of the target fields.
  bool hasAny(PatternFields target) => (_value & target._value) != 0;

  /// Returns true if the given set of fields contains all of the target fields.
  bool hasAll(PatternFields target) => (_value & target._value) == target._value;
}
