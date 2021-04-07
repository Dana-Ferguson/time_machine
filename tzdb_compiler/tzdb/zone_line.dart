import 'package:time_machine/src/time_machine_internal.dart';

import 'parser_helper.dart';
import 'rule_line.dart';
import 'zone_rule_set.dart';

/// Contains the parsed information from one 'Zone' line of the TZDB zone database.
///
/// <remarks>
/// Immutable, thread-safe
/// </remarks>
// todo: internal
@immutable
class ZoneLine {
  static final OffsetPattern _percentZPattern = OffsetPattern.createWithInvariantCulture('i');

  /// Initializes a new instance of the [ZoneLine] class.
  const ZoneLine(this.name, this.standardOffset, this.rules, this.format, this.untilYear, this.untilYearOffset);

  final ZoneYearOffset untilYearOffset;

  final int untilYear;

  /// Returns the format for generating the label for this time zone. May contain '%s' to
  /// be replaced by a daylight savings indicator, or '%z' to be replaced by an offset indicator.
  final String format;

  /// Returns the name of the time zone.
  final String name;

  /// Returns the offset to add to UTC for this time zone's standard time.
  final Offset standardOffset;

  /// The name of the set of rules applicable to this zone line, or
  /// null for just standard time, or an offset for a 'fixed savings' rule.
  final String? rules;

// #region IEquatable<Zone> Members

  /// Indicates whether the current object is equal to another object of the same type.
  ///
  /// <param name='other'>An object to compare with this object.</param>
  /// <returns>
  ///   true if the current object is equal to the <paramref name = 'other' /> parameter;
  ///   otherwise, false.
  /// </returns>
  bool equals(ZoneLine other) {
    if (identical(this, other)) {
      return true;
    }
    var result = name == other.name && standardOffset == other.standardOffset && rules == other.rules && format == other.format && untilYear == other.untilYear;
    if (untilYear != Platform.int32MaxValue) {
      result = result && untilYearOffset.equals(other.untilYearOffset);
    }
    return result;
  }

  @override bool operator ==(Object other) => other is ZoneLine && equals(other);

// #endregion


  ///   Returns a hash code for this instance.
  ///
  /// <returns>
  ///   A hash code for this instance, suitable for use in hashing algorithms and data
  ///   structures like a hash table.
  /// </returns>
  @override int get hashCode {
    var hashables = [
      name,
      standardOffset,
      rules,
      format,
      untilYear
    ];


    if (untilYear != Platform.int32MaxValue) {
      // todo: should this be hashCode???
      hashables.add(untilYearOffset.hashCode);
    }

    return hashObjects(hashables);
  }


  ///   Returns a <see cref='System.String' /> that represents this instance.
  ///
  /// <returns>
  ///   A <see cref='System.String' /> that represents this instance.
  /// </returns>
  @override
  String toString() {
    var builder = StringBuffer();
    builder..write(name)..write(' ');
    builder..write(standardOffset)..write(' ');
    builder..write(ParserHelper.formatOptional(rules))..write(' ');
    builder.write(format);
    if (untilYear != Platform.int32MaxValue) {
      builder..write(' ')..write(untilYear.toString().padLeft(4, '0'))..write(" ")..write(untilYearOffset);
    }
    return builder.toString();
  }

  ZoneRuleSet resolveRules(Map<String, List<RuleLine>> allRules) {
    if (rules == null) {
      var name = formatName(Offset.zero, '');
      return ZoneRuleSet.named(name, standardOffset, Offset.zero, untilYear, untilYearOffset);
    }

    // allRules.
    if (allRules.containsKey(rules)) {
      var ruleSet = allRules[rules]!;
      var _rules = <ZoneRecurrence>[];
      for (var zoneRecurrenceRules in ruleSet.map((x) => x.GetRecurrences(this))) {
        _rules.addAll(zoneRecurrenceRules);
      }
      return ZoneRuleSet.rules(_rules, standardOffset, untilYear, untilYearOffset);
    }
    else {
      try {
        // Check if Rules actually just refers to a savings.
        var savings = ParserHelper.parseOffset(rules!);
        var name = formatName(savings, '');
        return ZoneRuleSet.named(name, standardOffset, savings, untilYear, untilYearOffset);
      }
      on FormatException {
        throw ArgumentError(
            "Daylight savings rule name '$rules' for zone $name is neither a known ruleset nor a fixed offset");
      }
    }
  }

  String formatName(Offset savings, String daylightSavingsIndicator) {
    int index = format.indexOf('/');
    if (index >= 0) {
      return savings == Offset.zero ? format.substring(0, index) : format.substring(index + 1);
    }
    // todo: is this the same?
    index = format.indexOf('%s');
    if (index >= 0) {
      var left = format.substring(0, index);
      var right = format.substring(index + 2);
      return left + daylightSavingsIndicator + right;
    }
    // todo: is this the same?
    index = format.indexOf('%z');
    if (index >= 0) {
      var left = format.substring(0, index);
      var right = format.substring(index + 2);
      return left + _percentZPattern.format(standardOffset + savings) + right;
    }
    return format;
  }
}
