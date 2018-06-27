// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/text/time_machine_text.dart';


abstract class ICompositePatternBuilder {
  static IPartialPattern<T> buildAsPartial<T>(CompositePatternBuilder<T> compositePatternBuilder) => compositePatternBuilder._buildAsPartial();
}

/// A builder for composite patterns.
///
/// A composite pattern is a combination of multiple patterns. When parsing, these are checked
/// in the order in which they are added to the builder with the [add]
/// method, by trying to parse and seeing if the result is a successful one. When formatting,
/// the patterns are checked in the reverse order, using the predicate provided along with the pattern
/// when calling `Add`. The intention is that patterns are added in "most precise first" order,
/// and the predicate should indicate whether it can fully represent the given value - so the "less precise"
/// (and therefore usually shorter) pattern can be used first.
///
/// [T]: The type of value to be parsed or formatted by the resulting pattern.
///
/// This type is mutable, and should not be used between multiple threads. The patterns created
/// by the [build] method are immutable.
class CompositePatternBuilder<T> {
  final List<IPattern<T>> _patterns = new List<IPattern<T>>();
  // note: this was originally List<bool Function(T arg), but had to be dropped, because
  // in C#, you can have nested classes, so CompositePatternBuilder<T>._CompositePattern
  // would share their type parameter <T> ~ I'm a bit unsure how to do that here
  // And adding the generic to Function (which would be great for Type safety), means that
  // CompositePatternBuilder && _CompositePattern no longer work
  // ~ they could be verified at runtime - but Dart can't do it at compile time (not yet anyway?)
  // We also couldn't use [Object] iaw with the Style guide -- since that failed too???
  // todo: add back in type safety with a new method
  final List<bool Function(dynamic arg)> _formatPredicates = new List<bool Function(dynamic arg)>();

  /// Constructs a new instance which initially has no component patterns. At least one component
  /// pattern must be added before [build] is called.
  CompositePatternBuilder();

  /// Adds a component pattern to this builder.
  ///
  /// [pattern]: The component pattern to use as part of the eventual composite pattern.
  /// [formatPredicate]: A predicate to determine whether or not this pattern is suitable for
  /// formatting the given value.
  void add(IPattern<T> pattern, bool Function(dynamic arg) formatPredicate) {
    _patterns.add(Preconditions.checkNotNull(pattern, 'pattern'));
    _formatPredicates.add(Preconditions.checkNotNull(formatPredicate, 'formatPredicate'));
  }

  /// Builds a composite pattern from this builder. Further changes to this builder
  /// will have no impact on the returned pattern.
  ///
  /// [InvalidOperationException]: No component patterns have been added.
  /// Returns: A pattern using the patterns added to this builder.
  IPattern<T> build() {
    Preconditions.checkState(_patterns.length != 0, "A composite pattern must have at least one component pattern.");
    return new _CompositePattern<T>._(_patterns, _formatPredicates);
  }

  IPartialPattern<T> _buildAsPartial() {
    Preconditions.debugCheckState(_patterns.every((p) => p is IPartialPattern<T>), "All patterns should be partial");
    return build(); // as IPartialPattern<T>;
  }
}

class _CompositePattern<T> implements IPartialPattern<T> {
  final List<IPattern<T>> _patterns;
  final List<bool Function(dynamic arg)> _formatPredicates;

  _CompositePattern._(this._patterns, this._formatPredicates);

  ParseResult<T> parse(String text) {
    for (IPattern<T> pattern in _patterns) {
      ParseResult<T> result = pattern.parse(text);
      if (result.success || !IParseResult.continueAfterErrorWithMultipleFormats(result)) {
        return result;
      }
    }
    return IParseResult.noMatchingFormat<T>(new ValueCursor(text));
  }

  ParseResult<T> parsePartial(ValueCursor cursor) {
    int index = cursor.index;
    for (IPartialPattern<T> pattern in _patterns) {
      cursor.move(index);
      ParseResult<T> result = pattern.parsePartial(cursor);
      if (result.success || !IParseResult.continueAfterErrorWithMultipleFormats(result)) {
        return result;
      }
    }
    cursor.move(index);
    return IParseResult.noMatchingFormat<T>(cursor);
  }

  String format(T value) => _findFormatPattern(value).format(value);

  StringBuffer appendFormat(T value, StringBuffer builder) =>
      _findFormatPattern(value).appendFormat(value, builder);

  IPattern<T> _findFormatPattern(T value) {
    for (int i = _formatPredicates.length - 1; i >= 0; i--) {
      if (_formatPredicates[i](value)) {
        return _patterns[i];
      }
    }
    throw new FormatException("Composite pattern was unable to format value using any of the provided patterns.");
  }
}
