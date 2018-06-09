// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_utilities.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_timezones.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_patterns.dart';
import 'package:time_machine/time_machine_globalization.dart';

/// A [IIFormatProvider] for Time Machine types, usually initialised from a [System.Globalization.CultureInfo].
/// This provides a single place defining how NodaTime values are formatted and displayed, depending on the culture.
///
/// Currently this is "shallow-immutable" - although none of these properties can be changed, the
/// CultureInfo itself may be mutable. If the CultureInfo is mutated after initialization, results are not
/// guaranteed: some aspects of the CultureInfo may be extracted at initialization time, others may be
/// extracted on first demand but cached, and others may be extracted on-demand each time.
///
/// <threadsafety>Instances which use read-only CultureInfo instances are immutable,
/// and may be used freely between threads. Instances with mutable cultures should not be shared between threads
/// without external synchronization.
/// See the thread safety section of the user guide for more information.</threadsafety>
@internal  /*sealed*/ class NodaFormatInfo {
  // Names that we can use to check for broken Mono behaviour.
  // The cloning is *also* to work around a Mono bug, where even read-only cultures can change...
  // See http://bugzilla.xamarin.com/show_bug.cgi?id=3279
  @private static final List<String> ShortInvariantMonthNames = CultureInfo.invariantCulture.dateTimeFormat.abbreviatedMonthNames.toList(growable: false);
  @private static final List<String> LongInvariantMonthNames = CultureInfo.invariantCulture.dateTimeFormat.monthNames.toList(growable: false);

  // #region Patterns
  // @private final object fieldLock = new object();
  FixedFormatInfoPatternParser<Span> _spanPatternParser;
  FixedFormatInfoPatternParser<Offset> _offsetPatternParser;
  FixedFormatInfoPatternParser<Instant> _instantPatternParser;
  FixedFormatInfoPatternParser<LocalTime> _localTimePatternParser;
  FixedFormatInfoPatternParser<LocalDate> _localDatePatternParser;
  FixedFormatInfoPatternParser<LocalDateTime> _localDateTimePatternParser;
  FixedFormatInfoPatternParser<OffsetDateTime> _offsetDateTimePatternParser;
  FixedFormatInfoPatternParser<OffsetDate> _offsetDatePatternParser;
  FixedFormatInfoPatternParser<OffsetTime> _offsetTimePatternParser;
  FixedFormatInfoPatternParser<ZonedDateTime> _zonedDateTimePatternParser;
  FixedFormatInfoPatternParser<AnnualDate> _annualDatePatternParser;

// #endregion

  /// A NodaFormatInfo wrapping the invariant culture.
  // Note: this must occur below the pattern parsers, to make type initialization work...
  static final NodaFormatInfo InvariantInfo = new NodaFormatInfo(CultureInfo.invariantCulture);

  // Justification for max size: CultureInfo.GetCultures(CultureTypes.AllCultures) returns 378 cultures
  // on Windows 8 in mid-2013. In late 2016 on Windows 10 it's 832, but it's unlikely that they'll all be
  // used by any particular application.
  // 500 should be ample for almost all cases, without being enormous.
  @private static final Cache<CultureInfo, NodaFormatInfo> _cache = new Cache<CultureInfo, NodaFormatInfo>
    (500, (culture) => new NodaFormatInfo(culture) /*, new ReferenceEqualityComparer<CultureInfo>()*/);

  @private List<String> longMonthNames;
  @private List<String> longMonthGenitiveNames;
  @private List<String> longDayNames;
  @private List<String> shortMonthNames;
  @private List<String> shortMonthGenitiveNames;
  @private List<String> shortDayNames;

  @private final Map<Era, EraDescription> eraDescriptions;

  /// Initializes a new instance of the [NodaFormatInfo] class based solely
  /// on a [System.Globalization.CultureInfo].
  ///
  /// [cultureInfo]: The culture info to use.
  @visibleForTesting
  @internal
  NodaFormatInfo(CultureInfo cultureInfo)
      : this.withDateTimeFormat(cultureInfo, cultureInfo?.dateTimeFormat);

  /// Initializes a new instance of the [NodaFormatInfo] class based on
  /// potentially disparate [System.Globalization.CultureInfo] and
  /// [DateTimeFormatInfo] instances.
  ///
  /// [cultureInfo]: The culture info to use for text comparisons and resource lookups.
  /// [dateTimeFormat]: The date/time format to use for format strings etc.
  @visibleForTesting
  @internal
  NodaFormatInfo.withDateTimeFormat(this.cultureInfo, this.DateTimeFormat)
      : eraDescriptions = new Map<Era, EraDescription>() {
    Preconditions.checkNotNull(cultureInfo, 'cultureInfo');
    Preconditions.checkNotNull(DateTimeFormat, 'dateTimeFormat');
  //  #if NETSTANDARD1_3
  //  // Horrible, but it does the job...
  //  dateSeparator = DateTime.MinValue.ToString("%/", cultureInfo);
  //  timeSeparator = DateTime.MinValue.ToString("%:", cultureInfo);
  //  #endif
  }

  @private void EnsureMonthsInitialized() {
    if (longMonthNames != null) {
      return;
    }
    // Turn month names into 1-based read-only lists
    longMonthNames = ConvertMonthArray(DateTimeFormat.monthNames);
    shortMonthNames = ConvertMonthArray(DateTimeFormat.abbreviatedMonthNames);
    longMonthGenitiveNames = ConvertGenitiveMonthArray(longMonthNames, DateTimeFormat.monthGenitiveNames, LongInvariantMonthNames);
    shortMonthGenitiveNames = ConvertGenitiveMonthArray(shortMonthNames, DateTimeFormat.abbreviatedMonthGenitiveNames, ShortInvariantMonthNames);
  }

  /// The BCL returns arrays of month names starting at 0; we want a read-only list starting at 1 (with 0 as null).
  @private static List<String> ConvertMonthArray(List<String> monthNames) {
    List<String> list = new List<String>.from(monthNames);
    list.insert(0, null);
    return new List<String>.unmodifiable(list);
  }

  @private void EnsureDaysInitialized() {
    // lock (fieldLock)
    {
      if (longDayNames != null) {
        return;
      }
      longDayNames = ConvertDayArray(DateTimeFormat.dayNames);
      shortDayNames = ConvertDayArray(DateTimeFormat.abbreviatedDayNames);
    }
  }

  /// The BCL returns arrays of week names starting at 0 as Sunday; we want a read-only list starting at 1 (with 0 as null)
  /// and with 7 as Sunday.
  @private static List<String> ConvertDayArray(List<String> dayNames) {
    List<String> list = new List<String>.from(dayNames);
    list.add(dayNames[0]);
    list[0] = null;
    return new List<String>.unmodifiable(list);
  }

  /// Checks whether any of the genitive names differ from the non-genitive names, and returns
  /// either a reference to the non-genitive names or a converted list as per ConvertMonthArray.
  ///
  /// Mono uses the invariant month names for the genitive month names by default, so we'll assume that
  /// if we see an invariant name, that *isn't* deliberately a genitive month name. A non-invariant culture
  /// which decided to have genitive month names exactly matching the invariant ones would be distinctly odd.
  /// See http://bugzilla.xamarin.com/show_bug.cgi?id=3278 for more details and progress.
  ///
  /// Mono 3.0.6 has an exciting and different bug, where all the abbreviated genitive month names are just numbers ("1" etc).
  /// So again, if we detect that, we'll go back to the non-genitive version.
  /// See http://bugzilla.xamarin.com/show_bug.cgi?id=11361 for more details and progress.
  @private List<String> ConvertGenitiveMonthArray(List<String> nonGenitiveNames, List<String> bclNames, List<String> invariantNames) {
    var number = int.parse(bclNames[0], onError: (_) => null); //, NumberStyles.Integer, CultureInfo.InvariantCulture, out var _)

    if (number != null) {
      return nonGenitiveNames;
    }
    for (int i = 0; i < bclNames.length; i++) {
      if (bclNames[i] != nonGenitiveNames[i + 1] && bclNames[i] != invariantNames[i]) {
        return ConvertMonthArray(bclNames);
      }
    }
    return nonGenitiveNames;
  }

  /// Gets the culture info associated with this format provider. This is used
  /// for resource lookups and text comparisons.
  final CultureInfo cultureInfo;

  /// Gets the text comparison information associated with this format provider.
  CompareInfo get compareInfo => cultureInfo.compareInfo;

  @internal FixedFormatInfoPatternParser<Span> get spanPatternParser =>
      _spanPatternParser = EnsureFixedFormatInitialized(_spanPatternParser, () => new SpanPatternParser());

  @internal FixedFormatInfoPatternParser<Offset> get offsetPatternParser =>
      _offsetPatternParser = EnsureFixedFormatInitialized(_offsetPatternParser, () => new OffsetPatternParser());

  @internal FixedFormatInfoPatternParser<Instant> get instantPatternParser =>
      _instantPatternParser = EnsureFixedFormatInitialized(_instantPatternParser, () => new InstantPatternParser());

  @internal FixedFormatInfoPatternParser<LocalTime> get localTimePatternParser =>
      _localTimePatternParser = EnsureFixedFormatInitialized(_localTimePatternParser, () => new LocalTimePatternParser(LocalTime.Midnight));

  @internal FixedFormatInfoPatternParser<LocalDate> get localDatePatternParser =>
      _localDatePatternParser = EnsureFixedFormatInitialized(_localDatePatternParser, () => new LocalDatePatternParser(LocalDatePattern.DefaultTemplateValue));

  @internal FixedFormatInfoPatternParser<LocalDateTime> get localDateTimePatternParser =>
      _localDateTimePatternParser =
          EnsureFixedFormatInitialized(_localDateTimePatternParser, () => new LocalDateTimePatternParser(LocalDateTimePattern.DefaultTemplateValue));

  @internal FixedFormatInfoPatternParser<OffsetDateTime> get offsetDateTimePatternParser =>
      _offsetDateTimePatternParser =
          EnsureFixedFormatInitialized(_offsetDateTimePatternParser, () => new OffsetDateTimePatternParser(OffsetDateTimePattern.DefaultTemplateValue));

  @internal FixedFormatInfoPatternParser<OffsetDate> get offsetDatePatternParser =>
      _offsetDatePatternParser =
          EnsureFixedFormatInitialized(_offsetDatePatternParser, () => new OffsetDatePatternParser(OffsetDatePattern.DefaultTemplateValue));

  @internal FixedFormatInfoPatternParser<OffsetTime> get offsetTimePatternParser =>
      _offsetTimePatternParser =
          EnsureFixedFormatInitialized(_offsetTimePatternParser, () => new OffsetTimePatternParser(OffsetTimePattern.DefaultTemplateValue));

  @internal FixedFormatInfoPatternParser<ZonedDateTime> get zonedDateTimePatternParser =>
      _zonedDateTimePatternParser = EnsureFixedFormatInitialized(
          _zonedDateTimePatternParser, () => new ZonedDateTimePatternParser(ZonedDateTimePattern.DefaultTemplateValue, Resolvers.StrictResolver, null));

  @internal FixedFormatInfoPatternParser<AnnualDate> get annualDatePatternParser =>
      _annualDatePatternParser =
          EnsureFixedFormatInitialized(_annualDatePatternParser, () => new AnnualDatePatternParser(AnnualDatePattern.DefaultTemplateValue));


  @private FixedFormatInfoPatternParser<T> EnsureFixedFormatInitialized<T>(/*ref*/ FixedFormatInfoPatternParser<T> field,
      IPatternParser<T> Function() patternParserFactory) {
    // lock (fieldLock)
    if (field == null) {
      field = new FixedFormatInfoPatternParser<T>(patternParserFactory(), this);
    }
    return field;
  }

  /// Returns a read-only list of the names of the months for the default calendar for this culture.
  /// See the usage guide for caveats around the use of these names for other calendars.
  /// Element 0 of the list is null, to allow a more natural mapping from (say) 1 to the string "January".
  List<String> get LongMonthNames {
    EnsureMonthsInitialized();
    return longMonthNames;
  }

  /// Returns a read-only list of the abbreviated names of the months for the default calendar for this culture.
  /// See the usage guide for caveats around the use of these names for other calendars.
  /// Element 0 of the list is null, to allow a more natural mapping from (say) 1 to the string "Jan".
  List<String> get ShortMonthNames {
    EnsureMonthsInitialized();
    return shortMonthNames;
  }

  /// Returns a read-only list of the names of the months for the default calendar for this culture.
  /// See the usage guide for caveats around the use of these names for other calendars.
  /// Element 0 of the list is null, to allow a more natural mapping from (say) 1 to the string "January".
  /// The genitive form is used for month text where the day of month also appears in the pattern.
  /// If the culture does not use genitive month names, this property will return the same reference as
  /// [LongMonthNames].
  List<String> get LongMonthGenitiveNames {
    EnsureMonthsInitialized();
    return longMonthGenitiveNames;
  }

  /// Returns a read-only list of the abbreviated names of the months for the default calendar for this culture.
  /// See the usage guide for caveats around the use of these names for other calendars.
  /// Element 0 of the list is null, to allow a more natural mapping from (say) 1 to the string "Jan".
  /// The genitive form is used for month text where the day also appears in the pattern.
  /// If the culture does not use genitive month names, this property will return the same reference as
  /// [ShortMonthNames].
  List<String> get ShortMonthGenitiveNames {
    EnsureMonthsInitialized();
    return shortMonthGenitiveNames;
  }

  /// Returns a read-only list of the names of the days of the week for the default calendar for this culture.
  /// See the usage guide for caveats around the use of these names for other calendars.
  /// Element 0 of the list is null, and the other elements correspond with the index values returned from
  /// [LocalDateTime.DayOfWeek] and similar properties.
  List<String> get LongDayNames {
    EnsureDaysInitialized();
    return longDayNames;
  }

  /// Returns a read-only list of the abbreviated names of the days of the week for the default calendar for this culture.
  /// See the usage guide for caveats around the use of these names for other calendars.
  /// Element 0 of the list is null, and the other elements correspond with the index values returned from
  /// [LocalDateTime.DayOfWeek] and similar properties.
  List<String> get ShortDayNames {
    EnsureDaysInitialized();
    return shortDayNames;
  }

  /// Gets the BCL date time format associated with this formatting information.
  ///
  /// This is usually the [DateTimeFormatInfo] from [CultureInfo],
  /// but in some cases they're different: if a DateTimeFormatInfo is provided with no
  /// CultureInfo, that's used for format strings but the invariant culture is used for
  /// text comparisons and culture lookups for non-BCL formats (such as Offset) and for error messages.
  final DateTimeFormatInfo DateTimeFormat;

  /// Gets the time separator.
  String get TimeSeparator => DateTimeFormat.timeSeparator;

  /// Gets the date separator.
  String get DateSeparator => DateTimeFormat.dateSeparator;

  /// Gets the AM designator.
  String get AMDesignator => DateTimeFormat.amDesignator;

  /// Gets the PM designator.
  String get PMDesignator => DateTimeFormat.pmDesignator;

  /// Returns the names for the given era in this culture.
  ///
  /// [era]: The era to find the names of.
  /// A read-only list of names for the given era, or an empty list if
  /// the era is not known in this culture.
  List<String> GetEraNames(Era era) {
    Preconditions.checkNotNull(era, 'era');
    return GetEraDescription(era).AllNames;
  }

  /// Returns the primary name for the given era in this culture.
  ///
  /// [era]: The era to find the primary name of.
  /// Returns: The primary name for the given era, or an empty string if the era name is not known.
  String GetEraPrimaryName(Era era) {
    Preconditions.checkNotNull(era, 'era');
    return GetEraDescription(era).PrimaryName;
  }

  @private EraDescription GetEraDescription(Era era) {
    // lock (eraDescriptions)
    {
      EraDescription ret = eraDescriptions[era];
      if (ret == null) {
        ret = EraDescription.ForEra(era, cultureInfo);
        eraDescriptions[era] = ret;
      }
      return ret;
    }
  }

  /// Gets the [NodaFormatInfo] object for the current thread.
  static NodaFormatInfo get CurrentInfo => GetInstance(CultureInfo.currentCulture);

  /// Gets the [Offset] "l" pattern.
  String get OffsetPatternLong => PatternResources.GetString("OffsetPatternLong", cultureInfo);

  /// Gets the [Offset] "m" pattern.
  String get OffsetPatternMedium => PatternResources.GetString("OffsetPatternMedium", cultureInfo);

  /// Gets the [Offset] "s" pattern.
  String get OffsetPatternShort => PatternResources.GetString("OffsetPatternShort", cultureInfo);

  /// Gets the [Offset] "L" pattern.
  String get OffsetPatternLongNoPunctuation =>
      PatternResources.GetString("OffsetPatternLongNoPunctuation", cultureInfo);

  /// Gets the [Offset] "M" pattern.
  String get OffsetPatternMediumNoPunctuation =>
      PatternResources.GetString("OffsetPatternMediumNoPunctuation", cultureInfo);

  /// Gets the [Offset] "S" pattern.
  String get OffsetPatternShortNoPunctuation =>
      PatternResources.GetString("OffsetPatternShortNoPunctuation", cultureInfo);

  /// Clears the cache. Only used for test purposes.
  @internal static void ClearCache() => _cache.Clear();

  /// Gets the [NodaFormatInfo] for the given [CultureInfo].
  ///
  /// This method maintains a cache of results for read-only cultures.
  ///
  /// [cultureInfo]: The culture info.
  /// Returns: The [NodaFormatInfo]. Will never be null.
  @internal static NodaFormatInfo GetFormatInfo(CultureInfo cultureInfo) {
    Preconditions.checkNotNull(cultureInfo, 'cultureInfo');
    if (cultureInfo == CultureInfo.invariantCulture) {
      return InvariantInfo;
    }
    // Never cache (or consult the cache) for non-read-only cultures.
    if (!cultureInfo.isReadOnly) {
      return new NodaFormatInfo(cultureInfo);
    }
    return _cache.GetOrAdd(cultureInfo);
  }

  /// Gets the [NodaFormatInfo] for the given [IIFormatProvider]. If the
  /// format provider is null then the format object for the current thread is returned. If it's
  /// a CultureInfo, that's used for everything. If it's a DateTimeFormatInfo, that's used for
  /// format strings, day names etc but the invariant culture is used for text comparisons and
  /// resource lookups. Otherwise, [ArgumentException] is thrown.
  ///
  /// [provider]: The [IIFormatProvider].
  /// [ArgumentException]: The format provider cannot be used for Time Machine.
  /// Returns: The [NodaFormatInfo]. Will never be null.
  static NodaFormatInfo GetInstance(/*IFormatProvider*/ dynamic formatProvider) {
    if (formatProvider == null) {
      return GetFormatInfo(CurrentInfo.cultureInfo);
    } else if (formatProvider is CultureInfo) {
      return GetFormatInfo(formatProvider);
    } else if (formatProvider is DateTimeFormatInfo) {
      return new NodaFormatInfo.withDateTimeFormat(CultureInfo.invariantCulture, formatProvider);
    }

    throw new ArgumentError("Cannot use provider of type ${formatProvider
        .GetType()
        .FullName} in Noda Time");

    /*
    switch (provider)
    {
      case null:
        return GetFormatInfo(CurrentInfo.cultureInfo);
      case CultureInfo cultureInfo:
      return GetFormatInfo(cultureInfo);
      // Note: no caching for this case. It's a corner case anyway... we could add a cache later
      // if users notice a problem.
      case DateTimeFormatInfo dateTimeFormatInfo:
      return new NodaFormatInfo.withDateTimeFormat(CultureInfo.InvariantCulture, dateTimeFormatInfo);
      default:
        throw new ArgumentError("Cannot use provider of type ${provider.GetType().FullName} in Noda Time");
    }*/
  }

  /// Returns a [String] that represents this instance.
  @override String toString() => "NodaFormatInfo[" + cultureInfo.name + "]";
}

