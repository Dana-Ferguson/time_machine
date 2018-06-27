// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

// BCL fill-in
class CompareInfo {
// Todo: look at uses, we need to know how much shim we need
}


abstract class IFormatProvider
{
  // Interface does not need to be marked with the serializable attribute
  Object getFormat(Type formatType);
}
