// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:collection';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
// import 'package:matcher/matcher.dart';

import '../time_machine_testing.dart';

/// Tests for HebrewYearMonthDayCalculator via the Hebrew CalendarSystem.
/// See http://blog.nodatime.org/2014/06/hebrew-calendar-cheat-sheet.html
/// for sample year information.
Future main() async {
  await runTests();
}

@Test()
void IsLeapYear()
{
  var bclIsLeapYear = HashSet.from([5345, 5347, 5350, 5353, 5356, 5358, 5361, 5364, 5366, 5369, 5372, 5375, 5377, 5380, 5383, 5385, 5388, 5391, 5394, 5396, 5399, 5402, 5404, 5407, 5410, 5413, 5415, 5418, 5421, 5423, 5426, 5429, 5432, 5434, 5437, 5440, 5442, 5445, 5448, 5451, 5453, 5456, 5459, 5461, 5464, 5467, 5470, 5472, 5475, 5478, 5480, 5483, 5486, 5489, 5491, 5494, 5497, 5499, 5502, 5505, 5508, 5510, 5513, 5516, 5518, 5521, 5524, 5527, 5529, 5532, 5535, 5537, 5540, 5543, 5546, 5548, 5551, 5554, 5556, 5559, 5562, 5565, 5567, 5570, 5573, 5575, 5578, 5581, 5584, 5586, 5589, 5592, 5594, 5597, 5600, 5603, 5605, 5608, 5611, 5613, 5616, 5619, 5622, 5624, 5627, 5630, 5632, 5635, 5638, 5641, 5643, 5646, 5649, 5651, 5654, 5657, 5660, 5662, 5665, 5668, 5670, 5673, 5676, 5679, 5681, 5684, 5687, 5689, 5692, 5695, 5698, 5700, 5703, 5706, 5708, 5711, 5714, 5717, 5719, 5722, 5725, 5727, 5730, 5733, 5736, 5738, 5741, 5744, 5746, 5749, 5752, 5755, 5757, 5760, 5763, 5765, 5768, 5771, 5774, 5776, 5779, 5782, 5784, 5787, 5790, 5793, 5795, 5798, 5801, 5803, 5806, 5809, 5812, 5814, 5817, 5820, 5822, 5825, 5828, 5831, 5833, 5836, 5839, 5841, 5844, 5847, 5850, 5852, 5855, 5858, 5860, 5863, 5866, 5869, 5871, 5874, 5877, 5879, 5882, 5885, 5888, 5890, 5893, 5896, 5898, 5901, 5904, 5907, 5909, 5912, 5915, 5917, 5920, 5923, 5926, 5928, 5931, 5934, 5936, 5939, 5942, 5945, 5947, 5950, 5953, 5955, 5958, 5961, 5964, 5966, 5969, 5972, 5974, 5977, 5980, 5983, 5985, 5988, 5991, 5993, 5996, 5999]);

  // var bcl = BclCalendars.hebrew;
  var minYear = 5343; //bcl.GetYear(bcl.MinSupportedDateTime);
  var maxYear = 5999; //bcl.GetYear(bcl.MaxSupportedDateTime);
  var noda = CalendarSystem.hebrewCivil;

  for (int year = minYear; year <= maxYear; year++)
  {
    expect(bclIsLeapYear.contains(year), noda.isLeapYear(year));
  }
}

// todo: I'm a bit unsure on what to do with this one.
/*
/// This tests every day for the BCL-supported Hebrew calendar range, testing various aspects of each date,
/// using the civil month numbering.
@Test()
void BclThroughHistory_Civil()
{
  var bcl = BclCalendars.hebrew;
  var noda = CalendarSystem.hebrewCivil;

  // The min supported date/time starts part way through the year
  var minYear = bcl.GetYear(bcl.MinSupportedDateTime) + 1;
  // The max supported date/time ends part way through the year
  var maxYear = bcl.GetYear(bcl.MaxSupportedDateTime) - 1;

  BclEquivalenceHelper.AssertEquivalent(bcl, noda, minYear, maxYear);
}*/

