import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';

/// <summary>
/// Internal interface used by FixedFormatInfoPatternParser. Unfortunately
/// even though this is internal, implementations must either use public methods
/// or explicit interface implementation.
/// </summary>
@internal abstract class IPatternParser<T>
{
  IPattern<T> ParsePattern(String pattern, NodaFormatInfo formatInfo);
}