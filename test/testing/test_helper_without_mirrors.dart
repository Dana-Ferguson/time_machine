// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import 'test_helper.dart';

void setFunctions() {
  testOperatorComparisonFunction = TestHelperWithMirrors.TestOperatorComparison;
  testOperatorComparisonEqualityFunction = TestHelperWithMirrors.TestOperatorComparisonEquality;
  testOperatorEqualityFunction = TestHelperWithMirrors.TestOperatorEquality;
  print('Operator Functions without Mirrors!');
}

/// Provides methods to help run tests for some of the system interfaces and object support.
abstract class TestHelperWithMirrors
{
  /// Tests the less than (&lt;) and greater than (&gt;) operators if they exist on the object.
  ///
  /// <typeparam name='T'>The type to test.</typeparam>
  /// [value]: The base value.
  /// [equalValue]: The value equal to but not the same object as the base value.
  /// [greaterValue]: The values greater than the base value, in ascending order.
  static void TestOperatorComparison<T>(T tvalue, T tequalValue, List<T> tgreaterValues) {
    TestHelper.ValidateInput(tvalue, tequalValue, tgreaterValues, 'greaterValue');

    dynamic value = tvalue;
    dynamic equalValue = tequalValue;
    List greaterValues = tgreaterValues.map((v) => v as dynamic).toList();

    var greaterThan = true;
    var lessThan = true;
    
    // Comparisons only involving equal values
    if (greaterThan) {
      expect(value > null, isTrue, reason: 'value > null');
      expect(value > value, isFalse, reason: 'value > value');
      expect(value > equalValue, isFalse, reason: 'value > equalValue');
      expect(equalValue > value, isFalse, reason: 'equalValue > value');
    }
    if (lessThan) {
      expect(value < null, isFalse, reason: 'value < null');
      expect(value > value, isFalse, reason: 'value > value');
      expect(value > equalValue, isFalse, reason: 'value > equalValue');
      expect(equalValue > value, isFalse, reason: 'equalValue > value');
    }

    // Then comparisons involving the greater values
    for (var greaterValue in greaterValues) {
      if (greaterThan) {
        expect(value > greaterValue, isFalse, reason: 'value > greaterValue');
        expect(greaterValue > value, isTrue, reason: 'greaterValue > value');
      }
      if (lessThan) {
        expect(value < greaterValue, isTrue, reason: 'value < greaterValue');
        expect(greaterValue < value, isFalse, reason: 'greaterValue < value');
      }
      // Now move up to the next pair...
      value = greaterValue;
    }
  }

  /// Tests the equality (==), inequality (!=), less than (&lt;), greater than (&gt;), less than or equals (&lt;=),
  /// and greater than or equals (&gt;=) operators if they exist on the object.
  ///
  /// <typeparam name='T'>The type to test.</typeparam>
  /// [value]: The base value.
  /// [equalValue]: The value equal to but not the same object as the base value.
  /// [greaterValue]: The values greater than the base value, in ascending order.
  static void TestOperatorComparisonEquality<T>(T tvalue, T tequalValue, List<T> tgreaterValues) {
    for (var greaterValue in tgreaterValues) {
      TestOperatorEquality<T>(tvalue, tequalValue, greaterValue);
    }
    TestOperatorComparison<T>(tvalue, tequalValue, tgreaterValues);

    var greaterThanOrEqual = true;
    var lessThanOrEqual = true;

    dynamic value = tvalue;
    dynamic equalValue = tequalValue;
    List greaterValues = tgreaterValues.map((v) => v as dynamic).toList();

    // First the comparisons with equal values
    if (greaterThanOrEqual) {
      expect(value >= null, isTrue, reason: 'value >= null');
      expect(value >= value, isTrue, reason: 'value >= value');
      expect(value >= equalValue, isTrue, reason: 'value >= equalValue');
      expect(equalValue >= value, isTrue, reason: 'equalValue >= value');
    }
    if (lessThanOrEqual) {
      expect(value <= null, isFalse, reason: 'value <= null');
      expect(value <= value, isTrue, reason: 'value <= value');
      expect(value <= equalValue, isTrue, reason: 'value <= equalValue');
      expect(equalValue <= value, isTrue, reason: 'equalValue <= value');
    }

    // Now the 'greater than' values
    for (var greaterValue in greaterValues) {
      if (greaterThanOrEqual) {
        expect(value >= greaterValue, isFalse, reason: 'value >= greaterValue');
        expect(greaterValue >= value, isTrue, reason: 'greaterValue >= value');
      }
      if (lessThanOrEqual) {
        expect(value <= greaterValue, isTrue, reason: 'value <= greaterValue');
        expect(greaterValue <= value, isFalse, reason: 'greaterValue <= value');
      }
      // Now move up to the next pair...
      value = greaterValue;
    }
  }

  ///   Tests the equality and inequality operators (==, !=) if they exist on the object.
  ///
  /// <typeparam name='T'>The type to test.</typeparam>
  /// [value]: The base value.
  /// [equalValue]: The value equal to but not the same object as the base value.
  /// [unequalValue]: The value not equal to the base value.
  static void TestOperatorEquality<T>(T value, T equalValue, T unequalValue) {
    TestHelper.ValidateInput(value, equalValue, [unequalValue], 'unequalValue');

    // todo: we need a way to detect if operator == is overloaded (without mirrors)
    var equality = true;

    if (equality) {
      expect(value == null, isFalse, reason: 'value == null');
      expect(value == value, isTrue, reason: 'value == value');
      expect(value == equalValue, isTrue, reason: 'value == equalValue');
      expect(equalValue == value, isTrue, reason: 'equalValue == value');
      expect(value == unequalValue, isFalse, reason: 'value == unequalValue');
    }
  }
}