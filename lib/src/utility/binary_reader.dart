// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:convert';
import 'dart:typed_data';

import 'package:time_machine/src/time_machine_internal.dart';

import 'dart:io' as io;

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
  Offset readOffsetSeconds() => new Offset(read7BitEncodedInt());
  Offset readOffsetSeconds2() => new Offset(readInt32());

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
        throw new StateError('7bitInt32 Format Error');
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
    var tokens = new List<String>();
    var count = read7BitEncodedInt();
    for (int i = 0; i < count; i++) {
      tokens.add(readString());
    }
    return tokens;
  }
}


@internal
class BinaryWriter {
  static const _bufferSize = 1024 * 16;
  static const _bufferFlush = 1024 * 4;

  final ByteData _binary0 = ByteData(_bufferSize);
  final ByteData _binary1 = ByteData(_bufferSize);
  ByteData _binary;
  int _offset;
  int _bank;

  final io.IOSink _sink;

  // bool get isMore => _offset < _binary.lengthInBytes;

  BinaryWriter(this._sink) {
    _binary = _binary0;
    _bank = 0;
  }

  factory BinaryWriter.fromFile(String path) {
    var file = new io.File(path);
    return BinaryWriter(file.openWrite());
  }

  void _advance(int byteCount) {
    _offset += byteCount;
    if (byteCount > _bufferFlush) {
      _sink.add(_binary.buffer.asUint8List(0, _offset));
      // todo: do we need to do this?
      _sink.flush();
    }

    _offset = 0;
    switch (_bank) {
      case 0: {
          _bank = 1;
          _binary = _binary1;
          break;
        }
      case 1: {
        _bank = 0;
        _binary = _binary0;
        break;
      }
    }
  }

  void writeInt32(int value) {
    _binary.setInt32(_offset, value, Endian.little);
    _advance(4);
  }

  void writeUint8(int value) {
    _binary.setUint8(_offset, value);
    _advance(1);
  }

  void writeBool(bool value) {
    if (value) writeUint8(1);
    else writeUint8(0);
  }

  void writeOffsetSeconds(Offset value) {
    var seconds = value.inSeconds;
    if (seconds.isNegative) throw Exception('Value $value is negative which we can not 7 bit encode.');
    write7BitEncodedInt(seconds);
  }

  void writeOffsetSeconds2(Offset value) {
    writeInt32(value.inSeconds);
  }

  void writeInt64(int value) {
    _binary.setInt64(_offset, value, Endian.little);
    _advance(8);

    if (value > Platform.intMaxValueJS || value < Platform.intMinValueJS) {
      throw Exception('Value $value is not JS compatible.');
    }
  }


  // int readInt64() { var i64 = binary.getInt64(_offset, Endianness.LITTLE_ENDIAN); _offset +=8; print('READ ${i64}!!!!'); return i64; }
  // bool getBit(int uint8, int bit) => (uint8 & (1 << bit)) != 0;

  // bool get hasMoreData => _binary.lengthInBytes < _offset;

  void write7BitEncodedInt(int value) {
    if (value < 0) {
      throw Exception('Can not 7 bit encode negative numbers.');
    }

    while (value >= 0x80) {
      writeUint8((value | 0x80));
      value >>= 7;
    }

    writeUint8(value);
  }

  void writeString(String value) {
    var bytes = utf8.encode(value);
    write7BitEncodedInt(bytes.length);
    bytes.forEach((byte) => writeUint8(byte));
  }

  void writeStringList(List<String> list) {
    write7BitEncodedInt(list.length);
    list.forEach((value) => writeString(value));
  }
}