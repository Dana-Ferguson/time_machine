// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

// todo: verify with Dart Style Guide ... Should typedef's be UpperCaseInitial? (have some code that depends on that)
// Delegates used for mapping local date/time values to ZonedDateTime.

/// Chooses between two [ZonedDateTime] values that resolve to the same [LocalDateTime].
///
/// This delegate is used by [Resolvers.createMappingResolver] when handling an ambiguous local time,
/// due to clocks moving backward in a time zone transition (usually due to an autumnal daylight saving transition).
///
/// The returned value should be one of the two parameter values, based on the policy of the specific
/// implementation. Alternatively, it can throw an [AmbiguousTimeException] to implement a policy of
/// 'reject ambiguous times.'
///
/// See the [Resolvers] class for predefined implementations.
///
/// Implementations of this delegate can reasonably
/// assume that the target local date and time really is ambiguous; the behaviour when the local date and time
/// can be unambiguously mapped into the target time zone (or when it's skipped) is undefined.
///
/// [earlier]: The earlier of the ambiguous matches for the original local date and time
/// [later]: The later of the ambiguous matches for the original local date and time
/// [AmbiguousTimeException]: The implementation rejects requests to map ambiguous times.
///
/// A [ZonedDateTime] in the target time zone; typically, one of the two input parameters.
typedef AmbiguousTimeResolver = ZonedDateTime Function(ZonedDateTime earlier, ZonedDateTime later);

/// Resolves a [LocalDateTime] to a [ZonedDateTime] in the situation
/// where the requested local time does not exist in the target time zone.
///
/// This delegate is used by [Resolvers.createMappingResolver] when handling the situation where the
/// requested local time does not exist, due to clocks moving forward in a time zone transition (usually due to a
/// spring daylight saving transition).
///
/// The returned value will necessarily represent a different local date and time to the target one, but
/// the exact form of mapping is up to the delegate implementation. For example, it could return a value
/// as close to the target local date and time as possible, or the time immediately after the transition.
/// Alternatively, it can throw a [SkippedTimeException] to implement a policy of "reject
/// skipped times."
///
/// See the [Resolvers] class for predefined implementations.
///
/// Implementations of this delegate can reasonably
/// assume that the target local date and time really is skipped; the behaviour when the local date and time
/// can be directly mapped into the target time zone is undefined.
///
/// [localDateTime]: The local date and time to map to the given time zone
/// [zone]: The target time zone
/// [intervalBefore]: The zone interval directly before the target local date and time would have occurred
/// [intervalAfter]: The zone interval directly after the target local date and time would have occurred
/// [SkippedTimeException]: The implementation rejects requests to map skipped times.
/// Returns: A [ZonedDateTime] in the target time zone.
typedef SkippedTimeResolver = ZonedDateTime Function(LocalDateTime localDateTime,  DateTimeZone zone,
 ZoneInterval intervalBefore,  ZoneInterval intervalAfter);

/// Resolves the result of attempting to map a local date and time to a target time zone.
///
/// This delegate is consumed by [LocalDateTime.inZone] and [DateTimeZone.ResolveLocal(LocalDateTime, ZoneLocalMappingResolver)],
/// among others. It provides the strategy for converting a [ZoneLocalMapping] (the result of attempting
/// to map a local date and time to a target time zone) to a [ZonedDateTime].
///
/// See the [Resolvers] class for predefined implementations and a way of combining
/// separate [SkippedTimeResolver] and [AmbiguousTimeResolver] values.
///
/// [mapping]: The intermediate result of mapping a local time to a target time zone.
/// [AmbiguousTimeException]: The implementation rejects requests to map ambiguous times.
/// [SkippedTimeException]: The implementation rejects requests to map skipped times.
/// Returns: A [ZonedDateTime] in the target time zone.
typedef ZoneLocalMappingResolver = ZonedDateTime Function(ZoneLocalMapping mapping);

