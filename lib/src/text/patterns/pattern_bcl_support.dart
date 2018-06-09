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
  @private final FixedFormatInfoPatternParser<T> Function(NodaFormatInfo) patternParser;
  @private final String defaultFormatPattern;

  @internal PatternBclSupport(this.defaultFormatPattern, this.patternParser);

  // todo: do we want to provide an interface for formatProviders?
  @internal String Format(T value, String patternText, /*IFormatProvider*/ Object formatProvider)
  {
    if (patternText == null || patternText.length == 0)
    {
      patternText = defaultFormatPattern;
    }
    NodaFormatInfo formatInfo = NodaFormatInfo.GetInstance(formatProvider);
    IPattern<T> pattern = patternParser(formatInfo).ParsePattern(patternText);
    return pattern.Format(value);
  }
}
