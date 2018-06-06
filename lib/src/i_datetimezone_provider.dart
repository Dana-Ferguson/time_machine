// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/IDateTimeZoneProvider.cs
// 7160b82  on Jun 18, 2017
// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Extensions/DateTimeZoneProviderExtensions.cs
// 24fdeef  on Apr 10, 2017

import 'dart:async';

import 'package:time_machine/time_machine.dart';

/// Provides stable, performant time zone data.
/// </summary>
/// <remarks>
/// <para>Consumers should be able to treat an <see cref="IDateTimeZoneProvider"/> like a cache: 
/// lookups should be quick (after at most one lookup of a given ID), and multiple calls for a given ID must
/// always return references to equal instances, even if they are not references to a single instance.
/// Consumers should not feel the need to cache data accessed through this interface.</para>
/// <para>Implementations designed to work with any <see cref="IDateTimeZoneSource"/> implementation (such as
/// <see cref="DateTimeZoneCache"/>) should not attempt to handle exceptions thrown by the source. A source-specific
/// provider may do so, as it has more detailed knowledge of what can go wrong and how it can best be handled.</para>
/// </remarks>
abstract class IDateTimeZoneProvider {
  /// <summary>
  /// Gets the version ID of this provider.
  /// </summary>
  /// <value>The version ID of this provider.</value>
  final String VersionId = null;

  /// <summary>
  /// Gets the list of valid time zone ids advertised by this provider.
  /// </summary>
  /// <remarks>
  /// <para>
  /// This list will be sorted in ordinal lexicographic order. It cannot be modified by callers, and
  /// must not be modified by the provider either: client code can safely treat it as thread-safe
  /// and deeply immutable.
  /// </para>
  /// <para>
  /// In addition to the list returned here, providers always support the fixed-offset timezones with IDs "UTC"
  /// and "UTC+/-Offset". These may or may not be included explicitly in this list.
  /// </para>
  /// </remarks>
  /// <value>The <see cref="IEnumerable{T}" /> of string ids.</value>
  final List<String> Ids = null;

  /// <summary>
  /// Gets the time zone from this provider that matches the system default time zone, if a matching time zone is
  /// available.
  /// </summary>
  /// <remarks>
  /// <para>
  /// Callers should be aware that this method will throw <see cref="DateTimeZoneNotFoundException"/> if no matching
  /// time zone is found. For the built-in Noda Time providers, this is unlikely to occur in practice (assuming
  /// the system is using a standard Windows time zone), but can occur even then, if no mapping is found. The TZDB
  /// source contains mappings for almost all Windows system time zones, but a few (such as "Mid-Atlantic Standard Time")
  /// are unmappable.
  /// </para>
  /// </remarks>
  /// <exception cref="DateTimeZoneNotFoundException">The system default time zone is not mapped by
  /// this provider.</exception>
  /// <returns>
  /// The provider-specific representation of the system default time zone.
  /// </returns>
  Future<DateTimeZone> GetSystemDefault();

  /// <summary>
  /// Returns the time zone for the given ID, if it's available.
  /// </summary>
  /// <remarks>
  /// <para>
  /// Note that this may return a <see cref="DateTimeZone"/> that has a different ID to that requested, if the ID
  /// provided is an alias.
  /// </para>
  /// <para>
  /// Note also that this method is not required to return the same <see cref="DateTimeZone"/> instance for
  /// successive requests for the same ID; however, all instances returned for a given ID must compare
  /// as equal.
  /// </para>
  /// <para>
  /// The fixed-offset timezones with IDs "UTC" and "UTC+/-Offset" are always available.
  /// </para>
  /// </remarks>
  /// <param name="id">The time zone ID to find.</param>
  /// <returns>The <see cref="DateTimeZone" /> for the given ID or null if the provider does not support
  /// the given ID.</returns>
  Future<DateTimeZone> GetZoneOrNull(String id);

  /// <summary>
  /// Returns the time zone for the given ID.
  /// </summary>
  /// <remarks>
  /// <para>
  /// Unlike <see cref="GetZoneOrNull"/>, this indexer will never return a null reference. If the ID is not
  /// supported by this provider, it will throw <see cref="DateTimeZoneNotFoundException" />.
  /// </para>
  /// <para>
  /// Note that this may return a <see cref="DateTimeZone"/> that has a different ID to that requested, if the ID
  /// provided is an alias.
  /// </para>
  /// <para>
  /// Note also that this method is not required to return the same <see cref="DateTimeZone"/> instance for
  /// successive requests for the same ID; however, all instances returned for a given ID must compare
  /// as equal.
  /// </para>
  /// <para>
  /// The fixed-offset timezones with IDs "UTC" and "UTC+/-Offset" are always available.
  /// </para>
  /// </remarks>
  /// <param name="id">The time zone id to find.</param>
  /// <value>The <see cref="DateTimeZone" /> for the given ID.</value>
  /// <exception cref="DateTimeZoneNotFoundException">This provider does not support the given ID.</exception>
  // todo: drop the operator [] support if we're going to have async an sync support?
  Future<DateTimeZone> operator [](String id);

  DateTimeZone getDateTimeZoneSync(String id);

  /// Returns a sequence of time zones from the specified provider,
  /// in the same order in which the IDs are returned by the provider.
  Future<Iterable<DateTimeZone>> GetAllZones() async {
    // var ids = await GetIds();
    var futureZones = Ids.map((id) => this[id]);
    return await Future.wait(futureZones);
  }

}