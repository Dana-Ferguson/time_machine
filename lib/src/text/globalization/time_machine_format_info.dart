// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/utility/time_machine_utilities.dart';
import 'package:time_machine/src/calendars/time_machine_calendars.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';
import 'package:time_machine/src/text/time_machine_text.dart';
import 'package:time_machine/src/text/patterns/time_machine_patterns.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';

// todo: look at the name for this, with-respect-to, Culture && DateTimeFormatInfo
/// A [IIFormatProvider] for Time Machine types, usually initialised from a [Culture].
/// This provides a single place defining how Time Machine values are formatted and displayed, depending on the culture.
///
/// Currently this is 'shallow-immutable' - although none of these properties can be changed, the
/// [Culture] itself may be mutable. If the [Culture] is mutated after initialization, results are not
/// guaranteed: some aspects of the [Culture] may be extracted at initialization time, others may be
/// extracted on first demand but cached, and others may be extracted on-demand each time.
@internal
class TimeMachineFormatInfo {
  // todo: remove for Dart
  // Names that we can use to check for broken Mono behaviour.
  // The cloning is *also* to work around a Mono bug, where even read-only cultures can change...
  // See http://bugzilla.xamarin.com/show_bug.cgi?id=3279
  static final List<String> _shortInvariantMonthNames = Culture
      .invariant.dateTimeFormat.abbreviatedMonthNames
      .toList(growable: false);
  static final List<String> _longInvariantMonthNames =
      Culture.invariant.dateTimeFormat.monthNames.toList(growable: false);

  // Patterns
  FixedFormatInfoPatternParser<Time>? _timePatternParser;
  FixedFormatInfoPatternParser<Offset>? _offsetPatternParser;
  FixedFormatInfoPatternParser<Instant>? _instantPatternParser;
  FixedFormatInfoPatternParser<LocalTime>? _localTimePatternParser;
  FixedFormatInfoPatternParser<LocalDate>? _localDatePatternParser;
  FixedFormatInfoPatternParser<LocalDateTime>? _localDateTimePatternParser;
  FixedFormatInfoPatternParser<OffsetDateTime>?
      _offsetDateTimePatternParser;
  FixedFormatInfoPatternParser<OffsetDate>? _offsetDatePatternParser;
  FixedFormatInfoPatternParser<OffsetTime>? _offsetTimePatternParser;
  FixedFormatInfoPatternParser<ZonedDateTime>? _zonedDateTimePatternParser;
  FixedFormatInfoPatternParser<AnnualDate>? _annualDatePatternParser;

  /// A TimeMachineFormatInfo wrapping the invariant culture.
  // Note: this must occur below the pattern parsers, to make type initialization work...
  static final TimeMachineFormatInfo invariantInfo =
      TimeMachineFormatInfo(Culture.invariant);

  // Justification for max size: [Cultures.getCultures(CultureTypes.AllCultures)] returns 378 cultures
  // on Windows 8 in mid-2013. In late 2016 on Windows 10 it's 832, but it's unlikely that they'll all be
  // used by any particular application.
  // 500 should be ample for almost all cases, without being enormous.
  static final Cache<Culture, TimeMachineFormatInfo> _cache =
      Cache<Culture, TimeMachineFormatInfo>(
          500,
          (culture) => TimeMachineFormatInfo(
              culture) /*, new ReferenceEqualityComparer<Culture>()*/);

  bool _monthsInitialized = false;
  bool _daysInitialized = false;
  late List<String> _longMonthNames;
  late List<String> _longMonthGenitiveNames;
  late List<String?> _longDayNames;
  late List<String> _shortMonthNames;
  late List<String> _shortMonthGenitiveNames;
  late List<String?> _shortDayNames;

  final Map<Era, _EraDescription> _eraDescriptions;

  /// Initializes a new instance of the [TimeMachineFormatInfo] class based solely
  /// on a [Culture].
  ///
  /// [culture]: The culture info to use.
  @visibleForTesting
  TimeMachineFormatInfo(Culture culture)
      : this.withDateTimeFormat(culture, culture.dateTimeFormat);

