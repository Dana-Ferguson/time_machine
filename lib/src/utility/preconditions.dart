// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// todo: Look into what we want do do with debug-only checks

/// Helper static methods for argument/state validation.
class Preconditions {
  /// Returns the given argument after checking whether it's null. This is useful for putting
  /// nullity checks in parameters which are passed to base class constructors.
  static T checkNotNull<T>(T? argument, String paramName) // where T : class
  {
    if (argument == null) {
      throw ArgumentError.notNull(paramName);
    }
    return argument;
  }

  // todo: Remove ... we don't do the debug -- actually check on that? Rig through dev dependencies?
  /// Like [Preconditions.checkNotNull], but only checked in debug builds. (This means it can't return
  /// anything...)
  //[Conditional('DEBUG')]
  static void debugCheckNotNull<T>(T argument, String paramName) // where T : class
  {
    // #if DEBUG
    if (argument == null) {
      throw ArgumentError.notNull(paramName);
    }
  // #endif
  }

  // Note: this overload exists for performance reasons. It would be reasonable to call the
  // version using 'long' values, but we'd incur conversions on every call. This method
  // may well be called very often.
  static void checkArgumentRange(String paramName, int value, int minInclusive, int maxInclusive) {
    if (value < minInclusive || value > maxInclusive) {
      throw RangeError.range(value, minInclusive, maxInclusive, paramName);
    }
  }

  /// Range change to perform just within debug builds. This is typically for internal sanity checking, where we normally
  /// trusting the argument value to be valid, and adding a check just for the sake of documentation - and to help find
  /// internal bugs during development.
  // [Conditional('DEBUG')]
  static bool debugCheckArgumentRange(String paramName, int value, int minInclusive, int maxInclusive) {
    checkArgumentRange(paramName, value, minInclusive, maxInclusive);
    return true;
  }

  // [ContractAnnotation('expression:false => halt')]
  // [Conditional('DEBUG')]
  static bool debugCheckArgument(bool expression, String parameter, String message) {
    checkArgument(expression, parameter, message);
    return true;
  }

  // [ContractAnnotation('expression:false => halt')]
  static void checkArgument(bool? expression, String parameter, String message) {
    if (expression == null || !expression) {
      throw ArgumentError('$message (parameter name: $parameter)');
    }
  }

  static void checkState(bool? expression, String message) {
    if (expression == null || !expression) {
      throw StateError(message);
    }
  }

  // [ContractAnnotation('expression:false => halt')]
  // [Conditional('DEBUG')]
  static void debugCheckState(bool expression, String message) {
    // #if DEBUG
    checkState(expression, message);
  // #endif
  }
}

