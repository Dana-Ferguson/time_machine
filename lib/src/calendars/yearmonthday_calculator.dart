// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'package:meta/meta.dart';

import 'package:time_machine/src/utility/preconditions.dart';

import 'package:time_machine/src/calendars/time_machine_calendars.dart';
import 'package:time_machine/src/time_machine_internal.dart';


/// The core of date calculations in Time Machine. This class *only* cares about absolute years, and only
/// dates - it has no time aspects at all, nor era-related aspects.
// todo: IComparer<YearMonthDay>
@internal
abstract class YearMonthDayCalculator {
  /// Cache to speed up working out when a particular year starts.
  /// See the [YearStartCacheEntry] documentation and [GetStartOfYearInDays]
  /// for more details.
  final List<YearStartCacheEntry> _yearCache = YearStartCacheEntry.createCache();

  final int minYear;

  final int maxYear;

  final int daysAtStartOfYear1;

  // todo: should be private -- but collides with upstream averageDaysPer10Years -- which is differentiated in the code-source by capitalization
  final int averageDaysPer10Years;

  @protected
  YearMonthDayCalculator(this.minYear, this.maxYear,
      int averageDaysPer10Years, this.daysAtStartOfYear1) :
      // We add an extra day to make sure that
      // approximations using days-since-epoch are conservative, to avoid going out of bounds.
      averageDaysPer10Years = averageDaysPer10Years + 1 {
    // We should really check the minimum year as well, but constructing it hurts my brain.
    Preconditions.checkArgument(maxYear < YearStartCacheEntry.invalidEntryYear, 'maxYear',
        'Calendar year range would invalidate caching.');
  }

  /// Returns the number of days from the start of the given year to the start of the given month.
  @protected
  int getDaysFromStartOfYearToStartOfMonth(int year, int month);

  /// Compute the start of the given year in days since 1970-01-01 ISO. The year may be outside
  /// the bounds advertised by the calendar, but only by a single year. This method is only
  /// called by [GetStartOfYearInDays] (unless the calendar chooses to call it itself),
  /// so calendars which override that method and don't call the original implementation may leave
  /// this unimplemented (e.g. by throwing an exception if it's ever called).
  // TODO(misc): Either hard-code a check that this *is* only called by GetStartOfYearInDays
  // via a Roslyn test, or work out an attribute to indicate that, and write a more general test.
  @protected
  int calculateStartOfYearDays(int year);

  int getMonthsInYear(int year);

  int getDaysInMonth(int year, int month);

  bool isLeapYear(int year);

  YearMonthDay addMonths(YearMonthDay yearMonthDay, int months);

  YearMonthDay getYearMonthDay(int year, int dayOfYear);

  /// Returns the number of days in the given year, which will always be within 1 year of
  /// the valid range for the calculator.
  int getDaysInYear(int year);

  /// Find the months between [start] and [end].
  /// (If start is earlier than end, the result will be non-negative.)
  int monthsBetween(YearMonthDay start, YearMonthDay end);

  /// Adjusts the given YearMonthDay to the specified year, potentially adjusting
  /// other fields as required.
  YearMonthDay setYear(YearMonthDay yearMonthDay, int year);

  // Virtual methods (subclasses should check to see whether they could override for performance, or should override for correctness)
  // ^^ todo: investigate this -- we have different pressures than nodatime

  /// Computes the days since the Unix epoch at the start of the given year/month/day.
  /// This is the opposite of [GetYearMonthDay(int)].
  /// This assumes the parameter have been validated previously.
  int getDaysSinceEpoch(YearMonthDay yearMonthDay) {
    int year = yearMonthDay.year;
    int startOfYear = getStartOfYearInDays(year);
    int startOfMonth = startOfYear + getDaysFromStartOfYearToStartOfMonth(year, yearMonthDay.month);
    return startOfMonth + yearMonthDay.day - 1;
  }

