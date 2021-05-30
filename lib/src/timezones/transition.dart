// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
// import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/src/time_machine_internal.dart';

/// A transition between two offsets, usually for daylight saving reasons. This type only knows about
/// the new offset, and the transition point.
@immutable
@internal
class Transition {
  final Instant instant;

  /// The offset from the time when this transition occurs until the next transition.
  final Offset newOffset;

  const Transition(this.instant, this.newOffset);

  bool equals(Transition other) => instant == other.instant && newOffset == other.newOffset;

  /// Implements the operator == (equality).
  ///
  /// [left]: The left hand side of the operator.
  /// [right]: The right hand side of the operator.
  /// Returns: `true` if values are equal to each other, otherwise `false`.
  @override
  bool operator ==(Object right) => right is Transition && equals(right);

  /// Returns a hash code for this instance.
  ///
  /// A hash code for this instance, suitable for use in hashing algorithms and data
  /// structures like a hash table.
  @override int get hashCode => hash2(Instant, newOffset);

  /// Returns a [String] that represents this instance.
  @override String toString() => 'Transition to $newOffset at $instant';
}
