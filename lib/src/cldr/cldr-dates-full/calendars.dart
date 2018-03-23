import 'dart:collection';

import 'package:meta/meta.dart';

import 'package:time_machine/time_machine_cldr.dart';
import 'package:time_machine/time_machine.dart';

@immutable
class IntervalFormats {
  final String fallback;
  final Map<String, Map<String, String>> formats;

  IntervalFormats._(this.fallback, this.formats);

  factory IntervalFormats(Map<String, dynamic> json) {
    String fallback;
    Map<String, Map<String, String>> formats = {};

    json.forEach((String key, dynamic value) {
      if (key == 'intervalFormatFallback') {
        fallback = value;
      } else {
        Map<String, String> _formats = {};
        (value as Map<String, dynamic>).forEach((String _key, dynamic _value) {
          _formats[_key] = _value;
        });
        formats[key] = new Map<String, String>.unmodifiable(_formats);
      }
    });

    return new IntervalFormats._(fallback, new Map<String, Map<String, String>>.unmodifiable(formats));
  }
}

enum AppendItemKeys {
  day,
  dayOfWeek,
  era,
  hour,
  minute,
  month,
  quarter,
  second,
  timezone,
  week,
  year
}

@immutable
class DateTimeFormats {
  final String full;
  final String long;
  final String medium;
  final String short;
  final Map<String, String> availableFormats;
  final Map<AppendItemKeys, String> appendItems;
  final IntervalFormats intervalFormats;

  static const Map<String, AppendItemKeys> key2AppendItemKey = const {
    'Day': AppendItemKeys.day,
    'Day-Of-Week': AppendItemKeys.dayOfWeek,
    'Era': AppendItemKeys.era,
    'Hour': AppendItemKeys.hour,
    'Minute': AppendItemKeys.minute,
    'Month': AppendItemKeys.month,
    'Quarter': AppendItemKeys.quarter,
    'Second': AppendItemKeys.second,
    'Timezone': AppendItemKeys.timezone,
    'Week': AppendItemKeys.week,
    'Year': AppendItemKeys.year,
  };

  DateTimeFormats._(this.full, this.long, this.medium, this.short,
      this.availableFormats, this.appendItems, this.intervalFormats);

  factory DateTimeFormats(Map<String, dynamic> json) {
    String full, long, medium, short;
    Map<String, String> availableFormats = {};
    Map<AppendItemKeys, String> appendItems = {};
    IntervalFormats intervalFormats;

    json.forEach((String key, dynamic value) {
      switch (key) {
        case 'full': full = value; break;
        case 'long': long = value; break;
        case 'medium': medium = value; break;
        case 'short': short = value; break;
        case 'availableFormats':
          (value as Map<String, dynamic>).forEach((String _key, dynamic _value) {
            availableFormats[_key] = _value;
          });
          break;
        case 'appendItems':
          (value as Map<String, dynamic>).forEach((String _key, dynamic _value) {
            var itemKey = key2AppendItemKey[_key];
            appendItems[itemKey] = _value;
          });
          break;
        case 'intervalFormats':
          intervalFormats = new IntervalFormats(value);
          break;
        default:
          throw new StateError('$key is unknown.');
      }
    });

    return new DateTimeFormats._(full, long, medium, short, availableFormats, appendItems, intervalFormats);
  }
}

// http://unicode.org/reports/tr35/tr35-dates.html#dateFormats
/*
<!ELEMENT dateFormats (alias | (default*, dateFormatLength*, special*)) >
<!ELEMENT dateFormatLength (alias | (default*, dateFormat*, special*)) >
<!ATTLIST dateFormatLength type ( full | long | medium | short ) #REQUIRED >
<!ELEMENT dateFormat (alias | (pattern*, displayName*, special*)) >
*/

@immutable
class TimeFormats {
  final String full;
  final String long;
  final String medium;
  final String short;

  TimeFormats._(this.full, this.long, this.medium, this.short);

  factory TimeFormats(Map<String, dynamic> json) {
    String full, long, medium, short;

    json.forEach((String key, dynamic value) {
      switch (key) {
        case 'full': full = value; break;
        case 'long': long = value; break;
        case 'medium': medium = value; break;
        case 'short': short = value; break;
        default:
          throw new StateError('$key is unknown.');
      }
    });

    return new TimeFormats._(full, long, medium, short);
  }
}


@immutable
class DateFormats {
  final String full;
  final String long;
  final String medium;
  final String short;

  DateFormats._(this.full, this.long, this.medium, this.short);

  factory DateFormats(Map<String, dynamic> json) {
    String full, long, medium, short;

    json.forEach((String key, dynamic value) {
      switch (key) {
        case 'full': full = value; break;
        case 'long': long = value; break;
        case 'medium': medium = value; break;
        case 'short': short = value; break;
        default:
          throw new StateError('$key is unknown.');
      }
    });

    return new DateFormats._(full, long, medium, short);
  }
}

/*
<!ELEMENT eras (alias | (eraNames?, eraAbbr?, eraNarrow?, special*)) >
<!ELEMENT eraNames ( alias | (era*, special*) ) >
<!ELEMENT eraAbbr ( alias | (era*, special*) ) >
<!ELEMENT eraNarrow ( alias | (era*, special*) ) >
*/

