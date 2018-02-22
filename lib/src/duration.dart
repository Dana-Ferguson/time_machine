//import 'dart:core' as core show Duration;
//import 'dart:core' hide Duration;
import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'utility/preconditions.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';

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

@immutable
class Span implements Comparable<Span> {
  // todo: We're not day-based here - we could be? (I don't think it's in the cards)
  // This is 104249991 days
  @internal static const int maxDays = maxMillis ~/ TimeConstants.millisecondsPerDay; // (1 << 24) - 1;
  @internal static const int minDays = -maxDays; // ~MaxDays;

  // 285420 years worth -- we are good for anything;
  @internal static const int maxMillis = Utility.intMaxValueJS;
  @internal static const int minMillis = -maxMillis;

  // 285420 years max (unlimited on VM)
  final int _milliseconds;
  /// 0 to 999999 ~ 20 bits ~ 4 bytes on the VM
  final int _nanosecondsInterval;
  static const int _minNano = 0;
  static const int _maxNano = TimeConstants.nanosecondsPerMillisecond - 1; // 999999;

  // this is only true on the VM....
  // static final Duration maxValue = new Duration._trusted(9007199254740992, 999999);

  static final Span zero = new Span._trusted(0);
  /// Gets a [Span] value equal to 1 nanosecond; the smallest amount by which an instant can vary.
  static final Span epsilon = new Span._trusted(0, 1);

  /// Gets the maximum value supported by [Span]. (todo: is this okay for us? -- after the integer math on that division ... maybe??? maybe not???)
  static Span maxValue = new Span(days: maxDays, nanoseconds: TimeConstants.nanosecondsPerDay - 1);

  /// Gets the minimum (largest negative) value supported by [Span].
  static Span minValue = new Span(days: minDays);

  Span._trusted(this._milliseconds, [this._nanosecondsInterval = 0]);

  factory Span._untrusted(int milliseconds, [int nanoseconds = 0]) {
    if (nanoseconds >= _minNano && nanoseconds <= _maxNano) return new Span._trusted(milliseconds, nanoseconds);

    if (nanoseconds < _minNano) {
      // newNS = ns + TimeConstants.nanosecondsPerMillisecond * n;
      // _minNano < ns <= _maxNano => ns > _minNano
      var delta = ((_minNano - nanoseconds) / TimeConstants.nanosecondsPerMillisecond).ceil();
      nanoseconds = nanoseconds + TimeConstants.nanosecondsPerMillisecond * delta;
      milliseconds = milliseconds - delta;
      return new Span._trusted(milliseconds, nanoseconds);
    }

    if (nanoseconds >= _maxNano) {
      var delta = ((nanoseconds - _maxNano) / TimeConstants.nanosecondsPerMillisecond).floor();
      nanoseconds = nanoseconds - TimeConstants.nanosecondsPerMillisecond * delta;
      milliseconds = milliseconds + delta;
      return new Span._trusted(milliseconds, nanoseconds);
    }

    // todo: custom errors
    throw new ArgumentError.notNull('Checked duration failure: milliseconds = $milliseconds, nanoseconds = $nanoseconds;');
    // return new Duration._trusted(milliseconds, 0);
  }

  factory Span({int days = 0, int hours = 0, int minutes = 0, int seconds = 0,
    int milliseconds = 0, int microseconds = 0, int ticks = 0, int nanoseconds = 0}) {

    milliseconds += days * TimeConstants.millisecondsPerDay;
    milliseconds += hours * TimeConstants.millisecondsPerHour;
    milliseconds += minutes * TimeConstants.millisecondsPerMinute;
    milliseconds += seconds * TimeConstants.millisecondsPerSecond;

    nanoseconds += microseconds * TimeConstants.nanosecondsPerMicrosecond;
    nanoseconds += ticks * TimeConstants.nanosecondsPerTick;

    return new Span._untrusted(milliseconds, nanoseconds);
  }

  // todo: should these be the default constructor?
  factory Span.complex({num days = 0, num hours = 0, num minutes = 0, num seconds = 0,
    num milliseconds = 0, num microseconds = 0, num ticks = 0, num nanoseconds = 0}) {

    int _days = days.floor();
    int _hours = hours.floor();
    int _minutes = minutes.floor();
    int _seconds = seconds.floor();
    int _milliseconds = milliseconds.floor();

    milliseconds += _days * TimeConstants.millisecondsPerDay;
    milliseconds += _hours * TimeConstants.millisecondsPerHour;
    milliseconds += _minutes * TimeConstants.millisecondsPerMinute;
    milliseconds += _seconds * TimeConstants.millisecondsPerSecond;

    nanoseconds += (microseconds * TimeConstants.nanosecondsPerMicrosecond).round();
    nanoseconds += (ticks * TimeConstants.nanosecondsPerTick).round();

    nanoseconds += ((days - _days) * TimeConstants.nanosecondsPerDay).round();
    nanoseconds += ((hours - _hours) * TimeConstants.nanosecondsPerDay).round();
    nanoseconds += ((minutes - _minutes) * TimeConstants.nanosecondsPerDay).round();
    nanoseconds += ((seconds - _seconds) * TimeConstants.nanosecondsPerDay).round();
    nanoseconds += ((milliseconds - _milliseconds) * TimeConstants.nanosecondsPerMillisecond).round();

    return new Span._untrusted(milliseconds, nanoseconds);
  }

  Span.fromDuration(Duration duration) :
      _milliseconds = duration.inMilliseconds,
      _nanosecondsInterval = TimeConstants.nanosecondsPerMicrosecond
          * (duration.inMicroseconds - duration.inMilliseconds * TimeConstants.microsecondsPerMillisecond)
  ;

