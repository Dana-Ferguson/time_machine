import 'dart:async';
import 'dart:convert';

import 'package:time_machine/src/cldr/cldr_loader.dart';

Future main() async {
  try {
    var dtz = await getDateTimeZoneNames('en-US-POSIX');
    print(dtz.exemplarCities.cities.length);

    var dfs = await getDateFields('en-US-POSIX');
    print(dfs.fields);
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
