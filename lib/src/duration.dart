// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

//import 'dart:core' as core show Duration;
//import 'dart:core' hide Duration;

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

@internal
abstract class ITime {
  // This is 104249991 days
  static const int maxDays = maxMillis ~/ TimeConstants.millisecondsPerDay; // (1 << 24) - 1;
  // ~maxDays would be 4190717304 on JS (-104249992 is the correct number)
  static const int minDays = -104249992; // ~maxDays; <-- doesn't work in JS // todo: may hard encode if this makes unit tests not work

  // todo: Convert to BigInt for Dart 2.0
  static final BigInt minNanoseconds = BigInt.from(minDays) * BigInt.from(TimeConstants.nanosecondsPerDay);
  static final BigInt maxNanoseconds = (BigInt.from(maxDays) + BigInt.one) * BigInt.from(TimeConstants.nanosecondsPerDay) - BigInt.one;

  // 285420 years worth -- we are good for anything;
  // todo: should this be specific to the Platform?
  // todo: why was minMillis == -9007199254740993, which is Platform.intMinValueJS-1;
  static const int maxMillis = Platform.intMaxValueJS;
  static const int minMillis = Platform.intMinValueJS; // -9007199254740993; // Utility.intMinValueJS; // was -maxMillis; very shortly was ~maxMillis (which I guess doesn't work well in JS)

  static Time plusSmallNanoseconds(Time span, int nanoseconds) => span._plusSmallNanoseconds(nanoseconds);

  static int millisecondsOf(Time span) => span._milliseconds;
  static int nanosecondsIntervalOf(Time span) => span._nanosecondsInterval;
  static Time trusted(int milliseconds, [int nanosecondsInterval = 0]) => MillisecondTime(milliseconds, nanosecondsInterval);
  static Time untrusted(int milliseconds, [int nanoseconds = 0]) => Time._untrusted(milliseconds, nanoseconds);

  // Instant.epochTime(nanos).timeOfEpochDay.inNanoseconds
  static int nanosecondOfEpochDay(Time time) => time._nanosecondOfEpochDay;
  // return Instant.epochTime(time).epochDayTime.inNanoseconds;
  // return (time._milliseconds - (Instant.epochTime(time).daysSinceEpoch * TimeConstants.millisecondsPerDay)) * TimeConstants.nanosecondsPerMillisecond + time._nanosecondsInterval;

  // @deprecated
  /// This is probably not the method the average person wants to be calling.
  /// This is used by the TimePatternParser to get the nanosecond portion of the amount of nanoseconds passed a day's worth of time,
  /// (not the calendar concept of a day)
  static int nanosecondOfDurationDay(Time time) => time._nanosecondOfDurationDay;

  // todo: a performant check?
  static int epochDay(Time time) => IInstant.trusted(time).epochDay;
}

// Implementation note:
// When/if BigInt is becoming part of dart:core, add a nanosecond API supporting it?

/*
  Potentially:
    // 68 years as int32 on VM
    // 292271023045 years as int64 on VM
    // 142710460 years on JS before precision loss
    final int _seconds;
    // 0  to 999999999 ~ 30 bits ~ 4 bytes on VM
    final int _nanosecondOfSecond;

  // 8 or 12 bytes on VM (slight optimization)
  // 16 bytes on JS (no change)
*/

/// Represents a fixed (and calendar-independent) length of time.
///
/// A [Time] is a fixed length of time defined by an integral number of nanoseconds.
/// Although [Time]s are usually used with a positive number of nanoseconds, negative [Time]s are valid, and may occur
/// naturally when e.g. subtracting an earlier [Instant] from a later one.
///
/// A [Time] represents a fixed length of elapsed time along the time line that occupies the same amount of
/// time regardless of when it is applied. In contrast, [Period] represents a period of time in
/// calendrical terms (years, months, days, and so on) that may vary in elapsed time when applied.
///
/// In general, use [Time] to represent durations applied to global types like [Instant]
/// and [ZonedDateTime]; use [Period] to represent a period applied to local types like
/// [LocalDateTime].
///
/// The range of valid values of a [Time] is greater than the span of time supported by Time Machine - so for
/// example, subtracting one [Instant] from another will always give a valid [Time].
///
/// This type is immutable.
@immutable
abstract class Time implements Comparable<Time> {
  // 285420 years max (unlimited on VM)
  int get _milliseconds;
  /// 0 to 999999 ~ 20 bits ~ 4 bytes on the VM
  int get _nanosecondsInterval;