  // https://www.dartlang.org/guides/language/effective-dart/design#prefer-naming-a-method-to___-if-it-copies-the-objects-state-to-a-new-object
  Duration get toDuration => new Duration(
      microseconds: milliseconds * TimeConstants.microsecondsPerMillisecond
          + _nanosecondsInterval ~/ TimeConstants.nanosecondsPerMicrosecond);

  // todo: I feel like the naming here is not consistent enough (but this is consistent with Nodatime)
  // todo: yeah -- look at this shit, days are so f'n different, I don't think it's obvious (maybe, hours --> hourOfDay or something like that ~ which is really weird to be in [Span] anyway?)
  // todo: I put in days as FloorDays a lot ~ which is fine until you go negative ~ then all of this acts wrong (I think for all of it - I want to do a check
  //  where I use floor() if it's negative) .. or does the VM basically already cover that.
  int get days => (_milliseconds ~/ TimeConstants.millisecondsPerDay);
  int get hours => (_milliseconds ~/ TimeConstants.millisecondsPerHour) % TimeConstants.hoursPerDay;
  int get minutes => (_milliseconds ~/ TimeConstants.millisecondsPerMinute) % TimeConstants.minutesPerHour;
  int get seconds => (_milliseconds ~/ TimeConstants.millisecondsPerSecond) % TimeConstants.secondsPerMinute;
  int get milliseconds => _milliseconds % TimeConstants.millisecondsPerDay;
  // microseconds?
  int get subsecondTicks => (_nanosecondsInterval ~/ TimeConstants.nanosecondsPerTick) % TimeConstants.ticksPerSecond;
  int get subsecondNanoseconds => _nanosecondsInterval % TimeConstants.nanosecondsPerSecond;

  double get totalDays => _milliseconds / TimeConstants.millisecondsPerDay + _nanosecondsInterval / TimeConstants.nanosecondsPerDay;
  double get totalHours => _milliseconds / TimeConstants.millisecondsPerHour + _nanosecondsInterval / TimeConstants.nanosecondsPerHour;
  double get totalMinutes => _milliseconds / TimeConstants.millisecondsPerMinute + _nanosecondsInterval / TimeConstants.nanosecondsPerMinute;
  double get totalSeconds => _milliseconds / TimeConstants.millisecondsPerSecond + _nanosecondsInterval / TimeConstants.nanosecondsPerSecond;
  double get totalMilliseconds => _milliseconds + _nanosecondsInterval / TimeConstants.nanosecondsPerMillisecond;
  double get totalMicroseconds => _milliseconds * TimeConstants.microsecondsPerMillisecond + _nanosecondsInterval / TimeConstants.nanosecondsPerMicrosecond;
  double get totalTicks => _milliseconds * TimeConstants.ticksPerMillisecond + _nanosecondsInterval / TimeConstants.nanosecondsPerTick;
  int get totalNanoseconds => _milliseconds * TimeConstants.nanosecondsPerMillisecond + _nanosecondsInterval;

  // todo: here to ease porting, unsure if this is wanted -- but it's not hurting me?
  int get nanosecondOfDay => ((totalDays - days.toDouble()) * TimeConstants.nanosecondsPerDay).toInt();

  // todo: need to test that this is good -- should be
  @override get hashCode => _milliseconds.hashCode ^ _nanosecondsInterval;

  // todo: we need a good formatting story -- work with (or be compatible with DateFormat class)
  @override toString() => '$totalSeconds seconds';

  Span operator+(Span other) => new Span._untrusted(_milliseconds + other._milliseconds, _nanosecondsInterval + other._nanosecondsInterval);
  Span operator-(Span other) => new Span._untrusted(_milliseconds - other._milliseconds, _nanosecondsInterval - other._nanosecondsInterval);

  Span plus(Span other) => this + other;
  Span minus(Span other) => this - other;

  Span operator*(num factor) => new Span._untrusted(_milliseconds * factor, _nanosecondsInterval * factor);
  Span operator/(num factor) => new Span._untrusted(_milliseconds ~/ factor, _nanosecondsInterval ~/ factor);

  Span multiply(num factor) => this * factor;
  Span divide(num factor) => this / factor;

  Span plusSmallNanoseconds(int nanoseconds) => new Span._untrusted(_milliseconds, _nanosecondsInterval + nanoseconds);

  @override
  bool operator==(dynamic other) => other is Span && equals(other);
  bool operator >=(Span other) => (other._milliseconds > _milliseconds) ||
      (other._milliseconds == _milliseconds && other._nanosecondsInterval >= _nanosecondsInterval);
  bool operator <=(Span other) => (other._milliseconds < _milliseconds) ||
      (other._milliseconds == _milliseconds && other._nanosecondsInterval <= _nanosecondsInterval);
  bool operator >(Span other) => (other._milliseconds > _milliseconds) ||
      (other._milliseconds == _milliseconds && other._nanosecondsInterval > _nanosecondsInterval);
  bool operator <(Span other) => (other._milliseconds < _milliseconds) ||
      (other._milliseconds == _milliseconds && other._nanosecondsInterval < _nanosecondsInterval);

  bool equals(Span other) => _milliseconds == other._milliseconds && _nanosecondsInterval == other._nanosecondsInterval;

  int compareTo(Span other) {
    int millisecondsComparison = _milliseconds.compareTo(other._milliseconds);
    return millisecondsComparison != 0 ? millisecondsComparison : _nanosecondsInterval.compareTo(other._nanosecondsInterval);
  }

  bool get IsInt64Representable {
    if (Utility.intMaxValue / TimeConstants.nanosecondsPerMillisecond < _milliseconds) {
      return false;
    }

    return true;
  }

}