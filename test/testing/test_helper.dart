// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import 'test_helper_interface.dart'
  if (dart.library.html) 'test_helper_without_mirrors.dart'
  if (dart.library.io) 'test_helper_with_mirrors.dart'
as helping_machine;

late Function<T>(T value, T equalValue, T unequalValue) testOperatorEqualityFunction;
late Function<T>(T value, T equalValue, List<T> greaterValues) testOperatorComparisonEqualityFunction;
late Function<T>(T value, T equalValue, List<T> greaterValues) testOperatorComparisonFunction;

void setFunctions() {
  helping_machine.setFunctions();
}

/// Provides methods to help run tests for some of the system interfaces and object support.
abstract class TestHelper
{
  ///   Tests the equality and inequality operators (==, !=) if they exist on the object.
  ///
  /// <typeparam name='T'>The type to test.</typeparam>
  /// [value]: The base value.
  /// [equalValue]: The value equal to but not the same object as the base value.
  /// [unequalValue]: The value not equal to the base value.
  static void TestOperatorEquality<T>(T value, T equalValue, T unequalValue) => testOperatorEqualityFunction;

  /// Tests the equality (==), inequality (!=), less than (&lt;), greater than (&gt;), less than or equals (&lt;=),
  /// and greater than or equals (&gt;=) operators if they exist on the object.
  ///
  /// <typeparam name='T'>The type to test.</typeparam>
  /// [value]: The base value.
  /// [equalValue]: The value equal to but not the same object as the base value.
  /// [greaterValue]: The values greater than the base value, in ascending order.
  static void TestOperatorComparisonEquality<T>(T value, T equalValue, List<T> greaterValues) => testOperatorComparisonEqualityFunction;

  /// Tests the less than (&lt;) and greater than (&gt;) operators if they exist on the object.
  ///
  /// <typeparam name='T'>The type to test.</typeparam>
  /// [value]: The base value.
  /// [equalValue]: The value equal to but not the same object as the base value.
  /// [greaterValue]: The values greater than the base value, in ascending order.
  static void TestOperatorComparison<T>(T value, T equalValue, List<T> greaterValues) => testOperatorComparisonFunction;

  /// Does nothing other than let us prove method or constructor calls don't throw.
  static void Consume<T>(T ignored)
  {
  }

  /// Asserts that calling the specified delegate with the specified value throws ArgumentException.
  static void AssertInvalid<TArg, TOut>(TOut Function(TArg) func, TArg arg)
  {
    expect(() => func(arg), throwsArgumentError);
  }

  /// Asserts that calling the specified delegate with the specified values throws ArgumentException.
  static void AssertInvalid2<TArg1, TArg2, TOut>(TOut Function(TArg1, TArg2) func, TArg1 arg1, TArg2 arg2)
  {
    // Assert.Throws<ArgumentException>(() => func(arg1, arg2));
    expect(() => func(arg1, arg2), throwsArgumentError);
  }

  /// Asserts that calling the specified delegate with the specified value throws ArgumentNullException.
  static void AssertArgumentNull<TArg, TOut>(TOut Function(TArg) func, TArg arg)
  {
    expect(() => func(arg), throwsArgumentError);
  // Assert.Throws<ArgumentNullException>(() => func(arg));
  }

  /// Asserts that calling the specified delegate with the specified value throws ArgumentOutOfRangeException.
  static void AssertOutOfRange<TArg, TOut>(TOut Function(TArg) func, TArg arg)
  {
    expect(() => func(arg), throwsRangeError);
  // Assert.Throws<ArgumentOutOfRangeException>(() => func(arg));
  }

  /// Asserts that calling the specified delegate with the specified value doesn't throw an exception.
  static void AssertValid<TArg, TOut>(TOut Function(TArg) func, TArg arg)
  {
    func(arg);
  }

  /// Asserts that calling the specified delegate with the specified values throws ArgumentOutOfRangeException.
  static void AssertOutOfRange2<TArg1, TArg2, TOut>(TOut Function(TArg1, TArg2) func, TArg1 arg1, TArg2 arg2)
  {
    // Assert.Throws<ArgumentOutOfRangeException>(() => func(arg1, arg2));
    expect(() => func(arg1, arg2), throwsRangeError);
  }

  /// Asserts that calling the specified delegate with the specified values throws ArgumentNullException.
  static void AssertArgumentNull2<TArg1, TArg2, TOut>(TOut Function(TArg1, TArg2) func, TArg1 arg1, TArg2 arg2)
  {
    // Assert.Throws<ArgumentNullException>(() => func(arg1, arg2));
    expect(() => func(arg1, arg2), throwsArgumentError);
  }

  /// Asserts that calling the specified delegate with the specified values doesn't throw an exception.
  static void AssertValid2<TArg1, TArg2, TOut>(TOut Function(TArg1, TArg2) func, TArg1 arg1, TArg2 arg2)
  {
    func(arg1, arg2);
  }

