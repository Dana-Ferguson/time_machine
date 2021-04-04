// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

/// A location entry generated from the 'zone.tab' file in a TZDB release. This can be used to provide
/// users with a choice of time zone, although it is not internationalized.
@immutable
class TzdbZoneLocation
{
  final int _latitudeSeconds, _longitudeSeconds;

  /// Gets the latitude in degrees; positive for North, negative for South.
  ///
  /// The value will be in the range [-90, 90].
  double get latitude => _latitudeSeconds / 3600.0;

  /// Gets the longitude in degrees; positive for East, negative for West.
  ///
  /// The value will be in the range [-180, 180].
  double get longitude => _longitudeSeconds / 3600.0;

  /// Gets the English name of the country containing the location, which is never empty.
  final String countryName;

  /// Gets the ISO-3166 2-letter country code for the country containing the location.
  final String countryCode;

  /// The ID of the time zone for this location.
  ///
  /// If this mapping was fetched from a [TzdbDateTimeZoneSource], it will always be a valid ID within that source.
  final String zoneId;

  /// Gets the comment (in English) for the mapping, if any.
  ///
  /// This is usually used to differentiate between locations in the same country.
  /// This will return an empty string if no comment was provided in the original data.
  final String comment;

  // TzdbZone1970Location._(this.Comment, this.Countries, this.latitudeSeconds, this.longitudeSeconds, this.ZoneId);
  const TzdbZoneLocation._(this.comment, this.countryCode, this.countryName, this._latitudeSeconds, this._longitudeSeconds, this.zoneId);

  /// Creates a new location.
  ///
  /// This constructor is only for the sake of testability. Non-test code should
  /// usually obtain locations from a [TzdbDateTimeZoneSource].
  ///
  /// [latitudeSeconds]: Latitude of the location, in seconds.
  /// [longitudeSeconds]: Longitude of the location, in seconds.
  /// [countryName]: English country name of the location, in degrees. Must not be null.
  /// [countryCode]: ISO-3166 country code of the location. Must not be null.
  /// [zoneId]: Time zone identifier of the location. Must not be null.
  /// [comment]: Optional comment. Must not be null, but may be empty.
  /// [ArgumentOutOfRangeException]: The latitude or longitude is invalid.
  factory TzdbZoneLocation(int latitudeSeconds, int longitudeSeconds, String countryName, String countryCode, String zoneId, String comment)
  {
    Preconditions.checkArgumentRange('latitudeSeconds', latitudeSeconds, -90 * 3600, 90 * 3600);
    Preconditions.checkArgumentRange('longitudeSeconds', longitudeSeconds, -180 * 3600, 180 * 3600);
    var CountryName = Preconditions.checkNotNull(countryName, 'countryName');
    var CountryCode = Preconditions.checkNotNull(countryCode, 'countryCode');
    Preconditions.checkArgument(CountryName.isNotEmpty, 'countryName', "Country name cannot be empty");
    Preconditions.checkArgument(CountryCode.length == 2, 'countryCode', "Country code must be two characters");
    var ZoneId = Preconditions.checkNotNull(zoneId, 'zoneId');
    var Comment = Preconditions.checkNotNull(comment, 'comment');

    return TzdbZoneLocation._(Comment, CountryCode, CountryName, latitudeSeconds, longitudeSeconds, ZoneId);
  }

  @internal void write(IDateTimeZoneWriter writer)
  {
    writer.writeInt32(_latitudeSeconds);
    writer.writeInt32(_longitudeSeconds);
    writer.writeString(countryName);
    writer.writeString(countryCode);
    writer.writeString(zoneId);
    writer.writeString(comment);
  }

  @internal static TzdbZoneLocation read(DateTimeZoneReader reader) {
    int latitudeSeconds = reader.readInt32(); // reader.ReadSignedCount();
    int longitudeSeconds = reader.readInt32(); // reader.ReadSignedCount();
    String countryName = reader.readString();
    String countryCode = reader.readString();
    String zoneId = reader.readString();
    String comment = reader.readString();
    // We could duplicate the validation, but there's no good reason to. It's odd
    // to catch ArgumentException, but we're in pretty tight control of what's going on here.
    try {
      return TzdbZoneLocation(latitudeSeconds, longitudeSeconds, countryName, countryCode, zoneId, comment);
    }
    on ArgumentError catch (e) {
      throw InvalidTimeDataError('Invalid zone location data in stream', e);
    }
  }
}
