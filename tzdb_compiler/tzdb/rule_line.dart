import 'package:time_machine/src/time_machine_internal.dart';

import 'zone_line.dart';

/// Defines one 'Rule' line from the tz data. (This may be applied to multiple zones.)
///
/// <remarks>
/// Immutable, threadsafe.
/// </remarks>
@immutable
class RuleLine // implements Comparable<RuleLine> // IEquatable<RuleLine>
{
  /// The string to replace '%s' with (if any) when formatting the zone name key.
  ///
  /// <remarks>This is always used to replace %s, whether or not the recurrence
  /// actually includes savings; it is expected to be appropriate to the recurrence.</remarks>
  final String _daylightSavingsIndicator;

  /// The recurrence pattern for the rule.
  final ZoneRecurrence _recurrence;

  /// Returns the name of the rule set this rule belongs to.
  String get name => _recurrence.name;

  /// The 'type' of the rule - usually null, meaning "applies in every year" - but can be
  /// 'odd', "even" etc - usually yearistype.sh is used to determine this; TimeMachine only supports
  /// 'odd' and "even" (used in Australia for data up to and including 2000e).
  final String? type;

  /// Initializes a new instance of the [RuleLine] class.
  ///
  /// <param name='recurrence'>The recurrence definition of this rule.</param>
  /// <param name='daylightSavingsIndicator'>The daylight savings indicator letter for time zone names.</param>
  const RuleLine(this._recurrence, this._daylightSavingsIndicator, this.type);

// #region IEquatable<ZoneRule> Members
  /// <summary>
  ///   Indicates whether the current object is equal to another object of the same type.
  /// </summary>
  /// <param name='other'>An object to compare with this object.</param>
  /// <returns>
  ///   true if the current object is equal to the <paramref name = 'other' /> parameter;
  ///   otherwise, false.
  /// </returns>
  bool equals(RuleLine other) =>
      _recurrence.equals(other._recurrence) &&
      _daylightSavingsIndicator == other._daylightSavingsIndicator;

// #endregion

// #region Operator overloads
  /// Implements the operator ==.
  @override
  bool operator ==(Object other) => other is RuleLine && equals(other);

  /// <summary>
  /// Retrieves the recurrence, after applying the specified name format.
  /// </summary>
  /// <remarks>
  /// Multiple zones may apply the same set of rules as to when they change into/out of
  /// daylight saving time, but with different names.
  /// </remarks>
  /// <param name='zone'>The zone for which this rule is being considered.</param>
  Iterable<ZoneRecurrence> GetRecurrences(ZoneLine zone) sync* {
    String name =
        zone.formatName(_recurrence.savings, _daylightSavingsIndicator);
    if (type == null) {
      yield _recurrence.withName(name);
    } else {
      var yearPredicate = _getYearPredicate();
      // Apply a little sanity...
      if (_recurrence.isInfinite ||
          _recurrence.toYear - _recurrence.fromYear > 1000) {
        throw UnsupportedError(
            "TimeMachine does not support 'typed' rules over large periods");
      }
      for (int year = _recurrence.fromYear;
          year <= _recurrence.toYear;
          year++) {
        if (yearPredicate(year)) {
          yield _recurrence.forSingleYear(year).withName(name);
        }
      }
    }
  }

  bool Function(int) _getYearPredicate() {
    switch (type) {
      case 'odd':
        return (year) => year.isOdd;
      case 'even':
        return (year) => year.isEven;
      default:
        throw UnsupportedError(
            'TimeMachine does not support rules of type $type');
    }
  }

  /// Returns a hash code for this instance.
  @override
  int get hashCode => hash2(_recurrence, _daylightSavingsIndicator);

  /// Returns a [String] that represents this instance.
  @override
  String toString() {
    var builder = StringBuffer();
    builder.write(_recurrence);
    builder..write(" \"")..write(_daylightSavingsIndicator)..write("\"");
    return builder.toString();
  }
}