@immutable
class CalendarEras {
  final Map<int, String> eraNames;
  final Map<int, String> eraNamesAltVariant;
  final Map<int, String> eraAbbr;
  final Map<int, String> eraAbbrAltVariant;
  final Map<int, String> eraNarrow;
  final Map<int, String> eraNarrowAltVariant;

  CalendarEras._(this.eraNames, this.eraNamesAltVariant,
      this.eraAbbr, this.eraAbbrAltVariant,
      this.eraNarrow, this.eraNarrowAltVariant);

  factory CalendarEras(Map<String, dynamic> json) {
    Map<int, String> eraNames = {}, eraNamesAltVariant = {},
        eraAbbr = {}, eraAbbrAltVariant = {},
        eraNarrow = {}, eraNarrowAltVariant = {},
        focus, focusAltVariant;

    json.forEach((String key, dynamic value) {
      switch(key) {
        case 'eraNames': focus = eraNames; focusAltVariant = eraNamesAltVariant; break;
        case 'eraAbbr': focus = eraAbbr; focusAltVariant = eraAbbrAltVariant; break;
        case 'eraNarrow': focus = eraNarrow; focusAltVariant = eraNarrowAltVariant; break;
        default: throw new StateError('$key is unknown.');
      }

      (value as Map<String, dynamic>).forEach((String _key, dynamic _value) {
        if (key.endsWith("-alt-variant")) {
          // todo: micro-optimize
          var n = int.parse(_key.split('-').first);
          focusAltVariant[n] = _value;
        }
        else {
          var n = int.parse(_key);
          focus[n] = _value;
        }
      });
    });

    return new CalendarEras._(eraNames, eraNamesAltVariant,
        eraAbbr, eraAbbrAltVariant,
        eraNarrow, eraNarrowAltVariant);
  }
}

// am, pm, midnight, noon (midnight and noon are optional)
// afternoon, evening, morning, night + integer(starting at 1, counting upward for more rules, no more than 2);

/*
<!ELEMENT dayPeriods ( alias | (dayPeriodContext*) ) >

<!ELEMENT dayPeriodContext (alias | dayPeriodWidth*) >
<!ATTLIST dayPeriodContext type NMTOKEN #REQUIRED >

<!ELEMENT dayPeriodWidth (alias | dayPeriod*) >
<!ATTLIST dayPeriodWidth type NMTOKEN #REQUIRED >

<!ELEMENT dayPeriod ( #PCDATA ) >
<!ATTLIST dayPeriod type NMTOKEN #REQUIRED >
*/

// todo: Optimal Name?
enum DayPeriodsFieldType {
  am, pm, amAltVariant, pmAltVariant,
  midnight, noon,
  afternoon1, afternoon2,
  evening1, evening2,
  morning1, morning2,
  night1, night2
}

@immutable
class DayPeriodsContext {
  final Map<DayPeriodsFieldType, String> abbreviated;
  final Map<DayPeriodsFieldType, String> narrow;
  final Map<DayPeriodsFieldType, String> wide;

  static const Map<String, DayPeriodsFieldType> key2DPFT = const {
    'am': DayPeriodsFieldType.am,
    'am-alt-variant': DayPeriodsFieldType.amAltVariant,
    'pm': DayPeriodsFieldType.pm,
    'pm-alt-variant': DayPeriodsFieldType.pmAltVariant,
    'midnight': DayPeriodsFieldType.midnight,
    'noon': DayPeriodsFieldType.noon,
    'afternoon1': DayPeriodsFieldType.afternoon1,
    'afternoon2': DayPeriodsFieldType.afternoon2,
    'evening1': DayPeriodsFieldType.evening1,
    'evening2': DayPeriodsFieldType.evening2,
    'morning1': DayPeriodsFieldType.morning1,
    'morning2': DayPeriodsFieldType.morning2,
    'night1': DayPeriodsFieldType.night1,
    'night2': DayPeriodsFieldType.night2,
  };

  DayPeriodsContext._(this.abbreviated, this.narrow, this.wide);

  factory DayPeriodsContext(Map<String, dynamic> json) {
    Map<DayPeriodsFieldType, String> abbreviated = {}, narrow = {}, wide = {};
    Map<DayPeriodsFieldType, String> focus = null;

    json.forEach((String key, dynamic value) {
      switch(key) {
        case 'abbreviated': focus = abbreviated; break;
        case 'narrow': focus = narrow; break;
        case 'wide': focus = wide; break;
        default: throw new StateError('$key is unknown.');
      }

      (value as Map<String, dynamic>).forEach((String _key, dynamic _value) {
        var dpft =key2DPFT[_key];
        focus[dpft] = _value;
      });
    });

    return new DayPeriodsContext._(abbreviated, narrow, wide);
  }
}

@immutable
class CalendarDayPeriods {
  final DayPeriodsContext format;
  final DayPeriodsContext stand_alone;

  CalendarDayPeriods._(this.format, this.stand_alone);

