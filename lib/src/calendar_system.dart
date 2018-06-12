// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

import 'utility/preconditions.dart';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';


/// A calendar system maps the non-calendar-specific "local time line" to human concepts
/// such as years, months and days.
///
/// Many developers will never need to touch this class, other than to potentially ask a calendar
/// how many days are in a particular year/month and the like. Time Machine defaults to using the ISO-8601
/// calendar anywhere that a calendar system is required but hasn't been explicitly specified.
///
/// If you need to obtain a [CalendarSystem] instance, use one of the static properties or methods in this
/// class, such as the [iso] property or the [GetHebrewCalendar(HebrewMonthNumbering)] method.
///
/// Although this class is currently sealed (as of Time Machine 1.2), in the future this decision may
/// be reversed. In any case, there is no current intention for third-party developers to be able to implement
/// their own calendar systems (for various reasons). If you require a calendar system which is not
/// currently supported, please file a feature request and we'll see what we can do.
///
/// <threadsafety>
/// All calendar implementations are immutable and thread-safe. See the thread safety
/// section of the user guide for more information.
/// </threadsafety>
@immutable // sealed
class CalendarSystem {
  // IDs and names are separated out (usually with the ID either being the same as the name,
  // or the base ID being the same as a name and then other IDs being formed from it.) The
  // differentiation is only present for clarity.
  static const String _gregorianName = "Gregorian";
  static const String _gregorianId = _gregorianName;

  static const String _isoName = "ISO";
  static const String _isoId = _isoName;

  static const String _copticName = "Coptic";
  static const String _copticId = _copticName;

  static const String _wondrousName = "Wondrous";
  static const String _wondrousId = _wondrousName;

  static const String _julianName = "Julian";
  static const String _julianId = _julianName;

  static const String _islamicName = "Hijri";
  static const String _islamicIdBase = _islamicName;

//// Not part of IslamicCalendars as we want to be able to call it without triggering type initialization.
//@internal static String GetIslamicId(IslamicLeapYearPattern leapYearPattern, IslamicEpoch epoch)
//{
//  return '$IslamicIdBase $epoch-$leapYearPattern';
//}

  static const String _persianName = "Persian";
  static const String _persianIdBase = _persianName;
  static const String _persianSimpleId = _persianIdBase + " Simple";
  static const String _persianAstronomicalId = _persianIdBase + " Algorithmic";
  static const String _persianArithmeticId = _persianIdBase + " Arithmetic";

  static const String _hebrewName = "Hebrew";
  static const String _hebrewIdBase = _hebrewName;
  static const String _hebrewCivilId = _hebrewIdBase + " Civil";
  static const String _hebrewScripturalId = _hebrewIdBase + " Scriptural";

  static const String _umAlQuraName = "Um Al Qura";
  static const String _umAlQuraId = _umAlQuraName;

  // While we could implement some of these as auto-props, it probably adds more confusion than convenience.
  static final CalendarSystem _isoCalendarSystem = _generateIsoCalendarSystem();
  static final List<CalendarSystem> _calendarByOrdinal = new List<CalendarSystem>(CalendarOrdinal.size.value);

  // this was a static constructor
  static CalendarSystem _generateIsoCalendarSystem() {
    var gregorianCalculator = new GregorianYearMonthDayCalculator();
    var gregorianEraCalculator = new GJEraCalculator(gregorianCalculator);
    return new CalendarSystem(CalendarOrdinal.iso, _isoId, _isoName, gregorianCalculator, gregorianEraCalculator);
  }

  /// Fetches a calendar system by its unique identifier. This provides full round-tripping of a calendar
  /// system. It is not guaranteed that calling this method twice with the same identifier will return
  /// identical references, but the references objects will be equal.
  ///
  /// [id]: The ID of the calendar system. This is case-sensitive.
  /// Returns: The calendar system with the given [id].
  /// 
  /// [KeyNotFoundException]: No calendar system for the specified ID can be found.
  /// [NotSupportedException]: The calendar system with the specified ID is known, but not supported on this platform.
  static CalendarSystem forId(String id) {
    Preconditions.checkNotNull(id, 'id');
    CalendarSystem Function() factory = _idToFactoryMap[id];
    if (factory == null) {
      throw new ArgumentError("No calendar system for ID {id} exists");
    }
    return factory();
  }


  /// Fetches a calendar system by its ordinal value, constructing it if necessary.
  @internal static CalendarSystem forOrdinal(CalendarOrdinal ordinal) {
    Preconditions.debugCheckArgument(ordinal >= const CalendarOrdinal(0) && ordinal < CalendarOrdinal.size, 'ordinal',
        "Unknown ordinal value $ordinal");
    // Avoid an array lookup for the overwhelmingly common case.
    if (ordinal == CalendarOrdinal.iso) {
      return _isoCalendarSystem;
    }
    CalendarSystem calendar = _calendarByOrdinal[ordinal.value];
    if (calendar != null) {
      return calendar;
    }
    // Not found it in the array. This can happen if the calendar system was initialized in
    // a different thread, and the write to the array isn't visible in this thread yet.
    // A simple switch will do the right thing. This is separated out (directly below) to allow
    // it to be tested separately. (It may also help this method be inlined...) The return
    // statement below is unlikely to ever be hit by code coverage, as it's handling a very
    // unusual and hard-to-provoke situation.
    return forOrdinalUncached(ordinal);
  }

