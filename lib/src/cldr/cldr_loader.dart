import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'dart:collection';

import 'package:meta/meta.dart';

// I think importing the files here, and then only exporting this file *might* be the right move here
// -- let's keep it as clean as we can and look at what we have when we're done.
import 'cldr-dates-full/timezone_names.dart';
import 'cldr-dates-full/date_fields.dart';

// I'm thinking of doing something like: cldr_io.dart and cldr_http.dart --> and then build a transformer that
// will rewrite all *_io.dart references to *_http.dart references
// *** can I extend this to deal with Duration's different implementations (maybe an *_vm to *_js mapping as well?)
// *** at the least, I can make the 'isDartVM check' not a function, but just a compile time constant

/*

  cldr-dates-full --> ca-generic, ca-gregorian, dateFields, timeZoneNames
  cldr-localenames-full --> languages, localDisplayNames, scripts, territories, variants
  cldr-misc-full --> characters, contextTransformations, delimiters, layout, listPatterns, posix
  cldr-numbers-full --> currencies, numbers

 */

// todo: I need some sort of warning so that I know if there is information in this structure that I'm not absorbing
//  ??? validation check ???

// ** This is also grab-able from the JSON
const String cldrVersion = '32.0.1';
// todo: make this a datetime of some sort (local, zoned, or instant?)
const String cldrPublishDate = '2017-12-08';

Future getJson(String path) async {
  // Keep as much as the repeated path arguments in here as possible
  var file = new File('${Directory.current.path}/lib/data/cldr/$path');
  return JSON.decode(await file.readAsString());
}

Future loadDatesTimeZoneNamesJson(String id) {
  return getJson('cldr-dates-full/main/$id/timeZoneNames.json');
}

Future loadDateFieldsJson(String id) {
  return getJson('cldr-dates-full/main/$id/dateFields.json');
}

// todo: need to create a good naming scheme and classify things
Future<DateTimeZoneNames> getDateTimeZoneNames(String id) async {
  var json = await loadDatesTimeZoneNamesJson(id);
  var dtzNames = new DateTimeZoneNames(id, json);
  return dtzNames;
}

Future<DateFields> getDateFields(String id) async {
  var json = await loadDateFieldsJson(id);
  var dateFields = new DateFields(id, json);
  return dateFields;
}

int getTotalListItems(Iterable items) {
  int total = 0;
  for(var value in items) {
    if (value is List) total += getTotalListItems(value);
    else if (value is Map) total += getTotalMapItems(value);
    else {
      total++;
    }
  }
  return total;
}

int getTotalMapItems(Map<String, dynamic> json) {
  int total = 0;
  total = getTotalListItems(json.values);
  return total;
}

int getTotalItems(dynamic item) {
  if (item is Map) return getTotalItems(item.values);
  if (item is Iterable) return getTotalListItems(item);
  return 1;
}

void assertTotalItems(dynamic item, int expected) {
  var actual = getTotalItems(item);
  if (actual != expected) {
    // AssertionError accepts a message it doesn't print. It's weird.
    throw new StateError('Actual: $actual != Expected: $expected\nItem = $item');
  }
}

void assertItemsCount(dynamic item, bool Function(int) test) {
  var actual = getTotalItems(item);
  if (!test(actual)) {
    throw new StateError('Actual: $actual -- Test failed!');
  }
}

@immutable
class CldrIdentity {
  // todo: make this an integer is it will always follow an integer pattern
  final String revision;
  final int version;
  final String language;
  final String territory;
  final String variant;

  CldrIdentity.from(this.revision, this.version, this.language, this.territory, this.variant);
  factory CldrIdentity(Map<String, dynamic> json) {
    print (json);
    assertTotalItems(json, 5);
    var revision = json['version']['_number'];
    var version = int.parse(json['version']['_cldrVersion']);
    var language = json['language'];
    var territory = json['territory'];
    var variant = json['variant'];
    return new CldrIdentity.from(revision, version, language, territory, variant);
  }
}

