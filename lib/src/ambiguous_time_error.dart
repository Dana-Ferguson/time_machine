// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/AmbiguousTimeException.cs
// 0958802  on Jun 18, 2017

import 'package:meta/meta.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';

class AmbiguousTimeError extends Error {
  /// Get the local date and time which is ambiguous in the time zone.
  /// <value>The local date and time which is ambiguous in the time zone.</value>
  @internal LocalDateTime get localDateTime => earlierMapping.LocalDateTime;

  /// The time zone in which the local date and time is ambiguous.
  /// <value>The time zone in which the local date and time is ambiguous.</value>
  DateTimeZone get Zone => earlierMapping.Zone;

  /// Gets the earlier of the two occurrences of the local date and time within the time zone.
  /// <value>The earlier of the two occurrences of the local date and time within the time zone.</value>
  final ZonedDateTime earlierMapping;

  /// Gets the later of the two occurrences of the local date and time within the time zone.
  /// <value>The later of the two occurrences of the local date and time within the time zone.</value>
  final ZonedDateTime laterMapping;

  final String message;

  /// Constructs an instance from the given information.
  /// <remarks>
  /// <para>
  /// User code is unlikely to need to deliberately call this constructor except
  /// possibly for testing.
  /// </para>
  /// <para>
  /// The two mappings must have the same local time and time zone.
  /// </para>
  /// </remarks>
  /// <param name="earlierMapping">The earlier possible mapping</param>
  /// <param name="laterMapping">The later possible mapping</param>
  AmbiguousTimeError(this.earlierMapping, this.laterMapping)
      : message = "Local time ${earlierMapping.LocalDateTime} is ambiguous in time zone ${earlierMapping.Zone.Id}" {
    Preconditions.checkArgument(earlierMapping.Zone == laterMapping.Zone, 'laterMapping',
        "Ambiguous possible values must use the same time zone");
    Preconditions.checkArgument(earlierMapping.LocalDateTime == laterMapping.LocalDateTime, 'laterMapping',
        "Ambiguous possible values must have the same local date/time");
  }
}
