import 'package:time_machine/time_machine.dart';
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';


Matcher instantIsCloseTo(Instant value) => new InstantIsCloseTo(value, Span.epsilon);

class InstantIsCloseTo extends Matcher {
  final Instant _value;
  final Span _delta;

  const InstantIsCloseTo(this._value, this._delta);

  bool matches(item, Map matchState) {
    if (item is Instant) {
      var diff = (item > _value) ? item - _value : _value - item;
      // if (diff < 0) diff = -diff;
      return (diff <= _delta);
    } else {
      return false;
    }
  }

  Description describe(Description description) => description
      .add('a Instant value within ')
      .addDescriptionOf(_delta)
      .add(' of ')
      .addDescriptionOf(_value);

  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    if (item is Instant) {
      var diff = (item > _value) ? item - _value : _value - item;
      // if (diff < Span.zero) diff = -diff;
      return mismatchDescription.add(' differs by ').addDescriptionOf(diff);
    } else {
      return mismatchDescription.add(' not Instant');
    }
  }
}
