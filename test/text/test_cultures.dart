// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';
import 'dart:math' as math;
import 'dart:mirrors';

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_patterns.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import '../time_machine_testing.dart';
import 'pattern_test_data.dart';
import 'text_cursor_test_base_tests.dart';

@internal abstract class TestLocalDateTimes {
  @private static final LocalDateTime SampleLocalDateTime = new LocalDateTime.fromYMDHMS(1976, 6, 19, 21, 13, 34).plusNanoseconds(123456789);
  @private static final LocalDateTime SampleLocalDateTimeToTicks = new LocalDateTime.fromYMDHMS(1976, 6, 19, 21, 13, 34).plusNanoseconds(123456700);
  @private static final LocalDateTime SampleLocalDateTimeToMillis = new LocalDateTime.fromYMDHMSM(
      1976,
      6,
      19,
      21,
      13,
      34,
      123);
  @private static final LocalDateTime SampleLocalDateTimeToSeconds = new LocalDateTime.fromYMDHMS(1976, 6, 19, 21, 13, 34);
  @private static final LocalDateTime SampleLocalDateTimeToMinutes = new LocalDateTime.fromYMDHM(1976, 6, 19, 21, 13);

/*@internal static final LocalDateTime SampleLocalDateTimeCoptic = new LocalDateTime.fromYMDHMSC(
      1976,
      6,
      19,
      21,
      13,
      34,
      CalendarSystem.Coptic).PlusNanoseconds(123456789);*/

  // The standard example date/time used in all the MSDN samples, which means we can just cut and paste
  // the expected results of the standard patterns.
  @internal static final LocalDateTime MsdnStandardExample = new LocalDateTime.fromYMDHMSM(
      2009,
      06,
      15,
      13,
      45,
      30,
      90);
  @internal static final LocalDateTime MsdnStandardExampleNoMillis = new LocalDateTime.fromYMDHMS(2009, 06, 15, 13, 45, 30);
  @private static final LocalDateTime MsdnStandardExampleNoSeconds = new LocalDateTime.fromYMDHM(2009, 06, 15, 13, 45);
}

/// Cultures to use from various tests.
@internal abstract class TestCultures {
  /*
  // Force the cultures to be read-only for tests, to take advantage of caching. Note that on .NET Core,
  // CultureInfo.GetCultures doesn't exist, so we have a big long list of cultures, generated against
  // .NET 4.6.
  @internal static final Iterable<CultureInfo> AllCultures = CultureInfo.GetCultures(CultureTypes.SpecificCultures)
      .Where((culture) => !RuntimeFailsToLookupResourcesForCulture(culture))
      .Where((culture) => !MonthNamesCompareEqual(culture))
      .Select(CultureInfo.ReadOnly)
      .ToList();*/

  @internal static final CultureInfo Invariant = CultureInfo.invariantCulture;

  static CultureInfo getCulture(String id) {
    switch (id) {
      case 'en-US': return EnUs;
      case 'fr-FR': return FrFr;
      case 'fr-CA': return FrCa;
      case 'ff-Fi': return DotTimeSeparator;
    }

    return null;
  }

// Specify en-US patterns explicitly, as .NET Core on Linux gives a different answer. We
// don't need it to be US English really, just an example...

