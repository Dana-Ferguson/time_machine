// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';

/// A transition between two offsets, usually for daylight saving reasons. This type only knows about
/// the new offset, and the transition point.
///
/// <threadsafety>This type is an immutable value type. See the thread safety section of the user guide for more information.</threadsafety>
@internal class Transition // : IEquatable<Transition>
    {
  @internal final Instant instant;

  /// The offset from the time when this transition occurs until the next transition.
  @internal final Offset NewOffset;

  @internal Transition(this.instant, this.NewOffset);

  bool Equals(Transition other) => instant == other.instant && NewOffset == other.NewOffset;

  /// Implements the operator == (equality).
  ///
  /// [left]: The left hand side of the operator.
  /// [right]: The right hand side of the operator.
  /// Returns: `true` if values are equal to each other, otherwise `false`.
  bool operator ==(dynamic right) => right is Transition && Equals(right);

  /// Returns a hash code for this instance.
  ///
  /// A hash code for this instance, suitable for use in hashing algorithms and data
  /// structures like a hash table.
  @override int get hashCode => hash2(Instant, NewOffset);

  /// Returns a [String] that represents this instance.
  ///
  /// A [String] that represents this instance.
  @override String toString() => "Transition to $NewOffset at $instant";
}