  /// Initializes a new instance of the [TimeMachineFormatInfo] class based on
  /// potentially disparate [Culture] and
  /// [DateTimeFormat] instances.
  ///
  /// [culture]: The culture info to use for text comparisons and resource lookups.
  /// [dateTimeFormat]: The date/time format to use for format strings etc.
  @visibleForTesting
  TimeMachineFormatInfo.withDateTimeFormat(this.culture, this.dateTimeFormat)
      : _eraDescriptions = <Era, _EraDescription>{} {
    Preconditions.checkNotNull(culture, 'culture');
    Preconditions.checkNotNull(dateTimeFormat, 'dateTimeFormat');
  }

  void _ensureMonthsInitialized() {
    if (_monthsInitialized) return;

    // Turn month names into 1-based read-only lists
    _longMonthNames = _convertMonthArray(dateTimeFormat.monthNames);
    _shortMonthNames = _convertMonthArray(dateTimeFormat.abbreviatedMonthNames);
    _longMonthGenitiveNames = _convertGenitiveMonthArray(_longMonthNames,
        dateTimeFormat.monthGenitiveNames, _longInvariantMonthNames);
    _shortMonthGenitiveNames = _convertGenitiveMonthArray(
        _shortMonthNames,
        dateTimeFormat.abbreviatedMonthGenitiveNames,
        _shortInvariantMonthNames);
    _monthsInitialized = true;
  }

  /// The BCL returns arrays of month names starting at 0; we want a read-only list starting at 1 (with 0 as null).
  static List<String> _convertMonthArray(List<String> monthNames) {
    List<String?> list = List<String?>.from(monthNames);
    list.insert(0, '');
    return List<String>.unmodifiable(list);
  }

  void _ensureDaysInitialized() {
    // lock (fieldLock)
    {
      if (_daysInitialized) return;
      _longDayNames = _convertDayArray(dateTimeFormat.dayNames);
      _shortDayNames = _convertDayArray(dateTimeFormat.abbreviatedDayNames);
      _daysInitialized = true;
    }
  }

  /// The BCL returns arrays of week names starting at 0 as Sunday; we want a read-only list starting at 1 (with 0 as null)
  /// and with 7 as Sunday.
  static List<String> _convertDayArray(List<String> dayNames) {
    List<String> list = List<String>.from(dayNames);
    list.add(dayNames[0]);
    list[0] = '';
    return List<String>.unmodifiable(list);
  }

  /// Checks whether any of the genitive names differ from the non-genitive names, and returns
  /// either a reference to the non-genitive names or a converted list as per ConvertMonthArray.
  ///
  /// Mono uses the invariant month names for the genitive month names by default, so we'll assume that
  /// if we see an invariant name, that *isn't* deliberately a genitive month name. A non-invariant culture
  /// which decided to have genitive month names exactly matching the invariant ones would be distinctly odd.
  /// See http://bugzilla.xamarin.com/show_bug.cgi?id=3278 for more details and progress.
  ///
  /// todo: verify and remove
  /// Mono 3.0.6 has an exciting and different bug, where all the abbreviated genitive month names are just numbers ('1' etc).
  /// So again, if we detect that, we'll go back to the non-genitive version.
  /// See http://bugzilla.xamarin.com/show_bug.cgi?id=11361 for more details and progress.
  List<String> _convertGenitiveMonthArray(List<String> nonGenitiveNames,
      List<String> bclNames, List<String> invariantNames) {
    var number = int.tryParse(bclNames[
        0]); //, NumberStyles.Integer, Culture.invariantCulture, out var _)

    if (number != null) {
      return nonGenitiveNames;
    }
    for (int i = 0; i < bclNames.length; i++) {
      if (bclNames[i] != nonGenitiveNames[i + 1] &&
          bclNames[i] != invariantNames[i]) {
        return _convertMonthArray(bclNames);
      }
    }
    return nonGenitiveNames;
  }

  /// Gets the culture info associated with this format provider. This is used
  /// for resource lookups and text comparisons.
  final Culture culture;

  /// Gets the text comparison information associated with this format provider.
  CompareInfo? get compareInfo => culture.compareInfo;

  FixedFormatInfoPatternParser<Time> get timePatternParser =>
      _timePatternParser = _ensureFixedFormatInitialized(
          _timePatternParser, () => TimePatternParser());