  // todo: how would caching work if this was inside the function body?
  static final Map<CalendarOrdinal, CalendarSystem> _forOrdinalUncached_referenceMap = {
    CalendarOrdinal.iso: iso,
    CalendarOrdinal.gregorian: gregorian,
    CalendarOrdinal.julian: julian,
  // CalendarOrdinal.Coptic: Coptic
  };

  @visibleForTesting
  @internal
  static CalendarSystem forOrdinalUncached(CalendarOrdinal ordinal) {
    var calendarSystem = CalendarSystem._forOrdinalUncached_referenceMap[ordinal];
    if (calendarSystem == null) throw new StateError("Bug: calendar ordinal $ordinal missing from switch in CalendarSystem.ForOrdinal.");
    return calendarSystem;

    /*
    switch (ordinal) {
      // This entry is really just for completeness. We'd never get called with this.
      case CalendarOrdinal.Iso:
        return Iso;
      case CalendarOrdinal.Gregorian:
        return Gregorian;
      case CalendarOrdinal.Julian:
        return Julian;
      case CalendarOrdinal.Coptic:
        return Coptic;
      case CalendarOrdinal.Wondrous:
      //return Wondrous;
      case CalendarOrdinal.HebrewCivil:
      //return HebrewCivil;
      case CalendarOrdinal.HebrewScriptural:
      //return HebrewScriptural;
      case CalendarOrdinal.PersianSimple:
      //return PersianSimple;
      case CalendarOrdinal.PersianArithmetic:
      //return PersianArithmetic;
      case CalendarOrdinal.PersianAstronomical:
      //return PersianAstronomical;
      case CalendarOrdinal.IslamicAstronomicalBase15:
      //return GetIslamicCalendar(IslamicLeapYearPattern.Base15, IslamicEpoch.Astronomical);
      case CalendarOrdinal.IslamicAstronomicalBase16:
      //return GetIslamicCalendar(IslamicLeapYearPattern.Base16, IslamicEpoch.Astronomical);
      case CalendarOrdinal.IslamicAstronomicalIndian:
      //return GetIslamicCalendar(IslamicLeapYearPattern.Indian, IslamicEpoch.Astronomical);
      case CalendarOrdinal.IslamicAstronomicalHabashAlHasib:
      //return GetIslamicCalendar(IslamicLeapYearPattern.HabashAlHasib, IslamicEpoch.Astronomical);
      case CalendarOrdinal.IslamicCivilBase15:
      //return GetIslamicCalendar(IslamicLeapYearPattern.Base15, IslamicEpoch.Civil);
      case CalendarOrdinal.IslamicCivilBase16:
      //return GetIslamicCalendar(IslamicLeapYearPattern.Base16, IslamicEpoch.Civil);
      case CalendarOrdinal.IslamicCivilIndian:
      //return GetIslamicCalendar(IslamicLeapYearPattern.Indian, IslamicEpoch.Civil);
      case CalendarOrdinal.IslamicCivilHabashAlHasib:
        //return GetIslamicCalendar(IslamicLeapYearPattern.HabashAlHasib, IslamicEpoch.Civil);
        throw new UnimplementedError('Selected $ordinal not implemented');
      case CalendarOrdinal.UmAlQura:
        return UmAlQura;
      default:
        throw new StateError("Bug: calendar ordinal $ordinal missing from switch in CalendarSystem.ForOrdinal.");
    }*/
  }


  /// Returns the IDs of all calendar systems available within Time Machine. The order of the keys is not guaranteed.
  static Iterable<String> get Ids => _idToFactoryMap.keys;

  // todo: make const
  static final Map<String, CalendarSystem Function()> _idToFactoryMap =
  {
    _isoId: () => iso,
    //  PersianSimpleId: () => PersianSimple,
    //  PersianArithmeticId: () => PersianArithmetic,
    //  PersianAstronomicalId: () => PersianAstronomical,
    //  HebrewCivilId: () => GetHebrewCalendar(HebrewMonthNumbering.Civil),
    //  HebrewScripturalId: () => GetHebrewCalendar(HebrewMonthNumbering.Scriptural),
    _gregorianId: () => gregorian,
    //  CopticId: () => Coptic,
    //  WondrousId: () => Wondrous,
    _julianId: () => julian,
  //  UmAlQuraId: () => UmAlQura,
  //  GetIslamicId(IslamicLeapYearPattern.Indian, IslamicEpoch.Civil): () => GetIslamicCalendar(IslamicLeapYearPattern.Indian, IslamicEpoch.Civil),
  //  GetIslamicId(IslamicLeapYearPattern.Base15, IslamicEpoch.Civil): () => GetIslamicCalendar(IslamicLeapYearPattern.Base15, IslamicEpoch.Civil),
  //  GetIslamicId(IslamicLeapYearPattern.Base16, IslamicEpoch.Civil): () => GetIslamicCalendar(IslamicLeapYearPattern.Base16, IslamicEpoch.Civil),
  //  GetIslamicId(IslamicLeapYearPattern.HabashAlHasib, IslamicEpoch.Civil): () => GetIslamicCalendar(IslamicLeapYearPattern.HabashAlHasib, IslamicEpoch.Civil),
  //  GetIslamicId(IslamicLeapYearPattern.Indian, IslamicEpoch.Astronomical): () => GetIslamicCalendar(IslamicLeapYearPattern.Indian, IslamicEpoch.Astronomical),
  //  GetIslamicId(IslamicLeapYearPattern.Base15, IslamicEpoch.Astronomical): () => GetIslamicCalendar(IslamicLeapYearPattern.Base15, IslamicEpoch.Astronomical),
  //  GetIslamicId(IslamicLeapYearPattern.Base16, IslamicEpoch.Astronomical): () => GetIslamicCalendar(IslamicLeapYearPattern.Base16, IslamicEpoch.Astronomical),
  //  GetIslamicId(IslamicLeapYearPattern.HabashAlHasib, IslamicEpoch.Astronomical): () => GetIslamicCalendar(IslamicLeapYearPattern.HabashAlHasib, IslamicEpoch.Astronomical)
  };


