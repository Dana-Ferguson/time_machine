// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

// Note: documentation that refers to the LocalDateTime type within this class must use the fully-qualified
// reference to avoid being resolved to the LocalDateTime property instead.

/// A [LocalDateTime] in a specific time zone and with a particular offset to distinguish
/// between otherwise-ambiguous instants. A [ZonedDateTime] is global, in that it maps to a single
/// [Instant].
///
/// Although [ZonedDateTime] includes both local and global concepts, it only supports
/// duration-based - and not calendar-based - arithmetic. This avoids ambiguities
/// and skipped date/time values becoming a problem within a series of calculations; instead,
/// these can be considered just once, at the point of conversion to a [ZonedDateTime].
///
/// `ZonedDateTime` does not implement ordered comparison operators, as there is no obvious natural ordering that works in all cases. 
/// Equality is supported however, requiring equality of zone, calendar and date/time. If you want to sort `ZonedDateTime`
/// values, you should explicitly choose one of the orderings provided via the static properties in the
/// [ZonedDateTime.Comparer] nested class (or implement your own comparison).
@immutable
class ZonedDateTime // : IEquatable<ZonedDateTime>, IFormattable, IXmlSerializable
{
@private final OffsetDateTime offsetDateTime;
@private final DateTimeZone zone;

/// Internal constructor from pre-validated values.
@internal ZonedDateTime.trusted(this.offsetDateTime, this.zone);

/// Initializes a new instance of the [ZonedDateTime] struct.
///
/// [instant]: The instant.
/// [zone]: The time zone.
/// [calendar]: The calendar system.
ZonedDateTime.withCalendar(Instant instant, DateTimeZone zone, CalendarSystem calendar)
:
this.zone = Preconditions.checkNotNull(zone, 'zone'),
offsetDateTime = new OffsetDateTime.instantCalendar(instant, zone.getUtcOffset(instant), Preconditions.checkNotNull(calendar, 'calendar'));

/// Initializes a new instance of the [ZonedDateTime] struct in the specified time zone
/// and the ISO calendar.
///
/// [instant]: The instant.
/// [zone]: The time zone.
ZonedDateTime([Instant instant = const Instant(), DateTimeZone zone = null])
:
this.zone = zone ?? DateTimeZone.utc /*Preconditions.checkNotNull(zone, 'zone')*/,
offsetDateTime = new OffsetDateTime.instant(instant, (zone ?? DateTimeZone.utc).getUtcOffset(instant));

/// Initializes a new instance of the [ZonedDateTime] struct in the specified time zone
/// from a given local time and offset. The offset is validated to be correct as part of initialization.
/// In most cases a local time can only map to a single instant anyway, but the offset is included here for cases
/// where the local time is ambiguous, usually due to daylight saving transitions.
///
/// [localDateTime]: The local date and time.
/// [zone]: The time zone.
/// [offset]: The offset between UTC and local time at the desired instant.
/// [ArgumentException]: [offset] is not a valid offset at the given
/// local date and time.
factory ZonedDateTime.fromLocal(LocalDateTime localDateTime, DateTimeZone zone, Offset offset)
{
zone = Preconditions.checkNotNull(zone, 'zone');
Instant candidateInstant = localDateTime.toLocalInstant().Minus(offset);
Offset correctOffset = zone.getUtcOffset(candidateInstant);
// Not using Preconditions, to avoid building the string unnecessarily.
if (correctOffset != offset)
{
throw new ArgumentError("Offset $offset is invalid for local date and time $localDateTime in time zone ${zone?.id} offset");

}
var offsetDateTime = new OffsetDateTime(localDateTime, offset);
return new ZonedDateTime.trusted(offsetDateTime, zone);
}

/// Gets the offset of the local representation of this value from UTC.
Offset get offset => offsetDateTime.offset;

/// Gets the time zone associated with this value.
DateTimeZone get Zone => zone ?? DateTimeZone.utc;

/// Gets the local date and time represented by this zoned date and time.
///
/// The returned
/// [LocalDateTime] will have the same calendar system and return the same values for
/// each of the calendar properties (Year, MonthOfYear and so on), but will not be associated with any
/// particular time zone.
LocalDateTime get localDateTime => offsetDateTime.localDateTime;

/// Gets the calendar system associated with this zoned date and time.
CalendarSystem get Calendar => offsetDateTime.Calendar;

/// Gets the local date represented by this zoned date and time.
///
/// The returned [LocalDate]
/// will have the same calendar system and return the same values for each of the date-based calendar
/// properties (Year, MonthOfYear and so on), but will not be associated with any particular time zone.
LocalDate get Date => offsetDateTime.Date;

/// Gets the time portion of this zoned date and time.
///
/// The returned [LocalTime] will
/// return the same values for each of the time-based properties (Hour, Minute and so on), but
/// will not be associated with any particular time zone.
LocalTime get TimeOfDay => offsetDateTime.TimeOfDay;

/// Gets the era for this zoned date and time.
Era get era => offsetDateTime.era;

/// Gets the year of this zoned date and time.
/// This returns the "absolute year", so, for the ISO calendar,
/// a value of 0 means 1 BC, for example.
int get Year => offsetDateTime.Year;

/// Gets the year of this zoned date and time within its era.
int get YearOfEra => offsetDateTime.YearOfEra;

/// Gets the month of this zoned date and time within the year.
int get Month => offsetDateTime.Month;

/// Gets the day of this zoned date and time within the year.
int get DayOfYear => offsetDateTime.DayOfYear;

/// Gets the day of this zoned date and time within the month.
int get Day => offsetDateTime.Day;

/// Gets the week day of this zoned date and time expressed as an [IsoDayOfWeek] value.
IsoDayOfWeek get DayOfWeek => offsetDateTime.DayOfWeek;

/// Gets the hour of day of this zoned date and time, in the range 0 to 23 inclusive.
int get Hour => offsetDateTime.Hour;

/// Gets the hour of the half-day of this zoned date and time, in the range 1 to 12 inclusive.
int get ClockHourOfHalfDay => offsetDateTime.ClockHourOfHalfDay;

/// Gets the minute of this zoned date and time, in the range 0 to 59 inclusive.
int get Minute => offsetDateTime.Minute;

/// Gets the second of this zoned date and time within the minute, in the range 0 to 59 inclusive.
int get Second => offsetDateTime.Second;

/// Gets the millisecond of this zoned date and time within the second, in the range 0 to 999 inclusive.
int get Millisecond => offsetDateTime.Millisecond;

/// Gets the tick of this zoned date and time within the second, in the range 0 to 9,999,999 inclusive.
int get TickOfSecond => offsetDateTime.TickOfSecond;

/// Gets the tick of this zoned date and time within the day, in the range 0 to 863,999,999,999 inclusive.
int get TickOfDay => offsetDateTime.TickOfDay;

/// Gets the nanosecond of this zoned date and time within the second, in the range 0 to 999,999,999 inclusive.
int get NanosecondOfSecond => offsetDateTime.NanosecondOfSecond;

/// Gets the nanosecond of this zoned date and time within the day, in the range 0 to 86,399,999,999,999 inclusive.
int get  NanosecondOfDay => offsetDateTime.NanosecondOfDay;

/// Converts this value to the instant it represents on the time line.
///
/// This is always an unambiguous conversion. Any difficulties due to daylight saving
/// transitions or other changes in time zone are handled when converting from a
/// [LocalDateTime] to a [ZonedDateTime]; the `ZonedDateTime` remembers
/// the actual offset from UTC to local time, so it always knows the exact instant represented.
///
/// Returns: The instant corresponding to this value.

Instant ToInstant() => offsetDateTime.ToInstant();

/// Creates a new [ZonedDateTime] representing the same instant in time, in the
/// same calendar but a different time zone.
///
/// [targetZone]: The target time zone to convert to.
/// Returns: A new value in the target time zone.

ZonedDateTime WithZone(DateTimeZone targetZone)
{
Preconditions.checkNotNull(targetZone, 'targetZone');
return new ZonedDateTime.withCalendar(ToInstant(), targetZone, Calendar);
}

/// Creates a new ZonedDateTime representing the same physical date, time and offset, but in a different calendar.
/// The returned ZonedDateTime is likely to have different date field values to this one.
/// For example, January 1st 1970 in the Gregorian calendar was December 19th 1969 in the Julian calendar.
///
/// [calendar]: The calendar system to convert this zoned date and time to.
/// Returns: The converted ZonedDateTime.

ZonedDateTime WithCalendar(CalendarSystem calendar)
{
return new ZonedDateTime.trusted(offsetDateTime.WithCalendar(calendar), zone);
}

/// Indicates whether the current object is equal to another object of the same type.
///
/// true if the current object is equal to the [other] parameter; otherwise, false.
///
/// [other]: An object to compare with this object.
/// Returns: True if the specified value is the same instant in the same time zone; false otherwise.
bool Equals(ZonedDateTime other) => offsetDateTime == other.offsetDateTime && Zone == other.Zone;

/// Computes the hash code for this instance.
///
/// A 32-bit signed integer that is the hash code for this instance.
///
/// <filterpriority>2</filterpriority>
@override int get hashCode => hash2(offsetDateTime, zone);

/// Implements the operator ==.
///
/// [left]: The first value to compare
/// [right]: The second value to compare
/// Returns: True if the two operands are equal according to [Equals(ZonedDateTime)]; false otherwise
@override bool operator ==(dynamic right) => right is ZonedDateTime && Equals(right);

/// Adds a duration to a zoned date and time.
///
/// This is an alternative way of calling [op_Addition(ZonedDateTime, Duration)].
///
/// [zonedDateTime]: The value to add the duration to.
/// [span]: The duration to add
/// Returns: A new value with the time advanced by the given duration, in the same calendar system and time zone.
static ZonedDateTime AddSpan(ZonedDateTime zonedDateTime, Span span) => zonedDateTime + span;

/// Returns the result of adding a duration to this zoned date and time.
///
/// This is an alternative way of calling [op_Addition(ZonedDateTime, Duration)].
///
/// [span]: The duration to add
/// Returns: A new [ZonedDateTime] representing the result of the addition.

ZonedDateTime PlusSpan(Span span) => this + span;

/// Returns the result of adding a increment of hours to this zoned date and time
///
/// [hours]: The number of hours to add
/// Returns: A new [ZonedDateTime] representing the result of the addition.

ZonedDateTime PlusHours(int hours) => this + new Span(hours: hours);

/// Returns the result of adding an increment of minutes to this zoned date and time
///
/// [minutes]: The number of minutes to add
/// Returns: A new [ZonedDateTime] representing the result of the addition.

ZonedDateTime PlusMinutes(int minutes) => this + new Span(minutes: minutes);

/// Returns the result of adding an increment of seconds to this zoned date and time
///
/// [seconds]: The number of seconds to add
/// Returns: A new [ZonedDateTime] representing the result of the addition.

ZonedDateTime PlusSeconds(int seconds) => this + new Span(seconds: seconds);

/// Returns the result of adding an increment of milliseconds to this zoned date and time
///
/// [milliseconds]: The number of milliseconds to add
/// Returns: A new [ZonedDateTime] representing the result of the addition.

ZonedDateTime PlusMilliseconds(int milliseconds) => this + new Span(milliseconds: milliseconds);

/// Returns the result of adding an increment of ticks to this zoned date and time
///
/// [ticks]: The number of ticks to add
/// Returns: A new [ZonedDateTime] representing the result of the addition.

ZonedDateTime PlusTicks(int ticks) => this + new Span(ticks: ticks);

/// Returns the result of adding an increment of nanoseconds to this zoned date and time
///
/// [nanoseconds]: The number of nanoseconds to add
/// Returns: A new [ZonedDateTime] representing the result of the addition.

ZonedDateTime PlusNanoseconds(int nanoseconds) => this + new Span(nanoseconds: nanoseconds);

/// Returns a new [ZonedDateTime] with the time advanced by the given duration. Note that
/// due to daylight saving time changes this may not advance the local time by the same amount.
///
/// The returned value retains the calendar system and time zone of [zonedDateTime].
///
/// [zonedDateTime]: The [ZonedDateTime] to add the duration to.
/// [span]: The duration to add.
/// Returns: A new value with the time advanced by the given duration, in the same calendar system and time zone.
ZonedDateTime operator +(Span span) =>
new ZonedDateTime.withCalendar(ToInstant() + span, zone, Calendar);

/// Subtracts a duration from a zoned date and time.
///
/// This is an alternative way of calling [op_Subtraction(ZonedDateTime, Duration)].
///
/// [zonedDateTime]: The value to subtract the duration from.
/// [span]: The duration to subtract.
/// Returns: A new value with the time "rewound" by the given duration, in the same calendar system and time zone.
static ZonedDateTime SubtractSpan(ZonedDateTime zonedDateTime, Span span) => zonedDateTime.MinusSpan(span);

/// Returns the result of subtracting a duration from this zoned date and time, for a fluent alternative to
/// [op_Subtraction(ZonedDateTime, Duration)]
///
/// [span]: The duration to subtract
/// Returns: A new [ZonedDateTime] representing the result of the subtraction.

ZonedDateTime MinusSpan(Span span) => new ZonedDateTime.withCalendar(ToInstant() - span, zone, Calendar);

/// Subtracts one zoned date and time from another, returning an elapsed duration.
///
/// This is an alternative way of calling [op_Subtraction(ZonedDateTime, ZonedDateTime)].
///
/// [end]: The zoned date and time value to subtract from; if this is later than [start]
/// then the result will be positive.
/// [start]: The zoned date and time to subtract from [end].
/// Returns: The elapsed duration from [start] to [end].
static Span Subtract(ZonedDateTime end, ZonedDateTime start) => end.Minus(start);

/// Returns the result of subtracting another zoned date and time from this one, resulting in the elapsed duration
/// between the two instants represented in the values.
///
/// This is an alternative way of calling [op_Subtraction(ZonedDateTime, ZonedDateTime)].
///
/// [other]: The zoned date and time to subtract from this one.
/// Returns: The elapsed duration from [other] to this value.

Span Minus(ZonedDateTime other) => ToInstant() - other.ToInstant();

/// Subtracts one [ZonedDateTime] from another, resulting in the elapsed time between
/// the two values.
///
/// This is equivalent to `end.ToInstant() - start.ToInstant()`; in particular:
/// <list type="bullet">
///   <item><description>The two values can use different calendar systems</description></item>
///   <item><description>The two values can be in different time zones</description></item>
///   <item><description>The two values can have different UTC offsets</description></item>
/// </list>
///
/// [end]: The zoned date and time value to subtract from; if this is later than [start]
/// then the result will be positive.
/// [start]: The zoned date and time to subtract from [end].
/// Returns: The elapsed duration from [start] to [end].
/// Returns a new [ZonedDateTime] with the duration subtracted. Note that
/// due to daylight saving time changes this may not change the local time by the same amount.
///
/// The returned value retains the calendar system and time zone of [zonedDateTime].
///
/// [zonedDateTime]: The value to subtract the duration from.
/// [span]: The duration to subtract.
/// Returns: A new value with the time "rewound" by the given duration, in the same calendar system and time zone.
// todo: I really do not like this pattern
dynamic operator -(dynamic start) => start is Span ? MinusSpan(start) : start is ZonedDateTime ? Minus(start) : throw new TypeError();

/// Returns the [ZoneInterval] containing this value, in the time zone this
/// value refers to.
///
/// This is simply a convenience method - it is logically equivalent to converting this
/// value to an [Instant] and then asking the appropriate [DateTimeZone]
/// for the `ZoneInterval` containing that instant.
///
/// Returns: The `ZoneInterval` containing this value.
ZoneInterval GetZoneInterval() => Zone.getZoneInterval(ToInstant());

/// Indicates whether or not this [ZonedDateTime] is in daylight saving time
/// for its time zone. This is determined by checking the [ZoneInterval.Savings] property
/// of the zone interval containing this value.
///
/// <seealso cref="GetZoneInterval()"/>
/// `true` if the zone interval containing this value has a non-zero savings
/// component; `false` otherwise.

bool IsDaylightSavingTime() => GetZoneInterval().savings != Offset.zero;

