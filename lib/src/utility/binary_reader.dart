import 'dart:convert';
import 'dart:typed_data';

import 'package:time_machine/time_machine.dart';

class BinaryReader {
  final ByteData binary;
  int _offset;

  BinaryReader(this.binary, [this._offset = 0]);

  int readInt32() { var i32 = binary.getInt32(_offset, Endianness.LITTLE_ENDIAN); _offset +=4; return i32; }
  int readInt64() { var i64 = binary.getInt64(_offset, Endianness.LITTLE_ENDIAN); _offset +=8; return i64; }
  int readUint8() => binary.getUint8(_offset++);
  bool readBool() => readUint8() == 1;
  Offset readOffsetSeconds() => new Offset.fromSeconds(read7BitEncodedInt());
  Offset readOffsetSeconds2() => new Offset.fromSeconds(readInt32());

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
    return UTF8.decode(bytes);
  }

  List<String> readStringList() {
    var tokens = new List<String>();
    var count = read7BitEncodedInt();
    for (int i = 0; i < count; i++) {
      tokens.add(readString());
    }
    return tokens;
  }

  // note: I just looked here: https://en.wikipedia.org/wiki/UTF-8 and then guessed a routine
  //    I'm sure there are much more clever and awesome algorithms out there for doing this
  //    Or even some way to just do this with the [UTF8.decoder]
  int _getUnicodeCodeSize(int o) {
    var b = binary.getUint8(o);
    if (b <= 127) return 1;
    if (b <= 191) return 0; // This is a tail byte
    if (b <= 223) return 2;
    if (b <= 239) return 3;
    if (b <= 247) return 4;
    throw new StateError('Impossible UTF-8 byte.');
  }

  int _getStringByteCount(int o, int charLength) {
    int byteCount = 0;

    // I'm not proud of this (turns out -- I didn't need this)
    for (int i = o; i < o+charLength; i++) {
      byteCount += _getUnicodeCodeSize(o);
    }

    return byteCount;
  }
}