  static const int _minNano = 0;

  static const Time zero = MillisecondTime(0, 0);
  /// Gets a [Time] value equal to 1 nanosecond; the smallest amount by which an instant can vary.
  static const Time epsilon = MillisecondTime(0, 1);
  // oneNanosecond is constant forever -- in theory, epsilon will change if we go beyond nanosecond precision.
  static const Time oneNanosecond = MillisecondTime(0, 1);
  static const Time oneMicrosecond = MillisecondTime(0, TimeConstants.nanosecondsPerMicrosecond);
  static const Time oneMillisecond = MillisecondTime(1, 0);
  static const Time oneSecond = MillisecondTime(TimeConstants.millisecondsPerSecond, 0);
  static const Time oneDay = MillisecondTime(TimeConstants.millisecondsPerDay, 0);
  static const Time oneWeek = MillisecondTime(TimeConstants.millisecondsPerWeek, 0);

  // todo: we don't ever seem to check this, do we want to?
  /// Gets the maximum value supported by [Time]. (todo: is this okay for us? -- after the integer math on that division ... maybe??? maybe not???)
  static final Time maxValue = Time(days: ITime.maxDays, nanoseconds: TimeConstants.nanosecondsPerDay - 1);

  /// Gets the minimum (largest negative) value supported by [Time].
  static final Time minValue = Time(days: ITime.minDays);

  factory Time._untrusted(int milliseconds, [int nanoseconds = 0]) {
    if (nanoseconds >= _minNano && nanoseconds < TimeConstants.nanosecondsPerMillisecond) return MillisecondTime(milliseconds, nanoseconds);

    if (nanoseconds < _minNano) {
      var delta = ((_minNano - nanoseconds) / TimeConstants.nanosecondsPerMillisecond).ceil();
      milliseconds -= delta;
      nanoseconds = nanoseconds % TimeConstants.nanosecondsPerMillisecond;
    }
    else if (nanoseconds >= TimeConstants.nanosecondsPerMillisecond) {
      var delta = nanoseconds ~/ TimeConstants.nanosecondsPerMillisecond;
      milliseconds += delta;
      nanoseconds = nanoseconds % TimeConstants.nanosecondsPerMillisecond;
    }

    if (milliseconds < 0 && nanoseconds != 0) {
      milliseconds++;
      nanoseconds -= TimeConstants.nanosecondsPerMillisecond;
    }

    return MillisecondTime(milliseconds, nanoseconds);

    // todo: custom errors
    // throw new ArgumentError.notNull('Checked duration failure: milliseconds = $milliseconds, nanoseconds = $nanoseconds;');
  }

  factory Time.bigIntNanoseconds(BigInt bigNanoseconds) {
    // todo: this clamps -- should we test for overflow?
    var milliseconds = (bigNanoseconds ~/ TimeConstants.nanosecondsPerMillisecondBigInt).toInt();
    var nanoseconds = bigArithmeticMod(bigNanoseconds, TimeConstants.nanosecondsPerMillisecondBigInt).toInt();
    return Time._untrusted(milliseconds, nanoseconds);
  }

  const Time._();

  // todo: more optimization likely possible
  factory Time({num days = 0, num hours = 0, num minutes = 0, num seconds = 0,
    num milliseconds = 0, num microseconds = 0, num nanoseconds = 0}) {
    var _hours = days * TimeConstants.hoursPerDay;
    var _minutes = (_hours + hours) * TimeConstants.minutesPerHour;
    var _seconds = (_minutes + minutes) * TimeConstants.secondsPerMinute;
    var _milliseconds = (_seconds + seconds) * TimeConstants.millisecondsPerSecond + milliseconds;

    var _microseconds = (_milliseconds - _milliseconds.toInt()) * TimeConstants.microsecondsPerMillisecond;

    // note: this is here to deal with extreme values
    if (microseconds.abs() > Platform.maxMicrosecondsToNanoseconds) {
      var millisecondsToAdd = microseconds ~/ TimeConstants.microsecondsPerMillisecond;
      _milliseconds += millisecondsToAdd;
      microseconds -= millisecondsToAdd * TimeConstants.microsecondsPerMillisecond;
    }

    var _nanoseconds = (_microseconds + microseconds) * TimeConstants.nanosecondsPerMicrosecond + nanoseconds;

    return Time._untrusted(_milliseconds.toInt(), _nanoseconds.toInt());
  }

