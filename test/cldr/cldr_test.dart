import 'dart:async';
import 'dart:convert';

import 'package:time_machine/src/cldr/cldr_loader.dart';
// todo: is there a better way to reference this?
import '../time_machine_testing.dart';

Future main() async {
  try {
    var id = 'en-US-POSIX';
    var dtz = await getDateTimeZoneNames(id);
    print(dtz.exemplarCities.cities.length);

    var dfs = await getDateFields(id);
    print(dfs.fields);

    var genericCalendar = await getGenericCalendar(id);
    var gregorianCalendar = await getGenericCalendar(id);

    print(genericCalendar);
    print(gregorianCalendar);
  }
  catch (e, s) {
    print ('$e\n$s');
  }
  // SpiderTest();
}

String json = '''
        {
          "zone": {
            "America": {
              "Adak": {
                "exemplarCity": "Adak"
              },
              "Anchorage": {
                "exemplarCity": "Anchorage"
              },
              "Anguilla": {
                "exemplarCity": "Anguilla"
              },
              "Antigua": {
                "exemplarCity": "Antigua"
              },
              "Araguaina": {
                "exemplarCity": "Araguaina"
              },
              "Argentina": {
                "Rio_Gallegos": {
                  "exemplarCity": "Rio Gallegos"
                },
                "San_Juan": {
                  "exemplarCity": "San Juan"
                },
                "Ushuaia": {
                  "exemplarCity": "Ushuaia"
                },
                "La_Rioja": {
                  "exemplarCity": "La Rioja"
                },
                "San_Luis": {
                  "exemplarCity": "San Luis"
                },
                "Salta": {
                  "exemplarCity": "Salta"
                },
                "Tucuman": {
                  "exemplarCity": "Tucuman"
                }
              }
            }
          }
        }

''';

void SpiderTest() {
  var _json = JSON.decode(json);
  print(_json);
  var map = new ExemplarCityMap(_json);
  print (map[['zone']]);
  print(map[['zone', 'America']]);
  print(map[['zone', 'America', 'Adak']]);
  print(map[['zone', 'America', 'Argentina']]);
  print(map[['zone', 'America', 'Argentina', 'San_Luis']]);
}
