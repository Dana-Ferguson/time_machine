// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
// import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

/// A location entry generated from the 'zone1970.tab' file in a TZDB release. This can be used to provide
/// users with a choice of time zone, although it is not internationalized. This is equivalent to
/// [TzdbZoneLocation], except that multiple countries may be represented.
@immutable
class TzdbZone1970Location {
  final int _latitudeSeconds, _longitudeSeconds;

  /// Gets the latitude in degrees; positive for North, negative for South.
  ///
  /// The value will be in the range [-90, 90].
  double get latitude => _latitudeSeconds / 3600.0;

  /// Gets the longitude in degrees; positive for East, negative for West.
  ///
  /// The value will be in the range [-180, 180].
  double get longitude => _longitudeSeconds / 3600.0;

  /// Gets the list of countries associated with this location.
  ///
  /// The list is immutable, and will always contain at least one entry. The list is
  /// in the order specified in 'zone1970.tab', so the first entry is always the
  /// country containing the position indicated by the latitude and longitude, and
  /// is the most populous country in the list. No entry in this list is ever null.
  // todo: make immutable list?
  final List<TzdbZone1970LocationCountry> countries;

  /// The ID of the time zone for this location.
  ///
  /// If this mapping was fetched from a [TzdbDateTimeZoneSource], it will always be a valid ID within that source.
  final String zoneId;

  /// Gets the comment (in English) for the mapping, if any.
  ///
  /// This is usually used to differentiate between locations in the same country.
  /// This will return an empty string if no comment was provided in the original data.
  final String comment;

  const TzdbZone1970Location._(this.comment, this.countries, this._latitudeSeconds, this._longitudeSeconds, this.zoneId);

  /// Creates a new location.
  ///
  /// This constructor is only for the sake of testability. Non-test code should
  /// usually obtain locations from a [TzdbDateTimeZoneSource].
  ///
  /// [latitudeSeconds]: Latitude of the location, in seconds.
  /// [longitudeSeconds]: Longitude of the location, in seconds.
  /// [countries]: Countries associated with this location. Must not be null, must have at least
  /// one entry, and all entries must be non-null.
  /// [zoneId]: Time zone identifier of the location. Must not be null.
  /// [comment]: Optional comment. Must not be null, but may be empty.
  /// [ArgumentOutOfRangeException]: The latitude or longitude is invalid.
  factory TzdbZone1970Location(int latitudeSeconds, int longitudeSeconds,  List<TzdbZone1970LocationCountry?>? countries,  String zoneId, String comment) {
    Preconditions.checkArgumentRange('latitudeSeconds', latitudeSeconds, -90 * 3600, 90 * 3600);
    Preconditions.checkArgumentRange('longitudeSeconds', longitudeSeconds, -180 * 3600, 180 * 3600);

    var Countries = List<TzdbZone1970LocationCountry>.unmodifiable(Preconditions.checkNotNull(countries, 'countries'));
    Preconditions.checkArgument(Countries.isNotEmpty, 'countries', "Collection must contain at least one entry");
    // for (var entry in Countries) {
    //   Preconditions.checkArgument(entry != null, 'countries', "Collection must not contain null entries");
    // }
    var ZoneId = Preconditions.checkNotNull(zoneId, 'zoneId');
    var Comment = Preconditions.checkNotNull(comment, 'comment');

    return TzdbZone1970Location._(Comment, Countries, latitudeSeconds, longitudeSeconds, ZoneId);
  }

  @internal void write(IDateTimeZoneWriter writer) {
    // We considered writing out the ISO-3166 file as a separate field,
    // so we can reuse objects, but we don't actually waste very much space this way,
    // due to the string pool... and the increased code complexity isn't worth it.

    writer.writeInt32(_latitudeSeconds);
    writer.writeInt32(_longitudeSeconds);

    writer.write7BitEncodedInt(countries.length);
    countries.forEach((country) {
      writer.writeString(country.name);
      writer.writeString(country.code);
    });

    writer.writeString(zoneId);
    writer.writeString(comment);
  }

  @internal static TzdbZone1970Location read(DateTimeZoneReader reader)
  {
    int latitudeSeconds = reader.readInt32();
    int longitudeSeconds = reader.readInt32();
    int countryCount = reader.read7BitEncodedInt();
    var countries = <TzdbZone1970LocationCountry>[];
    for (int i = 0; i < countryCount; i++)
    {
      String countryName = reader.readString();
      String countryCode = reader.readString();
      countries.add(TzdbZone1970LocationCountry(countryName, countryCode));
    }
    String zoneId = reader.readString();
    String comment = reader.readString();
    // We could duplicate the validation, but there's no good reason to. It's odd
    // to catch ArgumentException, but we're in pretty tight control of what's going on here.
    try
    {
      return TzdbZone1970Location(latitudeSeconds, longitudeSeconds, countries, zoneId, comment);
    }
    on ArgumentError catch (e) {
      throw InvalidTimeDataError('Invalid zone location data in stream', e);
    }
  }
}


/// A country represented within an entry in the 'zone1970.tab' file, with the English name
/// mapped from the 'iso3166.tab' file.
@immutable
class TzdbZone1970LocationCountry {
  /// Gets the English name of the country.
  final String name;

  /// Gets the ISO-3166 2-letter country code for the country.
  final String code;

  /// Constructs a new country from its name and ISO-3166 2-letter code.
  ///
  /// [name]: Country name; must not be empty.
  /// [code]: 2-letter code
  TzdbZone1970LocationCountry(this.name, this.code) {
    Preconditions.checkNotNull(name, 'name');
    Preconditions.checkNotNull(code, 'code');
    Preconditions.checkArgument(name.isNotEmpty, 'name', "Country name cannot be empty");
    Preconditions.checkArgument(code.length == 2, 'code', "Country code must be two characters");
  }

  /// Compares countries for equality, by name and code.
  ///
  /// [other]: The country to compare with this one.
  /// Returns: `true` if the given country has the same name and code as this one; `false` otherwise.
  bool equals(TzdbZone1970LocationCountry other) => other.code == code && other.name == name;

  @override bool operator==(Object other) => other is TzdbZone1970LocationCountry && other.code == code && other.name == name;

  /// Returns a hash code for this country.
  @override int get hashCode => hash2(name, code);

  /// Returns a string representation of this country, including the code and name.
  @override String toString() => '$code ($name)';
}
