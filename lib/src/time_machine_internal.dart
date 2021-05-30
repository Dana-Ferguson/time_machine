/// This library provides functions for working with time inside machines running Dart.
library time_machine;

export 'package:meta/meta.dart';

export 'yearmonthday.dart';
export 'yearmonthday_and_calendar.dart';

export 'calendar_ordinal.dart';
export 'calendar_system.dart';

export 'dayofweek.dart';

export 'datetimezone_provider.dart';
export 'datetimezone.dart';
export 'zoneddatetime.dart';

export 'localinstant.dart';
export 'localtime.dart';
export 'localdate.dart';
export 'localdatetime.dart';

export 'duration.dart';
export 'instant.dart';
export 'interval.dart';

export 'time_constants.dart';

export 'clock.dart';
export 'zoned_clock.dart';
export 'system_clock.dart';

// todo: should probably push this to time_machine_utilities
export 'utility/utilities.dart';

export 'ambiguous_time_error.dart';
export 'skipped_time_error.dart';

export 'annual_date.dart';
export 'date_adjusters.dart';
export 'date_interval.dart';
export 'time_adjusters.dart';

export 'offset.dart';
export 'offset_date.dart';
export 'offset_time.dart';
export 'offset_datetime.dart';

export 'period.dart';
export 'period_units.dart';
export 'period_builder.dart';

export 'package:time_machine/src/calendars/time_machine_calendars.dart';
export 'package:time_machine/src/fields/time_machine_fields.dart';
export 'package:time_machine/src/text/globalization/time_machine_globalization.dart';
export 'package:time_machine/src/text/patterns/time_machine_patterns.dart';
export 'package:time_machine/src/text/time_machine_text.dart';
export 'package:time_machine/src/timezones/time_machine_timezones.dart';
export 'package:time_machine/src/utility/time_machine_utilities.dart';

class _Internal{
  const _Internal();
}

/// Any accessible function marked with this annotation should not be considered part of the public API.
///
/// This is a placeholder annotation so we know where all the internal only code is, so we can work out a possible strategy in the future.
/// We may be able to restructure the library when it's more mature to remedy this situation.
/// The only 'easy' tool provided in the dart ecosystem is `part/part of` keywords and their usage has been discouraged with possible removal in the future.
///
/// What I might do is just separate the classes into a public facing interface only classes and a set of
/// implementation classes (much like a lot to the io\stream classes).
/// src/public ~ src/internal ~ or I could just do one large public file with all the classes
// this is now a part of meta
// const Object internal = const _Internal();

/// This was internal in Noda Time, but I'm considering keeping it public in Time Machine
const Object wasInternal = _Internal();

/// This is a marker to ease in porting. When the port is finished, this should be removable without causing any errors.
class _Private {
  const _Private();
}

const Object private = _Private();


class _DDCSupportHack {
  const _DDCSupportHack();
}

// todo: make sure ddcSupportHack's have bad names -- so we can get a reverse Contagion effect
/// DDC has some bugs -- and I want to reserve judgement until 2.0 stable
/// 1) DDC can't @override methods without parameters with optional parameters, while Dart2JS and DartVM can.
const Object ddcSupportHack = _DDCSupportHack();

/// This indicates that the class is meant to be used as an interface
class _Interface {
  const _Interface();
}

const Object interface = _Interface();
