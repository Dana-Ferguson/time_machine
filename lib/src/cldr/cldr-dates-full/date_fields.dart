import 'dart:collection';

import 'package:meta/meta.dart';

import 'package:time_machine/time_machine_cldr.dart';

enum DateFieldDataType {
  relativeType,
  relativeTimeType,
  relativePeriod
}

enum DateFieldType {
  era, year, quarter, month, week,
  weekOfMonth, day, dayOfYear, weekday, weekdayOfMonth, sun, mon, tue,
  wed, thu, fri, sat, dayperiod, hour, minute, second, zone
}

// todo: Probably not a good class Name? (but does work with the JSON)
@immutable
class DateField {
  static const List<String> dateFieldTypesList = const ['era', 'year', 'quarter', 'month', 'week',
  'weekOfMonth', 'day', 'dayOfYear', 'weekday', 'weekdayOfMonth', 'sun', 'mon', 'tue',
  'wed', 'thu', 'fri', 'sat', 'dayperiod', 'hour', 'minute', 'second', 'zone'];
  static final HashSet<String> dateFieldTypes = new HashSet<String>.from(dateFieldTypesList);
  static const List<String> dateDataTypesList = const['relative-type', 'relativeTime-type', 'relativePeriod'];
  static const List<DateFieldDataType> dateDataTypesEnums =
  const[DateFieldDataType.relativeType, DateFieldDataType.relativeTimeType, DateFieldDataType.relativePeriod];

  static const Map<String, DateFieldType> DateFieldTypeStringToEnum = const {
    'era': DateFieldType.era,
    'year': DateFieldType.year,
    'quarter': DateFieldType.quarter,
    'month': DateFieldType.month,
    'week': DateFieldType.week,
    'weekOfMonth': DateFieldType.weekOfMonth,
    'day': DateFieldType.day,
    'dayOfYear': DateFieldType.dayOfYear,
    'weekday': DateFieldType.weekday,
    'weekdayOfMonth': DateFieldType.weekdayOfMonth,
    'sun': DateFieldType.sun,
    'mon': DateFieldType.mon,
    'tue': DateFieldType.tue,
    'wed': DateFieldType.wed,
    'thu': DateFieldType.thu,
    'fri': DateFieldType.fri,
    'sat': DateFieldType.sat,
    'dayperiod': DateFieldType.dayperiod,
    'hour': DateFieldType.hour,
    'minute': DateFieldType.minute,
    'second': DateFieldType.second,
    'zone': DateFieldType.zone
  };

  final String displayName;
  final String displayNameAltVariant;
  final DateFieldType dateFieldType;
  final DateFieldVariant dateFieldVariant;

  // final Map<DateFieldDataType, dynamic> data;
  final Map<int, DateFieldRelativeType> relatives;
  final Map<DateFieldRelativeTimeType, DateFieldRelativeTime> relativeTimes;
  final String relativePeriod;

  // data can be:
  // DateFieldRelativeType -- relative-type-[-1,0,1] ???
  // DateFieldRelativeTime -- relativeTime-type-[past, future]
  //                          * relativeTimePattern-count-[zero, one, two, few, many, other]
  // String -- relativePeriod

  DateField._(this.dateFieldType, this.dateFieldVariant, this.displayName, this.displayNameAltVariant,
      this.relatives, this.relativeTimes, this.relativePeriod);

  factory DateField(DateFieldType dateFieldType, DateFieldVariant dateFieldVariant, Map<String, dynamic> json) {
    String displayName = json['displayName'];
    String displayNameAltVariant = json['displayName-alt-variant'];

    Map<int, DateFieldRelativeType> relatives = {};
    Map<DateFieldRelativeTimeType, DateFieldRelativeTime> relativeTimes = {};
    String relativePeriod = null;

    json.forEach((String key, dynamic value) {
      var char = key[8];
      if (char == '-') {
        // relative-type
        int type = int.parse(key.substring(14));
        relatives[type] = new DateFieldRelativeType(type, value);
      } else if (char == 'T') {
        // relativeTime-type
        var type = DateFieldRelativeTime.relativeTypesStringToEnum[key.substring(18)];
        relativeTimes[type] = new DateFieldRelativeTime(type, value);
      } else if (char == 'P') {
        // relativePeriod
        relativePeriod = value;
      } else if (char == 'a' && (key == 'displayName' || key == 'displayName-alt-variant')) {
        // do nothing
      } else throw new StateError('$key for $value is unknown in ($dateFieldType, $dateFieldVariant, $json)');
    });

    return new DateField._(dateFieldType, dateFieldVariant, displayName, displayNameAltVariant,
        relatives, relativeTimes, relativePeriod);
  }
}

@immutable
class DateFieldRelativeType {
  final int type;
  final String text;

  DateFieldRelativeType(this.type, this.text);

  @override String toString() => 'DateFieldRelativeType: ($type, $text)';
}

