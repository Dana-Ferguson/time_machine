// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/TzdbZone1970Location.cs
// 24fdeef  on Apr 10, 2017

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

/// <summary>
/// A location entry generated from the "zone1970.tab" file in a TZDB release. This can be used to provide
/// users with a choice of time zone, although it is not internationalized. This is equivalent to
/// <see cref="TzdbZoneLocation"/>, except that multiple countries may be represented.
/// </summary>
/// <threadsafety>This type is immutable reference type. See the thread safety section of the user guide for more information.</threadsafety>
@immutable
/* sealed */ class TzdbZone1970Location
{
  @private final int latitudeSeconds, longitudeSeconds;

  /// <summary>
  /// Gets the latitude in degrees; positive for North, negative for South.
  /// </summary>
  /// <remarks>The value will be in the range [-90, 90].</remarks>
  /// <value>The latitude in degrees; positive for North, negative for South.</value>
  double get Latitude => latitudeSeconds / 3600.0;

  /// <summary>
  /// Gets the longitude in degrees; positive for East, negative for West.
  /// </summary>
  /// <remarks>The value will be in the range [-180, 180].</remarks>
  /// <value>The longitude in degrees; positive for East, negative for West.</value>
  double get Longitude => longitudeSeconds / 3600.0;

  /// <summary>
  /// Gets the list of countries associated with this location.
  /// </summary>
  /// <remarks>
  /// The list is immutable, and will always contain at least one entry. The list is
  /// in the order specified in "zone1970.tab", so the first entry is always the
  /// country containing the position indicated by the latitude and longitude, and
  /// is the most populous country in the list. No entry in this list is ever null.
  /// </remarks>
  /// <value>The list of countries associated with this location</value>
  // IList
  final List<Country> Countries;

  /// <summary>
  /// The ID of the time zone for this location.
  /// </summary>
  /// <remarks>If this mapping was fetched from a <see cref="TzdbDateTimeZoneSource"/>, it will always be a valid ID within that source.
  /// </remarks>
  /// <value>The ID of the time zone for this location.</value>
  final String ZoneId;

  /// <summary>
  /// Gets the comment (in English) for the mapping, if any.
  /// </summary>
  /// <remarks>
  /// This is usually used to differentiate between locations in the same country.
  /// This will return an empty string if no comment was provided in the original data.
  /// </remarks>
  /// <value>The comment (in English) for the mapping, if any.</value>
  final String Comment;

  TzdbZone1970Location._(this.Comment, this.Countries, this.latitudeSeconds, this.longitudeSeconds, this.ZoneId);

  /// <summary>
  /// Creates a new location.
  /// </summary>
  /// <remarks>This constructor is only for the sake of testability. Non-test code should
  /// usually obtain locations from a <see cref="TzdbDateTimeZoneSource"/>.
  /// </remarks>
  /// <param name="latitudeSeconds">Latitude of the location, in seconds.</param>
  /// <param name="longitudeSeconds">Longitude of the location, in seconds.</param>
  /// <param name="countries">Countries associated with this location. Must not be null, must have at least
  /// one entry, and all entries must be non-null.</param>
  /// <param name="zoneId">Time zone identifier of the location. Must not be null.</param>
  /// <param name="comment">Optional comment. Must not be null, but may be empty.</param>
  /// <exception cref="ArgumentOutOfRangeException">The latitude or longitude is invalid.</exception>
  factory TzdbZone1970Location(int latitudeSeconds, int longitudeSeconds,  List<Country> countries,  String zoneId, String comment) {
    Preconditions.checkArgumentRange('latitudeSeconds', latitudeSeconds, -90 * 3600, 90 * 3600);
    Preconditions.checkArgumentRange('longitudeSeconds', longitudeSeconds, -180 * 3600, 180 * 3600);

    var Countries = new List<Country>.unmodifiable(Preconditions.checkNotNull(countries, 'countries'));
    Preconditions.checkArgument(Countries.length > 0, 'countries', "Collection must contain at least one entry");
    for (var entry in Countries) {
      Preconditions.checkArgument(entry != null, 'countries', "Collection must not contain null entries");
    }
    var ZoneId = Preconditions.checkNotNull(zoneId, 'zoneId');
    var Comment = Preconditions.checkNotNull(comment, 'comment');

    return new TzdbZone1970Location._(Comment, Countries, latitudeSeconds, longitudeSeconds, ZoneId);
  }

  @internal void Write(IDateTimeZoneWriter writer)
  {
    writer.WriteSignedCount(latitudeSeconds);
    writer.WriteSignedCount(longitudeSeconds);
    writer.WriteCount(Countries.length);
    // We considered writing out the ISO-3166 file as a separate field,
    // so we can reuse objects, but we don't actually waste very much space this way, 
    // due to the string pool... and the increased code complexity isn't worth it.
    for (var country in Countries)
    {
      writer.WriteString(country.Name);
      writer.WriteString(country.Code);
    }
    writer.WriteString(ZoneId);
    writer.WriteString(Comment);
  }

  @internal static TzdbZone1970Location Read(IDateTimeZoneReader reader)
  {
    int latitudeSeconds = reader.ReadSignedCount();
    int longitudeSeconds = reader.ReadSignedCount();
    int countryCount = reader.ReadCount();
    var countries = new List<Country>();
    for (int i = 0; i < countryCount; i++)
    {
      String countryName = reader.ReadString();
      String countryCode = reader.ReadString();
      countries.add(new Country(countryName, countryCode));
    }
    String zoneId = reader.ReadString();
    String comment = reader.ReadString();
    // We could duplicate the validation, but there's no good reason to. It's odd
    // to catch ArgumentException, but we're in pretty tight control of what's going on here.
    try
    {
      return new TzdbZone1970Location(latitudeSeconds, longitudeSeconds, countries, zoneId, comment);
    }
    on ArgumentError catch (e) {
    throw new InvalidTimeDataError("Invalid zone location data in stream", e);
    }
  }
}


