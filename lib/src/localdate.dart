// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/LocalDate.cs
// 785b680  on Nov 8, 2017

import 'package:meta/meta.dart';

import 'utility/preconditions.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_fields.dart';
import 'package:time_machine/time_machine_utilities.dart';

class LocalDate implements Comparable<LocalDate> {
  YearMonthDayCalendar _yearMonthDayCalendar;

  /// The maximum (latest) date representable in the ISO calendar system.
  static LocalDate get MaxIsoValue => new LocalDate.trusted(new YearMonthDayCalendar(GregorianYearMonthDayCalculator.maxGregorianYear, 12, 31, CalendarOrdinal.Iso));

  /// <summary>
  /// The minimum (earliest) date representable in the ISO calendar system.
  /// </summary>
  static LocalDate get MinIsoValue => new LocalDate.trusted(new YearMonthDayCalendar(GregorianYearMonthDayCalculator.minGregorianYear, 1, 1, CalendarOrdinal.Iso));

  /// Constructs an instance from values which are assumed to already have been validated.
  // todo: this one seems like it might be trouble (is this truly protected from being used as an external API?)
  @internal LocalDate.trusted(YearMonthDayCalendar yearMonthDayCalendar)
  {
    this._yearMonthDayCalendar = yearMonthDayCalendar;
  }

  /// <summary>
  /// Constructs an instance from the number of days since the unix epoch, in the ISO
  /// calendar system.
  /// </summary>
  @internal LocalDate.fromDaysSinceEpoch(int daysSinceEpoch)
  {
  Preconditions.debugCheckArgumentRange('daysSinceEpoch', daysSinceEpoch, CalendarSystem.Iso.minDays, CalendarSystem.Iso.maxDays);
  this._yearMonthDayCalendar = GregorianYearMonthDayCalculator.getGregorianYearMonthDayCalendarFromDaysSinceEpoch(daysSinceEpoch);
  }

  /// <summary>
  /// Constructs an instance from the number of days since the unix epoch, and a calendar
  /// system. The calendar system is assumed to be non-null, but the days since the epoch are
  /// validated.
  /// </summary>
  @internal LocalDate.fromDaysSinceEpoch_forCalendar(int daysSinceEpoch, CalendarSystem calendar)
  {
  Preconditions.debugCheckNotNull(calendar, 'calendar');
  this._yearMonthDayCalendar = calendar.GetYearMonthDayCalendarFromDaysSinceEpoch(daysSinceEpoch);
  }

  /// <summary>
  /// Constructs an instance for the given year, month and day in the ISO calendar.
  /// </summary>
  /// <param name="year">The year. This is the "absolute year", so a value of 0 means 1 BC, for example.</param>
  /// <param name="month">The month of year.</param>
  /// <param name="day">The day of month.</param>
  /// <returns>The resulting date.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The parameters do not form a valid date.</exception>
  LocalDate(int year, int month, int day)
  {
    GregorianYearMonthDayCalculator.validateGregorianYearMonthDay(year, month, day);
    _yearMonthDayCalendar = new YearMonthDayCalendar(year, month, day, CalendarOrdinal.Iso);
  }

  /// <summary>
  /// Constructs an instance for the given year, month and day in the specified calendar.
  /// </summary>
  /// <param name="year">The year. This is the "absolute year", so, for
  /// the ISO calendar, a value of 0 means 1 BC, for example.</param>
  /// <param name="month">The month of year.</param>
  /// <param name="day">The day of month.</param>
  /// <param name="calendar">Calendar system in which to create the date.</param>
  /// <returns>The resulting date.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The parameters do not form a valid date.</exception>
  LocalDate.forCalendar(int year, int month, int day, CalendarSystem calendar)
  {
  Preconditions.checkNotNull(calendar, 'calendar');
  calendar.ValidateYearMonthDay(year, month, day);
  _yearMonthDayCalendar = new YearMonthDayCalendar(year, month, day, calendar.ordinal);
  }

  /// <summary>
  /// Constructs an instance for the given era, year of era, month and day in the ISO calendar.
  /// </summary>
  /// <param name="era">The era within which to create a date. Must be a valid era within the ISO calendar.</param>
  /// <param name="yearOfEra">The year of era.</param>
  /// <param name="month">The month of year.</param>
  /// <param name="day">The day of month.</param>
  /// <returns>The resulting date.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The parameters do not form a valid date.</exception>
  LocalDate.forIsoEra(Era era, int yearOfEra, int month, int day)
      : this.forEra(era, yearOfEra, month, day, CalendarSystem.Iso);

