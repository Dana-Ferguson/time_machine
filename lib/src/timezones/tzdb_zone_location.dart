// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/TzdbZoneLocation.cs
// 0554a6c  on Mar 31, 2015

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

/// <summary>
/// A location entry generated from the "zone.tab" file in a TZDB release. This can be used to provide
/// users with a choice of time zone, although it is not internationalized.
/// </summary>
/// <threadsafety>This type is immutable reference type. See the thread safety section of the user guide for more information.</threadsafety>
@immutable
/*sealed*/ class TzdbZoneLocation
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
  /// Gets the English name of the country containing the location, which is never empty.
  /// </summary>
  /// <value>The English name of the country containing the location.</value>
  final String CountryName;

  /// <summary>
  /// Gets the ISO-3166 2-letter country code for the country containing the location.
  /// </summary>
  /// <value>The ISO-3166 2-letter country code for the country containing the location.</value>
  final String CountryCode;

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

  // TzdbZone1970Location._(this.Comment, this.Countries, this.latitudeSeconds, this.longitudeSeconds, this.ZoneId);
  TzdbZoneLocation._(this.Comment, this.CountryCode, this.CountryName, this.latitudeSeconds, this.longitudeSeconds, this.ZoneId);

  /// <summary>
  /// Creates a new location.
  /// </summary>
  /// <remarks>This constructor is only for the sake of testability. Non-test code should
  /// usually obtain locations from a <see cref="TzdbDateTimeZoneSource"/>.
  /// </remarks>
  /// <param name="latitudeSeconds">Latitude of the location, in seconds.</param>
  /// <param name="longitudeSeconds">Longitude of the location, in seconds.</param>
  /// <param name="countryName">English country name of the location, in degrees. Must not be null.</param>
  /// <param name="countryCode">ISO-3166 country code of the location. Must not be null.</param>
  /// <param name="zoneId">Time zone identifier of the location. Must not be null.</param>
  /// <param name="comment">Optional comment. Must not be null, but may be empty.</param>
  /// <exception cref="ArgumentOutOfRangeException">The latitude or longitude is invalid.</exception>
  factory TzdbZoneLocation(int latitudeSeconds, int longitudeSeconds, String countryName, String countryCode, String zoneId, String comment)
  {
    Preconditions.checkArgumentRange('latitudeSeconds', latitudeSeconds, -90 * 3600, 90 * 3600);
    Preconditions.checkArgumentRange('longitudeSeconds', longitudeSeconds, -180 * 3600, 180 * 3600);
    var CountryName = Preconditions.checkNotNull(countryName, 'countryName');
    var CountryCode = Preconditions.checkNotNull(countryCode, 'countryCode');
    Preconditions.checkArgument(CountryName.length > 0, 'countryName', "Country name cannot be empty");
    Preconditions.checkArgument(CountryCode.length == 2, 'countryCode', "Country code must be two characters");
    var ZoneId = Preconditions.checkNotNull(zoneId, 'zoneId');
    var Comment = Preconditions.checkNotNull(comment, 'comment');

    return new TzdbZoneLocation._(Comment, CountryCode, CountryName, latitudeSeconds, longitudeSeconds, ZoneId);
  }

  @internal void Write(IDateTimeZoneWriter writer)
  {
    throw new UnimplementedError('This feature is not supported.');
//    writer.WriteSignedCount(latitudeSeconds);
//    writer.WriteSignedCount(longitudeSeconds);
//    writer.WriteString(CountryName);
//    writer.WriteString(CountryCode);
//    writer.WriteString(ZoneId);
//    writer.WriteString(Comment);
  }

  @internal static TzdbZoneLocation Read(DateTimeZoneReader reader) {
    int latitudeSeconds = reader.readInt32(); // reader.ReadSignedCount();
    int longitudeSeconds = reader.readInt32(); // reader.ReadSignedCount();
    String countryName = reader.readString();
    String countryCode = reader.readString();
    String zoneId = reader.readString();
    String comment = reader.readString();
    // We could duplicate the validation, but there's no good reason to. It's odd
    // to catch ArgumentException, but we're in pretty tight control of what's going on here.
    try {
      return new TzdbZoneLocation(latitudeSeconds, longitudeSeconds, countryName, countryCode, zoneId, comment);
    }
    on ArgumentError catch (e) {
      throw new InvalidTimeDataError("Invalid zone location data in stream", e);
    }
  }
}