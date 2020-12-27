// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';

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

  static bool? dirtyCheck() {
    var isDartVM = _checkForDartVM();
    _isVM = isDartVM;
    _isWeb = !_isVM!;
    return null;
  }

  static bool? _isWeb;
  static bool? _isVM;

  static bool get isWeb => _isWeb ?? dirtyCheck() ?? _isWeb!;
  static bool get isVM => _isVM ?? dirtyCheck() ?? _isVM!;

  static const int intMaxValueJS = 9007199254740992; // math.pow(2, 53);
  static const int intMinValueJS = -9007199254740992; // -math.pow(2, 53); appears to be the same (not 1 more, not 1 less)
  static const int int32MinValue = -2147483648;
  static const int int32MaxValue = 2147483647;

  static const int maxMicrosecondsToNanoseconds = Platform.intMaxValueJS ~/ TimeConstants.microsecondsPerMillisecond;

  // representable in JS and VM: +\- 9223372036854775000 (but, constants in JS must be bounded by intMinValueJS and intMaxValueJS)
  // Fix for: https://github.com/dart-lang/sdk/issues/33282 <-- bizarre
  static const int valueCursorPrediction = 13860*66546695792603; // vm: 922337203685477580; js: 922337203685477600
  static const int int64MinValue = 2147483648 * 2147483648 * -2; // vm: -9223372036854775808; js: -9223372036854776000
  static const int int64MaxValue = 2147483648 * 2147483648 - 1 + 2147483648 * 2147483648; // vm: 9223372036854775807; js: 9223372036854776000

  static int _intMaxValue = isVM ? _intMaxValue = int64MaxValue : _intMaxValue = intMaxValueJS;
  static int _intMinValue = isVM ? _intMinValue = int64MinValue : _intMinValue = intMinValueJS;
  static int get intMaxValue => _intMaxValue;
  static int get intMinValue => _intMinValue;

  static BigInt? _bigIntMinValue ;
  static BigInt bigIntMinValue = _bigIntMinValue ??= BigInt.from(Platform.intMinValue);

  static BigInt? _bigIntMaxValue;
  static BigInt bigIntMaxValue = _bigIntMaxValue ??= BigInt.from(Platform.intMaxValue);
}

// todo: remove me
abstract class TimeZoneInfo {
// This is a BCL class
}

/// see: https://en.wikipedia.org/wiki/Modulo_operation
///
/// For performance, we should only use this where 'x' can be negative.
///
/// This returns a pattern consistent with duration based times
/// [-5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5]
/// [-2, -1,  0, -2, -1, 0, 1, 2, 0, 1, 2]
int arithmeticMod(num x, int y) {
  if (x >= 0) return x % y as int;
  return -((-x)%y) as int;
}

BigInt bigArithmeticMod(BigInt x, BigInt y) {
  if (x.isNegative) return -((-x)%y);
  return x % y;
}

/// This returns a pattern consistent with epoch (or calendar) based times
/// [-5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5]
/// [ 1,  2,  0,  1,  2, 0, 1, 2, 0, 1, 2]
int epochArithmeticMod(num x, int y) {
  if (x >= 0) return x % y as int;
  if (x >= 0) return x % y as int;
  return -(y-x)%y as int;
}

BigInt epochBigArithmeticMod(BigInt x, BigInt y) {
  if (x.isNegative) return -(y-x)%y;
  return x % y;
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
