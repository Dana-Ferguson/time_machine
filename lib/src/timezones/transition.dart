// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/TimeZones/Transition.cs
// 32a15d0  on Aug 24, 2017

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

/// <summary>
/// A transition between two offsets, usually for daylight saving reasons. This type only knows about
/// the new offset, and the transition point.
/// </summary>
/// 
/// <threadsafety>This type is an immutable value type. See the thread safety section of the user guide for more information.</threadsafety>
@internal class Transition // : IEquatable<Transition>
    {
  @internal final Instant instant;

  /// <summary>
  /// The offset from the time when this transition occurs until the next transition.
  /// </summary>
  @internal final Offset NewOffset;

  @internal Transition(this.instant, this.NewOffset);

  bool Equals(Transition other) => Instant == other.instant && NewOffset == other.NewOffset;

  /// <summary>
  /// Implements the operator == (equality).
  /// </summary>
  /// <param name="left">The left hand side of the operator.</param>
  /// <param name="right">The right hand side of the operator.</param>
  /// <returns><c>true</c> if values are equal to each other, otherwise <c>false</c>.</returns>
  bool operator ==(dynamic right) => right is Transition && Equals(right);

  /// <summary>
  /// Returns a hash code for this instance.
  /// </summary>
  /// <returns>
  /// A hash code for this instance, suitable for use in hashing algorithms and data
  /// structures like a hash table.
  /// </returns>
  @override int get hashCode => hash2(Instant, NewOffset);

  /// <summary>
  /// Returns a <see cref="System.String"/> that represents this instance.
  /// </summary>
  /// <returns>
  /// A <see cref="System.String"/> that represents this instance.
  /// </returns>
  @override String ToString() => "Transition to $NewOffset at $Instant";
}