  /// <summary>
  /// Constructs an instance for the given era, year of era, month and day in the specified calendar.
  /// </summary>
  /// <param name="era">The era within which to create a date. Must be a valid era within the specified calendar.</param>
  /// <param name="yearOfEra">The year of era.</param>
  /// <param name="month">The month of year.</param>
  /// <param name="day">The day of month.</param>
  /// <param name="calendar">Calendar system in which to create the date.</param>
  /// <returns>The resulting date.</returns>
  /// <exception cref="ArgumentOutOfRangeException">The parameters do not form a valid date.</exception>
  LocalDate.forEra(Era era, int yearOfEra, int month, int day, CalendarSystem calendar)
      : this.forCalendar(Preconditions.checkNotNull(calendar, 'calendar').GetAbsoluteYear(yearOfEra, era), month, day, calendar);

  /// <summary>Gets the calendar system associated with this local date.</summary>
  /// <value>The calendar system associated with this local date.</value>
  CalendarSystem get Calendar => CalendarSystem.ForOrdinal(_yearMonthDayCalendar.calendarOrdinal);

  /// <summary>Gets the year of this local date.</summary>
  /// <remarks>This returns the "absolute year", so, for the ISO calendar,
  /// a value of 0 means 1 BC, for example.</remarks>
  /// <value>The year of this local date.</value>
  int get Year => _yearMonthDayCalendar.year;

  /// <summary>Gets the month of this local date within the year.</summary>
  /// <value>The month of this local date within the year.</value>
  int get Month => _yearMonthDayCalendar.month;

  /// <summary>Gets the day of this local date within the month.</summary>
  /// <value>The day of this local date within the month.</value>
  int get Day => _yearMonthDayCalendar.day;

  /// <summary>Gets the number of days since the Unix epoch for this date.</summary>
  /// <value>The number of days since the Unix epoch for this date.</value>
  @internal int get DaysSinceEpoch => Calendar.GetDaysSinceEpoch(_yearMonthDayCalendar.toYearMonthDay());

  /// <summary>
  /// Gets the week day of this local date expressed as an <see cref="NodaTime.IsoDayOfWeek"/> value.
  /// </summary>
  /// <value>The week day of this local date expressed as an <c>IsoDayOfWeek</c>.</value>
  IsoDayOfWeek get DayOfWeek => Calendar.GetDayOfWeek(_yearMonthDayCalendar.toYearMonthDay());

  /// <summary>Gets the year of this local date within the era.</summary>
  /// <value>The year of this local date within the era.</value>
  int get YearOfEra => Calendar.GetYearOfEra(_yearMonthDayCalendar.year);

  /// <summary>Gets the era of this local date.</summary>
  /// <value>The era of this local date.</value>
  Era get era => Calendar.GetEra(_yearMonthDayCalendar.year);

  /// <summary>Gets the day of this local date within the year.</summary>
  /// <value>The day of this local date within the year.</value>
  int get DayOfYear => Calendar.GetDayOfYear(_yearMonthDayCalendar.toYearMonthDay());

  @internal YearMonthDay get yearMonthDay => _yearMonthDayCalendar.toYearMonthDay();

  @internal YearMonthDayCalendar get yearMonthDayCalendar => _yearMonthDayCalendar;

  /// <summary>
  /// Gets a <see cref="LocalDateTime" /> at midnight on the date represented by this local date.
  /// </summary>
  /// <returns>The <see cref="LocalDateTime" /> representing midnight on this local date, in the same calendar
  /// system.</returns>
  // todo: this should probably be a method? Check style guide.
  LocalDateTime get AtMidnight => new LocalDateTime(this, LocalTime.Midnight);

  /// <summary>
  /// Constructs a <see cref="DateTime"/> from this value which has a <see cref="DateTime.Kind" />
  /// of <see cref="DateTimeKind.Unspecified"/>. The result is midnight on the day represented
  /// by this value.
  /// </summary>
  /// <remarks>
  /// <see cref="DateTimeKind.Unspecified"/> is slightly odd - it can be treated as UTC if you use <see cref="DateTime.ToLocalTime"/>
  /// or as system local time if you use <see cref="DateTime.ToUniversalTime"/>, but it's the only kind which allows
  /// you to construct a <see cref="DateTimeOffset"/> with an arbitrary offset, which makes it as close to
  /// the Noda Time non-system-specific "local" concept as exists in .NET.
  /// </remarks>
  /// <returns>A <see cref="DateTime"/> value for the same date and time as this value.</returns>
  DateTime toDateTimeUnspecified() =>
      new DateTime(Year, Month, Day);
      // new DateTime.fromMicrosecondsSinceEpoch(DaysSinceEpoch * TimeConstants.microsecondsPerDay);
              // + TimeConstants.BclTicksAtUnixEpoch ~/ TimeConstants.ticksPerMicrosecond); //, DateTimeKind.Unspecified);

