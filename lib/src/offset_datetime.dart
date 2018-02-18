// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/OffsetDateTime.cs
// 27cf251  on Nov 11, 2017

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';

@immutable
class OffsetDateTime // : IEquatable<OffsetDateTime>, IFormattable, IXmlSerializable
{
@private static const int NanosecondsBits = 47;
// todo: we can't use this -- WE CAN NOT USE LONG SIZED MASKS IN JS
//@private static const int NanosecondsMask = 0; // (1L << TimeConstants.nanosecondsBits) - 1;
//@private static const int OffsetMask = ~NanosecondsMask;
@private static const int MinBclOffsetMinutes = -14 * TimeConstants.minutesPerHour;
@private static const int MaxBclOffsetMinutes = 14 * TimeConstants.minutesPerHour;

// These are effectively the fields of a LocalDateTime and an Offset, but by keeping them directly here,
// we reduce the levels of indirection and copying, which makes a surprising difference in speed, and
// should allow us to optimize memory usage too. todo: this may not be the same in Dart
@private final YearMonthDayCalendar yearMonthDayCalendar;
// Bottom NanosecondsBits bits are the nanosecond-of-day; top 17 bits are the offset (in seconds). This has a slight
// execution-time cost (masking for each component) but the logical benefit of saving 4 bytes per
// value actually ends up being 8 bytes per value on a 64-bit CLR due to alignment.
@private final int nanosecondsAndOffset;

// TRUSTED
@internal OffsetDateTime.fullTrust(this.yearMonthDayCalendar, this.nanosecondsAndOffset)
{
  Calendar.ValidateYearMonthDay(YearMonthDay);
}

// TRUSTED
@internal OffsetDateTime._lessTrust(this.yearMonthDayCalendar, LocalTime time, Offset offset)
 : nanosecondsAndOffset = CombineNanoOfDayAndOffset(time.NanosecondOfDay, offset)
{
  Calendar.ValidateYearMonthDay(YearMonthDay);
}

/// <summary>
/// Optimized conversion from an Instant to an OffsetDateTime in the ISO calendar.
/// This is equivalent to <c>new OffsetDateTime(new LocalDateTime(instant.Plus(offset)), offset)</c>
/// but with less overhead.
/// </summary>
@internal factory OffsetDateTime.instant(Instant instant, Offset offset)
{
// unchecked
  int days = instant.DaysSinceEpoch;
  int nanoOfDay = instant.NanosecondOfDay + offset.Nanoseconds;
  if (nanoOfDay >= TimeConstants.nanosecondsPerDay) {
    days++;
    nanoOfDay -= TimeConstants.nanosecondsPerDay;
  }
  else if (nanoOfDay < 0) {
    days--;
    nanoOfDay += TimeConstants.nanosecondsPerDay;
  }
  var yearMonthDayCalendar = GregorianYearMonthDayCalculator.getGregorianYearMonthDayCalendarFromDaysSinceEpoch(days);
  var nanosecondsAndOffset = CombineNanoOfDayAndOffset(nanoOfDay, offset);

  return new OffsetDateTime.fullTrust(yearMonthDayCalendar, nanosecondsAndOffset);
}

/// <summary>
/// Optimized conversion from an Instant to an OffsetDateTime in the specified calendar.
/// This is equivalent to <c>new OffsetDateTime(new LocalDateTime(instant.Plus(offset), calendar), offset)</c>
/// but with less overhead.
/// </summary>
@internal factory OffsetDateTime.instantCalendar(Instant instant, Offset offset, CalendarSystem calendar)
{
// unchecked
    int days = instant.DaysSinceEpoch;
    int nanoOfDay = instant.NanosecondOfDay + offset.Nanoseconds;
    if (nanoOfDay >= TimeConstants.nanosecondsPerDay) {
      days++;
      nanoOfDay -= TimeConstants.nanosecondsPerDay;
    }
    else if (nanoOfDay < 0) {
      days--;
      nanoOfDay += TimeConstants.nanosecondsPerDay;
    }
    var yearMonthDayCalendar = calendar.GetYearMonthDayCalendarFromDaysSinceEpoch(days);
    var nanosecondsAndOffset = CombineNanoOfDayAndOffset(nanoOfDay, offset);
    return new OffsetDateTime.fullTrust(yearMonthDayCalendar, nanosecondsAndOffset);
}

/// <summary>
/// Constructs a new offset date/time with the given local date and time, and the given offset from UTC.
/// </summary>
/// <param name="localDateTime">Local date and time to represent</param>
/// <param name="offset">Offset from UTC</param>
OffsetDateTime(LocalDateTime localDateTime, Offset offset)
    : this.fullTrust(localDateTime.Date.yearMonthDayCalendar, CombineNanoOfDayAndOffset(localDateTime.NanosecondOfDay, offset));

@private static int CombineNanoOfDayAndOffset(int nanoOfDay, Offset offset)
{
  // todo: yeap -- can't do this shit -- also wrecks efficiency strategy here
  return nanoOfDay | (((long) offset.Seconds) << NanosecondsBits);
}

/// <summary>Gets the calendar system associated with this offset date and time.</summary>
/// <value>The calendar system associated with this offset date and time.</value>
CalendarSystem get Calendar => CalendarSystem.ForOrdinal(yearMonthDayCalendar.CalendarOrdinal);

/// <summary>Gets the year of this offset date and time.</summary>
/// <remarks>This returns the "absolute year", so, for the ISO calendar,
/// a value of 0 means 1 BC, for example.</remarks>
/// <value>The year of this offset date and time.</value>
int get Year => yearMonthDayCalendar.Year;

/// <summary>Gets the month of this offset date and time within the year.</summary>
/// <value>The month of this offset date and time within the year.</value>
int get Month => yearMonthDayCalendar.Month;

/// <summary>Gets the day of this offset date and time within the month.</summary>
/// <value>The day of this offset date and time within the month.</value>
int get Day => yearMonthDayCalendar.Day;

@internal YearMonthDay get YearMonthDay => yearMonthDayCalendar.toYearMonthDay();

/// <summary>
/// Gets the week day of this offset date and time expressed as an <see cref="NodaTime.IsoDayOfWeek"/> value.
/// </summary>
/// <value>The week day of this offset date and time expressed as an <c>IsoDayOfWeek</c>.</value>
IsoDayOfWeek get DayOfWeek => Calendar.GetDayOfWeek(yearMonthDayCalendar.toYearMonthDay());

/// <summary>Gets the year of this offset date and time within the era.</summary>
/// <value>The year of this offset date and time within the era.</value>
int get YearOfEra => Calendar.GetYearOfEra(yearMonthDayCalendar.year);

/// <summary>Gets the era of this offset date and time.</summary>
/// <value>The era of this offset date and time.</value>
Era get era => Calendar.GetEra(yearMonthDayCalendar.year);

/// <summary>Gets the day of this offset date and time within the year.</summary>
/// <value>The day of this offset date and time within the year.</value>
int get DayOfYear => Calendar.GetDayOfYear(yearMonthDayCalendar.ToYearMonthDay());

/// <summary>
/// Gets the hour of day of this offest date and time, in the range 0 to 23 inclusive.
/// </summary>
/// <value>The hour of day of this offest date and time, in the range 0 to 23 inclusive.</value>
int get Hour =>
// Effectively nanoseconds / NanosecondsPerHour, but apparently rather more efficient.
((NanosecondOfDay >> 13) / 439453125);

/// <summary>
/// Gets the hour of the half-day of this offest date and time, in the range 1 to 12 inclusive.
/// </summary>
/// <value>The hour of the half-day of this offest date and time, in the range 1 to 12 inclusive.</value>
int get ClockHourOfHalfDay
{
int hourOfHalfDay = HourOfHalfDay;
return hourOfHalfDay == 0 ? 12 : hourOfHalfDay;
}

// TODO(feature): Consider exposing this.
/// <summary>
/// Gets the hour of the half-day of this offset date and time, in the range 0 to 11 inclusive.
/// </summary>
/// <value>The hour of the half-day of this offset date and time, in the range 0 to 11 inclusive.</value>
@internal int get HourOfHalfDay => (Hour % 12);

/// <summary>
/// Gets the minute of this offset date and time, in the range 0 to 59 inclusive.
/// </summary>
/// <value>The minute of this offset date and time, in the range 0 to 59 inclusive.</value>
int get Minute
{
// Effectively NanosecondOfDay / NanosecondsPerMinute, but apparently rather more efficient.
int minuteOfDay = ((NanosecondOfDay >> 11) ~/ 29296875);
return minuteOfDay % TimeConstants.minutesPerHour;
}

/// <summary>
/// Gets the second of this offset date and time within the minute, in the range 0 to 59 inclusive.
/// </summary>
/// <value>The second of this offset date and time within the minute, in the range 0 to 59 inclusive.</value>
int get Second
{
int secondOfDay = (NanosecondOfDay ~/ TimeConstants.nanosecondsPerSecond);
return secondOfDay % TimeConstants.secondsPerMinute;
}

/// <summary>
/// Gets the millisecond of this offset date and time within the second, in the range 0 to 999 inclusive.
/// </summary>
/// <value>The millisecond of this offset date and time within the second, in the range 0 to 999 inclusive.</value>
int get Millisecond
{
  int milliSecondOfDay = (NanosecondOfDay ~/ TimeConstants.nanosecondsPerMillisecond);
  return (int) (milliSecondOfDay % TimeConstants.millisecondsPerSecond);
}

// TODO(optimization): Rewrite for performance?
/// <summary>
/// Gets the tick of this offset date and time within the second, in the range 0 to 9,999,999 inclusive.
/// </summary>
/// <value>The tick of this offset date and time within the second, in the range 0 to 9,999,999 inclusive.</value>
int get TickOfSecond => ((TickOfDay % TimeConstants.ticksPerSecond));

/// <summary>
/// Gets the tick of this offset date and time within the day, in the range 0 to 863,999,999,999 inclusive.
/// </summary>
/// <value>The tick of this offset date and time within the day, in the range 0 to 863,999,999,999 inclusive.</value>
int get TickOfDay => NanosecondOfDay ~/ TimeConstants.nanosecondsPerTick;

/// <summary>
/// Gets the nanosecond of this offset date and time within the second, in the range 0 to 999,999,999 inclusive.
/// </summary>
/// <value>The nanosecond of this offset date and time within the second, in the range 0 to 999,999,999 inclusive.</value>
int get NanosecondOfSecond => ((NanosecondOfDay % TimeConstants.nanosecondsPerSecond));

/// <summary>
/// Gets the nanosecond of this offset date and time within the day, in the range 0 to 86,399,999,999,999 inclusive.
/// </summary>
/// <value>The nanosecond of this offset date and time within the day, in the range 0 to 86,399,999,999,999 inclusive.</value>
int get NanosecondOfDay => nanosecondsAndOffset & NanosecondsMask;

/// <summary>
/// Returns the local date and time represented within this offset date and time.
/// </summary>
/// <value>The local date and time represented within this offset date and time.</value>
// todo: should this be a const? or cached -- or???
LocalDateTime get localDateTime => new LocalDateTime(Date, TimeOfDay);

/// <summary>
/// Gets the local date represented by this offset date and time.
/// </summary>
/// <remarks>
/// The returned <see cref="LocalDate"/>
/// will have the same calendar system and return the same values for each of the date-based calendar
/// properties (Year, MonthOfYear and so on), but will not have any offset information.
/// </remarks>
/// <value>The local date represented by this offset date and time.</value>
LocalDate get Date => new LocalDate.trusted(yearMonthDayCalendar);

/// <summary>
/// Gets the time portion of this offset date and time.
/// </summary>
/// <remarks>
/// The returned <see cref="LocalTime"/> will
/// return the same values for each of the time-based properties (Hour, Minute and so on), but
/// will not have any offset information.
/// </remarks>
/// <value>The time portion of this offset date and time.</value>
LocalTime get TimeOfDay => new LocalTime.fromNanoseconds(NanosecondOfDay);

/// <summary>
/// Gets the offset from UTC.
/// </summary>
/// <value>The offset from UTC.</value>
Offset get offset => new Offset((int) (nanosecondsAndOffset >> NanosecondsBits));

/// <summary>
/// Returns the number of nanoseconds in the offset, without going via an Offset.
/// </summary>
@private int get OffsetNanoseconds => (nanosecondsAndOffset >> NanosecondsBits) * TimeConstants.nanosecondsPerSecond;

/// <summary>
/// Converts this offset date and time to an instant in time by subtracting the offset from the local date and time.
/// </summary>
/// <returns>The instant represented by this offset date and time</returns>

Instant ToInstant() => Instant.FromUntrustedDuration(ToElapsedTimeSinceEpoch());

@private Span ToElapsedTimeSinceEpoch()
{
// Equivalent to LocalDateTime.ToLocalInstant().Minus(offset)
int days = Calendar.GetDaysSinceEpoch(yearMonthDayCalendar.toYearMonthDay());
Span elapsedTime = new Span(days: days, nanoseconds: NanosecondOfDay - OffsetNanoseconds);
// Duration elapsedTime = new Duration(days, NanosecondOfDay).MinusSmallNanoseconds(OffsetNanoseconds);
return elapsedTime;
}

/// <summary>
/// Returns this value as a <see cref="ZonedDateTime"/>.
/// </summary>
/// <remarks>
/// <para>
/// This method returns a <see cref="ZonedDateTime"/> with the same local date and time as this value, using a
/// fixed time zone with the same offset as the offset for this value.
/// </para>
/// <para>
/// Note that because the resulting <c>ZonedDateTime</c> has a fixed time zone, it is generally not useful to
/// use this result for arithmetic operations, as the zone will not adjust to account for daylight savings.
/// </para>
/// </remarks>
/// <returns>A zoned date/time with the same local time and a fixed time zone using the offset from this value.</returns>

ZonedDateTime get InFixedZone() => new ZonedDateTime(this, DateTimeZone.ForOffset(offset));

/// <summary>
/// Returns this value in ths specified time zone. This method does not expect
/// the offset in the zone to be the same as for the current value; it simply converts
/// this value into an <see cref="Instant"/> and finds the <see cref="ZonedDateTime"/>
/// for that instant in the specified zone.
/// </summary>
/// <param name="zone">The time zone of the new value.</param>
/// <returns>The instant represented by this value, in the specified time zone.</returns>

ZonedDateTime InZone(DateTimeZone zone)
{
Preconditions.checkNotNull(zone, 'zone');
return ToInstant().InZone(zone);
}

/// <summary>
/// Creates a new OffsetDateTime representing the same physical date, time and offset, but in a different calendar.
/// The returned OffsetDateTime is likely to have different date field values to this one.
/// For example, January 1st 1970 in the Gregorian calendar was December 19th 1969 in the Julian calendar.
/// </summary>
/// <param name="calendar">The calendar system to convert this offset date and time to.</param>
/// <returns>The converted OffsetDateTime.</returns>

OffsetDateTime WithCalendar(CalendarSystem calendar)
{
LocalDate newDate = Date.WithCalendar(calendar);
return new OffsetDateTime(newDate.yearMonthDayCalendar, nanosecondsAndOffset);
}

/// <summary>
/// Returns this offset date/time, with the given date adjuster applied to it, maintaining the existing time of day and offset.
/// </summary>
/// <remarks>
/// If the adjuster attempts to construct an
/// invalid date (such as by trying to set a day-of-month of 30 in February), any exception thrown by
/// that construction attempt will be propagated through this method.
/// </remarks>
/// <param name="adjuster">The adjuster to apply.</param>
/// <returns>The adjusted offset date/time.</returns>

OffsetDateTime WithDate(LocalDate Function(LocalDate) adjuster)
{
LocalDate newDate = Date.With(adjuster);
return new OffsetDateTime(newDate.yearMonthDayCalendar, nanosecondsAndOffset);
}

/// <summary>
/// Returns this date/time, with the given time adjuster applied to it, maintaining the existing date and offset.
/// </summary>
/// <remarks>
/// If the adjuster attempts to construct an invalid time, any exception thrown by
/// that construction attempt will be propagated through this method.
/// </remarks>
/// <param name="adjuster">The adjuster to apply.</param>
/// <returns>The adjusted offset date/time.</returns>

OffsetDateTime WithTime(LocalTime Function(LocalTime) adjuster)
{
LocalTime newTime = TimeOfDay.With(adjuster);
return new OffsetDateTime(yearMonthDayCalendar, (nanosecondsAndOffset & OffsetMask) | newTime.NanosecondOfDay);
}

/// <summary>
/// Creates a new OffsetDateTime representing the instant in time in the same calendar,
/// but with a different offset. The local date and time is adjusted accordingly.
/// </summary>
/// <param name="offset">The new offset to use.</param>
/// <returns>The converted OffsetDateTime.</returns>

OffsetDateTime WithOffset(Offset offset) {
  // Slight change to the normal operation, as it's *just* about plausible that we change day
  // twice in one direction or the other.
  int days = 0;
  int nanos = (nanosecondsAndOffset & NanosecondsMask) + offset.nanoseconds - OffsetNanoseconds;
  if (nanos >= TimeConstants.nanosecondsPerDay) {
    days++;
    nanos -= TimeConstants.nanosecondsPerDay;
    if (nanos >= TimeConstants.nanosecondsPerDay) {
      days++;
      nanos -= TimeConstants.nanosecondsPerDay;
    }
  }
  else if (nanos < 0) {
    days--;
    nanos += TimeConstants.nanosecondsPerDay;
    if (nanos < 0) {
      days--;
      nanos += TimeConstants.nanosecondsPerDay;
    }
  }
  return new OffsetDateTime(
      days == 0 ? yearMonthDayCalendar : Date
          .PlusDays(days)
          .yearMonthDayCalendar,
      CombineNanoOfDayAndOffset(nanos, offset));
}

/// <summary>
/// Constructs a new <see cref="OffsetDate"/> from the date and offset of this value,
/// but omitting the time-of-day.
/// </summary>
/// <returns>A value representing the date and offset aspects of this value.</returns>

OffsetDate get ToOffsetDate() => new OffsetDate(Date, offset);

/// <summary>
/// Constructs a new <see cref="OffsetTime"/> from the time and offset of this value,
/// but omitting the date.
/// </summary>
/// <returns>A value representing the time and offset aspects of this value.</returns>

OffsetTime get ToOffsetTime() => new OffsetTime(TimeOfDay, offset);

/// <summary>
/// Returns a hash code for this offset date and time.
/// </summary>
/// <returns>A hash code for this offset date and time.</returns>
@override int get hashCode => hash2(LocalDateTime, offset);

/// <summary>
/// Compares two <see cref="OffsetDateTime"/> values for equality. This requires
/// that the local date/time values be the same (in the same calendar) and the offsets.
/// </summary>
/// <param name="other">The value to compare this offset date/time with.</param>
/// <returns>True if the given value is another offset date/time equal to this one; false otherwise.</returns>
bool equals(OffsetDateTime other) =>
this.yearMonthDayCalendar == other.yearMonthDayCalendar && this.nanosecondsAndOffset == other.nanosecondsAndOffset;

/// <summary>
/// Returns a <see cref="System.String" /> that represents this instance.
/// </summary>
/// <returns>
/// The value of the current instance in the default format pattern ("G"), using the current thread's
/// culture to obtain a format provider.
/// </returns>
@override String toString() => OffsetDateTimePattern.Patterns.BclSupport.Format(this, null, CultureInfo.CurrentCulture);

/// <summary>
/// Formats the value of the current instance using the specified pattern.
/// </summary>
/// <returns>
/// A <see cref="T:System.String" /> containing the value of the current instance in the specified format.
/// </returns>
/// <param name="patternText">The <see cref="T:System.String" /> specifying the pattern to use,
/// or null to use the default format pattern ("G").
/// </param>
/// <param name="formatProvider">The <see cref="T:System.IFormatProvider" /> to use when formatting the value,
/// or null to use the current thread's culture to obtain a format provider.
/// </param>
/// <filterpriority>2</filterpriority>
String toString_Format(String patternText, IFormatProvider formatProvider) =>
OffsetDateTimePattern.Patterns.BclSupport.Format(this, patternText, formatProvider);

/// <summary>
/// Adds a duration to an offset date and time.
/// </summary>
/// <remarks>
/// This is an alternative way of calling <see cref="op_Addition(OffsetDateTime, Duration)"/>.
/// </remarks>
/// <param name="offsetDateTime">The value to add the duration to.</param>
/// <param name="duration">The duration to add</param>
/// <returns>A new value with the time advanced by the given duration, in the same calendar system and with the same offset.</returns>
static OffsetDateTime Add(OffsetDateTime offsetDateTime, Span span) => offsetDateTime + span;

/// <summary>
/// Returns the result of adding a duration to this offset date and time.
/// </summary>
/// <remarks>
/// This is an alternative way of calling <see cref="op_Addition(OffsetDateTime, Duration)"/>.
/// </remarks>
/// <param name="duration">The duration to add</param>
/// <returns>A new <see cref="OffsetDateTime" /> representing the result of the addition.</returns>

OffsetDateTime Plus(Span span) => this + span;

/// <summary>
/// Returns the result of adding a increment of hours to this zoned date and time
/// </summary>
/// <param name="hours">The number of hours to add</param>
/// <returns>A new <see cref="OffsetDateTime" /> representing the result of the addition.</returns>

OffsetDateTime PlusHours(int hours) => this + new Span(hours: hours);

/// <summary>
/// Returns the result of adding an increment of minutes to this zoned date and time
/// </summary>
/// <param name="minutes">The number of minutes to add</param>
/// <returns>A new <see cref="OffsetDateTime" /> representing the result of the addition.</returns>

OffsetDateTime PlusMinutes(int minutes) => this + new Span(minutes: minutes);

/// <summary>
/// Returns the result of adding an increment of seconds to this zoned date and time
/// </summary>
/// <param name="seconds">The number of seconds to add</param>
/// <returns>A new <see cref="OffsetDateTime" /> representing the result of the addition.</returns>

OffsetDateTime PlusSeconds(int seconds) => this + new Span(seconds: seconds);

/// <summary>
/// Returns the result of adding an increment of milliseconds to this zoned date and time
/// </summary>
/// <param name="milliseconds">The number of milliseconds to add</param>
/// <returns>A new <see cref="OffsetDateTime" /> representing the result of the addition.</returns>

OffsetDateTime PlusMilliseconds(int milliseconds) => this + new Span(milliseconds: milliseconds);

/// <summary>
/// Returns the result of adding an increment of ticks to this zoned date and time
/// </summary>
/// <param name="ticks">The number of ticks to add</param>
/// <returns>A new <see cref="OffsetDateTime" /> representing the result of the addition.</returns>

OffsetDateTime PlusTicks(int ticks) => this + new Span(ticks: ticks);

/// <summary>
/// Returns the result of adding an increment of nanoseconds to this zoned date and time
/// </summary>
/// <param name="nanoseconds">The number of nanoseconds to add</param>
/// <returns>A new <see cref="OffsetDateTime" /> representing the result of the addition.</returns>

OffsetDateTime PlusNanoseconds(int nanoseconds) => this + new Span(nanoseconds: nanoseconds);

/// <summary>
/// Returns a new <see cref="OffsetDateTime"/> with the time advanced by the given duration.
/// </summary>
/// <remarks>
/// The returned value retains the calendar system and offset of the <paramref name="offsetDateTime"/>.
/// </remarks>
/// <param name="offsetDateTime">The <see cref="OffsetDateTime"/> to add the duration to.</param>
/// <param name="duration">The duration to add.</param>
/// <returns>A new value with the time advanced by the given duration, in the same calendar system and with the same offset.</returns>
OffsetDateTime operator +(Span span) =>
new OffsetDateTime(ToInstant() + span, offset);

/// <summary>
/// Subtracts a duration from an offset date and time.
/// </summary>
/// <remarks>
/// This is an alternative way of calling <see cref="op_Subtraction(OffsetDateTime, Duration)"/>.
/// </remarks>
/// <param name="offsetDateTime">The value to subtract the duration from.</param>
/// <param name="duration">The duration to subtract.</param>
/// <returns>A new value with the time "rewound" by the given duration, in the same calendar system and with the same offset.</returns>
static OffsetDateTime Subtract(OffsetDateTime offsetDateTime, Span span) => offsetDateTime - span;

/// <summary>
/// Returns the result of subtracting a duration from this offset date and time, for a fluent alternative to
/// <see cref="op_Subtraction(OffsetDateTime, Duration)"/>
/// </summary>
/// <param name="duration">The duration to subtract</param>
/// <returns>A new <see cref="OffsetDateTime" /> representing the result of the subtraction.</returns>

OffsetDateTime Minus(Span span) => this - span;

/// <summary>
/// Returns a new <see cref="OffsetDateTime"/> with the duration subtracted.
/// </summary>
/// <remarks>
/// The returned value retains the calendar system and offset of the <paramref name="offsetDateTime"/>.
/// </remarks>
/// <param name="offsetDateTime">The value to subtract the duration from.</param>
/// <param name="duration">The duration to subtract.</param>
/// <returns>A new value with the time "rewound" by the given duration, in the same calendar system and with the same offset.</returns>
OffsetDateTime operator -(Duration duration) =>
new OffsetDateTime(ToInstant() - duration, offset);

/// <summary>
/// Subtracts one offset date and time from another, returning an elapsed duration.
/// </summary>
/// <remarks>
/// This is an alternative way of calling <see cref="op_Subtraction(OffsetDateTime, OffsetDateTime)"/>.
/// </remarks>
/// <param name="end">The offset date and time value to subtract from; if this is later than <paramref name="start"/>
/// then the result will be positive.</param>
/// <param name="start">The offset date and time to subtract from <paramref name="end"/>.</param>
/// <returns>The elapsed duration from <paramref name="start"/> to <paramref name="end"/>.</returns>
static Duration Subtract(OffsetDateTime end, OffsetDateTime start) => end - start;

/// <summary>
/// Returns the result of subtracting another offset date and time from this one, resulting in the elapsed duration
/// between the two instants represented in the values.
/// </summary>
/// <remarks>
/// This is an alternative way of calling <see cref="op_Subtraction(OffsetDateTime, OffsetDateTime)"/>.
/// </remarks>
/// <param name="other">The offset date and time to subtract from this one.</param>
/// <returns>The elapsed duration from <paramref name="other"/> to this value.</returns>

Duration Minus(OffsetDateTime other) => this - other;

/// <summary>
/// Subtracts one <see cref="OffsetDateTime"/> from another, resulting in the elapsed time between
/// the two values.
/// </summary>
/// <remarks>
/// This is equivalent to <c>end.ToInstant() - start.ToInstant()</c>; in particular:
/// <list type="bullet">
///   <item><description>The two values can use different calendar systems</description></item>
///   <item><description>The two values can have different UTC offsets</description></item>
/// </list>
/// </remarks>
/// <param name="end">The offset date and time value to subtract from; if this is later than <paramref name="start"/>
/// then the result will be positive.</param>
/// <param name="start">The offset date and time to subtract from <paramref name="end"/>.</param>
/// <returns>The elapsed duration from <paramref name="start"/> to <paramref name="end"/>.</returns>
static Duration operator -(OffsetDateTime end, OffsetDateTime start) => end.ToInstant() - start.ToInstant();

/// <summary>
/// Implements the operator == (equality).
/// </summary>
/// <param name="left">The left hand side of the operator.</param>
/// <param name="right">The right hand side of the operator.</param>
/// <returns><c>true</c> if values are equal to each other, otherwise <c>false</c>.</returns>
bool operator ==(dynamic right) => right is OffsetDateTime && equals(right);


}