  /// Asserts that calling the specified delegate with the specified values throws ArgumentOutOfRangeException.
  static void AssertOutOfRange3<TArg1, TArg2, TArg3, TOut>(TOut Function(TArg1, TArg2, TArg3) func, TArg1 arg1, TArg2 arg2, TArg3 arg3)
  {
    // Assert.Throws<ArgumentOutOfRangeException>(() => func(arg1, arg2, arg3));
    expect(() => func(arg1, arg2, arg3), throwsRangeError);
  }

  /// Asserts that calling the specified delegate with the specified values throws ArgumentNullException.
  static void AssertArgumentNull3<TArg1, TArg2, TArg3, TOut>(TOut Function(TArg1, TArg2, TArg3) func, TArg1 arg1, TArg2 arg2, TArg3 arg3)
  {
    // Assert.Throws<ArgumentNullException>(() => func(arg1, arg2, arg3));
    expect(() => func(arg1, arg2, arg3), throwsNullThrownError);
  }

  /// Asserts that calling the specified delegate with the specified values doesn't throw an exception.
  static void AssertValid3<TArg1, TArg2, TArg3, TOut>(TOut Function(TArg1, TArg2, TArg3) func, TArg1 arg1, TArg2 arg2, TArg3 arg3)
  {
    func(arg1, arg2, arg3);
  }

  /// Asserts that the given operation throws one of InvalidOperationException, ArgumentException (including
  /// ArgumentOutOfRangeException) or OverflowException. (It's hard to always be consistent bearing in mind
  /// one method calling another.)
  static void AssertOverflow<TArg1, TOut>(TOut Function(TArg1) func, TArg1 arg1)
  {
    AssertOverflow_Action(() => func(arg1));
  }

  /// Typically used to report a list of items (e.g. reflection members) that fail a condition, one per line.
  static void AssertNoFailures<T>(Iterable<T> failures, String Function(T) failureFormatter)
  {
    var failureList = failures.toList();
    if (failureList.isEmpty)
    {
      return;
    }
    var message = "Failures: ${failureList.length}\n${failureList.map((i) => failureFormatter(i))}";
    throw Exception(message);
  }

//  static void AssertNoFailures<T>(Iterable<T> failures, String failureFormatter(T), TestExemptionCategory category)
//  // where T : MemberInfo
//  => AssertNoFailures(failures.where(member => !IsExempt(member, category)), failureFormatter);

//  static bool IsExempt(MemberInfo member, TestExemptionCategory category) =>
//      member.GetCustomAttributes(typeof(TestExemptionAttribute), false)
//          .Cast<TestExemptionAttribute>()
//          .Any(e => e.Category == category);

  /// Asserts that the given operation throws one of InvalidOperationException, ArgumentException (including
  /// ArgumentOutOfRangeException) or OverflowException. (It's hard to always be consistent bearing in mind
  /// one method calling another.)
  static void AssertOverflow_Action(Function() action)
  {
    try
    {
      action();
      throw Exception('Expected OverflowException, ArgumentException, ArgumentOutOfRangeException or InvalidOperationException');
    }
    // todo: we don't really overflow
    //    on OverflowException catch (e)
    //    {
    //    }
    on ArgumentError catch (e)
    {
    //Assert.IsTrue(e.GetType() == typeof(ArgumentException) || e.GetType() == typeof(ArgumentOutOfRangeException),
    //'Exception should not be a subtype of ArgumentException, other than ArgumentOutOfRangeException');
      print(e);
    }
    catch (InvalidOperationException)
    // ignore: empty_catches
    {
    }
  }

//  static void TestComparerStruct2<T>(Comparable<T> comparer, T value, T equalValue, T greaterValue) // where T : struct
//  {
//    Comparable.compare(a, b);
//    expect(comparer.Compare(value, equalValue), 0);
//    expect(comparer.Compare(greaterValue, value).sign, 1);
//    expect(comparer.Compare(value, greaterValue).sign, -1);
//
//    //Assert.AreEqual(0, comparer.Compare(value, equalValue));
//    //Assert.AreEqual(1, math.Sign(comparer.Compare(greaterValue, value)));
//    //Assert.AreEqual(-1, Math.Sign(comparer.Compare(value, greaterValue)));
//  }

  static void TestComparerStruct<T>(Comparator<T> comparer, T value, T equalValue, T greaterValue)
  {
    expect(comparer(value, equalValue), 0);
    expect(comparer(greaterValue, value).sign, 1);
    expect(comparer(value, greaterValue).sign, -1);

  //Assert.AreEqual(0, comparer.Compare(value, equalValue));
  //Assert.AreEqual(1, math.Sign(comparer.Compare(greaterValue, value)));
  //Assert.AreEqual(-1, Math.Sign(comparer.Compare(value, greaterValue)));
  }