enum DateFieldRelativeTimeCount {
  zero,
  one,
  two,
  few,
  many,
  other
}

enum DateFieldRelativeTimeType {
  future,
  past
}


// relativeTime-type-[past, future]
// relativeTimePattern-count-[zero, one, two, few, many, other]
@immutable
class DateFieldRelativeTime {
  // make these HashSets?
  static const List<String> relativeTypesList = const ['future', 'past'];
  static const List<String> countTypesList = const ['zero', 'one', 'two', 'few', 'many', 'other'];
  static final HashSet<String> countTypes = new HashSet<String>.from(countTypesList);
  static final HashSet<String> relativeTypes = new HashSet<String>.from(relativeTypesList);

  static const List<DateFieldRelativeTimeCount> countTypesEnum = const[DateFieldRelativeTimeCount.zero,
  DateFieldRelativeTimeCount.one, DateFieldRelativeTimeCount.two, DateFieldRelativeTimeCount.few,
  DateFieldRelativeTimeCount.many, DateFieldRelativeTimeCount.other];

  static const Map<String, DateFieldRelativeTimeCount> countTypesStringToEnum = const {
    'zero':  DateFieldRelativeTimeCount.zero,
    'one': DateFieldRelativeTimeCount.one,
    'two': DateFieldRelativeTimeCount.two,
    'few': DateFieldRelativeTimeCount.few,
    'many': DateFieldRelativeTimeCount.many,
    'other': DateFieldRelativeTimeCount.other
  };

  static const Map<String, DateFieldRelativeTimeType> relativeTypesStringToEnum = const {
    'future': DateFieldRelativeTimeType.future,
    'past': DateFieldRelativeTimeType.past
  };

  // future, past
  final DateFieldRelativeTimeType type;
  final Map<DateFieldRelativeTimeCount, String> patternCounts;

  DateFieldRelativeTime._(this.type, Map<DateFieldRelativeTimeCount, String> patternCounts) :
        patternCounts = new Map<DateFieldRelativeTimeCount, String>.unmodifiable(patternCounts)
  ;

  factory DateFieldRelativeTime(DateFieldRelativeTimeType type, Map<String, dynamic> json) {
    Map<DateFieldRelativeTimeCount, String> patternCounts = {};

    json.forEach((String key, dynamic value) {
      var countType = countTypesStringToEnum[key.substring(26)];
      patternCounts[countType] = value as String;
    });

    return new DateFieldRelativeTime._(type, patternCounts);
  }
}

enum DateFieldVariant {
  normal,
  short,
  narrow
}

@immutable
class DateFieldVariants {
  static const List<String> variantTypesList = const ['', 'short', 'narrow'];
  static final HashSet<String> variantTypes = new HashSet<String>.from(variantTypesList);

  static const Map<String, DateFieldVariant> dateFieldVariantsStringToEnum = const {
    '': DateFieldVariant.normal,
    'short': DateFieldVariant.short,
    'narrow': DateFieldVariant.narrow
  };

  final DateFieldType dateFieldType;

  // Just gonna list them out, instead of doing a Map<String or DateFieldVariant, DateField>;
  final DateField normal;
  final DateField short;
  final DateField narrow;

  DateFieldVariants(this.dateFieldType, this.normal, this.short, this.narrow);

  DateField operator[](DateFieldVariant variant) {
    switch(variant) {
      case DateFieldVariant.normal: return normal;
      case DateFieldVariant.short: return short;
      case DateFieldVariant.narrow: return narrow;
      default: throw new StateError('Variant $variant unknown for $dateFieldType.');
    }
  }
}

class DateFieldVariantsBuilder {
  final DateFieldType dateFieldType;
  DateField normal = null;
  DateField short = null;
  DateField narrow = null;

  DateFieldVariantsBuilder(this.dateFieldType);

  DateFieldVariants build() => new DateFieldVariants(dateFieldType, normal, short, narrow);

  operator[]=(DateFieldVariant variant, DateField dateField) {
    switch(variant) {
      case DateFieldVariant.normal: normal = dateField; break;
      case DateFieldVariant.short: short = dateField; break;
      case DateFieldVariant.narrow: narrow = dateField; break;
      default: throw new StateError('Variant $variant unknown for $dateField.');
    }
  }
}

// unicode.org/reports/tr35/tr35-dates.html
@immutable
class DateFields {
  final String id;
  final CldrIdentity identity;

  final Map<DateFieldType, DateFieldVariants> fields;

  DateFields._(this.id, this.identity, this.fields);

  factory DateFields(String id, Map<String, dynamic> json) {
    var main = json['main'];
    assertTotalItems(main.keys, 1);

    var locale = main[id];
    assertTotalItems(locale.keys, 2);

    var identity = new CldrIdentity(locale['identity']);
    Map<String, dynamic> fieldsJson = locale['dates']['fields'];

    Map<DateFieldType, DateFieldVariantsBuilder> fields = {};
    fieldsJson.forEach((String key, dynamic json) {
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