  /// Returns a calendar system that follows the rules of the ISO-8601 standard,
  /// which is compatible with Gregorian for all modern dates.
  ///
  /// As of NoTime Machine 2.0, this calendar system is equivalent to [gregorian].
  /// The only areas in which the calendars differed were around centuries, and the members
  /// relating to those differences were removed in Time Machine 2.0.
  /// The distinction between Gregorian and ISO has been maintained for the sake of simplicity, compatibility
  /// and consistency.
  static final CalendarSystem iso = _isoCalendarSystem;


/// Returns a Hebrew calendar, as described at http://en.wikipedia.org/wiki/Hebrew_calendar. This is a
/// purely mathematical calculator, applied proleptically to the period where the real calendar was observational.
///
/// Please note that in version 1.3.0 of Time Machine, support for the Hebrew calendar is somewhat experimental,
/// particularly in terms of calculations involving adding or subtracting years. Additionally, text formatting
/// and parsing using month names is not currently supported, due to the challenges of handling leap months.
/// It is hoped that this will be improved in future versions.
/// The implementation for this was taken from http://www.cs.tau.ac.il/~nachum/calendar-book/papers/calendar.ps,
/// which is a domain algorithm presumably equivalent to that given in the Calendrical Calculations book
/// by the same authors (Nachum Dershowitz and Edward Reingold).
///
/// [monthNumbering]: The month numbering system to use
/// Returns: A Hebrew calendar system for the given month numbering.
//static CalendarSystem GetHebrewCalendar(HebrewMonthNumbering monthNumbering)
//{
//Preconditions.checkArgumentRange('monthNumbering', (int) monthNumbering, 1, 2);
//return HebrewCalendars.ByMonthNumbering[((int) monthNumbering) - 1];
//}


/// Returns the Wondrous (Badí') calendar, as described at https://en.wikipedia.org/wiki/Badi_calendar.
/// This is a purely solar calendar with years starting at the vernal equinox.
///
/// The Wondrous calendar was developed and defined by the founders of the Bahá'í Faith in the mid to late
/// 1800's A.D. The first year in the calendar coincides with 1844 A.D. Years are labeled "B.E." for Bahá'í Era.
/// A year consists of 19 months, each with 19 days. Each day starts at sunset. Years are grouped into sets
/// of 19 "Unities" (Váḥid) and 19 Unities make up 1 "All Things" (Kull-i-Shay’).
/// A period of days (usually 4 or 5, called Ayyám-i-Há) occurs between the 18th and 19th months. The length of this
/// period of intercalary days is solely determined by the date of the following vernal equinox. The vernal equinox is
/// a momentary point in time, so the "date" of the equinox is determined by the date (beginning
/// at sunset) in effect in Tehran, Iran at the moment of the equinox.
/// In this Time Machine implementation, days start at midnight and lookup tables are used to determine vernal equinox dates.
/// Ayyám-i-Há is internally modelled as extra days added to the 18th month. As a result, a few functions will
/// not work as expected for Ayyám-i-Há, such as EndOfMonth.
///
/// Returns: The Wondrous calendar system.
// static CalendarSystem Wondrous => MiscellaneousCalendars.Wondrous;


