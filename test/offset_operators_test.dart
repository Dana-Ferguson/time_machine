// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
// import 'package:matcher/matcher.dart';

import 'time_machine_testing.dart';

Future main() async {
  await TimeMachine.initialize();
  await runTests();
}

final Offset ThreeHours = TestObjects.CreatePositiveOffset(3, 0, 0);
final Offset NegativeThreeHours = TestObjects.CreateNegativeOffset(3, 0, 0);
final Offset NegativeTwelveHours = TestObjects.CreateNegativeOffset(12, 0, 0);

@Test()
void IEquatableIComparable_Tests()
{
  var value = Offset(12345);
  var equalValue = Offset(12345);
  var greaterValue = Offset(54321);

  TestHelper.TestEqualsStruct(value, equalValue, [greaterValue]);
  TestHelper.TestCompareToStruct(value, equalValue, [greaterValue]);
  // TestHelper.TestNonGenericCompareTo(value, equalValue, greaterValue);
  TestHelper.TestOperatorComparisonEquality(value, equalValue, [greaterValue]);
}

/* No unary plus in Dart
@Test()
void UnaryPlusOperator()
{
  expect(Offset.zero, +Offset.zero, reason: '+ 0');
  expect(new Offset.fromSeconds(1), + new Offset.fromSeconds(1), reason: '+ 1');
  expect(new Offset.fromSeconds(-7), + new Offset.fromSeconds(-7), reason: '+ (-7)');
}*/

@Test()
void NegateOperator()
{
  expect(Offset.zero, -Offset.zero, reason: '-0');
  expect(Offset(-1), -Offset(1), reason: '-1');
  expect(Offset(7), -Offset(-7), reason: '- (-7)');
}

@Test()
void NegateMethod()
{
  expect(Offset.zero, Offset.negate(Offset.zero), reason: '-0');
  expect(Offset(-1), Offset.negate(Offset(1)), reason: '-1');
  expect(Offset(7), Offset.negate(Offset(-7)), reason: '- (-7)');
}

// #region operator +
@Test()
void OperatorPlus_Zero_IsNeutralElement()
{
  expect(0, (Offset.zero + Offset.zero).inSeconds, reason: '0 + 0');
  expect(TestObjects.CreatePositiveOffset(3, 0, 0), ThreeHours + Offset.zero, reason: 'ThreeHours + 0');
  expect(TestObjects.CreatePositiveOffset(3, 0, 0), Offset.zero + ThreeHours, reason: '0 + ThreeHours');
}

@Test()
void OperatorPlus_NonZero()
{
  expect(TestObjects.CreatePositiveOffset(6, 0, 0), ThreeHours + ThreeHours, reason: 'ThreeHours + ThreeHours');
  expect(Offset.zero, ThreeHours + NegativeThreeHours, reason: 'ThreeHours + (-ThreeHours)');
  expect(TestObjects.CreateNegativeOffset(9, 0, 0), NegativeTwelveHours + ThreeHours, reason: '-TwelveHours + ThreeHours');
}

// Static method equivalents
@Test()
void MethodAdd_Zero_IsNeutralElement()
{
  expect(0, Offset.plus(Offset.zero, Offset.zero).inMilliseconds, reason: '0 + 0');
  expect(TestObjects.CreatePositiveOffset(3, 0, 0), Offset.plus(ThreeHours, Offset.zero), reason: 'ThreeHours + 0');
  expect(TestObjects.CreatePositiveOffset(3, 0, 0), Offset.plus(Offset.zero, ThreeHours), reason: '0 + ThreeHours');
}

@Test()
void MethodAdd_NonZero()
{
  expect(TestObjects.CreatePositiveOffset(6, 0, 0), Offset.plus(ThreeHours, ThreeHours), reason: 'ThreeHours + ThreeHours');
  expect(Offset.zero, Offset.plus(ThreeHours, NegativeThreeHours), reason: 'ThreeHours + (-ThreeHours)');
  expect(TestObjects.CreateNegativeOffset(9, 0, 0), Offset.plus(NegativeTwelveHours, ThreeHours), reason: '-TwelveHours + ThreeHours');
}

