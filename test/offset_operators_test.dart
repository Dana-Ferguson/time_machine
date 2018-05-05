// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/OffsetTest.Operators.cs
// 7208243  on Mar 18, 2015

import 'dart:async';
import 'dart:math' as math;

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

final Offset ThreeHours = TestObjects.CreatePositiveOffset(3, 0, 0);
final Offset NegativeThreeHours = TestObjects.CreateNegativeOffset(3, 0, 0);
final Offset NegativeTwelveHours = TestObjects.CreateNegativeOffset(12, 0, 0);

@Test()
void IEquatableIComparable_Tests()
{
  var value = new Offset.fromSeconds(12345);
  var equalValue = new Offset.fromSeconds(12345);
  var greaterValue = new Offset.fromSeconds(54321);

  TestHelper.TestEqualsStruct(value, equalValue, [greaterValue]);
  TestHelper.TestCompareToStruct(value, equalValue, [greaterValue]);
  // TestHelper.TestNonGenericCompareTo(value, equalValue, greaterValue);
  TestHelper.TestOperatorComparisonEquality(value, equalValue, [greaterValue]);
}

/* No unary plus in Dart
@Test()
void UnaryPlusOperator()
{
  expect(Offset.zero, +Offset.zero, reason: "+ 0");
  expect(new Offset.fromSeconds(1), + new Offset.fromSeconds(1), reason: "+ 1");
  expect(new Offset.fromSeconds(-7), + new Offset.fromSeconds(-7), reason: "+ (-7)");
}*/

@Test()
void NegateOperator()
{
  expect(Offset.zero, -Offset.zero, reason: "-0");
  expect(new Offset.fromSeconds(-1), -new Offset.fromSeconds(1), reason: "-1");
  expect(new Offset.fromSeconds(7), -new Offset.fromSeconds(-7), reason: "- (-7)");
}

@Test()
void NegateMethod()
{
  expect(Offset.zero, Offset.negate(Offset.zero), reason: "-0");
  expect(new Offset.fromSeconds(-1), Offset.negate(new Offset.fromSeconds(1)), reason: "-1");
  expect(new Offset.fromSeconds(7), Offset.negate(new Offset.fromSeconds(-7)), reason: "- (-7)");
}

// #region operator +
@Test()
void OperatorPlus_Zero_IsNeutralElement()
{
  expect(0, (Offset.zero + Offset.zero).seconds, reason: "0 + 0");
  expect(TestObjects.CreatePositiveOffset(3, 0, 0), ThreeHours + Offset.zero, reason: "ThreeHours + 0");
  expect(TestObjects.CreatePositiveOffset(3, 0, 0), Offset.zero + ThreeHours, reason: "0 + ThreeHours");
}

@Test()
void OperatorPlus_NonZero()
{
  expect(TestObjects.CreatePositiveOffset(6, 0, 0), ThreeHours + ThreeHours, reason: "ThreeHours + ThreeHours");
  expect(Offset.zero, ThreeHours + NegativeThreeHours, reason: "ThreeHours + (-ThreeHours)");
  expect(TestObjects.CreateNegativeOffset(9, 0, 0), NegativeTwelveHours + ThreeHours, reason: "-TwelveHours + ThreeHours");
}

// Static method equivalents
@Test()
void MethodAdd_Zero_IsNeutralElement()
{
  expect(0, Offset.add(Offset.zero, Offset.zero).milliseconds, reason: "0 + 0");
  expect(TestObjects.CreatePositiveOffset(3, 0, 0), Offset.add(ThreeHours, Offset.zero), reason: "ThreeHours + 0");
  expect(TestObjects.CreatePositiveOffset(3, 0, 0), Offset.add(Offset.zero, ThreeHours), reason: "0 + ThreeHours");
}

@Test()
void MethodAdd_NonZero()
{
  expect(TestObjects.CreatePositiveOffset(6, 0, 0), Offset.add(ThreeHours, ThreeHours), reason: "ThreeHours + ThreeHours");
  expect(Offset.zero, Offset.add(ThreeHours, NegativeThreeHours), reason: "ThreeHours + (-ThreeHours)");
  expect(TestObjects.CreateNegativeOffset(9, 0, 0), Offset.add(NegativeTwelveHours, ThreeHours), reason: "-TwelveHours + ThreeHours");
}