  /// Returns an Islamic, or Hijri, calendar system.
  ///
  /// This returns a tablular calendar, rather than one based on lunar observation. This calendar is a
  /// lunar calendar with 12 months, each of 29 or 30 days, resulting in a year of 354 days (or 355 on a leap
  /// year).
  ///
  /// Year 1 in the Islamic calendar began on July 15th or 16th, 622 CE (Julian), thus
  /// Islamic years do not begin at the same time as Julian years. This calendar
  /// is not proleptic, as it does not allow dates before the first Islamic year.
  ///
  /// There are two basic forms of the Islamic calendar, the tabular and the
  /// observed. The observed form cannot easily be used by computers as it
  /// relies on human observation of the new moon. The tabular calendar, implemented here, is an
  /// arithmetic approximation of the observed form that follows relatively simple rules.
  ///
  /// You should choose an epoch based on which external system you wish
  /// to be compatible with. The epoch beginning on July 16th is the more common
  /// one for the tabular calendar, so using [IslamicEpoch.Civil]
  /// would usually be a logical choice. However, Windows uses July 15th, so
  /// if you need to be compatible with other Windows systems, you may wish to use
  /// [IslamicEpoch.Astronomical]. The fact that the Islamic calendar
  /// traditionally starts at dusk, a Julian day traditionally starts at noon,
  /// and all calendar systems in Time Machine start their days at midnight adds
  /// somewhat inevitable confusion to the mix, unfortunately.
  ///
  /// The tabular form of the calendar defines 12 months of alternately
  /// 30 and 29 days. The last month is extended to 30 days in a leap year.
  /// Leap years occur according to a 30 year cycle. There are four recognised
  /// patterns of leap years in the 30 year cycle:
  ///
  /// <list type="table">
  ///    <listheader><term>Origin</term><description>Leap years</description></listheader>
  ///    <item><term>Kūshyār ibn Labbān</term><description>2, 5, 7, 10, 13, 15, 18, 21, 24, 26, 29</description></item>
  ///    <item><term>al-Fazārī</term><description>2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29</description></item>
  ///    <item><term>Fātimid (also known as Misri or Bohra)</term><description>2, 5, 8, 10, 13, 16, 19, 21, 24, 27, 29</description></item>
  ///    <item><term>Habash al-Hasib</term><description>2, 5, 8, 11, 13, 16, 19, 21, 24, 27, 30</description></item>
  /// </list>
  ///
  /// The leap year pattern to use is determined from the first parameter to this factory method.
  /// The second parameter determines which epoch is used - the "astronomical" or "Thursday" epoch
  /// (July 15th 622CE) or the "civil" or "Friday" epoch (July 16th 622CE).
  ///
  /// This implementation defines a day as midnight to midnight exactly as per
  /// the ISO calendar. This correct start of day is at sunset on the previous
  /// day, however this cannot readily be modelled and has been ignored.
  ///
  /// [leapYearPattern]: The pattern of years in the 30-year cycle to consider as leap years
  /// [epoch]: The kind of epoch to use (astronomical or civil)
  /// A suitable Islamic calendar reference; the same reference may be returned by several
  /// calls as the object is immutable and thread-safe.
  static CalendarSystem getIslamicCalendar(leapYearPattern, epoch) => throw new UnimplementedError();
//  static CalendarSystem GetIslamicCalendar(IslamicLeapYearPattern leapYearPattern, IslamicEpoch epoch)
//  {
//    Preconditions.checkArgumentRange('leapYearPattern', leapYearPattern.value, 1, 4);
//    Preconditions.checkArgumentRange('epoch', epoch.value, 1, 2);
//    return IslamicCalendars.ByLeapYearPatterAndEpoch[leapYearPattern.value - 1, epoch.value - 1];
//  }

// #endregion

  // Other fields back read-only automatic properties.
  @private final EraCalculator eraCalculator;

  @private CalendarSystem.singleEra(CalendarOrdinal ordinal, String id, String name, YearMonthDayCalculator yearMonthDayCalculator, Era singleEra)
      : this(ordinal, id, name, yearMonthDayCalculator, new SingleEraCalculator(singleEra, yearMonthDayCalculator));

  @private CalendarSystem(this.ordinal, this.id, this.name, this.yearMonthDayCalculator, this.eraCalculator)
      :
        minYear = yearMonthDayCalculator.minYear,
        maxYear = yearMonthDayCalculator.maxYear,
        minDays = yearMonthDayCalculator.getStartOfYearInDays(yearMonthDayCalculator.minYear),
        maxDays = yearMonthDayCalculator.getStartOfYearInDays(yearMonthDayCalculator.maxYear + 1) - 1 {
    // We trust the construction code not to mutate the array...
    _calendarByOrdinal[ordinal.value] = this;
  }


