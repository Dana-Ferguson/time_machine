// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

abstract class IDateTimeZone {
  static bool isFixed(DateTimeZone dateTimeZone) => dateTimeZone._isFixed;

  // todo: should this just be a TimeConstant?
  /// The ID of the UTC (Coordinated Universal Time) time zone. This ID is always valid, whatever provider is
  /// used. If the provider has its own mapping for UTC, that will be returned by [DateTimeZoneCache.getZoneOrNull], but otherwise
  /// the value of the [utc] property will be returned.
  static const String utcId = 'UTC';
}


/// Represents a time zone - a mapping between UTC and local time. A time zone maps UTC instants to local times
///  - or, equivalently, to the offset from UTC at any particular instant.
///
/// The mapping is unambiguous in the 'UTC to local' direction, but
/// the reverse is not true: when the offset changes, usually due to a Daylight Saving transition,
/// the change either creates a gap (a period of local time which never occurs in the time zone)
/// or an ambiguity (a period of local time which occurs twice in the time zone). Mapping back from
/// local time to an instant requires consideration of how these problematic times will be handled.
///
/// // todo: move this?
/// Time Machine provides various options when mapping local time to a specific instant:
/// * [atStrictly] will throw an exception if the mapping from local time is either ambiguous
///     or impossible, i.e. if there is anything other than one instant which maps to the given local time.
/// * [atLeniently] will never throw an exception due to ambiguous or skipped times,
///     resolving to the earlier option of ambiguous matches, or to a value that's forward-shifted by the duration
///     of the gap for skipped times.
/// * [resolveLocal] will apply a [ZoneLocalMappingResolver] to the result of
///     a mapping.
/// * [mapLocal] will return a [ZoneLocalMapping]
///     with complete information about whether the given local time occurs zero times, once or twice. This is the most
///     fine-grained approach, which is the fiddliest to use but puts the caller in the most control.
///
/// Time Machine has one built-in source of time zone data available: a copy of the
/// [tz database](http://www.iana.org/time-zones) (also known as the IANA Time Zone database, or zoneinfo
/// or Olson database).
///
/// To obtain a [DateTimeZone] for a given timezone ID, use one of the methods on
/// [DateTimeZoneProvider] (and see [DateTimeZoneProviders] for access to the built-in
/// providers). The UTC timezone is also available via the [utc] property on this class.
///
/// To obtain a [DateTimeZone] representing the system default time zone, you can either call
/// [DateTimeZoneProvider.getSystemDefault] on a provider to obtain the [DateTimeZone] that
/// the provider considers matches the system default time zone
///
/// Note that Time Machine does not require that [DateTimeZone] instances be singletons.
/// Comparing two time zones for equality is not straightforward: if you care about whether two
/// zones act the same way within a particular portion of time, use [ZoneEqualityComparer].
/// Additional guarantees are provided by [DateTimeZoneProvider] and [DateTimeZone.forOffset].
@immutable
abstract class DateTimeZone implements ZoneIntervalMapWithMinMax {
  /// Gets the UTC (Coordinated Universal Time) time zone.
  ///
  /// This is a single instance which is not provider-specific; it is guaranteed to have the ID 'UTC', and to
  /// compare equal to an instance returned by calling [forOffset] with an offset of zero, but it may
  /// or may not compare equal to an instance returned by e.g. `DateTimeZoneProviders.Tzdb['UTC']`.
  static final DateTimeZone utc = FixedDateTimeZone.forOffset(Offset.zero);
  static const int _fixedZoneCacheGranularitySeconds = TimeConstants.secondsPerMinute * 30;
  static const int _fixedZoneCacheMinimumSeconds = -_fixedZoneCacheGranularitySeconds * 12 * 2; // From UTC-12
  static const int _fixedZoneCacheSize = (12 + 15) * 2 + 1; // To UTC+15 inclusive
  static final List<DateTimeZone> _fixedZoneCache = _buildFixedZoneCache();

  /// Gets the local [DateTimeZone] of the local machine if the [DateTimeZoneProviders.defaultProvider] is defined, or [utc].
  static DateTimeZone get local => DateTimeZoneProviders.defaultProvider?.getCachedSystemDefault() ?? utc;