  FixedFormatInfoPatternParser<Offset> get offsetPatternParser =>
      _offsetPatternParser = _ensureFixedFormatInitialized(
          _offsetPatternParser, () => OffsetPatternParser());

  FixedFormatInfoPatternParser<Instant> get instantPatternParser =>
      _instantPatternParser = _ensureFixedFormatInitialized(
          _instantPatternParser, () => InstantPatternParser());

  FixedFormatInfoPatternParser<LocalTime> get localTimePatternParser =>
      _localTimePatternParser = _ensureFixedFormatInitialized(
          _localTimePatternParser,
          () => LocalTimePatternParser(LocalTime.midnight));

  FixedFormatInfoPatternParser<LocalDate> get localDatePatternParser =>
      _localDatePatternParser = _ensureFixedFormatInitialized(
          _localDatePatternParser,
          () => LocalDatePatternParser(LocalDatePatterns.defaultTemplateValue));

  FixedFormatInfoPatternParser<LocalDateTime> get localDateTimePatternParser =>
      _localDateTimePatternParser = _ensureFixedFormatInitialized(
          _localDateTimePatternParser,
          () => LocalDateTimePatternParser(
              LocalDateTimePatterns.defaultTemplateValue));

  FixedFormatInfoPatternParser<OffsetDateTime>
      get offsetDateTimePatternParser =>
          _offsetDateTimePatternParser = _ensureFixedFormatInitialized(
              _offsetDateTimePatternParser,
              () => OffsetDateTimePatternParser(
                  OffsetDateTimePatterns.defaultTemplateValue));

  FixedFormatInfoPatternParser<OffsetDate> get offsetDatePatternParser =>
      _offsetDatePatternParser = _ensureFixedFormatInitialized(
          _offsetDatePatternParser,
          () =>
              OffsetDatePatternParser(OffsetDatePatterns.defaultTemplateValue));

  FixedFormatInfoPatternParser<OffsetTime> get offsetTimePatternParser =>
      _offsetTimePatternParser = _ensureFixedFormatInitialized(
          _offsetTimePatternParser,
          () =>
              OffsetTimePatternParser(OffsetTimePatterns.defaultTemplateValue));

  FixedFormatInfoPatternParser<ZonedDateTime> get zonedDateTimePatternParser =>
      _zonedDateTimePatternParser = _ensureFixedFormatInitialized(
          _zonedDateTimePatternParser,
          () => ZonedDateTimePatternParser(
              ZonedDateTimePatterns.defaultTemplateValue,
              Resolvers.strictResolver,
              null));

  FixedFormatInfoPatternParser<AnnualDate> get annualDatePatternParser =>
      _annualDatePatternParser = _ensureFixedFormatInitialized(
          _annualDatePatternParser,
          () =>
              AnnualDatePatternParser(AnnualDatePatterns.defaultTemplateValue));

  // todo: I think I can simplify the usage of this
  FixedFormatInfoPatternParser<T> _ensureFixedFormatInitialized<T>(
      /*ref*/ FixedFormatInfoPatternParser<T>? field,
      IPatternParser<T> Function() patternParserFactory) {
    // lock (fieldLock)
    field ??= FixedFormatInfoPatternParser<T>(patternParserFactory(), this);
    return field;
  }

  // todo: this needs to be immutable
  /// Returns a read-only list of the names of the months for the default calendar for this culture.
  /// See the usage guide for caveats around the use of these names for other calendars.
  /// Element 0 of the list is null, to allow a more natural mapping from (say) 1 to the string 'January'.
  List<String> get longMonthNames {
    _ensureMonthsInitialized();
    return _longMonthNames;
  }

  /// Returns a read-only list of the abbreviated names of the months for the default calendar for this culture.
  /// See the usage guide for caveats around the use of these names for other calendars.
  /// Element 0 of the list is null, to allow a more natural mapping from (say) 1 to the string 'Jan'.
  List<String> get shortMonthNames {
    _ensureMonthsInitialized();
    return _shortMonthNames;
  }

  /// Returns a read-only list of the names of the months for the default calendar for this culture.
  /// See the usage guide for caveats around the use of these names for other calendars.
  /// Element 0 of the list is null, to allow a more natural mapping from (say) 1 to the string 'January'.
  /// The genitive form is used for month text where the day of month also appears in the pattern.
  /// If the culture does not use genitive month names, this property will return the same reference as
  /// [longMonthNames].
  List<String> get longMonthGenitiveNames {
    _ensureMonthsInitialized();
    return _longMonthGenitiveNames;
  }

