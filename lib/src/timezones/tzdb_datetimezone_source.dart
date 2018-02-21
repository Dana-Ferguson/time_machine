// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/TzdbDateTimeZoneSource.cs
// 407f018  on Aug 31, 2017

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

// todo: THIS WILL BE VERY DIFFERENT FOR US ************ This class has a lot of Stream reading in it
// Class to enable lazy initialization of the default instance.
@private abstract class DefaultHolder
{
  // static DefaultHolder() {}

  @internal static final TzdbDateTimeZoneSource builtin = new TzdbDateTimeZoneSource(LoadDefaultDataSource());

  @private static TzdbStreamData LoadDefaultDataSource() {
//    var assembly = typeof(DefaultHolder).GetTypeInfo().Assembly;
//    using (Stream stream = assembly.GetManifestResourceStream("NodaTime.TimeZones.Tzdb.nzd"))
//    {
//    return TzdbStreamData.FromStream(stream);
//    }
    return null;
  }
}

/// <summary>
/// Provides an implementation of <see cref="IDateTimeZoneSource" /> that loads data originating from the
/// <a href="http://www.iana.org/time-zones">tz database</a> (also known as the IANA Time Zone database, or zoneinfo
/// or Olson database).
/// </summary>
/// <remarks>
/// All calls to <see cref="ForId"/> for fixed-offset IDs advertised by the source (i.e. "UTC" and "UTC+/-Offset")
/// will return zones equal to those returned by <see cref="DateTimeZone.ForOffset"/>.
/// </remarks>
///
/// <threadsafety>This type is immutable reference type. See the thread safety section of the user guide for more information.</threadsafety>
@immutable
/*sealed*/ class TzdbDateTimeZoneSource implements IDateTimeZoneSource
{
/// <summary>
/// Gets the <see cref="TzdbDateTimeZoneSource"/> initialised from resources within the NodaTime assembly.
/// </summary>
/// <value>The source initialised from resources within the NodaTime assembly.</value>
static TzdbDateTimeZoneSource get Default => DefaultHolder.builtin;

/// <summary>
/// Original source data - we delegate to this to create actual DateTimeZone instances,
/// and for windows mappings.
/// </summary>
@private final TzdbStreamData source;

/// <summary>
/// Composite version ID including TZDB and Windows mapping version strings.
/// </summary>
@private final String version;

/// <summary>
/// Gets a lookup from canonical time zone ID (e.g. "Europe/London") to a group of aliases for that time zone
/// (e.g. {"Europe/Belfast", "Europe/Guernsey", "Europe/Jersey", "Europe/Isle_of_Man", "GB", "GB-Eire"}).
/// </summary>
/// <remarks>
/// The group of values for a key never contains the canonical ID, only aliases. Any time zone
/// ID which is itself an alias or has no aliases linking to it will not be present in the lookup.
/// The aliases within a group are returned in alphabetical (ordinal) order.
/// </remarks>
/// <value>A lookup from canonical ID to the aliases of that ID.</value>
// ILookUp
final LookUp<String, String> Aliases;

/// <summary>
/// Returns a read-only map from time zone ID to the canonical ID. For example, the key "Europe/Jersey"
/// would be associated with the value "Europe/London".
/// </summary>
/// <remarks>
/// <para>This map contains an entry for every ID returned by <see cref="GetIds"/>, where
/// canonical IDs map to themselves.</para>
/// <para>The returned map is read-only; any attempts to call a mutating method will throw
/// <see cref="NotSupportedException" />.</para>
/// </remarks>
/// <value>A map from time zone ID to the canonical ID.</value>
// IDictionary
final Map<String, String> CanonicalIdMap;

/// <summary>
/// Gets a read-only list of zone locations known to this source, or null if the original source data
/// does not include zone locations.
/// </summary>
/// <remarks>
/// Every zone location's time zone ID is guaranteed to be valid within this source (assuming the source
/// has been validated).
/// </remarks>
/// <value>A read-only list of zone locations known to this source.</value>
// ILIST
final List<TzdbZoneLocation> ZoneLocations;

/// <summary>
/// Gets a read-only list of "zone 1970" locations known to this source, or null if the original source data
/// does not include zone locations.
/// </summary>
/// <remarks>
/// <p>
/// This location data differs from <see cref="ZoneLocations"/> in two important respects:
/// <ul>
///   <li>Where multiple similar zones exist but only differ in transitions before 1970,
///     this location data chooses one zone to be the canonical "post 1970" zone.
///   </li>
///   <li>
///     This location data can represent multiple ISO-3166 country codes in a single entry. For example,
///     the entry corresponding to "Europe/London" includes country codes GB, GG, JE and IM (Britain,
///     Guernsey, Jersey and the Isle of Man, respectively).
///   </li>
/// </ul>
/// </p>
/// <p>
/// Every zone location's time zone ID is guaranteed to be valid within this source (assuming the source
/// has been validated).
/// </p>
/// </remarks>
/// <value>A read-only list of zone locations known to this source.</value>
// ILIST
final List<TzdbZone1970Location> Zone1970Locations;

/// <inheritdoc />
/// <remarks>
/// <para>
/// This source returns a string such as "TZDB: 2013b (mapping: 8274)" corresponding to the versions of the tz
/// database and the CLDR Windows zones mapping file.
/// </para>
/// <para>
/// Note that there is no need to parse this string to extract any of the above information, as it is available
/// directly from the <see cref="TzdbVersion"/> and <see cref="WindowsZones.Version"/> properties.
/// </para>
/// </remarks>
String get VersionId => "TZDB: $version";

/// <summary>
/// Creates an instance from a stream in the custom Noda Time format. The stream must be readable.
/// </summary>
/// <remarks>
/// <para>
/// The stream is not closed by this method, but will be read from
/// without rewinding. A successful call will read the stream to the end.
/// </para>
/// <para>
/// See the user guide for instructions on how to generate an updated time zone database file from a copy of the
/// (textual) tz database.
/// </para>
/// </remarks>
/// <param name="stream">The stream containing time zone data</param>
/// <returns>A <c>TzdbDateTimeZoneSource</c> providing information from the given stream.</returns>
/// <exception cref="InvalidTimeDataError">The stream contains invalid time zone data, or data which cannot
/// be read by this version of Noda Time.</exception>
/// <exception cref="IOException">Reading from the stream failed.</exception>
/// <exception cref="InvalidOperationException">The supplied stream doesn't support reading.</exception>
factory TzdbDateTimeZoneSource.FromStream(Stream stream)
{
  Preconditions.checkNotNull(stream, 'stream');
  return new TzdbDateTimeZoneSource(TzdbStreamData.FromStream(stream));
  }

  @private factory TzdbDateTimeZoneSource(TzdbStreamData source)
  {
  Preconditions.checkNotNull(source, 'source');
  var CanonicalIdMap = new Map.unmodifiable(source.TzdbIdMap); // new NodaReadOnlyDictionary<string, string>(source.TzdbIdMap);
  // todo: I'm gonna need to know what I'm doing in order to really fix this one
  var Aliases =
      new LookUp.fromList(
      KeyValuePair.getPairs(CanonicalIdMap)
      .where((pair) => pair.key != pair.value)
      .toList(), (kvp) => kvp.value, (kvp) => kvp.key);

//  var Aliases = CanonicalIdMap
//      .where((pair) => pair.Key != pair.Value)
//      .orderBy((pair) => pair.Key, StringComparer.Ordinal)
//      .toLookup((pair) => pair.Value, pair => pair.Key);
  var version = source.TzdbVersion + " (mapping: " + source.WindowsMapping.Version + ")";
  var originalZoneLocations = source.ZoneLocations;
  var ZoneLocations = originalZoneLocations == null ? null : new List<TzdbZoneLocation>.unmodifiable(originalZoneLocations);
  var originalZone1970Locations = source.Zone1970Locations;
  var Zone1970Locations = originalZone1970Locations == null ? null : new List<TzdbZone1970Location>.unmodifiable(originalZone1970Locations);

  return new TzdbDateTimeZoneSource._(CanonicalIdMap, Aliases, source, version, Zone1970Locations, ZoneLocations);
}

TzdbDateTimeZoneSource._(this.CanonicalIdMap, this.Aliases, this.source, this.version, this.Zone1970Locations, this.ZoneLocations);

/// <inheritdoc />
DateTimeZone ForId(String id) {
  String canonicalId = CanonicalIdMap[Preconditions.checkNotNull(id, 'id')];
  if (canonicalId == null) {
    throw new ArgumentError("Time zone with ID $id not found in source $version id");
  }
  return source.CreateZone(id, canonicalId);
}

/// <inheritdoc />
Iterable<String> GetIds() => CanonicalIdMap.keys;

/// <inheritdoc />
String GetSystemDefaultId() => MapTimeZoneInfoId(TimeZoneInfoInterceptor.Local);

@visibleForTesting
@internal String MapTimeZoneInfoId(TimeZoneInfo timeZone)
{
  String id = timeZone.Id;
  String result;
  // First see if it's a Windows time zone ID.
  if (source.WindowsMapping.PrimaryMapping.TryGetValue(id, /*out*/ result))
  {
    return result;
  }
  // Next see if it's already a TZDB ID (e.g. .NET Core running on Linux or Mac).
  if (CanonicalIdMap.containsKey(id))
  {
    return id;
  }
  // Maybe it's a Windows zone we don't have a mapping for, or we're on a Mono system
  // where TimeZoneInfo.Local.Id returns "Local" but can actually do the mappings.
  return GuessZoneIdByTransitions(timeZone);
}

@private final Map<String, String> guesses = {};

// Cache around GuessZoneIdByTransitionsUncached
@private String GuessZoneIdByTransitions(TimeZoneInfo zone)
{
  // lock (guesses)
  {
    // FIXME: Stop using StandardName! (We have Id now...)
    String cached = guesses[zone.StandardName];
    if (cached != null)
    {
      return cached;
    }
    // Build the list of candidates here instead of within the method, so that
    // tests can pass in the same list on each iteration.
    var candidates = CanonicalIdMap.values.select(ForId).ToList();
    String guess = GuessZoneIdByTransitionsUncached(zone, candidates);
    guesses[zone.StandardName] = guess;
    return guess;
  }
}

/// <summary>
/// In cases where we can't get a zone mapping directly, we try to work out a good fit
/// by checking the transitions within the next few years.
/// This can happen if the Windows data isn't up-to-date, or if we're on a system where
/// TimeZoneInfo.Local.Id just returns "local", or if TimeZoneInfo.Local is a custom time
/// zone for some reason. We return null if we don't get a 70% hit rate.
/// We look at all transitions in all canonical IDs for the next 5 years.
/// Heuristically, this seems to be good enough to get the right results in most cases.
/// This method used to only be called in the PCL build in 1.x, but it seems reasonable enough to
/// call it if we can't get an exact match anyway.
/// </summary>
/// <param name="zone">Zone to resolve in a best-effort fashion.</param>
/// <param name="candidates">All the Noda Time zones to consider - normally a list
/// obtained from this source.</param>
@internal String GuessZoneIdByTransitionsUncached(TimeZoneInfo zone, List<DateTimeZone> candidates) {
  // See https://github.com/nodatime/nodatime/issues/686 for performance observations.
  // Very rare use of the system clock! Windows time zone updates sometimes sacrifice past
  // accuracy for future accuracy, so let's use the current year's transitions.
  int thisYear = SystemClock.instance
      .getCurrentInstant()
      .inUtc()
      .Year;
  Instant startOfThisYear = new Instant.fromUtc(thisYear, 1, 1, 0, 0);
  Instant startOfNextYear = new Instant.fromUtc(thisYear + 5, 1, 1, 0, 0);
  var instants = candidates.selectMany((z) => z.GetZoneIntervals(startOfThisYear, startOfNextYear))
      .Select((zi) => Instant.max(zi.RawStart, startOfThisYear)) // Clamp to start of interval
      .Distinct()
      .ToList();
  var bclOffsets = instants.select((instant) => new Offset.fromTimeSpan(zone.GetUtcOffset(instant.ToDateTimeUtc()))).ToList();
// For a zone to be mappable, at most 30% of the checks must fail
// - so if we get to that number (or whatever our "best" so far is)
// we know we can stop for any particular zone.
  int lowestFailureScore = (instants.Count * 30) / 100;
  DateTimeZone bestZone = null;
  for (var candidate in candidates) {
    int failureScore = 0;
    for (int i = 0; i < instants.Count; i++) {
      if (candidate.GetUtcOffset(instants[i]) != bclOffsets[i]) {
        failureScore++;
        if (failureScore == lowestFailureScore) {
          break;
        }
      }
    }
    if (failureScore < lowestFailureScore) {
      lowestFailureScore = failureScore;
      bestZone = candidate;
    }
  }
  return bestZone?.id;
}

/// <summary>
/// Gets just the TZDB version (e.g. "2013a") of the source data.
/// </summary>
/// <value>The TZDB version (e.g. "2013a") of the source data.</value>
String get TzdbVersion => source.TzdbVersion;

/// <summary>
/// Gets the Windows time zone mapping information provided in the CLDR
/// supplemental "windowsZones.xml" file.
/// </summary>
/// <value>The Windows time zone mapping information provided in the CLDR
/// supplemental "windowsZones.xml" file.</value>
WindowsZones get WindowsMapping => source.WindowsMapping;

/// <summary>
/// Validates that the data within this source is consistent with itself.
/// </summary>
/// <remarks>
/// Source data is not validated automatically when it's loaded, but any source
/// loaded from data produced by <c>NodaTime.TzdbCompiler</c> (including the data shipped with Noda Time)
/// will already have been validated via this method when it was originally produced. This method should
/// only normally be called explicitly if you have data from a source you're unsure of.
/// </remarks>
/// <exception cref="InvalidTimeDataError">The source data is invalid. The source may not function
/// correctly.</exception>
void Validate()
{
  // Check that each entry has a canonical value. (Every mapping x to y
  // should be such that y maps to itself.)
  for (var entryValue in this.CanonicalIdMap.values)
  {
    String canonical = CanonicalIdMap[entryValue];
    if (canonical == null)
    {
      throw new InvalidTimeDataError(
          "Mapping for entry {entry.Key} ({entry.Value}) is missing");
    }
    if (entryValue != canonical)
    {
      throw new InvalidTimeDataError(
          "Mapping for entry {entry.Key} ({entry.Value}) is not canonical ({entry.Value} maps to {canonical}");
    }
  }

  // Check that every Windows mapping has a primary territory
  for (var mapZone in source.WindowsMapping.MapZones)
  {
    // Simplest way of checking is to find the primary mapping...
    if (!source.WindowsMapping.PrimaryMapping.ContainsKey(mapZone.WindowsId))
    {
      throw new InvalidTimeDataError(
          "Windows mapping for standard ID ${mapZone.WindowsId} has no primary territory");
    }
  }

  // Check that each Windows mapping has a known canonical ID.
  for (var mapZone in source.WindowsMapping.MapZones)
  {
    for (var id in mapZone.TzdbIds)
    {
      if (!CanonicalIdMap.containsKey(id))
      {
        throw new InvalidTimeDataError(
            "Windows mapping uses canonical ID $id which is missing");
      }
    }
  }

  // Check that each zone location has a valid zone ID
  if (ZoneLocations != null)
  {
    for (var location in ZoneLocations)
    {
      if (!CanonicalIdMap.containsKey(location.ZoneId))
      {
        throw new InvalidTimeDataError(
            "Zone location ${location.CountryName} uses zone ID ${location.ZoneId} which is missing");
      }
    }
  }
  if (Zone1970Locations != null)
  {
    for (var location in Zone1970Locations)
    {
      if (!CanonicalIdMap.containsKey(location.ZoneId))
      {
        throw new InvalidTimeDataError(
            "Zone 1970 location ${location.Countries[0].Name} uses zone ID ${location.ZoneId} which is missing");
      }
    }
  }
}
}