  /// Returns a fixed time zone with the given offset.
  ///
  /// The returned time zone will have an ID of 'UTC' if the offset is zero, or "UTC+/-Offset"
  /// otherwise. In the former case, the returned instance will be equal to [utc].
  ///
  /// Note also that this method is not required to return the same [DateTimeZone] instance for
  /// successive requests for the same offset; however, all instances returned for a given offset will compare
  /// as equal.
  ///
  /// * [offset]: The offset for the returned time zone
  ///
  /// Returns: A fixed time zone with the given offset.
  factory DateTimeZone.forOffset(Offset offset) {
    int seconds = offset.inSeconds;
    if (arithmeticMod(seconds, _fixedZoneCacheGranularitySeconds) != 0) {
      return FixedDateTimeZone.forOffset(offset);
    }
    int index = (seconds - _fixedZoneCacheMinimumSeconds) ~/ _fixedZoneCacheGranularitySeconds;
    if (index < 0 || index >= _fixedZoneCacheSize) {
      return FixedDateTimeZone.forOffset(offset);
    }
    return _fixedZoneCache[index];
  }


  /// Initializes a new instance of the [DateTimeZone] class.
  ///
  /// * [id]: The unique id of this time zone.
  /// * [isFixed]: Set to `true` if this time zone has no transitions.
  /// * [minOffset]: Minimum offset applied within this zone
  /// * [maxOffset]: Maximum offset applied within this zone
  @protected DateTimeZone(String id, bool isFixed, Offset minOffset, Offset maxOffset)
      : id = Preconditions.checkNotNull(id, 'id'),
        _isFixed = isFixed,
        minOffset = minOffset,
        maxOffset = maxOffset;

  /// Get the provider's ID for the time zone.
  ///
  /// This identifies the time zone within the current time zone provider; a different provider may
  /// provide a different time zone with the same ID, or may not provide a time zone with that ID at all.
  final String id;

  /// Indicates whether the time zone is fixed, i.e. contains no transitions.
  ///
  /// This is used as an optimization. If the time zone has no transitions but returns `false`
  /// for this then the behavior will be correct but the system will have to do extra work. However
  /// if the time zone has transitions and this returns `true` then the transitions will never
  /// be examined.
  final bool _isFixed;


  /// Gets the least (most negative) offset within this time zone, over all time.
  @override
  final Offset minOffset;


  /// Gets the greatest (most positive) offset within this time zone, over all time.
  @override
  final Offset maxOffset;

  /// Returns the offset from UTC, where a positive duration indicates that local time is
  /// later than UTC. In other words, local time = UTC + offset.
  ///
  /// This is mostly a convenience method for calling `GetZoneInterval(instant).WallOffset`,
  /// although it can also be overridden for more efficiency.
  ///
  /// * [instant]: The instant for which to calculate the offset.
  ///
  /// The offset from UTC at the specified instant.
  Offset getUtcOffset(Instant instant) => getZoneInterval(instant).wallOffset;


  /// Gets the zone interval for the given instant; the range of time around the instant in which the same Offset
  /// applies (with the same split between standard time and daylight saving time, and with the same offset).
  ///
  /// This will always return a valid zone interval, as time zones cover the whole of time.
  ///
  /// * [instant]: The [Instant] to query.
  ///
  /// Returns: The defined [TimeZones.ZoneInterval].
  ///
  /// see:[getZoneIntervals]
  @override
  ZoneInterval getZoneInterval(Instant instant);


