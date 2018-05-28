
// BCL fill-in
class CompareInfo {

}

// https://github.com/dotnet/coreclr/blob/master/src/System.Private.CoreLib/src/System/Globalization/CultureInfo.Unix.cs
// https://github.com/dotnet/coreclr/blob/master/src/System.Private.CoreLib/src/System/Globalization/CultureInfo.cs
class CultureInfo {
  // another fill-in

  static CultureInfo InvariantCulture;
  static CultureInfo CurrentCulture;
  bool get IsReadOnly => true;

  DateTimeFormatInfo DateTimeFormat;
  CompareInfo compareInfo;

  String Name;

  // PatternResources.ResourceManager.GetString(**var**, cultureInfo);
  String OffsetPatternLong;
  String OffsetPatternMedium;
  String OffsetPatternShort;

  String OffsetPatternLongNoPunctuation;
  String OffsetPatternMediumNoPunctuation;
  String OffsetPatternShortNoPunctuation;
}

class DateTimeFormatInfo {
  String AMDesignator;
  String PMDesignator;

  List<String> AbbreviatedDayNames;
  List<String> DayNames;
  List<String> MonthNames;
  List<String> AbbreviatedMonthNames;
  List<String> MonthGenitiveNames;
  List<String> AbbreviatedMonthGenitiveNames;

  // BCL Calendar Enumeration?
  Object Calendar;

  String GetEraName(int x) => "";

  String FullDateTimePattern;
  String ShortDatePattern;
  String LongDatePattern;
  String ShortTimePattern;
  String LongTimePattern;
}

abstract class IFormatProvider
{
  // Interface does not need to be marked with the serializable attribute
  Object GetFormat(Type formatType);
}