  /// Returns the unique identifier for this calendar system. This is provides full round-trip capability
  /// using [forId] to retrieve the calendar system from the identifier.
  ///
  /// A unique ID for a calendar is required when serializing types which include a [CalendarSystem].
  /// As of 2 Nov 2012 (ISO calendar) there are no ISO or RFC standards for naming a calendar system. As such,
  /// the identifiers provided here are specific to Time Machine, and are not guaranteed to interoperate with any other
  /// date and time API.
  ///
  /// <list type="table">
  ///   <listheader>
  ///     <term>Calendar ID</term>
  ///     <description>Equivalent factory method or property</description>
  ///   </listheader>
  ///   <item><term>ISO</term><description>[CalendarSystem.iso]</description></item>
  ///   <item><term>Gregorian</term><description>[CalendarSystem.gregorian]</description></item>
  ///   <item><term>Coptic</term><description>[CalendarSystem.coptic]</description></item>
  ///   <item><term>Wondrous</term><description>[CalendarSystem.wondrous]</description></item>
  ///   <item><term>Julian</term><description>[CalendarSystem.julian]</description></item>
  ///   <item><term>Hijri Civil-Indian</term><description>[CalendarSystem.GetIslamicCalendar](IslamicLeapYearPattern.Indian, IslamicEpoch.Civil)</description></item>
  ///   <item><term>Hijri Civil-Base15</term><description>[CalendarSystem.GetIslamicCalendar](IslamicLeapYearPattern.Base15, IslamicEpoch.Civil)</description></item>
  ///   <item><term>Hijri Civil-Base16</term><description>[CalendarSystem.GetIslamicCalendar](IslamicLeapYearPattern.Base16, IslamicEpoch.Civil)</description></item>
  ///   <item><term>Hijri Civil-HabashAlHasib</term><description>[CalendarSystem.GetIslamicCalendar](IslamicLeapYearPattern.HabashAlHasib, IslamicEpoch.Civil)</description></item>
  ///   <item><term>Hijri Astronomical-Indian</term><description>[CalendarSystem.GetIslamicCalendar](IslamicLeapYearPattern.Indian, IslamicEpoch.Astronomical)</description></item>
  ///   <item><term>Hijri Astronomical-Base15</term><description>[CalendarSystem.GetIslamicCalendar](IslamicLeapYearPattern.Base15, IslamicEpoch.Astronomical)</description></item>
  ///   <item><term>Hijri Astronomical-Base16</term><description>[CalendarSystem.GetIslamicCalendar](IslamicLeapYearPattern.Base16, IslamicEpoch.Astronomical)</description></item>
  ///   <item><term>Hijri Astronomical-HabashAlHasib</term><description>[CalendarSystem.GetIslamicCalendar](IslamicLeapYearPattern.HabashAlHasib, IslamicEpoch.Astronomical)</description></item>
  ///   <item><term>Persian Simple</term><description>[CalendarSystem.persianSimple]</description></item>
  ///   <item><term>Persian Arithmetic</term><description>[CalendarSystem.persianArithmetic]</description></item>
  ///   <item><term>Persian Astronomical</term><description>[CalendarSystem.persianAstronomical]</description></item>
  ///   <item><term>Um Al Qura</term><description>[CalendarSystem.UmAlQura]()</description></item>
  ///   <item><term>Hebrew Civil</term><description>[CalendarSystem.hebrewCivil]</description></item>
  ///   <item><term>Hebrew Scriptural</term><description>[CalendarSystem.hebrewScriptural]</description></item>
  /// </list>
  final String id;


  /// Returns the name of this calendar system. Each kind of calendar system has a unique name, but this
  /// does not usually provide enough information for round-tripping. (For example, the name of an
  /// Islamic calendar system does not indicate which kind of leap cycle it uses.)
  final String name;


  /// Gets the minimum valid year (inclusive) within this calendar.
  final int minYear;


  /// Gets the maximum valid year (inclusive) within this calendar.
  final int maxYear;


  /// Returns the minimum day number this calendar can handle.
  @internal final int minDays;


  /// Returns the maximum day number (inclusive) this calendar can handle.
  @internal final int maxDays;


  /// Returns the ordinal value of this calendar.
  @internal final CalendarOrdinal ordinal;

// #region Era-based members


  /// Gets a read-only list of eras used in this calendar system.
  Iterable<Era> get eras => eraCalculator.eras;


  /// Returns the "absolute year" (the one used throughout most of the API, without respect to eras)
  /// from a year-of-era and an era.
  ///
  /// For example, in the Gregorian and Julian calendar systems, the BCE era starts at year 1, which is
  /// equivalent to an "absolute year" of 0 (then BCE year 2 has an absolute year of -1, and so on).  The absolute
  /// year is the year that is used throughout the API; year-of-era is typically used primarily when formatting
  /// and parsing date values to and from text.
  ///
  /// [yearOfEra]: The year within the era.
  /// [era]: The era in which to consider the year
  /// Returns: The absolute year represented by the specified year of era.
  /// [ArgumentOutOfRangeException]: [yearOfEra] is out of the range of years for the given era.
  /// [ArgumentException]: [era] is not an era used in this calendar.
  int getAbsoluteYear(int yearOfEra, Era era) => eraCalculator.getAbsoluteYear(yearOfEra, era);


  /// Returns the maximum valid year-of-era in the given era.
  ///
  /// Note that depending on the calendar system, it's possible that only
  /// part of the returned year falls within the given era. It is also possible that
  /// the returned value represents the earliest year of the era rather than the latest
  /// year. (See the BC era in the Gregorian calendar, for example.)
  /// [era]: The era in which to find the greatest year
  /// Returns: The maximum valid year in the given era.
  /// [ArgumentException]: [era] is not an era used in this calendar.
  int getMaxYearOfEra(Era era) => eraCalculator.getMaxYearOfEra(era);


  /// Returns the minimum valid year-of-era in the given era.
  ///
  /// Note that depending on the calendar system, it's possible that only
  /// part of the returned year falls within the given era. It is also possible that
  /// the returned value represents the latest year of the era rather than the earliest
  /// year. (See the BC era in the Gregorian calendar, for example.)
  /// [era]: The era in which to find the greatest year
  /// Returns: The minimum valid year in the given eraera.
  /// [ArgumentException]: [era] is not an era used in this calendar.
  int getMinYearOfEra(Era era) => eraCalculator.getMinYearOfEra(era);

  @internal final YearMonthDayCalculator yearMonthDayCalculator;

