// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/LocalDateTime.cs
// 12c338e  on Nov 11, 2017

import 'package:quiver_hashcode/hashcode.dart';
import 'package:meta/meta.dart';
import 'package:time_machine/time_machine_fields.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_timezones.dart';
import 'utility/preconditions.dart';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

// TODO(feature): Calendar-neutral comparer.

/// A date and time in a particular calendar system. A LocalDateTime value does not represent an
/// instant on the global time line, because it has no associated time zone: "November 12th 2009 7pm, ISO calendar"
/// occurred at different instants for different people around the world.
/// 
/// <remarks>
/// <para>
/// This type defaults to using the ISO calendar system unless a different calendar system is
/// specified.
/// </para>
/// <para>
/// Values can freely be compared for equality: a value in a different calendar system is not equal to
/// a value in a different calendar system. However, ordering comparisons (either via the <see cref="CompareTo"/> method
/// or via operators) fail with <see cref="ArgumentException"/>; attempting to compare values in different calendars
/// almost always indicates a bug in the calling code.
/// </para>
/// </remarks>
/// <threadsafety>This type is an immutable value type. See the thread safety section of the user guide for more information.</threadsafety>
@immutable
class LocalDateTime implements Comparable<LocalDateTime> // : IEquatable<LocalDateTime>, IComparable<LocalDateTime>, IComparable, IFormattable, IXmlSerializable
    {
  @private final LocalDate date;
  @private final LocalTime time;


  /// Initializes a new instance of the <see cref="LocalDateTime"/> struct using the ISO
  /// calendar system.
  ///
  /// <param name="localInstant">The local instant.</param>
  /// <returns>The resulting date/time.</returns>
  @internal LocalDateTime.fromInstant(LocalInstant localInstant)
      :
        date = new LocalDate.fromDaysSinceEpoch(localInstant.DaysSinceEpoch),
        time = new LocalTime.fromNanoseconds(localInstant.NanosecondOfDay);


  /// Initializes a new instance of the <see cref="LocalDateTime"/> struct using the ISO calendar system.
  ///
  /// <param name="year">The year. This is the "absolute year",
  /// so a value of 0 means 1 BC, for example.</param>
  /// <param name="month">The month of year.</param>
  /// <param name="day">The day of month.</param>
  /// <param name="hour">The hour.</param>
  /// <param name="minute">The minute.</param>
  /// <returns>The resulting date/time.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The parameters do not form a valid date/time.</exception>
// todo: better names
  LocalDateTime.fromYMDHM(int year, int month, int day, int hour, int minute)
      : this(new LocalDate(year, month, day), new LocalTime(hour, minute));


  /// Initializes a new instance of the <see cref="LocalDateTime"/> struct.
  ///
  /// <param name="year">The year. This is the "absolute year", so, for
  /// the ISO calendar, a value of 0 means 1 BC, for example.</param>
  /// <param name="month">The month of year.</param>
  /// <param name="day">The day of month.</param>
  /// <param name="hour">The hour.</param>
  /// <param name="minute">The minute.</param>
  /// <param name="calendar">The calendar.</param>
  /// <returns>The resulting date/time.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The parameters do not form a valid date/time.</exception>
  LocalDateTime.fromYMDHMC(int year, int month, int day, int hour, int minute, CalendarSystem calendar)
      : this(new LocalDate.forCalendar(year, month, day, calendar), new LocalTime(hour, minute));


  /// Initializes a new instance of the <see cref="LocalDateTime"/> struct using the ISO calendar system.
  ///
  /// <param name="year">The year. This is the "absolute year",
  /// so a value of 0 means 1 BC, for example.</param>
  /// <param name="month">The month of year.</param>
  /// <param name="day">The day of month.</param>
  /// <param name="hour">The hour.</param>
  /// <param name="minute">The minute.</param>
  /// <param name="second">The second.</param>
  /// <returns>The resulting date/time.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The parameters do not form a valid date/time.</exception>
  LocalDateTime.fromYMDHMS(int year, int month, int day, int hour, int minute, int second)
      : this(new LocalDate(year, month, day), new LocalTime(hour, minute, second));


  /// Initializes a new instance of the <see cref="LocalDateTime"/> struct.
  ///
  /// <param name="year">The year. This is the "absolute year", so, for
  /// the ISO calendar, a value of 0 means 1 BC, for example.</param>
  /// <param name="month">The month of year.</param>
  /// <param name="day">The day of month.</param>
  /// <param name="hour">The hour.</param>
  /// <param name="minute">The minute.</param>
  /// <param name="second">The second.</param>
  /// <param name="calendar">The calendar.</param>
  /// <returns>The resulting date/time.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The parameters do not form a valid date/time.</exception>
  LocalDateTime.fromYMDHMSC(int year, int month, int day, int hour, int minute, int second, CalendarSystem calendar)
      : this(new LocalDate.forCalendar(year, month, day, calendar), new LocalTime(hour, minute, second));


  /// Initializes a new instance of the <see cref="LocalDateTime"/> struct using the ISO calendar system.
  ///
  /// <param name="year">The year. This is the "absolute year",
  /// so a value of 0 means 1 BC, for example.</param>
  /// <param name="month">The month of year.</param>
  /// <param name="day">The day of month.</param>
  /// <param name="hour">The hour.</param>
  /// <param name="minute">The minute.</param>
  /// <param name="second">The second.</param>
  /// <param name="millisecond">The millisecond.</param>
  /// <returns>The resulting date/time.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The parameters do not form a valid date/time.</exception>
  LocalDateTime.fromYMDHMSM(int year, int month, int day, int hour, int minute, int second, int millisecond)
      : this(new LocalDate(year, month, day), new LocalTime(hour, minute, second, millisecond));


  /// Initializes a new instance of the <see cref="LocalDateTime"/> struct.
  ///
  /// <param name="year">The year. This is the "absolute year", so, for
  /// the ISO calendar, a value of 0 means 1 BC, for example.</param>
  /// <param name="month">The month of year.</param>
  /// <param name="day">The day of month.</param>
  /// <param name="hour">The hour.</param>
  /// <param name="minute">The minute.</param>
  /// <param name="second">The second.</param>
  /// <param name="millisecond">The millisecond.</param>
  /// <param name="calendar">The calendar.</param>
  /// <returns>The resulting date/time.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The parameters do not form a valid date/time.</exception>
  LocalDateTime.fromYMDHMSMC(int year, int month, int day, int hour, int minute, int second, int millisecond, CalendarSystem calendar)
      : this(new LocalDate.forCalendar(year, month, day, calendar), new LocalTime(hour, minute, second, millisecond));

  @internal LocalDateTime(this.date, this.time);

  /// Gets the calendar system associated with this local date and time.
  /// <value>The calendar system associated with this local date and time.</value>
  CalendarSystem get Calendar => date.Calendar;

  /// Gets the year of this local date and time.
  /// <remarks>This returns the "absolute year", so, for the ISO calendar,
  /// a value of 0 means 1 BC, for example.</remarks>
  /// <value>The year of this local date and time.</value>
  int get Year => date.Year;

  /// Gets the year of this local date and time within its era.
  /// <value>The year of this local date and time within its era.</value>
  int get YearOfEra => date.YearOfEra;

  /// Gets the era of this local date and time.
  /// <value>The era of this local date and time.</value>
  Era get era => date.era;


  /// Gets the month of this local date and time within the year.
  ///
  /// <value>The month of this local date and time within the year.</value>
  int get Month => date.Month;


  /// Gets the day of this local date and time within the year.
  ///
  /// <value>The day of this local date and time within the year.</value>
  int get DayOfYear => date.DayOfYear;


  /// Gets the day of this local date and time within the month.
  ///
  /// <value>The day of this local date and time within the month.</value>
  int get Day => date.Day;


  /// Gets the week day of this local date and time expressed as an <see cref="NodaTime.IsoDayOfWeek"/> value.
  ///
  /// <value>The week day of this local date and time expressed as an <c>IsoDayOfWeek</c>.</value>
  IsoDayOfWeek get DayOfWeek => date.DayOfWeek;


  /// Gets the hour of day of this local date and time, in the range 0 to 23 inclusive.
  ///
  /// <value>The hour of day of this local date and time, in the range 0 to 23 inclusive.</value>
  int get Hour => time.Hour;


  /// Gets the hour of the half-day of this local date and time, in the range 1 to 12 inclusive.
  ///
  /// <value>The hour of the half-day of this local date and time, in the range 1 to 12 inclusive.</value>
  int get ClockHourOfHalfDay => time.ClockHourOfHalfDay;


  /// Gets the minute of this local date and time, in the range 0 to 59 inclusive.
  ///
  /// <value>The minute of this local date and time, in the range 0 to 59 inclusive.</value>
  int get Minute => time.Minute;


  /// Gets the second of this local date and time within the minute, in the range 0 to 59 inclusive.
  ///
  /// <value>The second of this local date and time within the minute, in the range 0 to 59 inclusive.</value>
  int get Second => time.Second;


  /// Gets the millisecond of this local date and time within the second, in the range 0 to 999 inclusive.
  ///
  /// <value>The millisecond of this local date and time within the second, in the range 0 to 999 inclusive.</value>
  int get Millisecond => time.Millisecond;


  /// Gets the tick of this local time within the second, in the range 0 to 9,999,999 inclusive.
  ///
  /// <value>The tick of this local time within the second, in the range 0 to 9,999,999 inclusive.</value>
  int get TickOfSecond => time.TickOfSecond;


  /// Gets the tick of this local date and time within the day, in the range 0 to 863,999,999,999 inclusive.
  ///
  /// <value>The tick of this local date and time within the day, in the range 0 to 863,999,999,999 inclusive.</value>
  int get TickOfDay => time.TickOfDay;


  /// Gets the nanosecond of this local time within the second, in the range 0 to 999,999,999 inclusive.
  ///
  /// <value>The nanosecond of this local time within the second, in the range 0 to 999,999,999 inclusive.</value>
  int get NanosecondOfSecond => time.NanosecondOfSecond;


  /// Gets the nanosecond of this local date and time within the day, in the range 0 to 86,399,999,999,999 inclusive.
  ///
  /// <value>The nanosecond of this local date and time within the day, in the range 0 to 86,399,999,999,999 inclusive.</value>
  int get NanosecondOfDay => time.NanosecondOfDay;


  /// Gets the time portion of this local date and time as a <see cref="LocalTime"/>.
  ///
  /// <value>The time portion of this local date and time as a <c>LocalTime</c>.</value>
  LocalTime get TimeOfDay => time;


  /// Gets the date portion of this local date and time as a <see cref="LocalDate"/> in the same calendar system as this value.
  ///
  /// <value>The date portion of this local date and time as a <c>LocalDate</c> in the same calendar system as this value.</value>
  LocalDate get Date => date;


  /// Constructs a <see cref="DateTime"/> from this value which has a <see cref="DateTime.Kind" />
  /// of <see cref="DateTimeKind.Unspecified"/>.
  ///
  /// <remarks>
  /// <para>
  /// <see cref="DateTimeKind.Unspecified"/> is slightly odd - it can be treated as UTC if you use <see cref="DateTime.ToLocalTime"/>
  /// or as system local time if you use <see cref="DateTime.ToUniversalTime"/>, but it's the only kind which allows
  /// you to construct a <see cref="DateTimeOffset"/> with an arbitrary offset, which makes it as close to
  /// the Noda Time non-system-specific "local" concept as exists in .NET.
  /// </para>
  /// <para>
  /// If the date and time is not on a tick boundary (the unit of granularity of DateTime) the value will be truncated
  /// towards the start of time.
  /// </para>
  /// </remarks>
  /// <exception cref="InvalidOperationException">The date/time is outside the range of <c>DateTime</c>.</exception>
  /// <returns>A <see cref="DateTime"/> value for the same date and time as this value.</returns>

  DateTime ToDateTimeUnspecified() {
//int ticks = TickArithmetic.BoundedDaysAndTickOfDayToTicks(date.DaysSinceEpoch, time.TickOfDay) + NodaConstants.BclTicksAtUnixEpoch;
//if (ticks < 0)
//{
//throw new StateError("LocalDateTime out of range of DateTime");
//}
// todo: on VM we should supply the microsecond
    return new DateTime(
        date.Year,
        date.Month,
        date.Day,
        time.Hour,
        time.Minute,
        time.Second,
        time.Millisecond);
  }


  @internal LocalInstant ToLocalInstant() => new LocalInstant.daysNanos(date.DaysSinceEpoch, time.NanosecondOfDay);


  /// Converts a <see cref="DateTime" /> of any kind to a LocalDateTime in the ISO calendar. This does not perform
  /// any time zone conversions, so a DateTime with a <see cref="DateTime.Kind"/> of <see cref="DateTimeKind.Utc"/>
  /// will still have the same day/hour/minute etc - it won't be converted into the local system time.
  ///
  /// <param name="dateTime">Value to convert into a Noda Time local date and time</param>
  /// <returns>A new <see cref="LocalDateTime"/> with the same values as the specified <c>DateTime</c>.</returns>
//static LocalDateTime FromDateTime(DateTime dateTime)
//{
//int tickOfDay;
//int days = dateTime.difference(new DateTime.fromMillisecondsSinceEpoch(0)).inDays; // TickArithmetic.NonNegativeTicksToDaysAndTickOfDay(dateTime.ticks, out tickOfDay) - NodaConstants.BclDaysAtUnixEpoch;
//return new LocalDateTime(new LocalDate.fromDaysSinceEpoch(days), new LocalTime.fromNanoseconds(/*unchecked*/(tickOfDay * TimeConstants.nanosecondsPerTick)));
//}


  /// Converts a <see cref="DateTime" /> of any kind to a LocalDateTime in the specified or ISO calendar. This does not perform
  /// any time zone conversions, so a DateTime with a <see cref="DateTime.Kind"/> of <see cref="DateTimeKind.Utc"/>
  /// will still have the same day/hour/minute etc - it won't be converted into the local system time.
  ///
  /// <param name="dateTime">Value to convert into a Noda Time local date and time</param>
  /// <param name="calendar">The calendar system to convert into</param>
  /// <returns>A new <see cref="LocalDateTime"/> with the same values as the specified <c>DateTime</c>.</returns>
  static LocalDateTime FromDateTime(DateTime dateTime, [CalendarSystem calendar = null]) {
    // return new LocalDateTime(LocalDate.FromDateTime(dateTime), new LocalTime(dateTime.hour, dateTime.minute, dateTime.second, dateTime.millisecond));

    var ms = dateTime.millisecondsSinceEpoch;
    var days = ms ~/ TimeConstants.millisecondsPerDay; // - 1;
    ms -= days * TimeConstants.millisecondsPerDay;
    // print('days: $days; ms: $ms');

    if (calendar == null) return new LocalDateTime(
        new LocalDate.fromDaysSinceEpoch(days), new LocalTime.fromNanoseconds(ms * TimeConstants.nanosecondsPerMillisecond));
    return new LocalDateTime(new LocalDate.fromDaysSinceEpoch_forCalendar(days, calendar),
        new LocalTime.fromNanoseconds(ms * TimeConstants.nanosecondsPerMillisecond));
  }

// #region Implementation of IEquatable<LocalDateTime>


  /// Indicates whether the current object is equal to another object of the same type.
  ///
  /// <param name="other">An object to compare with this object.</param>
  /// <returns>
  /// true if the current object is equal to the <paramref name="other"/> parameter; otherwise, false.
  /// </returns>
  bool Equals(LocalDateTime other) => date == other.date && time == other.time;

// #endregion

// #region Operators


  /// Implements the operator == (equality).
  ///
  /// <param name="left">The left hand side of the operator.</param>
  /// <param name="right">The right hand side of the operator.</param>
  /// <returns><c>true</c> if values are equal to each other, otherwise <c>false</c>.</returns>
  bool operator ==(dynamic right) => right is LocalDateTime && Equals(right);


  /// Compares two LocalDateTime values to see if the left one is strictly earlier than the right
  /// one.
  ///
  /// <remarks>
  /// Only values with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  /// </remarks>
  /// <param name="lhs">First operand of the comparison</param>
  /// <param name="rhs">Second operand of the comparison</param>
  /// <exception cref="ArgumentException">The calendar system of <paramref name="rhs"/> is not the same
  /// as the calendar of <paramref name="lhs"/>.</exception>
  /// <returns>true if the <paramref name="lhs"/> is strictly earlier than <paramref name="rhs"/>, false otherwise.</returns>
  bool operator <(LocalDateTime rhs) {
    if (rhs == null) return false;
    Preconditions.checkArgument(Calendar == rhs.Calendar, 'rhs', "Only values in the same calendar can be compared");
    return compareTo(rhs) < 0;
  }


  /// Compares two LocalDateTime values to see if the left one is earlier than or equal to the right
  /// one.
  ///
  /// <remarks>
  /// Only values with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  /// </remarks>
  /// <param name="lhs">First operand of the comparison</param>
  /// <param name="rhs">Second operand of the comparison</param>
  /// <exception cref="ArgumentException">The calendar system of <paramref name="rhs"/> is not the same
  /// as the calendar of <paramref name="lhs"/>.</exception>
  /// <returns>true if the <paramref name="lhs"/> is earlier than or equal to <paramref name="rhs"/>, false otherwise.</returns>
  bool operator <=(LocalDateTime rhs) {
    if (rhs == null) return false;
    Preconditions.checkArgument(Calendar == rhs.Calendar, 'rhs', "Only values in the same calendar can be compared");
    return compareTo(rhs) <= 0;
  }


  /// Compares two LocalDateTime values to see if the left one is strictly later than the right
  /// one.
  ///
  /// <remarks>
  /// Only values with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  /// </remarks>
  /// <param name="lhs">First operand of the comparison</param>
  /// <param name="rhs">Second operand of the comparison</param>
  /// <exception cref="ArgumentException">The calendar system of <paramref name="rhs"/> is not the same
  /// as the calendar of <paramref name="lhs"/>.</exception>
  /// <returns>true if the <paramref name="lhs"/> is strictly later than <paramref name="rhs"/>, false otherwise.</returns>
  bool operator >(LocalDateTime rhs) {
    if (rhs == null) return true;
    Preconditions.checkArgument(Calendar == rhs.Calendar, 'rhs', "Only values in the same calendar can be compared");
    return compareTo(rhs) > 0;
  }


  /// Compares two LocalDateTime values to see if the left one is later than or equal to the right
  /// one.
  ///
  /// <remarks>
  /// Only values with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  /// </remarks>
  /// <param name="lhs">First operand of the comparison</param>
  /// <param name="rhs">Second operand of the comparison</param>
  /// <exception cref="ArgumentException">The calendar system of <paramref name="rhs"/> is not the same
  /// as the calendar of <paramref name="lhs"/>.</exception>
  /// <returns>true if the <paramref name="lhs"/> is later than or equal to <paramref name="rhs"/>, false otherwise.</returns>
  bool operator >=(LocalDateTime rhs) {
    if (rhs == null) return true;
    Preconditions.checkArgument(Calendar == rhs.Calendar, 'rhs', "Only values in the same calendar can be compared");
    return compareTo(rhs) >= 0;
  }


  /// Indicates whether this date/time is earlier, later or the same as another one.
  ///
  /// <remarks>
  /// Only date/time values within the same calendar systems can be compared with this method. Attempting to compare
  /// values within different calendars will fail with an <see cref="ArgumentException"/>. Ideally, comparisons
  /// is almost always preferable to continuing.
  /// </remarks>
  /// <param name="other">The other local date/time to compare with this value.</param>
  /// <exception cref="ArgumentException">The calendar system of <paramref name="other"/> is not the
  /// same as the calendar system of this value.</exception>
  /// <returns>A value less than zero if this date/time is earlier than <paramref name="other"/>;
  /// zero if this date/time is the same as <paramref name="other"/>; a value greater than zero if this date/time is
  /// later than <paramref name="other"/>.</returns>
  int compareTo(LocalDateTime other) {
    // This will check calendars...
    if (other == null) return 1;
    int dateComparison = date.compareTo(other.date);
    if (dateComparison != 0) {
      return dateComparison;
    }
    return time.compareTo(other.time);
  }


///// Implementation of <see cref="IComparable.CompareTo"/> to compare two LocalDateTimes.
/////
///// <remarks>
///// This uses explicit interface implementation to avoid it being called accidentally. The generic implementation should usually be preferred.
///// </remarks>
///// <exception cref="ArgumentException"><paramref name="obj"/> is non-null but does not refer to an instance of <see cref="LocalDateTime"/>,
///// or refers to a adate/time in a different calendar system.</exception>
///// <param name="obj">The object to compare this value with.</param>
///// <returns>The result of comparing this LocalDateTime with another one; see <see cref="CompareTo(NodaTime.LocalDateTime)"/> for general details.
///// If <paramref name="obj"/> is null, this method returns a value greater than 0.
///// </returns>
//int IComparable.CompareTo(object obj)
//{
//if (obj == null)
//{
//return 1;
//}
//Preconditions.checkArgument(obj is LocalDateTime, 'obj', "Object must be of type NodaTime.LocalDateTime.");
//return CompareTo(obj);
//}


  /// Adds a period to a local date/time. Fields are added in the order provided by the period.
  /// This is a convenience operator over the <see cref="Plus"/> method.
  ///
  /// <param name="localDateTime">Initial local date and time</param>
  /// <param name="period">Period to add</param>
  /// <returns>The resulting local date and time</returns>
  LocalDateTime operator +(Period period) => Plus(period);


  /// Add the specified period to the date and time. Friendly alternative to <c>operator+()</c>.
  ///
  /// <param name="localDateTime">Initial local date and time</param>
  /// <param name="period">Period to add</param>
  /// <returns>The resulting local date and time</returns>
  static LocalDateTime Add(LocalDateTime localDateTime, Period period) => localDateTime.Plus(period);


  /// Adds a period to this local date/time. Fields are added in the order provided by the period.
  ///
  /// <param name="period">Period to add</param>
  /// <returns>The resulting local date and time</returns>

  LocalDateTime Plus(Period period) {
    Preconditions.checkNotNull(period, 'period');
    return period.AddDateTimeTo(date, time, 1);
  }


  /// Subtracts a period from a local date/time. Fields are subtracted in the order provided by the period.
  /// This is a convenience operator over the <see cref="Minus(Period)"/> method.
  ///
  /// <param name="localDateTime">Initial local date and time</param>
  /// <param name="period">Period to subtract</param>
  /// <returns>The resulting local date and time</returns>
  /// Subtracts one date/time from another, returning the result as a <see cref="Period"/>.
  ///
  /// <remarks>
  /// This is simply a convenience operator for calling <see cref="Period.Between(NodaTime.LocalDateTime,NodaTime.LocalDateTime)"/>.
  /// The calendar systems of the two date/times must be the same.
  /// </remarks>
  /// <param name="lhs">The date/time to subtract from</param>
  /// <param name="rhs">The date/time to subtract</param>
  /// <returns>The result of subtracting one date/time from another.</returns>
// LocalDateTime operator -(Period period) => MinusPeriod(period);
// Period operator -(LocalDateTime rhs) => Period.Between(rhs, this);
  // todo: still hate dynamic dispatch
  dynamic operator -(dynamic value) => value is Period ? MinusPeriod(value) : value is LocalDateTime ? MinusLocalDateTime(value) : throw new TypeError();

  /// Subtracts the specified period from the date and time. Friendly alternative to <c>operator-()</c>.
  ///
  /// <param name="localDateTime">Initial local date and time</param>
  /// <param name="period">Period to subtract</param>
  /// <returns>The resulting local date and time</returns>
  static LocalDateTime SubtractPeriod(LocalDateTime localDateTime, Period period) => localDateTime.MinusPeriod(period);


  /// Subtracts a period from a local date/time. Fields are subtracted in the order provided by the period.
  ///
  /// <param name="period">Period to subtract</param>
  /// <returns>The resulting local date and time</returns>

  LocalDateTime MinusPeriod(Period period) {
    Preconditions.checkNotNull(period, 'period');
    return period.AddDateTimeTo(date, time, -1);
  }


  /// Subtracts one date/time from another, returning the result as a <see cref="Period"/>.
  ///
  /// <remarks>
  /// This is simply a convenience method for calling <see cref="Period.Between(NodaTime.LocalDateTime,NodaTime.LocalDateTime)"/>.
  /// The calendar systems of the two date/times must be the same.
  /// </remarks>
  /// <param name="lhs">The date/time to subtract from</param>
  /// <param name="rhs">The date/time to subtract</param>
  /// <returns>The result of subtracting one date/time from another.</returns>
  static Period SubtractLocalDateTime(LocalDateTime lhs, LocalDateTime rhs) => lhs.MinusLocalDateTime(rhs);


  /// Subtracts the specified date/time from this date/time, returning the result as a <see cref="Period"/>.
  /// Fluent alternative to <c>operator-()</c>.
  ///
  /// <remarks>The specified date/time must be in the same calendar system as this.</remarks>
  /// <param name="localDateTime">The date/time to subtract from this</param>
  /// <returns>The difference between the specified date/time and this one</returns>


  Period MinusLocalDateTime(LocalDateTime localDateTime) => Period.Between(localDateTime, this);

// #endregion

// #region object overrides


///// Determines whether the specified <see cref="System.Object"/> is equal to this instance.
/////
///// <param name="obj">The <see cref="System.Object"/> to compare with this instance.</param>
///// <returns>
///// <c>true</c> if the specified <see cref="System.Object"/> is equal to this instance;
///// otherwise, <c>false</c>.
///// </returns>
//@override bool Equals(object obj) => obj is LocalDateTime && Equals(obj);


  /// Returns a hash code for this instance.
  ///
  /// <returns>
  /// A hash code for this instance, suitable for use in hashing algorithms and data
  /// structures like a hash table.
  /// </returns>
  @override int get hashCode => hash3(date, time, Calendar); // HashCodeHelper.Hash(date, time, Calendar);
//#endregion


  /// Returns this date/time, with the given date adjuster applied to it, maintaing the existing time of day.
  ///
  /// <remarks>
  /// If the adjuster attempts to construct an
  /// invalid date (such as by trying to set a day-of-month of 30 in February), any exception thrown by
  /// that construction attempt will be propagated through this method.
  /// </remarks>
  /// <param name="adjuster">The adjuster to apply.</param>
  /// <returns>The adjusted date/time.</returns>

  LocalDateTime WithDate(LocalDate Function(LocalDate) adjuster) =>
      date.With(adjuster).At(time);


  /// Returns this date/time, with the given time adjuster applied to it, maintaining the existing date.
  ///
  /// <remarks>
  /// If the adjuster attempts to construct an invalid time, any exception thrown by
  /// that construction attempt will be propagated through this method.
  /// </remarks>
  /// <param name="adjuster">The adjuster to apply.</param>
  /// <returns>The adjusted date/time.</returns>

  LocalDateTime WithTime(LocalTime Function(LocalTime) adjuster) => date.At(time.With(adjuster));


  /// Creates a new LocalDateTime representing the same physical date and time, but in a different calendar.
  /// The returned LocalDateTime is likely to have different date field values to this one.
  /// For example, January 1st 1970 in the Gregorian calendar was December 19th 1969 in the Julian calendar.
  ///
  /// <param name="calendar">The calendar system to convert this local date to.</param>
  /// <returns>The converted LocalDateTime.</returns>

  LocalDateTime WithCalendar(CalendarSystem calendar) {
    Preconditions.checkNotNull(calendar, 'calendar');
    return new LocalDateTime(date.WithCalendar(calendar), time);
  }


  /// Returns a new LocalDateTime representing the current value with the given number of years added.
  ///
  /// <remarks>
  /// If the resulting date is invalid, lower fields (typically the day of month) are reduced to find a valid value.
  /// For example, adding one year to February 29th 2012 will return February 28th 2013; subtracting one year from
  /// February 29th 2012 will return February 28th 2011.
  /// </remarks>
  /// <param name="years">The number of years to add</param>
  /// <returns>The current value plus the given number of years.</returns>

  LocalDateTime PlusYears(int years) => new LocalDateTime(date.PlusYears(years), time);


  /// Returns a new LocalDateTime representing the current value with the given number of months added.
  ///
  /// <remarks>
  /// <para>
  /// This method does not try to maintain the year of the current value, so adding four months to a value in
  /// October will result in a value in the following February.
  /// </para>
  /// <para>
  /// If the resulting date is invalid, the day of month is reduced to find a valid value.
  /// For example, adding one month to January 30th 2011 will return February 28th 2011; subtracting one month from
  /// March 30th 2011 will return February 28th 2011.
  /// </para>
  /// </remarks>
  /// <param name="months">The number of months to add</param>
  /// <returns>The current value plus the given number of months.</returns>

  LocalDateTime PlusMonths(int months) => new LocalDateTime(date.PlusMonths(months), time);


  /// Returns a new LocalDateTime representing the current value with the given number of days added.
  ///
  /// <remarks>
  /// <para>
  /// This method does not try to maintain the month or year of the current value, so adding 3 days to a value on January 30th
  /// will result in a value on February 2nd.
  /// </para>
  /// </remarks>
  /// <param name="days">The number of days to add</param>
  /// <returns>The current value plus the given number of days.</returns>

  LocalDateTime PlusDays(int days) => new LocalDateTime(date.PlusDays(days), time);


  /// Returns a new LocalDateTime representing the current value with the given number of weeks added.
  ///
  /// <param name="weeks">The number of weeks to add</param>
  /// <returns>The current value plus the given number of weeks.</returns>

  LocalDateTime PlusWeeks(int weeks) => new LocalDateTime(date.PlusWeeks(weeks), time);


  /// Returns a new LocalDateTime representing the current value with the given number of hours added.
  ///
  /// <param name="hours">The number of hours to add</param>
  /// <returns>The current value plus the given number of hours.</returns>

  LocalDateTime PlusHours(int hours) => TimePeriodField.Hours.AddDateTime(this, hours);


  /// Returns a new LocalDateTime representing the current value with the given number of minutes added.
  ///
  /// <param name="minutes">The number of minutes to add</param>
  /// <returns>The current value plus the given number of minutes.</returns>

  LocalDateTime PlusMinutes(int minutes) => TimePeriodField.Minutes.AddDateTime(this, minutes);


  /// Returns a new LocalDateTime representing the current value with the given number of seconds added.
  ///
  /// <param name="seconds">The number of seconds to add</param>
  /// <returns>The current value plus the given number of seconds.</returns>

  LocalDateTime PlusSeconds(int seconds) => TimePeriodField.Seconds.AddDateTime(this, seconds);


  /// Returns a new LocalDateTime representing the current value with the given number of milliseconds added.
  ///
  /// <param name="milliseconds">The number of milliseconds to add</param>
  /// <returns>The current value plus the given number of milliseconds.</returns>

  LocalDateTime PlusMilliseconds(int milliseconds) =>
      TimePeriodField.Milliseconds.AddDateTime(this, milliseconds);


  /// Returns a new LocalDateTime representing the current value with the given number of ticks added.
  ///
  /// <param name="ticks">The number of ticks to add</param>
  /// <returns>The current value plus the given number of ticks.</returns>

  LocalDateTime PlusTicks(int ticks) => TimePeriodField.Ticks.AddDateTime(this, ticks);


  /// Returns a new LocalDateTime representing the current value with the given number of nanoseconds added.
  ///
  /// <param name="nanoseconds">The number of nanoseconds to add</param>
  /// <returns>The current value plus the given number of nanoseconds.</returns>

  LocalDateTime PlusNanoseconds(int nanoseconds) => TimePeriodField.Nanoseconds.AddDateTime(this, nanoseconds);


  /// Returns the next <see cref="LocalDateTime" /> falling on the specified <see cref="IsoDayOfWeek"/>,
  /// at the same time of day as this value.
  /// This is a strict "next" - if this value on already falls on the target
  /// day of the week, the returned value will be a week later.
  ///
  /// <param name="targetDayOfWeek">The ISO day of the week to return the next date of.</param>
  /// <returns>The next <see cref="LocalDateTime"/> falling on the specified day of the week.</returns>
  /// <exception cref="InvalidOperationException">The underlying calendar doesn't use ISO days of the week.</exception>
  /// <exception cref="ArgumentOutOfRangeException"><paramref name="targetDayOfWeek"/> is not a valid day of the
  /// week (Monday to Sunday).</exception>

  LocalDateTime Next(IsoDayOfWeek targetDayOfWeek) => new LocalDateTime(date.Next(targetDayOfWeek), time);


  /// Returns the previous <see cref="LocalDateTime" /> falling on the specified <see cref="IsoDayOfWeek"/>,
  /// at the same time of day as this value.
  /// This is a strict "previous" - if this value on already falls on the target
  /// day of the week, the returned value will be a week earlier.
  ///
  /// <param name="targetDayOfWeek">The ISO day of the week to return the previous date of.</param>
  /// <returns>The previous <see cref="LocalDateTime"/> falling on the specified day of the week.</returns>
  /// <exception cref="InvalidOperationException">The underlying calendar doesn't use ISO days of the week.</exception>
  /// <exception cref="ArgumentOutOfRangeException"><paramref name="targetDayOfWeek"/> is not a valid day of the
  /// week (Monday to Sunday).</exception>

  LocalDateTime Previous(IsoDayOfWeek targetDayOfWeek) => new LocalDateTime(date.Previous(targetDayOfWeek), time);


  /// Returns an <see cref="OffsetDateTime"/> for this local date/time with the given offset.
  ///
  /// <remarks>This method is purely a convenient alternative to calling the <see cref="OffsetDateTime"/> constructor directly.</remarks>
  /// <param name="offset">The offset to apply.</param>
  /// <returns>The result of this local date/time offset by the given amount.</returns>

  OffsetDateTime WithOffset(Offset offset) => new OffsetDateTime.lessTrust(date.yearMonthDayCalendar, time, offset);


  /// Returns the mapping of this local date/time within <see cref="DateTimeZone.Utc"/>.
  ///
  /// <remarks>As UTC is a fixed time zone, there is no chance that this local date/time is ambiguous or skipped.</remarks>
  /// <returns>The result of mapping this local date/time in UTC.</returns>

  ZonedDateTime InUtc() =>
// Use the @internal constructors to avoid validation. We know it will be fine.
  new ZonedDateTime.trusted(new OffsetDateTime.fullTrust(date.yearMonthDayCalendar, time.NanosecondOfDay, Offset.zero), DateTimeZone.Utc);


  /// Returns the mapping of this local date/time within the given <see cref="DateTimeZone" />,
  /// with "strict" rules applied such that an exception is thrown if either the mapping is
  /// ambiguous or the time is skipped.
  ///
  /// <remarks>
  /// See <see cref="InZoneLeniently"/> and <see cref="InZone"/> for alternative ways to map a local time to a
  /// specific instant.
  /// This is solely a convenience method for calling <see cref="DateTimeZone.AtStrictly" />.
  /// </remarks>
  /// <param name="zone">The time zone in which to map this local date/time.</param>
  /// <exception cref="SkippedTimeException">This local date/time is skipped in the given time zone.</exception>
  /// <exception cref="AmbiguousTimeException">This local date/time is ambiguous in the given time zone.</exception>
  /// <returns>The result of mapping this local date/time in the given time zone.</returns>

  ZonedDateTime InZoneStrictly(DateTimeZone zone) {
    Preconditions.checkNotNull(zone, 'zone');
    return zone.AtStrictly(this);
  }


  /// Returns the mapping of this local date/time within the given <see cref="DateTimeZone" />,
  /// with "lenient" rules applied such that ambiguous values map to the earlier of the alternatives, and
  /// "skipped" values are shifted forward by the duration of the "gap".
  ///
  /// <remarks>
  /// See <see cref="InZoneStrictly"/> and <see cref="InZone"/> for alternative ways to map a local time to a
  /// specific instant.
  /// This is solely a convenience method for calling <see cref="DateTimeZone.AtLeniently" />.
  /// <para>Note: The behavior of this method was changed in version 2.0 to fit the most commonly seen real-world
  /// usage pattern.  Previous versions returned the later instance of ambiguous values, and returned the start of
  /// the zone interval after the gap for skipped value.  The previous functionality can still be used if desired,
  /// by using <see cref="InZone(DateTimeZone, ZoneLocalMappingResolver)"/> and passing a resolver that combines the
  /// <see cref="Resolvers.ReturnLater"/> and <see cref="Resolvers.ReturnStartOfIntervalAfter"/> resolvers.</para>
  /// </remarks>
  /// <param name="zone">The time zone in which to map this local date/time.</param>
  /// <returns>The result of mapping this local date/time in the given time zone.</returns>

  ZonedDateTime InZoneLeniently(DateTimeZone zone) {
    Preconditions.checkNotNull(zone, 'zone');
    return zone.AtLeniently(this);
  }


  /// Resolves this local date and time into a <see cref="ZonedDateTime"/> in the given time zone, following
  /// the given <see cref="ZoneLocalMappingResolver"/> to handle ambiguity and skipped times.
  ///
  /// <remarks>
  /// See <see cref="InZoneStrictly"/> and <see cref="InZoneLeniently"/> for alternative ways to map a local time
  /// to a specific instant.
  /// This is a convenience method for calling <see cref="DateTimeZone.ResolveLocal(LocalDateTime, ZoneLocalMappingResolver)"/>.
  /// </remarks>
  /// <param name="zone">The time zone to map this local date and time into</param>
  /// <param name="resolver">The resolver to apply to the mapping.</param>
  /// <returns>The result of resolving the mapping.</returns>

  ZonedDateTime InZone(DateTimeZone zone, ZoneLocalMappingResolver resolver) {
    Preconditions.checkNotNull(zone, 'zone');
    Preconditions.checkNotNull(resolver, 'resolver');
    return zone.ResolveLocal(this, resolver);
  }


  /// Returns the later date/time of the given two.
  ///
  /// <param name="x">The first date/time to compare.</param>
  /// <param name="y">The second date/time to compare.</param>
  /// <exception cref="ArgumentException">The two date/times have different calendar systems.</exception>
  /// <returns>The later date/time of <paramref name="x"/> or <paramref name="y"/>.</returns>
  static LocalDateTime Max(LocalDateTime x, LocalDateTime y) {
    Preconditions.checkArgument(x.Calendar == y.Calendar, 'y', "Only values with the same calendar system can be compared");
    return x > y ? x : y;
  }


  /// Returns the earlier date/time of the given two.
  ///
  /// <param name="x">The first date/time to compare.</param>
  /// <param name="y">The second date/time to compare.</param>
  /// <exception cref="ArgumentException">The two date/times have different calendar systems.</exception>
  /// <returns>The earlier date/time of <paramref name="x"/> or <paramref name="y"/>.</returns>
  static LocalDateTime Min(LocalDateTime x, LocalDateTime y) {
    Preconditions.checkArgument(x.Calendar == y.Calendar, 'y', "Only values with the same calendar system can be compared");
    return x < y ? x : y;
  }

// #region Formatting


  /// Returns a <see cref="System.String" /> that represents this instance.
  ///
  /// <returns>
  /// The value of the current instance in the default format pattern ("G"), using the current thread's
  /// culture to obtain a format provider.
  /// </returns>
  // @override String toString() => TextShim.toStringLocalDateTime(this);
  @override String toString([String patternText = null, /*IFormatProvider*/ dynamic formatProvider = null]) =>
      LocalDateTimePattern.BclSupport.Format(this, patternText, formatProvider ?? CultureInfo.currentCulture);



/// Formats the value of the current instance using the specified pattern.
/// 
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
//String ToString(String patternText, IFormatProvider formatProvider) =>
//LocalDateTimePattern.BclSupport.Format(this, patternText, formatProvider);
//#endregion Formatting

}