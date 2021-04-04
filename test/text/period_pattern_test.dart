// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import '../time_machine_testing.dart';
import 'pattern_test_data.dart';

Future main() async {
  await runTests();
}

/// A container for test data for formatting and parsing [Period] objects.
class Data extends PatternTestData<Period> {
  @override Period get defaultTemplate => const Period(days: 0);

  Data([Period? value]) : super(value ?? const Period(days: 0)) {
    standardPattern = PeriodPattern.roundtrip;
  }

  Data.builder(PeriodBuilder builder) : this(builder.build());

  @internal
  @override
  IPattern<Period> CreatePattern() => standardPattern!;
}
