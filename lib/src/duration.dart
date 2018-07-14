// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

//import 'dart:core' as core show Duration;
//import 'dart:core' hide Duration;

import 'package:meta/meta.dart';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';
import 'package:time_machine/src/text/time_machine_text.dart';

// Todo: should I rename Duration? I kind of don't want to cause issues with dart.core collisions?
// Can I do the core.Duration trick as a standard?

// I did consider just doing nanoseconds only, but we would max out at 104 days.

// *** I guess implicitly hiding a core class (Duration in this case) is considered too evil.
// todo: maybe names:
//  - Span, TimeSpan, TimeDuration, Time, TimeLength, TimeAmount
//  note: I don't want something that required other classes to need to be renamed as well:
//  I don't want --> TimeDuration; TimeInstant; TimeInterval --> etc...
//  - maybe it's Darty that way -- but probably not -- in that case, you do your import 'time_machine' as time;
//  see: https://www.dartlang.org/guides/language/effective-dart/design#do-use-terms-consistently
//
// Span (working name atm) is cool... but its a pre-existing concept in many languages that isn't time related

@internal
abstract class ITime {
  // This is 104249991 days
  static const int maxDays = maxMillis ~/ TimeConstants.millisecondsPerDay; // (1 << 24) - 1;
  // ~maxDays would be 4190717304 on JS (-104249992 is the correct number)
  static const int minDays = -104249992; // ~maxDays; <-- doesn't work in JS // todo: may hard encode if this makes unit tests not work

  // todo: Convert to BigInt for Dart 2.0
  static final /*BigInt*/ int minNanoseconds = /*(BigInteger)*/minDays * TimeConstants.nanosecondsPerDay;
  static final /*BigInt*/ int maxNanoseconds = (maxDays + 1 /*BigInteger.One*/) * TimeConstants.nanosecondsPerDay - 1;

  // 285420 years worth -- we are good for anything;
  // todo: should this be specific to the Platform?
  // todo: why was minMillis == -9007199254740993, which is Platform.intMinValueJS-1;
  static const int maxMillis = Platform.intMaxValueJS;
  static const int minMillis = Platform.intMinValueJS; // -9007199254740993; // Utility.intMinValueJS; // was -maxMillis; very shortly was ~maxMillis (which I guess doesn't work well in JS)

  static bool isInt64Representable(Time span) => span._isInt64Representable;
  static Time plusSmallNanoseconds(Time span, int nanoseconds) => span._plusSmallNanoseconds(nanoseconds);
  
  static int floorSeconds(Time span) => span._floorSeconds;
  
  static int millisecondsOf(Time span) => span._milliseconds;
  static int nanosecondsIntervalOf(Time span) => span._nanosecondsInterval;
  static Time trusted(int milliseconds, [int nanosecondsInterval = 0]) => new Time._(milliseconds, nanosecondsInterval);
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
class Time implements Comparable<Time> {
  // 285420 years max (unlimited on VM)
  final int _milliseconds;

  /// 0 to 999999 ~ 20 bits ~ 4 bytes on the VM
  final int _nanosecondsInterval;
  static const int _minNano = 0;
  // static const int _maxNano = TimeConstants.nanosecondsPerMillisecond - 1; // 999999;

  // this is only true on the VM....
  // static final Duration maxValue = new Duration._trusted(9007199254740992, 999999);

  // todo: Should these technically be under TimeConstants? (since they are 'Time' and 'const'??? ... or should I move TimeConstants to here?)
  static const Time zero = const Time._(0);
  /// Gets a [Time] value equal to 1 nanosecond; the smallest amount by which an instant can vary.
  static const Time epsilon = const Time._(0, 1);
  // oneNanosecond is constant forever -- in theory, epsilon will change if we go beyond nanosecond precision.
  static const Time oneNanosecond = const Time._(0, 1);
  static const Time oneMicrosecond = const Time._(0, TimeConstants.nanosecondsPerMicrosecond);
  static const Time oneMillisecond = const Time._(1, 0);
  static const Time oneSecond = const Time._(TimeConstants.millisecondsPerSecond, 0);
  static const Time oneDay = const Time._(TimeConstants.millisecondsPerDay, 0);
  static const Time oneWeek = const Time._(TimeConstants.millisecondsPerWeek, 0);


  /// Gets the maximum value supported by [Time]. (todo: is this okay for us? -- after the integer math on that division ... maybe??? maybe not???)
  static Time maxValue = new Time(days: ITime.maxDays, nanoseconds: TimeConstants.nanosecondsPerDay - 1);

  /// Gets the minimum (largest negative) value supported by [Time].
  static Time minValue = new Time(days: ITime.minDays);

