import 'package:meta/meta.dart';

// BCL fill-in
class CompareInfo {
  // Todo: look at uses, we need to know how much shim we need
}

// https://github.com/dotnet/coreclr/blob/master/src/System.Private.CoreLib/src/System/Globalization/CultureInfo.Unix.cs
// https://github.com/dotnet/coreclr/blob/master/src/System.Private.CoreLib/src/System/Globalization/CultureInfo.cs
@immutable
class CultureInfo {
  // another fill-in

  static final CultureInfo InvariantCulture = new CultureInfo.invariantCulture();
  static CultureInfo get CurrentCulture => InvariantCulture;
  bool get IsReadOnly => true;

  final DateTimeFormatInfo DateTimeFormat;
  final CompareInfo compareInfo;

  final String Name;

  CultureInfo.invariantCulture()
  : DateTimeFormat = new DateTimeFormatInfo.invariantCulture(),
    Name = "Invariant Culture",
    compareInfo = null
    ;
}

enum BclCalendarType {
  unknown,
  gregorian,
  persian,
  hijri,
  umAlQura
}

@immutable
class DateTimeFormatInfo {
  final String AMDesignator;
  final String PMDesignator;

  final String TimeSeparator;
  final String DateSeparator;

  final List<String> AbbreviatedDayNames;
  final List<String> DayNames;
  final List<String> MonthNames;
  final List<String> AbbreviatedMonthNames;
  final List<String> MonthGenitiveNames;
  final List<String> AbbreviatedMonthGenitiveNames;

  // BCL Calendar Class
  final BclCalendarType Calendar;

  final List<String> EraNames;
  String GetEraName(int era) {
    if (era == 0) throw new UnimplementedError('Calendar.CurrentEraValue not implemented.');
    if (--era < this.EraNames.length && era >= 0) return EraNames[era];
    throw new ArgumentError.value(era, 'era');
  }

  final String FullDateTimePattern;
  final String ShortDatePattern;
  final String LongDatePattern;
  final String ShortTimePattern;
  final String LongTimePattern;

  DateTimeFormatInfo.invariantCulture()
      : AMDesignator = 'AM',
        PMDesignator = 'PM',
        TimeSeparator = ':',
        DateSeparator = '/',
        AbbreviatedDayNames = const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
        DayNames = const ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
        // Month's have a blank entry at the end
        MonthNames = const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', ''],
        AbbreviatedMonthNames = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', ''],
        MonthGenitiveNames = const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', ''],
        AbbreviatedMonthGenitiveNames = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', ''],
        Calendar = BclCalendarType.gregorian,
        EraNames = const ['A.D.'],
        FullDateTimePattern = 'dddd, dd MMMM yyyy HH:mm:ss',
        ShortDatePattern = 'MM/dd/yyyy',
        LongDatePattern = 'dddd, dd MMMM yyyy',
        ShortTimePattern = 'HH:mm',
        LongTimePattern = 'HH:mm:ss'
    ;
}

abstract class IFormatProvider
{
  // Interface does not need to be marked with the serializable attribute
  Object GetFormat(Type formatType);
}