  // Helper method used by both FromDateTime overloads.
  // todo: private
  static int NonNegativeMicrosecondsToDays(int microseconds) => microseconds ~/ TimeConstants.microsecondsPerDay;
      // ((ticks >> 14) ~/ 52734375);

  /// <summary>
  /// Converts a <see cref="DateTime" /> of any kind to a LocalDate in the ISO calendar, ignoring the time of day.
  /// This does not perform any time zone conversions, so a DateTime with a <see cref="DateTime.Kind"/> of
  /// <see cref="DateTimeKind.Utc"/> will still represent the same year/month/day - it won't be converted into the local system time.
  /// </summary>
  /// <param name="dateTime">Value to convert into a Noda Time local date</param>
  /// <returns>A new <see cref="LocalDate"/> with the same values as the specified <c>DateTime</c>.</returns>
  static LocalDate FromDateTime(DateTime dateTime)
  {
    // todo: we might want to make this so it's microseconds on VM and milliseconds on JS -- but I don't know how .. yet
    int days = NonNegativeMicrosecondsToDays(dateTime.microsecondsSinceEpoch);
    return new LocalDate.fromDaysSinceEpoch(days);
  }

  /// <summary>
  /// Converts a <see cref="DateTime" /> of any kind to a LocalDate in the specified calendar, ignoring the time of day.
  /// This does not perform any time zone conversions, so a DateTime with a <see cref="DateTime.Kind"/> of
  /// <see cref="DateTimeKind.Utc"/> will still represent the same year/month/day - it won't be converted into the local system time.
  /// </summary>
  /// <param name="dateTime">Value to convert into a Noda Time local date</param>
  /// <param name="calendar">The calendar system to convert into</param>
  /// <returns>A new <see cref="LocalDate"/> with the same values as the specified <c>DateTime</c>.</returns>
  static LocalDate FromDateTimeAndCalendar(DateTime dateTime, CalendarSystem calendar)
  {
  int days = NonNegativeMicrosecondsToDays(dateTime.microsecondsSinceEpoch); // - TimeConstants.BclDaysAtUnixEpoch;
  return new LocalDate.fromDaysSinceEpoch_forCalendar(days, calendar);
  }

  /// <summary>
  /// Returns the local date corresponding to the given "week year", "week of week year", and "day of week"
  /// in the ISO calendar system, using the ISO week-year rules.
  /// </summary>
  /// <param name="weekYear">ISO-8601 week year of value to return</param>
  /// <param name="weekOfWeekYear">ISO-8601 week of week year of value to return</param>
  /// <param name="dayOfWeek">ISO-8601 day of week to return</param>
  /// <returns>The date corresponding to the given week year / week of week year / day of week.</returns>
  static LocalDate FromWeekYearWeekAndDay(int weekYear, int weekOfWeekYear, IsoDayOfWeek dayOfWeek)
  => WeekYearRules.Iso.GetLocalDate(weekYear, weekOfWeekYear, dayOfWeek, CalendarSystem.Iso);

  /// <summary>
  /// Returns the local date corresponding to a particular occurrence of a day-of-week
  /// within a year and month. For example, this method can be used to ask for "the third Monday in April 2012".
  /// </summary>
  /// <remarks>
  /// The returned date is always in the ISO calendar. This method is unrelated to week-years and any rules for
  /// "business weeks" and the like - if a month begins on a Friday, then asking for the first Friday will give
  /// that day, for example.
  /// </remarks>
  /// <param name="year">The year of the value to return.</param>
  /// <param name="month">The month of the value to return.</param>
  /// <param name="occurrence">The occurrence of the value to return, which must be in the range [1, 5]. The value 5 can
  /// be used to always return the last occurrence of the specified day-of-week, even if there are only 4
  /// occurrences of that day-of-week in the month.</param>
  /// <param name="dayOfWeek">The day-of-week of the value to return.</param>
  /// <returns>The date corresponding to the given year and month, on the given occurrence of the
  /// given day of week.</returns>
  static LocalDate FromYearMonthWeekAndDay(int year, int month, int occurrence, IsoDayOfWeek dayOfWeek)
  {
    // This validates year and month as well as getting us a useful date.
    LocalDate startOfMonth = new LocalDate(year, month, 1);
    Preconditions.checkArgumentRange('occurrence', occurrence, 1, 5);
    Preconditions.checkArgumentRange('dayOfWeek', dayOfWeek.value, 1, 7);

    // Correct day of week, 1st week of month.
    int week1Day = dayOfWeek - startOfMonth.DayOfWeek + 1;
    if (week1Day <= 0)
    {
      week1Day += 7;
    }
    int targetDay = week1Day + (occurrence - 1) * 7;
    if (targetDay > CalendarSystem.Iso.GetDaysInMonth(year, month))
    {
      targetDay -= 7;
    }
    return new LocalDate(year, month, targetDay);
  }