  factory Time.duration(Duration duration) {
    var milliseconds = duration.inMilliseconds;
    // todo: I think this can be optimized
    var nanosecondsInterval = TimeConstants.nanosecondsPerMicrosecond
        * (duration.inMicroseconds - duration.inMilliseconds * TimeConstants.microsecondsPerMillisecond);
    return MillisecondTime(milliseconds, nanosecondsInterval);
  }

  // https://www.dartlang.org/guides/language/effective-dart/design#prefer-naming-a-method-to___-if-it-copies-the-objects-state-to-a-new-object
  Duration get toDuration =>
      Duration(
          microseconds: _milliseconds * TimeConstants.microsecondsPerMillisecond
              + _nanosecondsInterval ~/ TimeConstants.nanosecondsPerMicrosecond);

  /// Gets the hour of the half-day of this local time, in the range 1 to 12 inclusive.
  ///
  /// see: https://en.wikipedia.org/wiki/12-hour_clock
  int get hourOf12HourClock {
    var hod = hourOfDay % 12;
    return hod == 0 ? 12 : hod;
  }

  // todo: hour of Day?
  int get hourOfDay => arithmeticMod((_milliseconds ~/ TimeConstants.millisecondsPerHour), TimeConstants.hoursPerDay);
  int get minuteOfHour => arithmeticMod((_milliseconds ~/ TimeConstants.millisecondsPerMinute), TimeConstants.minutesPerHour);
  int get secondOfMinute => arithmeticMod((_milliseconds ~/ TimeConstants.millisecondsPerSecond), TimeConstants.secondsPerMinute);
  int get millisecondOfSecond => arithmeticMod(_milliseconds, TimeConstants.millisecondsPerSecond);
  int get microsecondOfSecond =>
      arithmeticMod(_milliseconds, TimeConstants.millisecondsPerSecond) * TimeConstants.microsecondsPerMillisecond
          + _nanosecondsInterval ~/ TimeConstants.nanosecondsPerMicrosecond;
  int get nanosecondOfSecond =>
      arithmeticMod(_milliseconds, TimeConstants.millisecondsPerSecond) * TimeConstants.nanosecondsPerMillisecond
          + _nanosecondsInterval; // % TimeConstants.nanosecondsPerSecond;

  double get totalDays => _milliseconds / TimeConstants.millisecondsPerDay + _nanosecondsInterval / TimeConstants.nanosecondsPerDay;
  double get totalHours => _milliseconds / TimeConstants.millisecondsPerHour + _nanosecondsInterval / TimeConstants.nanosecondsPerHour;
  double get totalMinutes => _milliseconds / TimeConstants.millisecondsPerMinute + _nanosecondsInterval / TimeConstants.nanosecondsPerMinute;
  double get totalSeconds => _milliseconds / TimeConstants.millisecondsPerSecond + _nanosecondsInterval / TimeConstants.nanosecondsPerSecond;
  double get totalMilliseconds => _milliseconds + _nanosecondsInterval / TimeConstants.nanosecondsPerMillisecond;
  double get totalMicroseconds => _milliseconds * TimeConstants.microsecondsPerMillisecond + _nanosecondsInterval / TimeConstants.nanosecondsPerMicrosecond;
  double get totalNanoseconds => canNanosecondsBeInteger ? inNanoseconds.toDouble() : inNanosecondsAsBigInt.toDouble();

  BigInt get inNanosecondsAsBigInt => BigInt.from(_milliseconds) * TimeConstants.nanosecondsPerMillisecondBigInt + BigInt.from(_nanosecondsInterval);

