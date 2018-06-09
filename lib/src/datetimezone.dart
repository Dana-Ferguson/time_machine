// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'package:meta/meta.dart';

import 'utility/preconditions.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_timezones.dart';

// todo: IZoneIntervalMapWithMinMax ??? (not sure if it matters)
@immutable
abstract class DateTimeZone implements IZoneIntervalMapWithMinMax {
  /// The ID of the UTC (Coordinated Universal Time) time zone. This ID is always valid, whatever provider is
  /// used. If the provider has its own mapping for UTC, that will be returned by [DateTimeZoneCache.GetZoneOrNull], but otherwise
  /// the value of the [Utc] property will be returned.
  @internal static const String UtcId = "UTC";

  /// Gets the UTC (Coordinated Universal Time) time zone.
  ///
  /// This is a single instance which is not provider-specific; it is guaranteed to have the ID "UTC", and to
  /// compare equal to an instance returned by calling [ForOffset] with an offset of zero, but it may
  /// or may not compare equal to an instance returned by e.g. `DateTimeZoneProviders.Tzdb["UTC"]`.
  static final DateTimeZone Utc = new FixedDateTimeZone.forOffset(Offset.zero);
  static const int FixedZoneCacheGranularitySeconds = TimeConstants.secondsPerMinute * 30;
  static const int FixedZoneCacheMinimumSeconds = -FixedZoneCacheGranularitySeconds * 12 * 2; // From UTC-12
  static const int FixedZoneCacheSize = (12 + 15) * 2 + 1; // To UTC+15 inclusive
  static final List<DateTimeZone> FixedZoneCache = _buildFixedZoneCache();

  /// Returns a fixed time zone with the given offset.
  ///
  /// The returned time zone will have an ID of "UTC" if the offset is zero, or "UTC+/-Offset"
  /// otherwise. In the former case, the returned instance will be equal to [Utc].
  ///
  /// Note also that this method is not required to return the same [DateTimeZone] instance for
  /// successive requests for the same offset; however, all instances returned for a given offset will compare
  /// as equal.
  ///
  /// [offset]: The offset for the returned time zone
  /// Returns: A fixed time zone with the given offset.
  static DateTimeZone ForOffset(Offset offset) {
    int seconds = offset.seconds;
    if (csharpMod(seconds, FixedZoneCacheGranularitySeconds) != 0) {
      return new FixedDateTimeZone.forOffset(offset);
    }
    int index = (seconds - FixedZoneCacheMinimumSeconds) ~/ FixedZoneCacheGranularitySeconds;
    if (index < 0 || index >= FixedZoneCacheSize) {
      return new FixedDateTimeZone.forOffset(offset);
    }
    return FixedZoneCache[index];
  }


  /// Initializes a new instance of the [DateTimeZone] class.
  ///
  /// [id]: The unique id of this time zone.
  /// [isFixed]: Set to `true` if this time zone has no transitions.
  /// [minOffset]: Minimum offset applied within this zone
  /// [maxOffset]: Maximum offset applied within this zone
  @protected DateTimeZone(String id, bool isFixed, Offset minOffset, Offset maxOffset)
      : this.id = Preconditions.checkNotNull(id, 'id'),
        this.isFixed = isFixed,
        this.minOffset = minOffset,
        this.maxOffset = maxOffset;

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
  @internal final bool isFixed;


  /// Gets the least (most negative) offset within this time zone, over all time.
  final Offset minOffset;


  /// Gets the greatest (most positive) offset within this time zone, over all time.
  final Offset maxOffset;

// #region Core abstract/virtual methods

  /// Returns the offset from UTC, where a positive duration indicates that local time is
  /// later than UTC. In other words, local time = UTC + offset.
  ///
  /// This is mostly a convenience method for calling `GetZoneInterval(instant).WallOffset`,
  /// although it can also be overridden for more efficiency.
  ///
  /// [instant]: The instant for which to calculate the offset.
  ///
  /// The offset from UTC at the specified instant.
  @virtual Offset GetUtcOffset(Instant instant) => GetZoneInterval(instant).wallOffset;


  /// Gets the zone interval for the given instant; the range of time around the instant in which the same Offset
  /// applies (with the same split between standard time and daylight saving time, and with the same offset).
  ///
  /// This will always return a valid zone interval, as time zones cover the whole of time.
  ///
  /// [instant]: The [Instant] to query.
  /// Returns: The defined [TimeZones.ZoneInterval].
  /// <seealso cref="GetZoneIntervals(Interval)"/>
  ZoneInterval GetZoneInterval(Instant instant);


