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
import 'package:time_machine/time_machine_text.dart';

/// A builder for composite patterns.
///
/// A composite pattern is a combination of multiple patterns. When parsing, these are checked
/// in the order in which they are added to the builder with the [Add]
/// method, by trying to parse and seeing if the result is a successful one. When formatting,
/// the patterns are checked in the reverse order, using the predicate provided along with the pattern
/// when calling `Add`. The intention is that patterns are added in "most precise first" order,
/// and the predicate should indicate whether it can fully represent the given value - so the "less precise"
/// (and therefore usually shorter) pattern can be used first.
///
/// [T]: The type of value to be parsed or formatted by the resulting pattern.
///
/// This type is mutable, and should not be used between multiple threads. The patterns created
/// by the [Build] method are immutable and can be used between multiple threads, assuming
/// that each component (both pattern and predicate) is also immutable.
class CompositePatternBuilder<T> // : IEnumerable<IPattern<T>>
    {
  @private final List<IPattern<T>> patterns = new List<IPattern<T>>();
  final List<bool Function(T arg)> _formatPredicates = new List<bool Function(T arg)>();

  /// Constructs a new instance which initially has no component patterns. At least one component
  /// pattern must be added before [Build] is called.
  CompositePatternBuilder();

  /// Adds a component pattern to this builder.
  ///
  /// [pattern]: The component pattern to use as part of the eventual composite pattern.
  /// [formatPredicate]: A predicate to determine whether or not this pattern is suitable for
  /// formatting the given value.
  void Add(IPattern<T> pattern, bool Function(T arg) formatPredicate) {
    patterns.add(Preconditions.checkNotNull(pattern, 'pattern'));
    _formatPredicates.add(Preconditions.checkNotNull(formatPredicate, 'formatPredicate'));
  }

  /// Builds a composite pattern from this builder. Further changes to this builder
  /// will have no impact on the returned pattern.
  ///
  /// [InvalidOperationException]: No component patterns have been added.
  /// Returns: A pattern using the patterns added to this builder.
  IPattern<T> Build() {
    Preconditions.checkState(patterns.length != 0, "A composite pattern must have at least one component pattern.");
    return new _CompositePattern(patterns, _formatPredicates);
  }

  @internal IPartialPattern<T> BuildAsPartial() {
    Preconditions.debugCheckState(patterns.every((p) => p is IPartialPattern<T>), "All patterns should be partial");
    return Build(); // as IPartialPattern<T>;
  }

  /// GetEnumerator
  Iterable<IPattern<T>> GetEnumerator() => patterns; // GetEnumerator();
}

/*sealed*/ class _CompositePattern<T> implements IPartialPattern<T> {
  @private final List<IPattern<T>> patterns;
  @private final List<bool Function(T)> formatPredicates;

  @internal _CompositePattern(this.patterns, this.formatPredicates);

  ParseResult<T> Parse(String text) {
    for (IPattern<T> pattern in patterns) {
      ParseResult<T> result = pattern.Parse(text);
      if (result.Success || !result.ContinueAfterErrorWithMultipleFormats) {
        return result;
      }
    }
    return ParseResult.NoMatchingFormat<T>(new ValueCursor(text));
  }

  ParseResult<T> ParsePartial(ValueCursor cursor) {
    int index = cursor.Index;
    for (IPartialPattern<T> pattern in patterns) {
      cursor.Move(index);
      ParseResult<T> result = pattern.ParsePartial(cursor);
      if (result.Success || !result.ContinueAfterErrorWithMultipleFormats) {
        return result;
      }
    }
    cursor.Move(index);
    return ParseResult.NoMatchingFormat<T>(cursor);
  }

  String Format(T value) => FindFormatPattern(value).Format(value);

  StringBuffer AppendFormat(T value, StringBuffer builder) =>
      FindFormatPattern(value).AppendFormat(value, builder);

  @private IPattern<T> FindFormatPattern(T value) {
    for (int i = formatPredicates.length - 1; i >= 0; i--) {
      if (formatPredicates[i](value)) {
        return patterns[i];
      }
    }
    throw new FormatException("Composite pattern was unable to format value using any of the provided patterns.");
  }
}
