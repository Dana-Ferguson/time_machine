// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

@internal
abstract class IInstant {
  // NodaTime enforces a range of -9998-01-01 and 9999-12-31 ... Is this related to CalendarCalculators?
  // These correspond to -9998-01-01 and 9999-12-31 respectively.
  static const int minDays = -4371222;
  static const int maxDays = 2932896; // 104249991

  static Instant trusted(Time time) => new Instant._trusted(time);
  static Instant untrusted(Time time) => new Instant.epochTime(time);

  /// Instant which is invalid *except* for comparison purposes; it is earlier than any valid value.
  /// This must never be exposed.
  static final Instant beforeMinValue = new Instant._trusted(new Time(days: ITime.minDays)); //, deliberatelyInvalid: true);
  /// Instant which is invalid *except* for comparison purposes; it is later than any valid value.
  /// This must never be exposed.
  static final Instant afterMaxValue = new Instant._trusted(new Time(days: ITime.maxDays)); //, deliberatelyInvalid: true);

  // note: Extensions would be `better than sliced bread` here!!!!
  static LocalInstant plusOffset(Instant instant, Offset offset) => instant._plusOffset(offset);
  static LocalInstant safePlus(Instant instant, Offset offset) => instant._safePlus(offset);
}

/// Represents an instant on the global timeline, with nanosecond resolution.
///
/// An [Instant] has no concept of a particular time zone or calendar: it simply represents a point in
/// time that can be globally agreed-upon.
///
/// This type is immutable.
@immutable
class Instant implements Comparable<Instant> {
  /// Represents the smallest possible [Instant].
  /// This value is equivalent to -9998-01-01T00:00:00Z
  static final Instant minValue = new Instant._trusted(new Time(days: IInstant.minDays));
  /// Represents the largest possible [Instant].
  /// This value is equivalent to 9999-12-31T23:59:59.999999999Z
  static final Instant maxValue = new Instant._trusted(new Time(days: IInstant.maxDays, nanoseconds: TimeConstants.nanosecondsPerDay - 1));

  static const Instant unixEpoch = const Instant._trusted(Time.zero);

  final Time timeSinceEpoch;

  // todo: investigate if this is okay ... see Instant.cs#115
  factory Instant.epochTime(Time time) {
    if (time < minValue.timeSinceEpoch) return IInstant.beforeMinValue;
    if (time > maxValue.timeSinceEpoch) return IInstant.afterMaxValue;
    return new Instant._trusted(time);
  }

  /// [Clock.getCurrentInstant] for [Clock.current].
  factory Instant.now() {
    return Clock.current.getCurrentInstant();
  }

  const Instant._trusted(this.timeSinceEpoch);

  /// Time since the [unixEpoch]
  factory Instant({int days = 0, int hours = 0, int minutes = 0, int seconds = 0,
    int milliseconds = 0, int microseconds = 0, int nanoseconds = 0}) =>
      Instant.epochTime(
          Time(days: days, hours:hours, minutes: minutes, seconds: seconds,
              milliseconds: milliseconds, microseconds: microseconds, nanoseconds: nanoseconds));

  // Convenience methods from NodaTime -- evaluate if I want to keep these, todo: convert to be like LocalDateTime?
  factory Instant.utc(int year, int monthOfYear, int dayOfMonth, int hourOfDay, int minuteOfHour, [int secondOfMinute = 0]) {
    var days = ILocalDate.daysSinceEpoch(new LocalDate(year, monthOfYear, dayOfMonth));
    var nanoOfDay = new LocalTime(hourOfDay, minuteOfHour, secondOfMinute).nanosecondOfDay;
    return new Instant._trusted(new Time(days: days, nanoseconds:  nanoOfDay));
  }

  factory Instant.julianDate(double julianDate) => TimeConstants.julianEpoch + new Time.complex(days: julianDate);

  factory Instant.dateTime(DateTime dateTime) {
    if (Platform.isVM) return new Instant._trusted(new Time(microseconds: dateTime.microsecondsSinceEpoch));
    return new Instant._trusted(new Time(milliseconds: dateTime.millisecondsSinceEpoch));
  }


  int compareTo(Instant other) => timeSinceEpoch.compareTo(other.timeSinceEpoch);
  @wasInternal bool get isValid => this >= minValue && this <= maxValue;

  @override int get hashCode => timeSinceEpoch.hashCode;
  @override bool operator==(dynamic other) => other is Instant && timeSinceEpoch == other.timeSinceEpoch;

  Instant operator+(Time time) => this.add(time);
  Instant operator-(Time time) => this.subtract(time);
  Instant add(Time time) => new Instant.epochTime(timeSinceEpoch + time);
  Instant subtract(Time time) => new Instant.epochTime(timeSinceEpoch - time);

  LocalInstant _plusOffset(Offset offset) {
    return new LocalInstant(timeSinceEpoch + offset.toTime());
  }

  LocalInstant _safePlus(Offset offset) {
    var days = timeSinceEpoch.inDays;
    // plusOffset(offset);
    // If we can do the arithmetic safely, do so.
    if (days > IInstant.minDays && days < IInstant.maxDays)
    {
      return _plusOffset(offset);
    }
    // Handle BeforeMinValue and BeforeMaxValue simply.
    if (days < IInstant.minDays)
    {
      return LocalInstant.beforeMinValue;
    }
    if (days > IInstant.maxDays)
    {
      return LocalInstant.afterMaxValue;
    }
    // Okay, do the arithmetic as a Duration, then check the result for overflow, effectively.
    var asDuration = ITime.plusSmallNanoseconds(timeSinceEpoch, offset.nanoseconds);
    if (asDuration.inDays < IInstant.minDays)
    {
      return LocalInstant.beforeMinValue;
    }
    if (asDuration.inDays > IInstant.maxDays)
    {
      return LocalInstant.afterMaxValue;
    }
    return new LocalInstant(asDuration);
  }