  factory CalendarDayPeriods(Map<String, dynamic> json) {
    DayPeriodsContext format;
    DayPeriodsContext stand_alone;

    json.forEach((String key, dynamic value) {
      switch (key) {
        case 'format': format = new DayPeriodsContext(value); break;
        case 'stand-alone': stand_alone = new DayPeriodsContext(value); break;
        default: throw new StateError('$key is unknown.');
      }
    });

    return new CalendarDayPeriods._(format, stand_alone);
  }
}


/*
<!ELEMENT quarters ( alias | (quarterContext*, special*)) >
<!ELEMENT quarterContext ( alias | (default*, quarterWidth*, special*)) >
<!ATTLIST quarterContext type ( format | stand-alone ) #REQUIRED >
<!ELEMENT quarterWidth ( alias | (quarter*, special*)) >
<!ATTLIST quarterWidth type NMTOKEN #REQUIRED >
<!ELEMENT quarter ( #PCDATA ) >
<!ATTLIST quarter type ( 1 | 2 | 3 | 4 ) #REQUIRED >
*/


@immutable
class QuartersContext {
  final Map<int, String> abbreviated;
  final Map<int, String> narrow;
  // final Map<int, String> short;
  final Map<int, String> wide;

  QuartersContext._(this.abbreviated, this.narrow, /*this.short,*/ this.wide);

  factory QuartersContext(Map<String, dynamic> json) {
    Map<int, String> abbreviated = {}, narrow = {}, wide = {};
    Map<int, String> focus = null;

    json.forEach((String key, dynamic value) {
      switch(key) {
        case 'abbreviated': focus = abbreviated; break;
        case 'narrow': focus = narrow; break;
        // case 'short': focus = short; break;
        case 'wide': focus = wide; break;
        default: throw new StateError('$key is unknown.');
      }

      (value as Map<String, dynamic>).forEach((String _key, dynamic _value) {
        var intKey = int.parse(_key);
        focus[intKey] = _value;
      });
    });

    return new QuartersContext._(abbreviated, narrow, wide);
  }
}

@immutable
class CalendarQuarters {
  final QuartersContext format;
  final QuartersContext stand_alone;

  CalendarQuarters._(this.format, this.stand_alone);

  factory CalendarQuarters(Map<String, dynamic> json) {
    QuartersContext format;
    QuartersContext stand_alone;

    json.forEach((String key, dynamic value) {
      switch (key) {
        case 'format': format = new QuartersContext(value); break;
        case 'stand-alone': stand_alone = new QuartersContext(value); break;
        default: throw new StateError('$key is unknown.');
      }
    });

    return new CalendarQuarters._(format, stand_alone);
  }
}


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

//enum MonthContext {
//  format,
//  stand_alone
//}
//
//enum MonthWidthType {
//  abbreviated,
//  narrow,
//  wide
//}

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

  final CalendarMonths months;
  final CalendarDays days;
  final CalendarQuarters quarters;
  final CalendarDayPeriods dayPeriods;
  final CalendarEras eras;
  final DateFormats dateFormats;
  final TimeFormats timeFormats;
  final DateTimeFormats dateTimeFormats;

  CalendarElements._(this.id, this.identity,
      this.months, this.days, this.quarters, this.dayPeriods, this.eras,
      this.dateFormats, this.timeFormats, this.dateTimeFormats);

  factory CalendarElements.gregorian(String id, Map<String, dynamic> json) {
    return new CalendarElements(id, 'gregorian', json);
  }

  factory CalendarElements.generic(String id, Map<String, dynamic> json) {
    return new CalendarElements(id, 'generic', json);
  }

  /// calendarType = 'gregorian' \\ 'generic' \\ others based on the id?
  factory CalendarElements(String id, String calendarType, Map<String, dynamic> json) {
    var main = json['main'];
    assertTotalItems(main.keys, 1);

    var locale = main[id];
    assertTotalItems(locale.keys, 2);

    var identity = new CldrIdentity(locale['identity']);
    Map<String, dynamic> elementsJson = locale['dates']['calendars'][calendarType];

    CalendarMonths months;
    CalendarDays days;
    CalendarQuarters quarters;
    CalendarDayPeriods dayPeriods;
    CalendarEras eras;
    DateFormats dateFormats;
    TimeFormats timeFormats;
    DateTimeFormats dateTimeFormats;

    elementsJson.forEach((String key, dynamic value) {
      switch(key) {
        case 'months': months = new CalendarMonths(value); break;
        case 'days': days = new CalendarDays(value); break;
        case 'quarters': quarters = new CalendarQuarters(value); break;
        case 'dayPeriods': dayPeriods = new CalendarDayPeriods(value); break;
        case 'eras': eras = new CalendarEras(value); break;
        case 'dateFormats': dateFormats = new DateFormats(value); break;
        case 'timeFormats': timeFormats = new TimeFormats(value); break;
        case 'dateTimeFormats': dateTimeFormats = new DateTimeFormats(value); break;
        default: throw new StateError('$key is unknown.');
      }
    });


    return new CalendarElements._(id, identity,
        months, days, quarters, dayPeriods, eras,
        dateFormats, timeFormats, dateTimeFormats);
  }
}