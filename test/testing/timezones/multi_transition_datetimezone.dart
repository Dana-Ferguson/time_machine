// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Testing/TimeZones/MultiTransitionDateTimeZone.cs
// 9b8ed83  on Aug 24, 2017

import 'dart:math' as math;

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_timezones.dart';

T min<T extends Comparable>(x, y) => x < y ? x : y;
T max<T extends Comparable>(x, y) => x > y ? x : y;

/// <summary>
/// Time zone with multiple transitions, created via a builder.
/// </summary>
class MultiTransitionDateTimeZone extends DateTimeZone {
  /// <summary>
  /// Gets the zone intervals within this time zone, in chronological order, spanning the whole time line.
  /// </summary>
  /// <value>The zone intervals within this time zone, in chronological order, spanning the whole time line.</value>
  final List<ZoneInterval> Intervals;

  /// <summary>
  /// Gets the transition points between intervals.
  /// </summary>
  /// <value>The transition points between intervals.</value>
  final List<Instant> Transitions;

  MultiTransitionDateTimeZone(String id, List<ZoneInterval> intervals)
      : Intervals = intervals.toList(),
        Transitions = intervals.skip(1).map((x) => x.start).toList(),
        super(id, intervals.length == 1,
          intervals.map((x) => x.wallOffset).reduce(min),
          intervals.map((x) => x.wallOffset).reduce(max));

  /// <inheritdoc />
  @override ZoneInterval GetZoneInterval(Instant instant) {
    int lower = 0; // Inclusive
    int upper = Intervals.length; // Exclusive

    while (lower < upper) {
      int current = (lower + upper) ~/ 2;
      var candidate = Intervals[current];
      if (candidate.HasStart && candidate.start > instant) {
        upper = current;
      }
      else if (candidate.HasEnd && candidate.end <= instant) {
        lower = current + 1;
      }
      else {
        return candidate;
      }
    }
    // Note: this would indicate a bug. The time zone is meant to cover the whole of time.
    throw new StateError("Instant $instant did not exist in time zone $id.");
  }
}

/// <summary>
/// Builder to create instances of <see cref="MultiTransitionDateTimeZone"/>. Each builder
/// can only be built once.
/// </summary>
class MtdtzBuilder {
  final List<ZoneInterval> intervals = new List<ZoneInterval>();
  Offset currentStandardOffset;
  Offset currentSavings;
  String currentName;
  bool built = false;

  /// <summary>
  /// Gets the ID of the time zone which will be built.
  /// </summary>
  /// <value>The ID of the time zone which will be built.</value>
  String id;

//  /// <summary>
//  /// Constructs a builder using an ID of "MultiZone", an initial offset of zero (standard and savings),
//  /// and an initial name of "First".
//  /// </summary>
//  Builder() : this(0, 0);

  /// <summary>
  /// Constructs a builder using the given first name, standard offset, and a daylight saving
  /// offset of 0. The ID is initially "MultiZone".
  /// </summary>
  /// <param name="firstName">Name of the first zone interval.</param>
  /// <param name="firstOffsetHours">Standard offset in hours in the first zone interval.</param>
  MtdtzBuilder.withName(int firstOffsetHours, String firstName)
      : this(firstOffsetHours, 0, firstName);

//  /// <summary>
//  /// Constructs a builder using the given standard offset and saving offset. The ID is initially "MultiZone".
//  /// </summary>
//  /// <param name="firstStandardOffsetHours">Standard offset in hours in the first zone interval.</param>
//  /// <param name="firstSavingOffsetHours">Standard offset in hours in the first zone interval.</param>
//  Builder([int firstStandardOffsetHours = 0, int firstSavingOffsetHours = 0])
//      : this(firstStandardOffsetHours, firstSavingOffsetHours, "First") {
//  }

  /// <summary>
  /// Constructs a builder using the given first name, standard offset, and daylight saving offset.
  /// The ID is initially "MultiZone".
  /// </summary>
  /// <param name="firstStandardOffsetHours">Standard offset in hours in the first zone interval.</param>
  /// <param name="firstSavingOffsetHours">Daylight saving offset in hours in the first zone interval.</param>
  /// <param name="firstName">Name of the first zone interval.</param>
  MtdtzBuilder([int firstStandardOffsetHours = 0, int firstSavingOffsetHours = 0, String firstName = "First"]) {
    id = "MultiZone";
    currentName = firstName;
    currentStandardOffset = new Offset.fromHours(firstStandardOffsetHours);
    currentSavings = new Offset.fromHours(firstSavingOffsetHours);
  }

  /// <summary>
  /// Adds a transition at the given instant, to the specified new standard offset,
  /// with the new specified daylight saving. The name is generated from the transition.
  /// </summary>
  /// <param name="transition">Instant at which the zone changes.</param>
  /// <param name="newStandardOffsetHours">The new standard offset, in hours.</param>
  /// <param name="newSavingOffsetHours">The new daylight saving offset, in hours.</param>
  /// <param name="newName">The new zone interval name.</param>
  void Add(Instant transition, int newStandardOffsetHours, [int newSavingOffsetHours = 0, String newName = null]) {
    if (newName == null) newName = "Interval from $transition";

    EnsureNotBuilt();
    Instant previousStart = intervals.length == 0 ? null : intervals.last.end;
// The ZoneInterval constructor will perform validation.
    intervals.add(new ZoneInterval(currentName, previousStart, transition, currentStandardOffset + currentSavings, currentSavings));
    currentName = newName;
    currentStandardOffset = new Offset.fromHours(newStandardOffsetHours);
    currentSavings = new Offset.fromHours(newSavingOffsetHours);
  }

  /// <summary>
  /// Builds a <see cref="MultiTransitionDateTimeZone"/> from this builder, invalidating it in the process.
  /// </summary>
  /// <returns>The newly-built zone.</returns>
  MultiTransitionDateTimeZone Build() {
    EnsureNotBuilt();
    built = true;
    Instant previousStart = intervals.length == 0 ? null : intervals.last.end;
    intervals.add(new ZoneInterval(currentName, previousStart, null, currentStandardOffset + currentSavings, currentSavings));
    return new MultiTransitionDateTimeZone(id, intervals);
  }

  void EnsureNotBuilt() {
    if (built) {
      throw new StateError("Cannot use a builder after building");
    }
  }
}