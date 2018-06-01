// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/Text/PatternTestBase.cs
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
import 'pattern_test_data.dart';
import 'text_cursor_test_base_tests.dart';

/// Base class for all the pattern tests (when we've migrated OffsetPattern off FormattingTestSupport).
/// Derived classes should have internal static fields with the names listed in the TestCaseSource
/// attributes here: InvalidPatternData, ParseFailureData, ParseData, FormatData. Any field
/// which is missing causes that test to be "not runnable" for that concrete subclass.
/// If a test isn't appropriate (e.g. there's no configurable pattern) just provide a property with
/// an array containing a null value - that will be ignored.
abstract class PatternTestBase<T>
{
  @Test()
  @TestCaseSource(#InvalidPatternData)
  void InvalidPatterns(PatternTestData<T> data)
  {
    data?.TestInvalidPattern();
  }

  @Test()
  @TestCaseSource(#ParseFailureData)
  void ParseFailures(PatternTestData<T> data)
  {
    data?.TestParseFailure();
  }

  @Test()
  @TestCaseSource(#ParseData)
  void Parse(PatternTestData<T> data)
  {
    data?.TestParse();
  }

  @Test()
  @TestCaseSource(#FormatData)
  void Format(PatternTestData<T> data)
  {
    data?.TestFormat();
  }

  // Testing this for every item is somewhat overkill, but not too slow.
  @Test()
  @TestCaseSource(#FormatData)
  void AppendFormat(PatternTestData<T> data)
  {
    data?.TestAppendFormat();
  }

  void AssertRoundTrip(T value, IPattern<T> pattern)
  {
    String text = pattern.Format(value);
    var parseResult = pattern.Parse(text);
    expect(value, parseResult.Value);
  }

  void AssertParseNull(IPattern<T> pattern)
  {
    var result = pattern.Parse(null);
    expect(result.Success, isFalse);
    // Assert.IsInstanceOf<ArgumentNullException>(result.Exception);
    expect(result.Exception, new isInstanceOf<ArgumentError>());
  }
}

