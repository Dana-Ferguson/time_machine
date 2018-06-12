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

class _ZoneYearOffset {
  int dayOfMonth;
  int dayOfWeek;
  int monthOfYear;
  bool addDay;

  /// Gets the method by which offsets are added to Instants to get LocalInstants.
  TransitionMode mode;

  /// Gets a value indicating whether [advance day of week].
  bool advanceDayOfWeek;

  /// Gets the time of day when the rule takes effect.
  LocalTime timeOfDay;
}

/// Defines an offset within a year as an expression that can be used to reference multiple
/// years.
///
/// A year offset defines a way of determining an offset into a year based on certain criteria.
/// The most basic is the month of the year and the day of the month. If only these two are
/// supplied then the offset is always the same day of each year. The only exception is if the
/// day is February 29th, then it only refers to those years that have a February 29th.
///
/// If the day of the week is specified then the offset determined by the month and day are
/// adjusted to the nearest day that falls on the given day of the week. If the month and day
/// fall on that day of the week then nothing changes. Otherwise the offset is moved forward or
/// backward up to 6 days to make the day fall on the correct day of the week. The direction the
/// offset is moved is determined by the [AdvanceDayOfWeek] property.
///
/// Finally the [Mode] property deterines whether the [time] value
/// is added to the calculated offset to generate an offset within the day.
///
/// Immutable, thread safe
@immutable
@internal /*sealed*/ class ZoneYearOffset // : IEquatable<ZoneYearOffset>
    {
  /// An offset that specifies the beginning of the year.
  @internal static final ZoneYearOffset StartOfYear = new ZoneYearOffset(TransitionMode.wall, 1, 1, 0, false, LocalTime.midnight);

  @private final int dayOfMonth;
  @private final int dayOfWeek;
  @private final int monthOfYear;
  @private final bool addDay;

  /// Gets the method by which offsets are added to Instants to get LocalInstants.
  final TransitionMode mode;

  /// Gets a value indicating whether [advance day of week].
  final bool advanceDayOfWeek;

  /// Gets the time of day when the rule takes effect.
  final LocalTime timeOfDay;

  /// Initializes a new instance of the [ZoneYearOffset] class.
  ///
  /// [mode]: The transition mode.
  /// [monthOfYear]: The month year offset.
  /// [dayOfMonth]: The day of month. Negatives count from end of month.
  /// [dayOfWeek]: The day of week. 0 means not set.
  /// [advance]: if set to `true` [advance].
  /// [timeOfDay]: The time of day at which the transition occurs.
  /// [addDay]: Whether to add an extra day (for 24:00 handling). Default is false. 
  @internal ZoneYearOffset(this.mode, this.monthOfYear, this.dayOfMonth, this.dayOfWeek, this.advanceDayOfWeek, this.timeOfDay, [this.addDay = false]) {
    VerifyFieldValue(1, 12, "monthOfYear", monthOfYear, false);
    VerifyFieldValue(1, 31, "dayOfMonth", dayOfMonth, true);
    if (dayOfWeek != 0) {
      VerifyFieldValue(1, 7, "dayOfWeek", dayOfWeek, false);
    }
  }

  /// Verifies the input value against the valid range of the calendar field.
  ///
  /// If this becomes more widely required, move to Preconditions.
  ///
  /// [minimum]: The minimum valid value.
  /// [maximum]: The maximum valid value (inclusive).
  /// [name]: The name of the field for the error message.
  /// [value]: The value to check.
  /// [allowNegated]: if set to `true` all the range of value to be the negative as well.
  /// [ArgumentOutOfRangeException]: If the given value is not in the valid range of the given calendar field.
  @private static void VerifyFieldValue(int minimum, int maximum, String name, int value, bool allowNegated) {
    bool failed = false;
    if (allowNegated && value < 0) {
      if (value < -maximum || -minimum < value) {
        failed = true;
      }
    }
    else {
      if (value < minimum || maximum < value) {
        failed = true;
      }
    }
    if (failed) {
      String range = allowNegated ? "[$minimum, $maximum] or [${-maximum}, ${-minimum}]" : "[$minimum, $maximum]";
      throw new ArgumentError.value(value, name, "$name is not in the valid range: $range");
    }
  }

  /// Indicates whether the current object is equal to another object of the same type.
  ///
  /// [other]: An object to compare with this object.
  ///
  /// true if the current object is equal to the [other] parameter; otherwise, false.
  bool Equals(ZoneYearOffset other) {
    if (null == other) {
      return false;
    }
    if (identical(this, other)) {
      return true;
    }
    return mode == other.mode &&
        monthOfYear == other.monthOfYear &&
        dayOfMonth == other.dayOfMonth &&
        dayOfWeek == other.dayOfWeek &&
        advanceDayOfWeek == other.advanceDayOfWeek &&
        timeOfDay == other.timeOfDay &&
        addDay == other.addDay;
  }

  bool operator==(dynamic other) => other is ZoneYearOffset && Equals(other);

  // todo: timeOfDay:{5:r} <-- recreate the format?
  @override String toString() =>
      "ZoneYearOffset[mode:$mode monthOfYear:$monthOfYear dayOfMonth:$dayOfMonth dayOfWeek:$dayOfWeek advance:$advanceDayOfWeek timeOfDay:$timeOfDay addDay:$addDay]";

  /// Returns the occurrence of this rule within the given year, as a LocalInstant.
  ///
  /// LocalInstant is used here so that we can use the representation of "AfterMaxValue"
  /// for December 31st 9999 24:00.
  @internal LocalInstant GetOccurrenceForYear(int year) {
    // unchecked
    {
      int actualDayOfMonth = dayOfMonth > 0 ? dayOfMonth : CalendarSystem.iso.getDaysInMonth(year, monthOfYear) + dayOfMonth + 1;
      if (monthOfYear == 2 && dayOfMonth == 29 && !CalendarSystem.iso.isLeapYear(year)) {
        // In zic.c, this would result in an error if dayOfWeek is 0 or AdvanceDayOfWeek is true.
        // However, it's very convenient to be able to ask any rule for its occurrence in any year.
        // We rely on genuine rules being well-written - and before releasing an nzd file we always
        // check that it's in line with zic anyway. Ignoring the brokenness is simpler than fixing
        // rules that are only in force for a single year.
        actualDayOfMonth = 28; // We'll now look backwards for the right day-of-week.
      }
      LocalDate date = new LocalDate(year, monthOfYear, actualDayOfMonth);
      if (dayOfWeek != 0) {
        // Optimized "go to next or previous occurrence of day or week". Try to do as few comparisons
        // as possible, and only fetch DayOfWeek once. (If we call Next or Previous, it will work it out again.)
        int currentDayOfWeek = date.dayOfWeek.value;
        if (currentDayOfWeek != dayOfWeek) {
          int diff = dayOfWeek - currentDayOfWeek;
          if (diff > 0) {
            if (!advanceDayOfWeek) {
              diff -= 7;
            }
          }
          else if (advanceDayOfWeek) {
            diff += 7;
          }
          date = date.plusDays(diff);
        }
      }
      if (addDay) {
        // Adding a day to the last representable day will fail, but we can return an infinite value instead.
        if (year == 9999 && date.month == 12 && date.day == 31) {
          return LocalInstant.afterMaxValue;
        }
        date = date.plusDays(1);
      }
      return (date.at(timeOfDay)).toLocalInstant();
    }
  }

  /// Writes this object to the given [IDateTimeZoneWriter].
  ///
  /// [writer]: Where to send the output.
  @internal void Write(/*IDateTimeZoneWriter*/ dynamic writer) {
  //  // Flags contains four pieces of information in a single byte:
  //  // 0MMDDDAP:
  //  // - MM is the mode (0-2)
  //  // - DDD is the day of week (0-7)
  //  // - A is the AdvanceDayOfWeek
  //  // - P is the "addDay" (24:00) flag
  //  int flags = ((mode << 5) |
  //  (dayOfWeek << 2) |
  //  (advanceDayOfWeek ? 2 : 0) |
  //  (addDay ? 1 : 0);
  //  writer.WriteByte(flags /*as byte*/);
  //  writer.WriteCount(monthOfYear);
  //  writer.WriteSignedCount(dayOfMonth);
  //  // The time of day is written as a number of milliseconds historical reasons.
  //  writer.WriteMilliseconds((timeOfDay.TickOfDay ~/ TimeConstants.ticksPerMillisecond));
  }

  static ZoneYearOffset Read(DateTimeZoneReader reader) {
    // todo: we can bit-pack all this; for example: see below
    int flags = reader.readUint8();
    var dayOfMonthSign = flags >> 7 == 1 ? -1 : 1;
    var mode = new TransitionMode(flags >> 5 & 3);
    var dayOfWeek = (flags >> 2) & 7;
    var advanceDayOfWeek = (flags & 2) != 0;
    var addDay = (flags & 1) != 0;
//  var dayOfWeek = reader.readInt32();
//  var addDay = reader.readBool();
//  var mode = new TransitionMode(reader.readUint8());
//  var advanceDayOfWeek = reader.readBool();

    var dayOfMonth = reader.read7BitEncodedInt() * dayOfMonthSign; //.readInt32();
    var monthOfYear = reader.read7BitEncodedInt(); //.readInt32();
    var timeOfDay = new LocalTime.fromNanoseconds(reader.readInt32() * TimeConstants.nanosecondsPerSecond);

    return new ZoneYearOffset(mode, monthOfYear, dayOfMonth, dayOfWeek, advanceDayOfWeek, timeOfDay, addDay);//Preconditions.checkNotNull(reader, 'reader');
  //int flags = reader.ReadByte();
  //var mode = new TransitionMode(flags >> 5);
  //var dayOfWeek = (flags >> 2) & 7;
  //var advance = (flags & 2) != 0;
  //var addDay = (flags & 1) != 0;
  //int monthOfYear = reader.ReadCount();
  //int dayOfMonth = reader.ReadSignedCount();
  //// The time of day is written as a number of milliseconds for historical reasons.
  //var timeOfDay = LocalTime.FromMillisecondsSinceMidnight(reader.ReadMilliseconds());
  //return new ZoneYearOffset(mode, monthOfYear, dayOfMonth, dayOfWeek, advance, timeOfDay, addDay);
  }

  /// Returns the offset to use for this rule's [TransitionMode].
  /// The year/month/day/time for a rule is in a specific frame of reference:
  /// UTC, "wall" or "standard".
  ///
  /// [standardOffset]: The standard offset.
  /// [savings]: The daylight savings adjustment.
  /// Returns: The base time offset as a [Duration].
  @internal Offset GetRuleOffset(Offset standardOffset, Offset savings) {
    // note: switch statements in Dart 1.25 don't work with constant classes
    if (mode == TransitionMode.wall) return standardOffset + savings;
    else if (mode == TransitionMode.standard) return standardOffset;
    return Offset.zero;
  }

  /// Returns a hash code for this instance.
  ///
  /// A hash code for this instance, suitable for use in hashing algorithms and data
  /// structures like a hash table.
  @override int get hashCode => hashObjects([mode, monthOfYear, dayOfMonth, dayOfWeek, advanceDayOfWeek, timeOfDay, addDay]);
}
