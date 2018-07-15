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
  static Instant untrusted(Time time) => new Instant._untrusted(time);

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

  final Time _epochTime;

  // todo: investigate if this is okay ... see Instant.cs#115
  factory Instant._untrusted(Time time) {
    if (time < minValue._epochTime) return IInstant.beforeMinValue;
    if (time > maxValue._epochTime) return IInstant.afterMaxValue;
    return new Instant._trusted(time);
  }

  /// [Clock.getCurrentInstant] for [Clock.current].
  factory Instant.now() {
    return Clock.current.getCurrentInstant();
  }

  const Instant._trusted(this._epochTime);

  /// Time since the [unixEpoch]
  factory Instant({int days = 0, int hours = 0, int minutes = 0, int seconds = 0,
    int milliseconds = 0, int microseconds = 0, int nanoseconds = 0}) => 
      Instant._untrusted(
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


  int compareTo(Instant other) => _epochTime.compareTo(other._epochTime);
  @wasInternal bool get isValid => this >= minValue && this <= maxValue;

  @override int get hashCode => _epochTime.hashCode;
  @override bool operator==(dynamic other) => other is Instant && _epochTime == other._epochTime;

  Instant operator+(Time time) => this.plus(time);
  // Instant operator-(Span span) => this.minus(span);
  Instant plus(Time time) => new Instant._untrusted(_epochTime + time);
  Instant minus(Time time) => new Instant._untrusted(_epochTime - time);

  LocalInstant _plusOffset(Offset offset) {
    return new LocalInstant(_epochTime + offset.toTime());
  }

  LocalInstant _safePlus(Offset offset) {
    var days = _epochTime.floorDays;
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
    var asDuration = ITime.plusSmallNanoseconds(_epochTime, offset.nanoseconds);
    if (asDuration.floorDays < IInstant.minDays)
    {
      return LocalInstant.beforeMinValue;
    }
    if (asDuration.floorDays > IInstant.maxDays)
    {
      return LocalInstant.afterMaxValue;
    }
    return new LocalInstant(asDuration);
  }

  // Span operator-(Instant instant) => _span - instant._span;
  // todo: is there any clever way to add type annotations to this?
  dynamic operator-(dynamic other) =>
      other is Instant ? timeUntil(other) :
      other is Time ? minus(other) :
      throw new ArgumentError('Expected Time or Instant.');

  // todo: this name is really bad
  // todo: think about this name ... it's not good
  // Instant minusSpan(Span span) => new Instant._trusted(_span - span);
  Time timeUntil(Instant instant) => _epochTime - instant._epochTime;

  bool operator<(Instant other) => _epochTime < other._epochTime;
  bool operator<=(Instant other) => _epochTime <= other._epochTime;
  bool operator>(Instant other) => _epochTime > other._epochTime;
  bool operator>=(Instant other) => _epochTime >= other._epochTime;
  
  static Instant max(Instant x, Instant y) => x > y ? x : y;
  static Instant min(Instant x, Instant y) => x < y ? x : y;

  // @override toString() => TextShim.toStringInstant(this); // '${_span.totalSeconds} seconds since epoch.';
  @override String toString([String patternText, Culture culture]) =>
      InstantPatterns.format(this, patternText, culture);

  // On Dart2: this is still required, but I can't reproduce a minimal test case -- I am lost.
  @ddcSupportHack String toStringDDC([String patternText, Culture culture]) =>
      InstantPatterns.format(this, patternText, culture);

  double toJulianDate() => (this - TimeConstants.julianEpoch).totalDays;

  DateTime toDateTimeUtc() {
    if (Platform.isVM) return new DateTime.fromMicrosecondsSinceEpoch(_epochTime.totalMicroseconds.toInt(), isUtc: true);
    return new DateTime.fromMillisecondsSinceEpoch(_epochTime.totalMilliseconds.toInt(), isUtc: true);
  }

  // DateTime toDateTimeLocal() => inLocalZone().toDateTimeLocal();
  // todo: verify this is equivalent to above? ... detect platform and do microseconds where appropriate
  DateTime toDateTimeLocal() => new DateTime.fromMillisecondsSinceEpoch(timeSinceEpoch.totalMilliseconds.toInt());

  Time get timeSinceEpoch => _epochTime;

  int get daysSinceEpoch => _epochTime.floorDays; //days;
  int get nanosecondOfDay => _epochTime.nanosecondOfFloorDay; //nanosecondOfDay;
  // todo: I don't think I like this --> timeSinceEpoch??? -- are these useful convenient overloads?
  int toUnixTimeSeconds() => ITime.floorSeconds(_epochTime);
  int toUnixTimeMilliseconds() => _epochTime.floorMilliseconds; //.totalMilliseconds.toInt();
  int toUnixTimeMicroseconds() => _epochTime.totalMicroseconds.floor();
  
  // todo: should be toUtc iaw Dart Style Guide ~ leaving like it is in Nodatime for ease of porting
  //  ?? maybe the same for the 'WithOffset' ??? --< toOffsetDateTime
  ZonedDateTime inUtc() {
    // Bypass any determination of offset and arithmetic, as we know the offset is zero.
    var ymdc = GregorianYearMonthDayCalculator.getGregorianYearMonthDayCalendarFromDaysSinceEpoch(_epochTime.floorDays);
    var offsetDateTime = IOffsetDateTime.fullTrust(ymdc, _epochTime.nanosecondOfFloorDay, Offset.zero);
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