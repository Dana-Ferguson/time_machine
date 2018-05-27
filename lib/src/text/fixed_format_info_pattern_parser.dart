// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Text/FixedFormatInfoPatternParser.cs
// a209e60  on Mar 18, 2015

import 'package:meta/meta.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';


/// A pattern parser for a single format info, which caches patterns by text/style.
@internal /*@sealed*/ class FixedFormatInfoPatternParser<T>
{
  // It would be unusual to have more than 50 different patterns for a specific culture
  // within a real app.
  @private static const int CacheSize = 50;
  @private final Cache<String, IPattern<T>> cache;

  @internal FixedFormatInfoPatternParser(IPatternParser<T> patternParser, NodaFormatInfo formatInfo)
  : cache = new Cache<String, IPattern<T>>(CacheSize, (patternText) => patternParser.ParsePattern(patternText, formatInfo)
    // https://msdn.microsoft.com/en-us/library/system.stringcomparer.ordinal(v=vs.110).aspx
    // StringComparer object that performs a case-sensitive ordinal string comparison.
    /*StringComparer.Ordinal*/);

  @internal IPattern<T> ParsePattern(String pattern) => cache.GetOrAdd(pattern);
}