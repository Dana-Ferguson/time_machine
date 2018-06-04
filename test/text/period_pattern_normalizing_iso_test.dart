// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/Text/PeriodPatternTest.NormalizingIso.cs
// 69dedbc  on Apr 23

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
      ..Text = "X5H"
      ..Message = TextErrorMessages.MismatchedCharacter
      ..Parameters.addAll(['P']),
    new Data()
      ..Text = ""
      ..Message = TextErrorMessages.ValueStringEmpty,
    new Data()
      ..Text = "P5J"
      ..Message = TextErrorMessages.InvalidUnitSpecifier
      ..Parameters.addAll(['J']),
    new Data()
      ..Text = "P5D10M"
      ..Message = TextErrorMessages.MisplacedUnitSpecifier
      ..Parameters.addAll(['M']),
    new Data()
      ..Text = "P6M5D6D"
      ..Message = TextErrorMessages.RepeatedUnitSpecifier
      ..Parameters.addAll(['D']),
    new Data()
      ..Text = "PT5M10H"
      ..Message = TextErrorMessages.MisplacedUnitSpecifier
      ..Parameters.addAll(['H']),
    new Data()
      ..Text = "P5H"
      ..Message = TextErrorMessages.MisplacedUnitSpecifier
      ..Parameters.addAll(['H']),
    new Data()
      ..Text = "PT5Y"
      ..Message = TextErrorMessages.MisplacedUnitSpecifier
      ..Parameters.addAll(['Y']),
    // Invalid in ISO.
    new Data()
      ..Text = "P"
      ..Message = TextErrorMessages.EmptyPeriod,
    new Data()
      ..Text = "PX"
      ..Message = TextErrorMessages.MissingNumber,
    new Data()
      ..Text = "P10M-"
      ..Message = TextErrorMessages.EndOfString,
    new Data()
      ..Text = "P5"
      ..Message = TextErrorMessages.EndOfString,
    new Data()
      ..Text = "PT9223372036854775808H"
      ..Message = TextErrorMessages.ValueOutOfRange
      ..Parameters.addAll(["9223372036854775808", 'Period']),
    new Data()
      ..Text = "PT-9223372036854775809H"
      ..Message = TextErrorMessages.ValueOutOfRange
      ..Parameters.addAll(["-9223372036854775809", 'Period']),
    new Data()
      ..Text = "PT10000000000000000000H"
      ..Message = TextErrorMessages.ValueOutOfRange
      ..Parameters.addAll(["10000000000000000000", 'Period']),
    new Data()
      ..Text = "PT-10000000000000000000H"
      ..Message = TextErrorMessages.ValueOutOfRange
      ..Parameters.addAll(["-10000000000000000000", 'Period']),
    new Data()
      ..Text = "P5.5S"
      ..Message = TextErrorMessages.MisplacedUnitSpecifier
      ..Parameters.addAll(['.']),
    new Data()
      ..Text = "PT.5S"
      ..Message = TextErrorMessages.MissingNumber,
    new Data()
      ..Text = "PT0.5X"
      ..Message = TextErrorMessages.MismatchedCharacter
      ..Parameters.addAll(['S']),
    new Data()
      ..Text = "PT0.X"
      ..Message = TextErrorMessages.MissingNumber,
    new Data()
      ..Text = "PT5S0.5S"
      ..Message = TextErrorMessages.MisplacedUnitSpecifier
      ..Parameters.addAll(['.']),
    new Data()
      ..Text = "PT5."
      ..Message = TextErrorMessages.MissingNumber,
    new Data()
      ..Text = "PT5.5SX"
      ..Message = TextErrorMessages.ExpectedEndOfString
  ];

  @internal final List<Data> ParseOnlyData = [
    new Data.builder(new PeriodBuilder()..Hours = 5)
      ..Text = "PT005H",
    new Data.builder(new PeriodBuilder()..Milliseconds = 500)
      ..Text = "PT0,5S",
    new Data.builder(new PeriodBuilder()..Hours = 5)
      ..Text = "PT00000000000000000000005H",
    new Data.builder(new PeriodBuilder()..Weeks = 5)
      ..Text = "P5W",
  ];

  // Only a small amount of testing here - it's around normalization, which is
  // unit tested more thoroughly elsewhere.
  @internal final List<Data> FormatOnlyData = [
    new Data.builder(new PeriodBuilder()
      ..Hours = 25
      ..Minutes = 90)
      ..Text = "P1D2H30M",
    new Data.builder(new PeriodBuilder()..Ticks = 12345678)
      ..Text = "P1.2345678S",
    new Data.builder(new PeriodBuilder()
      ..Hours = 1
      ..Minutes = -1)
      ..Text = "PT59M",
    new Data.builder(new PeriodBuilder()
      ..Hours = -1
      ..Minutes = 1)
      ..Text = "PT-59M",
    new Data.builder(new PeriodBuilder()..Weeks = 5)
      ..Text = "P35D",
  ];

  @internal final List<Data> FormatAndParseData = [
    new Data(Period.Zero)
      ..Text = "P0D",

    // All single values
    new Data.builder(new PeriodBuilder()..Years = 5)
      ..Text = "P5Y",
    new Data.builder(new PeriodBuilder()..Months = 5)
      ..Text = "P5M",
    new Data.builder(new PeriodBuilder()..Days = 5)
      ..Text = "P5D",
    new Data.builder(new PeriodBuilder()..Hours = 5)
      ..Text = "PT5H",
    new Data.builder(new PeriodBuilder()..Minutes = 5)
      ..Text = "PT5M",
    new Data.builder(new PeriodBuilder()..Seconds = 5)
      ..Text = "PT5S",
    new Data.builder(new PeriodBuilder()..Milliseconds = 5)
      ..Text = "PT0.005S",
    new Data.builder(new PeriodBuilder()..Ticks = 5)
      ..Text = "PT0.0000005S",
    new Data.builder(new PeriodBuilder()..Nanoseconds = 5)
      ..Text = "PT0.000000005S",

    // Compound, negative and zero tests
    new Data.builder(new PeriodBuilder()
      ..Years = 5
      ..Months = 2)
      ..Text = "P5Y2M",
    new Data.builder(new PeriodBuilder()
      ..Months = 1
      ..Hours = 0)
      ..Text = "P1M",
    new Data.builder(new PeriodBuilder()
      ..Months = 1
      ..Minutes = -1)
      ..Text = "P1MT-1M",
    new Data.builder(new PeriodBuilder()
      ..Seconds = 1
      ..Milliseconds = 320)
      ..Text = "PT1.32S",
    new Data.builder(new PeriodBuilder()..Seconds = -1)
      ..Text = "PT-1S",
    new Data.builder(new PeriodBuilder()
      ..Seconds = -1
      ..Milliseconds = -320)
      ..Text = "PT-1.32S",
    new Data.builder(new PeriodBuilder()..Milliseconds = -320)
      ..Text = "PT-0.32S",
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
        item.StandardPattern = PeriodPattern.NormalizingIso;
      }
    }
  }

  @Test()
  void ParseNull() => AssertParseNull(PeriodPattern.NormalizingIso);
}

