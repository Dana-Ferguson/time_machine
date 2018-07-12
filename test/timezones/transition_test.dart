// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.


import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:test/test.dart';

import '../time_machine_testing.dart';

Future main() async {
  await runTests();
}

@Test()
void Equality() {
  var equal1 = new Transition(new Instant.fromUnixTimeSeconds(100), new Offset.fromHours(1));
  var equal2 = new Transition(new Instant.fromUnixTimeSeconds(100), new Offset.fromHours(1));
  var unequal1 = new Transition(new Instant.fromUnixTimeSeconds(101), new Offset.fromHours(1));
  var unequal2 = new Transition(new Instant.fromUnixTimeSeconds(100), new Offset.fromHours(2));
  TestHelper.TestEqualsStruct(equal1, equal2, [unequal1]);
  TestHelper.TestEqualsStruct(equal1, equal2, [unequal2]);
  TestHelper.TestOperatorEquality(equal1, equal2, unequal1);
  TestHelper.TestOperatorEquality(equal1, equal2, unequal2);
}

@Test()
void TransitionToString() {
  var transition = new Transition(new Instant.fromUtc(2017, 8, 25, 15, 26, 30), new Offset.fromHours(1));
  print(transition.toString());
  expect(transition.toString(), "Transition to +01 at 2017-08-25T15:26:30Z");
}

