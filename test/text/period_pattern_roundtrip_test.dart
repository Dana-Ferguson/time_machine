// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import '../time_machine_testing.dart';
import 'pattern_test_base.dart';

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
      ..message = TextErrorMessages.mismatchedCharacter
      ..parameters.addAll(['P']),
    new Data()
      ..text = ""
      ..message = TextErrorMessages.valueStringEmpty,
    new Data()
      ..text = "PJ"
      ..message = TextErrorMessages.missingNumber,
    new Data()
      ..text = "P5J"
      ..message = TextErrorMessages.invalidUnitSpecifier
      ..parameters.addAll(['J']),
    new Data()
      ..text = "P5D10M"
      ..message = TextErrorMessages.misplacedUnitSpecifier
      ..parameters.addAll(['M']),
    new Data()
      ..text = "P6M5D6D"
      ..message = TextErrorMessages.repeatedUnitSpecifier
      ..parameters.addAll(['D']),
    new Data()
      ..text = "PT5M10H"
      ..message = TextErrorMessages.misplacedUnitSpecifier
      ..parameters.addAll(['H']),
    new Data()
      ..text = "P5H"
      ..message = TextErrorMessages.misplacedUnitSpecifier
      ..parameters.addAll(['H']),
    new Data()
      ..text = "PT5Y"
      ..message = TextErrorMessages.misplacedUnitSpecifier
      ..parameters.addAll(['Y']),
    new Data()
      ..text = "PX"
      ..message = TextErrorMessages.missingNumber,
    new Data()
      ..text = "P10M-"
      ..message = TextErrorMessages.endOfString,
    new Data()
      ..text = "P5"
      ..message = TextErrorMessages.endOfString,
    new Data()
      ..text = "P9223372036854775808H"
      ..message = TextErrorMessages.valueOutOfRange
      ..parameters.addAll(["9223372036854775808", 'Period']),
    new Data()
      ..text = "P-9223372036854775809H"
      ..message = TextErrorMessages.valueOutOfRange
      ..parameters.addAll(["-9223372036854775809", 'Period']),
    new Data()
      ..text = "P10000000000000000000H"
      ..message = TextErrorMessages.valueOutOfRange
      ..parameters.addAll(["10000000000000000000", 'Period']),
    new Data()
      ..text = "P-10000000000000000000H"
      ..message = TextErrorMessages.valueOutOfRange
      ..parameters.addAll(["-10000000000000000000", 'Period']),
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
    new Data(Period.zero)
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
    new Data(new Period.fromHours(Platform.int64MaxValue))
      ..text = "PT9223372036854775807H",
    new Data(new Period.fromHours(Platform.int64MinValue))
      ..text = "PT-9223372036854775808H",
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);

  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);

  @Test()
  void ParseNull() => AssertParseNull(PeriodPattern.roundtrip);
}