  const Time._(this._milliseconds, [this._nanosecondsInterval = 0]);

  factory Time._untrusted(int milliseconds, [int nanoseconds = 0]) {
    if (nanoseconds >= _minNano && nanoseconds < TimeConstants.nanosecondsPerMillisecond) return new Time._(milliseconds, nanoseconds);

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

    return new Time._(milliseconds, nanoseconds);

    // todo: custom errors
    // throw new ArgumentError.notNull('Checked duration failure: milliseconds = $milliseconds, nanoseconds = $nanoseconds;');
  }

  factory Time({int days = 0, int hours = 0, int minutes = 0, int seconds = 0,
    int milliseconds = 0, int microseconds = 0, int nanoseconds = 0}) {
    milliseconds += days * TimeConstants.millisecondsPerDay;
    milliseconds += hours * TimeConstants.millisecondsPerHour;
    milliseconds += minutes * TimeConstants.millisecondsPerMinute;
    milliseconds += seconds * TimeConstants.millisecondsPerSecond;

    // todo: can this be simplified?
    if (microseconds > TimeConstants.microsecondsPerMillisecond) {
      milliseconds += microseconds ~/ TimeConstants.microsecondsPerMillisecond;
      nanoseconds += microseconds % TimeConstants.microsecondsPerMillisecond * TimeConstants.nanosecondsPerMicrosecond;;
    }
    else if (microseconds < -TimeConstants.microsecondsPerMillisecond) {
      milliseconds += microseconds ~/ TimeConstants.microsecondsPerMillisecond;
      nanoseconds += arithmeticMod(microseconds, TimeConstants.microsecondsPerMillisecond) * TimeConstants.nanosecondsPerMicrosecond;
    }
    else {
      nanoseconds += microseconds * TimeConstants.nanosecondsPerMicrosecond;
    }

    return new Time._untrusted(milliseconds, nanoseconds);
  }
  
  factory Time.fromBigIntNanoseconds(BigInt bigNanoseconds) {
    // todo: this clamps -- should we test for overflow?
    var milliseconds = (bigNanoseconds ~/ TimeConstants.nanosecondsPerMillisecondBigInt).toInt();
    var nanoseconds = bigArithmeticMod(bigNanoseconds, TimeConstants.nanosecondsPerMillisecondBigInt).toInt();
    return Time._untrusted(milliseconds, nanoseconds);
  }

  // todo: should these be the default constructor?
  factory Time.complex({num days = 0, num hours = 0, num minutes = 0, num seconds = 0,
    num milliseconds = 0, num microseconds = 0, num nanoseconds = 0}) {
    int _days = days.floor();
    int _hours = hours.floor();
    int _minutes = minutes.floor();
    int _seconds = seconds.floor();
    int _milliseconds = milliseconds.floor();

    var totalMilliseconds = _milliseconds;
    var intervalNanoseconds = nanoseconds.toInt();

    totalMilliseconds += _days * TimeConstants.millisecondsPerDay;
    totalMilliseconds += _hours * TimeConstants.millisecondsPerHour;
    totalMilliseconds += _minutes * TimeConstants.millisecondsPerMinute;
    totalMilliseconds += _seconds * TimeConstants.millisecondsPerSecond;

    intervalNanoseconds += (microseconds * TimeConstants.nanosecondsPerMicrosecond).round();

    intervalNanoseconds += ((days - _days) * TimeConstants.nanosecondsPerDay).round();
    intervalNanoseconds += ((hours - _hours) * TimeConstants.nanosecondsPerDay).round();
    intervalNanoseconds += ((minutes - _minutes) * TimeConstants.nanosecondsPerDay).round();
    intervalNanoseconds += ((seconds - _seconds) * TimeConstants.nanosecondsPerDay).round();
    intervalNanoseconds += ((milliseconds - _milliseconds) * TimeConstants.nanosecondsPerMillisecond).round();

// print("***$milliseconds***$nanoseconds***_days=$_days***days=$days***delta=${days-_days}***");

    return new Time._untrusted(totalMilliseconds, intervalNanoseconds);
  }

  Time.fromDuration(Duration duration)
      :
        _milliseconds = duration.inMilliseconds,
        _nanosecondsInterval = TimeConstants.nanosecondsPerMicrosecond
            * (duration.inMicroseconds - duration.inMilliseconds * TimeConstants.microsecondsPerMillisecond)
  ;

  // https://www.dartlang.org/guides/language/effective-dart/design#prefer-naming-a-method-to___-if-it-copies-the-objects-state-to-a-new-object
  Duration get toDuration =>
      new Duration(
          microseconds: milliseconds * TimeConstants.microsecondsPerMillisecond
              + _nanosecondsInterval ~/ TimeConstants.nanosecondsPerMicrosecond);