/// The description for an era: the primary name and all possible names.
@private class EraDescription {
  @internal final String PrimaryName;
  @internal final /*ReadOnlyCollection*/ List<String> AllNames;

  @private EraDescription(this.PrimaryName, this.AllNames);

  @internal static EraDescription ForEra(Era era, CultureInfo cultureInfo)
  {
    String pipeDelimited = PatternResources.GetString(era.resourceIdentifier, cultureInfo);
    String primaryName;
    List<String> allNames;
    if (pipeDelimited == null)
    {
      allNames = new List<String>(0); // string[0];
      primaryName = "";
    }
    else
    {
      String eraNameFromCulture = GetEraNameFromBcl(era, cultureInfo);
      if (eraNameFromCulture != null && !pipeDelimited.startsWith(eraNameFromCulture + "|"))
      {
        pipeDelimited = eraNameFromCulture + "|" + pipeDelimited;
      }
      allNames = pipeDelimited.split('|');
      primaryName = allNames[0];
      // Order by length, descending to avoid early out (e.g. parsing BCE as BC and then having a spare E)
      allNames.sort((x, y) => y.length.compareTo(x.length));
    }
    return new EraDescription(primaryName, new List<String>.unmodifiable(allNames));
  }

  /// Returns the name of the era within a culture according to the BCL, if this is known and we're confident that
  /// it's correct. (The selection here seems small, but it covers most cases.) This isn't ideal, but it's better
  /// than nothing, and fixes an issue where non-English BCL cultures have "gg" in their patterns.
  @private static String GetEraNameFromBcl(Era era, CultureInfo culture) {
    var calendar = culture.dateTimeFormat.calendar;

    bool getEraFromCalendar =
        (era == Era.Common && calendar == BclCalendarType.gregorian) ||
        (era == Era.AnnoPersico && calendar == BclCalendarType.persian) ||
        (era == Era.AnnoHegirae && (calendar == BclCalendarType.hijri || calendar == BclCalendarType.umAlQura));

    return getEraFromCalendar ? culture.dateTimeFormat.getEraName(1) : null;
  }
}