  /// Returns complete information about how the given [LocalDateTime] is mapped in this time zone.
  ///
  /// Mapping a local date/time to a time zone can give an unambiguous, ambiguous or impossible result, depending on
  /// time zone transitions. Use the return value of this method to handle these cases in an appropriate way for
  /// your use case.
  ///
  /// As an alternative, consider [ResolveLocal(LocalDateTime, ZoneLocalMappingResolver)], which uses a caller-provided strategy to
  /// convert the [ZoneLocalMapping] returned here to a [ZonedDateTime].
  ///
  /// * [localDateTime]: The local date and time to map in this time zone.
  ///
  /// Returns: A mapping of the given local date and time to zero, one or two zoned date/time values.
  ZoneLocalMapping mapLocal(LocalDateTime localDateTime) {
    LocalInstant localInstant = ILocalDateTime.toLocalInstant(localDateTime);
    Instant firstGuess = localInstant.minusZeroOffset();
    ZoneInterval interval = getZoneInterval(firstGuess);

    // Most of the time we'll go into here... the local instant and the instant
    // are close enough that we've found the right instant.
    if (IZoneInterval.containsLocal(interval, localInstant)) {
      ZoneInterval? earlier = _getEarlierMatchingInterval(interval, localInstant);
      if (earlier != null) {
        return IZoneLocalMapping.newZoneLocalMapping(this, localDateTime, earlier, interval, 2);
      }
      ZoneInterval? later = _getLaterMatchingInterval(interval, localInstant);
      if (later != null) {
        return IZoneLocalMapping.newZoneLocalMapping(this, localDateTime, interval, later, 2);
      }
      return IZoneLocalMapping.newZoneLocalMapping(this, localDateTime, interval, interval, 1);
    }
    else {
      // Our first guess was wrong. Either we need to change interval by one (either direction)
      // or we're in a gap.
      ZoneInterval? earlier = _getEarlierMatchingInterval(interval, localInstant);
      if (earlier != null) {
        return IZoneLocalMapping.newZoneLocalMapping(this, localDateTime, earlier, earlier, 1);
      }
      ZoneInterval? later = _getLaterMatchingInterval(interval, localInstant);
      if (later != null) {
        return IZoneLocalMapping.newZoneLocalMapping(this, localDateTime, later, later, 1);
      }
      return IZoneLocalMapping.newZoneLocalMapping(this, localDateTime, _getIntervalBeforeGap(localInstant), _getIntervalAfterGap(localInstant), 0);
    }
  }

  /// Returns the interval before this one, if it contains the given local instant, or null otherwise.
  ZoneInterval? _getEarlierMatchingInterval(ZoneInterval interval, LocalInstant localInstant) {
    // Micro-optimization to avoid fetching interval.Start multiple times. Seems
    // to give a performance improvement on x86 at least...
    // If the zone interval extends to the start of time, the next check will definitely evaluate to false.
    Instant intervalStart = IZoneInterval.rawStart(interval);
    // This allows for a maxOffset of up to +1 day, and the 'truncate towards beginning of time'
    // nature of the Days property.
    if (localInstant.daysSinceEpoch <= intervalStart.epochDay + 1) {
      // We *could* do a more accurate check here based on the actual maxOffset, but it's probably
      // not worth it.
      ZoneInterval candidate = getZoneInterval(intervalStart - Time.epsilon);
      if (IZoneInterval.containsLocal(candidate, localInstant)) {
        return candidate;
      }
    }
    return null;
  }


  /// Returns the next interval after this one, if it contains the given local instant, or null otherwise.
  ZoneInterval? _getLaterMatchingInterval(ZoneInterval interval, LocalInstant localInstant) {
    // Micro-optimization to avoid fetching interval.End multiple times. Seems
    // to give a performance improvement on x86 at least...
    // If the zone interval extends to the end of time, the next check will
    // definitely evaluate to false.
    Instant intervalEnd = IZoneInterval.rawEnd(interval);
    // Crude but cheap first check to see whether there *might* be a later interval.
    // This allows for a minOffset of up to -1 day, and the 'truncate towards beginning of time'
    // nature of the Days property.
    if (localInstant.daysSinceEpoch >= intervalEnd.epochDay - 1) {
      // We *could* do a more accurate check here based on the actual maxOffset, but it's probably
      // not worth it.
      ZoneInterval candidate = getZoneInterval(intervalEnd);
      if (IZoneInterval.containsLocal(candidate, localInstant)) {
        return candidate;
      }
    }
    return null;
  }

  ZoneInterval _getIntervalBeforeGap(LocalInstant localInstant) {
    Instant guess = localInstant.minusZeroOffset();
    ZoneInterval guessInterval = getZoneInterval(guess);
    // If the local interval occurs before the zone interval we're looking at starts,
    // we need to find the earlier one; otherwise this interval must come after the gap, and
    // it's therefore the one we want.
    if (localInstant.minus(guessInterval.wallOffset) < IZoneInterval.rawStart(guessInterval)) {
      return getZoneInterval(guessInterval.start - Time.epsilon);
    }
    else {
      return guessInterval;
    }
  }

  ZoneInterval _getIntervalAfterGap(LocalInstant localInstant) {
    Instant guess = localInstant.minusZeroOffset();
    ZoneInterval guessInterval = getZoneInterval(guess);
    // If the local interval occurs before the zone interval we're looking at starts,
    // it's the one we're looking for. Otherwise, we need to find the next interval.
    if (localInstant.minus(guessInterval.wallOffset) < IZoneInterval.rawStart(guessInterval)) {
      return guessInterval;
    }
    else {
      // Will definitely be valid - there can't be a gap after an infinite interval.
      return getZoneInterval(guessInterval.end);
    }
  }

