// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:meta/meta.dart';

abstract class IEra {
  static String resourceIdentifier(Era era) => era._resourceIdentifier;
}

/// Represents an era used in a calendar.
///
/// All the built-in calendars in Time Machine use the values specified by the static
/// read-only fields in this class. These may be compared for reference equality to check for specific
/// eras.
@immutable
class Era {
  /// The 'Common' era (CE), also known as Anno Domini (AD). This is used in the ISO, Gregorian and Julian calendars.
  static const Era common = Era._('CE', "Eras_Common");

  /// The 'before common' era (BCE), also known as Before Christ (BC). This is used in the ISO, Gregorian and Julian calendars.
  static const Era beforeCommon = Era._('BCE', "Eras_BeforeCommon");

  /// The 'Anno Martyrum' or "Era of the Martyrs". This is the sole era used in the Coptic calendar.
  static const Era annoMartyrum = Era._('AM', "Eras_AnnoMartyrum");

  /// The 'Anno Hegira' era. This is the sole era used in the Hijri (Islamic) calendar.
  static const Era annoHegirae = Era._('EH', "Eras_AnnoHegirae");

  /// The 'Anno Mundi' era. This is the sole era used in the Hebrew calendar.
  static const Era annoMundi = Era._('AM', "Eras_AnnoMundi");

  /// The 'Anno Persico' era. This is the sole era used in the Persian calendar.
  static const Era annoPersico = Era._('AP', "Eras_AnnoPersico");

  /// The "Bahá'í" era. This is the sole era used in the Wondrous calendar.
  static const Era bahai = Era._('BE', "Eras_Bahai");

  final String _resourceIdentifier;

  /// Returns the name of this era, e.g. 'CE' or "BCE".
  final String name;

  const Era._(this.name, this._resourceIdentifier);

  /// Returns the name of this era.
  @override String toString() => name;
}
