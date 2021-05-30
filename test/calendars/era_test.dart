// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
// todo: this affects JS_Test_Gen
import 'dart:mirrors';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import '../time_machine_testing.dart';

Future main() async {
  var eraType = reflectType(Era) as ClassMirror;
  Eras = eraType
      .declarations
      .values
      .where((v) => v is VariableMirror && v.isStatic)
      .map((v) => eraType.getField(v.simpleName).reflectee)
      .toList()
      .cast();

  await runTests();
}

List<Era> Eras = []; /*typeof(Era).GetTypeInfo()
    .DeclaredProperties // TODO: Only static and ones...
    .Where(property => property.PropertyType == typeof(Era))
.Select(property => property.GetValue(null, null))
.Cast<Era>();*/

@TestCaseSource(#Eras)
@Test() @SkipMe.unimplemented()
void ResourcePresence(Era? era)
{
  // todo: get us resources?
  var valueByName; // PatternResources.ResourceManager.GetString(era.ResourceIdentifier, Culture.invariantCulture);
  expect(valueByName, isNotNull, reason: 'Missing resource for ' + (era != null ? IEra.resourceIdentifier(era) : 'null'));
}

