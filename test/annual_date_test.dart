import 'dart:async';

import 'package:time_machine/time_machine.dart';
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

@Test()
void Feb29()
{
  var date = new AnnualDate(2, 29);
  expect(29, date.day);
  expect(2, date.month);
  expect(new LocalDate(2016, 2, 29), date.inYear(2016));
  expect(date.isValidYear(2016), isTrue);
  expect(new LocalDate(2015, 2, 28), date.inYear(2015));
  expect(date.isValidYear(2015), isFalse);
}

@Test()
void June19()
{
  var date = new AnnualDate(6, 19);
  expect(19, date.day);
  expect(6, date.month);
  expect(new LocalDate(2016, 6, 19), date.inYear(2016));
  expect(date.isValidYear(2016), isTrue);
  expect(new LocalDate(2015, 6, 19), date.inYear(2015));
  expect(date.isValidYear(2015), isTrue);
}

@Test()
void Validation()
{
  // Feb 30th is invalid, but January 30th is fine
  expect(() => new AnnualDate(2, 30), throwsRangeError);
  // Assert.Throws<ArgumentOutOfRangeException>(() => new AnnualDate(2, 30));
  new AnnualDate(1, 30);

  // 13th month is invalid
  expect(() => new AnnualDate(13, 1), throwsRangeError);
  // Assert.Throws<ArgumentOutOfRangeException>(() => new AnnualDate(13, 1));
}

@Test()
void Equality()
{
  TestHelper.TestEqualsStruct(new AnnualDate(3, 15), new AnnualDate(3, 15), [new AnnualDate(4, 15), new AnnualDate(3, 16)]);
}

@Test()
void DefaultValueIsJanuary1st()
{
  // todo: I don't see a default constructor in the original C# code?
  expect(new AnnualDate(1, 1), new AnnualDate());
}

@Test()
void Comparision()
{
  TestHelper.TestCompareToStruct(new AnnualDate(6, 19), new AnnualDate(6, 19), [new AnnualDate(6, 20), new AnnualDate(7, 1)]);
}

@Test()
void Operators()
{
  TestHelper.TestOperatorComparisonEquality(new AnnualDate(6, 19), new AnnualDate(6, 19), [new AnnualDate(6, 20), new AnnualDate(7, 1)]);
}

@Test()
void ToStringTest()
{
  expect("02-01", new AnnualDate(2, 1).toString());
  expect("02-10", new AnnualDate(2, 10).toString());
  expect("12-01", new AnnualDate(12, 1).toString());
  expect("12-20", new AnnualDate(12, 20).toString());
}