  /// Returns a read-only list of the abbreviated names of the months for the default calendar for this culture.
  /// See the usage guide for caveats around the use of these names for other calendars.
  /// Element 0 of the list is null, to allow a more natural mapping from (say) 1 to the string 'Jan'.
  /// The genitive form is used for month text where the day also appears in the pattern.
  /// If the culture does not use genitive month names, this property will return the same reference as
  /// [shortMonthNames].
  List<String> get shortMonthGenitiveNames {
    _ensureMonthsInitialized();
    return _shortMonthGenitiveNames;
  }

  /// Returns a read-only list of the names of the days of the week for the default calendar for this culture.
  /// See the usage guide for caveats around the use of these names for other calendars.
  /// Element 0 of the list is null, and the other elements correspond with the index values returned from
  /// [LocalDateTime.dayOfWeek] and similar properties.
  List<String?> get longDayNames {
    _ensureDaysInitialized();
    return _longDayNames;
  }

  /// Returns a read-only list of the abbreviated names of the days of the week for the default calendar for this culture.
  /// See the usage guide for caveats around the use of these names for other calendars.
  /// Element 0 of the list is null, and the other elements correspond with the index values returned from
  /// [LocalDateTime.dayOfWeek] and similar properties.
  List<String?> get shortDayNames {
    _ensureDaysInitialized();
    return _shortDayNames;
  }

  /// Gets the date time format associated with this formatting information.
  ///
  /// This is usually the [DateTimeFormat] from [Culture],
  /// but in some cases they're different: if a [DateTimeFormat] is provided with no
  /// [Culture], that's used for format strings but the invariant culture is used for
  /// text comparisons and culture lookups for formats (such as [Offset]) and for error messages.
  final DateTimeFormat dateTimeFormat;

  /// Gets the time separator.
  String get timeSeparator => dateTimeFormat.timeSeparator;

  /// Gets the date separator.
  String get dateSeparator => dateTimeFormat.dateSeparator;

  /// Gets the AM designator.
  String get amDesignator => dateTimeFormat.amDesignator;

  /// Gets the PM designator.
  String get pmDesignator => dateTimeFormat.pmDesignator;

  /// Returns the names for the given era in this culture.
  ///
  /// [era]: The era to find the names of.
  /// A read-only list of names for the given era, or an empty list if
  /// the era is not known in this culture.
  List<String> getEraNames(Era era) {
    Preconditions.checkNotNull(era, 'era');
    return _getEraDescription(era).allNames;
  }

  /// Returns the primary name for the given era in this culture.
  ///
  /// [era]: The era to find the primary name of.
  /// Returns: The primary name for the given era, or an empty string if the era name is not known.
  String getEraPrimaryName(Era era) {
    Preconditions.checkNotNull(era, 'era');
    return _getEraDescription(era).primaryName;
  }

  _EraDescription _getEraDescription(Era era) {
    // lock (eraDescriptions)
    {
      _EraDescription? ret = _eraDescriptions[era];
      if (ret == null) {
        ret = _EraDescription.forEra(era, culture);
        _eraDescriptions[era] = ret;
      }
      return ret;
    }
  }

  /// Gets the [TimeMachineFormatInfo] object for the current thread.
  static TimeMachineFormatInfo get currentInfo => getInstance(Culture.current);

  /// Gets the [Offset] 'l' pattern.
  String get offsetPatternLong =>
      PatternResources.getString('OffsetPatternLong', culture);

  /// Gets the [Offset] 'm' pattern.
  String get offsetPatternMedium =>
      PatternResources.getString('OffsetPatternMedium', culture);

  /// Gets the [Offset] 's' pattern.
  String get offsetPatternShort =>
      PatternResources.getString('OffsetPatternShort', culture);

  /// Gets the [Offset] 'L' pattern.
  String get offsetPatternLongNoPunctuation =>
      PatternResources.getString('OffsetPatternLongNoPunctuation', culture);

  /// Gets the [Offset] 'M' pattern.
  String get offsetPatternMediumNoPunctuation =>
      PatternResources.getString('OffsetPatternMediumNoPunctuation', culture);