  /// <summary>
  /// Adds the specified period to the date. Friendly alternative to <c>operator+()</c>.
  /// </summary>
  /// <param name="date">The date to add the period to</param>
  /// <param name="period">The period to add. Must not contain any (non-zero) time units.</param>
  /// <returns>The sum of the given date and period</returns>
  static LocalDate Add(LocalDate date, Period period) => date + period;

  /// <summary>
  /// Adds the specified period to this date. Fluent alternative to <c>operator+()</c>.
  /// </summary>
  /// <param name="period">The period to add. Must not contain any (non-zero) time units.</param>
  /// <returns>The sum of this date and the given period</returns>
  LocalDate Plus(Period period) => this + period;

  /// <summary>
  /// Adds the specified period to the date.
  /// </summary>
  /// <param name="date">The date to add the period to</param>
  /// <param name="period">The period to add. Must not contain any (non-zero) time units.</param>
  /// <returns>The sum of the given date and period</returns>
  LocalDate operator +(Period period)
  {
    Preconditions.checkNotNull(period, 'period');
    Preconditions.checkArgument(!period.HasTimeComponent, 'period', "Cannot add a period with a time component to a date");
    return period.AddDateTo(this, 1);
  }

//  /// <summary>
//  /// Combines the given <see cref="LocalDate"/> and <see cref="LocalTime"/> components
//  /// into a single <see cref="LocalDateTime"/>.
//  /// </summary>
//  /// <param name="date">The date to add the time to</param>
//  /// <param name="time">The time to add</param>
//  /// <returns>The sum of the given date and time</returns>
//  LocalDateTime AtTime(LocalTime time) => new LocalDateTime(this, time);

  /// <summary>
  /// Subtracts the specified period from the date. Friendly alternative to <c>operator-()</c>.
  /// </summary>
  /// <param name="date">The date to subtract the period from</param>
  /// <param name="period">The period to subtract. Must not contain any (non-zero) time units.</param>
  /// <returns>The result of subtracting the given period from the date.</returns>
  static LocalDate Subtract(LocalDate date, Period period) => date - period;

  /// <summary>
  /// Subtracts one date from another, returning the result as a <see cref="Period"/> with units of years, months and days.
  /// </summary>
  /// <remarks>
  /// This is simply a convenience method for calling <see cref="Period.Between(NodaTime.LocalDate,NodaTime.LocalDate)"/>.
  /// The calendar systems of the two dates must be the same.
  /// </remarks>
  /// <param name="lhs">The date to subtract from</param>
  /// <param name="rhs">The date to subtract</param>
  /// <returns>The result of subtracting one date from another.</returns>
  static Period Between(LocalDate lhs, LocalDate rhs) => lhs - rhs;

  /// <summary>
  /// Subtracts the specified period from this date. Fluent alternative to <c>operator-()</c>.
  /// </summary>
  /// <param name="period">The period to subtract. Must not contain any (non-zero) time units.</param>
  /// <returns>The result of subtracting the given period from this date.</returns>
  LocalDate MinusPeriod(Period period) {
    Preconditions.checkNotNull(period, 'period');
    Preconditions.checkArgument(!period.HasTimeComponent, 'period', "Cannot subtract a period with a time component from a date");
    return period.AddDateTo(this, -1);
  }

  /// <summary>
  /// Subtracts the specified date from this date, returning the result as a <see cref="Period"/> with units of years, months and days.
  /// Fluent alternative to <c>operator-()</c>.
  /// </summary>
  /// <remarks>The specified date must be in the same calendar system as this.</remarks>
  /// <param name="date">The date to subtract from this</param>
  /// <returns>The difference between the specified date and this one</returns>
  Period MinusDate(LocalDate date) => Period.BetweenDates(date, this); // this - date;