  /// Returns complete information about how the given [LocalDateTime] is mapped in this time zone.
  ///
  /// Mapping a local date/time to a time zone can give an unambiguous, ambiguous or impossible result, depending on
  /// time zone transitions. Use the return value of this method to handle these cases in an appropriate way for
  /// your use case.
  ///
  /// As an alternative, consider [ResolveLocal(LocalDateTime, ZoneLocalMappingResolver)], which uses a caller-provided strategy to
  /// convert the [ZoneLocalMapping] returned here to a [ZonedDateTime].
  ///
  /// [localDateTime]: The local date and time to map in this time zone.
  /// Returns: A mapping of the given local date and time to zero, one or two zoned date/time values.
  @virtual ZoneLocalMapping MapLocal(LocalDateTime localDateTime) {
    LocalInstant localInstant = localDateTime.ToLocalInstant();
    Instant firstGuess = localInstant.MinusZeroOffset();
    ZoneInterval interval = GetZoneInterval(firstGuess);

    // Most of the time we'll go into here... the local instant and the instant
    // are close enough that we've found the right instant.
    if (interval.ContainsLocal(localInstant)) {
      ZoneInterval earlier = _getEarlierMatchingInterval(interval, localInstant);
      if (earlier != null) {
        return new ZoneLocalMapping(this, localDateTime, earlier, interval, 2);
      }
      ZoneInterval later = _getLaterMatchingInterval(interval, localInstant);
      if (later != null) {
        return new ZoneLocalMapping(this, localDateTime, interval, later, 2);
      }
      return new ZoneLocalMapping(this, localDateTime, interval, interval, 1);
    }
    else {
      // Our first guess was wrong. Either we need to change interval by one (either direction)
      // or we're in a gap.
      ZoneInterval earlier = _getEarlierMatchingInterval(interval, localInstant);
      if (earlier != null) {
        return new ZoneLocalMapping(this, localDateTime, earlier, earlier, 1);
      }
      ZoneInterval later = _getLaterMatchingInterval(interval, localInstant);
      if (later != null) {
        return new ZoneLocalMapping(this, localDateTime, later, later, 1);
      }
      return new ZoneLocalMapping(this, localDateTime, _getIntervalBeforeGap(localInstant), _getIntervalAfterGap(localInstant), 0);
    }
  }

// #endregion

//#region Conversion between local dates/times and ZonedDateTime

  /// Returns the earliest valid [ZonedDateTime] with the given local date.
  ///
  /// If midnight exists unambiguously on the given date, it is returned.
  /// If the given date has an ambiguous start time (e.g. the clocks go back from 1am to midnight)
  /// then the earlier ZonedDateTime is returned. If the given date has no midnight (e.g. the clocks
  /// go forward from midnight to 1am) then the earliest valid value is returned; this will be the instant
  /// of the transition.
  ///
  /// [date]: The local date to map in this time zone.
  /// [SkippedTimeException]: The entire day was skipped due to a very large time zone transition.
  /// (This is extremely rare.)
  /// Returns: The [ZonedDateTime] representing the earliest time in the given date, in this time zone.
  ZonedDateTime AtStartOfDay(LocalDate date) {
    LocalDateTime midnight = date.AtMidnight;
    var mapping = MapLocal(midnight);
    switch (mapping.Count) {
      // Midnight doesn't exist. Maybe we just skip to 1am (or whatever), or maybe the whole day is missed.
      case 0:
        var interval = mapping.LateInterval;
        // Safe to use Start, as it can't extend to the start of time.
        var offsetDateTime = new OffsetDateTime.instantCalendar(interval.start, interval.wallOffset, date.Calendar);
        // It's possible that the entire day is skipped. For example, Samoa skipped December 30th 2011.
        // We know the two values are in the same calendar here, so we just need to check the YearMonthDay.
        if (offsetDateTime.yearMonthDay != date.yearMonthDay) {
          throw new SkippedTimeError(midnight, this);
        }
        return new ZonedDateTime.trusted(offsetDateTime, this);
      // Unambiguous or occurs twice, we can just use the offset from the earlier interval.
      case 1:
      case 2:
        return new ZonedDateTime.trusted(midnight.WithOffset(mapping.EarlyInterval.wallOffset), this);
      default:
        throw new StateError("This won't happen.");
    }
  }


  /// Maps the given [LocalDateTime] to the corresponding [ZonedDateTime], following
  /// the given [ZoneLocalMappingResolver] to handle ambiguity and skipped times.
  ///
  /// This is a convenience method for calling [MapLocal] and passing the result to the resolver.
  /// Common options for resolvers are provided in the static [Resolvers] class.
  ///
  /// See [AtStrictly] and [AtLeniently] for alternative ways to map a local time to a
  /// specific instant.
  ///
  /// [localDateTime]: The local date and time to map in this time zone.
  /// [resolver]: The resolver to apply to the mapping.
  /// Returns: The result of resolving the mapping.
  ZonedDateTime ResolveLocal(LocalDateTime localDateTime, ZoneLocalMappingResolver resolver) {
    Preconditions.checkNotNull(resolver, 'resolver');
    return resolver(MapLocal(localDateTime));
  }