// todo: we can bring this all in as tables (see: above) -- but...wow... this is gonna be a lot of tables
/*
/// This tests every day for the BCL-supported Hebrew calendar range, testing various aspects of each date,
/// using the scriptural month numbering.
@Test()
void BclThroughHistory_Scriptural()
{
  var bcl = BclCalendars.hebrew;
  var noda = CalendarSystem.hebrewScriptural;

  // The min supported date/time starts part way through the year
  var minYear = 5343 + 1; //bcl.GetYear(bcl.MinSupportedDateTime) + 1;
  // The max supported date/time ends part way through the year
  var maxYear = 5999 - 1; //bcl.GetYear(bcl.MaxSupportedDateTime) - 1;

  // Can't use BclEquivalenceHelper for this one, because of the month conversions.
  for (int year = minYear; year <= maxYear; year++)
  {
    int months = bcl.GetMonthsInYear(year);
    expect(months, noda.getMonthsInYear(year));
    for (int civilMonth = 1; civilMonth <= months; civilMonth++)
    {
      int scripturalMonth = HebrewMonthConverter.civilToScriptural(year, civilMonth);
      expect(bcl.getDaysInMonth(year, civilMonth), noda.getDaysInMonth(year, scripturalMonth),
          reason: 'Year: $year; Month: $civilMonth (civil)');
      for (int day = 1; day < bcl.GetDaysInMonth(year, civilMonth); day++)
      {
        DateTime bclDate = bcl.ToDateTime(year, civilMonth, day, 0, 0, 0, 0);
        LocalDate nodaDate = new LocalDate(year, scripturalMonth, day, noda);
        expect(bclDate, nodaDate.atMidnight().toDateTimeLocal(), reason: '$year-$scripturalMonth-$day');
        expect(nodaDate, new LocalDateTime.fromDateTime(bclDate, noda).date);
        expect(year, nodaDate.year);
        expect(scripturalMonth, nodaDate.month);
        expect(day, nodaDate.day);
      }
    }
  }
}*/

// Test cases are in scriptural month numbering, but we check both. This is
// mostly testing the behaviour of SetYear, via LocalDate.PlusYears.
@Test()
// Simple case
@TestCase(['5405-02-10', 1, "5406-02-10"])
// Adar mapping - Adar from non-leap maps to Adar II in leap;
// Adar I and Adar II both map to Adar in a non-leap, except for the 30th of Adar I
// which maps to the 1st of Nisan.
@TestCase(['5402-12-05', 1, "5403-12-05"]) // Mapping from Adar I to Adar
@TestCase(['5402-13-05', 1, "5403-12-05"]) // Mapping from Adar II to Adar
@TestCase(['5402-12-30', 1, "5403-01-01"]) // Mapping from 30th of Adar I to 1st of Nisan
@TestCase(['5401-12-05', 1, "5402-13-05"]) // Mapping from Adar to Adar II
// Transfer to another leap year
@TestCase(['5402-12-05', 2, "5404-12-05"]) // Adar I to Adar I
@TestCase(['5402-12-30', 2, "5404-12-30"]) // 30th of Adar I to 30th of Adar I
@TestCase(['5402-13-05', 2, "5404-13-05"]) // Adar II to Adar II
// Rollover of 30th of Kislev and Heshvan to the 1st of the next month.
@TestCase(['5402-08-30', 1, "5403-09-01"]) // Rollover from 30th Heshvan to 1st Kislev
@TestCase(['5400-09-30', 1, "5401-10-01"]) // Rollover from 30th Kislev to 1st Tevet
// No rollover required (target year has 30 days in as well)
@TestCase(['5402-08-30', 3, "5405-08-30"]) // No truncation in Heshvan (both 5507 and 5509 are long)
@TestCase(['5400-09-30', 2, "5402-09-30"]) // No truncation in Kislev (both 5503 and 5504 are long)
void SetYear(String startText, int years, String expectedEndText)
{
  var civil = CalendarSystem.hebrewCivil;
  var scriptural = CalendarSystem.hebrewScriptural;
  var pattern = LocalDatePattern.createWithInvariantCulture('yyyy-MM-dd')
      .withTemplateValue(LocalDate(5774, 1, 1, scriptural)); // Sample value in 2014 ISO

  var start = pattern.parse(startText).value;
  var expectedEnd = pattern.parse(expectedEndText).value;
  expect(expectedEnd, start.addYears(years));

  // Check civil as well... the date should be the same (year, month, day) even though
  // the numbering is different.
  expect(expectedEnd.withCalendar(civil), start.withCalendar(civil).addYears(years));
}