  /// Returns a [String] that represents this instance.
  ///
  /// The value of the current instance in the default format pattern ("G"), using the current thread's
  /// culture to obtain a format provider.
  // @override String toString() => TextShim.toStringZonedDateTime(this);
  @override String toString([String patternText = null, /*IFormatProvider*/ dynamic formatProvider = null]) =>
      ZonedDateTimePatterns.BclSupport.Format(this, patternText, formatProvider ?? CultureInfo.currentCulture);

/// Formats the value of the current instance using the specified pattern.
///
/// A [String] containing the value of the current instance in the specified format.
///
/// [patternText]: The [String] specifying the pattern to use,
/// or null to use the default format pattern ("G").
///
/// [formatProvider]: The [IIFormatProvider] to use when formatting the value,
/// or null to use the current thread's culture to obtain a format provider.
///
/// <filterpriority>2</filterpriority>
//String toStringFormatted(String patternText, IFormatProvider formatProvider) =>
//ZonedDateTimePattern.Patterns.BclSupport.Format(this, patternText, formatProvider);

/// Constructs a [DateTimeOffset] value with the same local time and offset from
/// UTC as this value.
///
/// An offset does not convey as much information as a time zone; a [DateTimeOffset]
/// represents an instant in time aint with an associated local time, but it doesn't allow you
/// to find out what the local time would be for another instant.
///
/// If the date and time is not on a tick boundary (the unit of granularity of DateTime) the value will be truncated
/// towards the start of time.
///
/// If the offset has a non-zero second component, this is truncated as `DateTimeOffset` has an offset
/// granularity of minutes.
///
/// [InvalidOperationException]: The date/time is outside the range of `DateTimeOffset`,
/// or the offset is outside the range of +/-14 hours (the range supported by `DateTimeOffset`).
/// A `DateTimeOffset` with the same local date/time and offset as this. The [DateTime] part of
/// the result always has a "kind" of Unspecified.
// DateTimeOffset ToDateTimeOffset() => offsetDateTime.ToDateTimeOffset();

/// Returns a new [ZonedDateTime] representing the same instant in time as the given
/// [DateTimeOffset].
/// The time zone used will be a fixed time zone, which uses the same offset throughout time.
///
/// [dateTimeOffset]: Date and time value with an offset.
/// Returns: A [ZonedDateTime] value representing the same instant in time as the given [DateTimeOffset].
//static ZonedDateTime FromDateTimeOffset(DateTimeOffset dateTimeOffset) =>
//new ZonedDateTime(Instant.FromDateTimeOffset(dateTimeOffset),
//new FixedDateTimeZone(Offset.FromTimeSpan(dateTimeOffset.Offset)));

/// Constructs a [DateTime] from this [ZonedDateTime] which has a
/// [DateTime.Kind] of [DateTimeKind.utc] and represents the same instant of time as
/// this value rather than the same local time.
///
/// If the date and time is not on a tick boundary (the unit of granularity of DateTime) the value will be truncated
/// towards the start of time.
///
/// [InvalidOperationException]: The final date/time is outside the range of `DateTime`.
/// A [DateTime] representation of this value with a "universal" kind, with the same
/// instant of time as this value.

DateTime ToDateTimeUtc() => ToInstant().toDateTimeUtc();

/// Constructs a [DateTime] from this [ZonedDateTime] which has a
/// [DateTime.Kind] of [DateTimeKind.Unspecified] and represents the same local time as
/// this value rather than the same instant in time.
///
/// [DateTimeKind.Unspecified] is slightly odd - it can be treated as UTC if you use [DateTime.ToLocalTime]
/// or as system local time if you use [DateTime.ToUniversalTime], but it's the only kind which allows
/// you to construct a [DateTimeOffset] with an arbitrary offset.
///
/// If the date and time is not on a tick boundary (the unit of granularity of DateTime) the value will be truncated
/// towards the start of time.
///
/// [InvalidOperationException]: The date/time is outside the range of `DateTime`.
/// A [DateTime] representation of this value with an "unspecified" kind, with the same
/// local date and time as this value.

DateTime ToDateTimeUnspecified() => localDateTime.toDateTimeUnspecified();

/// Constructs an [OffsetDateTime] with the same local date and time, and the same offset
/// as this zoned date and time, effectively just "removing" the time zone itself.
///
/// Returns: An OffsetDateTime with the same local date/time and offset as this value.

OffsetDateTime ToOffsetDateTime() => offsetDateTime;

}