  // todo: I feel like the naming here is not consistent enough (but this is consistent with NodaTime)
  // todo: yeah -- look at this stuff, days are so different, I don't think it's obvious (maybe, hours --> hourOfDay or something like that ~ which is really weird to be in [Span] anyway?)
  // todo: I put in days as FloorDays a lot ~ which is fine until you go negative ~ then all of this acts wrong (I think for all of it - I want to do a check
  //  where I use floor() if it's negative) .. or does the VM basically already cover that.
  // int get days2 => floorDays;

  int get days => (_milliseconds ~/ TimeConstants.millisecondsPerDay);

  int get hours => arithmeticMod((_milliseconds ~/ TimeConstants.millisecondsPerHour), TimeConstants.hoursPerDay);

  int get minutes => arithmeticMod((_milliseconds ~/ TimeConstants.millisecondsPerMinute), TimeConstants.minutesPerHour);

  int get seconds => arithmeticMod((_milliseconds ~/ TimeConstants.millisecondsPerSecond), TimeConstants.secondsPerMinute);

  // todo: should this be called subsecondMilliseconds??? or shoudl the other's be changed?
  int get milliseconds => arithmeticMod(_milliseconds, TimeConstants.millisecondsPerSecond);

  int get subsecondMicroseconds =>
      arithmeticMod(_milliseconds, TimeConstants.millisecondsPerSecond) * TimeConstants.microsecondsPerMillisecond
      + _nanosecondsInterval ~/ TimeConstants.nanosecondsPerMicrosecond;

  int get subsecondNanoseconds =>
      arithmeticMod(_milliseconds, TimeConstants.millisecondsPerSecond) * TimeConstants.nanosecondsPerMillisecond
          + _nanosecondsInterval; // % TimeConstants.nanosecondsPerSecond;

  double get totalDays => _milliseconds / TimeConstants.millisecondsPerDay + _nanosecondsInterval / TimeConstants.nanosecondsPerDay;

  double get totalHours => _milliseconds / TimeConstants.millisecondsPerHour + _nanosecondsInterval / TimeConstants.nanosecondsPerHour;

  double get totalMinutes => _milliseconds / TimeConstants.millisecondsPerMinute + _nanosecondsInterval / TimeConstants.nanosecondsPerMinute;

  double get totalSeconds => _milliseconds / TimeConstants.millisecondsPerSecond + _nanosecondsInterval / TimeConstants.nanosecondsPerSecond;

  double get totalMilliseconds => _milliseconds + _nanosecondsInterval / TimeConstants.nanosecondsPerMillisecond;

  double get totalMicroseconds => _milliseconds * TimeConstants.microsecondsPerMillisecond + _nanosecondsInterval / TimeConstants.nanosecondsPerMicrosecond;

  int get totalNanoseconds => _milliseconds * TimeConstants.nanosecondsPerMillisecond + _nanosecondsInterval;

  BigInt get totalNanosecondsAsBigInt => BigInt.from(_milliseconds) * TimeConstants.nanosecondsPerMillisecondBigInt + BigInt.from(_nanosecondsInterval);
  // this isn't exact (since we don't look at _nanosecondsInterval, we just don't allow `==`
  bool get canNanosecondsBeInteger => _milliseconds < Platform.intMaxValue /~ TimeConstants.nanosecondsPerMillisecond && _milliseconds > Platform.intMinValue /~ TimeConstants.nanosecondsPerMillisecond;

  // totalsFloor* ???
  int get _floorSeconds => (_milliseconds / TimeConstants.millisecondsPerSecond).floor();

  @wasInternal
  // todo: make more like floorDays?
  int get floorMilliseconds => totalMilliseconds.floor();

  @wasInternal
  int get floorDays {
    var days = _milliseconds ~/ TimeConstants.millisecondsPerDay;
    // todo: determine if there are other corner-cases here
    if ((_milliseconds < 0 || (_milliseconds == 0 && _nanosecondsInterval < 0))
        && (_milliseconds % TimeConstants.millisecondsPerDay != 0 || _milliseconds == 0)) return days - 1;
    return days;
  }

  // original version shown here, very bad, rounding errors much bad -- be better than this
  // int get nanosecondOfDay => ((totalDays - days.toDouble()) * TimeConstants.nanosecondsPerDay).toInt();
  // todo: here to ease porting, unsure if this is wanted -- but it's not hurting me?
  // todo: these should work with the floorDay
  // int get nanosecondOfDay => millisecondsOfDay*TimeConstants.nanosecondsPerMillisecond + _nanosecondsInterval;
  int get millisecondsOfDay => _milliseconds - (days * TimeConstants.millisecondsPerDay);

