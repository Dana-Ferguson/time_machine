// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
// import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

/// Options to use when comparing time zones for equality. Each option makes the comparison more restrictive.
///
/// By default, the comparer only compares the wall offset (total of standard offset and any daylight saving offset)
/// at every instant within the interval over which the comparer operates. In practice, this is done by comparing each
/// [ZoneInterval] which includes an instant within the interval (using [DateTimeZone.getZoneIntervals(Interval)]).
/// For most purposes, this is all that's required: from the simple perspective of a time zone being just a function from instants to local time,
/// the default option of [onlyMatchWallOffset] effectively checks that the function gives the same result across the two time
/// zones being compared, for any given instant within the interval.
///
/// It's possible for a time zone to have a transition from one `ZoneInterval` to another which doesn't adjust the offset: it
/// might just change the name, or the balance between standard offset to daylight saving offset. (As an example, at midnight local
/// time on October 27th 1968, the Europe/London time zone went from a standard offset of 0 and a daylight saving offset of 1 hour
/// to a standard offset of 1 and a daylight saving offset of 0... which left the clocks unchanged.) This transition is irrelevant
/// to the default options, so the two zone intervals involved are effectively coalesced.
///
/// The options available change what sort of comparison is performed - which can also change which zone intervals can be coalesced. For
/// example, by specifying just the [matchAllTransitions] option, you would indicate that even though you don't care about the name within a zone
/// interval or how the wall offset is calculated, you do care about the fact that there was a transition at all, and when it occurred.
/// With that option enabled, zone intervals are never coalesced and the transition points within the operating interval are checked.
///
/// Similarly, the [matchStartAndEndTransitions] option is the only one where instants outside the operating interval are
/// relevant. For example, consider a comparer which operates over the interval [2000-01-01T00:00:00Z, 2011-01-01T00:00:00Z). Normally,
/// anything that happens before the year 2000 (UTC) would be irrelevant - but with this option enabled, the transitions of the first and last zone
/// intervals are part of the comparison... so if one time zone has a zone interval 1999-09-01T00:00:00Z to 2000-03-01T00:00:00Z and the other has
/// a zone interval 1999-10-15T00:00:00Z to 2000-03-01T00:00:Z, the two zones would be considered unequal, despite the fact that the only instants observing
/// the difference occur outside the operating interval.
@immutable
class ZoneEqualityComparerOptions {
  final int _value;

  int get value => _value;

  static const List<String> _stringRepresentations = [
    'OnlyMatchWallOffset', 'MatchOffsetComponents', 'MatchNames',
    'MatchAllTransitions', 'MatchStartAndEndTransitions', 'StrictestMatch'
  ];

  static const List<ZoneEqualityComparerOptions> _isoConstants = [
    onlyMatchWallOffset, matchOffsetComponents, matchNames,
    matchAllTransitions, matchStartAndEndTransitions, strictestMatch
  ];

  // todo: look at: Constants --> Strings; and then maybe Strings --> Constants ~ but the strings wrapped in a class that doesn't care about case
  //  they'd be really convenient for mask enumerations
  static final Map<ZoneEqualityComparerOptions, String> _nameMap = {
    onlyMatchWallOffset: 'OnlyMatchWallOffset', matchOffsetComponents: 'MatchOffsetComponents', matchNames: 'MatchNames',
    matchAllTransitions: 'MatchAllTransitions', matchStartAndEndTransitions: 'MatchStartAndEndTransitions', strictestMatch: 'StrictestMatch',
  };

