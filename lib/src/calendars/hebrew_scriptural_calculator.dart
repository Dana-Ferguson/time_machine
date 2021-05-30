// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';

// todo: probably doesn't need such liberal use of arithmeticMod();

/// Implementation of the algorithms described in
/// http://www.cs.tau.ac.il/~nachum/calendar-book/papers/calendar.ps, using scriptural
/// month numbering.
@internal
abstract class HebrewScripturalCalculator {
  static const int maxYear = 9999;
  static const int minYear = 1;
  // Use the bottom two bits of the day value to indicate Heshvan/Kislev.
  // Using the top bits causes issues for negative day values (only relevant for
  // invalid years, but still problematic in general).
  static const int _isHeshvanLongCacheBit = 1 << 0;
  static const int _isKislevShortCacheBit = 1 << 1;
  // Number of bits to shift the elapsed days in order to get the cache value.
  static const int _elapsedDaysCacheShift = 2;

  // Cache of when each year starts (in  terms of absolute days). This is the heart of
  // the algorithm, so just caching this is highly effective.
  // Each entry additionally encodes the length of Heshvan and Kislev. We could encode
  // more information too, but those are the tricky bits.
  static final List<YearStartCacheEntry> _yearCache = YearStartCacheEntry.createCache();

  static bool isLeapYear(int year) => arithmeticMod((year * 7) + 1, 19) < 7;

  static YearMonthDay getYearMonthDay(int year, int dayOfYear)
  {
    // Work out everything about the year in one go.
    int cache = _getOrPopulateCache(year);
    int heshvanLength = (cache & _isHeshvanLongCacheBit) != 0 ? 30 : 29;
    int kislevLength = (cache & _isKislevShortCacheBit) != 0 ? 29 : 30;
    bool isLeap = isLeapYear(year);
    int firstAdarLength = isLeap ? 30 : 29;

    if (dayOfYear < 31)
    {
      // Tishri
      return YearMonthDay(year, 7, dayOfYear);
    }
    if (dayOfYear < 31 + heshvanLength)
    {
      // Heshvan
      return YearMonthDay(year, 8, dayOfYear - 30);
    }
    // Now 'day of year without Heshvan'...
    dayOfYear -= heshvanLength;
    if (dayOfYear < 31 + kislevLength)
    {
      // Kislev
      return YearMonthDay(year, 9, dayOfYear - 30);
    }
    // Now 'day of year without Heshvan or Kislev'...
    dayOfYear -= kislevLength;
    if (dayOfYear < 31 + 29)
    {
      // Tevet
      return YearMonthDay(year, 10, dayOfYear - 30);
    }
    if (dayOfYear < 31 + 29 + 30)
    {
      // Shevat
      return YearMonthDay(year, 11, dayOfYear - (30 + 29));
    }
    if (dayOfYear < 31 + 29 + 30 + firstAdarLength)
    {
      // Adar / Adar I
      return YearMonthDay(year, 12, dayOfYear - (30 + 29 + 30));
    }
    // Now 'day of year without first month of Adar'
    dayOfYear -= firstAdarLength;
    if (isLeap)
    {
      if (dayOfYear < 31 + 29 + 30 + 29)
      {
        return YearMonthDay(year, 13, dayOfYear - (30 + 29 + 30));
      }
      // Now 'day of year without any Adar'
      dayOfYear -= 29;
    }
    // We could definitely do a binary search from here, but it would only
    // a few comparisons at most, and simplicity trumps optimization.
    if (dayOfYear < 31 + 29 + 30 + 30)
    {
      // Nisan
      return YearMonthDay(year, 1, dayOfYear - (30 + 29 + 30));
    }
    if (dayOfYear < 31 + 29 + 30 + 30 + 29)
    {
      // Iyar
      return YearMonthDay(year, 2, dayOfYear - (30 + 29 + 30 + 30));
    }
    if (dayOfYear < 31 + 29 + 30 + 30 + 29 + 30)
    {
      // Sivan
      return YearMonthDay(year, 3, dayOfYear - (30 + 29 + 30 + 30 + 29));
    }
    if (dayOfYear < 31 + 29 + 30 + 30 + 29 + 30 + 29)
    {
      // Tamuz
      return YearMonthDay(year, 4, dayOfYear - (30 + 29 + 30 + 30 + 29 + 30));
    }
    if (dayOfYear < 31 + 29 + 30 + 30 + 29 + 30 + 29 + 30)
    {
      // Av
      return YearMonthDay(year, 5, dayOfYear - (30 + 29 + 30 + 30 + 29 + 30 + 29));
    }
    // Elul
    return YearMonthDay(year, 6, dayOfYear - (30 + 29 + 30 + 30 + 29 + 30 + 29 + 30));
  }

