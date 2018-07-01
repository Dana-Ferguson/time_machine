// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:math' as math;

// todo: should this be called Utility? or even be packaged like it is?
abstract class Platform {
  static bool _checkForDartVM() {
    double n = 1.0;
    String s = n.toString();
    if (s == '1.0')
      return true;
    else if (s == '1') return false;

    return false;
  }

  static void startWeb() {
    _isWeb = true;
    _isVM = false;
  }

  static void startVM() {
    _isWeb = false;
    _isVM = true;
  }

  static Object dirtyCheck() {
    var isDartVM = _checkForDartVM();
    _isVM = isDartVM;
    _isWeb = !_isVM;
    return null;
  }

  static bool _isWeb = null;
  static bool _isVM = null;

  static bool get isWeb => _isWeb ?? dirtyCheck() ?? _isWeb;
  static bool get isVM => _isVM ?? dirtyCheck() ?? _isVM;

  static const intMaxValueJS = 9007199254740992; // math.pow(2, 53);
  static const intMinValueJS = -9007199254740992; // -math.pow(2, 53); appears to be the same (not 1 more, not 1 less)
  static const int32MinValue = -2147483648;
  static const int32MaxValue = 2147483647;
  static const int64MinValue = -9223372036854775808;
  static const int64MaxValue = 9223372036854775807;

  static int _intMaxValue = null;
  static int get intMaxValue => _intMaxValue ?? (_intMaxValue = _getIntMaxValue());
  static int _getIntMaxValue() {
    if (isVM) return math.pow(2, 63);
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

// todo: all of these may affect performance

// todo: only use this for porting... remove all of these later
@deprecated
class OutBox<T> {
  T value;
  OutBox(this.value);
}

// https://en.wikipedia.org/wiki/Modulo_operation
// we should only use this where 'x' can be negative
int arithmeticMod(num x, int y) {
  if (x >= 0) return x % y;
  return -((-x)%y);
}

// https://en.wikipedia.org/wiki/Arithmetic_shift#Handling_the_issue_in_programming_languages
// JS does bit shifting with two's complement preserved
// DartVM (like nearly everything else) does bit shifting arithmetically
// These shifts always work, so... I don't now if the `x>=0` check actually saves anytime or not.
int negRightShift(int x, int y) {
  return -(~x >> y) -1;
}

int negLeftShift(int x, int y) {
  return -~(x << y) -1;
}

int safeRightShift(int x, int y) => x >= 0 ? x >> y : -(~x >> y) -1; 
int safeLeftShift(int x, int y) => x >= 0 ? x << y : -~(x << y) -1;
