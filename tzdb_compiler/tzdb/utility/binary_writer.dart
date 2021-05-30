// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.
import 'dart:convert';
import 'dart:typed_data';

import 'package:time_machine/src/time_machine_internal.dart';

import 'dart:io' as io;

class MemoryStream implements io.IOSink {
  final List<int> buffer = [];
  int _position = 0;

  int get length => buffer.length;
  int get position => _position;
  set position(int value) {
    _position = value;
    buffer.length = _position;
  }

  void writeTo(BinaryWriter writer) {
    buffer.forEach((value) => writer.writeUint8(value));
  }

  @override
  late Encoding encoding;

  @override
  void add(List<int> data) {
    // this data must all be Uint8
    buffer.forEach((byte) {
      if (_position == buffer.length) buffer.add(byte);
      else buffer[_position] = byte;
      _position++;
    });
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    throw Exception('$error :: $stackTrace');
  }

  @override
  Future addStream(Stream<List<int>> stream) {
    throw Exception('not implemented');
  }

  @override
  Future close() async => null;

  @override
  Future get done async => null;

  @override
  Future flush() async => null;

  @override
  void write(Object? obj) {
    throw Exception('not implemented');
  }

  @override
  void writeAll(Iterable objects, [String separator = '']) {
    throw Exception('not implemented');
  }

  @override
  void writeCharCode(int charCode) {
    throw Exception('not implemented');
  }

  @override
  void writeln([Object? obj = '']) {
    throw Exception('not implemented');
  }
}

@internal
class BinaryWriter {
  static const _bufferSize = 1024 * 16;
  static const _bufferFlush = 1024 * 4;

  final ByteData _binary0 = ByteData(_bufferSize);
  final ByteData _binary1 = ByteData(_bufferSize);
  late ByteData _binary;
  late int _offset;
  late int _bank;

  final io.IOSink _sink;

  // bool get isMore => _offset < _binary.lengthInBytes;

  BinaryWriter(this._sink) {
    _binary = _binary0;
    _bank = 0;
    // _offset = 0 ???
  }

  factory BinaryWriter.fromFile(String path) {
    var file = io.File(path);
    return BinaryWriter(file.openWrite());
  }

  Future close() async {
    await _sink.flush();
    await _sink.close();
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
