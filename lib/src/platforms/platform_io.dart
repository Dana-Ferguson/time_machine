// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';
import 'dart:typed_data';

import 'package:time_machine/src/time_machine_internal.dart';

/// This class packages platform specific input-output functions that are initialized by the appropriate Platform Provider
@isInternal
abstract class PlatformIO {
  @isInternal Future<ByteData> getBinary(String path, String filename);
  // JSON.decode returns a dynamic -- will this change in Dart 2.0?
  @isInternal Future<dynamic> getJson(String path, String filename);

  @isInternal static PlatformIO local;
}

Future initialize(dynamic arg) {
  throw Exception('Conditional Import Failure.');
}