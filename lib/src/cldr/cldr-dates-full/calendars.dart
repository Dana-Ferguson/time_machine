import 'dart:collection';

import 'package:meta/meta.dart';

import 'package:time_machine/time_machine_cldr.dart';
import 'package:time_machine/time_machine.dart';

/*
<!ELEMENT days ( alias | (dayContext*, special*)) >
<!ELEMENT dayContext ( alias | (default*, dayWidth*, special*)) >
<!ATTLIST dayContext type ( format | stand-alone ) #REQUIRED >
<!ELEMENT dayWidth ( alias | (day*, special*)) >
<!ATTLIST dayWidth type NMTOKEN #REQUIRED >
<!ELEMENT day ( #PCDATA ) >
<!ATTLIST day type ( sun | mon | tue | wed | thu | fri | sat ) #REQUIRED >
*/

@immutable
class DaysContext {
  final Map<IsoDayOfWeek, String> abbreviated;
  final Map<IsoDayOfWeek, String> narrow;
  final Map<IsoDayOfWeek, String> short;
  final Map<IsoDayOfWeek, String> wide;

  static const Map<String, IsoDayOfWeek> key2Iso = const {
    'sun': IsoDayOfWeek.sunday,
    'mon': IsoDayOfWeek.monday,
    'tue': IsoDayOfWeek.tuesday,
    'wed': IsoDayOfWeek.wednesday,
    'thu': IsoDayOfWeek.thursday,
    'fri': IsoDayOfWeek.friday,
    'sat': IsoDayOfWeek.saturday
  };

  DaysContext._(this.abbreviated, this.narrow, this.short, this.wide);

  factory DaysContext(Map<String, dynamic> json) {
    Map<IsoDayOfWeek, String> abbreviated = {}, narrow = {}, short = {}, wide = {};
    Map<IsoDayOfWeek, String> focus = null;

    json.forEach((String key, dynamic value) {
      switch(key) {
        case 'abbreviated': focus = abbreviated; break;
        case 'narrow': focus = narrow; break;
        case 'short': focus = short; break;
        case 'wide': focus = wide; break;
        default: throw new StateError('$key is unknown.');
      }

      (value as Map<String, dynamic>).forEach((String daysKey, dynamic monthValue) {
        var isoKey = key2Iso[daysKey];
        focus[isoKey] = monthValue;
      });
    });

    return new DaysContext._(abbreviated, narrow, short, wide);
  }
}

@immutable
class CalendarDays {
  final DaysContext format;
  final DaysContext stand_alone;

  CalendarDays._(this.format, this.stand_alone);

  factory CalendarDays(Map<String, dynamic> json) {
    DaysContext format;
    DaysContext stand_alone;

    json.forEach((String key, dynamic value) {
      switch (key) {
        case 'format': format = new DaysContext(value); break;
        case 'stand-alone': stand_alone = new DaysContext(value); break;
        default: throw new StateError('$key is unknown.');
      }
    });

    return new CalendarDays._(format, stand_alone);
  }
}


/*
<!ELEMENT months ( alias | (monthContext*, special*)) >
<!ELEMENT monthContext ( alias | (default*, monthWidth*, special*)) >
<!ATTLIST monthContext type ( format | stand-alone ) #REQUIRED >
<!ELEMENT monthWidth ( alias | (month*, special*)) >
<!ATTLIST monthWidth type ( abbreviated| narrow | wide) #REQUIRED >
<!ELEMENT month ( #PCDATA )* >
<!ATTLIST month type ( 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 ) #REQUIRED >
<!ATTLIST month yeartype ( standard | leap ) #IMPLIED >
*/

enum MonthContext {
  format,
  stand_alone
}

enum MonthWidthType {
  abbreviated,
  narrow,
  wide
}

@immutable
class CalendarContext {
  final Map<int, String> abbreviated;
  final Map<int, String> narrow;
  final Map<int, String> wide;

  CalendarContext._(this.abbreviated, this.narrow, this.wide);

  factory CalendarContext(Map<String, dynamic> json) {
    Map<int, String> abbreviated = {};
    Map<int, String> narrow = {};
    Map<int, String> wide = {};

    Map<int, String> focus = null;

    json.forEach((String key, dynamic value) {
      switch(key) {
        case 'abbreviated': focus = abbreviated; break;
        case 'narrow': focus = narrow; break;
        case 'wide': focus = wide; break;
        default: throw new StateError('$key is unknown.');
      }

      (value as Map<String, dynamic>).forEach((String monthKey, dynamic monthValue) {
        var monthNumber = int.parse(monthKey);
        focus[monthNumber] = monthValue;
      });
    });

    return new CalendarContext._(abbreviated, narrow, wide);
  }
}

@immutable
class CalendarMonths {
  final CalendarContext format;
  final CalendarContext stand_alone;

  CalendarMonths._(this.format, this.stand_alone);

  factory CalendarMonths(Map<String, dynamic> json) {
    CalendarContext format;
    CalendarContext stand_alone;

    json.forEach((String key, dynamic value) {
      switch (key) {
        case 'format': format = new CalendarContext(value); break;
        case 'stand-alone': stand_alone = new CalendarContext(value); break;
        default: throw new StateError('$key is unknown.');
      }
    });

    return new CalendarMonths._(format, stand_alone);
  }
}

// months?, monthPatterns?, days?, quarters?, dayPeriods?, eras?, cyclicNameSets?, dateFormats?, timeFormats?, dateTimeFormats?, special*
// http://unicode.org/reports/tr35/tr35-dates.html#Calendar_Elements
@immutable
class CalendarElements {
  final String id;
  final CldrIdentity identity;

  final Map<DateFieldType, DateFieldVariants> fields;

  CalendarElements._(this.id, this.identity, this.fields);

  /// calendarType = 'gregorian' \\ 'generic' \\ others based on the id?
  factory CalendarElements(String id, String calendarType, Map<String, dynamic> json) {
    var main = json['main'];
    assertTotalItems(main.keys, 1);

    var locale = main[id];
    assertTotalItems(locale.keys, 2);

    var identity = new CldrIdentity(locale['identity']);
    Map<String, dynamic> elementsJson = locale['dates']['calendars'][calendarType];


    Map<DateFieldType, DateFieldVariantsBuilder> fields = {};
    elementsJson.forEach((String key, dynamic json) {
      var tokens = key.split('-');
      var fieldVariant = tokens.length == 1 ? DateFieldVariant.normal : DateFieldVariants.dateFieldVariantsStringToEnum[tokens[1]];
      var fieldType = DateField.DateFieldTypeStringToEnum[tokens[0]];

      var builder = fields[fieldType] ?? (fields[fieldType] = new DateFieldVariantsBuilder(fieldType));
      builder[fieldVariant] = new DateField(fieldType, fieldVariant, json);
    });

    Map<DateFieldType, DateFieldVariants> builtFields = {};
    fields.forEach((DateFieldType key, DateFieldVariantsBuilder builder) {
      builtFields[key] = builder.build();
    });

    return new DateFields._(id, identity, new Map<DateFieldType, DateFieldVariants>.unmodifiable(builtFields));
  }
}