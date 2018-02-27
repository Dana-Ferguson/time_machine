// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/ZoneEqualityComparer.cs
// 24fdeef  on Apr 10, 2017

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

/// <summary>
/// Options to use when comparing time zones for equality. Each option makes the comparison more restrictive.
/// </summary>
/// <remarks>
/// <para>
/// By default, the comparer only compares the wall offset (total of standard offset and any daylight saving offset)
/// at every instant within the interval over which the comparer operates. In practice, this is done by comparing each
/// <see cref="ZoneInterval"/> which includes an instant within the interval (using <see cref="DateTimeZone.GetZoneIntervals(Interval)"/>).
/// For most purposes, this is all that's required: from the simple perspective of a time zone being just a function from instants to local time,
/// the default option of <see cref="OnlyMatchWallOffset"/> effectively checks that the function gives the same result across the two time
/// zones being compared, for any given instant within the interval.
/// </para>
/// <para>
/// It's possible for a time zone to have a transition from one <c>ZoneInterval</c> to another which doesn't adjust the offset: it
/// might just change the name, or the balance between standard offset to daylight saving offset. (As an example, at midnight local
/// time on October 27th 1968, the Europe/London time zone went from a standard offset of 0 and a daylight saving offset of 1 hour
/// to a standard offset of 1 and a daylight saving offset of 0... which left the clocks unchanged.) This transition is irrelevant
/// to the default options, so the two zone intervals involved are effectively coalesced.
/// </para>
/// <para>
/// The options available change what sort of comparison is performed - which can also change which zone intervals can be coalesced. For
/// example, by specifying just the <see cref="MatchAllTransitions"/> option, you would indicate that even though you don't care about the name within a zone
/// interval or how the wall offset is calculated, you do care about the fact that there was a transition at all, and when it occurred.
/// With that option enabled, zone intervals are never coalesced and the transition points within the operating interval are checked.
/// </para>
/// <para>Similarly, the <see cref="MatchStartAndEndTransitions"/> option is the only one where instants outside the operating interval are
/// relevant. For example, consider a comparer which operates over the interval [2000-01-01T00:00:00Z, 2011-01-01T00:00:00Z). Normally,
/// anything that happens before the year 2000 (UTC) would be irrelevant - but with this option enabled, the transitions of the first and last zone
/// intervals are part of the comparison... so if one time zone has a zone interval 1999-09-01T00:00:00Z to 2000-03-01T00:00:00Z and the other has
/// a zone interval 1999-10-15T00:00:00Z to 2000-03-01T00:00:Z, the two zones would be considered unequal, despite the fact that the only instants observing
/// the difference occur outside the operating interval.
/// </para>
/// </remarks>
@immutable
class ZoneEqualityComparerOptions {
  final int _value;

  int get value => _value;

  static const List<String> _stringRepresentations = const [
    'OnlyMatchWallOffset', 'MatchOffsetComponents', 'MatchNames',
    'MatchAllTransitions', 'MatchStartAndEndTransitions', 'StrictestMatch'
  ];

  static const List<ZoneEqualityComparerOptions> _isoConstants = const [
    OnlyMatchWallOffset, MatchOffsetComponents, MatchNames,
    MatchAllTransitions, MatchStartAndEndTransitions, StrictestMatch
  ];

  // todo: look at: Constants --> Strings; and then maybe Strings --> Constants ~ but the strings wrapped in a class that doesn't care about case
  //  they'd be really convenient for mask enumerations
  static final Map<ZoneEqualityComparerOptions, String> _nameMap = {
    OnlyMatchWallOffset: 'OnlyMatchWallOffset', MatchOffsetComponents: 'MatchOffsetComponents', MatchNames: 'MatchNames',
    MatchAllTransitions: 'MatchAllTransitions', MatchStartAndEndTransitions: 'MatchStartAndEndTransitions', StrictestMatch: 'StrictestMatch',
  };

