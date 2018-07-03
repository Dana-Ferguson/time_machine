// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';

import 'package:time_machine/time_machine.dart' as public;

@internal
abstract class IInstant {
  // NodaTime enforces a range of -9998-01-01 and 9999-12-31 ... Is this related to CalendarCalculators?
  // These correspond to -9998-01-01 and 9999-12-31 respectively.
  static const int minDays = -4371222;
  static const int maxDays = 2932896; // 104249991

  static Instant trusted(Time span) => new Instant._trusted(span);
  static Instant untrusted(Time span) => new Instant._untrusted(span);

  /// Instant which is invalid *except* for comparison purposes; it is earlier than any valid value.
  /// This must never be exposed.
  static final Instant beforeMinValue = new Instant._trusted(new Time(days: ISpan.minDays)); //, deliberatelyInvalid: true);
  /// Instant which is invalid *except* for comparison purposes; it is later than any valid value.
  /// This must never be exposed.
  static final Instant afterMaxValue = new Instant._trusted(new Time(days: ISpan.maxDays)); //, deliberatelyInvalid: true);

  // note: Extensions would be `better than sliced bread` here!!!!
  static LocalInstant plusOffset(Instant instant, Offset offset) => instant._plusOffset(offset);
  static LocalInstant safePlus(Instant instant, Offset offset) => instant._safePlus(offset);
}

@immutable
class Instant implements Comparable<Instant> {
  // todo: Min\MaxTicks tack 62 bits ~ these will not work for the JSVM - check if this is okay?
  static const int _minTicks = IInstant.minDays * TimeConstants.ticksPerDay;
  static const int _maxTicks = (IInstant.maxDays + 1) * TimeConstants.ticksPerDay - 1;
  static const int _minMilliseconds = IInstant.minDays * TimeConstants.millisecondsPerDay;
  static const int _maxMilliseconds = (IInstant.maxDays + 1) * TimeConstants.millisecondsPerDay - 1;
  static const int _minSeconds = IInstant.minDays * TimeConstants.secondsPerDay;
  static const int _maxSeconds = (IInstant.maxDays + 1) * TimeConstants.secondsPerDay - 1;

  // This maps any integer x --> ~x --> -x - 1 (this might be important knowledge)
  /// Represents the smallest possible [Instant].
  /// This value is equivalent to -9998-01-01T00:00:00Z
  static final Instant minValue = new Instant._trusted(new Time(days: IInstant.minDays));
  /// Represents the largest possible [Instant].
  /// This value is equivalent to 9999-12-31T23:59:59.999999999Z
  static final Instant maxValue = new Instant._trusted(new Time(days: IInstant.maxDays, nanoseconds: TimeConstants.nanosecondsPerDay - 1));

  final Time _span;

  // todo: investigate if this is okay ... see Instant.cs#115
  factory Instant._untrusted(Time _span) {
    if (_span < minValue._span) return IInstant.beforeMinValue;
    if (_span > maxValue._span) return IInstant.afterMaxValue;
    return new Instant._trusted(_span);
  }

  /// [Clock.getCurrentInstant] for [Clock.current].
  factory Instant.now() {
    return Clock.current.getCurrentInstant();
  }

  const Instant._trusted(this._span);
  // todo: to untrusted factories
  Instant.fromUnixTimeTicks(int ticks) : _span = new Time(ticks: ticks);
  Instant.fromUnixTimeSeconds(int seconds) : _span = new Time(seconds: seconds);
  Instant.fromUnixTimeMilliseconds(int milliseconds) : _span = new Time(milliseconds: milliseconds);
  // todo: should this mirror functionality more similar to `new DateTime()`?
  const Instant() : _span = Time.zero;

  int compareTo(Instant other) => _span.compareTo(other._span);
  @wasInternal bool get isValid => this >= minValue && this <= maxValue;

  @override int get hashCode => _span.hashCode;
  @override bool operator==(dynamic other) => other is Instant && _span == other._span;

  Instant operator+(Time span) => this.plus(span);
  // Instant operator-(Span span) => this.minus(span);
  Instant plus(Time span) => new Instant._untrusted(_span + span);
  Instant minus(Time span) => new Instant._untrusted(_span - span);

  LocalInstant _plusOffset(Offset offset) {
    return new LocalInstant(_span + offset.toSpan());
  }

