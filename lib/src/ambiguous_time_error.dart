// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

@immutable
class AmbiguousTimeError extends Error {
  /// Get the local date and time which is ambiguous in the time zone.
  @internal LocalDateTime get localDateTime => earlierMapping.localDateTime;

  /// The time zone in which the local date and time is ambiguous.
  DateTimeZone get Zone => earlierMapping.zone;

  /// Gets the earlier of the two occurrences of the local date and time within the time zone.
  final ZonedDateTime earlierMapping;

  /// Gets the later of the two occurrences of the local date and time within the time zone.
  final ZonedDateTime laterMapping;

  final String message;

  /// Constructs an instance from the given information.
  ///
  /// User code is unlikely to need to deliberately call this constructor except
  /// possibly for testing.
  ///
  /// The two mappings must have the same local time and time zone.
  ///
  /// * [earlierMapping]: The earlier possible mapping
  /// * [laterMapping]: The later possible mapping
  AmbiguousTimeError(this.earlierMapping, this.laterMapping)
      : message = 'Local time ${earlierMapping.localDateTime} is ambiguous in time zone ${earlierMapping.zone.id}' {
    Preconditions.checkArgument(earlierMapping.zone == laterMapping.zone, 'laterMapping',
        'Ambiguous possible values must use the same time zone');
    Preconditions.checkArgument(earlierMapping.localDateTime == laterMapping.localDateTime, 'laterMapping',
        'Ambiguous possible values must have the same local date/time');
  }
}