  /// The default comparison, which only cares about the wall offset at any particular
  /// instant, within the interval of the comparer. In other words, if <see cref="DateTimeZone.GetUtcOffset"/>
  /// returns the same value for all instants in the interval, the comparer will consider the zones to be equal.
  static const ZoneEqualityComparerOptions OnlyMatchWallOffset = const ZoneEqualityComparerOptions(0);
  /// Instead of only comparing wall offsets, the standard/savings split is also considered. So when this
  /// option is used, two zones which both have a wall offset of +2 at one instant would be considered
  /// unequal if one of those offsets was +1 standard, +1 savings and the other was +2 standard with no daylight
  /// saving.
  static const ZoneEqualityComparerOptions MatchOffsetComponents = const ZoneEqualityComparerOptions(1 << 0);
  /// Compare the names of zone intervals as well as offsets.
  static const ZoneEqualityComparerOptions MatchNames = const ZoneEqualityComparerOptions(1 << 1);
  /// This option prevents adjacent zone intervals from being coalesced, even if they are otherwise considered
  /// equivalent according to other options.
  static const ZoneEqualityComparerOptions MatchAllTransitions = const ZoneEqualityComparerOptions(1 << 2);
  /// Includes the transitions into the first zone interval and out of the
  /// last zone interval as part of the comparison, even if they do not affect
  /// the offset or name for any instant within the operating interval.
  static const ZoneEqualityComparerOptions MatchStartAndEndTransitions = const ZoneEqualityComparerOptions(1 << 3);
  /// The combination of all available match options.
  static const ZoneEqualityComparerOptions StrictestMatch = const ZoneEqualityComparerOptions(0 | 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3);

  @override get hashCode => _value.hashCode;
  @override operator ==(dynamic other) => other is ZoneEqualityComparerOptions && other._value == _value || other is int && other == _value;

  const ZoneEqualityComparerOptions(this._value);

  bool operator <(ZoneEqualityComparerOptions other) => _value < other._value;
  bool operator <=(ZoneEqualityComparerOptions other) => _value <= other._value;
  bool operator >(ZoneEqualityComparerOptions other) => _value > other._value;
  bool operator >=(ZoneEqualityComparerOptions other) => _value >= other._value;

  int operator -(ZoneEqualityComparerOptions other) => _value - other._value;
  int operator +(ZoneEqualityComparerOptions other) => _value + other._value;

  // todo: I feel like dynamic dispatch like this is *very* dangerous
  int operator &(dynamic other) => other is ZoneEqualityComparerOptions ? _value & other._value : other is int ? _value & other : throw new ArgumentError('Must be either Options or int.');
  int operator ~() => ~_value;

  @override
  String toString() => _nameMap[this] ?? 'undefined';

  ZoneEqualityComparerOptions parse(String text) {
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
    return new ZoneEqualityComparerOptions(i);
  }
}

/// <summary>
/// Checks whether the given set of options includes the candidate one. This would be an extension method, but
/// that causes problems on Mono at the moment.
/// </summary>
bool _checkOption(ZoneEqualityComparerOptions options, ZoneEqualityComparerOptions candidate)
{
return (options & candidate) != 0;
}

