/// This library provides functions for working with time inside machines running Dart.
library time_machine;

export 'src/yearmonthday.dart';
export 'src/yearmonthday_and_calendar.dart';

export 'src/calendar_ordinal.dart';
export 'src/calendar_system.dart';

export 'src/isodayofweek.dart';

export 'src/datetimezone.dart';
export 'src/zoneddatetime.dart';

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
export 'src/time_classes_tmp.dart';

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


// files skipped:
//  AssemblyInfo.cs -- well, obviously -- this include the friend references for testing
//  DateTimeZoneProviders.cs -- only doing TSDB -- this might take a different form?
//  IDateTimeZoneProvider.cs -- looks like this is sort of part of the js\vm_platform functionality
//  NamespaceDoc.cs -- just namespace documentation -- add to library level documentation?
//  NodaTime.csproj -- sort of like a pubspec.yaml
//

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
