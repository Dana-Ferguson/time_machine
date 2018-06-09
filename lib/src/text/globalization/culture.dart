// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
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

class CultureInfo {
  static final CultureInfo invariantCulture = new CultureInfo._invariantCulture();
// todo: change this!

  static CultureInfo _currentCulture = null;
  static CultureInfo get currentCulture => _currentCulture??=invariantCulture;
  static void set currentCulture(CultureInfo value) => _currentCulture = value;

  bool get isReadOnly => true;

  final DateTimeFormatInfo dateTimeFormat;
  final CompareInfo compareInfo;

  final String name;
  static const invariantCultureId = "Invariant Culture";

  CultureInfo._invariantCulture()
      : dateTimeFormat = new DateTimeFormatInfoBuilder.invariantCulture().Build(),
        name = invariantCultureId,
        compareInfo = null
  ;

  CultureInfo(this.name, this.dateTimeFormat) : compareInfo = null;

  @override String toString() => name;
}