@Test()
@TestCaseSource(#AddAndSubtractMonthCases)
void AddMonths_MonthsBetween(String startText, int months, String expectedEndText)
{
  var civil = CalendarSystem.hebrewCivil;
  var pattern = LocalDatePattern.createWithInvariantCulture('yyyy-MM-dd')
      .withTemplateValue(LocalDate(5774, 1, 1, civil)); // Sample value in 2014 ISO

  var start = pattern.parse(startText).value;
  var expectedEnd = pattern.parse(expectedEndText).value;
  expect(expectedEnd, start.addMonths(months));
}

@Test()
@TestCaseSource(#AddAndSubtractMonthCases)
@TestCaseSource(#MonthsBetweenCases)
void MonthsBetween(String startText, int expectedMonths, String endText)
{
  var civil = CalendarSystem.hebrewCivil;
  var pattern = LocalDatePattern.createWithInvariantCulture('yyyy-MM-dd')
      .withTemplateValue(LocalDate(5774, 1, 1, civil)); // Sample value in 2014 ISO

  var start = pattern.parse(startText).value;
  var end = pattern.parse(endText).value;
  expect(expectedMonths, Period.differenceBetweenDates(start, end, PeriodUnits.months).months);
}

@Test()
void MonthsBetween_TimeOfDay()
{
  var civil = CalendarSystem.hebrewCivil;
  var start = LocalDateTime(5774, 5, 10, 15, 0, 0, calendar: civil); // 3pm
  var end = LocalDateTime(5774, 7, 10, 5, 0, 0, calendar: civil); // 5am
  // Would be 2, but the start time is later than the end time.
  expect(1, Period.differenceBetweenDateTime(start, end, PeriodUnits.months).months);
}

@Test()
@TestCase([HebrewMonthNumbering.civil])
@TestCase([HebrewMonthNumbering.scriptural])
void DayOfYearAndReverse(HebrewMonthNumbering numbering)
{
  var calculator = HebrewYearMonthDayCalculator(numbering);
  for (int year = 5400; year < 5419; year++)
  {
    int daysInYear = calculator.getDaysInYear(year);
    for (int dayOfYear = 1; dayOfYear <= daysInYear; dayOfYear++)
    {
      YearMonthDay ymd = calculator.getYearMonthDay(year, dayOfYear);
      expect(dayOfYear, calculator.getDayOfYear(ymd));
    }
  }
}

@Test()
void GetDaysSinceEpoch()
{
  var calculator = HebrewYearMonthDayCalculator(HebrewMonthNumbering.scriptural);
  var unixEpoch = const YearMonthDay(5730, 10, 23);
  expect(0, calculator.getDaysSinceEpoch(unixEpoch));
}

@Test()
void DaysAtStartOfYear()
{
  // These are somewhat random values used when diagnosing an issue.
  var calculator = HebrewYearMonthDayCalculator(HebrewMonthNumbering.scriptural);
  expect(-110, calculator.getStartOfYearInDays(5730));
  expect(273, calculator.getStartOfYearInDays(5731));
  expect(-140735, calculator.getStartOfYearInDays(5345));
  expect(const YearMonthDay(5345, 1, 1), calculator.getYearMonthDayFromDaysSinceEpoch(-140529));
}

@Test()
void GetDaysInYearCrossCheck() {
  var calculator = HebrewYearMonthDayCalculator(HebrewMonthNumbering.civil);
  for (int year = calculator.minYear; year <= calculator.maxYear; year++) {
    // int sum = Enumerable.Range(1, calculator.GetMonthsInYear(year))
    //    .Sum(month => calculator.GetDaysInMonth(year, month));
    // expect(sum, calculator.GetDaysInYear(year), 'Days in {0}', year);

    int sum = Iterable
        .generate(calculator.getMonthsInYear(year), (i) => i + 1)
        .map((month) => calculator.getDaysInMonth(year, month))
        .reduce((a, b) => a + b);

    expect(sum, calculator.getDaysInYear(year), reason: 'Days in $year');
  }
}

@Test()
@TestCase(['5502-01-01', "5503-01-01"])
@TestCase(['5502-01-01', "5502-02-01"], "Months in same half of year")
// This is the test that looks odd...
@TestCase(['5502-12-01', "5502-02-01"], "Months in opposite half of year")
@TestCase(['5502-03-10', "5502-03-12"])
void ScripturalCompare(String earlier, String later)
{
  var pattern = LocalDatePattern.iso.withCalendar(CalendarSystem.hebrewScriptural);
  var earlierDate = pattern.parse(earlier).value;
  var earlierDate2 = pattern.parse(earlier).value;
  var laterDate = pattern.parse(later).value;
  TestHelper.TestCompareToStruct(earlierDate, earlierDate2, [laterDate]);
}

@Test()
void ScripturalGetDaysFromStartOfYearToStartOfMonth_InvalidForCoverage()
{
  expect(() => HebrewScripturalCalculator.getDaysFromStartOfYearToStartOfMonth(5502, 0), throwsRangeError);
}

// Cases used for adding months and differences between months.
// 5501 is not a leap year; 5502 is; 5503 is not; 5505 is.
// Heshvan (civil 2) is long in 5507 and 5509; it is short in 5506 and 5508
// Kislev (civil 3) is long in 5503-5505; it is short in 5502 and 5506
// Test cases are in civil month numbering (for the sake of sanity!) - the
// implementation performs converts to civil for most of the work.
@private final List AddAndSubtractMonthCases =
[
  ['5502-02-13', 3, "5502-05-13"], // Simple
  ['5502-02-13', 238, "5521-05-13"], // Simple after a 19-year cycle
  ['5502-05-13', -3, "5502-02-13"], // Simple (negative)
  ['5521-05-13', -238, "5502-02-13"], // Simple after a 19-year cycle (negative)
  ['5501-02-13', 12, "5502-02-13"], // Not a leap year
  ['5502-02-13', 13, "5503-02-13"], // Leap year
  ['5501-02-13', 26, "5503-03-13"], // Traversing both (and then an extra month)
  ['5502-02-13', -12, "5501-02-13"], // Not a leap year (negative)
  ['5503-02-13', -13, "5502-02-13"], // Leap year (negative)
  ['5503-03-13', -26, "5501-02-13"], // Traversing both (and then an extra month) (negative)
  ['5507-01-30', 1, "5507-02-30"], // Long Heshvan
  ['5506-01-30', 1, "5506-02-29"], // Short Heshvan
  ['5505-01-30', 2, "5505-03-30"], // Long Kislev
  ['5506-01-30', 2, "5506-03-29"] // Short Kislev
];

// Test cases only used for testing MonthsBetween, in the same format as AddAndSubtractMonthCases
// for simplicity.
@private final List MonthsBetweenCases =
[
  ['5502-02-13', 1, "5502-03-15"],
  ['5502-02-13', 0, "5502-03-05"],
  ['5502-02-13', 0, "5502-02-15"],
  ['5502-02-13', 0, "5502-02-05"],
  ['5502-02-13', 0, "5502-01-15"],
  ['5502-02-13', -1, "5502-01-05"],
];