  ///   Tests the [IComparable{T}.CompareTo] method for reference objects.
  ///
  /// <typeparam name='T'>The type to test.</typeparam>
  /// [value]: The base value.
  /// [equalValue]: The value equal to but not the same object as the base value.
  /// [greaterValue]: The values greater than the base value, in ascending order.
  static void TestCompareToClass<T extends Comparable<T?>>(T value, T equalValue, List<T> greaterValues)
  {
    ValidateInput(value, equalValue, greaterValues, 'greaterValue');
    expect(value.compareTo(null) > 0, isTrue, reason: 'value.CompareTo<T>(null)');
    expect(value.compareTo(value) == 0, isTrue, reason: 'value.CompareTo<T>(value)');
    expect(value.compareTo(equalValue) == 0, isTrue, reason: 'value.CompareTo<T>(equalValue)');
    expect(equalValue.compareTo(value) == 0, isTrue, reason: 'equalValue.CompareTo<T>(value)');
    for (var greaterValue in greaterValues) {
      expect(value.compareTo(greaterValue) < 0, isTrue, reason: 'value.CompareTo<T>(greaterValue)');
      expect(greaterValue.compareTo(value) > 0, isTrue, reason: 'greaterValue.CompareTo<T>(value)');
      // Now move up to the next pair...
      value = greaterValue;
    }
  }

  /// Tests the [IComparable{T}.CompareTo] method for value objects.
  ///
  /// <typeparam name='T'>The type to test.</typeparam>
  /// [value]: The base value.
  /// [equalValue]: The value equal to but not the same object as the base value.
  /// [greaterValue]: The values greater than the base value, in ascending order.
  static void TestCompareToStruct<T extends Comparable<T>>(T value, T equalValue, List<T> greaterValues) // where T : struct, IComparable<T>
  {
    TestCompareToClass<T>(value, equalValue, greaterValues);
  //    Assert.AreEqual(value.CompareTo(value), 0, 'value.CompareTo(value)');
  //    Assert.AreEqual(value.CompareTo(equalValue), 0, 'value.CompareTo(equalValue)');
  //    Assert.AreEqual(equalValue.CompareTo(value), 0, 'equalValue.CompareTo(value)');
  //    for (var greaterValue in greaterValues) {
  //      Assert.Less(value.CompareTo(greaterValue), 0, 'value.CompareTo(greaterValue)');
  //      Assert.Greater(greaterValue.CompareTo(value), 0, 'greaterValue.CompareTo(value)');
  //      // Now move up to the next pair...
  //      value = greaterValue;
  //    }
  }

//  /// <summary>
//  /// Tests the <see cref='IComparable.CompareTo' /> method - note that this is the non-generic interface.
//  /// </summary>
//  /// <typeparam name='T'>The type to test.</typeparam>
//  /// <param name='value'>The base value.</param>
//  /// <param name='equalValue'>The value equal to but not the same object as the base value.</param>
//  /// <param name='greaterValue'>The values greater than the base value, in ascending order.</param>
//  static void TestNonGenericCompareTo<T>(T value, T equalValue, List<T> greaterValues) // where T : IComparable
//  {
//  // Just type the values as plain IComparable for simplicity
//  IComparable value2 = value;
//  IComparable equalValue2 = equalValue;
//
//  ValidateInput(value2, equalValue2, greaterValues, 'greaterValues');
//  Assert.Greater(value2.CompareTo(null), 0, 'value.CompareTo(null)');
//  Assert.AreEqual(value2.CompareTo(value2), 0, 'value.CompareTo(value)');
//  Assert.AreEqual(value2.CompareTo(equalValue2), 0, 'value.CompareTo(equalValue)');
//  Assert.AreEqual(equalValue2.CompareTo(value2), 0, 'equalValue.CompareTo(value)');
//
//  for (IComparable greaterValue in greaterValues)
//  {
//  Assert.Less(value2.CompareTo(greaterValue), 0, 'value.CompareTo(greaterValue)');
//  Assert.Greater(greaterValue.CompareTo(value2), 0, 'greaterValue.CompareTo(value)');
//  // Now move up to the next pair...
//  value2 = greaterValue;
//  }
//  Assert.Throws<ArgumentException>(() => value2.CompareTo(new object()));
//  }