  /*
  // Span operator-(Instant instant) => _span - instant._span;
  // todo: is there any clever way to add type annotations to this?
  dynamic operator-(dynamic other) =>
      other is Instant ? timeUntil(other) :
      other is Time ? minus(other) :
      throw new ArgumentError('Expected Time or Instant.');*/

  // todo: this name is really bad
  // todo: think about this name ... it's not good
  // Instant minusSpan(Span span) => new Instant._trusted(_span - span);

  /// Calculates the time until [this] would become [instant].
  /// [this] + [Time] = [instant] or `start + Time = end`
  Time timeUntil(Instant instant) => instant.timeSinceEpoch.subtract(timeSinceEpoch);

  /// The fluent opposite of [timeUntil]
  Time timeSince(Instant instant) => timeSinceEpoch.subtract(instant.timeSinceEpoch);

  bool operator<(Instant other) => timeSinceEpoch < other.timeSinceEpoch;
  bool operator<=(Instant other) => timeSinceEpoch <= other.timeSinceEpoch;
  bool operator>(Instant other) => timeSinceEpoch > other.timeSinceEpoch;
  bool operator>=(Instant other) => timeSinceEpoch >= other.timeSinceEpoch;

  bool isAfter(Instant other) => timeSinceEpoch > other.timeSinceEpoch;
  bool isBefore(Instant other) => timeSinceEpoch < other.timeSinceEpoch;

  static Instant max(Instant x, Instant y) => x > y ? x : y;
  static Instant min(Instant x, Instant y) => x < y ? x : y;
  static Instant plus(Instant x, Time y) => x.add(y);
  static Instant minus(Instant x, Time y) => x.subtract(y);
  static Time difference(Instant start, Instant end) => start.timeSince(end);

  // @override toString() => TextShim.toStringInstant(this); // '${_span.totalSeconds} seconds since epoch.';
  @override String toString([String patternText, Culture culture]) =>
      InstantPatterns.format(this, patternText, culture);

  // On Dart2: this is still required, but I can't reproduce a minimal test case -- I am lost.
  @ddcSupportHack String toStringDDC([String patternText, Culture culture]) =>
      InstantPatterns.format(this, patternText, culture);

  double toJulianDate() => (TimeConstants.julianEpoch.timeUntil(this)).totalDays;

  DateTime toDateTimeUtc() {
    if (Platform.isVM) return new DateTime.fromMicrosecondsSinceEpoch(timeSinceEpoch.totalMicroseconds.toInt(), isUtc: true);
    return new DateTime.fromMillisecondsSinceEpoch(timeSinceEpoch.totalMilliseconds.toInt(), isUtc: true);
  }

  // DateTime toDateTimeLocal() => inLocalZone().toDateTimeLocal();
  // todo: verify this is equivalent to above? ... detect platform and do microseconds where appropriate
  DateTime toDateTimeLocal() => new DateTime.fromMillisecondsSinceEpoch(timeSinceEpoch.totalMilliseconds.toInt());

  int get daysSinceEpoch => timeSinceEpoch.inDays; //days;
  int get nanosecondOfDay => timeSinceEpoch.nanosecondOfFloorDay; //nanosecondOfDay;

  // todo: I don't think I like this --> timeSinceEpoch??? -- are these useful convenient overloads?
  int toUnixTimeSeconds() => timeSinceEpoch.inSeconds;
  int toUnixTimeMilliseconds() => timeSinceEpoch.inMilliseconds; //.totalMilliseconds.toInt();
  int toUnixTimeMicroseconds() => timeSinceEpoch.totalMicroseconds.floor();

  // todo: should be toUtc iaw Dart Style Guide ~ leaving like it is in Nodatime for ease of porting
  //  ?? maybe the same for the 'WithOffset' ??? --< toOffsetDateTime
  ZonedDateTime inUtc() {
    // Bypass any determination of offset and arithmetic, as we know the offset is zero.
    var ymdc = GregorianYearMonthDayCalculator.getGregorianYearMonthDayCalendarFromDaysSinceEpoch(timeSinceEpoch.inDays);
    var offsetDateTime = IOffsetDateTime.fullTrust(ymdc, timeSinceEpoch.nanosecondOfFloorDay, Offset.zero);
    return IZonedDateTime.trusted(offsetDateTime, DateTimeZone.utc);
  }

  ZonedDateTime inZone(DateTimeZone zone, [CalendarSystem calendar]) =>
      // zone is checked for nullity by the constructor.
      // constructor also checks and corrects for calendar being null
    new ZonedDateTime(this, zone, calendar);

  // todo: get the correct calendar for the local timezone / culture
  /// Get the [ZonedDateTime] that corresponds to this [Instant] within in the zone [DateTimeZone.local].
  ZonedDateTime inLocalZone([CalendarSystem calendar]) => new ZonedDateTime(this, DateTimeZone.local, calendar);

  OffsetDateTime withOffset(Offset offset, [CalendarSystem calendar]) => IOffsetDateTime.fromInstant(this, offset, calendar);
}