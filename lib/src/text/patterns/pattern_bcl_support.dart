// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Text/Patterns/PatternBclSupport.cs
// a209e60  on Mar 18, 2015

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_text.dart';

/// <summary>
/// Class providing simple support for the various Parse/TryParse/ParseExact/TryParseExact/Format overloads
/// provided by individual types.
/// </summary>
@internal /*sealed*/ class PatternBclSupport<T>
{
  @private final FixedFormatInfoPatternParser<T> Function(NodaFormatInfo) patternParser;
  @private final String defaultFormatPattern;

  @internal PatternBclSupport(this.defaultFormatPattern, this.patternParser);

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