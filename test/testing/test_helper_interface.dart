// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'test_helper.dart';

void setFunctions() {
  print('TEST OPERATOR FUNCTIONS NOT SET!');
  testOperatorComparisonFunction =
      <T>(T value, T equalValue, List<T> greaterValues) => null;
  testOperatorComparisonEqualityFunction =
      <T>(T value, T equalValue, List<T> greaterValues) => null;
  testOperatorEqualityFunction =
      <T>(T value, T equalValue, T unequalValue) => null;
}
