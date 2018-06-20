/// This library provides functions for working with time inside machines running Dart.
library time_machine;

import 'dart:async';

export 'src/yearmonthday.dart';
export 'src/yearmonthday_and_calendar.dart';

export 'src/calendar_ordinal.dart';
export 'src/calendar_system.dart';

export 'src/isodayofweek.dart';

export 'src/i_datetimezone_provider.dart';
export 'src/datetimezone.dart';
export 'src/zoneddatetime.dart';

export 'src/localinstant.dart';
export 'src/localtime.dart';
export 'src/localdate.dart';
export 'src/localdatetime.dart';

export 'src/duration.dart';
export 'src/instant.dart';
export 'src/interval.dart';

export 'src/time_constants.dart';

export 'src/clock.dart';
export 'src/zoned_clock.dart';
export 'src/system_clock.dart';

// todo: should probably push this to time_machine_utilities
export 'src/utility/utilities.dart';

export 'src/ambiguous_time_error.dart';
export 'src/skipped_time_error.dart';

export 'src/annual_date.dart';
export 'src/date_adjusters.dart';
export 'src/date_interval.dart';
export 'src/time_adjusters.dart';

export 'src/offset.dart';
export 'src/offset_date.dart';
export 'src/offset_time.dart';
export 'src/offset_datetime.dart';

export 'src/period.dart';
export 'src/period_units.dart';
export 'src/period_builder.dart';

// https://github.com/dart-lang/sdk/issues/24581
import "src/platforms/platform_io.dart"
  if (dart.library.html) "src/platforms/web.dart"
  if (dart.library.io) "src/platforms/vm.dart"
  // looks like Flutter has all the same import defines as the vm does.. so, I'm going with a runtime flag instead of a compile time flag
  // e.g., Flutter does not support mirrors and isolates (I think) -- yet, the defines are true
  // if (dart.library.io) "src/platforms/flutter.dart"
as timeMachine;

abstract class TimeMachine {
  static Future initialize([dynamic arg]) => timeMachine.initialize(arg);
}

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
const Object internal = const _Internal();

/// This is a marker to ease in porting. When the port is finished, this should be removable without causing any errors.
class _Private {
  const _Private();
}

const Object private = const _Private();


class _DDCSupportHack {
  const _DDCSupportHack();
}

// todo: make sure ddcSupportHack's have bad names -- so we can get a reverse Contagion effect
/// DDC has some bugs -- and I want to reserve judgement until 2.0 stable
/// 1) DDC can't @override methods without parameters with optional parameters, while Dart2JS and DartVM can.
const Object ddcSupportHack = const _DDCSupportHack();