  /// <summary>
  /// Subtracts one date from another, returning the result as a <see cref="Period"/> with units of years, months and days.
  /// </summary>
  /// <remarks>
  /// This is simply a convenience operator for calling <see cref="Period.Between(NodaTime.LocalDate,NodaTime.LocalDate)"/>.
  /// The calendar systems of the two dates must be the same; an exception will be thrown otherwise.
  /// </remarks>
  /// <param name="lhs">The date to subtract from</param>
  /// <param name="rhs">The date to subtract</param>
  /// <returns>The result of subtracting one date from another.</returns>
  /// <exception cref="ArgumentException">
  /// <paramref name="lhs"/> and <paramref name="rhs"/> are not in the same calendar system.
  /// </exception>
  /// <summary>
  /// Subtracts the specified period from the date.
  /// This is a convenience operator over the <see cref="Minus(Period)"/> method.
  /// </summary>
  /// <param name="date">The date to subtract the period from</param>
  /// <param name="period">The period to subtract. Must not contain any (non-zero) time units.</param>
  /// <returns>The result of subtracting the given period from the date</returns>
  // todo: still hate dynamic dispatch
  dynamic operator -(dynamic rhs) => rhs is LocalDate ? MinusDate(rhs) : rhs is Period ? MinusPeriod(rhs) : throw new TypeError();

  /// <summary>
  /// Compares two <see cref="LocalDate" /> values for equality. This requires
  /// that the dates be the same, within the same calendar.
  /// </summary>
  /// <param name="lhs">The first value to compare</param>
  /// <param name="rhs">The second value to compare</param>
  /// <returns>True if the two dates are the same and in the same calendar; false otherwise</returns>
  bool operator ==(dynamic rhs) => rhs is LocalDate && this._yearMonthDayCalendar == rhs._yearMonthDayCalendar;

  // Comparison operators: note that we can't use YearMonthDayCalendar.Compare, as only the calendar knows whether it can use
  // naive comparisons.

  /// <summary>
  /// Compares two dates to see if the left one is strictly earlier than the right
  /// one.
  /// </summary>
  /// <remarks>
  /// Only dates with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  /// </remarks>
  /// <param name="lhs">First operand of the comparison</param>
  /// <param name="rhs">Second operand of the comparison</param>
  /// <exception cref="ArgumentException">The calendar system of <paramref name="rhs"/> is not the same
  /// as the calendar of <paramref name="lhs"/>.</exception>
  /// <returns>true if the <paramref name="lhs"/> is strictly earlier than <paramref name="rhs"/>, false otherwise.</returns>
  bool operator <(LocalDate rhs)
  {
    Preconditions.checkArgument(this.Calendar == rhs.Calendar, 'rhs', "Only values in the same calendar can be compared");
    return this.compareTo(rhs) < 0;
  }

  /// <summary>
  /// Compares two dates to see if the left one is earlier than or equal to the right
  /// one.
  /// </summary>
  /// <remarks>
  /// Only dates with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  /// </remarks>
  /// <param name="lhs">First operand of the comparison</param>
  /// <param name="rhs">Second operand of the comparison</param>
  /// <exception cref="ArgumentException">The calendar system of <paramref name="rhs"/> is not the same
  /// as the calendar of <paramref name="lhs"/>.</exception>
  /// <returns>true if the <paramref name="lhs"/> is earlier than or equal to <paramref name="rhs"/>, false otherwise.</returns>
  bool operator <=(LocalDate rhs)
  {
    Preconditions.checkArgument(this.Calendar== rhs.Calendar, 'rhs', "Only values in the same calendar can be compared");
    return this.compareTo(rhs) <= 0;
  }

  /// <summary>
  /// Compares two dates to see if the left one is strictly later than the right
  /// one.
  /// </summary>
  /// <remarks>
  /// Only dates with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  /// </remarks>
  /// <param name="lhs">First operand of the comparison</param>
  /// <param name="rhs">Second operand of the comparison</param>
  /// <exception cref="ArgumentException">The calendar system of <paramref name="rhs"/> is not the same
  /// as the calendar of <paramref name="lhs"/>.</exception>
  /// <returns>true if the <paramref name="lhs"/> is strictly later than <paramref name="rhs"/>, false otherwise.</returns>
  bool operator >(LocalDate rhs)
  {
    Preconditions.checkArgument(this.Calendar == rhs.Calendar, 'rhs', "Only values in the same calendar can be compared");
    return this.compareTo(rhs) > 0;
  }