  /// Maps the given [LocalDateTime] to the corresponding [ZonedDateTime], if and only if
  /// that mapping is unambiguous in this time zone.  Otherwise, [SkippedTimeException] or
  /// [AmbiguousTimeException] is thrown, depending on whether the mapping is ambiguous or the local
  /// date/time is skipped entirely.
  ///
  /// See [AtLeniently] and [ResolveLocal(LocalDateTime, ZoneLocalMappingResolver)] for alternative ways to map a local time to a
  /// specific instant.
  ///
  /// [localDateTime]: The local date and time to map into this time zone.
  /// [SkippedTimeException]: The given local date/time is skipped in this time zone.
  /// [AmbiguousTimeException]: The given local date/time is ambiguous in this time zone.
  /// Returns: The unambiguous matching [ZonedDateTime] if it exists.
  ZonedDateTime AtStrictly(LocalDateTime localDateTime) =>
      ResolveLocal(localDateTime, Resolvers.StrictResolver);


  /// Maps the given [LocalDateTime] to the corresponding [ZonedDateTime] in a lenient
  /// manner: ambiguous values map to the earlier of the alternatives, and "skipped" values are shifted forward
  /// by the duration of the "gap".
  ///
  /// See [AtStrictly] and [ResolveLocal(LocalDateTime, ZoneLocalMappingResolver)] for alternative ways to map a local time to a
  /// specific instant.
  /// Note: The behavior of this method was changed in version 2.0 to fit the most commonly seen real-world
  /// usage pattern.  Previous versions returned the later instance of ambiguous values, and returned the start of
  /// the zone interval after the gap for skipped value.  The previous functionality can still be used if desired,
  /// by using [ResolveLocal(LocalDateTime, ZoneLocalMappingResolver)], passing in a resolver
  /// created from [Resolvers.ReturnLater] and [Resolvers.ReturnStartOfIntervalAfter].
  ///
  /// [localDateTime]: The local date/time to map.
  /// The unambiguous mapping if there is one, the earlier result if the mapping is ambiguous,
  /// or the forward-shifted value if the given local date/time is skipped.
  ZonedDateTime AtLeniently(LocalDateTime localDateTime) =>
      ResolveLocal(localDateTime, Resolvers.LenientResolver);

// #endregion


  /// Returns the interval before this one, if it contains the given local instant, or null otherwise.
  ZoneInterval _getEarlierMatchingInterval(ZoneInterval interval, LocalInstant localInstant) {
    // Micro-optimization to avoid fetching interval.Start multiple times. Seems
    // to give a performance improvement on x86 at least...
    // If the zone interval extends to the start of time, the next check will definitely evaluate to false.
    Instant intervalStart = interval.RawStart;
    // This allows for a maxOffset of up to +1 day, and the "truncate towards beginning of time"
    // nature of the Days property.
    if (localInstant.DaysSinceEpoch <= intervalStart.daysSinceEpoch + 1) {
      // We *could* do a more accurate check here based on the actual maxOffset, but it's probably
      // not worth it.
      ZoneInterval candidate = GetZoneInterval(intervalStart - Span.epsilon);
      if (candidate.ContainsLocal(localInstant)) {
        return candidate;
      }
    }
    return null;
  }


  /// Returns the next interval after this one, if it contains the given local instant, or null otherwise.
  ZoneInterval _getLaterMatchingInterval(ZoneInterval interval, LocalInstant localInstant) {
    // Micro-optimization to avoid fetching interval.End multiple times. Seems
    // to give a performance improvement on x86 at least...
    // If the zone interval extends to the end of time, the next check will
    // definitely evaluate to false.
    Instant intervalEnd = interval.RawEnd;
    // Crude but cheap first check to see whether there *might* be a later interval.
    // This allows for a minOffset of up to -1 day, and the "truncate towards beginning of time"
    // nature of the Days property.
    if (localInstant.DaysSinceEpoch >= intervalEnd.daysSinceEpoch - 1) {
      // We *could* do a more accurate check here based on the actual maxOffset, but it's probably
      // not worth it.
      ZoneInterval candidate = GetZoneInterval(intervalEnd);
      if (candidate.ContainsLocal(localInstant)) {
        return candidate;
      }
    }
    return null;
  }

