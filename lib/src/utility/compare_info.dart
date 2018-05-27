
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

  String ShortDatePattern;
  String LongDatePattern;
}