  /// Fetches the start of the year (in days since 1970-01-01 ISO) from the cache, or calculates
  /// and caches it.
  ///
  /// The [year] to fetch the days at the start of. This must be within 1 year of the min/max
  /// range, but can exceed it to make week-year calculations simple.
  int getStartOfYearInDays(int year) { // todo: tag!
    assert(Preconditions.debugCheckArgumentRange('year', year, minYear - 1, maxYear + 1));
    int cacheIndex = YearStartCacheEntry.getCacheIndex(year);
    YearStartCacheEntry cacheEntry = _yearCache[cacheIndex];
    if (!cacheEntry.isValidForYear(year)) {
      int days = calculateStartOfYearDays(year);
      cacheEntry = YearStartCacheEntry(year, days);
      _yearCache[cacheIndex] = cacheEntry;
    }
    return cacheEntry.startOfYearDays;
  }

  /// Compares two YearMonthDay values according to the rules of this calendar.
  /// The default implementation simply uses a naive comparison of the values,
  /// as this is suitable for most calendars (where the first month of the year is month 1).
  ///
  /// Although the parameters are trusted (as in, they'll be valid in this calendar),
  /// the method being public isn't a problem - this type is never exposed.
  int compare(YearMonthDay lhs, YearMonthDay rhs) => lhs.compareTo(rhs);

  // Catch-all year/month/day validation. Subclasses can optimize further - currently
  // this is only done for Gregorian/Julian calendars, which are the most performance-critical.
  void validateYearMonthDay(int year, int month, int day) {
    Preconditions.checkArgumentRange('year', year, minYear, maxYear);
    Preconditions.checkArgumentRange('month', month, 1, getMonthsInYear(year));
    Preconditions.checkArgumentRange('day', day, 1, getDaysInMonth(year, month));
  }

// #endregion Virtual Methods

  /// Converts from a YearMonthDay representation to 'day of year'.
  /// This assumes the parameter have been validated previously.
  int getDayOfYear(YearMonthDay yearMonthDay) => getDaysFromStartOfYearToStartOfMonth(yearMonthDay.year, yearMonthDay.month) + yearMonthDay.day;

  /// Works out the year/month/day of a given days-since-epoch by first computing the year and day of year,
  /// then getting the month and day from those two. This is how almost all calendars are naturally implemented
  /// anyway.
  YearMonthDay getYearMonthDayFromDaysSinceEpoch(int daysSinceEpoch) {
    // todo: I do not like this solution
    var args = getYear(daysSinceEpoch);
    int year = args[0];
    int zeroBasedDay = args[1];
    return getYearMonthDay(year, zeroBasedDay + 1);
  }

  /// Work out the year from the number of days since the epoch, as well as the
  /// day of that year (0-based).
  List<int> getYear(int daysSinceEpoch) {
    // Get an initial estimate of the year, and the days-since-epoch value that
    // represents the start of that year. Then verify estimate and fix if
    // necessary. We have the average days per 100 years to avoid getting bad candidates
    // pretty quickly.
    int daysSinceYear1 = daysSinceEpoch - daysAtStartOfYear1;
    int candidate = ((daysSinceYear1 * 10) ~/ averageDaysPer10Years) + 1;

    // Most of the time we'll get the right year straight away, and we'll almost
    // always get it after one adjustment - but it's safer (and easier to think about)
    // if we just keep going until we know we're right.
    int candidateStart = getStartOfYearInDays(candidate);
    int daysFromCandidateStartToTarget = daysSinceEpoch - candidateStart;
    if (daysFromCandidateStartToTarget < 0) {
      // Our candidate year is later than we want. Keep going backwards until we've got
      // a non-negative result, which must then be correct.
      do {
        candidate--;
        daysFromCandidateStartToTarget += getDaysInYear(candidate);
      }
      while (daysFromCandidateStartToTarget < 0);
      var zeroBasedDayOfYear = daysFromCandidateStartToTarget;
      return [candidate, zeroBasedDayOfYear];
    }
    // Our candidate year is correct or earlier than the right one. Find out which by
    // comparing it with the length of the candidate year.
    int candidateLength = getDaysInYear(candidate);
    while (daysFromCandidateStartToTarget >= candidateLength) {
      // Our candidate year is earlier than we want, so fast forward a year,
      // removing the current candidate length from the 'remaining days' and
      // working out the length of the new candidate.
      candidate++;
      daysFromCandidateStartToTarget -= candidateLength;
      candidateLength = getDaysInYear(candidate);
    }
    var zeroBasedDayOfYear = daysFromCandidateStartToTarget;
    return [candidate, zeroBasedDayOfYear];
  }
}

