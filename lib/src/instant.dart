// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Instant.cs
// c1fb0aa  on Oct 5, 2017

import 'package:intl/intl.dart';

import 'package:meta/meta.dart';
import 'package:time_machine/time_machine.dart';

// todo: remove me -- this prevents me from accidentally using core.Duration
import 'dart:core' hide Duration;

// LUXON & MOMENT.JS are both milliseconds (neither of them run in a VM)
// HighResTimer is 5 microsecond accuracy
// I wish I could have two different versions of this class for the VM and JS targets. (a specific VM and JS include with just an external declaration here)
@immutable
class Instant implements Comparable<Instant> {
  // NodaTime enforces a range of -9998-01-01 and 9999-12-31 ... Is this related to CalendarCalculators?
  final Span _span;

  Instant._trusted(this._span);
  // Instant.fromUnixTimeTicks(int ticks) : _span = new Span(ticks: ticks);
  Instant.fromUnixTimeSeconds(int seconds) : _span = new Span(seconds: seconds);

  int compareTo(Instant other) => _span.compareTo(other._span);

  @override int get hashCode => _span.hashCode;
  @override bool operator==(dynamic other) => other is Instant && _span == other._span;

  Instant operator+(Span span) => new Instant._trusted(_span + span);
  // Instant operator-(Span span) => new Instant._trusted(_span - span);
  Instant plus(Span span) => this + span;
  Instant minus(Span span) => this - span;

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
  bool operator>=(Instant other) => _span <= other._span;

  // Convenience methods from Nodatime -- evaluate if I want to keep these
  factory Instant.fromUtc(int year, int monthOfYear, int dayOfMonth, int hourOfDay, int minuteOfHour, [int secondOfMinute = 0])
  {
    var days = new LocalDate(year, monthOfYear, dayOfMonth).DaysSinceEpoch;
    var nanoOfDay = new LocalTime(hourOfDay, minuteOfHour, secondOfMinute).NanosecondOfDay;
    return new Instant._trusted(new Span(days: days, nanoseconds:  nanoOfDay));
  }

  static Instant max(Instant x, Instant y) => x > y ? x : y;
  static Instant min(Instant x, Instant y) => x < y ? x : y;

  @override toString() => '${_span.totalSeconds} seconds since epoch.';

  // todo: you are here: https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Instant.cs#L507

  double toJulianDate() => (this - TimeConstants.julianEpoch).totalDays;

  DateTime toDateTimeUtc() {
    if (this < TimeConstants.bclEpoch) {
      // todo: this may not actually be the case for us
      throw new StateError('Instant out of range for DateTime');
    }

    return new DateTime.fromMicrosecondsSinceEpoch(_span.totalMicroseconds.toInt(), isUtc: true);
  }

  DateTime toDateTimeLocal() {
    //
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
