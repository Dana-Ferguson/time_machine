import 'package:time_machine/src/time_machine_internal.dart';

/// <summary>
/// Represents a transition two different time references.
/// </summary>
/// <remarks>
/// <para>
/// Normally this is between standard time and daylight savings time.
/// </para>
/// <para>
/// Immutable, thread safe.
/// </para>
/// </remarks>
// todo: internal sealed
class ZoneTransition {
  /// Initializes a new instance of the [ZoneTransition] class.
  ///
  /// <remarks>
  /// </remarks>
  /// <param name='instant'>The instant that this transistion occurs at.</param>
  /// <param name='name'>The name for the time at this transition e.g. PDT or PST.</param>
  /// <param name='standardOffset'>The standard offset at this transition.</param>
  /// <param name='savings'>The actual offset at this transition.</param>
  ZoneTransition(this.instant, this.name, this.standardOffset, this.savings) {
    Preconditions.checkNotNull(name, 'name');
  }

  /// The instant at which the transition occurs.
  final Instant instant;

  /// The name of the zone interval after this transition.
  final String name;

  /// The standard offset after this transition.
  final Offset standardOffset;

  /// The daylight savings after this transition.
  final Offset savings;

  /// The wall offset (savings + standard) after this transition.
  Offset get wallOffset => standardOffset + savings;

  /// Determines whether is a transition from the given transition.
  ///
  /// <remarks>
  /// To be a transition from another the instant at which the transition occurs must be
  /// greater than the given transition's and at least one aspect out of (name, standard
  /// offset, wall offset) must differ. If this is not true then this transition is considered
  /// to be redundant and should not be used. Note that there are a few transitions which
  /// keep the same wall offset and name, but differ in how that wall offset is divided into
  /// daylight saving and standard components. One notable example of this is October 27th 1968, when
  /// the UK went from 'British Summer Time' (BST, standard=0, daylight=1) to "British Standard Time"
  /// (BST, standard=1, daylight=0).
  /// </remarks>
  /// <param name='other'>The <see cref="ZoneTransition"/> to compare to.</param>
  /// <returns>
  /// <c>true</c> if this is a transition from the given transition; otherwise, <c>false</c>.
  /// </returns>
  bool isTransitionFrom(ZoneTransition? other) {
    if (other == null) {
      return true;
    }
    bool later = instant > other.instant;
    bool different = name != other.name || standardOffset != other.standardOffset || savings != other.savings;
    return later && different;
  }

  /// <summary>
  /// Creates a new zone interval from this transition to the given end point.
  /// </summary>
  /// <param name='end'>The end of the interval.</param>
  ZoneInterval toZoneInterval(Instant end) => IZoneInterval.newZoneInterval(name, instant, end, standardOffset + savings, savings);

// #region Object overrides

  /// <summary>
  /// Returns a <see cref='System.String'/> that represents this instance.
  /// </summary>
  /// <returns>
  /// A <see cref='System.String'/> that represents this instance.
  /// </returns>
  @override String toString() => '$name at $instant $standardOffset [$savings]';
// #endregion // Object overrides
}