  int get inDays => _milliseconds ~/ TimeConstants.millisecondsPerDay;
  int get inHours => _milliseconds ~/ TimeConstants.millisecondsPerHour;
  int get inMinutes => _milliseconds ~/ TimeConstants.millisecondsPerMinute;
  int get inSeconds => _milliseconds ~/ TimeConstants.millisecondsPerSecond;
  int get inMilliseconds => _milliseconds;
  int get inMicroseconds => _milliseconds * TimeConstants.microsecondsPerMillisecond + _nanosecondsInterval ~/ TimeConstants.nanosecondsPerMicrosecond;
  int get inNanoseconds => _milliseconds * TimeConstants.nanosecondsPerMillisecond + _nanosecondsInterval;

  // this isn't exact (since we don't look at _nanosecondsInterval, we just don't allow `==`
  bool get canNanosecondsBeInteger =>
      _milliseconds < Platform.intMaxValue ~/ TimeConstants.nanosecondsPerMillisecond
          && _milliseconds > Platform.intMinValue ~/ TimeConstants.nanosecondsPerMillisecond;

  bool get isNegative => _milliseconds < 0 || (_milliseconds == 0 && _nanosecondsInterval < 0);

  /*
  // original version shown here, very bad, rounding errors much bad -- be better than this
  // int get nanosecondOfDay => ((totalDays - days.toDouble()) * TimeConstants.nanosecondsPerDay).toInt();
  // todo: here to ease porting, unsure if this is wanted -- but it's not hurting me?
  // todo: these should work with the floorDay
  // int get nanosecondOfDay => millisecondsOfDay*TimeConstants.nanosecondsPerMillisecond + _nanosecondsInterval;
  int get millisecondsOfDay => _milliseconds - (days * TimeConstants.millisecondsPerDay);

  int get nanosecondOfFloorDay =>
      (_milliseconds - (inDays * TimeConstants.millisecondsPerDay)) * TimeConstants.nanosecondsPerMillisecond + _nanosecondsInterval;

  // todo: this is not obvious enough that, this is probably not the method the average person wants to be calling
  int get nanosecondOfDay =>
      (_milliseconds - (days * TimeConstants.millisecondsPerDay)) * TimeConstants.nanosecondsPerMillisecond + _nanosecondsInterval;
  */

  // todo: Any reason for these? --- a bit disingenuously if you think about Offsets
  //@deprecated
  //Time get timeOfDay => new Time._ (_milliseconds - (days * TimeConstants.millisecondsPerDay), _nanosecondsInterval);
  //@deprecated
  //Time get timeOfFloorDay => new Time._ (_milliseconds - (floorDays * TimeConstants.millisecondsPerDay), _nanosecondsInterval);

  // todo: need to test that this is good -- should be
  @override int get hashCode => _milliseconds.hashCode ^ _nanosecondsInterval;

  @override String toString([String? patternText, Culture? culture]) => TimePatterns.format(this, patternText, culture);

  Time operator +(Time other) => add(other);

  Time operator -(Time other) => subtract(other);

  Time operator -() => Time._untrusted(-_milliseconds, -_nanosecondsInterval);

  // todo: test
  Time abs(Time other) => Time._untrusted(_milliseconds.abs(), _nanosecondsInterval.abs());

  Time add(Time other) => Time._untrusted(_milliseconds + other._milliseconds, _nanosecondsInterval + other._nanosecondsInterval);

  Time subtract(Time other) => Time._untrusted(_milliseconds - other._milliseconds, _nanosecondsInterval - other._nanosecondsInterval);

  Time operator *(num factor) => Time._untrusted((_milliseconds * factor).floor(), (_nanosecondsInterval * factor).floor());

  // Span operator*(num factor) => new Span(nanoseconds: (_milliseconds * TimeConstants.nanosecondsPerMillisecond + _nanosecondsInterval) * factor);

  // note: this is wrong'ish*
  // Span operator/(num factor) => new Span._untrusted(_milliseconds ~/ factor, _nanosecondsInterval ~/ factor);
  // note: this works on VM (because of BigInt)
  Time operator /(num quotient) {
    if (quotient.abs() < 1) return this * (1.0/quotient);

    if (canNanosecondsBeInteger) {
      return Time(nanoseconds: (_milliseconds * TimeConstants.nanosecondsPerMillisecond + _nanosecondsInterval) ~/ quotient);
    } else {
      return Time.bigIntNanoseconds(inNanosecondsAsBigInt ~/ BigInt.from(quotient));
    }
  }

