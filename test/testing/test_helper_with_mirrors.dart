// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:mirrors';
// import 'package:time_machine/src/time_machine_internal.dart';
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

// import 'test_fx.dart';
// import 'time_matchers.dart';

import 'test_helper.dart';

void setFunctions() {
  testOperatorComparisonFunction = TestHelperWithMirrors.TestOperatorComparison;
  testOperatorComparisonEqualityFunction = TestHelperWithMirrors.TestOperatorComparisonEquality;
  testOperatorEqualityFunction = TestHelperWithMirrors.TestOperatorEquality;
  print('Operator Functions with Mirrors!');
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
  static void TestOperatorComparison<T>(T value, T equalValue, List<T> greaterValues) {
    TestHelper.ValidateInput(value, equalValue, greaterValues, 'greaterValue');

    // Note: Dart is doing type erasure??? -- T becomes dynamic at runtime when it shouldn't be.
    // todo: re-evaluate after Dart 2.0
    InstanceMirror valueMirror = reflect(value);
    InstanceMirror equalValueMirror = reflect(equalValue);
    ClassMirror classMirror = reflectClass(/*T*/value.runtimeType);

    var gt = const Symbol('>');
    var lt = const Symbol('<');
    var greaterThan = classMirror.declarations[gt];
    var lessThan = classMirror.declarations[lt];

// print(instanceMirror.invoke(gt.simpleName, [null]).reflectee);
// print(instanceMirror.invoke(lt.simpleName, [null]).reflectee);

    // Comparisons only involving equal values
    if (greaterThan != null) {
      // if (!type.GetTypeInfo().IsValueType)
      {
        expect(valueMirror.invoke(gt, [null]).reflectee, isTrue, reason: 'value > null');
      // expect(greaterThan.Invoke(null, [ null, value ], isFalse, reason: 'null > value');
      }
      expect(valueMirror.invoke(gt, [value]).reflectee, isFalse, reason: 'value > value');
      expect(valueMirror.invoke(gt, [equalValue]).reflectee, isFalse, reason: 'value > equalValue');
      expect(equalValueMirror.invoke(gt, [value]).reflectee, isFalse, reason: 'equalValue > value');
    }
    if (lessThan != null) {
      // if (!type.GetTypeInfo().IsValueType)
      {
        expect(valueMirror.invoke(lt, [null]).reflectee, isFalse, reason: 'value < null');
      // expect(lessThan.Invoke(null, [ null, value ], isTrue, reason: 'null < value');
      }
      expect(valueMirror.invoke(lt, [value]).reflectee, isFalse, reason: 'value > value');
      expect(valueMirror.invoke(lt, [equalValue]).reflectee, isFalse, reason: 'value > equalValue');
      expect(equalValueMirror.invoke(lt, [value]).reflectee, isFalse, reason: 'equalValue > value');
    }

    // Then comparisons involving the greater values
    for (var greaterValue in greaterValues) {
      InstanceMirror greaterValueMirror = reflect(greaterValue);
      if (greaterThan != null) {
        expect(valueMirror.invoke(gt, [greaterValue]).reflectee, isFalse, reason: 'value > greaterValue');
        expect(greaterValueMirror.invoke(gt, [value]).reflectee, isTrue, reason: 'greaterValue > value');
      }
      if (lessThan != null) {
        expect(valueMirror.invoke(lt, [greaterValue]).reflectee, isTrue, reason: 'value < greaterValue');
        expect(greaterValueMirror.invoke(lt, [value]).reflectee, isFalse, reason: 'greaterValue < value');
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
  static void TestOperatorComparisonEquality<T>(T value, T equalValue, List<T> greaterValues) {
    for (var greaterValue in greaterValues) {
      TestOperatorEquality<T>(value, equalValue, greaterValue);
    }
    TestOperatorComparison<T>(value, equalValue, greaterValues);

    InstanceMirror valueMirror = reflect(value);
    InstanceMirror equalValueMirror = reflect(equalValue);
    ClassMirror classMirror = reflectClass(/*T*/value.runtimeType);

    var gte = const Symbol('>=');
    var lte = const Symbol('<=');
    var greaterThanOrEqual = classMirror.declarations[gte];
    var lessThanOrEqual = classMirror.declarations[lte];

    // First the comparisons with equal values
    if (greaterThanOrEqual != null) {
      //if (!type.GetTypeInfo().IsValueType)
      {
        expect(valueMirror.invoke(gte, [null]).reflectee, isTrue, reason: 'value >= null');
      // expect(valueMirror.invoke(gte, [value]), greaterThanOrEqual.Invoke(null, [ null, value ], isFalse, reason: 'null >= value');
      }
      expect(valueMirror.invoke(gte, [value]).reflectee, isTrue, reason: 'value >= value');
      expect(valueMirror.invoke(gte, [equalValue]).reflectee, isTrue, reason: 'value >= equalValue');
      expect(equalValueMirror.invoke(gte, [value]).reflectee, isTrue, reason: 'equalValue >= value');
    }
    if (lessThanOrEqual != null) {
      //if (!type.GetTypeInfo().IsValueType)
      {
        expect(valueMirror.invoke(lte, [null]).reflectee, isFalse, reason: 'value <= null');
      // expect(lessThanOrEqual.Invoke(null, [ null, value ], isTrue, reason: 'null <= value');
      }
      expect(valueMirror.invoke(lte, [value]).reflectee, isTrue, reason: 'value <= value');
      expect(valueMirror.invoke(lte, [equalValue]).reflectee, isTrue, reason: 'value <= equalValue');
      expect(equalValueMirror.invoke(lte, [value]).reflectee, isTrue, reason: 'equalValue <= value');
    }

    // Now the 'greater than' values
    for (var greaterValue in greaterValues) {
      InstanceMirror greaterValueMirror = reflect(greaterValue);
      if (greaterThanOrEqual != null) {
        expect(valueMirror.invoke(gte, [greaterValue]).reflectee, isFalse, reason: 'value >= greaterValue');
        expect(greaterValueMirror.invoke(gte, [value]).reflectee, isTrue, reason: 'greaterValue >= value');
      }
      if (lessThanOrEqual != null) {
        expect(valueMirror.invoke(lte, [greaterValue]).reflectee, isTrue, reason: 'value <= greaterValue');
        expect(greaterValueMirror.invoke(lte, [value]).reflectee, isFalse, reason: 'greaterValue <= value');
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

    InstanceMirror valueMirror = reflect(value);
    InstanceMirror equalValueMirror = reflect(equalValue);
    ClassMirror classMirror = reflectClass(/*T*/value.runtimeType);

    var equ = const Symbol('==');
    var equality = classMirror.declarations[equ];

    if (equality != null) {
      // if (!type.GetTypeInfo().IsValueType)
      {
        // expect(equality.Invoke(null, [ null, null ], isTrue, reason: 'null == null');
        expect(valueMirror.invoke(equ, [null]).reflectee, isFalse, reason: 'value == null');
      // expect(equality.Invoke(null, [ null, value ], isFalse, reason: 'null == value');
      }
      expect(valueMirror.invoke(equ, [value]).reflectee, isTrue, reason: 'value == value');
      expect(valueMirror.invoke(equ, [equalValue]).reflectee, isTrue, reason: 'value == equalValue');
      expect(equalValueMirror.invoke(equ, [value]).reflectee, isTrue, reason: 'equalValue == value');
      expect(valueMirror.invoke(equ, [unequalValue]).reflectee, isFalse, reason: 'value == unequalValue');
    }
  }
}

