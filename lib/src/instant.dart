// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Instant.cs
// c1fb0aa  on Oct 5, 2017

import 'package:intl/intl.dart';

import 'package:meta/meta.dart';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';

// todo: remove me -- this prevents me from accidentally using core.Duration
import 'dart:core' hide Duration;


/*
 TODO: BeforeMinValue / AfterMaxValue were being used to deal with nullable Instants -- Dart is struct-less -- everything can be nulled

 //ZoneInterval(String name, Instant start, Instant end, Offset wallOffset, Offset savings)
  //    : this(name, start ?? Instant.BeforeMinValue, end ?? Instant.AfterMaxValue, wallOffset, savings)


 */

// LUXON & MOMENT.JS are both milliseconds (neither of them run in a VM)
// HighResTimer is 5 microsecond accuracy
// I wish I could have two different versions of this class for the VM and JS targets. (a specific VM and JS include with just an external declaration here)
@immutable
class Instant implements Comparable<Instant> {
  // NodaTime enforces a range of -9998-01-01 and 9999-12-31 ... Is this related to CalendarCalculators?
  // These correspond to -9998-01-01 and 9999-12-31 respectively.
  @internal static const int minDays = -4371222;
  @internal static const int maxDays = 2932896; // 104249991

  // todo: Min\MaxTicks tack 62 bits ~ these will not work for the JSVM - check if this is okay?
  static const int _minTicks = minDays * TimeConstants.ticksPerDay;
  static const int _maxTicks = (maxDays + 1) * TimeConstants.ticksPerDay - 1;
  static const int _minMilliseconds = minDays * TimeConstants.millisecondsPerDay;
  static const int _maxMilliseconds = (maxDays + 1) * TimeConstants.millisecondsPerDay - 1;
  static const int _minSeconds = minDays * TimeConstants.secondsPerDay;
  static const int _maxSeconds = (maxDays + 1) * TimeConstants.secondsPerDay - 1;

  // This maps any integer x --> ~x --> -x - 1 (this might be important knowledge)
  /// Represents the smallest possible <see cref="Instant"/>.
  /// <remarks>This value is equivalent to -9998-01-01T00:00:00Z</remarks>
  static final Instant minValue = new Instant.trusted(new Span(days: minDays));
  /// Represents the largest possible <see cref="Instant"/>.
  /// <remarks>This value is equivalent to 9999-12-31T23:59:59.999999999Z</remarks>
  static final Instant maxValue = new Instant.trusted(new Span(days: maxDays, nanoseconds: TimeConstants.nanosecondsPerDay - 1));

  /// Instant which is invalid *except* for comparison purposes; it is earlier than any valid value.
  /// This must never be exposed.
  @internal static final Instant beforeMinValue = new Instant.trusted(new Span(days: Span.minDays)); //, deliberatelyInvalid: true);
  /// Instant which is invalid *except* for comparison purposes; it is later than any valid value.
  /// This must never be exposed.
  @internal static final Instant afterMaxValue = new Instant.trusted(new Span(days: Span.maxDays)); //, deliberatelyInvalid: true);

  final Span _span;

  // todo: investigate if this is okay ... see Instant.cs#115
  @internal Instant.untrusted(this._span);
  @internal Instant.trusted(this._span);
  Instant.fromUnixTimeTicks(int ticks) : _span = new Span(ticks: ticks);
  Instant.fromUnixTimeSeconds(int seconds) : _span = new Span(seconds: seconds);
  Instant.fromUnixTimeMilliseconds(int milliseconds) : _span = new Span(milliseconds: milliseconds);
  Instant() : _span = Span.zero;

  int compareTo(Instant other) => _span.compareTo(other._span);
  @internal bool get IsValid => daysSinceEpoch >= minDays && daysSinceEpoch <= maxDays;

  @override int get hashCode => _span.hashCode;
  @override bool operator==(dynamic other) => other is Instant && _span == other._span;

  Instant operator+(Span span) => this.plus(span);
  // Instant operator-(Span span) => this.minus(span);
  Instant plus(Span span) => new Instant.trusted(_span + span);
  Instant minus(Span span) => new Instant.trusted(_span - span);

  @internal LocalInstant plusOffset(Offset offset) {
    return new LocalInstant(_span + offset.toSpan());
  }

  // todo: evaluate whether all this extra framework is needed for our version: Instant.cs#L267
  @internal LocalInstant SafePlus(Offset offset) => plusOffset(offset);

  // Span operator-(Instant instant) => _span - instant._span;

  // todo: is there any clever way to add type annotations to this?
  dynamic operator-(dynamic other) =>
      other is Instant ? spanTo(other) :
      other is Span ? minus(other) :
      throw new ArgumentError('Expected Span or Instant.');

  // todo: think about this name ... it's not good
  // Instant minusSpan(Span span) => new Instant._trusted(_span - span);
  Span spanTo(Instant instant) => _span - instant._span;

  bool operator<(Instant other) => _span < other._span;
  bool operator<=(Instant other) => _span <= other._span;
  bool operator>(Instant other) => _span > other._span;
  bool operator>=(Instant other) => _span >= other._span;