// Instance method equivalents
@Test()
void MethodPlus_Zero_IsNeutralElement()
{
  expect(0, Offset.zero.add(Offset.zero).inMilliseconds, reason: '0 + 0');
  expect(TestObjects.CreatePositiveOffset(3, 0, 0), ThreeHours.add(Offset.zero), reason: 'ThreeHours + 0');
  expect(TestObjects.CreatePositiveOffset(3, 0, 0), Offset.zero.add(ThreeHours), reason: '0 + ThreeHours');
}

@Test()
void MethodPlus_NonZero()
{
  expect(TestObjects.CreatePositiveOffset(6, 0, 0), ThreeHours.add(ThreeHours), reason: 'ThreeHours + ThreeHours');
  expect(Offset.zero, ThreeHours.add(NegativeThreeHours), reason: 'ThreeHours + (-ThreeHours)');
  expect(TestObjects.CreateNegativeOffset(9, 0, 0), NegativeTwelveHours.add(ThreeHours), reason: '-TwelveHours + ThreeHours');
}
// #endregion

// #region operator -
@Test()
void OperatorMinus_Zero_IsNeutralElement()
{
  expect(Offset.zero, Offset.zero - Offset.zero, reason: '0 - 0');
  expect(TestObjects.CreatePositiveOffset(3, 0, 0), ThreeHours - Offset.zero, reason: 'ThreeHours - 0');
  expect(TestObjects.CreateNegativeOffset(3, 0, 0), Offset.zero - ThreeHours, reason: '0 - ThreeHours');
}

@Test()
void OperatorMinus_NonZero()
{
  expect(Offset.zero, ThreeHours - ThreeHours, reason: 'ThreeHours - ThreeHours');
  expect(TestObjects.CreatePositiveOffset(6, 0, 0), ThreeHours - NegativeThreeHours, reason: 'ThreeHours - (-ThreeHours)');
  expect(TestObjects.CreateNegativeOffset(15, 0, 0), NegativeTwelveHours - ThreeHours, reason: '-TwelveHours - ThreeHours');
}

// Static method equivalents
@Test()
void Subtract_Zero_IsNeutralElement()
{
  expect(Offset.zero, Offset.minus(Offset.zero, Offset.zero), reason: '0 - 0');
  expect(TestObjects.CreatePositiveOffset(3, 0, 0), Offset.minus(ThreeHours, Offset.zero), reason: 'ThreeHours - 0');
  expect(TestObjects.CreateNegativeOffset(3, 0, 0), Offset.minus(Offset.zero, ThreeHours), reason: '0 - ThreeHours');
}

@Test()
void Subtract_NonZero()
{
  expect(Offset.zero, Offset.minus(ThreeHours, ThreeHours), reason: 'ThreeHours - ThreeHours');
  expect(TestObjects.CreatePositiveOffset(6, 0, 0), Offset.minus(ThreeHours, NegativeThreeHours), reason: 'ThreeHours - (-ThreeHours)');
  expect(TestObjects.CreateNegativeOffset(15, 0, 0), Offset.minus(NegativeTwelveHours, ThreeHours), reason: '-TwelveHours - ThreeHours');
}

// Instance method equivalents
@Test()
void Minus_Zero_IsNeutralElement()
{
  expect(Offset.zero, Offset.zero.subtract(Offset.zero), reason: '0 - 0');
  expect(TestObjects.CreatePositiveOffset(3, 0, 0), ThreeHours.subtract(Offset.zero), reason: 'ThreeHours - 0');
  expect(TestObjects.CreateNegativeOffset(3, 0, 0), Offset.zero.subtract(ThreeHours), reason: '0 - ThreeHours');
}

@Test()
void Minus_NonZero()
{
  expect(Offset.zero, ThreeHours.subtract(ThreeHours), reason: 'ThreeHours - ThreeHours');
  expect(TestObjects.CreatePositiveOffset(6, 0, 0), ThreeHours.subtract(NegativeThreeHours), reason: 'ThreeHours - (-ThreeHours)');
  expect(TestObjects.CreateNegativeOffset(15, 0, 0), NegativeTwelveHours.subtract(ThreeHours), reason: '-TwelveHours - ThreeHours');
}
// #endregion