  /// The default comparison, which only cares about the wall offset at any particular
  /// instant, within the interval of the comparer. In other words, if [DateTimeZone.getUtcOffset]
  /// returns the same value for all instants in the interval, the comparer will consider the zones to be equal.
  static const ZoneEqualityComparerOptions onlyMatchWallOffset = ZoneEqualityComparerOptions(0);
  /// Instead of only comparing wall offsets, the standard/savings split is also considered. So when this
  /// option is used, two zones which both have a wall offset of +2 at one instant would be considered
  /// unequal if one of those offsets was +1 standard, +1 savings and the other was +2 standard with no daylight
  /// saving.
  static const ZoneEqualityComparerOptions matchOffsetComponents = ZoneEqualityComparerOptions(1 << 0);
  /// Compare the names of zone intervals as well as offsets.
  static const ZoneEqualityComparerOptions matchNames = ZoneEqualityComparerOptions(1 << 1);
  /// This option prevents adjacent zone intervals from being coalesced, even if they are otherwise considered
  /// equivalent according to other options.
  static const ZoneEqualityComparerOptions matchAllTransitions = ZoneEqualityComparerOptions(1 << 2);
  /// Includes the transitions into the first zone interval and out of the
  /// last zone interval as part of the comparison, even if they do not affect
  /// the offset or name for any instant within the operating interval.
  static const ZoneEqualityComparerOptions matchStartAndEndTransitions = ZoneEqualityComparerOptions(1 << 3);
  /// The combination of all available match options.
  static const ZoneEqualityComparerOptions strictestMatch = ZoneEqualityComparerOptions(0 | 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3);

  @override int get hashCode => _value.hashCode;
  @override bool operator ==(Object other) => other is ZoneEqualityComparerOptions && other._value == _value || other is int && other == _value;

  const ZoneEqualityComparerOptions(this._value);

  bool operator <(ZoneEqualityComparerOptions other) => _value < other._value;
  bool operator <=(ZoneEqualityComparerOptions other) => _value <= other._value;
  bool operator >(ZoneEqualityComparerOptions other) => _value > other._value;
  bool operator >=(ZoneEqualityComparerOptions other) => _value >= other._value;

  int operator -(ZoneEqualityComparerOptions other) => _value - other._value;
  int operator +(ZoneEqualityComparerOptions other) => _value + other._value;

  // todo: I feel like dynamic dispatch like this is *very* dangerous
  ZoneEqualityComparerOptions operator &(dynamic other) =>
      other is ZoneEqualityComparerOptions ? ZoneEqualityComparerOptions(_value & other._value)
          : other is int ? ZoneEqualityComparerOptions(_value & other)
          : throw ArgumentError('Must be either Options or int.');
  ZoneEqualityComparerOptions operator |(dynamic other) =>
      other is ZoneEqualityComparerOptions ? ZoneEqualityComparerOptions(_value | other._value)
          : other is int ? ZoneEqualityComparerOptions(_value | other)
          : throw ArgumentError('Must be either Options or int.');
  int operator ~() => ~_value;

  @override
  String toString() => _nameMap[this] ?? 'undefined';

  ZoneEqualityComparerOptions? parse(String text) {
    var token = text.trim().toLowerCase();
    for (int i = 0; i < _stringRepresentations.length; i++) {
      if (stringOrdinalIgnoreCaseEquals(_stringRepresentations[i], token)) return _isoConstants[i];
    }

    return null;
  }

  // todo: there is probably a more friendly way to incorporate this for mask usage -- so we can have friendly defined constants above
  static ZoneEqualityComparerOptions union(Iterable<ZoneEqualityComparerOptions> units) {
    int i = 0;
    units.forEach((u) => i = i|u._value);
    return ZoneEqualityComparerOptions(i);
  }
}

/// Checks whether the given set of options includes the candidate one. This would be an extension method, but
/// that causes problems on Mono at the moment.
bool _checkOption(ZoneEqualityComparerOptions options, ZoneEqualityComparerOptions candidate)
{
  return (options & candidate).value != 0;
}

@internal
abstract class IZoneEqualityComparer {
  /// Returns the interval over which this comparer operates.
  @visibleForTesting
  static Interval intervalForTest(ZoneEqualityComparer zoneEqualityComparer) => zoneEqualityComparer._interval;
  /// Returns the options used by this comparer.
  @visibleForTesting
  static ZoneEqualityComparerOptions optionsForTest(ZoneEqualityComparer zoneEqualityComparer) => zoneEqualityComparer._options;
}