// Instance method equivalents
@Test()
void MethodPlus_Zero_IsNeutralElement()
{
  expect(0, Offset.zero.plus(Offset.zero).milliseconds, reason: "0 + 0");
  expect(TestObjects.CreatePositiveOffset(3, 0, 0), ThreeHours.plus(Offset.zero), reason: "ThreeHours + 0");
  expect(TestObjects.CreatePositiveOffset(3, 0, 0), Offset.zero.plus(ThreeHours), reason: "0 + ThreeHours");
}

@Test()
void MethodPlus_NonZero()
{
  expect(TestObjects.CreatePositiveOffset(6, 0, 0), ThreeHours.plus(ThreeHours), reason: "ThreeHours + ThreeHours");
  expect(Offset.zero, ThreeHours.plus(NegativeThreeHours), reason: "ThreeHours + (-ThreeHours)");
  expect(TestObjects.CreateNegativeOffset(9, 0, 0), NegativeTwelveHours.plus(ThreeHours), reason: "-TwelveHours + ThreeHours");
}
// #endregion

// #region operator -
@Test()
void OperatorMinus_Zero_IsNeutralElement()
{
  expect(Offset.zero, Offset.zero - Offset.zero, reason: "0 - 0");
  expect(TestObjects.CreatePositiveOffset(3, 0, 0), ThreeHours - Offset.zero, reason: "ThreeHours - 0");
  expect(TestObjects.CreateNegativeOffset(3, 0, 0), Offset.zero - ThreeHours, reason: "0 - ThreeHours");
}

@Test()
void OperatorMinus_NonZero()
{
  expect(Offset.zero, ThreeHours - ThreeHours, reason: "ThreeHours - ThreeHours");
  expect(TestObjects.CreatePositiveOffset(6, 0, 0), ThreeHours - NegativeThreeHours, reason: "ThreeHours - (-ThreeHours)");
  expect(TestObjects.CreateNegativeOffset(15, 0, 0), NegativeTwelveHours - ThreeHours, reason: "-TwelveHours - ThreeHours");
}

// Static method equivalents
@Test()
void Subtract_Zero_IsNeutralElement()
{
  expect(Offset.zero, Offset.subtract(Offset.zero, Offset.zero), reason: "0 - 0");
  expect(TestObjects.CreatePositiveOffset(3, 0, 0), Offset.subtract(ThreeHours, Offset.zero), reason: "ThreeHours - 0");
  expect(TestObjects.CreateNegativeOffset(3, 0, 0), Offset.subtract(Offset.zero, ThreeHours), reason: "0 - ThreeHours");
}

@Test()
void Subtract_NonZero()
{
  expect(Offset.zero, Offset.subtract(ThreeHours, ThreeHours), reason: "ThreeHours - ThreeHours");
  expect(TestObjects.CreatePositiveOffset(6, 0, 0), Offset.subtract(ThreeHours, NegativeThreeHours), reason: "ThreeHours - (-ThreeHours)");
  expect(TestObjects.CreateNegativeOffset(15, 0, 0), Offset.subtract(NegativeTwelveHours, ThreeHours), reason: "-TwelveHours - ThreeHours");
}

// Instance method equivalents
@Test()
void Minus_Zero_IsNeutralElement()
{
  expect(Offset.zero, Offset.zero.minus(Offset.zero), reason: "0 - 0");
  expect(TestObjects.CreatePositiveOffset(3, 0, 0), ThreeHours.minus(Offset.zero), reason: "ThreeHours - 0");
  expect(TestObjects.CreateNegativeOffset(3, 0, 0), Offset.zero.minus(ThreeHours), reason: "0 - ThreeHours");
}

@Test()
void Minus_NonZero()
{
  expect(Offset.zero, ThreeHours.minus(ThreeHours), reason: "ThreeHours - ThreeHours");
  expect(TestObjects.CreatePositiveOffset(6, 0, 0), ThreeHours.minus(NegativeThreeHours), reason: "ThreeHours - (-ThreeHours)");
  expect(TestObjects.CreateNegativeOffset(15, 0, 0), NegativeTwelveHours.minus(ThreeHours), reason: "-TwelveHours - ThreeHours");
}
// #endregion
