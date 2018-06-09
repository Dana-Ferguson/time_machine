// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

bool stringOrdinalIgnoreCaseEquals(String a, String b) {
  if (a.length != b.length) return false;

  var aRunes = a.codeUnits;
  var bRunes = b.codeUnits;

  var aRunesIter = aRunes.iterator;
  var bRunesIter = bRunes.iterator;

  while(aRunesIter.moveNext() && bRunesIter.moveNext()) {
    var aRune=aRunesIter.current;
    var bRune=bRunesIter.current;

    if (aRune <= 90) aRune += 0x20;
    if (bRune <= 90) bRune += 0x20;

    if (aRune != bRune) {
      return false;
    // return aRune - bRune; // If we want to do a standard Compare Operation
    }
  }

  return true;
// return a.length-b.length;
}

/*
public static int CompareOrdinal(
	string strA,
	int indexA,
	string strB,
	int indexB,
	int length
)

Parameters
  strA
  Type: System.String
  The first string to use in the comparison.

  indexA
  Type: System.Int32
  The starting index of the substring in strA.

  strB
  Type: System.String
  The second string to use in the comparison.

  indexB
  Type: System.Int32
  The starting index of the substring in strB.

  length
  Type: System.Int32
*/

// string.CompareOrdinal
int stringOrdinalCompare(String a, int aIndex, String b, int bIndex, int length) {
// if (a.length != b.length) return false;

  var aRunes = a.codeUnits;
  var bRunes = b.codeUnits;

  var aRunesIter = aRunes.skip(aIndex).iterator;
  var bRunesIter = bRunes.skip(bIndex).iterator;

  int i = 0;
  while(aRunesIter.moveNext() && bRunesIter.moveNext()) {
    if (i++ >= length) break;

    var aRune=aRunesIter.current;
    var bRune=bRunesIter.current;

//    if (aRune <= 90) aRune += 0x20;
//    if (bRune <= 90) bRune += 0x20;

    if (aRune != bRune) {
      return aRune.compareTo(bRune);
    // return aRune - bRune; // If we want to do a standard Compare Operation
    }
  }

  // return a.length-b.length;
  return 0;
}

int stringOrdinalIgnoreCaseCompare(String a, int aIndex, String b, int bIndex, int length) {
// if (a.length != b.length) return false;

  var aRunes = a.codeUnits;
  var bRunes = b.codeUnits;

  var aRunesIter = aRunes.skip(aIndex).iterator;
  var bRunesIter = bRunes.skip(bIndex).iterator;

  int i = 0;
  while(aRunesIter.moveNext() && bRunesIter.moveNext()) {
    if (i++ >= length) break;

    var aRune=aRunesIter.current;
    var bRune=bRunesIter.current;

    if (aRune <= 90) aRune += 0x20;
    if (bRune <= 90) bRune += 0x20;

    if (aRune != bRune) {
      return aRune.compareTo(bRune);
    // return aRune - bRune; // If we want to do a standard Compare Operation
    }
  }

  // return a.length-b.length;
  return 0;
}
