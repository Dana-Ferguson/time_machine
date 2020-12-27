// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

T min<T extends Comparable>(x, y) => x < y ? x : y;
T max<T extends Comparable>(x, y) => x > y ? x : y;

/// Time zone with multiple transitions, created via a builder.
class MultiTransitionDateTimeZone extends DateTimeZone {
  /// Gets the zone intervals within this time zone, in chronological order, spanning the whole time line.
  final List<ZoneInterval> Intervals;

  /// Gets the transition points between intervals.
  final List<Instant> Transitions;

  MultiTransitionDateTimeZone(String id, List<ZoneInterval> intervals)
      : Intervals = intervals.toList(),
        Transitions = intervals.skip(1).map((x) => x.start).toList(),
        super(id, intervals.length == 1,
          intervals.map((x) => x.wallOffset).reduce(min),
          intervals.map((x) => x.wallOffset).reduce(max));

  /// <inheritdoc />
  @override ZoneInterval getZoneInterval(Instant instant) {
    int lower = 0; // Inclusive
    int upper = Intervals.length; // Exclusive

    while (lower < upper) {
      int current = (lower + upper) ~/ 2;
      var candidate = Intervals[current];
      if (candidate.hasStart && candidate.start > instant) {
        upper = current;
      }
      else if (candidate.hasEnd && candidate.end <= instant) {
        lower = current + 1;
      }
      else {
        return candidate;
      }
    }
    // Note: this would indicate a bug. The time zone is meant to cover the whole of time.
    throw StateError('Instant $instant did not exist in time zone $id.');
  }
}

/// Builder to create instances of [MultiTransitionDateTimeZone]. Each builder
/// can only be built once.
class MtdtzBuilder {
  final List<ZoneInterval> intervals = <ZoneInterval>[];
  late Offset currentStandardOffset;
  late Offset currentSavings;
  late String currentName;
  bool built = false;

  /// Gets the ID of the time zone which will be built.
  late String id;

//  /// <summary>
//  /// Constructs a builder using an ID of 'MultiZone', an initial offset of zero (standard and savings),
//  /// and an initial name of 'First'.
//  /// </summary>
//  Builder() : this(0, 0);

  /// Constructs a builder using the given first name, standard offset, and a daylight saving
  /// offset of 0. The ID is initially 'MultiZone'.
  ///
  /// [firstName]: Name of the first zone interval.
  /// [firstOffsetHours]: Standard offset in hours in the first zone interval.
  MtdtzBuilder.withName(int firstOffsetHours, String firstName)
      : this(firstOffsetHours, 0, firstName);

//  /// <summary>
//  /// Constructs a builder using the given standard offset and saving offset. The ID is initially 'MultiZone'.
//  /// </summary>
//  /// <param name='firstStandardOffsetHours'>Standard offset in hours in the first zone interval.</param>
//  /// <param name='firstSavingOffsetHours'>Standard offset in hours in the first zone interval.</param>
//  Builder([int firstStandardOffsetHours = 0, int firstSavingOffsetHours = 0])
//      : this(firstStandardOffsetHours, firstSavingOffsetHours, 'First') {
//  }

  /// Constructs a builder using the given first name, standard offset, and daylight saving offset.
  /// The ID is initially 'MultiZone'.
  ///
  /// [firstStandardOffsetHours]: Standard offset in hours in the first zone interval.
  /// [firstSavingOffsetHours]: Daylight saving offset in hours in the first zone interval.
  /// [firstName]: Name of the first zone interval.
  MtdtzBuilder([int firstStandardOffsetHours = 0, int firstSavingOffsetHours = 0, String firstName = 'First']) {
    id = 'MultiZone';
    currentName = firstName;
    currentStandardOffset = Offset.hours(firstStandardOffsetHours);
    currentSavings = Offset.hours(firstSavingOffsetHours);
  }

  /// Adds a transition at the given instant, to the specified new standard offset,
  /// with the new specified daylight saving. The name is generated from the transition.
  ///
  /// [transition]: Instant at which the zone changes.
  /// [newStandardOffsetHours]: The new standard offset, in hours.
  /// [newSavingOffsetHours]: The new daylight saving offset, in hours.
  /// [newName]: The new zone interval name.
  void Add(Instant transition, int newStandardOffsetHours, [int newSavingOffsetHours = 0, String? newName]) {
    newName ??= 'Interval from $transition';

    EnsureNotBuilt();
    Instant? previousStart = intervals.isEmpty ? null : intervals.last.end;
    // The ZoneInterval constructor will perform validation.
    intervals.add(IZoneInterval.newZoneInterval(currentName, previousStart, transition, currentStandardOffset + currentSavings, currentSavings));
    currentName = newName;
    currentStandardOffset = Offset.hours(newStandardOffsetHours);
    currentSavings = Offset.hours(newSavingOffsetHours);
  }

  /// Builds a [MultiTransitionDateTimeZone] from this builder, invalidating it in the process.
  ///
  /// Returns: The newly-built zone.
  MultiTransitionDateTimeZone Build() {
    EnsureNotBuilt();
    built = true;
    Instant? previousStart = intervals.isEmpty ? null : intervals.last.end;
    intervals.add(IZoneInterval.newZoneInterval(currentName, previousStart, null, currentStandardOffset + currentSavings, currentSavings));
    return MultiTransitionDateTimeZone(id, intervals);
  }

  void EnsureNotBuilt() {
    if (built) {
      throw StateError('Cannot use a builder after building');
    }
  }
}
