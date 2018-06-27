// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';

import 'package:meta/meta.dart';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_utilities.dart';

@internal
abstract class ICultures {
  static void set currentCulture(CultureInfo value) => Cultures._currentCulture = value;
  static void loadAllCulturesInformation_SetFlag() {
    if (Cultures._loader != null) throw new StateError('loadAllCultures flag may not be set after Cultures are initalized.');
    Cultures._loadAllCulturesInformation = true;
  }
}

abstract class Cultures {
  // todo: this is a bandaid ~ we need to rework our infrastructure a bit -- maybe draw some diagrams?
  // This gives us the JS functionality of just minimizing our timezones, and it gives us the VM/Flutter functionality of just loading them all from one file.
  static bool _loadAllCulturesInformation = false;

  static CultureLoader _loader = null;
  static Future<CultureLoader> get _cultures async => _loader??= await (_loadAllCulturesInformation ? CultureLoader.loadAll() : CultureLoader.load());

  static Future<Iterable<String>> get ids async => (await _cultures).cultureIds;
  static Future<CultureInfo> getCulture(String id) async => (await _cultures).getCulture(id);

  static final CultureInfo invariantCulture = new CultureInfo._invariantCulture();

  // todo: we need a way to set this for testing && be able to set this with Platform Initialization (and have it not be changed at random)
  static CultureInfo _currentCulture = null;
  static CultureInfo get currentCulture => _currentCulture??=invariantCulture;
}

// todo: look to combine this with TimeMachineInfo and we can merge all the *_pattern.create*() functions!
@immutable
class CultureInfo {
  static final CultureInfo invariantCulture = new CultureInfo._invariantCulture();

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
