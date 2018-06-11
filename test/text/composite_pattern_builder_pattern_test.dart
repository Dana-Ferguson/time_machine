// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_text.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import '../time_machine_testing.dart';

Future main() async {
  await runTests();
}

// See https://github.com/nodatime/nodatime/issues/607
@Test()
@TestCase(const ["2017-02-23T16:40:50.123456789"])
@TestCase(const ["2017-02-23T16:40:50.123"])
@TestCase(const ["2017-02-23T16:40:50"])
@TestCase(const ["2017-02-23T16:40"])
void IsoPattern(String text) {
  // We assert that the text round-trips. If it does, it's
  // reasonable to assume it parsed correctly...
  var shortPattern = LocalDateTimePattern.CreateWithInvariantCulture("uuuu'-'MM'-'dd'T'HH':'mm");
  var pattern = (new CompositePatternBuilder<LocalDateTime>()
    ..Add(LocalDateTimePattern.ExtendedIso, (_) => true)
    ..Add(shortPattern, (ldt) => ldt.second == 0 && ldt.nanosecondOfSecond == 0)).Build();
  var value = pattern
      .Parse(text)
      .Value;
  String formatted = pattern.Format(value);
  expect(text, formatted);
}

@Test()
void Format_NoValidPattern()
{
  var pattern = (new CompositePatternBuilder<LocalDate>()
    ..Add(LocalDatePattern.Iso, (_) => false)
    ..Add(LocalDatePattern.CreateWithInvariantCulture("yyyy"), (_) => false)).Build();

  expect(() => pattern.Format(new LocalDate(2017, 1, 1)), willThrow<FormatException>());
}

@Test()
void Parse() {
  var pattern = (new CompositePatternBuilder<LocalDate>()
    ..Add(LocalDatePattern.Iso, (_) => true)
    ..Add(LocalDatePattern.CreateWithInvariantCulture("yyyy"), (_) => false)).Build();
  expect(pattern.Parse("2017-03-20").Success, isTrue);
  expect(pattern.Parse("2017-03").Success, isFalse);
  expect(pattern.Parse("2017").Success, isTrue);
}

@Test()
void Build_Empty()
{
  var pattern = new CompositePatternBuilder<LocalDate>();
  expect(() => pattern.Build(), throwsStateError);
}

@Test() @SkipMe.unimplemented()
void Enumerators()
{
  var pattern1 = LocalDatePattern.Iso;
  var pattern2 = LocalDatePattern.CreateWithInvariantCulture("yyyy");

  var builder = (new CompositePatternBuilder<LocalDate>()
    ..Add(pattern1, (_) => true)
    ..Add(pattern2, (_) => false)).Build();

  /*
      CollectionAssert.AreEqual(new[] { pattern1, pattern2 }, builder.ToList());
      CollectionAssert.AreEqual(new[] { pattern1, pattern2 }, builder.OfType<LocalDatePattern>().ToList());
  */

  expect([ pattern1, pattern2 ], (builder as dynamic).patterns); //.ToList());
  expect([ pattern1, pattern2 ], (builder as dynamic).patterns as List<LocalDatePattern>); // builder.OfType<LocalDatePattern>().ToList());
}

