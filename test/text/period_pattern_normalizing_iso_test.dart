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
  // Single null value to keep it from being "inconclusive"
  @internal final List<Data> InvalidPatternData = [ null];

  @internal final List<Data> ParseFailureData = [
    new Data()
      ..text = "X5H"
      ..Message = TextErrorMessages.mismatchedCharacter
      ..Parameters.addAll(['P']),
    new Data()
      ..text = ""
      ..Message = TextErrorMessages.valueStringEmpty,
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
    // Invalid in ISO.
    new Data()
      ..text = "P"
      ..Message = TextErrorMessages.emptyPeriod,
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
      ..text = "PT9223372036854775808H"
      ..Message = TextErrorMessages.valueOutOfRange
      ..Parameters.addAll(["9223372036854775808", 'Period']),
    new Data()
      ..text = "PT-9223372036854775809H"
      ..Message = TextErrorMessages.valueOutOfRange
      ..Parameters.addAll(["-9223372036854775809", 'Period']),
    new Data()
      ..text = "PT10000000000000000000H"
      ..Message = TextErrorMessages.valueOutOfRange
      ..Parameters.addAll(["10000000000000000000", 'Period']),
    new Data()
      ..text = "PT-10000000000000000000H"
      ..Message = TextErrorMessages.valueOutOfRange
      ..Parameters.addAll(["-10000000000000000000", 'Period']),
    new Data()
      ..text = "P5.5S"
      ..Message = TextErrorMessages.misplacedUnitSpecifier
      ..Parameters.addAll(['.']),
    new Data()
      ..text = "PT.5S"
      ..Message = TextErrorMessages.missingNumber,
    new Data()
      ..text = "PT0.5X"
      ..Message = TextErrorMessages.mismatchedCharacter
      ..Parameters.addAll(['S']),
    new Data()
      ..text = "PT0.X"
      ..Message = TextErrorMessages.missingNumber,
    new Data()
      ..text = "PT5S0.5S"
      ..Message = TextErrorMessages.misplacedUnitSpecifier
      ..Parameters.addAll(['.']),
    new Data()
      ..text = "PT5."
      ..Message = TextErrorMessages.missingNumber,
    new Data()
      ..text = "PT5.5SX"
      ..Message = TextErrorMessages.expectedEndOfString
  ];

  @internal final List<Data> ParseOnlyData = [
    new Data.builder(new PeriodBuilder()..hours = 5)
      ..text = "PT005H",
    new Data.builder(new PeriodBuilder()..milliseconds = 500)
      ..text = "PT0,5S",
    new Data.builder(new PeriodBuilder()..hours = 5)
      ..text = "PT00000000000000000000005H",
    new Data.builder(new PeriodBuilder()..weeks = 5)
      ..text = "P5W",
  ];

  // Only a small amount of testing here - it's around normalization, which is
  // unit tested more thoroughly elsewhere.
  /*
    For NodaTime:
      var b = new PeriodBuilder(); b.Hours = 25; b.Minutes = 90;
      WriteLine(PeriodPattern.NormalizingIso.Format(b.Build()));
      
      Produces: P1DT2H30M
      
    The Text is "P1D2H30M" online... todo: what is happening here? do the tests fail on NodaTime.Test:master?
  */
  @internal final List<Data> FormatOnlyData = [
    new Data.builder(new PeriodBuilder()
      ..hours = 25
      ..minutes = 90)
      ..text = "P1DT2H30M",
    new Data.builder(new PeriodBuilder()..ticks = 12345678)
    // 'T' was added, see above:
      ..text = "PT1.2345678S",
    new Data.builder(new PeriodBuilder()
      ..hours = 1
      ..minutes = -1)
      ..text = "PT59M",
    new Data.builder(new PeriodBuilder()
      ..hours = -1
      ..minutes = 1)
      ..text = "PT-59M",
    new Data.builder(new PeriodBuilder()..weeks = 5)
      ..text = "P35D",
  ];

  @internal final List<Data> FormatAndParseData = [
    new Data(Period.zero)
      ..text = "P0D",

    // All single values
    new Data.builder(new PeriodBuilder()..years = 5)
      ..text = "P5Y",
    new Data.builder(new PeriodBuilder()..months = 5)
      ..text = "P5M",
    new Data.builder(new PeriodBuilder()..days = 5)
      ..text = "P5D",
    new Data.builder(new PeriodBuilder()..hours = 5)
      ..text = "PT5H",
    new Data.builder(new PeriodBuilder()..minutes = 5)
      ..text = "PT5M",
    new Data.builder(new PeriodBuilder()..seconds = 5)
      ..text = "PT5S",
    new Data.builder(new PeriodBuilder()..milliseconds = 5)
      ..text = "PT0.005S",
    new Data.builder(new PeriodBuilder()..ticks = 5)
      ..text = "PT0.0000005S",
    new Data.builder(new PeriodBuilder()..nanoseconds = 5)
      ..text = "PT0.000000005S",

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
      ..seconds = 1
      ..milliseconds = 320)
      ..text = "PT1.32S",
    new Data.builder(new PeriodBuilder()..seconds = -1)
      ..text = "PT-1S",
    new Data.builder(new PeriodBuilder()
      ..seconds = -1
      ..milliseconds = -320)
      ..text = "PT-1.32S",
    new Data.builder(new PeriodBuilder()..milliseconds = -320)
      ..text = "PT-0.32S",
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
        item.StandardPattern = PeriodPattern.normalizingIso;
      }
    }
  }

  @Test()
  void ParseNull() => AssertParseNull(PeriodPattern.normalizingIso);
}


