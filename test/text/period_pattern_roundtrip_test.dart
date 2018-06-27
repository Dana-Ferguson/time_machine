// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:mirrors';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';
import 'package:time_machine/src/text/patterns/time_machine_patterns.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

import '../time_machine_testing.dart';
import 'pattern_test_base.dart';
import 'pattern_test_data.dart';
import 'test_cultures.dart';
import 'text_cursor_test_base_tests.dart';

import 'period_pattern_test.dart';

Future main() async {
  await runTests();
}

@Test()
class PeriodPatternRoundtripTest extends PatternTestBase<Period> {
  @internal final List<Data> InvalidPatternData = [ null];

  @internal List<Data> ParseFailureData = [
    new Data()
      ..text = "X5H"
      ..Message = TextErrorMessages.mismatchedCharacter
      ..Parameters.addAll(['P']),
    new Data()
      ..text = ""
      ..Message = TextErrorMessages.valueStringEmpty,
    new Data()
      ..text = "PJ"
      ..Message = TextErrorMessages.missingNumber,
    new Data()
      ..text = "P5J"
      ..Message = TextErrorMessages.invalidUnitSpecifier
      ..Parameters.addAll(['J']),
    new Data()
      ..text = "P5D10M"
      ..Message = TextErrorMessages.misplacedUnitSpecifier
      ..Parameters.addAll(['M']),
    new Data()
      ..text = "P6M5D6D"
      ..Message = TextErrorMessages.repeatedUnitSpecifier
      ..Parameters.addAll(['D']),
    new Data()
      ..text = "PT5M10H"
      ..Message = TextErrorMessages.misplacedUnitSpecifier
      ..Parameters.addAll(['H']),
    new Data()
      ..text = "P5H"
      ..Message = TextErrorMessages.misplacedUnitSpecifier
      ..Parameters.addAll(['H']),
    new Data()
      ..text = "PT5Y"
      ..Message = TextErrorMessages.misplacedUnitSpecifier
      ..Parameters.addAll(['Y']),
    new Data()
      ..text = "PX"
      ..Message = TextErrorMessages.missingNumber,
    new Data()
      ..text = "P10M-"
      ..Message = TextErrorMessages.endOfString,
    new Data()
      ..text = "P5"
      ..Message = TextErrorMessages.endOfString,
    new Data()
      ..text = "P9223372036854775808H"
      ..Message = TextErrorMessages.valueOutOfRange
      ..Parameters.addAll(["9223372036854775808", 'Period']),
    new Data()
      ..text = "P-9223372036854775809H"
      ..Message = TextErrorMessages.valueOutOfRange
      ..Parameters.addAll(["-9223372036854775809", 'Period']),
    new Data()
      ..text = "P10000000000000000000H"
      ..Message = TextErrorMessages.valueOutOfRange
      ..Parameters.addAll(["10000000000000000000", 'Period']),
    new Data()
      ..text = "P-10000000000000000000H"
      ..Message = TextErrorMessages.valueOutOfRange
      ..Parameters.addAll(["-10000000000000000000", 'Period']),
  ];

  @internal List<Data> ParseOnlyData = [
    new Data.builder(new PeriodBuilder()..hours = 5)
      ..text = "PT005H",
    new Data.builder(new PeriodBuilder()..hours = 5)
      ..text = "PT00000000000000000000005H",
  ];

  // This pattern round-trips, so we can always parse what we format.
  @internal List<Data> FormatOnlyData = [];

  @internal static final List<Data> FormatAndParseData = [
    new Data(Period.Zero)
      ..text = "P",

    // All single values                                                                
    new Data.builder(new PeriodBuilder()..years = 5)
      ..text = "P5Y",
    new Data.builder(new PeriodBuilder()..months = 5)
      ..text = "P5M",
    new Data.builder(new PeriodBuilder()..weeks = 5)
      ..text = "P5W",
    new Data.builder(new PeriodBuilder()..days = 5)
      ..text = "P5D",
    new Data.builder(new PeriodBuilder()..hours = 5)
      ..text = "PT5H",
    new Data.builder(new PeriodBuilder()..minutes = 5)
      ..text = "PT5M",
    new Data.builder(new PeriodBuilder()..seconds = 5)
      ..text = "PT5S",
    new Data.builder(new PeriodBuilder()..milliseconds = 5)
      ..text = "PT5s",
    new Data.builder(new PeriodBuilder()..ticks = 5)
      ..text = "PT5t",
    new Data.builder(new PeriodBuilder()..nanoseconds = 5)
      ..text = "PT5n",

    // No normalization
    new Data.builder(new PeriodBuilder()
      ..hours = 25
      ..minutes = 90)
      ..text = "PT25H90M",

    // Compound, negative and zero tests
    new Data.builder(new PeriodBuilder()
      ..years = 5
      ..months = 2)
      ..text = "P5Y2M",
    new Data.builder(new PeriodBuilder()
      ..months = 1
      ..hours = 0)
      ..text = "P1M",
    new Data.builder(new PeriodBuilder()
      ..months = 1
      ..minutes = -1)
      ..text = "P1MT-1M",
    new Data.builder(new PeriodBuilder()
      ..hours = 1
      ..minutes = -1)
      ..text = "PT1H-1M",

    // Max/min
    new Data(new Period.fromHours(Utility.int64MaxValue))
      ..text = "PT9223372036854775807H",
    new Data(new Period.fromHours(Utility.int64MinValue))
      ..text = "PT-9223372036854775808H",
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);

  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);

  @Test()
  void ParseNull() => AssertParseNull(PeriodPattern.roundtrip);
}

