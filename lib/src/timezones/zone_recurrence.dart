// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/ZoneRecurrence.cs
// ffecbab  on Aug 26, 2017

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

/// <summary>
/// Extends <see cref="ZoneYearOffset"/> with a name and savings.
/// </summary>
/// <remarks>
/// <para>
/// This represents a recurring transition from or to a daylight savings time. The name is the
/// name of the time zone during this period (e.g. PST or PDT). The savings is usually 0 or the
/// daylight offset. This is also used to support some of the tricky transitions that occurred
/// before the time zones were normalized (i.e. when they were still tightly longitude-based,
/// with multiple towns in the same country observing different times).
/// </para>
/// <para>
/// Immutable, thread safe.
/// </para>
/// </remarks>
@immutable
@internal /*sealed*/ class ZoneRecurrence // : IEquatable<ZoneRecurrence>
    {
  @private final LocalInstant maxLocalInstant;
  @private final LocalInstant minLocalInstant;

  final String name;
  final Offset savings;
  final ZoneYearOffset yearOffset;
  final int fromYear;
  final int toYear;

// todo: we need a sane dart-like replacement for this logic
  bool get isInfinite => toYear == Int32.MaxValue;

  /// <summary>
  /// Initializes a new instance of the <see cref="ZoneRecurrence"/> class.
  /// </summary>
  /// <param name="name">The name of the time zone period e.g. PST.</param>
  /// <param name="savings">The savings for this period.</param>
  /// <param name="yearOffset">The year offset of when this period starts in a year.</param>
  /// <param name="fromYear">The first year in which this recurrence is valid</param>
  /// <param name="toYear">The last year in which this recurrence is valid</param>
  ZoneRecurrence(this.name, this.savings, this.yearOffset, this.fromYear, this.toYear)
      :
        this.minLocalInstant = fromYear == int.MinValue ? LocalInstant.BeforeMinValue : yearOffset.GetOccurrenceForYear(fromYear),
        this.maxLocalInstant = toYear == int.MaxValue ? LocalInstant.AfterMaxValue : yearOffset.GetOccurrenceForYear(toYear) {
    Preconditions.checkNotNull(name, 'name');
    Preconditions.checkNotNull(yearOffset, 'yearOffset');

// todo: magic numbers
    Preconditions.checkArgument(fromYear == int.MinValue || (fromYear >= -9998 && fromYear <= 9999), 'fromYear',
        "fromYear must be in the range [-9998, 9999] or Int32.MinValue");
    Preconditions.checkArgument(toYear == int.MaxValue || (toYear >= -9998 && toYear <= 9999), 'toYear',
        "toYear must be in the range [-9998, 9999] or Int32.MaxValue");
  }

  /// <summary>
  /// Returns a new recurrence which has the same values as this, but a different name.
  /// </summary>
  @internal ZoneRecurrence WithName(String name) =>
      new ZoneRecurrence(name, savings, yearOffset, fromYear, toYear);

  /// <summary>
  /// Returns a new recurrence with the same values as this, but just for a single year.
  /// </summary>
  @internal ZoneRecurrence ForSingleYear(int year) {
    return new ZoneRecurrence(name, savings, yearOffset, year, year);
  }

// #region IEquatable<ZoneRecurrence> Members
  /// <summary>
  /// Indicates whether the current object is equal to another object of the same type.
  /// </summary>
  /// <param name="other">An object to compare with this object.</param>
  /// <returns>
  /// true if the current object is equal to the <paramref name="other"/> parameter;
  /// otherwise, false.
  /// </returns>
  bool Equals(ZoneRecurrence other) {
    if (null == other) {
      return false;
    }
// todo: unsure about this
    if (this == other) {
      return true;
    }
    return savings == other.savings && fromYear == other.fromYear && toYear == other.toYear && name == other.name && yearOffset.Equals(other.yearOffset);
  }

  /// <summary>
  /// Returns the first transition which occurs strictly after the given instant.
  /// </summary>
  /// <remarks>
  /// If the given instant is before the starting year, the year of the given instant is
  /// adjusted to the beginning of the starting year. The first transition after the
  /// adjusted instant is determined. If the next adjustment is after the ending year, this
  /// method returns null; otherwise the next transition is returned.
  /// </remarks>
  /// <param name="instant">The <see cref="Instant"/> lower bound for the next transition.</param>
  /// <param name="standardOffset">The <see cref="Offset"/> standard offset.</param>
  /// <param name="previousSavings">The <see cref="Offset"/> savings adjustment at the given Instant.</param>
  /// <returns>The next transition, or null if there is no next transition. The transition may be
  /// infinite, i.e. after the end of representable time.</returns>
  @internal Transition Next(Instant instant, Offset standardOffset, Offset previousSavings) {
    Offset ruleOffset = yearOffset.GetRuleOffset(standardOffset, previousSavings);
    Offset newOffset = standardOffset + savings;

    LocalInstant safeLocal = instant.SafePlus(ruleOffset);
    int targetYear;
    if (safeLocal < minLocalInstant) {
// Asked for a transition after some point before the first transition: crop to first year (so we get the first transition)
      targetYear = fromYear;
    }
    else if (safeLocal >= maxLocalInstant) {
// Asked for a transition after our final transition... or both are beyond the end of time (in which case
// we can return an infinite transition). This branch will always be taken for transitions beyond the end
// of time.
      return maxLocalInstant == LocalInstant.AfterMaxValue ? new Transition(Instant.AfterMaxValue, newOffset) : (Transition ?)
      null;
    }
    else if (safeLocal == LocalInstant.BeforeMinValue) {
// We've been asked to find the next transition after some point which is a valid instant, but is before the
// start of valid local time after applying the rule offset. For example, passing Instant.MinValue for a rule which says
// "transition uses wall time, which is UTC-5". Proceed as if we'd been asked for something in -9998.
// I *think* that works...
      targetYear = GregorianYearMonthDayCalculator.minGregorianYear;
    }
    else {
// Simple case: we were asked for a "normal" value in the range of years for which this recurrence is valid.
// int ignoredDayOfYear;
      targetYear = CalendarSystem.Iso.yearMonthDayCalculator
          .getYear(safeLocal.DaysSinceEpoch)
          .first; //.GetYear(safeLocal.DaysSinceEpoch, out ignoredDayOfYear);
    }

    LocalInstant transition = yearOffset.GetOccurrenceForYear(targetYear);

    Instant safeTransition = transition.SafeMinus(ruleOffset);
    if (safeTransition > instant) {
      return new Transition(safeTransition, newOffset);
    }

// We've got a transition earlier than we were asked for. Try next year.
// Note that this will stil be within the FromYear/ToYear range, otherwise
// safeLocal >= maxLocalInstant would have been triggered earlier.
    targetYear++;
// Handle infinite transitions
    if (targetYear > GregorianYearMonthDayCalculator.maxGregorianYear) {
      return new Transition(Instant.AfterMaxValue, newOffset);
    }
// It's fine for this to be "end of time", and it can't be "start of time" because we're at least finding a transition in -9997.
    safeTransition = yearOffset.GetOccurrenceForYear(targetYear).SafeMinus(ruleOffset);
    return new Transition(safeTransition, newOffset);
  }

  /// <summary>
  /// Returns the last transition which occurs before or on the given instant.
  /// </summary>
  /// <param name="instant">The <see cref="Instant"/> lower bound for the next trasnition.</param>
  /// <param name="standardOffset">The <see cref="Offset"/> standard offset.</param>
  /// <param name="previousSavings">The <see cref="Offset"/> savings adjustment at the given Instant.</param>
  /// <returns>The previous transition, or null if there is no previous transition. The transition may be
  /// infinite, i.e. before the start of representable time.</returns>
  @internal Transition PreviousOrSame(Instant instant, Offset standardOffset, Offset previousSavings) {
    Offset ruleOffset = yearOffset.GetRuleOffset(standardOffset, previousSavings);
    Offset newOffset = standardOffset + savings;

    LocalInstant safeLocal = instant.SafePlus(ruleOffset);
    int targetYear;
    if (safeLocal > maxLocalInstant) {
// Asked for a transition before some point after our last year: crop to last year.
      targetYear = toYear;
    }
// Deliberately < here; "previous or same" means if safeLocal==minLocalInstant, we should compute it for this year.
    else if (safeLocal < minLocalInstant) {
// Asked for a transition before our first one
      return null;
    }
    else if (!safeLocal.IsValid) {
      if (safeLocal == LocalInstant.BeforeMinValue) {
// We've been asked to find the next transition before some point which is a valid instant, but is before the
// start of valid local time after applying the rule offset.  It's possible that the next transition *would*
// be representable as an instant (e.g. 1pm Dec 31st -9999 with an offset of -5) but it's reasonable to
// just return an infinite transition.
        return new Transition(Instant.BeforeMinValue, newOffset);
      }
      else {
// We've been asked to find the next transition before some point which is a valid instant, but is after the
// end of valid local time after applying the rule offset. For example, passing Instant.MaxValue for a rule which says
// "transition uses wall time, which is UTC+5". Proceed as if we'd been asked for something in 9999.
// I *think* that works...
        targetYear = GregorianYearMonthDayCalculator.maxGregorianYear;
      }
    }
    else {
// Simple case: we were asked for a "normal" value in the range of years for which this recurrence is valid.
// int ignoredDayOfYear;
      targetYear = CalendarSystem.Iso.yearMonthDayCalculator
          .getYear(safeLocal.DaysSinceEpoch)
          .first; //, out ignoredDayOfYear);
    }

    LocalInstant transition = yearOffset.GetOccurrenceForYear(targetYear);

    Instant safeTransition = transition.SafeMinus(ruleOffset);
    if (safeTransition <= instant) {
      return new Transition(safeTransition, newOffset);
    }

// We've got a transition later than we were asked for. Try next year.
// Note that this will stil be within the FromYear/ToYear range, otherwise
// safeLocal < minLocalInstant would have been triggered earlier.
    targetYear--;
// Handle infinite transitions
    if (targetYear < GregorianYearMonthDayCalculator.minGregorianYear) {
      return new Transition(Instant.BeforeMinValue, newOffset);
    }
// It's fine for this to be "start of time", and it can't be "end of time" because we're at latest finding a transition in 9998.
    safeTransition = yearOffset.GetOccurrenceForYear(targetYear).SafeMinus(ruleOffset);
    return new Transition(safeTransition, newOffset);
  }

  /// <summary>
  /// Piggy-backs onto Next, but fails with an InvalidOperationException if there's no such transition.
  /// </summary>
  @internal Transition NextOrFail(Instant instant, Offset standardOffset, Offset previousSavings) {
    Transition next = Next(instant, standardOffset, previousSavings);
    if (next == null) {
      throw new StateError(
          "Noda Time bug or bad data: Expected a transition later than $instant; standard offset = $standardOffset; previousSavings = $previousSavings; recurrence = $this");
    }
    return next.Value;
  }

  /// <summary>
  /// Piggy-backs onto PreviousOrSame, but fails with a descriptive InvalidOperationException if there's no such transition.
  /// </summary>
  @internal Transition PreviousOrSameOrFail(Instant instant, Offset standardOffset, Offset previousSavings) {
    Transition previous = PreviousOrSame(instant, standardOffset, previousSavings);
    if (previous == null) {
      throw new StateError(
          "Noda Time bug or bad data: Expected a transition earlier than $instant; standard offset = $standardOffset; previousSavings = $previousSavings; recurrence = $this");
    }
    return previous.Value;
  }

  /// <summary>
  /// Writes this object to the given <see cref="DateTimeZoneWriter"/>.
  /// </summary>
  /// <param name="writer">Where to send the output.</param>
  @internal void Write(IDateTimeZoneWriter writer) {
    writer.WriteString(name);
    writer.WriteOffset(savings);
    yearOffset.Write(writer);
// We'll never have time zones with recurrences between the beginning of time and 0AD,
// so we can treat anything negative as 0, and go to the beginning of time when reading.
    writer.WriteCount(math.max(fromYear, 0));
    writer.WriteCount(toYear);
  }


  /// <summary>
  /// Reads a recurrence from the specified reader.
  /// </summary>
  /// <param name="reader">The reader.</param>
  /// <returns>The recurrence read from the reader.</returns>
  static ZoneRecurrence Read(IDateTimeZoneReader reader) {
    Preconditions.checkNotNull(reader, 'reader');
    String name = reader.ReadString();
    Offset savings = reader.ReadOffset();
    ZoneYearOffset yearOffset = ZoneYearOffset.Read(reader);
    int fromYear = reader.ReadCount();
    if (fromYear == 0) {
      fromYear = int.MinValue;
    }
    int toYear = reader.ReadCount();
    return new ZoneRecurrence(name, savings, yearOffset, fromYear, toYear);
  }

  /// <summary>
  /// Returns a hash code for this instance.
  /// </summary>
  /// <returns>
  /// A hash code for this instance, suitable for use in hashing algorithms and data
  /// structures like a hash table.
  /// </returns>
  @override int get hashCode => hash3(savings, name, yearOffset);

  /// <summary>
  /// Returns a <see cref="System.String"/> that represents this instance.
  /// </summary>
  /// <returns>
  /// A <see cref="System.String"/> that represents this instance.
  /// </returns>
  @override String toString() => "$name $savings $yearOffset [$fromYear-$toYear]";

  /// <summary>
  /// Returns either "this" (if this zone recurrence already has a from year of int.MinValue)
  /// or a new zone recurrence which is identical but with a from year of int.MinValue.
  /// </summary>
  @internal ZoneRecurrence ToStartOfTime() =>
      fromYear == int.MinValue ? this : new ZoneRecurrence(name, savings, yearOffset, int.MinValue, toYear);
}
