// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/text/patterns/time_machine_patterns.dart';

/// Base class for 'buckets' of parse data - as field values are parsed, they are stored in a bucket,
/// then the final value is calculated at the end.
@internal
abstract class ParseBucket<T> {
  /// Performs the final conversion from fields to a value. The parse can still fail here, if there
  /// are incompatible field values.
  ///
  /// [usedFields]: Indicates which fields were part of the original text pattern.
  /// [value]: Complete value being parsed
  ParseResult<T> calculateValue(PatternFields usedFields, String value);
}
