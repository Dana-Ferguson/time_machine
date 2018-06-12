// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_patterns.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_globalization.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import '../../time_machine_testing.dart';
import '../text_cursor_test_base_tests.dart';

/// Tests for SteppedPatternBuilder, often using OffsetPatternParser as this is known
/// to use SteppedPatternBuilder.
Future main() async {
  await runTests();
}

@private final IPartialPattern<Offset> SimpleOffsetPattern =
new OffsetPatternParser().parsePattern("HH:mm", TimeMachineFormatInfo.invariantInfo);

@Test()
void ParsePartial_ValidInMiddle()
{
  var value = new ValueCursor("x17:30y");
  value.MoveNext();
  value.MoveNext();
  // Start already looking at the value to parse
  expect('1', value.Current);
  var result = SimpleOffsetPattern.parsePartial(value);
  expect(new Offset.fromHoursAndMinutes(17, 30), result.Value);
  // Finish just after the value
  expect('y', value.Current);
}

@Test()
void ParsePartial_ValidAtEnd()
{
  var value = new ValueCursor("x17:30");
  value.MoveNext();
  value.MoveNext();
  var result = SimpleOffsetPattern.parsePartial(value);
  expect(new Offset.fromHoursAndMinutes(17, 30), result.Value);
  // Finish just after the value, which in this case is at the end.
  expect(TextCursor.Nul, value.Current);
}

@Test()
void Parse_Partial_Invalid()
{
  var value = new ValueCursor("x17:y");
  value.MoveNext();
  value.MoveNext();
  var result = SimpleOffsetPattern.parsePartial(value);
  expect(() => result.GetValueOrThrow(), willThrow<UnparsableValueError>());
}

@Test()
void AppendFormat()
{
  var builder = new StringBuffer("x");
  var offset = new Offset.fromHoursAndMinutes(17, 30);
  SimpleOffsetPattern.appendFormat(offset, builder);
  expect("x17:30", builder.toString());
}

@Test()
@TestCase(const ["aBaB", true])
@TestCase(const ["aBAB", false]) // Case-sensitive
@TestCase(const ["<aBaB", false]) // < is reserved
@TestCase(const ["aBaB>", false]) // > is reserved
void UnhandledLiteral(String text, bool valid) {
  CharacterHandler<LocalDate, SampleBucket> handler = (PatternCursor x, SteppedPatternBuilder<LocalDate, SampleBucket> y) => null; // = delegate { };
  var handlers = new Map<String, CharacterHandler<LocalDate, SampleBucket>>.from(
      {
        'a': handler,
        'B': handler
      });
  var builder = new SteppedPatternBuilder<LocalDate, SampleBucket>(TimeMachineFormatInfo.invariantInfo, () => new SampleBucket());
  if (valid) {
    builder.parseCustomPattern(text, handlers);
  }
  else {
    expect(() => builder.parseCustomPattern(text, handlers), willThrow<InvalidPatternError>());
  }
}

@private class SampleBucket extends ParseBucket<LocalDate> {
  @internal
  @override
  ParseResult<LocalDate> CalculateValue(PatternFields usedFields, String value) {
    throw new UnimplementedError();
  }
}

