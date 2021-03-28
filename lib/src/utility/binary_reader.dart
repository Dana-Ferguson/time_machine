// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:convert';
import 'dart:typed_data';

import 'package:time_machine/src/time_machine_internal.dart';

// todo: collate into an input and output folder
@internal
class BinaryReader {
  // todo: should this be private?
  final ByteData binary;
  int _offset;

  bool get isMore => _offset < binary.lengthInBytes;

  BinaryReader(this.binary, [this._offset = 0]);

  int readInt32() { var i32 = binary.getInt32(_offset, Endian.little); _offset +=4; return i32; }
  // int readInt64() { var i64 = binary.getInt64(_offset, Endianness.LITTLE_ENDIAN); _offset +=8; print('READ ${i64}!!!!'); return i64; }
  int readUint8() => binary.getUint8(_offset++);
  bool readBool() => readUint8() == 1;
  Offset readOffsetSeconds() => Offset(read7BitEncodedInt());
  Offset readOffsetSeconds2() => Offset(readInt32());

  // JS Compatible version of readInt64
  int readInt64() {
    // var correctAnswer = binary.getInt64(_offset, Endianness.LITTLE_ENDIAN);
    var bytes = binary.buffer.asUint8List(_offset, 8);
    bool isNegative = getBit(bytes.last, 7);

    int i64 = 0;
    int value = 1;
    for(var byte in bytes) {
      if (isNegative) {
        i64 += (byte ^ 255) * value;
      }
      else {
        i64 += byte * value;
      }

      value *= 256;
    }

    if (isNegative) {
      i64 = -(i64+1);
    }

    _offset +=8;
    return i64;
  }

  bool getBit(int uint8, int bit) => (uint8 & (1 << bit)) != 0;

  bool get hasMoreData => binary.lengthInBytes < _offset;

  int read7BitEncodedInt() { //ByteData binary, int offset) {
    int count = 0;
    int shift = 0;
    int b;
    do {
      if (shift == 5 * 7) {
        throw StateError('7bitInt32 Format Error');
      }

      b = binary.getUint8(_offset++);
      count |= (b & 0x7F) << shift;
      shift += 7;
    } while ((b & 0x80) != 0);
    return count;
  }

  String readString() {
    int byteLength = read7BitEncodedInt();
    // var byteLength = _getStringByteCount(_offset, length);
    var bytes = binary.buffer.asUint8List(_offset, byteLength);
    _offset+=byteLength;
    return utf8.decode(bytes);
  }

  List<String> readStringList() {
    var tokens = <String>[];
    var count = read7BitEncodedInt();
    for (int i = 0; i < count; i++) {
      tokens.add(readString());
    }
    return tokens;
  }
}
