import 'dart:async';

import 'package:time_machine/time_machine.dart';
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_timezones.dart';

import '../time_machine_testing.dart';

Future main() async {
  await runTests();
}

@Test()
Future loadCultures() async
{
  var ids = await Cultures.ids;
  expect(ids.length, greaterThan(0));

  for (var id in ids) {
    var culture = await Cultures.getCulture(id);
    expect(culture.name, id);
  }
}