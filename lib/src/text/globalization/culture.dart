// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:async';

import 'package:meta/meta.dart';
import 'package:time_machine/src/time_machine_internal.dart';

@internal
abstract class ICultures {
  static set currentCulture(Culture value) { Cultures._currentCulture = value; }
  static void loadAllCulturesInformation_SetFlag() {
    if (Cultures._loader != null) throw StateError('loadAllCultures flag may not be set after Cultures are initalized.');
    Cultures._loadAllCulturesInformation = true;
  }

  static bool get allCulturesLoaded => Cultures._loadAllCulturesInformation;
}

abstract class Cultures {
  // todo: this is a bandaid ~ we need to rework our infrastructure a bit -- maybe draw some diagrams?
  // This gives us the JS functionality of just minimizing our timezones, and it gives us the VM/Flutter functionality of just loading them all from one file.
  static bool _loadAllCulturesInformation = false;

  static CultureLoader? _loader;
  static Future<CultureLoader> get _cultures async => _loader??= await (_loadAllCulturesInformation ? CultureLoader.loadAll() : CultureLoader.load());

  static Future<Iterable<String>> get ids async => (await _cultures).cultureIds;
  static Future<Culture?> getCulture(String id) async => (await _cultures).getCulture(id);

  static final Culture invariantCulture = Culture._invariant();

  // todo: we need a way to set this for testing && be able to set this with Platform Initialization (and have it not be changed at random)
  static Culture? _currentCulture;
  static Culture get currentCulture => _currentCulture??=invariantCulture;
}

// todo: look to combine this with TimeMachineInfo and we can merge all the *_pattern.create*() functions!
@immutable
class Culture {
  static final Culture invariant = Culture._invariant();

  static Culture? _current;
  static Culture get current => _current??=invariant;
  static set current(Culture value) { _current = value; }

  bool get isReadOnly => true;

  final DateTimeFormat dateTimeFormat;
  // todo: remove, maybe?
  final CompareInfo? compareInfo;

  final String name;
  static const invariantId = 'Invariant Culture';

  Culture._invariant()
      : dateTimeFormat = DateTimeFormatBuilder.invariant().Build(),
        name = invariantId,
        compareInfo = null
  ;

  const Culture(this.name, this.dateTimeFormat) : compareInfo = null;

  @override String toString() => name;
}