  int get nanosecondOfFloorDay =>
      (_milliseconds - (floorDays * TimeConstants.millisecondsPerDay)) * TimeConstants.nanosecondsPerMillisecond + _nanosecondsInterval;

  // todo: this is not obvious enough that, this is probably not the method the average person wants to be calling
  int get nanosecondOfDay =>
      (_milliseconds - (days * TimeConstants.millisecondsPerDay)) * TimeConstants.nanosecondsPerMillisecond + _nanosecondsInterval;

  Time get spanOfDay => new Time._ (_milliseconds - (days * TimeConstants.millisecondsPerDay), _nanosecondsInterval);

  Time get spanOfFloorDay => new Time._ (_milliseconds - (floorDays * TimeConstants.millisecondsPerDay), _nanosecondsInterval);

  // todo: need to test that this is good -- should be
  @override get hashCode => _milliseconds.hashCode ^ _nanosecondsInterval;

  @override String toString([String patternText, Culture culture]) =>
      TimePatterns.format(this, patternText, culture);

  Time operator +(Time other) => new Time._untrusted(_milliseconds + other._milliseconds, _nanosecondsInterval + other._nanosecondsInterval);

  Time operator -(Time other) => new Time._untrusted(_milliseconds - other._milliseconds, _nanosecondsInterval - other._nanosecondsInterval);

  Time operator -() => new Time._untrusted(-_milliseconds, -_nanosecondsInterval);

  Time plus(Time other) => this + other;

  Time minus(Time other) => this - other;

  Time operator *(num factor) => new Time._untrusted(_milliseconds * factor, _nanosecondsInterval * factor);

  // Span operator*(num factor) => new Span(nanoseconds: (_milliseconds * TimeConstants.nanosecondsPerMillisecond + _nanosecondsInterval) * factor);

  // note: this is wrong'ish*
  // Span operator/(num factor) => new Span._untrusted(_milliseconds ~/ factor, _nanosecondsInterval ~/ factor);
  // note: this works on VM (because of BigInt)
  Time operator /(num factor) {
    if (canNanosecondsBeInteger) {
      return new Time(nanoseconds: (_milliseconds * TimeConstants.nanosecondsPerMillisecond + _nanosecondsInterval) ~/ factor);
    } else {
      return new Time.fromBigIntNanoseconds(totalNanosecondsAsBigInt ~/ BigInt.from(factor));
    }
  }

  // This is what it will look like in JS -- only fails 1 unit test though
  // Span operator/(num factor) => new Span(nanoseconds: ((_milliseconds * TimeConstants.nanosecondsPerMillisecond + _nanosecondsInterval) / factor).toInt());

  Time multiply(num factor) => this * factor;

  Time divide(num factor) => this / factor;

  Time _plusSmallNanoseconds(int nanoseconds) => new Time._untrusted(_milliseconds, _nanosecondsInterval + nanoseconds);

  @override
  bool operator ==(dynamic other) => other is Time && equals(other);

  bool operator >=(Time other) =>
      other == null ? true : (_milliseconds > other._milliseconds) ||
          (_milliseconds == other._milliseconds && _nanosecondsInterval >= other._nanosecondsInterval);

  bool operator <=(Time other) =>
      other == null ? false : (_milliseconds < other._milliseconds) ||
          (_milliseconds == other._milliseconds && _nanosecondsInterval <= other._nanosecondsInterval);

  bool operator >(Time other) =>
      other == null ? true : (_milliseconds > other._milliseconds) ||
          (_milliseconds == other._milliseconds && _nanosecondsInterval > other._nanosecondsInterval);

  bool operator <(Time other) => other == null ? false : (_milliseconds < other._milliseconds) ||
      (_milliseconds == other._milliseconds && _nanosecondsInterval < other._nanosecondsInterval);
  

  static Time max(Time x, Time y) => x > y ? x : y;

  static Time min(Time x, Time y) => x < y ? x : y;

  bool equals(Time other) => _milliseconds == other._milliseconds && _nanosecondsInterval == other._nanosecondsInterval;

  int compareTo(Time other) {
    if (other == null) return 1;
    int millisecondsComparison = _milliseconds.compareTo(other._milliseconds);
    return millisecondsComparison != 0 ? millisecondsComparison : _nanosecondsInterval.compareTo(other._nanosecondsInterval);
  }

  bool get _isInt64Representable {
    if (Platform.intMaxValue / TimeConstants.nanosecondsPerMillisecond < _milliseconds) {
      return false;
    }

    return true;
  }
}