  /// Gets the [Offset] 'S' pattern.
  String get offsetPatternShortNoPunctuation =>
      PatternResources.getString('OffsetPatternShortNoPunctuation', culture);

  /// Clears the cache. Only used for test purposes.
  static void clearCache() => _cache.clear();

  /// Gets the [TimeMachineFormatInfo] for the given [Culture].
  ///
  /// This method maintains a cache of results for read-only cultures.
  ///
  /// [culture]: The culture info.
  /// Returns: The [TimeMachineFormatInfo]. Will never be null.
  static TimeMachineFormatInfo getFormatInfo(Culture culture) {
    Preconditions.checkNotNull(culture, 'culture');
    if (culture == Culture.invariant) {
      return invariantInfo;
    }
    // Never cache (or consult the cache) for non-read-only cultures.
    if (!culture.isReadOnly) {
      return TimeMachineFormatInfo(culture);
    }
    return _cache.getOrAdd(culture);
  }

  // todo: remove the [DateTimeFormat] pathway, we're going Culture first.
  /// Gets the [TimeMachineFormatInfo] for the given [IIFormatProvider]. If the
  /// format provider is null then the format object for the current thread is returned. If it's
  /// a Culture, that's used for everything. If it's a DateTimeFormat, that's used for
  /// format strings, day names etc but the invariant culture is used for text comparisons and
  /// resource lookups. Otherwise, [ArgumentException] is thrown.
  ///
  /// [provider]: The [IIFormatProvider].
  /// [ArgumentException]: The format provider cannot be used for Time Machine.
  /// Returns: The [TimeMachineFormatInfo]. Will never be null.
  static TimeMachineFormatInfo getInstance(Culture? culture) {
    if (culture == null) {
      return getFormatInfo(currentInfo.culture);
    }
    return getFormatInfo(culture);

    //else if (culture is Culture) {
    //  return getFormatInfo(culture);
    //} else if (culture is DateTimeFormat) {
    //  return new TimeMachineFormatInfo.withDateTimeFormat(Culture.invariant, culture);
    //}
    // throw new ArgumentError('Cannot use provider of type ${culture.runtimeType} in Time Machine');
  }

  /// Returns a [String] that represents this instance.
  @override
  String toString() => 'TimeMachineInfo[${culture.name}]';
}

/// The description for an era: the primary name and all possible names.
class _EraDescription {
  final String primaryName;
  final /*ReadOnlyCollection*/ List<String> allNames;

  _EraDescription._(this.primaryName, this.allNames);

  factory _EraDescription.forEra(Era era, Culture culture) {
    String? pipeDelimited =
        PatternResources.getString(IEra.resourceIdentifier(era), culture);
    String primaryName;
    List<String> allNames;
    String? eraNameFromCulture = _getEraNameFromBcl(era, culture);
    if (eraNameFromCulture != null &&
        !pipeDelimited.startsWith(eraNameFromCulture + '|')) {
      pipeDelimited = eraNameFromCulture + '|' + pipeDelimited;
    }
    allNames = pipeDelimited.split('|');
    primaryName = allNames[0];
    // Order by length, descending to avoid early out (e.g. parsing BCE as BC and then having a spare E)
    allNames.sort((x, y) => y.length.compareTo(x.length));

    return _EraDescription._(primaryName, List<String>.unmodifiable(allNames));
  }

  /// Returns the name of the era within a culture according to the BCL, if this is known and we're confident that
  /// it's correct. (The selection here seems small, but it covers most cases.) This isn't ideal, but it's better
  /// than nothing, and fixes an issue where non-English BCL cultures have 'gg' in their patterns.
  static String? _getEraNameFromBcl(Era era, Culture culture) {
    var calendar = culture.dateTimeFormat.calendar;

    bool getEraFromCalendar =
        (era == Era.common && calendar == CalendarType.gregorian) ||
            (era == Era.annoPersico && calendar == CalendarType.persian) ||
            (era == Era.annoHegirae &&
                (calendar == CalendarType.hijri ||
                    calendar == CalendarType.umAlQura));

    return getEraFromCalendar ? culture.dateTimeFormat.getEraName(1) : null;
  }
}