  /// <summary>
  /// Compares two dates to see if the left one is later than or equal to the right
  /// one.
  /// </summary>
  /// <remarks>
  /// Only dates with the same calendar system can be compared. See the top-level type
  /// documentation for more information about comparisons.
  /// </remarks>
  /// <param name="lhs">First operand of the comparison</param>
  /// <param name="rhs">Second operand of the comparison</param>
  /// <exception cref="ArgumentException">The calendar system of <paramref name="rhs"/> is not the same
  /// as the calendar of <paramref name="lhs"/>.</exception>
  /// <returns>true if the <paramref name="lhs"/> is later than or equal to <paramref name="rhs"/>, false otherwise.</returns>
  bool operator >=(LocalDate rhs)
  {
    Preconditions.checkArgument(Calendar == rhs.Calendar, 'rhs', "Only values in the same calendar can be compared");
    return compareTo(rhs) >= 0;
  }

  /// <summary>
  /// Indicates whether this date is earlier, later or the same as another one.
  /// </summary>
  /// <remarks>
  /// Only dates within the same calendar systems can be compared with this method. Attempting to compare
  /// dates within different calendars will fail with an <see cref="ArgumentException"/>. Ideally, comparisons
  /// between values in different calendars would be a compile-time failure, but failing at execution time
  /// is almost always preferable to continuing.
  /// </remarks>
  /// <param name="other">The other date to compare this one with</param>
  /// <exception cref="ArgumentException">The calendar system of <paramref name="other"/> is not the
  /// same as the calendar system of this value.</exception>
  /// <returns>A value less than zero if this date is earlier than <paramref name="other"/>;
  /// zero if this date is the same as <paramref name="other"/>; a value greater than zero if this date is
  /// later than <paramref name="other"/>.</returns>
  int compareTo(LocalDate other)
  {
    Preconditions.checkArgument(Calendar == other?.Calendar, 'other', "Only values with the same calendar system can be compared");
    return Calendar.Compare(yearMonthDay, other.yearMonthDay);
  }

  /// <summary>
  /// Implementation of <see cref="IComparable.CompareTo"/> to compare two LocalDates.
  /// </summary>
  /// <remarks>
  /// This uses explicit interface implementation to avoid it being called accidentally. The generic implementation should usually be preferred.
  /// </remarks>
  /// <exception cref="ArgumentException"><paramref name="obj"/> is non-null but does not refer to an instance of <see cref="LocalDate"/>, or refers
  /// to a date in a different calendar system.</exception>
  /// <param name="obj">The object to compare this value with.</param>
  /// <returns>The result of comparing this LocalDate with another one; see <see cref="CompareTo(NodaTime.LocalDate)"/> for general details.
  /// If <paramref name="obj"/> is null, this method returns a value greater than 0.
  /// </returns>
  // todo: Dart has a Comparable<T> something or another
  int IComparable_CompareTo(dynamic obj)
  {
    if (obj == null)
    {
      return 1;
    }
    Preconditions.checkArgument(obj is LocalDate, 'obj', "Object must be of type NodaTime.LocalDate.");
    return compareTo(obj as LocalDate);
  }

  /// <summary>
  /// Returns the later date of the given two.
  /// </summary>
  /// <param name="x">The first date to compare.</param>
  /// <param name="y">The second date to compare.</param>
  /// <exception cref="ArgumentException">The two dates have different calendar systems.</exception>
  /// <returns>The later date of <paramref name="x"/> or <paramref name="y"/>.</returns>
  static LocalDate Max(LocalDate x, LocalDate y)
  {
    Preconditions.checkArgument(x.Calendar == y.Calendar, 'y', "Only values with the same calendar system can be compared");
    return x > y ? x : y;
  }

  /// <summary>
  /// Returns the earlier date of the given two.
  /// </summary>
  /// <param name="x">The first date to compare.</param>
  /// <param name="y">The second date to compare.</param>
  /// <exception cref="ArgumentException">The two dates have different calendar systems.</exception>
  /// <returns>The earlier date of <paramref name="x"/> or <paramref name="y"/>.</returns>
  static LocalDate Min(LocalDate x, LocalDate y)
  {
    Preconditions.checkArgument(x.Calendar == y.Calendar, 'y', "Only values with the same calendar system can be compared");
    return x < y ? x : y;
  }