  ZoneInterval _getIntervalBeforeGap(LocalInstant localInstant) {
    Instant guess = localInstant.MinusZeroOffset();
    ZoneInterval guessInterval = GetZoneInterval(guess);
    // If the local interval occurs before the zone interval we're looking at starts,
    // we need to find the earlier one; otherwise this interval must come after the gap, and
    // it's therefore the one we want.
    if (localInstant.Minus(guessInterval.wallOffset) < guessInterval.RawStart) {
      return GetZoneInterval(guessInterval.start - Span.epsilon);
    }
    else {
      return guessInterval;
    }
  }

  ZoneInterval _getIntervalAfterGap(LocalInstant localInstant) {
    Instant guess = localInstant.MinusZeroOffset();
    ZoneInterval guessInterval = GetZoneInterval(guess);
    // If the local interval occurs before the zone interval we're looking at starts,
    // it's the one we're looking for. Otherwise, we need to find the next interval.
    if (localInstant.Minus(guessInterval.wallOffset) < guessInterval.RawStart) {
      return guessInterval;
    }
    else {
      // Will definitely be valid - there can't be a gap after an infinite interval.
      return GetZoneInterval(guessInterval.end);
    }
  }

// #region Object overrides

  /// Returns the ID of this time zone.
  ///
  /// The ID of this time zone.
  ///
  /// <filterpriority>2</filterpriority>
  @override String toString() => id;

// #endregion


  /// Creates a fixed time zone for offsets -12 to +15 at every half hour,
  /// fixing the 0 offset as DateTimeZone.Utc.
  static List<DateTimeZone> _buildFixedZoneCache() {
    List<DateTimeZone> ret = new List<DateTimeZone>(FixedZoneCacheSize);
    for (int i = 0; i < FixedZoneCacheSize; i++) {
      int offsetSeconds = i * FixedZoneCacheGranularitySeconds + FixedZoneCacheMinimumSeconds;
      ret[i] = new FixedDateTimeZone.forOffset(new Offset.fromSeconds(offsetSeconds));
    }
    ret[-FixedZoneCacheMinimumSeconds ~/ FixedZoneCacheGranularitySeconds] = Utc;
    return ret;
  }


  /// Returns all the zone intervals which occur for any instant in the interval [[start], [end]).
  ///
  /// This method is simply a convenience method for calling [GetZoneIntervals(Interval)] without
  /// explicitly static constructing the interval beforehand.
  ///
  /// [start]: Inclusive start point of the interval for which to retrieve zone intervals.
  /// [end]: Exclusive end point of the interval for which to retrieve zone intervals.
  /// [ArgumentOutOfRangeException]: [end] is earlier than [start].
  /// Returns: A sequence of zone intervals covering the given interval.
  /// <seealso cref="DateTimeZone.GetZoneInterval"/>
  Iterable<ZoneInterval> getZoneIntervalsFromTo(Instant start, Instant end) =>
  //    // The static constructor performs all the validation we need.
  getZoneIntervals(new Interval(start, end));


  /// Returns all the zone intervals which occur for any instant in the given interval.
  ///
  /// The zone intervals are returned in chronological order.
  /// This method is equivalent to calling [DateTimeZone.GetZoneInterval] for every
  /// instant in the interval and then collapsing to a set of distinct zone intervals.
  /// The first and last zone intervals are likely to also cover instants outside the given interval;
  /// the zone intervals returned are not truncated to match the start and end points.
  ///
  /// [interval]: Interval to find zone intervals for. This is allowed to be unbounded (i.e.
  /// infinite in both directions).
  /// Returns: A sequence of zone intervals covering the given interval.
  /// <seealso cref="DateTimeZone.GetZoneInterval"/>
  Iterable<ZoneInterval> getZoneIntervals(Interval interval) sync* {
    var current = interval.HasStart ? interval.Start : Instant.minValue;
    var end = interval.RawEnd;
    while (current < end) {
      var zoneInterval = GetZoneInterval(current);
      yield zoneInterval;
      // If this is the end of time, this will just fail on the next comparison.
      current = zoneInterval.RawEnd;
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
  /// [interval]: Interval to find zone intervals for. This is allowed to be unbounded (i.e.
  /// infinite in both directions).
  /// [options]: 
  /// Returns: 
  // todo: merge with regular getZoneIntervals as a custom parameter
  Iterable<ZoneInterval> getZoneIntervalsOptions(Interval interval, ZoneEqualityComparerOptions options) {
    if ((options & ~ZoneEqualityComparerOptions.StrictestMatch).value != 0) {
      throw new ArgumentError("The value $options is not defined within ZoneEqualityComparer.Options");
    }
    var zoneIntervalEqualityComparer = new ZoneIntervalEqualityComparer(options, interval);
    var originalIntervals = getZoneIntervals(interval);
    return zoneIntervalEqualityComparer.CoalesceIntervals(originalIntervals);
  }
}

