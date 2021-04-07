// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import 'time_machine_testing.dart';

Future main() async {
  await runTests();
}

final Iterable<String> SupportedIds = CalendarSystem.ids.toList();
final List<CalendarSystem> SupportedCalendars = SupportedIds.map(CalendarSystem.forId).toList();

@Test()
@TestCaseSource(Symbol('SupportedIds'))
void ValidId(String id)
{
  expect(CalendarSystem.forId(id), const TypeMatcher<CalendarSystem>());
// Assert.IsInstanceOf<CalendarSystem>(CalendarSystem.ForId(id));
}

@Test()
@TestCaseSource(Symbol('SupportedIds'))
void IdsAreCaseSensitive(String id)
{
  expect(() => CalendarSystem.forId(id.toLowerCase()), throwsArgumentError);
// Assert.Throws<KeyNotFoundException>(() => CalendarSystem.ForId(id.ToLowerInvariant()));
}

@Test()
void AllIdsGiveDifferentCalendars()
{
    var allCalendars = SupportedIds.map(CalendarSystem.forId).toList();
    expect(SupportedIds.length, allCalendars.toSet().length);
// Assert.AreEqual(SupportedIds.Count(), allCalendars.Distinct().Count());
}

@Test()
void BadId()
{
  expect(() => CalendarSystem.forId('bad'), throwsArgumentError);
// Assert.Throws<KeyNotFoundException>(() => CalendarSystem.ForId('bad'));
}

@Test()
void NoSubstrings()
{
    // CompareInfo comparison = Culture.invariantCulture.CompareInfo;
    for (var firstId in CalendarSystem.ids)
    {
        for (var secondId in CalendarSystem.ids)
        {
            // We're looking for firstId being a substring of secondId, which can only
            // happen if firstId is shorter...
            if (firstId.length >= secondId.length)
            {
                continue;
            }
            expect(stringOrdinalIgnoreCaseCompare(firstId, 0, secondId, 0, firstId.length),
                isNot(0),
                reason: '$firstId is a leading substring of $secondId');

        // Assert.AreNotEqual(0, comparison.Compare(firstId, 0, firstId.length, secondId, 0, firstId.length, CompareOptions.IgnoreCase),
        //     '$firstId is a leading substring of $secondId');
        }
    }
}

// Ordinals are similar enough to IDs to keep the tests in this file too...

@Test()
@TestCaseSource(Symbol('SupportedCalendars'))
void ForOrdinal_Roundtrip(CalendarSystem calendar)
{
  expect(calendar, ICalendarSystem.forOrdinal(ICalendarSystem.ordinal(calendar)));
  // Assert.AreSame(calendar, CalendarSystem.ForOrdinal(calendar.Ordinal));
}

@Test()
@TestCaseSource(Symbol('SupportedCalendars'))
void ForOrdinalUncached_Roundtrip(CalendarSystem calendar)
{
  var target = ICalendarSystem.forOrdinalUncached(ICalendarSystem.ordinal(calendar));
  expect(identical(calendar, target), isTrue);
  // Assert.AreSame(calendar, CalendarSystem.ForOrdinalUncached(calendar.Ordinal));
}

@Test()
void ForOrdinalUncached_Invalid()
{
  expect(() => ICalendarSystem.forOrdinalUncached(const CalendarOrdinal(9999)), throwsStateError);
// Assert.Throws<InvalidOperationException>(() => CalendarSystem.ForOrdinalUncached((CalendarOrdinal)9999));
}