  // This is what it will look like in JS -- only fails 1 unit test though
  // Span operator/(num factor) => new Span(nanoseconds: ((_milliseconds * TimeConstants.nanosecondsPerMillisecond + _nanosecondsInterval) / factor).toInt());

  Time multiply(num factor) => this * factor;

  Time divide(num factor) => this / factor;

  Time _plusSmallNanoseconds(int nanoseconds) => Time._untrusted(_milliseconds, _nanosecondsInterval + nanoseconds);

  @override
  bool operator ==(Object other) => other is Time && equals(other);

  bool operator >=(Time other) =>
      (_milliseconds > other._milliseconds) ||
          (_milliseconds == other._milliseconds && _nanosecondsInterval >= other._nanosecondsInterval);

  bool operator <=(Time other) =>
      (_milliseconds < other._milliseconds) ||
          (_milliseconds == other._milliseconds && _nanosecondsInterval <= other._nanosecondsInterval);

  bool operator >(Time other) =>
      (_milliseconds > other._milliseconds) ||
          (_milliseconds == other._milliseconds && _nanosecondsInterval > other._nanosecondsInterval);

  bool operator <(Time other) => (_milliseconds < other._milliseconds) ||
      (_milliseconds == other._milliseconds && _nanosecondsInterval < other._nanosecondsInterval);


  static Time max(Time x, Time y) => x > y ? x : y;

  static Time min(Time x, Time y) => x < y ? x : y;

  static Time minus(Time x, Time y) => x - y;

  static Time plus(Time x, Time y) => x + y;

  bool equals(Time other) => _milliseconds == other._milliseconds && _nanosecondsInterval == other._nanosecondsInterval;

  @override
  int compareTo(Time? other) {
    if (other == null) return 1;
    int millisecondsComparison = _milliseconds.compareTo(other._milliseconds);
    return millisecondsComparison != 0 ? millisecondsComparison : _nanosecondsInterval.compareTo(other._nanosecondsInterval);
  }

  int get _nanosecondOfDurationDay {
    // _milliseconds ~/ TimeConstants.millisecondsPerDay;
    // todo: convert to mod-based logic? (see: NanosecondTime)
    // return (_milliseconds - (inDays * TimeConstants.millisecondsPerDay)) * TimeConstants.nanosecondsPerMillisecond + _nanosecondsInterval;
    return arithmeticMod(_milliseconds, TimeConstants.millisecondsPerDay) * TimeConstants.nanosecondsPerMillisecond + _nanosecondsInterval;
        // + arithmeticMod(_nanosecondsInterval, TimeConstants.nanosecondsPerMillisecond);
  }

  int get _nanosecondOfEpochDay {
    // return (_milliseconds - (inDays * TimeConstants.millisecondsPerDay)) * TimeConstants.nanosecondsPerMillisecond + _nanosecondsInterval;

    // Do I need to re-mod this?
    return epochArithmeticMod(_milliseconds, TimeConstants.millisecondsPerDay) * TimeConstants.nanosecondsPerMillisecond +_nanosecondsInterval;
  }
}


class MillisecondTime extends Time {
  // 285420 years max (unlimited on VM)
  @override
  final int _milliseconds;

  /// 0 to 999999 ~ 20 bits ~ 4 bytes on the VM
  @override
  final int _nanosecondsInterval;

  // ignore: unused_field
  static const int _minNano = 0;

  const MillisecondTime(this._milliseconds, this._nanosecondsInterval) : super._();
}

/// A [Time] based only on nanoseconds.
///
/// Pro: Helps create a consistent experience that is computationally more efficient
///
/// Con: The super._milliseconds && super._nanoseconds is null -- and takes up some amount of memory
///
/// see: https://en.wikipedia.org/wiki/Space%E2%80%93time_tradeoff
///
/// Can we get the best of both?
@immutable
class NanosecondTime extends Time {
  final int _nanoseconds;

  @override int get _milliseconds => inMilliseconds;
  @override int get _nanosecondsInterval => arithmeticMod(_nanoseconds, TimeConstants.nanosecondsPerMillisecond);

  NanosecondTime(this._nanoseconds) : super._() {
    assert(_nanoseconds >= Platform.intMinValue && _nanoseconds <= Platform.intMaxValue);
  }