  LocalInstant _safePlus(Offset offset) {
    var days = _span.floorDays;
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
    var asDuration = ISpan.plusSmallNanoseconds(_span, offset.nanoseconds);
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
      other is Instant ? spanTo(other) :
      other is Time ? minus(other) :
      throw new ArgumentError('Expected Span or Instant.');

  // todo: this name is really bad
  // todo: think about this name ... it's not good
  // Instant minusSpan(Span span) => new Instant._trusted(_span - span);
  Time spanTo(Instant instant) => _span - instant._span;

  bool operator<(Instant other) => _span < other._span;
  bool operator<=(Instant other) => _span <= other._span;
  bool operator>(Instant other) => _span > other._span;
  bool operator>=(Instant other) => _span >= other._span;

  // Convenience methods from Nodatime -- evaluate if I want to keep these
  factory Instant.fromUtc(int year, int monthOfYear, int dayOfMonth, int hourOfDay, int minuteOfHour, [int secondOfMinute = 0])
  {
    var days = ILocalDate.daysSinceEpoch(new LocalDate(year, monthOfYear, dayOfMonth));
    var nanoOfDay = new LocalTime(hourOfDay, minuteOfHour, secondOfMinute).nanosecondOfDay;
    return new Instant._trusted(new Time(days: days, nanoseconds:  nanoOfDay));
  }

  static Instant max(Instant x, Instant y) => x > y ? x : y;
  static Instant min(Instant x, Instant y) => x < y ? x : y;

  // @override toString() => TextShim.toStringInstant(this); // '${_span.totalSeconds} seconds since epoch.';
  @override String toString([String patternText, /**IFormatProvider*/ dynamic formatProvider]) =>
      InstantPatterns.bclSupport.format(this, patternText, formatProvider ?? Cultures.currentCulture);

  @ddcSupportHack String toStringDDC([String patternText, /**IFormatProvider*/ dynamic formatProvider]) =>
      InstantPatterns.bclSupport.format(this, patternText, formatProvider ?? Cultures.currentCulture);

  double toJulianDate() => (this - TimeConstants.julianEpoch).totalDays;

  DateTime toDateTimeUtc() {
    if (Platform.isVM) return new DateTime.fromMicrosecondsSinceEpoch(_span.totalMicroseconds.toInt(), isUtc: true);
    return new DateTime.fromMillisecondsSinceEpoch(_span.totalMilliseconds.toInt(), isUtc: true);
  }

  // DateTime toDateTimeLocal() => inLocalZone().toDateTimeLocal();
  // todo: verify this is equivalent to above? ... detect platform and do microseconds where appropriate
  DateTime toDateTimeLocal() => new DateTime.fromMillisecondsSinceEpoch(timeSinceEpoch.totalMilliseconds.toInt());
  
  factory Instant.fromJulianDate(double julianDate) => TimeConstants.julianEpoch + new Time.complex(days: julianDate);

  factory Instant.fromDateTime(DateTime dateTime) {
    if (Platform.isVM) return new Instant._trusted(new Time(microseconds: dateTime.microsecondsSinceEpoch));
    return new Instant._trusted(new Time(milliseconds: dateTime.millisecondsSinceEpoch));
  }

  int get daysSinceEpoch => _span.floorDays; //days;
  int get nanosecondOfDay => _span.nanosecondOfFloorDay; //nanosecondOfDay;

  // todo: should this just be spanSinceEpoch() ?? would def. increase discoverability
  // todo: or could we just make Span be Time??? Would the be cool or confusing?
  // TimeSinceEpoch in Nodatime .. todo: should we change this to conform?
  Time get timeSinceEpoch => _span;

  int toUnixTimeSeconds() => ISpan.floorSeconds(_span);
  int toUnixTimeMilliseconds() => _span.floorMilliseconds; //.totalMilliseconds.toInt();
  int toUnixTimeTicks() => ISpan.floorTicks(_span); //.totalTicks.toInt();

  // todo: should be toUtc iaw Dart Style Guide ~ leaving like it is in Nodatime for ease of porting
  //  ?? maybe the same for the 'WithOffset' ??? --< toOffsetDateTime
  ZonedDateTime inUtc() {
    // Bypass any determination of offset and arithmetic, as we know the offset is zero.
    var ymdc = GregorianYearMonthDayCalculator.getGregorianYearMonthDayCalendarFromDaysSinceEpoch(_span.floorDays);
    var offsetDateTime = IOffsetDateTime.fullTrust(ymdc, _span.nanosecondOfFloorDay, Offset.zero);
    return IZonedDateTime.trusted(offsetDateTime, DateTimeZone.utc);
  }

  // todo: Combine the regular and x_Calendar constructors
  ZonedDateTime inZone(DateTimeZone zone, [CalendarSystem calendar]) =>
      // zone is checked for nullity by the constructor.
      // constructor also checks and corrects for calendar being null
    new ZonedDateTime(this, zone, calendar);
  
  // todo: get the correct calendar for the local timezone / culture
  /// Get the [ZonedDateTime] that corresponds to this [Instant] within in the zone [DateTimeZone.local].
  ZonedDateTime inLocalZone([CalendarSystem calendar]) => new ZonedDateTime(this, DateTimeZone.local, calendar);
  
  OffsetDateTime withOffset(Offset offset, [CalendarSystem calendar]) => IOffsetDateTime.fromInstant(this, offset, calendar);

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