  static int getDaysFromStartOfYearToStartOfMonth(int year, int month)
  {
    // Work out everything about the year in one go. (Admittedly we don't always need it all... but for
    // anything other than Tishri and Heshvan, we at least need the length of Heshvan...)
    int cache = _getOrPopulateCache(year);
    int heshvanLength = (cache & _isHeshvanLongCacheBit) != 0 ? 30 : 29;
    int kislevLength = (cache & _isKislevShortCacheBit) != 0 ? 29 : 30;
    bool isLeap = isLeapYear(year);
    int firstAdarLength = isLeap ? 30 : 29;
    int secondAdarLength = isLeap ? 29 : 0;
    switch (month) {
      // Note: this could be made slightly faster (at least in terms of the apparent IL) by
      // putting all the additions of compile-time constants in one place. Indeed, we could
      // go further by only using isLeap at most once per case. However, this code is clearer
      // and there's no evidence that this is a bottleneck.
      case 1: // Nisan
        return 30 + heshvanLength + kislevLength + (29 + 30) + firstAdarLength + secondAdarLength;
      case 2: // Iyar
        return 30 + heshvanLength + kislevLength + (29 + 30) + firstAdarLength + secondAdarLength + 30;
      case 3: // Sivan
        return 30 + heshvanLength + kislevLength + (29 + 30) + firstAdarLength + secondAdarLength + (30 + 29);
      case 4: // Tamuz
        return 30 + heshvanLength + kislevLength + (29 + 30) + firstAdarLength + secondAdarLength + (30 + 29 + 30);
      case 5: // Av
        return 30 + heshvanLength + kislevLength + (29 + 30) + firstAdarLength + secondAdarLength + (30 + 29 + 30 + 29);
      case 6: // Elul
        return 30 + heshvanLength + kislevLength + (29 + 30) + firstAdarLength + secondAdarLength + (30 + 29 + 30 + 29 + 30);
      case 7: // Tishri
        return 0;
      case 8: // Heshvan
        return 30;
      case 9: // Kislev
        return 30 + heshvanLength;
      case 10: // Tevet
        return 30 + heshvanLength + kislevLength;
      case 11: // Shevat
        return 30 + heshvanLength + kislevLength + 29;
      case 12: // Adar / Adar I
        return 30 + heshvanLength + kislevLength + 29 + 30;
      case 13: // Adar II
        return 30 + heshvanLength + kislevLength + 29 + 30 + firstAdarLength;
      default:
      // Just shorthand for using the right exception across netstandard and desktop
        Preconditions.checkArgumentRange('month', month, 1, 13);
        throw StateError('CheckArgumentRange should have thrown...');
    }
  }

  static int daysInMonth(int year, int month)
  {
    switch (month)
    {
      case 2:
      case 4:
      case 6:
      case 10:
      case 13:
        return 29;
      case 8:
      // Is Heshvan long in this year?
        return _isHeshvanLong(year) ? 30 : 29;
      case 9:
      // Is Kislev short in this year?
        return _isKislevShort(year) ?  29 : 30;
      case 12:
        return isLeapYear(year) ? 30 : 29;
      // 1, 3, 5, 7, 11, 13
      default:
        return 30;
    }
  }

  static bool _isHeshvanLong(int year)
  {
    int cache = _getOrPopulateCache(year);
    return (cache & _isHeshvanLongCacheBit) != 0;
  }

  static bool _isKislevShort(int year)
  {
    int cache = _getOrPopulateCache(year);
    return (cache & _isKislevShortCacheBit) != 0;
  }

