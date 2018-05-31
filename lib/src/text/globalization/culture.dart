import 'dart:async';

import 'package:meta/meta.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_utilities.dart';

abstract class Cultures {
  static CultureLoader _loader = null;
  static Future<CultureLoader> get _cultures async => _loader??= await CultureLoader.load();

  static Future<Iterable<String>> get ids async => (await _cultures).cultureIds;
  static Future<CultureInfo> getCulture(String id) async => (await _cultures).getCulture(id);
}

// https://github.com/dotnet/coreclr/blob/master/src/System.Private.CoreLib/src/System/Globalization/CultureInfo.Unix.cs
// https://github.com/dotnet/coreclr/blob/master/src/System.Private.CoreLib/src/System/Globalization/CultureInfo.cs
@immutable
class CultureInfo {
  static final CultureInfo invariantCulture = new CultureInfo._invariantCulture();
  // todo: change this!
  static CultureInfo get currentCulture => invariantCulture;
  bool get isReadOnly => true;

  final DateTimeFormatInfo dateTimeFormat;
  final CompareInfo compareInfo;

  final String name;

  CultureInfo._invariantCulture()
      : dateTimeFormat = new DateTimeFormatInfo.invariantCulture(),
        name = "Invariant Culture",
        compareInfo = null
  ;

  CultureInfo(this.name, this.dateTimeFormat) : compareInfo = null;
}