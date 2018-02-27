import 'package:time_machine/time_machine.dart';
import 'dart:collection';

/// <summary>
/// Implements a thread-safe cache of a fixed size, with a single computation function.
/// (That happens to be all we need at the time of writing.)
/// </summary>
/// <remarks>
/// For simplicity's sake, eviction is currently on a least-recently-added basis (not LRU). This
/// may change in the future.
/// </remarks>
/// <typeparam name="TKey">Type of key</typeparam>
/// <typeparam name="TValue">Type of value</typeparam>
@internal /*sealed*/ class Cache<TKey, TValue> {
  final int _size;
  // @private final object mutex = new object();
  final TValue Function(TKey) _valueFactory;
  // todo: should be LinkedList?
  final Queue<TKey> _keyList;
  final Map<TKey, TValue> _dictionary;

  @internal Cache(this._size, this._valueFactory /*, IEqualityComparer<TKey> keyComparer*/) :
        this._dictionary = new Map<TKey,TValue>(/*keyComparer*/),
        this._keyList = new Queue<TKey>();

  /// <summary>
  /// Fetches a value from the cache, populating it if necessary.
  /// </summary>
  /// <param name="key">Key to fetch</param>
  /// <returns>The value associated with the key.</returns>
  @internal TValue GetOrAdd(TKey key)
  {
    // lock (mutex)
    // First check the cache...
    TValue value = _dictionary[key];
    if (value != null) {
      return value;
    }

    // Make space if necessary...
    if (_dictionary.length == _size)
    {
      TKey firstKey = _keyList.first;
      _keyList.removeFirst();
      _dictionary.remove(firstKey);
    }

    // Create and cache the new value
    value = _valueFactory(key);
    _keyList.addLast(key);
    _dictionary[key] = value;
    return value;
  }

  /// <summary>
  /// Returns the number of entries currently in the cache, primarily for diagnostic purposes.
  /// </summary>
  @internal int get Count => _dictionary.length;


  /// <summary>
  /// Returns a copy of the keys in the cache as a list, for diagnostic purposes.
  /// </summary>
  @internal List<TKey> get Keys => new List<TKey>.unmodifiable(_keyList);

  /// <summary>
  /// Clears the cache.
  /// </summary>
  @internal void Clear()
  {
    _keyList.clear();
    _dictionary.clear();
  }
}