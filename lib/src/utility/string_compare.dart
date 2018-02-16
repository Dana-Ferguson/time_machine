
bool ordinalIgnoreCaseStringEquals(String a, String b) {
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