  // Convenience methods from Nodatime -- evaluate if I want to keep these
  factory Instant.fromUtc(int year, int monthOfYear, int dayOfMonth, int hourOfDay, int minuteOfHour, [int secondOfMinute = 0])
  {
    var days = new LocalDate(year, monthOfYear, dayOfMonth).DaysSinceEpoch;
    var nanoOfDay = new LocalTime(hourOfDay, minuteOfHour, secondOfMinute).NanosecondOfDay;
    return new Instant.trusted(new Span(days: days, nanoseconds:  nanoOfDay));
  }

  static Instant max(Instant x, Instant y) => x > y ? x : y;
  static Instant min(Instant x, Instant y) => x < y ? x : y;

  @override toString() => TextShim.toStringInstant(this); // '${_span.totalSeconds} seconds since epoch.';

  // todo: you are here: https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Instant.cs#L507

  double toJulianDate() => (this - TimeConstants.julianEpoch).totalDays;

  DateTime toDateTimeUtc() {
    if (this < TimeConstants.bclEpoch) {
      // todo: this may not actually be the case for us
      throw new StateError('Instant out of range for DateTime');
    }

    if (Utility.isDartVM) return new DateTime.fromMicrosecondsSinceEpoch(_span.totalMicroseconds.toInt(), isUtc: true);
    return new DateTime.fromMillisecondsSinceEpoch(_span.totalMilliseconds.toInt(), isUtc: true);
  }

  DateTime toDateTimeLocal() {
    throw new UnimplementedError('Pipe in local date time zone.');
  }

//  // DateTimeOffset is a BCL Class
//  DateTimeOffset ToDateTimeOffset()
//  {
//    if (this < TimeConstants.bclEpoch)
//    {
//      throw new ArgumentError("Instant out of range for DateTimeOffset");
//    }
//    return new DateTimeOffset(TimeConstants.BclTicksAtUnixEpoch + ToUnixTimeTicks(), TimeSpan.Zero);
//  }

  factory Instant.fromJulianDate(double julianDate) => TimeConstants.julianEpoch + new Span.complex(days: julianDate);

  factory Instant.fromDateTime(DateTime dateTime) {
    if (Utility.isDartVM) return new Instant.trusted(new Span(microseconds: dateTime.microsecondsSinceEpoch));
    return new Instant.trusted(new Span(milliseconds: dateTime.millisecondsSinceEpoch));
  }

  // todo: why are these different?
  int get daysSinceEpoch => _span.days;
  int get nanosecondOfDay => _span.nanosecondOfDay;

  Span get spanSinceEpoch => _span;

  int toUnixTimeSeconds() => _span.floorSeconds;
  int toUnixTimeMilliseconds() => _span.floorMilliseconds; //.totalMilliseconds.toInt();
  int toUnixTimeTicks() => _span.floorTicks; //.totalTicks.toInt();

  // todo: should be toUtc iaw Dart Style Guide ~ leaving like it is in Nodatime for ease of porting
  //  ?? maybe the same for the 'WithOffset' ??? --< toOffsetDateTime
  ZonedDateTime inUtc() {
    // Bypass any determination of offset and arithmetic, as we know the offset is zero.
    var ymdc = GregorianYearMonthDayCalculator.getGregorianYearMonthDayCalendarFromDaysSinceEpoch(_span.days);
    var offsetDateTime = new OffsetDateTime.fullTrust(ymdc, _span.nanosecondOfDay, Offset.zero);
    return new ZonedDateTime.trusted(offsetDateTime, DateTimeZone.Utc);
  }

  // todo: Combine the regular and x_Calendar constructors
  ZonedDateTime InZone(DateTimeZone zone) =>
    // zone is checked for nullity by the constructor.
    new ZonedDateTime(this, zone);

  ZonedDateTime InZone_Calendar(DateTimeZone zone, CalendarSystem calendar)
  {
    Preconditions.checkNotNull(zone, 'zone');
    Preconditions.checkNotNull(calendar, 'calendar');
  return new ZonedDateTime.withCalendar(this, zone, calendar);
  }

  OffsetDateTime WithOffset(Offset offset) => new OffsetDateTime.instant(this, offset);

  OffsetDateTime WithOffset_Calendar(Offset offset, CalendarSystem calendar)
  {
    Preconditions.checkNotNull(calendar, 'calendar');
    return new OffsetDateTime.instantCalendar(this, offset, calendar);
  }

// todo: https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Instant.cs#L255
  // Add LocalInstant code

//  int _epochMilliseconds;
//  /// 0 to 999999 ~ 20 bits ~ 4 bytes on the VM
//  int _nanosecondsInterval;
//
//  /// This will being to lose precision in JS after 104 epoch days. The precision will be about 200 ns today (is there an exact equation for this?).
//  int get getEpochNanoseconds => _epochMilliseconds * TimeConstants.nanosecondsPerMillisecond + _nanosecondsInterval;
//  int get getEpochMicroseconds => _epochMilliseconds * TimeConstants.microsecondsPerMillisecond + _nanosecondsInterval ~/  TimeConstants.nanosecondsPerMicrosecond;
//  int get getEpochMilliseconds => _epochMilliseconds;
//  int get getEpochSeconds => _epochMilliseconds ~/ TimeConstants.millisecondsPerSecond;

}
