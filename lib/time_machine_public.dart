// todo: make this time_machine.dart and then hide the other imports! (move library documentation here)
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

// export 'time_machine.dart' show Instant, AmbiguousTimeError;

export 'src/calendar_system.dart';

export 'src/isodayofweek.dart' show IsoDayOfWeek;

export 'src/i_datetimezone_provider.dart' show IDateTimeZoneProvider;
export 'src/datetimezone.dart' show DateTimeZone;
export 'src/zoneddatetime.dart' show ZonedDateTime;

export 'src/localtime.dart' show LocalTime;
export 'src/localdate.dart' show LocalDate;
export 'src/localdatetime.dart';

export 'src/duration.dart' show Span;
export 'src/instant.dart' show Instant;
export 'src/interval.dart' show Interval;

export 'src/time_constants.dart';

export 'src/clock.dart';
export 'src/zoned_clock.dart';
export 'src/system_clock.dart';

export 'src/ambiguous_time_error.dart' show AmbiguousTimeError;
export 'src/skipped_time_error.dart' show SkippedTimeError;

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

bool _initialized = false;

abstract class TimeMachine {
  static Future initialize([dynamic arg]) {
    if (_initialized) return null;
    _initialized = true;
    return timeMachine.initialize(arg);
  }
}