import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_patterns.dart';
import 'package:time_machine/time_machine_text.dart';

// This file contains all the delegates declared within the NodaTime.Text namespace.
// It's simpler than either nesting them or giving them a file per delegate.
@internal typedef void CharacterHandler<TResult, TBucket extends ParseBucket<TResult>>(PatternCursor patternCursor, SteppedPatternBuilder<TResult, TBucket> patternBuilder);