  /// Returns the ID of this time zone.
  @override String toString() => id;

  /// Creates a fixed time zone for offsets -12 to +15 at every half hour,
  /// fixing the 0 offset as DateTimeZone.Utc.
  static List<DateTimeZone> _buildFixedZoneCache() {
    List<DateTimeZone> ret = List<DateTimeZone>.generate(
      _fixedZoneCacheSize,
      (int i) => FixedDateTimeZone.forOffset(Offset(i * _fixedZoneCacheGranularitySeconds + _fixedZoneCacheMinimumSeconds)),
    );
    ret[-_fixedZoneCacheMinimumSeconds ~/ _fixedZoneCacheGranularitySeconds] = utc;
    return ret;
  }


  /// Returns all the zone intervals which occur for any instant in the interval [[start], [end]).
  ///
  /// This method is simply a convenience method for calling [GetZoneIntervals(Interval)] without
  /// explicitly static constructing the interval beforehand.
  ///
  /// * [start]: Inclusive start point of the interval for which to retrieve zone intervals.
  /// * [end]: Exclusive end point of the interval for which to retrieve zone intervals.
  ///
  /// Returns: A sequence of zone intervals covering the given interval.
  ///
  /// * [ArgumentOutOfRangeException]: [end] is earlier than [start].
  ///
  /// see also: [DateTimeZone.getZoneInterval]
  Iterable<ZoneInterval> getZoneIntervalsFromTo(Instant start, Instant end) =>
  //    // The static constructor performs all the validation we need.
  getZoneIntervals(Interval(start, end));


  /// Returns all the zone intervals which occur for any instant in the given interval.
  ///
  /// The zone intervals are returned in chronological order.
  /// This method is equivalent to calling [DateTimeZone.getZoneInterval] for every
  /// instant in the interval and then collapsing to a set of distinct zone intervals.
  /// The first and last zone intervals are likely to also cover instants outside the given interval;
  /// the zone intervals returned are not truncated to match the start and end points.
  ///
  /// * [interval]: Interval to find zone intervals for. This is allowed to be unbounded (i.e.
  /// infinite in both directions).
  ///
  /// Returns: A sequence of zone intervals covering the given interval.
  ///
  /// see also: [DateTimeZone.getZoneInterval]
  Iterable<ZoneInterval> getZoneIntervals(Interval interval) sync* {
    var current = interval.hasStart ? interval.start : Instant.minValue;
    var end = IInterval.rawEnd(interval);
    while (current < end) {
      var zoneInterval = getZoneInterval(current);
      yield zoneInterval;
      // If this is the end of time, this will just fail on the next comparison.
      current = IZoneInterval.rawEnd(zoneInterval);
    }
  }


  /// Returns the zone intervals within the given interval, potentially coalescing some of the
  /// original intervals according to options.
  ///
  /// This is equivalent to [GetZoneIntervals(Interval)], but may coalesce some intervals.
  /// For example, if the [ZoneEqualityComparer.Options.OnlyMatchWallOffset] is specified,
  /// and two consecutive zone intervals have the same offset but different names, a single zone interval
  /// will be returned instead of two separate ones. When zone intervals are coalesced, all aspects of
  /// the first zone interval are used except its end instant, which is taken from the second zone interval.
  ///
  /// As the options are only used to determine which intervals to coalesce, the
  /// [ZoneEqualityComparer.Options.MatchStartAndEndTransitions] option does not affect
  /// the intervals returned.
  ///
  /// * [interval]: Interval to find zone intervals for. This is allowed to be unbounded (i.e.
  /// infinite in both directions).
  /// * [options]:
  // todo: merge with regular getZoneIntervals as a custom parameter
  Iterable<ZoneInterval> getZoneIntervalsOptions(Interval interval, ZoneEqualityComparerOptions options) {
    if ((options & ~ZoneEqualityComparerOptions.strictestMatch).value != 0) {
      throw ArgumentError('The value $options is not defined within ZoneEqualityComparer.Options');
    }
    var zoneIntervalEqualityComparer = ZoneIntervalEqualityComparer(options, interval);
    var originalIntervals = getZoneIntervals(interval);
    return zoneIntervalEqualityComparer.coalesceIntervals(originalIntervals);
  }
}

