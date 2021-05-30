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
  @internal final List<Data?> InvalidPatternData = [ null];

  @internal List<Data> ParseFailureData = [
    Data()
      ..text = 'X5H'
      ..message = TextErrorMessages.mismatchedCharacter
      ..parameters.addAll(['P']),
    Data()
      ..text = ''
      ..message = TextErrorMessages.valueStringEmpty,
    Data()
      ..text = 'PJ'
      ..message = TextErrorMessages.missingNumber,
    Data()
      ..text = 'P5J'
      ..message = TextErrorMessages.invalidUnitSpecifier
      ..parameters.addAll(['J']),
    Data()
      ..text = 'P5D10M'
      ..message = TextErrorMessages.misplacedUnitSpecifier
      ..parameters.addAll(['M']),
    Data()
      ..text = 'P6M5D6D'
      ..message = TextErrorMessages.repeatedUnitSpecifier
      ..parameters.addAll(['D']),
    Data()
      ..text = 'PT5M10H'
      ..message = TextErrorMessages.misplacedUnitSpecifier
      ..parameters.addAll(['H']),
    Data()
      ..text = 'P5H'
      ..message = TextErrorMessages.misplacedUnitSpecifier
      ..parameters.addAll(['H']),
    Data()
      ..text = 'PT5Y'
      ..message = TextErrorMessages.misplacedUnitSpecifier
      ..parameters.addAll(['Y']),
    Data()
      ..text = 'PX'
      ..message = TextErrorMessages.missingNumber,
    Data()
      ..text = 'P10M-'
      ..message = TextErrorMessages.endOfString,
    Data()
      ..text = 'P5'
      ..message = TextErrorMessages.endOfString,
    Data()
      ..text = 'P9223372036854775808H'
      ..message = TextErrorMessages.valueOutOfRange
      ..parameters.addAll(['9223372036854775808', 'Period']),
    Data()
      ..text = 'P-9223372036854775809H'
      ..message = TextErrorMessages.valueOutOfRange
      ..parameters.addAll(['-9223372036854775809', 'Period']),
    Data()
      ..text = 'P10000000000000000000H'
      ..message = TextErrorMessages.valueOutOfRange
      ..parameters.addAll(['10000000000000000000', 'Period']),
    Data()
      ..text = 'P-10000000000000000000H'
      ..message = TextErrorMessages.valueOutOfRange
      ..parameters.addAll(['-10000000000000000000', 'Period']),
  ];

  @internal List<Data> ParseOnlyData = [
    Data.builder(PeriodBuilder()..hours = 5)
      ..text = 'PT005H',
    Data.builder(PeriodBuilder()..hours = 5)
      ..text = 'PT00000000000000000000005H',
  ];

  // This pattern round-trips, so we can always parse what we format.
  @internal List<Data> FormatOnlyData = [];

  @internal static final List<Data> FormatAndParseData = [
    Data(Period.zero)
      ..text = 'P',

    // All single values                                                                
    Data.builder(PeriodBuilder()..years = 5)
      ..text = 'P5Y',
    Data.builder(PeriodBuilder()..months = 5)
      ..text = 'P5M',
    Data.builder(PeriodBuilder()..weeks = 5)
      ..text = 'P5W',
    Data.builder(PeriodBuilder()..days = 5)
      ..text = 'P5D',
    Data.builder(PeriodBuilder()..hours = 5)
      ..text = 'PT5H',
    Data.builder(PeriodBuilder()..minutes = 5)
      ..text = 'PT5M',
    Data.builder(PeriodBuilder()..seconds = 5)
      ..text = 'PT5S',
    Data.builder(PeriodBuilder()..milliseconds = 5)
      ..text = 'PT5s',
    Data.builder(PeriodBuilder()..microseconds = 5)
      ..text = 'PT5t',
    Data.builder(PeriodBuilder()..nanoseconds = 5)
      ..text = 'PT5n',

    // No normalization
    Data.builder(PeriodBuilder()
      ..hours = 25
      ..minutes = 90)
      ..text = 'PT25H90M',

    // Compound, negative and zero tests
    Data.builder(PeriodBuilder()
      ..years = 5
      ..months = 2)
      ..text = 'P5Y2M',
    Data.builder(PeriodBuilder()
      ..months = 1
      ..hours = 0)
      ..text = 'P1M',
    Data.builder(PeriodBuilder()
      ..months = 1
      ..minutes = -1)
      ..text = 'P1MT-1M',
    Data.builder(PeriodBuilder()
      ..hours = 1
      ..minutes = -1)
      ..text = 'PT1H-1M',

    // Max/min
    Data(const Period(hours: Platform.int64MaxValue))
      ..text = 'PT9223372036854775807H',
    Data(const Period(hours: Platform.int64MinValue))
      ..text = 'PT-9223372036854775808H',
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);

  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);

  // @Test()
  // void ParseNull() => AssertParseNull(PeriodPattern.roundtrip);
}