/// Equality comparer for time zones, comparing specific aspects of the zone intervals within
/// a time zone for a specific interval of the time line.
///
/// The default behaviour of this comparator is to consider two time zones to be equal if they share the same wall
/// offsets at all points within a given time interval, regardless of other aspects of each
/// [ZoneInterval] within the two time zones. This behaviour can be changed using the
/// [withOptions] method.
@immutable
class ZoneEqualityComparer {

  final Interval _interval;
  final ZoneEqualityComparerOptions _options;

  final ZoneIntervalEqualityComparer _zoneIntervalComparer;

  /// Creates a new comparer for the given interval, with the given comparison options.
  ///
  /// [interval]: The interval within the time line to use for comparisons.
  /// [options]: The options to use when comparing time zones.
  /// [ArgumentOutOfRangeException]: The specified options are invalid.
  ZoneEqualityComparer._(this._interval, this._options) : _zoneIntervalComparer = ZoneIntervalEqualityComparer(_options, _interval) {
    if ((_options & ~ZoneEqualityComparerOptions.strictestMatch).value != 0) {
      throw ArgumentError('The value $_options is not defined within ZoneEqualityComparer.Options');
    }
  }

  /// Returns a [ZoneEqualityComparer] for the given interval with the default options.
  ///
  /// The default behaviour of this comparator is to consider two time zones to be equal if they share the same wall
  /// offsets at all points within a given interval.
  /// To specify non-default options, call the [withOptions] method on the result
  /// of this method.
  /// [interval]: The interval over which to compare time zones. This must have both a start and an end.
  /// Returns: A ZoneEqualityComparer for the given interval with the default options.
  factory ZoneEqualityComparer.forInterval(Interval interval) {
    Preconditions.checkArgument(interval.hasStart && interval.hasEnd, 'interval',
        'The interval must have both a start and an end.');
    return ZoneEqualityComparer._(interval, ZoneEqualityComparerOptions.onlyMatchWallOffset);
  }

  /// Returns a comparer operating over the same interval as this one, but with the given
  /// set of options.
  ///
  /// This method does not modify the comparer on which it's called.
  ///
  /// [options]: New set of options, which must consist of flags defined within the [Options] enum.
  /// [ArgumentOutOfRangeException]: The specified options are invalid.
  /// Returns: A comparer operating over the same interval as this one, but with the given set of options.
  ZoneEqualityComparer withOptions(ZoneEqualityComparerOptions options) {
    return _options == options ? this : ZoneEqualityComparer._(_interval, options);
  }

  /// Compares two time zones for equality according to the options and interval provided to this comparer.
  ///
  /// [x]: The first [DateTimeZone] to compare.
  /// [y]: The second [DateTimeZone] to compare.
  /// Returns: `true` if the specified time zones are equal under the options and interval of this comparer; otherwise, `false`.
  bool equals(DateTimeZone x, DateTimeZone y) {
    if (identical(x, y)) {
      return true;
    }

    if (x == y) {
      return true;
    }

    // If we ever need to port this to a platform which doesn't support LINQ,
    // we'll need to reimplement this. Until then, it would seem pointless...
    // Dart: that day is TODAY! todo: is this inefficient?
    var ax = _getIntervals(x); //.toList(growable: false);
    var by = _getIntervals(y); //.toList(growable: false);
    // Need a way to know if length can be efficiently computed or not
    // if (ax.length != by.length) return false;

    var a = ax.iterator;
    var b = by.iterator;
    // if (a.length != b.length) return false;
    //    while(a.moveNext() || b.moveNext()) {
    //      if (a.current == null || b.current == null) return false;
    //      if (!zoneIntervalComparer.Equals(a.current, b.current)) return false;
    //    }

    while (a.moveNext())
    {
      if (!b.moveNext() || !_zoneIntervalComparer.equals(a.current, b.current))
        return false;
    }
    return !b.moveNext();

    // return true;
    // return GetIntervals(x).SequenceEqual(GetIntervals(y), zoneIntervalComparer);
  }

