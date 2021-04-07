// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import '../time_machine_testing.dart';

Future main() async {
  await runTests();
}

final ParseResult<int> _failureResult = IParseResult.forInvalidValue<int>(ValueCursor('text'), "text");

@Test()
void Value_Success()
{
  ParseResult<int> result = ParseResult.forValue<int>(5);
  expect(5, result.value);
}

@Test()
void Value_Failure()
{
  expect(() => _failureResult.value.hashCode, willThrow<UnparsableValueError>());
}

@Test()
void Exception_Success()
{
  ParseResult<int> result = ParseResult.forValue<int>(5);
  expect(() => result.error.hashCode, throwsStateError);
}

@Test()
void Exception_Failure()
{
  // Assert.IsInstanceOf<UnparsableValueError>(FailureResult.Exception);
  expect(_failureResult.error, const TypeMatcher<UnparsableValueError>());
}

@Test()
void GetValueOrThrow_Success()
{
  ParseResult<int> result = ParseResult.forValue<int>(5);
  expect(5, result.getValueOrThrow());
}

@Test()
void GetValueOrThrow_Failure()
{
  expect(() => _failureResult.getValueOrThrow(), willThrow<UnparsableValueError>());
}

@Test()
void TryGetValue_Success() {
  ParseResult<int> result = ParseResult.forValue<int>(5);
  //expect(result.TryGetValue(-1, out int actual), isTrue);
  int actual;
  expect(actual = result.TryGetValue(-1), isNot(-1));
  expect(5, actual);
}

@Test()
void TryGetValue_Failure()
{
// expect(FailureResult.TryGetValue(-1, out int actual), isFalse);

  int actual;
  expect(actual = _failureResult.TryGetValue(-1), -1);
  expect(-1, actual);
}

@Test()
void Convert_ForFailureResult()
{
  ParseResult<String> converted = _failureResult.convert((x) => 'xx${x}xx');
  expect(() => converted.getValueOrThrow(), willThrow<UnparsableValueError>());
}

@Test()
void Convert_ForSuccessResult()
{
  ParseResult<int> original = ParseResult.forValue<int>(10);
  ParseResult<String> converted = original.convert((x) => 'xx${x}xx');
  expect('xx10xx', converted.value);
}

@Test()
void ConvertError_ForFailureResult()
{
  ParseResult<String> converted = _failureResult.convertError<String>();
  expect(() => converted.getValueOrThrow(), willThrow<UnparsableValueError>());
}

@Test()
void ConvertError_ForSuccessResult()
{
  ParseResult<int> original = ParseResult.forValue<int>(10);
expect(() => original.convertError<String>(), throwsStateError);
}

@Test()
void ForException() {
  Error e = Error();
  ParseResult<int> result = ParseResult.forError<int>(() => e);
  expect(result.success, isFalse);
  expect(identical(e, result.error), isTrue);
}


