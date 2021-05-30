// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
// import 'package:time_machine/src/time_machine_internal.dart';
import 'dart:collection';
import 'package:meta/meta.dart';

/// Implements a thread-safe cache of a fixed size, with a single computation function.
/// (That happens to be all we need at the time of writing.)
///
/// For simplicity's sake, eviction is currently on a least-recently-added basis (not LRU). This
/// may change in the future.
///
/// [TKey]: Type of key
/// [TValue]: Type of value
@internal
class Cache<TKey, TValue> {
  final int _size;
  // @private final object mutex = new object();
  final TValue Function(TKey) _valueFactory;
  // todo: should be LinkedList?
  final Queue<TKey> _keyList;
  final Map<TKey, TValue> _dictionary;

  // todo: Do i want to make our own IEqualityComparer for use here?
  Cache(this._size, this._valueFactory /*, IEqualityComparer<TKey> keyComparer*/) :
        //   external factory LinkedHashMap(
        //      {bool equals(K key1, K key2),
        //      int hashCode(K key),
        //      bool isValidKey(potentialKey)});
        _dictionary = <TKey,TValue>{}, // Map<TKey,TValue>(/*keyComparer*/),
        _keyList = Queue<TKey>();

  /// Fetches a value from the cache, populating it if necessary.
  ///
  /// [key]: Key to fetch
  /// Returns: The value associated with the key.
  TValue getOrAdd(TKey key)
  {
    // lock (mutex)
    // First check the cache...
    TValue? cacheValue = _dictionary[key];
    if (cacheValue != null) {
      return cacheValue;
    }

    // Make space if necessary...
    while (_dictionary.length >= _size)
    {
      TKey firstKey = _keyList.removeFirst();
      _dictionary.remove(firstKey);
    }

    // Create and cache the new value
    final value = _valueFactory(key);
    _keyList.addLast(key);
    _dictionary[key] = value;
    return value;
  }

  /// Returns the number of entries currently in the cache, primarily for diagnostic purposes.
  int get count => _dictionary.length;

  /// Returns a copy of the keys in the cache as a list, for diagnostic purposes.
  List<TKey> get keys => List<TKey>.unmodifiable(_keyList);

  /// Clears the cache.
  void clear()
  {
    _keyList.clear();
    _dictionary.clear();
  }
}