/// <summary>
/// A country represented within an entry in the "zone1970.tab" file, with the English name
/// mapped from the "iso3166.tab" file.
/// </summary>
@immutable
/* sealed */ class Country // : IEquatable<Country>
    {
  /// <summary>
  /// Gets the English name of the country.
  /// </summary>
  /// <value>The English name of the country.</value>
  final String Name;

  /// <summary>
  /// Gets the ISO-3166 2-letter country code for the country.
  /// </summary>
  /// <value>The ISO-3166 2-letter country code for the country.</value>
  final String Code;

  /// <summary>
  /// Constructs a new country from its name and ISO-3166 2-letter code.
  /// </summary>
  /// <param name="name">Country name; must not be empty.</param>
  /// <param name="code">2-letter code</param>
  Country(this.Name, this.Code) {
    Preconditions.checkNotNull(Name, 'name');
    Preconditions.checkNotNull(Code, 'code');
    Preconditions.checkArgument(Name.length > 0, 'name', "Country name cannot be empty");
    Preconditions.checkArgument(Code.length == 2, 'code', "Country code must be two characters");
  }

  /// <summary>
  /// Compares countries for equality, by name and code.
  /// </summary>
  /// <param name="other">The country to compare with this one.</param>
  /// <returns><c>true</c> if the given country has the same name and code as this one; <c>false</c> otherwise.</returns>
  bool Equals(Country other) => other != null && other.Code == Code && other.Name == Name;

  /// <summary>
  /// Returns a hash code for this country.
  /// </summary>
  /// <returns>A hash code for this country.</returns>
  @override int get hashCode => hash2(Name, Code);

  /// <summary>
  /// Returns a string representation of this country, including the code and name.
  /// </summary>
  /// <returns>A string representation of this country.</returns>
  @override String toString() => "$Code ($Name)";
}