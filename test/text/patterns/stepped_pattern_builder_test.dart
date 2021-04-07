// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
// import 'package:matcher/matcher.dart';

import '../../time_machine_testing.dart';
// import '../text_cursor_test_base_tests.dart';

/// Tests for SteppedPatternBuilder, often using OffsetPatternParser as this is known
/// to use SteppedPatternBuilder.
Future main() async {
  await runTests();
}

@private final IPartialPattern<Offset> SimpleOffsetPattern =
OffsetPatternParser().parsePattern('HH:mm', TimeMachineFormatInfo.invariantInfo);

@Test()
void ParsePartial_ValidInMiddle()
{
  var value = ValueCursor('x17:30y');
  value.moveNext();
  value.moveNext();
  // Start already looking at the value to parse
  expect('1', value.current);
  var result = SimpleOffsetPattern.parsePartial(value);
  expect(Offset.hoursAndMinutes(17, 30), result.value);
  // Finish just after the value
  expect('y', value.current);
}

@Test()
void ParsePartial_ValidAtEnd()
{
  var value = ValueCursor('x17:30');
  value.moveNext();
  value.moveNext();
  var result = SimpleOffsetPattern.parsePartial(value);
  expect(Offset.hoursAndMinutes(17, 30), result.value);
  // Finish just after the value, which in this case is at the end.
  expect(TextCursor.nul, value.current);
}

@Test()
void Parse_Partial_Invalid()
{
  var value = ValueCursor('x17:y');
  value.moveNext();
  value.moveNext();
  var result = SimpleOffsetPattern.parsePartial(value);
  expect(() => result.getValueOrThrow(), willThrow<UnparsableValueError>());
}

@Test()
void AppendFormat()
{
  var builder = StringBuffer('x');
  var offset = Offset.hoursAndMinutes(17, 30);
  SimpleOffsetPattern.appendFormat(offset, builder);
  expect('x17:30', builder.toString());
}

@Test()
@TestCase(['aBaB', true])
@TestCase(['aBAB', false]) // Case-sensitive
@TestCase(['<aBaB', false]) // < is reserved
@TestCase(['aBaB>', false]) // > is reserved
void UnhandledLiteral(String text, bool valid) {
  CharacterHandler<LocalDate, SampleBucket> handler = (PatternCursor x, SteppedPatternBuilder<LocalDate, SampleBucket> y) => null; // = delegate { };
  var handlers = Map<String, CharacterHandler<LocalDate, SampleBucket>>.from(
      {
        'a': handler,
        'B': handler
      });
  var builder = SteppedPatternBuilder<LocalDate, SampleBucket>(TimeMachineFormatInfo.invariantInfo, () => SampleBucket());
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
  ParseResult<LocalDate> calculateValue(PatternFields usedFields, String value) {
    throw UnimplementedError();
  }
}

