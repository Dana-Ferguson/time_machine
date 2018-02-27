import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';

/// <summary>
/// Base class for "buckets" of parse data - as field values are parsed, they are stored in a bucket,
/// then the final value is calculated at the end.
/// </summary>
@internal abstract class ParseBucket<T> {
  /// <summary>
  /// Performs the final conversion from fields to a value. The parse can still fail here, if there
  /// are incompatible field values.
  /// </summary>
  /// <param name="usedFields">Indicates which fields were part of the original text pattern.</param>
  /// <param name="value">Complete value being parsed</param>
  @internal ParseResult<T> CalculateValue(PatternFields usedFields, String value);
}