  @internal YearMonthDayCalendar getYearMonthDayCalendarFromDaysSinceEpoch(int daysSinceEpoch) {
    Preconditions.checkArgumentRange('daysSinceEpoch', daysSinceEpoch, minDays, maxDays);
    return yearMonthDayCalculator.getYearMonthDayFromDaysSinceEpoch(daysSinceEpoch).withCalendarOrdinal(ordinal);
  }
  
  /// Converts this calendar system to text by simply returning its unique ID.
  ///
  /// Returns: The ID of this calendar system.
  @override String toString() => id;

  /// Returns the number of days since the Unix epoch (1970-01-01 ISO) for the given date.
  @internal int getDaysSinceEpoch(YearMonthDay yearMonthDay) {
    // DebugValidateYearMonthDay(yearMonthDay);
    return yearMonthDayCalculator.getDaysSinceEpoch(yearMonthDay);
  }


  /// Returns the IsoDayOfWeek corresponding to the day of week for the given year, month and day.
  ///
  /// [yearMonthDay]: The year, month and day to use to find the day of the week
  /// Returns: The day of the week as an IsoDayOfWeek
  @internal IsoDayOfWeek getDayOfWeek(YearMonthDay yearMonthDay) {
    // DebugValidateYearMonthDay(yearMonthDay);
    int daysSinceEpoch = yearMonthDayCalculator.getDaysSinceEpoch(yearMonthDay);
    // % operations in C# retain their sign, in Dart they are always positive
    int numericDayOfWeek = daysSinceEpoch >= -3 ? 1 + ((daysSinceEpoch + 3) % 7)
        : 7 + -(-(daysSinceEpoch + 4) % 7);
    return new IsoDayOfWeek(numericDayOfWeek);
  }


  /// Returns the number of days in the given year.
  ///
  /// [year]: The year to determine the number of days in
  /// [ArgumentOutOfRangeException]: The given year is invalid for this calendar.
  /// Returns: The number of days in the given year.
  int getDaysInYear(int year) {
    Preconditions.checkArgumentRange('year', year, minYear, maxYear);
    return yearMonthDayCalculator.getDaysInYear(year);
  }


  /// Returns the number of days in the given month within the given year.
  ///
  /// [year]: The year in which to consider the month
  /// [month]: The month to determine the number of days in
  /// [ArgumentOutOfRangeException]: The given year / month combination
  /// is invalid for this calendar.
  /// Returns: The number of days in the given month and year.
  int getDaysInMonth(int year, int month) {
    // Simplest way to validate the year and month. Assume it's quick enough to validate the day...
    validateYearMonthDay(year, month, 1);
    return yearMonthDayCalculator.getDaysInMonth(year, month);
  }


  /// Returns whether or not the given year is a leap year in this calendar.
  ///
  /// [year]: The year to consider.
  /// [ArgumentOutOfRangeException]: The given year is invalid for this calendar.
  /// Note that some implementations may return a value rather than throw this exception. Failure to throw an
  /// exception should not be treated as an indication that the year is valid.
  /// Returns: True if the given year is a leap year; false otherwise.
  bool isLeapYear(int year) {
    Preconditions.checkArgumentRange('year', year, minYear, maxYear);
    return yearMonthDayCalculator.IsLeapYear(year);
  }


  /// Returns the maximum valid month (inclusive) within this calendar in the given year.
  ///
  /// It is assumed that in all calendars, every month between 1 and this month
  /// number is valid for the given year. This does not necessarily mean that the first month of the year
  /// is 1, however. (See the Hebrew calendar system using the scriptural month numbering system for example.)
  ///
  /// [year]: The year to consider.
  /// [ArgumentOutOfRangeException]: The given year is invalid for this calendar.
  /// Note that some implementations may return a month rather than throw this exception (for example, if all
  /// years have the same number of months in this calendar system). Failure to throw an exception should not be
  /// treated as an indication that the year is valid.
  /// Returns: The maximum month number within the given year.
  int getMonthsInYear(int year) {
    Preconditions.checkArgumentRange('year', year, minYear, maxYear);
    return yearMonthDayCalculator.getMonthsInYear(year);
  }

  @internal void validateYearMonthDay(int year, int month, int day) {
    yearMonthDayCalculator.validateYearMonthDay(year, month, day);
  }

  // todo: name
  @internal void validateYearMonthDay_(YearMonthDay ymd) {
    yearMonthDayCalculator.validateYearMonthDay(ymd.year, ymd.month, ymd.day);
  }

  @internal int compare(YearMonthDay lhs, YearMonthDay rhs) {
    //DebugValidateYearMonthDay(lhs);
    //DebugValidateYearMonthDay(rhs);
    return yearMonthDayCalculator.compare(lhs, rhs);
  }

// #region "Getter" methods which used to be DateTimeField

  @internal int getDayOfYear(YearMonthDay yearMonthDay) {
    //DebugValidateYearMonthDay(yearMonthDay);
    return yearMonthDayCalculator.getDayOfYear(yearMonthDay);
  }

  @internal int getYearOfEra(int absoluteYear) {
    Preconditions.debugCheckArgumentRange('absoluteYear', absoluteYear, minYear, maxYear);
    return eraCalculator.GetYearOfEra(absoluteYear);
  }

