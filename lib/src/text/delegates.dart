// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/text/patterns/time_machine_patterns.dart';
import 'package:time_machine/src/text/time_machine_text.dart';

// This file contains all the delegates declared within the NodaTime.Text namespace.
// It's simpler than either nesting them or giving them a file per delegate.
// @internal typedef CharacterHandler = void Function<TResult, TBucket extends ParseBucket<TResult>>(PatternCursor patternCursor, SteppedPatternBuilder<TResult, TBucket> patternBuilder);
@internal
typedef CharacterHandler<TResult, TBucket extends ParseBucket<TResult>> = void Function(PatternCursor patternCursor, SteppedPatternBuilder<TResult, TBucket> patternBuilder);