  /// Returns a hash code for the specified time zone.
  ///
  /// The hash code generated by any instance of [ZoneEqualityComparer] will be equal to the hash code
  /// generated by any other instance constructed with the same options and interval, for the same time zone (or equal ones).
  /// Two instances of [ZoneEqualityComparer] with different options or intervals may (but may not) produce
  /// different hash codes for the same zone.
  ///
  /// [obj]: The time zone to compute a hash code for.
  /// Returns: A hash code for the specified object.
  int getHashCode(DateTimeZone obj) {
    Preconditions.checkNotNull(obj, 'obj');
    return hashObjects(
        _getIntervals(obj)
            .map((zoneInterval) => _zoneIntervalComparer.getHashCode(zoneInterval))
    );
  }

  Iterable<ZoneInterval> _getIntervals(DateTimeZone zone) {
    var allIntervals = zone.getZoneIntervals(Interval(_interval.start, _interval.end));
    return _checkOption(_options, ZoneEqualityComparerOptions.matchAllTransitions) ? allIntervals : _zoneIntervalComparer.coalesceIntervals(allIntervals);
  }
}

@internal
class ZoneIntervalEqualityComparer {
  final ZoneEqualityComparerOptions _options;
  final Interval _interval;

  ZoneIntervalEqualityComparer(this._options, this._interval);

  Iterable<ZoneInterval> coalesceIntervals(Iterable<ZoneInterval> zoneIntervals) sync*
  {
    ZoneInterval? current;
    for (var zoneInterval in zoneIntervals) {
      if (current == null) {
        current = zoneInterval;
        continue;
      }
      if (_equalExceptStartAndEnd(current, zoneInterval)) {
        current = IZoneInterval.withEnd(current, IZoneInterval.rawEnd(zoneInterval));
      }
      else {
        yield current;
        current = zoneInterval;
      }
    }
    // current will only be null if start == end...
    if (current != null) {
      yield current;
    }
  }

  bool equals(ZoneInterval x, ZoneInterval y) {
    if (!_equalExceptStartAndEnd(x, y)) {
      return false;
    }
    return _getEffectiveStart(x) == _getEffectiveStart(y) &&
        _getEffectiveEnd(x) == _getEffectiveEnd(y);
  }

  int getHashCode(ZoneInterval obj) {
    List hashables = [_getEffectiveStart(obj), _getEffectiveEnd(obj)];
    if (_checkOption(_options, ZoneEqualityComparerOptions.matchOffsetComponents)) {
      hashables.addAll([obj.standardOffset, obj.savings]);
    }
    else {
      hashables.add(obj.wallOffset);
    }
    if (_checkOption(_options, ZoneEqualityComparerOptions.matchNames)) {
      hashables.add(obj.name);
    }

    return hashObjects(hashables);
  }

  Instant _getEffectiveStart(ZoneInterval zoneInterval) =>
      _checkOption(_options, ZoneEqualityComparerOptions.matchStartAndEndTransitions)
          ? IZoneInterval.rawStart(zoneInterval) : Instant.max(IZoneInterval.rawStart(zoneInterval), _interval.start);

  Instant _getEffectiveEnd(ZoneInterval zoneInterval) =>
      _checkOption(_options, ZoneEqualityComparerOptions.matchStartAndEndTransitions)
          ? IZoneInterval.rawEnd(zoneInterval) : Instant.min(IZoneInterval.rawEnd(zoneInterval), _interval.end);

  /// Compares the parts of two zone intervals which are deemed 'interesting' by the options.
  /// The wall offset is always compared, regardless of options, but the start/end points are
  /// never compared.
  bool _equalExceptStartAndEnd(ZoneInterval x, ZoneInterval y) {
    if (x.wallOffset != y.wallOffset) {
      return false;
    }
    // As we've already compared wall offsets, we only need to compare savings...
    // If the savings are equal, the standard offset will be too.
    if (_checkOption(_options, ZoneEqualityComparerOptions.matchOffsetComponents) && x.savings != y.savings) {
      return false;
    }
    if (_checkOption(_options, ZoneEqualityComparerOptions.matchNames) && x.name != y.name) {
      return false;
    }
    return true;
  }
}

