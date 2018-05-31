import 'package:meta/meta.dart';

// BCL fill-in
class CompareInfo {
  // Todo: look at uses, we need to know how much shim we need
}


abstract class IFormatProvider
{
  // Interface does not need to be marked with the serializable attribute
  Object GetFormat(Type formatType);
}