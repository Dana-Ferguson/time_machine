// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// todo: make this time_machine_internal.dart and then hide the other imports! (move library documentation here)
// todo: investigate: https://github.com/pinkfish/flutter_native_timezone

// https://github.com/dart-lang/sdk/issues/24581
import 'dart:async';
import 'src/platforms/platform_io.dart'
  // `dart.library.js` is compatible with node and browser via dart2js -- `dart.library.html` will only work for the browser
  // or at lest it seemed it should be, when I tried `dart.library.js` in chrome, it failed to evaluate to true
  if (dart.library.html) 'src/platforms/web.dart'
  if (dart.library.io) 'src/platforms/vm.dart'
  //if (dart.library.js) "package:time_machine/src/platforms/web.dart"
  //if (dart.library.io) "package:time_machine/src/platforms/vm.dart"
  // looks like Flutter has all the same import defines as the vm does.. so, I'm going with a runtime flag instead of a compile time flag
  // e.g., Flutter does not support mirrors and isolates (I think) -- yet, the defines are true
  // if (dart.library.io) "src/platforms/flutter.dart"
as timeMachine;

// todo: lots of spiders in this one!
export 'src/calendar_system.dart' show CalendarSystem;

export 'src/isodayofweek.dart' show IsoDayOfWeek;

export 'src/i_datetimezone_provider.dart' show IDateTimeZoneProvider;
export 'src/datetimezone.dart' show DateTimeZone;
export 'src/zoneddatetime.dart' show ZonedDateTime;

export 'src/localtime.dart' show LocalTime;
export 'src/localdate.dart' show LocalDate;
export 'src/localdatetime.dart' show LocalDateTime;

export 'src/duration.dart' show Span;
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
export 'src/calendars/i_week_rule.dart' show IWeekYearRule;
export 'src/calendars/week_year_rules.dart' show WeekYearRules, CalendarWeekRule;

// Fields (no public classes)

// Globalization
export 'src/text/globalization/culture.dart' show Cultures, CultureInfo;
// todo: Do we want to expose the Builder?
export 'src/text/globalization/datetime_format_info.dart' show BclCalendarType, DateTimeFormatInfo, DateTimeFormatInfoBuilder;

// Patterns (no public classes)

// Text
export 'src/text/composite_pattern_builder.dart' show CompositePatternBuilder;
export 'src/text/i_pattern.dart' show IPattern;
export 'src/text/parse_result.dart' show ParseResult;
export 'src/text/unparsable_value_error.dart' show UnparsableValueError;
export 'src/text/period_pattern.dart' show PeriodPattern;
export 'src/text/invalid_pattern_error.dart' show InvalidPatternError;

export 'src/text/localdate_pattern.dart' show LocalDatePattern;
export 'src/text/localtime_pattern.dart' show LocalTimePattern;
export 'src/text/localdatetime_pattern.dart' show LocalDateTimePattern;

export 'src/text/annual_date_pattern.dart' show AnnualDatePattern;
export 'src/text/duration_pattern.dart' show SpanPattern;
export 'src/text/instant_pattern.dart' show InstantPattern;
export 'src/text/offset_date_pattern.dart' show OffsetDatePattern;
export 'src/text/offset_datetime_pattern.dart' show OffsetDateTimePattern;
export 'src/text/offset_pattern.dart' show OffsetPattern;
export 'src/text/offset_time_pattern.dart' show OffsetTimePattern;
export 'src/text/zoneddatetime_pattern.dart' show ZonedDateTimePattern;

// TimeZones
// todo: why is this public?
export 'src/timezones/datetimezone_cache.dart' show DateTimeZoneCache;
export 'src/timezones/datetimezone_notfound_error.dart' show DateTimeZoneNotFoundError;
export 'src/timezones/delegates.dart';
export 'src/timezones/i_datetimezone_source.dart' show IDateTimeZoneSource;
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
  static Future initialize([dynamic arg]) {
    if (_initialized) return null;
    _initialized = true;
    return timeMachine.initialize(arg);
  }
}