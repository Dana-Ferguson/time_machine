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
class PeriodPatternNormalizingIsoTest extends PatternTestBase<Period> {
  // Single null value to keep it from being 'inconclusive'
  @internal final List<Data?> InvalidPatternData = [null];

  @internal final List<Data> ParseFailureData = [
    Data()
      ..text = 'X5H'
      ..message = TextErrorMessages.mismatchedCharacter
      ..parameters.addAll(['P']),
    Data()
      ..text = ''
      ..message = TextErrorMessages.valueStringEmpty,
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
    // Invalid in ISO.
    Data()
      ..text = 'P'
      ..message = TextErrorMessages.emptyPeriod,
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
      ..text = 'PT9223372036854775808H'
      ..message = TextErrorMessages.valueOutOfRange
      ..parameters.addAll(['9223372036854775808', 'Period']),
    Data()
      ..text = 'PT-9223372036854775809H'
      ..message = TextErrorMessages.valueOutOfRange
      ..parameters.addAll(['-9223372036854775809', 'Period']),
    Data()
      ..text = 'PT10000000000000000000H'
      ..message = TextErrorMessages.valueOutOfRange
      ..parameters.addAll(['10000000000000000000', 'Period']),
    Data()
      ..text = 'PT-10000000000000000000H'
      ..message = TextErrorMessages.valueOutOfRange
      ..parameters.addAll(['-10000000000000000000', 'Period']),
    Data()
      ..text = 'P5.5S'
      ..message = TextErrorMessages.misplacedUnitSpecifier
      ..parameters.addAll(['.']),
    Data()
      ..text = 'PT.5S'
      ..message = TextErrorMessages.missingNumber,
    Data()
      ..text = 'PT0.5X'
      ..message = TextErrorMessages.mismatchedCharacter
      ..parameters.addAll(['S']),
    Data()
      ..text = 'PT0.X'
      ..message = TextErrorMessages.missingNumber,
    Data()
      ..text = 'PT5S0.5S'
      ..message = TextErrorMessages.misplacedUnitSpecifier
      ..parameters.addAll(['.']),
    Data()
      ..text = 'PT5.'
      ..message = TextErrorMessages.missingNumber,
    Data()
      ..text = 'PT5.5SX'
      ..message = TextErrorMessages.expectedEndOfString
  ];

  @internal final List<Data> ParseOnlyData = [
    Data.builder(PeriodBuilder()..hours = 5)
      ..text = 'PT005H',
    Data.builder(PeriodBuilder()..milliseconds = 500)
      ..text = 'PT0,5S',
    Data.builder(PeriodBuilder()..hours = 5)
      ..text = 'PT00000000000000000000005H',
    Data.builder(PeriodBuilder()..weeks = 5)
      ..text = 'P5W',
  ];

  // Only a small amount of testing here - it's around normalization, which is
  // unit tested more thoroughly elsewhere.
  /*
    For NodaTime:
      var b = new PeriodBuilder(); b.Hours = 25; b.Minutes = 90;
      WriteLine(PeriodPattern.NormalizingIso.Format(b.Build()));
      
      Produces: P1DT2H30M
      
    The Text is 'P1D2H30M' online... todo: what is happening here? do the tests fail on NodaTime.Test:master?
  */
  @internal final List<Data> FormatOnlyData = [
    Data.builder(PeriodBuilder()
      ..hours = 25
      ..minutes = 90)
      ..text = 'P1DT2H30M',
    Data.builder(PeriodBuilder()..nanoseconds = 1234567800)
    // 'T' was added, see above:
      ..text = 'PT1.2345678S',
    Data.builder(PeriodBuilder()
      ..hours = 1
      ..minutes = -1)
      ..text = 'PT59M',
    Data.builder(PeriodBuilder()
      ..hours = -1
      ..minutes = 1)
      ..text = 'PT-59M',
    Data.builder(PeriodBuilder()..weeks = 5)
      ..text = 'P35D',
  ];

  @internal final List<Data> FormatAndParseData = [
    Data(Period.zero)
      ..text = 'P0D',

    // All single values
    Data.builder(PeriodBuilder()..years = 5)
      ..text = 'P5Y',
    Data.builder(PeriodBuilder()..months = 5)
      ..text = 'P5M',
    Data.builder(PeriodBuilder()..days = 5)
      ..text = 'P5D',
    Data.builder(PeriodBuilder()..hours = 5)
      ..text = 'PT5H',
    Data.builder(PeriodBuilder()..minutes = 5)
      ..text = 'PT5M',
    Data.builder(PeriodBuilder()..seconds = 5)
      ..text = 'PT5S',
    Data.builder(PeriodBuilder()..milliseconds = 5)
      ..text = 'PT0.005S',
    Data.builder(PeriodBuilder()..microseconds = 5)
      ..text = 'PT0.000005S',
    Data.builder(PeriodBuilder()..nanoseconds = 5)
      ..text = 'PT0.000000005S',

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
      ..seconds = 1
      ..milliseconds = 320)
      ..text = 'PT1.32S',
    Data.builder(PeriodBuilder()..seconds = -1)
      ..text = 'PT-1S',
    Data.builder(PeriodBuilder()
      ..seconds = -1
      ..milliseconds = -320)
      ..text = 'PT-1.32S',
    Data.builder(PeriodBuilder()..milliseconds = -320)
      ..text = 'PT-0.32S',
  ];

  @internal Iterable<Data> get ParseData => [ParseOnlyData, FormatAndParseData].expand((x) => x);

  @internal Iterable<Data> get FormatData => [FormatOnlyData, FormatAndParseData].expand((x) => x);

  // note: in C# this was a static constructor; a regular constructor works in Dart's test infrastructure
  // Go over all our sequences and change the pattern to use. This is ugly,
  // but it beats specifying it on each line.
  PeriodPatternNormalizingIsoTest() {
    print ('Constructor called.');
    for (var sequence in [ ParseFailureData, ParseData, FormatData]) {
      for (var item in sequence) {
        item.standardPattern = PeriodPattern.normalizingIso;
      }
    }
  }

  // @Test()
  // void ParseNull() => AssertParseNull(PeriodPattern.normalizingIso);
}


