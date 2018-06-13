// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';

/// Class providing simple support for the various Parse/TryParse/ParseExact/TryParseExact/Format overloads
/// provided by individual types.
@internal /*sealed*/ class PatternBclSupport<T>
{
  final FixedFormatInfoPatternParser<T> Function(TimeMachineFormatInfo) _patternParser;
  final String _defaultFormatPattern;

  @internal PatternBclSupport(this._defaultFormatPattern, this._patternParser);

  // todo: do we want to provide an interface for formatProviders?
  @internal String format(T value, String patternText, /*IFormatProvider*/ Object formatProvider)
  {
    if (patternText == null || patternText.length == 0)
    {
      patternText = _defaultFormatPattern;
    }
    TimeMachineFormatInfo formatInfo = TimeMachineFormatInfo.getInstance(formatProvider);
    IPattern<T> pattern = _patternParser(formatInfo).parsePattern(patternText);
    return pattern.format(value);
  }
}