/// Base class for [ZonedDateTime] comparers.
///
/// Use the static properties of this class to obtain instances. This type is exposed so that the
/// same value can be used for both equality and ordering comparisons.
@immutable
abstract class ZonedDateTimeComparer // : IComparer<ZonedDateTime>, IEqualityComparer<ZonedDateTime>
    {
// TODO(feature): A comparer which compares instants, but in a calendar-sensitive manner?

  /// Gets a comparer which compares [ZonedDateTime] values by their local date/time, without reference to
  /// the time zone or offset. Comparisons between two values of different calendar systems will fail with [ArgumentException].
  ///
  /// For example, this comparer considers 2013-03-04T20:21:00 (Europe/London) to be later than
  /// 2013-03-04T19:21:00 (America/Los_Angeles) even though the second value represents a later instant in time.
  /// This property will return a reference to the same instance every time it is called.
  static ZonedDateTimeComparer get local => ZonedDateTime_LocalComparer.Instance;

  /// Gets a comparer which compares [ZonedDateTime] values by the instants obtained by applying the offset to
  /// the local date/time, ignoring the calendar system.
  ///
  /// For example, this comparer considers 2013-03-04T20:21:00 (Europe/London) to be earlier than
  /// 2013-03-04T19:21:00 (America/Los_Angeles) even though the second value has a local time which is earlier; the time zones
  /// mean that the first value occurred earlier in the universal time line.
  /// This property will return a reference to the same instance every time it is called.
  ///
  /// <value>A comparer which compares values by the instants obtained by applying the offset to
  /// the local date/time, ignoring the calendar system.</value>
  static ZonedDateTimeComparer get instant => ZonedDateTime_InstantComparer.Instance;

  /// Internal constructor to prevent external classes from deriving from this.
  /// (That means we can add more abstract members in the future.)
  @internal ZonedDateTimeComparer() {
  }

  /// Compares two [ZonedDateTime] values and returns a value indicating whether one is less than, equal to, or greater than the other.
  ///
  /// [x]: The first value to compare.
  /// [y]: The second value to compare.
  /// A signed integer that indicates the relative values of [x] and [y], as shown in the following table.
  ///   <list type = "table">
  ///     <listheader>
  ///       <term>Value</term>
  ///       <description>Meaning</description>
  ///     </listheader>
  ///     <item>
  ///       <term>Less than zero</term>
  ///       <description>[x] is less than [y].</description>
  ///     </item>
  ///     <item>
  ///       <term>Zero</term>
  ///       <description>[x] is equals to [y].</description>
  ///     </item>
  ///     <item>
  ///       <term>Greater than zero</term>
  ///       <description>[x] is greater than [y].</description>
  ///     </item>
  ///   </list>
  int compare(ZonedDateTime x, ZonedDateTime y);

  /// Determines whether the specified `ZonedDateTime` values are equal.
  ///
  /// [x]: The first `ZonedDateTime` to compare.
  /// [y]: The second `ZonedDateTime` to compare.
  /// Returns: `true` if the specified objects are equal; otherwise, `false`.
  bool equals(ZonedDateTime x, ZonedDateTime y);

  /// Returns a hash code for the specified `ZonedDateTime`.
  ///
  /// [obj]: The `ZonedDateTime` for which a hash code is to be returned.
  /// Returns: A hash code for the specified value.
  int getHashCode(ZonedDateTime obj);
}

