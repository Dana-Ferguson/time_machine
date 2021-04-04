// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';

import '../time_machine_testing.dart';

Future main() async {
  await runTests();
}

@Test()
@TestCase([123, 1, '123'])
@TestCase([123, 3, '123'])
@TestCase([123, 4, '0123'])
@TestCase([123, 5, '00123'])
@TestCase([123, 6, '000123'])
@TestCase([123, 7, '0000123'])
@TestCase([123, 15, '000000000000123'])
@TestCase([-123, 1, '-123'])
@TestCase([-123, 3, '-123'])
@TestCase([-123, 4, '-0123'])
@TestCase([-123, 5, '-00123'])
@TestCase([-123, 6, '-000123'])
@TestCase([-123, 7, '-0000123'])
@TestCase([-123, 15, '-000000000000123'])
@TestCase([Platform.int32MinValue, 15, '-000002147483648'])
@TestCase([Platform.int32MinValue, 10, '-2147483648'])
@TestCase([Platform.int32MinValue, 3, '-2147483648'])
void TestLeftPad(int value, int length, String expected)
{
  var builder = StringBuffer();
  FormatHelper.leftPad(value, length, builder);
  expect(expected, builder.toString());
}

@Test()
@TestCase([123, 1, '123'])
@TestCase([123, 3, '123'])
@TestCase([123, 4, '0123'])
@TestCase([123, 5, '00123'])
@TestCase([123, 6, '000123'])
@TestCase([123, 7, '0000123'])
@TestCase([123, 15, '000000000000123'])
void TestLeftPadNonNegativeInt64(int value, int length, String expected)
{
  var builder = StringBuffer();
  FormatHelper.leftPadNonNegativeInt64(value, length, builder);
  expect(expected, builder.toString());
}

@Test()
@TestCase([1, 3, 3, '001'])
@TestCase([1200, 4, 5, '0120'])
@TestCase([1, 2, 3, '00'])
void TestAppendFraction(int value, int length, int scale, String expected)
{
  var builder = StringBuffer();
  FormatHelper.appendFraction(value, length, scale, builder);
  expect(expected, builder.toString());
}

@Test()
@TestCase(['x', 1, 3, 3, "x001"])
@TestCase(['x', 1200, 4, 5, "x012"])
@TestCase(['x', 1, 2, 3, "x"])
@TestCase(['1.', 1, 2, 3, "1"])
void TestAppendFractionTruncate(String initial, int value, int length, int scale, String expected)
{
  var builder = StringBuffer(initial);
  FormatHelper.appendFractionTruncate(value, length, scale, builder);
  expect(expected, builder.toString());
}

@Test()
@TestCase([0, 'x0'])
@TestCase([-1230, 'x-1230'])
@TestCase([1230, 'x1230'])
@TestCase([Platform.int64MinValue, 'x-9223372036854775808'])
void FormatInvariant(int value, String expected)
{
  var builder = StringBuffer('x');
  FormatHelper.formatInvariant(value, builder);
  expect(expected, builder.toString());
}        