  /// <summary>
  /// Elapsed days since the Hebrew epoch at the start of the given Hebrew year.
  /// This is *inclusive* of the first day of the year, so ElapsedDays(1) returns 1.
  /// </summary>
  static int elapsedDays(int year)
  {
    int cache = _getOrPopulateCache(year);
    return cache >> _elapsedDaysCacheShift;
  }

  static int _elapsedDaysNoCache(int year)
  {
    int monthsElapsed = (235 * ((year - 1) ~/ 19)) // Months in complete cycles so far
        + (12 * arithmeticMod((year - 1), 19)) // Regular months in this cycle
        + ((arithmeticMod((year - 1), 19) * 7 + 1) ~/ 19); // Leap months this cycle
    // Second option in the paper, which keeps values smaller
    int partsElapsed = 204 + (793 * arithmeticMod(monthsElapsed, 1080));
    int hoursElapsed = 5 + (12 * monthsElapsed) + (793 * (monthsElapsed ~/ 1080)) + (partsElapsed ~/ 1080);
    int day = 1 + (29 * monthsElapsed) + (hoursElapsed ~/ 24);
    int parts = (arithmeticMod(hoursElapsed, 24) * 1080) + arithmeticMod(partsElapsed, 1080);
    bool postponeRoshHaShanah = (parts >= 19440) ||
        (arithmeticMod(day, 7) == 2 && parts >= 9924 && !isLeapYear(year)) ||
        (arithmeticMod(day, 7) == 1 && parts >= 16789 && isLeapYear(year - 1));
    int alternativeDay = postponeRoshHaShanah ? 1 + day : day;
    int alternativeDayMod7 = arithmeticMod(alternativeDay, 7);
    return (alternativeDayMod7 == 0 || alternativeDayMod7 == 3 || alternativeDayMod7 == 5)
        ? alternativeDay + 1 : alternativeDay;
  }

  /// <summary>
  /// Returns the cached 'elapsed day at start of year / IsHeshvanLong / IsKislevShort' combination,
  /// populating the cache if necessary. Bits 2-24 are the 'elapsed days start of year'; bit 0 is
  /// 'is Heshvan long'; bit 1 is "is Kislev short". If the year is out of the range for the cache,
  /// the value is populated but not cached.
  /// </summary>
  /// <param name='year'></param>
  static int _getOrPopulateCache(int year)
  {
    if (year < minYear || year > maxYear)
    {
      return _computeCacheEntry(year);
    }
    int cacheIndex = YearStartCacheEntry.getCacheIndex(year);
    YearStartCacheEntry cacheEntry = _yearCache[cacheIndex];
    if (!cacheEntry.isValidForYear(year))
    {
      int days = _computeCacheEntry(year);
      cacheEntry = YearStartCacheEntry(year, days);
      _yearCache[cacheIndex] = cacheEntry;
    }
    return cacheEntry.startOfYearDays;
  }

  /// <summary>
  /// Computes the cache entry value for the given year, but without populating the cache.
  /// </summary>
  static int _computeCacheEntry(int year)
  {
    int days = _elapsedDaysNoCache(year);
    // We want the elapsed days for the next year as well. Check the cache if possible.
    int nextYear = year + 1;
    int nextYearDays;
    if (nextYear <= maxYear)
    {
      int cacheIndex = YearStartCacheEntry.getCacheIndex(nextYear);
      YearStartCacheEntry cacheEntry = _yearCache[cacheIndex];
      nextYearDays = cacheEntry.isValidForYear(nextYear)
          ? cacheEntry.startOfYearDays >> _elapsedDaysCacheShift
          : _elapsedDaysNoCache(nextYear);
    }
    else
    {
      nextYearDays = _elapsedDaysNoCache(year + 1);
    }
    int daysInYear = nextYearDays - days;
    bool isHeshvanLong = daysInYear % 10 == 5;
    bool isKislevShort = daysInYear % 10 == 3;
    return (days << _elapsedDaysCacheShift)
    | (isHeshvanLong ? _isHeshvanLongCacheBit : 0)
    | (isKislevShort ? _isKislevShortCacheBit : 0);
  }

  static int daysInYear(int year) => elapsedDays(year + 1) - elapsedDays(year);
}