/// Implementation for [Comparer.Local].
@private class ZonedDateTime_LocalComparer extends ZonedDateTimeComparer {
  @internal static final ZonedDateTimeComparer Instance = new ZonedDateTime_LocalComparer();

  @private ZonedDateTime_LocalComparer() {
  }

  /// <inheritdoc />
  @override int compare(ZonedDateTime x, ZonedDateTime y) =>
      OffsetDateTimeComparer.local.compare(x.offsetDateTime, y.offsetDateTime);

  /// <inheritdoc />
  @override bool equals(ZonedDateTime x, ZonedDateTime y) =>
      OffsetDateTimeComparer.local.equals(x.offsetDateTime, y.offsetDateTime);

  /// <inheritdoc />
  @override int getHashCode(ZonedDateTime obj) =>
      OffsetDateTimeComparer.local.getHashCode(obj.offsetDateTime);
}


/// Implementation for [Comparer.Instant].
@private class ZonedDateTime_InstantComparer extends ZonedDateTimeComparer {
  @internal static final ZonedDateTimeComparer Instance = new ZonedDateTime_InstantComparer();

  @private ZonedDateTime_InstantComparer() {
  }

  /// <inheritdoc />
  @override int compare(ZonedDateTime x, ZonedDateTime y) =>
      OffsetDateTimeComparer.instant.compare(x.offsetDateTime, y.offsetDateTime);

  /// <inheritdoc />
  @override bool equals(ZonedDateTime x, ZonedDateTime y) =>
      OffsetDateTimeComparer.instant.equals(x.offsetDateTime, y.offsetDateTime);

  /// <inheritdoc />
  @override int getHashCode(ZonedDateTime obj) =>
      OffsetDateTimeComparer.instant.getHashCode(obj.offsetDateTime);
}

