// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

/// Extends [ZoneYearOffset] with a name and savings.
///
/// This represents a recurring transition from or to a daylight savings time. The name is the
/// name of the time zone during this period (e.g. PST or PDT). The savings is usually 0 or the
/// daylight offset. This is also used to support some of the tricky transitions that occurred
/// before the time zones were normalized (i.e. when they were still tightly longitude-based,
/// with multiple towns in the same country observing different times).
///
/// Immutable, thread safe.
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

  // todo: there seems to be a lot of dependence on 'number systems' here -- not sure Dart likes this
  bool get isInfinite => toYear == Utility.int32MaxValue;

  /// Initializes a new instance of the [ZoneRecurrence] class.
  ///
  /// [name]: The name of the time zone period e.g. PST.
  /// [savings]: The savings for this period.
  /// [yearOffset]: The year offset of when this period starts in a year.
  /// [fromYear]: The first year in which this recurrence is valid
  /// [toYear]: The last year in which this recurrence is valid
  ZoneRecurrence(this.name, this.savings, this.yearOffset, this.fromYear, this.toYear)
      :
        this.minLocalInstant = fromYear == Utility.int32MinValue ? LocalInstant.BeforeMinValue : yearOffset?.GetOccurrenceForYear(fromYear),
        this.maxLocalInstant = toYear == Utility.int32MaxValue ? LocalInstant.AfterMaxValue : yearOffset?.GetOccurrenceForYear(toYear) {
    Preconditions.checkNotNull(name, 'name');
    Preconditions.checkNotNull(yearOffset, 'yearOffset');

    // todo: magic numbers
    Preconditions.checkArgument(fromYear == Utility.int32MinValue || (fromYear >= -9998 && fromYear <= 9999), 'fromYear',
        "fromYear must be in the range [-9998, 9999] or Int32.MinValue");
    Preconditions.checkArgument(toYear == Utility.int32MaxValue || (toYear >= -9998 && toYear <= 9999), 'toYear',
        "toYear must be in the range [-9998, 9999] or Int32.MaxValue");
  }

  /// Returns a new recurrence which has the same values as this, but a different name.
  @internal ZoneRecurrence WithName(String name) =>
      new ZoneRecurrence(name, savings, yearOffset, fromYear, toYear);

  /// Returns a new recurrence with the same values as this, but just for a single year.
  @internal ZoneRecurrence ForSingleYear(int year) {
    return new ZoneRecurrence(name, savings, yearOffset, year, year);
  }

  // #region IEquatable<ZoneRecurrence> Members
  /// Indicates whether the current object is equal to another object of the same type.
  ///
  /// [other]: An object to compare with this object.
  ///
  /// true if the current object is equal to the [other] parameter;
  /// otherwise, false.
  bool Equals(ZoneRecurrence other) {
    if (null == other) {
      return false;
    }
    if (identical(this, other)) {
      return true;
    }
    return savings == other.savings && fromYear == other.fromYear && toYear == other.toYear && name == other.name && yearOffset.Equals(other.yearOffset);
  }

  bool operator==(dynamic other) => other is ZoneRecurrence && Equals(other);

  /// Returns the first transition which occurs strictly after the given instant.
  ///
  /// If the given instant is before the starting year, the year of the given instant is
  /// adjusted to the beginning of the starting year. The first transition after the
  /// adjusted instant is determined. If the next adjustment is after the ending year, this
  /// method returns null; otherwise the next transition is returned.
  ///
  /// [instant]: The [Instant] lower bound for the next transition.
  /// [standardOffset]: The [Offset] standard offset.
  /// [previousSavings]: The [Offset] savings adjustment at the given Instant.
  /// The next transition, or null if there is no next transition. The transition may be
  /// infinite, i.e. after the end of representable time.
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
      return maxLocalInstant == LocalInstant.AfterMaxValue ? new Transition(Instant.afterMaxValue, newOffset) : null;
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
      return new Transition(Instant.afterMaxValue, newOffset);
    }
    // It's fine for this to be "end of time", and it can't be "start of time" because we're at least finding a transition in -9997.
    safeTransition = yearOffset.GetOccurrenceForYear(targetYear).SafeMinus(ruleOffset);
    return new Transition(safeTransition, newOffset);
  }

  /// Returns the last transition which occurs before or on the given instant.
  ///
  /// [instant]: The [Instant] lower bound for the next trasnition.
  /// [standardOffset]: The [Offset] standard offset.
  /// [previousSavings]: The [Offset] savings adjustment at the given Instant.
  /// The previous transition, or null if there is no previous transition. The transition may be
  /// infinite, i.e. before the start of representable time.
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
        return new Transition(Instant.beforeMinValue, newOffset);
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
      return new Transition(Instant.beforeMinValue, newOffset);
    }
    // It's fine for this to be "start of time", and it can't be "end of time" because we're at latest finding a transition in 9998.
    safeTransition = yearOffset.GetOccurrenceForYear(targetYear).SafeMinus(ruleOffset);
    return new Transition(safeTransition, newOffset);
  }

  /// Piggy-backs onto Next, but fails with an InvalidOperationException if there's no such transition.
  @internal Transition NextOrFail(Instant instant, Offset standardOffset, Offset previousSavings) {
    Transition next = Next(instant, standardOffset, previousSavings);
    if (next == null) {
      throw new StateError(
          "Noda Time bug or bad data: Expected a transition later than $instant; standard offset = $standardOffset; previousSavings = $previousSavings; recurrence = $this");
    }
    return next;
  }

  /// Piggy-backs onto PreviousOrSame, but fails with a descriptive InvalidOperationException if there's no such transition.
  @internal Transition PreviousOrSameOrFail(Instant instant, Offset standardOffset, Offset previousSavings) {
    Transition previous = PreviousOrSame(instant, standardOffset, previousSavings);
    if (previous == null) {
      throw new StateError(
          "Noda Time bug or bad data: Expected a transition earlier than $instant; standard offset = $standardOffset; previousSavings = $previousSavings; recurrence = $this");
    }
    return previous;
  }

  /// Writes this object to the given [DateTimeZoneWriter].
  ///
  /// [writer]: Where to send the output.
  @internal void Write(IDateTimeZoneWriter writer) {
    throw new UnimplementedError('This feature is not supported');
  //    writer.WriteString(name);
  //    writer.WriteOffset(savings);
  //    yearOffset.Write(writer);
  //// We'll never have time zones with recurrences between the beginning of time and 0AD,
  //// so we can treat anything negative as 0, and go to the beginning of time when reading.
  //    writer.WriteCount(math.max(fromYear, 0));
  //    writer.WriteCount(toYear);
  }


  /// Reads a recurrence from the specified reader.
  ///
  /// [reader]: The reader.
  /// Returns: The recurrence read from the reader.
  static ZoneRecurrence Read(DateTimeZoneReader reader) {
    Preconditions.checkNotNull(reader, 'reader');
    var name = reader.readString();
    var savings = reader.readOffsetSeconds2(); // Offset.fromSeconds(reader.readInt32());
    var yearOffset = ZoneYearOffset.Read(reader);
    var fromYear = reader.readInt32();
    var toYear = reader.readInt32();

//// todo: remove me in the future... but for now, it's a good sanity check
//var isInfinite = reader.readBool();

    return new ZoneRecurrence(name, savings, yearOffset, fromYear, toYear);
// if (zoneRecurrence.isInfinite != isInfinite) throw new Exception('zoneRecurrence.isInfinite error.');



  // String name = reader.ReadString();
  // Offset savings = reader.ReadOffset();
  // ZoneYearOffset yearOffset = ZoneYearOffset.Read(reader);
  // int fromYear = reader.ReadCount();
  // if (fromYear == 0) {
  //   fromYear = Utility.int32MinValue; // int.minValue;
  // }
  // int toYear = reader.ReadCount();
  // return new ZoneRecurrence(name, savings, yearOffset, fromYear, toYear);
  }

  /// Returns a hash code for this instance.
  ///
  /// A hash code for this instance, suitable for use in hashing algorithms and data
  /// structures like a hash table.
  @override int get hashCode => hash3(savings, name, yearOffset);

  /// Returns a [String] that represents this instance.
  ///
  /// A [String] that represents this instance.
  @override String toString() => "$name $savings $yearOffset [$fromYear-$toYear]";

  /// Returns either "this" (if this zone recurrence already has a from year of int.MinValue)
  /// or a new zone recurrence which is identical but with a from year of int.MinValue.
  @internal ZoneRecurrence ToStartOfTime() =>
      fromYear == Utility.int32MinValue ? this : new ZoneRecurrence(name, savings, yearOffset, Utility.int32MinValue, toYear);
}