  /// Tests the IEquatable.Equals method for reference objects. Also tests the
  /// object equals method.
  ///
  /// <typeparam name='T'>The type to test.</typeparam>
  /// [value]: The base value.
  /// [equalValue]: The value equal to but not the same object as the base value.
  /// [unequalValue]: Values not equal to the base value.
  static void TestEqualsClass<T>(T value, T equalValue, List<T> unequalValues) // where T : class, IEquatable<T>
  {
    TestObjectEquals(value, equalValue, unequalValues);
    expect(value == (null), isFalse, reason: 'value.Equals<T>(null)');
    expect(value == (value), isTrue, reason: 'value.Equals<T>(value)');
    expect(value == (equalValue), isTrue, reason: 'value.Equals<T>(equalValue)');
    expect(equalValue == (value), isTrue, reason: 'equalValue.Equals<T>(value)');
    for (var unequal in unequalValues) {
      expect(value == (unequal), isFalse, reason: 'value.Equals<T>(unequalValue)');
    }
  }

  /// Tests the IEquatable.Equals method for value objects. Also tests the
  /// object equals method.
  ///
  /// <typeparam name='T'>The type to test.</typeparam>
  /// [value]: The base value.
  /// [equalValue]: The value equal to but not the same object as the base value.
  /// [unequalValue]: The value not equal to the base value.
  static void TestEqualsStruct<T>(T value, T equalValue, Iterable<T> unequalValues) // where T : struct, IEquatable<T>
  {
    // var unequalArray = unequalValues.toList(); // unequalValues.Cast<object>().ToArray();
    TestEqualsClass(value, equalValue, unequalValues.toList());
  //    TestObjectEquals(value, equalValue, unequalArray);
  //    Assert.True(value == (value), reason: 'value.Equals<T>(value)');
  //    Assert.True(value == (equalValue), reason: 'value.Equals<T>(equalValue)');
  //    Assert.True(equalValue == (value), reason: 'equalValue.Equals<T>(value)');
  //    for (var unequalValue in unequalValues) {
  //      Assert.False(value == (unequalValue), reason: 'value.Equals<T>(unequalValue)');
  //    }
  }

  /// Tests the Object.Equals method.
  ///
  /// It takes two equal values, and then an array of values which should not be equal to the first argument.
  ///
  /// [value]: The base value.
  /// [equalValue]: The value equal to but not the same object as the base value.
  /// [unequalValue]: The value not equal to the base value.
  static void TestObjectEquals(dynamic? value, dynamic equalValue, List<dynamic> unequalValues) {
    ValidateInput(value, equalValue, unequalValues, 'unequalValue');
    expect(value == null, isFalse, reason: 'value.Equals(null)');
    expect(value == (value), isTrue, reason: 'value.Equals(value)');
    expect(value == (equalValue), isTrue, reason: 'value.Equals(equalValue)');
    expect(equalValue == (value), isTrue, reason: 'equalValue.Equals(value)');
    for (var unequalValue in unequalValues) {
      expect(value == (unequalValue), isFalse, reason: 'value.Equals(unequalValue)');
    }
    expect(value.hashCode, value.hashCode, reason: 'hashCode twice for same object');
    expect(value.hashCode, equalValue.hashCode, reason: 'hashCode for two different but equal objects');
  }

  /// Validates that the input parameters to the test methods are valid.
  ///
  /// [value]: The base value.
  /// [equalValue]: The value equal to but not the same object as the base value.
  /// [unequalValues]: The values not equal to the base value.
  /// [unequalName]: The name to use in 'not equal value' error messages.
  static void ValidateInput(Object? value, dynamic equalValue, List unequalValues, String unequalName) {
    //Assert.NotNull(value, 'value cannot be null in TestObjectEquals() method');
    //Assert.NotNull(equalValue, 'equalValue cannot be null in TestObjectEquals() method');
    //Assert.AreNotSame(value, equalValue, 'value and equalValue MUST be different objects');
    expect(value, isNotNull, reason: 'value cannot be null in TestObjectEquals() method');
    expect(equalValue, isNotNull, reason: 'equalValue cannot be null in TestObjectEquals() method');
    expect(identical(equalValue, value), isFalse, reason: 'value and equalValue MUST be different objects');

    for (var unequalValue in unequalValues) {
      expect(unequalName, isNotNull, reason: unequalName + ' cannot be null in TestObjectEquals() method');
      expect(identical(value, unequalValue), isFalse, reason: unequalName + ' and value MUST be different objects');

    //Assert.NotNull(unequalValue, unequalName + ' cannot be null in TestObjectEquals() method');
    //Assert.AreNotSame(value, unequalValue, unequalName + ' and value MUST be different objects');
    }
  }

  /// Validates that the input parameters to the test methods are valid.
  ///
  /// [value]: The base value.
  /// [equalValue]: The value equal to but not the same object as the base value.
  /// [unequalValue]: The value not equal to the base value.
  /// [unequalName]: The name to use in 'not equal value' error messages.
  static void ValidateInput_Single(Object value, Object equalValue, Object unequalValue, String unequalName)
  {
    ValidateInput(value, equalValue, [ unequalValue ], unequalName);
  }
}