  /// <summary>
  /// Returns a hash code for this local date.
  /// </summary>
  /// <returns>A hash code for this local date.</returns>
  @override int get hashCode => _yearMonthDayCalendar.hashCode;

//  /// <summary>
//  /// Compares two <see cref="LocalDate"/> values for equality. This requires
//  /// that the dates be the same, within the same calendar.
//  /// </summary>
//  /// <param name="obj">The object to compare this date with.</param>
//  /// <returns>True if the given value is another local date equal to this one; false otherwise.</returns>
//  bool Equals(dynamic obj) => obj is LocalDate && this == obj;

  /// <summary>
  /// Compares two <see cref="LocalDate"/> values for equality. This requires
  /// that the dates be the same, within the same calendar.
  /// </summary>
  /// <param name="other">The value to compare this date with.</param>
  /// <returns>True if the given value is another local date equal to this one; false otherwise.</returns>
  bool Equals(LocalDate other) => this == other;

  /// <summary>
  /// Resolves this local date into a <see cref="ZonedDateTime"/> in the given time zone representing the
  /// start of this date in the given zone.
  /// </summary>
  /// <remarks>
  /// This is a convenience method for calling <see cref="DateTimeZone.AtStartOfDay(LocalDate)"/>.
  /// </remarks>
  /// <param name="zone">The time zone to map this local date into</param>
  /// <exception cref="SkippedTimeException">The entire day was skipped due to a very large time zone transition.
  /// (This is extremely rare.)</exception>
  /// <returns>The <see cref="ZonedDateTime"/> representing the earliest time on this date, in the given time zone.</returns>
  ZonedDateTime AtStartOfDayInZone(DateTimeZone zone)
  {
  Preconditions.checkNotNull(zone, 'zone');
  return zone.AtStartOfDay(this);
  }

  /// <summary>
  /// Creates a new LocalDate representing the same physical date, but in a different calendar.
  /// The returned LocalDate is likely to have different field values to this one.
  /// For example, January 1st 1970 in the Gregorian calendar was December 19th 1969 in the Julian calendar.
  /// </summary>
  /// <param name="calendar">The calendar system to convert this local date to.</param>
  /// <returns>The converted LocalDate</returns>
  LocalDate WithCalendar(CalendarSystem calendar)
  {
  Preconditions.checkNotNull(calendar, 'calendar');
  return new LocalDate.fromDaysSinceEpoch_forCalendar(DaysSinceEpoch, calendar);
  }

  /// <summary>
  /// Returns a new LocalDate representing the current value with the given number of years added.
  /// </summary>
  /// <remarks>
  /// If the resulting date is invalid, lower fields (typically the day of month) are reduced to find a valid value.
  /// For example, adding one year to February 29th 2012 will return February 28th 2013; subtracting one year from
  /// February 29th 2012 will return February 28th 2011.
  /// </remarks>
  /// <param name="years">The number of years to add</param>
  /// <returns>The current value plus the given number of years.</returns>
  LocalDate PlusYears(int years) => DatePeriodFields.YearsField.Add(this, years);

  /// <summary>
  /// Returns a new LocalDate representing the current value with the given number of months added.
  /// </summary>
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
  /// <returns>The current date plus the given number of months</returns>
  LocalDate PlusMonths(int months) => DatePeriodFields.MonthsField.Add(this, months);

  /// <summary>
  /// Returns a new LocalDate representing the current value with the given number of days added.
  /// </summary>
  /// <remarks>
  /// <para>
  /// This method does not try to maintain the month or year of the current value, so adding 3 days to a value of January 30th
  /// will result in a value of February 2nd.
  /// </para>
  /// </remarks>
  /// <param name="days">The number of days to add</param>
  /// <returns>The current value plus the given number of days.</returns>
  LocalDate PlusDays(int days) => DatePeriodFields.DaysField.Add(this, days);

  /// <summary>
  /// Returns a new LocalDate representing the current value with the given number of weeks added.
  /// </summary>
  /// <param name="weeks">The number of weeks to add</param>
  /// <returns>The current value plus the given number of weeks.</returns>
  LocalDate PlusWeeks(int weeks) => DatePeriodFields.WeeksField.Add(this, weeks);