  // Generated this from C#
  static final CultureInfo EnUs =
  new CultureInfo('en-US', (new DateTimeFormatInfoBuilder()
    ..amDesignator = 'AM'
    ..pmDesignator = 'PM'
    ..timeSeparator = ':'
    ..dateSeparator = '/'
    ..abbreviatedDayNames = const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
    ..dayNames = const ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    ..monthNames = const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', '']
    ..abbreviatedMonthNames = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', '']
    ..monthGenitiveNames = const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', '']
    ..abbreviatedMonthGenitiveNames = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', '']
    ..calendar = BclCalendarType.gregorian
    ..eraNames = const ['AD']
    ..fullDateTimePattern = 'dddd, MMMM d, yyyy h:mm:ss tt'
    ..shortDatePattern = 'M/d/yyyy'
    ..longDatePattern = 'dddd, MMMM d, yyyy'
    ..shortTimePattern = 'h:mm tt'
    ..longTimePattern = 'h:mm:ss tt').Build());
  static final CultureInfo FrFr =
  new CultureInfo('fr-FR', (new DateTimeFormatInfoBuilder()
    ..amDesignator = 'AM'
    ..pmDesignator = 'PM'
    ..timeSeparator = ':'
    ..dateSeparator = '/'
    ..abbreviatedDayNames = const ['dim.', 'lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.']
    ..dayNames = const ['dimanche', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi']
    ..monthNames = const ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre', '']
    ..abbreviatedMonthNames = const ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.', '']
    ..monthGenitiveNames = const ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre', '']
    ..abbreviatedMonthGenitiveNames = const ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.', '']
    ..calendar = BclCalendarType.gregorian
    ..eraNames = const ['ap. J.-C.']
    ..fullDateTimePattern = 'dddd d MMMM yyyy HH:mm:ss'
    ..shortDatePattern = 'dd/MM/yyyy'
    ..longDatePattern = 'dddd d MMMM yyyy'
    ..shortTimePattern = 'HH:mm'
    ..longTimePattern = 'HH:mm:ss').Build());
  static final CultureInfo FrCa =
  new CultureInfo('fr-CA', (new DateTimeFormatInfoBuilder()
    ..amDesignator = 'a.m.'
    ..pmDesignator = 'p.m.'
    ..timeSeparator = ' '
    ..dateSeparator = '-'
    ..abbreviatedDayNames = const ['dim.', 'lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.']
    ..dayNames = const ['dimanche', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi']
    ..monthNames = const ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre', '']
    ..abbreviatedMonthNames = const ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juill.', 'août', 'sept.', 'oct.', 'nov.', 'déc.', '']
    ..monthGenitiveNames = const ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre', '']
    ..abbreviatedMonthGenitiveNames = const ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juill.', 'août', 'sept.', 'oct.', 'nov.', 'déc.', '']
    ..calendar = BclCalendarType.gregorian
    ..eraNames = const ['ap. J.-C.']
    ..fullDateTimePattern = 'd MMMM yyyy HH:mm:ss'
    ..shortDatePattern = 'yyyy-MM-dd'
    ..longDatePattern = 'd MMMM yyyy'
    ..shortTimePattern = 'HH:mm'
    ..longTimePattern = 'HH:mm:ss').Build());
  static final CultureInfo DotTimeSeparator =
  new CultureInfo('fi-FI', (new DateTimeFormatInfoBuilder()
    ..amDesignator = 'ap.'
    ..pmDesignator = 'ip.'
    ..timeSeparator = '.'
    ..dateSeparator = '.'
    ..abbreviatedDayNames = const ['su', 'ma', 'ti', 'ke', 'to', 'pe', 'la']
    ..dayNames = const ['sunnuntai', 'maanantai', 'tiistai', 'keskiviikko', 'torstai', 'perjantai', 'lauantai']
    ..monthNames = const [
      'tammikuu', 'helmikuu', 'maaliskuu', 'huhtikuu', 'toukokuu', 'kesäkuu', 'heinäkuu', 'elokuu', 'syyskuu', 'lokakuu', 'marraskuu', 'joulukuu', ''
    ]
    ..abbreviatedMonthNames = const ['tammi', 'helmi', 'maalis', 'huhti', 'touko', 'kesä', 'heinä', 'elo', 'syys', 'loka', 'marras', 'joulu', '']
    ..monthGenitiveNames = const [
      'tammikuuta',
      'helmikuuta',
      'maaliskuuta',
      'huhtikuuta',
      'toukokuuta',
      'kesäkuuta',
      'heinäkuuta',
      'elokuuta',
      'syyskuuta',
      'lokakuuta',
      'marraskuuta',
      'joulukuuta',
      ''
    ]
    ..abbreviatedMonthGenitiveNames = const [
      'tammik.', 'helmik.', 'maalisk.', 'huhtik.', 'toukok.', 'kesäk.', 'heinäk.', 'elok.', 'syysk.', 'lokak.', 'marrask.', 'jouluk.', ''
    ]
    ..calendar = BclCalendarType.gregorian
    ..eraNames = const ['jKr.']
    ..fullDateTimePattern = 'dddd d. MMMM yyyy H.mm.ss'
    ..shortDatePattern = 'd.M.yyyy'
    ..longDatePattern = 'dddd d. MMMM yyyy'
    ..shortTimePattern = 'H.mm'
    ..longTimePattern = 'H.mm.ss').Build());
  static final CultureInfo GenitiveNameTestCulture =
  new CultureInfo('', (new DateTimeFormatInfoBuilder()
    ..amDesignator = 'AM'
    ..pmDesignator = 'PM'
    ..timeSeparator = ':'
    ..dateSeparator = '/'
    ..abbreviatedDayNames = const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
    ..dayNames = const ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    ..monthNames = const ['FullNonGenName', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', '']
    ..abbreviatedMonthNames = const ['AbbrNonGenName', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', '']
    ..monthGenitiveNames = const [
      'FullGenName', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', ''
    ]
    ..abbreviatedMonthGenitiveNames = const ['AbbrGenName', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', '']
    ..calendar = BclCalendarType.gregorian
    ..eraNames = const ['A.D.']
    ..fullDateTimePattern = 'dddd, dd MMMM yyyy HH:mm:ss'
    ..shortDatePattern = 'MM/dd/yyyy'
    ..longDatePattern = 'dddd, dd MMMM yyyy'
    ..shortTimePattern = 'HH:mm'
    ..longTimePattern = 'HH:mm:ss').Build());
  static final CultureInfo GenitiveNameTestCultureWithLeadingNames =
  new CultureInfo('', (new DateTimeFormatInfoBuilder()
    ..amDesignator = 'AM'
    ..pmDesignator = 'PM'
    ..timeSeparator = ':'
    ..dateSeparator = '/'
    ..abbreviatedDayNames = const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
    ..dayNames = const ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    ..monthNames = const ['MonthName', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', '']
    ..abbreviatedMonthNames = const ['MN', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', '']
    ..monthGenitiveNames = const [
      'MonthName-Genitive', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', ''
    ]
    ..abbreviatedMonthGenitiveNames = const ['MN-Gen', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', '']
    ..calendar = BclCalendarType.gregorian
    ..eraNames = const ['A.D.']
    ..fullDateTimePattern = 'dddd, dd MMMM yyyy HH:mm:ss'
    ..shortDatePattern = 'MM/dd/yyyy'
    ..longDatePattern = 'dddd, dd MMMM yyyy'
    ..shortTimePattern = 'HH:mm'
    ..longTimePattern = 'HH:mm:ss').Build());
  static final CultureInfo AwkwardDayOfWeekCulture =
  new CultureInfo('', (new DateTimeFormatInfoBuilder()
    ..amDesignator = 'AM'
    ..pmDesignator = 'PM'
    ..timeSeparator = ':'
    ..dateSeparator = '/'
    ..abbreviatedDayNames = const ['Sun', 'Mon', 'Tue', 'Wed', 'FooBaz', 'Foo', 'Sat']
    ..dayNames = const ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'FooBa', 'FooBar', 'Saturday']
    ..monthNames = const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', '']
    ..abbreviatedMonthNames = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', '']
    ..monthGenitiveNames = const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', '']
    ..abbreviatedMonthGenitiveNames = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', '']
    ..calendar = BclCalendarType.gregorian
    ..eraNames = const ['A.D.']
    ..fullDateTimePattern = 'dddd, dd MMMM yyyy HH:mm:ss'
    ..shortDatePattern = 'MM/dd/yyyy'
    ..longDatePattern = 'dddd, dd MMMM yyyy'
    ..shortTimePattern = 'HH:mm'
    ..longTimePattern = 'HH:mm:ss').Build());

  static final CultureInfo AwkwardAmPmDesignatorCulture =
  new CultureInfo('', (new DateTimeFormatInfoBuilder()
    ..amDesignator = 'Foo'
    ..pmDesignator = 'FooBar'
    ..timeSeparator = ':'
    ..dateSeparator = '/'
    ..abbreviatedDayNames = const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
    ..dayNames = const ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    ..monthNames = const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', '']
    ..abbreviatedMonthNames = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', '']
    ..monthGenitiveNames = const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', '']
    ..abbreviatedMonthGenitiveNames = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', '']
    ..calendar = BclCalendarType.gregorian
    ..eraNames = const ['A.D.']
    ..fullDateTimePattern = 'dddd, dd MMMM yyyy HH:mm:ss'
    ..shortDatePattern = 'MM/dd/yyyy'
    ..longDatePattern = 'dddd, dd MMMM yyyy'
    ..shortTimePattern = 'HH:mm'
    ..longTimePattern = 'HH:mm:ss').Build());
}
