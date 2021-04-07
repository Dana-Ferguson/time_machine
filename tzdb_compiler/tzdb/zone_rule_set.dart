import 'package:time_machine/src/time_machine_internal.dart';

/// A rule set associated with a single Zone line, after any rules
/// associated with it have been resolved to a collection of ZoneRecurrences.
/// It may have an upper bound, or extend to infinity: lower bounds aren't known.
/// Likewise it may have rules associated with it, or just a fixed offset and savings.
// todo: internal sealed
class ZoneRuleSet {
  // Either rules or name+fixedSavings is specified.
  final List<ZoneRecurrence> _rules; // = new List<ZoneRecurrence>();
  final String? _name;
  final Offset _fixedSavings;
  final int _upperYear;
  final ZoneYearOffset _upperYearOffset;
  final Offset standardOffset;

  ZoneRuleSet.rules(this._rules, this.standardOffset, this._upperYear, this._upperYearOffset)
      :
        _name = null,
        _fixedSavings = Offset.zero;

  ZoneRuleSet.named(this._name, this.standardOffset, this._fixedSavings, this._upperYear, this._upperYearOffset)
      :
        _rules = [];

  /// Returns <c>true</c> if this rule set extends to the end of time, or
  /// <c>false</c> if it has a finite end point.
  bool get isInfinite => _upperYear == Platform.int32MaxValue;

  bool get isFixed => _name != null;

  Iterable<ZoneRecurrence> get rules => _rules;

  ZoneInterval CreateFixedInterval(Instant start) {
    Preconditions.checkState(isFixed, 'Rule set is not fixed');
    var limit = GetUpperLimit(_fixedSavings);
    return IZoneInterval.newZoneInterval(_name!, start, limit, standardOffset + _fixedSavings, _fixedSavings);
  }

  /// <summary>
  /// Gets the inclusive upper limit of time that this rule set applies to.
  /// </summary>
  /// <param name='savings'>The daylight savings value during the final zone interval.</param>
  /// <returns>The <see cref='LocalInstant'/> of the upper limit for this rule set.</returns>
  Instant GetUpperLimit(Offset savings) {
    if (isInfinite) {
      return IInstant.afterMaxValue;
    }
    var localInstant = _upperYearOffset.getOccurrenceForYear(_upperYear);
    var offset = _upperYearOffset.getRuleOffset(standardOffset, savings);
    return localInstant.safeMinus(offset);
  }
}