  /// <summary>
  /// Returns the next <see cref="LocalDate" /> falling on the specified <see cref="IsoDayOfWeek"/>.
  /// This is a strict "next" - if this date on already falls on the target
  /// day of the week, the returned value will be a week later.
  /// </summary>
  /// <param name="targetDayOfWeek">The ISO day of the week to return the next date of.</param>
  /// <returns>The next <see cref="LocalDate"/> falling on the specified day of the week.</returns>
  /// <exception cref="InvalidOperationException">The underlying calendar doesn't use ISO days of the week.</exception>
  /// <exception cref="ArgumentOutOfRangeException"><paramref name="targetDayOfWeek"/> is not a valid day of the
  /// week (Monday to Sunday).</exception>
  LocalDate Next(IsoDayOfWeek targetDayOfWeek)
  {
    // Avoids boxing...
    if (targetDayOfWeek < IsoDayOfWeek.monday || targetDayOfWeek > IsoDayOfWeek.sunday)
    {
      throw new RangeError('targetDayOfWeek');
    }
    // This will throw the desired exception for calendars with different week systems.
    IsoDayOfWeek thisDay = DayOfWeek;
    int difference = targetDayOfWeek - thisDay;
    if (difference <= 0)
    {
      difference += 7;
    }
    return PlusDays(difference);
  }

  /// <summary>
  /// Returns the previous <see cref="LocalDate" /> falling on the specified <see cref="IsoDayOfWeek"/>.
  /// This is a strict "previous" - if this date on already falls on the target
  /// day of the week, the returned value will be a week earlier.
  /// </summary>
  /// <param name="targetDayOfWeek">The ISO day of the week to return the previous date of.</param>
  /// <returns>The previous <see cref="LocalDate"/> falling on the specified day of the week.</returns>
  /// <exception cref="InvalidOperationException">The underlying calendar doesn't use ISO days of the week.</exception>
  /// <exception cref="ArgumentOutOfRangeException"><paramref name="targetDayOfWeek"/> is not a valid day of the
  /// week (Monday to Sunday).</exception>
  LocalDate Previous(IsoDayOfWeek targetDayOfWeek)
  {
    // Avoids boxing...
    if (targetDayOfWeek < IsoDayOfWeek.monday || targetDayOfWeek > IsoDayOfWeek.sunday)
    {
      throw new RangeError('targetDayOfWeek');
    }
    // This will throw the desired exception for calendars with different week systems.
    IsoDayOfWeek thisDay = DayOfWeek;
    int difference = targetDayOfWeek - thisDay;
    if (difference >= 0)
    {
      difference -= 7;
    }
    return PlusDays(difference);
  }

  /// <summary>
  /// Returns an <see cref="OffsetDate"/> for this local date with the given offset.
  /// </summary>
  /// <remarks>This method is purely a convenient alternative to calling the <see cref="OffsetDate"/> constructor directly.</remarks>
  /// <param name="offset">The offset to apply.</param>
  /// <returns>The result of this date offset by the given amount.</returns>
  OffsetDate WithOffset(Offset offset) => new OffsetDate(this, offset);

  /// <summary>
  /// Combines this <see cref="LocalDate"/> with the given <see cref="LocalTime"/>
  /// into a single <see cref="LocalDateTime"/>.
  /// Fluent alternative to <c>operator+()</c>.
  /// </summary>
  /// <param name="time">The time to combine with this date.</param>
  /// <returns>The <see cref="LocalDateTime"/> representation of the given time on this date</returns>
  LocalDateTime At(LocalTime time) => new LocalDateTime(this, time);

  LocalDate With(LocalDate Function(LocalDate) adjuster) => adjuster(this);

  /// <summary>
  /// Returns a <see cref="System.String" /> that represents this instance.
  /// </summary>
  /// <returns>
  /// The value of the current instance in the default format pattern ("D"), using the current thread's
  /// culture to obtain a format provider.
  /// </returns>
  @override String toString() => TextShim.toStringLocalDate(this); // LocalDatePattern.BclSupport.Format(this, null, CultureInfo.CurrentCulture);

  /// <summary>
  /// Formats the value of the current instance using the specified pattern.
  /// </summary>
  /// <returns>
  /// A <see cref="T:System.String" /> containing the value of the current instance in the specified format.
  /// </returns>
  /// <param name="patternText">The <see cref="T:System.String" /> specifying the pattern to use,
  /// or null to use the default format pattern ("D").
  /// </param>
  /// <param name="formatProvider">The <see cref="T:System.IFormatProvider" /> to use when formatting the value,
  /// or null to use the current thread's culture to obtain a format provider.
  /// </param>
  /// <filterpriority>2</filterpriority>
//  String ToStringFormatted(string patternText, IFormatProvider formatProvider) =>
//      LocalDatePattern.BclSupport.Format(this, patternText, formatProvider);

}