/// <summary>
/// Equality comparer for time zones, comparing specific aspects of the zone intervals within
/// a time zone for a specific interval of the time line.
/// </summary>
/// <remarks>
/// The default behaviour of this comparator is to consider two time zones to be equal if they share the same wall
/// offsets at all points within a given time interval, regardless of other aspects of each
/// <see cref="ZoneInterval"/> within the two time zones. This behaviour can be changed using the
/// <see cref="WithOptions"/> method.
/// </remarks>
@immutable
/*sealed*/ class ZoneEqualityComparer // : IEqualityComparer<DateTimeZone>
    {

  @private final Interval interval;
  @private final ZoneEqualityComparerOptions options;

  /// <summary>
  /// Returns the interval over which this comparer operates.
  /// </summary>
  @visibleForTesting
  @internal
  Interval get IntervalForTest => interval;

  /// <summary>
  /// Returns the options used by this comparer.
  /// </summary>
  @visibleForTesting
  @internal
  ZoneEqualityComparerOptions get OptionsForTest => options;

  @private final ZoneIntervalEqualityComparer zoneIntervalComparer;

  /// <summary>
  /// Creates a new comparer for the given interval, with the given comparison options.
  /// </summary>
  /// <param name="interval">The interval within the time line to use for comparisons.</param>
  /// <param name="options">The options to use when comparing time zones.</param>
  /// <exception cref="ArgumentOutOfRangeException">The specified options are invalid.</exception>
  @private ZoneEqualityComparer(this.interval, this.options) : zoneIntervalComparer = new ZoneIntervalEqualityComparer(options, interval) {
    if ((options & ~ZoneEqualityComparerOptions.StrictestMatch) != 0) {
      throw new ArgumentError("The value $options is not defined within ZoneEqualityComparer.Options");
    }
  }

  /// <summary>
  /// Returns a <see cref="ZoneEqualityComparer"/> for the given interval with the default options.
  /// </summary>
  /// <remarks>
  /// The default behaviour of this comparator is to consider two time zones to be equal if they share the same wall
  /// offsets at all points within a given interval.
  /// To specify non-default options, call the <see cref="WithOptions"/> method on the result
  /// of this method.</remarks>
  /// <param name="interval">The interval over which to compare time zones. This must have both a start and an end.</param>
  /// <returns>A ZoneEqualityComparer for the given interval with the default options.</returns>
  static ZoneEqualityComparer ForInterval(Interval interval) {
    Preconditions.checkArgument(interval.HasStart && interval.HasEnd, 'interval',
        "The interval must have both a start and an end.");
    return new ZoneEqualityComparer(interval, ZoneEqualityComparerOptions.OnlyMatchWallOffset);
  }

  /// <summary>
  /// Returns a comparer operating over the same interval as this one, but with the given
  /// set of options.
  /// </summary>
  /// <remarks>
  /// This method does not modify the comparer on which it's called.
  /// </remarks>
  /// <param name="options">New set of options, which must consist of flags defined within the <see cref="Options"/> enum.</param>
  /// <exception cref="ArgumentOutOfRangeException">The specified options are invalid.</exception>
  /// <returns>A comparer operating over the same interval as this one, but with the given set of options.</returns>
  ZoneEqualityComparer WithOptions(ZoneEqualityComparerOptions options) {
    return this.options == options ? this : new ZoneEqualityComparer(this.interval, options);
  }

  /// <summary>
  /// Compares two time zones for equality according to the options and interval provided to this comparer.
  /// </summary>
  /// <param name="x">The first <see cref="DateTimeZone"/> to compare.</param>
  /// <param name="y">The second <see cref="DateTimeZone"/> to compare.</param>
  /// <returns><c>true</c> if the specified time zones are equal under the options and interval of this comparer; otherwise, <c>false</c>.</returns>
  bool Equals(DateTimeZone x, DateTimeZone y) {
    // todo: unsure what do do about these
//  if (ReferenceEquals(x, y))
//  {
//    return true;
//  }

    if (x == null || y == null) {
      return false;
    }

    // If we ever need to port this to a platform which doesn't support LINQ,
    // we'll need to reimplement this. Until then, it would seem pointless...
    // Dart: that day is TODAY!
    var a = GetIntervals(x).iterator;
    var b = GetIntervals(y).iterator;
    // if (a.length != b.length) return false;
    while(a.moveNext() || b.moveNext()) {
      if (a.current == null || b.current == null) return false;
      if (!zoneIntervalComparer.Equals(a.current, b.current)) return false;
    }

    return true;
    // return GetIntervals(x).SequenceEqual(GetIntervals(y), zoneIntervalComparer);
  }

  /// <summary>
  /// Returns a hash code for the specified time zone.
  /// </summary>
  /// <remarks>
  /// The hash code generated by any instance of <c>ZoneEqualityComparer</c> will be equal to the hash code
  /// generated by any other instance constructed with the same options and interval, for the same time zone (or equal ones).
  /// Two instances of <c>ZoneEqualityComparer</c> with different options or intervals may (but may not) produce
  /// different hash codes for the same zone.
  /// </remarks>
  /// <param name="obj">The time zone to compute a hash code for.</param>
  /// <returns>A hash code for the specified object.</returns>
  int GetHashCode(DateTimeZone obj) {
    Preconditions.checkNotNull(obj, 'obj');
    return hashObjects(GetIntervals(obj).map((i) => zoneIntervalComparer.GetHashCode(i)));
  }

  @private Iterable<ZoneInterval> GetIntervals(DateTimeZone zone) {
    var allIntervals = zone.getZoneIntervals(new Interval(interval.Start, interval.End));
    return _checkOption(options, ZoneEqualityComparerOptions.MatchAllTransitions) ? allIntervals : zoneIntervalComparer.CoalesceIntervals(allIntervals);
  }
}

