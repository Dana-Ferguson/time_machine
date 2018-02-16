/// This library provides functions for working with time inside machines running Dart.
library time_machine;

export 'src/yearmonthday.dart';
export 'src/yearmonthday_and_calendar.dart';

export 'src/calendar_ordinal.dart';
export 'src/calendar_system.dart';

export 'src/isodayofweek.dart';
export 'src/time_constants.dart';

export 'src/datetimezone.dart';
export 'src/localtime.dart';
export 'src/localdate.dart';
export 'src/localdatetime.dart';

export 'src/duration.dart';
export 'src/instant.dart';

export 'src/time_classes_tmp.dart';

int calculate() {
  return 6 * 7;
}

class _Internal {
  const _Internal();
}

/// Any accessible function marked with this annotation should not be considered part of the public API.
///
/// This is a placeholder annotation so we know where all the internal only code is, so we can work out a possible strategy in the future.
/// We may be able to restructure the library when it's more mature to remedy this situation.
/// The only 'easy' tool provided in the dart ecosystem is `part/part of` keywords and their usage has been discouraged with possible removal in the future.
const Object internal = const _Internal();

class _Private {
  const _Private();
}

const Object private = const _Private();