  @internal Era getEra(int absoluteYear) {
    Preconditions.debugCheckArgumentRange('absoluteYear', absoluteYear, minYear, maxYear);
    return eraCalculator.GetEra(absoluteYear);
  }


  /// Returns a Gregorian calendar system.
  ///
  /// The Gregorian calendar system defines every
  /// fourth year as leap, unless the year is divisible by 100 and not by 400.
  /// This improves upon the Julian calendar leap year rule.
  ///
  /// Although the Gregorian calendar did not exist before 1582 CE, this
  /// calendar system assumes it did, thus it is proleptic. This implementation also
  /// fixes the start of the year at January 1.
  static final CalendarSystem gregorian = GregorianJulianCalendars.gregorian;


  /// Returns a pure proleptic Julian calendar system, which defines every
  /// fourth year as a leap year. This implementation follows the leap year rule
  /// strictly, even for dates before 8 CE, where leap years were actually
  /// irregular.
  ///
  /// Although the Julian calendar did not exist before 45 BCE, this calendar
  /// assumes it did, thus it is proleptic. This implementation also fixes the
  /// start of the year at January 1.
  ///
  /// A suitable Julian calendar reference; the same reference may be returned by several
  /// calls as the object is immutable and thread-safe.<
  static final CalendarSystem julian = GregorianJulianCalendars.julian;


  /// Returns a Coptic calendar system, which defines every fourth year as
  /// leap, much like the Julian calendar. The year is broken down into 12 months,
  /// each 30 days in length. An extra period at the end of the year is either 5
  /// or 6 days in length. In this implementation, it is considered a 13th month.
  ///
  /// Year 1 in the Coptic calendar began on August 29, 284 CE (Julian), thus
  /// Coptic years do not begin at the same time as Julian years. This calendar
  /// is not proleptic, as it does not allow dates before the first Coptic year.
  ///
  /// This implementation defines a day as midnight to midnight exactly as per
  /// the ISO calendar. Some references indicate that a Coptic day starts at
  /// sunset on the previous ISO day, but this has not been confirmed and is not
  /// implemented.
  ///
  /// <value>A suitable Coptic calendar reference; the same reference may be returned by several
  /// calls as the object is immutable and thread-safe.</value>
  static CalendarSystem get coptic => throw new UnimplementedError(); // MiscellaneousCalendars.Coptic;


  /// Returns an Islamic calendar system equivalent to the one used by the BCL HijriCalendar.
  ///
  /// This uses the [IslamicLeapYearPattern.Base16] leap year pattern and the
  /// [IslamicEpoch.Astronomical] epoch. This is equivalent to HijriCalendar
  /// when the `HijriCalendar.HijriAdjustment` is 0.
  ///
  /// <seealso cref="CalendarSystem.GetIslamicCalendar"/>
  static CalendarSystem get islamicBcl => throw new UnimplementedError(); // GetIslamicCalendar(IslamicLeapYearPattern.Base16, IslamicEpoch.Astronomical);


  /// Returns a Persian (also known as Solar Hijri) calendar system implementing the behaviour of the
  /// BCL `PersianCalendar` before .NET 4.6, and the sole Persian calendar in Time Machine 1.3.
  ///
  /// This implementation uses a simple 33-year leap cycle, where years  1, 5, 9, 13, 17, 22, 26, and 30
  /// in each cycle are leap years.
  static CalendarSystem get persianSimple => throw new UnimplementedError(); // PersianCalendars.Simple;


  /// Returns a Persian (also known as Solar Hijri) calendar system implementing the behaviour of the
  /// BCL `PersianCalendar` from .NET 4.6 onwards (and Windows 10), and the astronomical
  /// system described in Wikipedia and Calendrical Calculations.
  ///
  /// This implementation uses data derived from the .NET 4.6 implementation (with the data built into Time Machine, so there's
  /// no BCL dependency) for simplicity; the actual implementation involves computing the time of noon in Iran, and
  /// is complex.
  static CalendarSystem get persianArithmetic => throw new UnimplementedError(); // PersianCalendars.Arithmetic;


  /// Returns a Persian (also known as Solar Hijri) calendar system implementing the behaviour
  /// proposed by Ahmad Birashk with nested cycles of years determining which years are leap years.
  ///
  /// This calendar is also known as the algorithmic Solar Hijri calendar.
  static CalendarSystem get persianAstronomical => throw new UnimplementedError(); // PersianCalendars.Astronomical;


  /// Returns a Hebrew calendar system using the civil month numbering,
  /// equivalent to the one used by the BCL HebrewCalendar.
  ///
  /// <seealso cref="CalendarSystem.GetHebrewCalendar"/>
  /// <value>A Hebrew calendar system using the civil month numbering, equivalent to the one used by the
  /// BCL.</value>
  static CalendarSystem get hebrewCivil => throw new UnimplementedError(); // GetHebrewCalendar(HebrewMonthNumbering.Civil);


  /// Returns a Hebrew calendar system using the scriptural month numbering.
  ///
  /// <seealso cref="CalendarSystem.GetHebrewCalendar"/>
  static CalendarSystem get hebrewScriptural => throw new UnimplementedError(); // GetHebrewCalendar(HebrewMonthNumbering.Scriptural);


