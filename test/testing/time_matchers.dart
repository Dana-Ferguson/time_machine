// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'package:time_machine/src/time_machine_internal.dart';
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';


Matcher instantIsCloseTo(Instant value) => InstantIsCloseTo(value, Time.epsilon);

/// Returns the uncached version of the given zone. If the zone isn't
/// an instance of CachedDateTimeZone, the same reference is returned back.
DateTimeZone Uncached(DateTimeZone zone)
{
  // 'as' will return 'null' in C#, throws exception in Dart
  if (zone is! CachedDateTimeZone?) return zone;

  CachedDateTimeZone? cached = zone as CachedDateTimeZone?;
  return cached == null ? zone : cached.timeZone;
}

// Matcher throwsAsync<T>() => new Throws(wrapMatcher(new isInstanceOf<T>()));
Matcher willThrow<T>() => throwsA(TypeMatcher<T>());
// Matcher throws<T>() => throwsA(new isInstanceOf<T>());

// throwsA(new isInstanceOf<ArgumentError>()));

class InstantIsCloseTo extends Matcher {
  final Instant _value;
  final Time _delta;

  const InstantIsCloseTo(this._value, this._delta);

  @override
  bool matches(item, Map matchState) {
    if (item is Instant) {
      var diff = (item > _value) ? _value.timeUntil(item) : item.timeUntil(_value);
      // if (diff < 0) diff = -diff;
      return (diff <= _delta);
    } else {
      return false;
    }
  }

  @override
  Description describe(Description description) => description
      .add('a Instant value within ')
      .addDescriptionOf(_delta)
      .add(' of ')
      .addDescriptionOf(_value);

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    if (item is Instant) {
      var diff = (item > _value) ? _value.timeUntil(item) : item.timeUntil(_value);
      // if (diff < Span.zero) diff = -diff;
      return mismatchDescription.add(' differs by ').addDescriptionOf(diff);
    } else {
      return mismatchDescription.add(' not Instant');
    }
  }
}