@internal /*sealed*/ class ZoneIntervalEqualityComparer // : IEqualityComparer<ZoneInterval>
    {
  @private final ZoneEqualityComparerOptions options;
  @private final Interval interval;

  @internal ZoneIntervalEqualityComparer(this.options, this.interval);

  @internal Iterable<ZoneInterval> CoalesceIntervals(Iterable<ZoneInterval> zoneIntervals) sync*
  {
    ZoneInterval current = null;
    for (var zoneInterval in zoneIntervals) {
      if (current == null) {
        current = zoneInterval;
        continue;
      }
      if (EqualExceptStartAndEnd(current, zoneInterval)) {
        current = current.WithEnd(zoneInterval.RawEnd);
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

  bool Equals(ZoneInterval x, ZoneInterval y) {
    if (!EqualExceptStartAndEnd(x, y)) {
      return false;
    }
    return GetEffectiveStart(x) == GetEffectiveStart(y) &&
        GetEffectiveEnd(x) == GetEffectiveEnd(y);
  }

  int GetHashCode(ZoneInterval obj) {
    var hashables = new List<Object>();
    if (_checkOption(options, ZoneEqualityComparerOptions.MatchOffsetComponents)) {
      hashables.addAll([obj.StandardOffset, obj.savings]);
    }
    else {
      hashables.add(obj.wallOffset);
    }
    if (_checkOption(options, ZoneEqualityComparerOptions.MatchNames)) {
      hashables.add(obj.name);
    }

    return hashObjects(hashables);
  }

  @private Instant GetEffectiveStart(ZoneInterval zoneInterval) =>
      _checkOption(options, ZoneEqualityComparerOptions.MatchStartAndEndTransitions)
          ? zoneInterval.RawStart : Instant.max(zoneInterval.RawStart, interval.Start);

  @private Instant GetEffectiveEnd(ZoneInterval zoneInterval) =>
      _checkOption(options, ZoneEqualityComparerOptions.MatchStartAndEndTransitions)
          ? zoneInterval.RawEnd : Instant.min(zoneInterval.RawEnd, interval.End);

  /// <summary>
  /// Compares the parts of two zone intervals which are deemed "interesting" by the options.
  /// The wall offset is always compared, regardless of options, but the start/end points are
  /// never compared.
  /// </summary>
  @private bool EqualExceptStartAndEnd(ZoneInterval x, ZoneInterval y) {
    if (x.wallOffset != y.wallOffset) {
      return false;
    }
    // As we've already compared wall offsets, we only need to compare savings...
    // If the savings are equal, the standard offset will be too.
    if (_checkOption(options, ZoneEqualityComparerOptions.MatchOffsetComponents) && x.savings != y.savings) {
      return false;
    }
    if (_checkOption(options, ZoneEqualityComparerOptions.MatchNames) && x.name != y.name) {
      return false;
    }
    return true;
  }
}