// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// todo: investigate: https://github.com/pinkfish/flutter_native_timezone

// https://github.com/dart-lang/sdk/issues/24581
import 'dart:async';
import 'src/platforms/platform_io.dart'
  // `dart.library.js` is compatible with node and browser via dart2js -- `dart.library.html` will only work for the browser
  // or at lest it seemed it should be, when I tried `dart.library.js` in chrome, it failed to evaluate to true
  if (dart.library.html) 'src/platforms/web.dart'
  if (dart.library.io) 'src/platforms/vm.dart'
as time_machine;

export 'src/calendar_system.dart' show CalendarSystem;

export 'src/dayofweek.dart' show DayOfWeek;

export 'src/datetimezone_provider.dart' show DateTimeZoneProvider;
export 'src/datetimezone.dart' show DateTimeZone;
export 'src/zoneddatetime.dart' show ZonedDateTime;

export 'src/localtime.dart' show LocalTime;
export 'src/localdate.dart' show LocalDate;
export 'src/localdatetime.dart' show LocalDateTime;

export 'src/duration.dart' show Time;
export 'src/instant.dart' show Instant;
export 'src/interval.dart' show Interval;

export 'src/time_constants.dart' show TimeConstants;

export 'src/clock.dart' show Clock;
export 'src/zoned_clock.dart' show ZonedClock;
export 'src/system_clock.dart' show SystemClock;

export 'src/ambiguous_time_error.dart' show AmbiguousTimeError;
export 'src/skipped_time_error.dart' show SkippedTimeError;

export 'src/annual_date.dart' show AnnualDate;
export 'src/date_adjusters.dart' show DateAdjusters;
export 'src/date_interval.dart' show DateInterval;
export 'src/time_adjusters.dart' show TimeAdjusters;

export 'src/offset.dart' show Offset;
export 'src/offset_date.dart' show OffsetDate;
export 'src/offset_time.dart' show OffsetTime;
export 'src/offset_datetime.dart' show OffsetDateTime;

export 'src/period.dart' show Period;
export 'src/period_units.dart' show PeriodUnits;
export 'src/period_builder.dart' show PeriodBuilder;

// Utility
export 'src/utility/invalid_time_data_error.dart' show InvalidTimeDataError;

// Calendars
export 'src/calendars/era.dart' show Era;
export 'src/calendars/week_rule.dart' show WeekYearRule;
export 'src/calendars/week_year_rules.dart' show WeekYearRules, CalendarWeekRule;
export 'src/calendars/hebrew_month_numbering.dart' show HebrewMonthNumbering;
export 'src/calendars/islamic_epoch.dart' show IslamicEpoch;
export 'src/calendars/islamic_leap_year_pattern.dart' show IslamicLeapYearPattern;

// Fields (no public classes)

// Globalization
export 'src/text/globalization/culture.dart' show Cultures, Culture;
// todo: Do we want to expose the Builder?
export 'src/text/globalization/datetime_format_info.dart' show CalendarType, DateTimeFormat, DateTimeFormatBuilder;

// Patterns (no public classes)

// TimeZones
// todo: why is this public? (investigate)
export 'src/timezones/datetimezone_cache.dart' show DateTimeZoneCache;

export 'src/timezones/datetimezone_notfound_error.dart' show DateTimeZoneNotFoundError;
export 'src/timezones/delegates.dart';
export 'src/timezones/datetimezone_source.dart' show DateTimeZoneSource;
export 'src/timezones/invalid_datetimezone_source_error.dart' show InvalidDateTimeZoneSourceError;
export 'src/timezones/resolvers.dart' show Resolvers;
export 'src/timezones/tzdb_datetimezone_source.dart' show DateTimeZoneProviders, TzdbDateTimeZoneSource;

// These are not used (but aren't @internal either)
// export 'src/timezones/tzdb_zone_1970_location.dart';
// export 'src/timezones/tzdb_zone_location.dart';

export 'src/timezones/zone_equality_comparer.dart' show ZoneEqualityComparerOptions, ZoneEqualityComparer;
export 'src/timezones/zoneinterval.dart' show ZoneInterval;
export 'src/timezones/zone_local_mapping.dart' show ZoneLocalMapping;

bool _initialized = false;

abstract class TimeMachine {
  TimeMachine() { throw StateError('TimeMachine can not be instantiated, because no platform has been detected.'); }
  static Future initialize([Map args = const {}]) {
    if (_initialized) return Future.sync(() => null);
    _initialized = true;
    return time_machine.initialize(args);
  }
}
