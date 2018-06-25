// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:math' as math;
import 'package:logging/logging.dart';

// todo: should this be called Utility? or even be packaged like it is?
abstract class Utility {
  static final Logger _log = new Logger('Utility');

  // Log Levels:
  // FINEST, FINER, FINE, CONFIG, INFO, WARNING, SEVERE, SHOUT
  static void printAllLogs() {
    Logger.root.level = Level.CONFIG; // Level.ALL;
    Logger.root.onRecord.listen((LogRecord rec) {
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
    });
  }

  static bool _isDartVM = null;
  static bool get isDartVM => _isDartVM ??= _checkForDartVM();
  static bool _checkForDartVM() {
    double n = 1.0;
    String s = n.toString();
    if (s == '1.0')
      return true;
    else if (s == '1') return false;

    _log.warning('Performed simple isDart (or JS) check and it did not turn out as expected. s == $s;');

    return false;
  }

  static const intMaxValueJS = 9007199254740992; // math.pow(2, 53);
  static const intMinValueJS = -9007199254740992; // -math.pow(2, 53); appears to be the same (not 1 more, not 1 less)
  static const int32MinValue = -2147483648;
  static const int32MaxValue = 2147483647;
  static const int64MinValue = -9223372036854775808;
  static const int64MaxValue = 9223372036854775807;

  static int _intMaxValue = null;
  static int get intMaxValue => _intMaxValue ?? (_intMaxValue = _getIntMaxValue());
  static int _getIntMaxValue() {
    if (isDartVM) return math.pow(2, 63);
    return intMaxValueJS;
  }
}

@deprecated
class KeyValuePair<K, V> {
  final K key;
  final V value;
  KeyValuePair(this.key, this.value);

  static Iterable<KeyValuePair<K, V>> getPairs<K, V>(Map<K, V> map) sync* {
    var keys = map.keys.iterator;
    var values = map.values.iterator;

    while(keys.moveNext() && values.moveNext()) {
      yield new KeyValuePair(keys.current, values.current);
    }
  }
}

class LookUp<K, V> {
  Map<K, List<V>> _map = {};

  LookUp.fromMap(Map map, Function keySelector, Function valueSelector) {
    var kvpList = KeyValuePair.getPairs(map);
    kvpList.forEach((kvp) => _add(keySelector(kvp), valueSelector(kvp)));
  }

  LookUp.fromList(Iterable<KeyValuePair> kvpList, Function keySelector, Function valueSelector) {
    kvpList.forEach((kvp) => _add(keySelector(kvp), valueSelector(kvp)));
  }

  void _add(K k, V v) {
    var values = _map[k] ?? (_map[k] = new List<V>());
    values.add(v);
  }

  Iterable<V> operator[](K key) => _map[key];
}

abstract class TimeZoneInfo {
// This is a BCL class
}

abstract class IDateTimeZoneWriter {
//
}

// todo: only use this for porting... remove all of these later
@deprecated
class OutBox<T> {
  T value;
  OutBox(this.value);
}

// we should only use this where 'x' can be negative
int csharpMod(num x, int y) {
  if (x >= 0) return x % y;
  return -((-x)%y);
}