  /// Returns an Um Al Qura calendar system - an Islamic calendar system primarily used by
  /// Saudi Arabia.
  ///
  /// This is a tabular calendar, relying on pregenerated data.
  static CalendarSystem get umAlQura => throw new UnimplementedError(); // MiscellaneousCalendars.UmAlQura;

}

// "Holder" classes for lazy initialization of calendar systems
// todo: privative! piratize?
// todo: Dart lazy loads static variables, can I use this to lazy load these calendars?
// (https://stackoverflow.com/questions/23511100/final-and-top-level-lazy-initialization) ~ I'm unable to find official information on this - check language spec?

@private class PersianCalendars
{
//  @internal static final CalendarSystem Simple =
//  new CalendarSystem(CalendarOrdinal.PersianSimple, PersianSimpleId, PersianName, new PersianYearMonthDayCalculator.Simple(), Era.AnnoPersico);
//  @internal static final CalendarSystem Arithmetic =
//  new CalendarSystem(CalendarOrdinal.PersianArithmetic, PersianArithmeticId, PersianName, new PersianYearMonthDayCalculator.Arithmetic(), Era.AnnoPersico);
//  @internal static final CalendarSystem Astronomical =
//  new CalendarSystem(CalendarOrdinal.PersianAstronomical, PersianAstronomicalId, PersianName, new PersianYearMonthDayCalculator.Astronomical(), Era.AnnoPersico);
}


/// Specifically the calendars implemented by IslamicYearMonthDayCalculator, as opposed to all
/// Islam-based calendars (which would include UmAlQura and Persian, for example).
@private class IslamicCalendars
{
//  @internal static final CalendarSystem[,] ByLeapYearPatterAndEpoch;
//
//// todo: was a static constructor
//  IslamicCalendars()
//  {
//    ByLeapYearPatterAndEpoch = new CalendarSystem[4, 2];
//    for (int i = 1; i <= 4; i++)
//    {
//      for (int j = 1; j <= 2; j++)
//      {
//        var leapYearPattern = (IslamicLeapYearPattern) i;
//        var epoch = (IslamicEpoch) j;
//        var calculator = new IslamicYearMonthDayCalculator((IslamicLeapYearPattern) i, (IslamicEpoch) j);
//        CalendarOrdinal ordinal = CalendarOrdinal.IslamicAstronomicalBase15 + (i - 1) + (j - 1) * 4;
//        ByLeapYearPatterAndEpoch[i - 1, j - 1] = new CalendarSystem(ordinal, GetIslamicId(leapYearPattern, epoch), IslamicName, calculator, Era.AnnoHegirae);
//      }
//    }
//  }
}


/// Odds and ends, with an assumption that it's not *that* painful to initialize UmAlQura if you only
/// need Coptic, for example.
@private class MiscellaneousCalendars {
//  @internal static final CalendarSystem Coptic =
//  new CalendarSystem(CalendarOrdinal.Coptic, CopticId, CopticName, new CopticYearMonthDayCalculator(), Era.AnnoMartyrum);
//  @internal static final CalendarSystem UmAlQura =
//  new CalendarSystem(CalendarOrdinal.UmAlQura, UmAlQuraId, UmAlQuraName, new UmAlQuraYearMonthDayCalculator(), Era.AnnoHegirae);
//  @internal static final CalendarSystem Wondrous =
//  new CalendarSystem(CalendarOrdinal.Wondrous, WondrousId, WondrousName, new WondrousYearMonthDayCalculator(), Era.Bahai);
}

@private class GregorianJulianCalendars {
  static CalendarSystem _gregorian;
  static CalendarSystem _julian;

  @internal static CalendarSystem get gregorian => _gregorian ?? _init()[0];
  @internal static CalendarSystem get julian => _julian ?? _init()[1];

  // todo: was a static constructor .. is this an okay pattern?
  static List<CalendarSystem> _init() {
    var julianCalculator = new JulianYearMonthDayCalculator();
    _julian = new CalendarSystem(CalendarOrdinal.julian, CalendarSystem._julianId, CalendarSystem._julianName,
        julianCalculator, new GJEraCalculator(julianCalculator));
    _gregorian = new CalendarSystem(CalendarOrdinal.gregorian, CalendarSystem._gregorianId, CalendarSystem._gregorianName,
        CalendarSystem._isoCalendarSystem.yearMonthDayCalculator, CalendarSystem._isoCalendarSystem.eraCalculator);

    return [_gregorian, _julian];
  }
}

@private class HebrewCalendars {
//  @internal static final List<CalendarSystem> ByMonthNumbering =
//  [
//    new CalendarSystem(CalendarOrdinal.HebrewCivil, HebrewCivilId, HebrewName, new HebrewYearMonthDayCalculator(HebrewMonthNumbering.Civil), Era.AnnoMundi),
//    new CalendarSystem(
//        CalendarOrdinal.HebrewScriptural, HebrewScripturalId, HebrewName, new HebrewYearMonthDayCalculator(HebrewMonthNumbering.Scriptural), Era.AnnoMundi)
//  ];
}