  @override Time operator -() => NanosecondTime(-_nanoseconds);
  @override bool operator <(Time other) => _nanoseconds < other.totalNanoseconds;
  @override bool operator <=(Time other) => _nanoseconds <= other.totalNanoseconds;
  @override bool operator >(Time other) => _nanoseconds > other.totalNanoseconds;
  @override bool operator >=(Time other) => _nanoseconds >= other.totalNanoseconds;
  @override Time _plusSmallNanoseconds(int nanoseconds) => NanosecondTime(nanoseconds + _nanoseconds);

  @override Time abs(Time other) => NanosecondTime(_nanoseconds.abs());
  @override bool get isNegative => _nanoseconds.isNegative;

  @override bool get canNanosecondsBeInteger => true;

  @override int compareTo(Time? other) {
    if (other == null) return 1;
    if (other.canNanosecondsBeInteger) {
      return _nanoseconds.compareTo(other.inNanoseconds);
    }
    return super.compareTo(other);
  }

  @override bool equals(Time other) => other.canNanosecondsBeInteger ? _nanoseconds == other.inNanoseconds : false;

  @override int get hourOfDay => arithmeticMod((_nanoseconds ~/ TimeConstants.nanosecondsPerHour), TimeConstants.hoursPerDay);
  @override int get minuteOfHour => arithmeticMod((_nanoseconds ~/ TimeConstants.nanosecondsPerMinute), TimeConstants.minutesPerHour);
  @override int get secondOfMinute => arithmeticMod((_nanoseconds ~/ TimeConstants.nanosecondsPerSecond), TimeConstants.secondsPerMinute);
  @override int get millisecondOfSecond => arithmeticMod(_nanoseconds ~/ TimeConstants.nanosecondsPerMillisecond, TimeConstants.millisecondsPerSecond);
  // todo: is [mod, division] or [division, mod] better?
  @override int get microsecondOfSecond => arithmeticMod(_nanoseconds, TimeConstants.nanosecondsPerSecond) ~/ TimeConstants.microsecondsPerMillisecond;
  @override int get nanosecondOfSecond => arithmeticMod(_nanoseconds, TimeConstants.nanosecondsPerSecond);

  @override double get totalDays => _nanoseconds / TimeConstants.nanosecondsPerDay;
  @override double get totalHours => _nanoseconds / TimeConstants.nanosecondsPerHour;
  @override double get totalMinutes => _nanoseconds / TimeConstants.nanosecondsPerMinute;
  @override double get totalSeconds => _nanoseconds / TimeConstants.nanosecondsPerSecond;
  @override double get totalMilliseconds => _nanoseconds / TimeConstants.nanosecondsPerMillisecond;
  @override double get totalMicroseconds => _nanoseconds / TimeConstants.nanosecondsPerMicrosecond;
  @override double get totalNanoseconds => _nanoseconds.toDouble();

  @override BigInt get inNanosecondsAsBigInt => BigInt.from(_nanoseconds);

  @override int get inDays => _nanoseconds ~/ TimeConstants.nanosecondsPerDay;
  @override int get inHours => _nanoseconds ~/ TimeConstants.nanosecondsPerHour;
  @override int get inMinutes => _nanoseconds ~/ TimeConstants.nanosecondsPerMinute;
  @override int get inSeconds => _nanoseconds ~/ TimeConstants.nanosecondsPerSecond;
  @override int get inMilliseconds => _nanoseconds ~/ TimeConstants.nanosecondsPerMillisecond;
  @override int get inMicroseconds => _nanoseconds ~/ TimeConstants.nanosecondsPerMicrosecond;
  @override int get inNanoseconds => _nanoseconds;

  @override Duration get toDuration => Duration(microseconds: inMicroseconds);

  @override int get _nanosecondOfDurationDay {
    // return arithmeticMod((_nanoseconds ~/ TimeConstants.nanosecondsPerDay), TimeConstants.hoursPerDay);
    // return _nanoseconds - (inDays * TimeConstants.nanosecondsPerDay);
    return arithmeticMod(_nanoseconds, TimeConstants.nanosecondsPerDay);
  }

  @override int get _nanosecondOfEpochDay {
    return epochArithmeticMod(_nanoseconds, TimeConstants.nanosecondsPerDay);
  }
}