// todo: very unsure about what to do with these

/// <summary>
/// Implementation for <see cref="Comparer.Local"/>
/// </summary>
@private class OffsetDateTime_LocalComparer extends OffsetDateTimeComparer {
  @internal static final OffsetDateTimeComparer Instance = new OffsetDateTime_LocalComparer();

  @private OffsetDateTime_LocalComparer() {
  }

  /// <inheritdoc />
  @override int compare(OffsetDateTime x, OffsetDateTime y) {
    Preconditions.checkArgument(x.Calendar == y.Calendar, 'y',
        "Only values with the same calendar system can be compared");
    int dateComparison = x.Calendar.Compare(x.YearMonthDay, y.YearMonthDay);
    if (dateComparison != 0) {
      return dateComparison;
    }
    return x.NanosecondOfDay.compareTo(y.NanosecondOfDay);
  }

  /// <inheritdoc />
  @override bool equals(OffsetDateTime x, OffsetDateTime y) =>
      x.yearMonthDayCalendar == y.yearMonthDayCalendar && x.NanosecondOfDay == y.NanosecondOfDay;

  /// <inheritdoc />
  @override int getHashCode(OffsetDateTime obj) => hash2(obj.yearMonthDayCalendar, obj.NanosecondOfDay);
}


/// <summary>
/// Base class for <see cref="OffsetDateTime"/> comparers.
/// </summary>
/// <remarks>
/// Use the static properties of this class to obtain instances. This type is exposed so that the
/// same value can be used for both equality and ordering comparisons.
/// </remarks>
@immutable
abstract class OffsetDateTimeComparer // implements Comparable<OffsetDateTime> // : IComparer<OffsetDateTime>, IEqualityComparer<OffsetDateTime>
    {
// TODO(feature): Should we have a comparer which is calendar-sensitive (so will fail if the calendars are different)
// but still uses the offset?

  /// <summary>
  /// Gets a comparer which compares <see cref="OffsetDateTime"/> values by their local date/time, without reference to
  /// the offset. Comparisons between two values of different calendar systems will fail with <see cref="ArgumentException"/>.
  /// </summary>
  /// <remarks>
  /// <para>For example, this comparer considers 2013-03-04T20:21:00+0100 to be later than 2013-03-04T19:21:00-0700 even though
  /// the second value represents a later instant in time.</para>
  /// <para>This property will return a reference to the same instance every time it is called.</para>
  /// </remarks>
  /// <value>A comparer which compares values by their local date/time, without reference to the offset.</value>
  static OffsetDateTimeComparer get local => OffsetDateTime_LocalComparer.Instance;

  /// <summary>
  /// Returns a comparer which compares <see cref="OffsetDateTime"/> values by the instant values obtained by applying the offset to
  /// the local date/time, ignoring the calendar system.
  /// </summary>
  /// <remarks>
  /// <para>For example, this comparer considers 2013-03-04T20:21:00+0100 to be earlier than 2013-03-04T19:21:00-0700 even though
  /// the second value has a local time which is earlier.</para>
  /// <para>This property will return a reference to the same instance every time it is called.</para>
  /// </remarks>
  /// <value>A comparer which compares values by the instant values obtained by applying the offset to
  /// the local date/time, ignoring the calendar system.</value>
  static OffsetDateTimeComparer get instant => OffsetDateTime_InstantComparer.Instance;

  /// <summary>
  /// @internal constructor to prevent external classes from deriving from this.
  /// (That means we can add more abstract members in the future.)
  /// </summary>
  @internal Comparer() {
  }

  /// <summary>
  /// Compares two <see cref="OffsetDateTime"/> values and returns a value indicating whether one is less than, equal to, or greater than the other.
  /// </summary>
  /// <param name="x">The first value to compare.</param>
  /// <param name="y">The second value to compare.</param>
  /// <returns>A signed integer that indicates the relative values of <paramref name="x"/> and <paramref name="y"/>, as shown in the following table.
  ///   <list type = "table">
  ///     <listheader>
  ///       <term>Value</term>
  ///       <description>Meaning</description>
  ///     </listheader>
  ///     <item>
  ///       <term>Less than zero</term>
  ///       <description><paramref name="x"/> is less than <paramref name="y"/>.</description>
  ///     </item>
  ///     <item>
  ///       <term>Zero</term>
  ///       <description><paramref name="x"/> is equals to <paramref name="y"/>.</description>
  ///     </item>
  ///     <item>
  ///       <term>Greater than zero</term>
  ///       <description><paramref name="x"/> is greater than <paramref name="y"/>.</description>
  ///     </item>
  ///   </list>
  /// </returns>
  int compare(OffsetDateTime x, OffsetDateTime y);

  /// <summary>
  /// Determines whether the specified <c>OffsetDateTime</c> values are equal.
  /// </summary>
  /// <param name="x">The first <c>OffsetDateTime</c> to compare.</param>
  /// <param name="y">The second <c>OffsetDateTime</c> to compare.</param>
  /// <returns><c>true</c> if the specified objects are equal; otherwise, <c>false</c>.</returns>
  bool equals(OffsetDateTime x, OffsetDateTime y);

  /// <summary>
  /// Returns a hash code for the specified <c>OffsetDateTime</c>.
  /// </summary>
  /// <param name="obj">The <c>OffsetDateTime</c> for which a hash code is to be returned.</param>
  /// <returns>A hash code for the specified value.</returns>
  int getHashCode(OffsetDateTime obj);
}


/// <summary>
/// Implementation for <see cref="Comparer.Instant"/>.
/// </summary>
@private class OffsetDateTime_InstantComparer extends OffsetDateTimeComparer {
  @internal static final OffsetDateTimeComparer Instance = new OffsetDateTime_InstantComparer();

  @private OffsetDateTime_InstantComparer() {
  }

  /// <inheritdoc />
  @override int compare(OffsetDateTime x, OffsetDateTime y) =>
// TODO(optimization): Optimize cases which are more than 2 days apart, by avoiding the arithmetic?
  x.ToElapsedTimeSinceEpoch().compareTo(y.ToElapsedTimeSinceEpoch());

  /// <inheritdoc />
  @override bool equals(OffsetDateTime x, OffsetDateTime y) =>
      x.ToElapsedTimeSinceEpoch() == y.ToElapsedTimeSinceEpoch();

  /// <inheritdoc />
  @override int getHashCode(OffsetDateTime obj) =>
      obj
          .ToElapsedTimeSinceEpoch()
          .hashCode;
  @override
}