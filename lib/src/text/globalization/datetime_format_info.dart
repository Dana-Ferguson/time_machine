// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'package:meta/meta.dart';

// todo: evaluate name, need, and should this be combined with something else?
enum CalendarType {
  unknown,
  gregorian,
  persian,
  hijri,
  umAlQura
}

@immutable
class DateTimeFormat {
  final String amDesignator;
  final String pmDesignator;

  final String timeSeparator;
  final String dateSeparator;

  final List<String> abbreviatedDayNames;
  final List<String> dayNames;
  final List<String> monthNames;
  final List<String> abbreviatedMonthNames;
  final List<String> monthGenitiveNames;
  final List<String> abbreviatedMonthGenitiveNames;

  // todo: convert to non-BCL or remove?
  // BCL Calendar Class
  final CalendarType calendar;

  final List<String> eraNames;
  String getEraName(int era) {
    if (era == 0) throw UnimplementedError('Calendar.CurrentEraValue not implemented.');
    if (--era < eraNames.length && era >= 0) return eraNames[era];
    throw ArgumentError.value(era, 'era');
  }

  final String fullDateTimePattern;
  final String shortDatePattern;
  final String longDatePattern;
  final String shortTimePattern;
  final String longTimePattern;

  factory DateTimeFormat.invariantCulture() => DateTimeFormatBuilder.invariant().Build();

  const DateTimeFormat(
      this.amDesignator,
      this.pmDesignator,
      this.timeSeparator,
      this.dateSeparator,
      this.abbreviatedDayNames,
      this.dayNames,
      this.monthNames,
      this.abbreviatedMonthNames,
      this.monthGenitiveNames,
      this.abbreviatedMonthGenitiveNames,
      this.calendar,
      this.eraNames,
      this.fullDateTimePattern,
      this.shortDatePattern,
      this.longDatePattern,
      this.shortTimePattern,
      this.longTimePattern
      );
}

class DateTimeFormatBuilder {
  late String amDesignator;
  late String pmDesignator;

  late String timeSeparator;
  late String dateSeparator;

  late List<String> abbreviatedDayNames;
  late List<String> dayNames;
  late List<String> monthNames;
  late List<String> abbreviatedMonthNames;
  late List<String> monthGenitiveNames;
  late List<String> abbreviatedMonthGenitiveNames;

  // BCL Calendar Class
  late CalendarType calendar;

  late List<String> eraNames;

  late String fullDateTimePattern;
  late String shortDatePattern;
  late String longDatePattern;
  late String shortTimePattern;
  late String longTimePattern;

  DateTimeFormat Build() =>
      DateTimeFormat(
          amDesignator,
          pmDesignator,
          timeSeparator,
          dateSeparator,
          abbreviatedDayNames,
          dayNames,
          monthNames,
          abbreviatedMonthNames,
          monthGenitiveNames,
          abbreviatedMonthGenitiveNames,
          calendar,
          eraNames,
          fullDateTimePattern,
          shortDatePattern,
          longDatePattern,
          shortTimePattern,
          longTimePattern);

  DateTimeFormatBuilder([DateTimeFormat? info]) {
    if (info == null) return;
    amDesignator = info.amDesignator;
    pmDesignator = info.pmDesignator;
    timeSeparator = info.timeSeparator;
    dateSeparator = info.dateSeparator;
    abbreviatedDayNames = info.abbreviatedDayNames;
    dayNames = info.dayNames;
    monthNames = info.monthNames;
    abbreviatedMonthNames = info.abbreviatedMonthNames;
    monthGenitiveNames = info.monthGenitiveNames;
    abbreviatedMonthGenitiveNames = info.abbreviatedMonthGenitiveNames;
    calendar = info.calendar;
    eraNames = info.eraNames;
    fullDateTimePattern = info.fullDateTimePattern;
    shortDatePattern = info.shortDatePattern;
    longDatePattern = info.longDatePattern;
    shortTimePattern = info.shortTimePattern;
    longTimePattern = info.longTimePattern;
  }

  // Month's have a blank entry at the end
  static const List<String> _invariantMonthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', ''];
  static const List<String> _invariantAbbreviatedMonthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', ''];

  DateTimeFormatBuilder.invariant()
      : amDesignator = 'AM',
        pmDesignator = 'PM',
        timeSeparator = ':',
        dateSeparator = '/',
        abbreviatedDayNames = const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
        dayNames = const ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
        monthNames = _invariantMonthNames,
        abbreviatedMonthNames = _invariantAbbreviatedMonthNames,
        monthGenitiveNames = _invariantMonthNames,
        abbreviatedMonthGenitiveNames = _invariantAbbreviatedMonthNames,
        calendar = CalendarType.gregorian,
        eraNames = const ['A.D.'],
        fullDateTimePattern = 'dddd, dd MMMM yyyy HH:mm:ss',
        shortDatePattern = 'MM/dd/yyyy',
        longDatePattern = 'dddd, dd MMMM yyyy',
        shortTimePattern = 'HH:mm',
        longTimePattern = 'HH:mm:ss'
  ;
}
