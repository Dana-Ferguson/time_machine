// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/Text/PeriodPatternTest.cs
// cae7975  on Aug 24, 2017
import 'dart:async';
import 'dart:math' as math;
import 'dart:mirrors';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_patterns.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import '../time_machine_testing.dart';
import 'pattern_test_base.dart';
import 'pattern_test_data.dart';
import 'test_cultures.dart';
import 'text_cursor_test_base_tests.dart';

Future main() async {
  await runTests();
}

/// <summary>
/// A container for test data for formatting and parsing <see cref="Period" /> objects.
/// </summary>
/*sealed*/ class Data extends PatternTestData<Period> {
// Irrelevant
/*protected*/ @override Period get DefaultTemplate => new Period.fromDays(0);

  Data([Period value = null]) : super(value ?? new Period.fromDays(0)) {
    this.StandardPattern = PeriodPattern.Roundtrip;
  }

  Data.builder(PeriodBuilder builder) : this(builder.Build());

  @internal
  @override
  IPattern<Period> CreatePattern() => StandardPattern;
}