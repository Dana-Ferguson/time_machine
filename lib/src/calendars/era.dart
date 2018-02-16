// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Calendars/Era.cs
// 816afe8  on Dec 9, 2017

import 'package:meta/meta.dart';

import 'package:time_machine/time_machine.dart';


/// Represents an era used in a calendar.
///
/// <remarks>All the built-in calendars in Noda Time use the values specified by the static
/// read-only fields in this class. These may be compared for reference equality to check for specific
/// eras.</remarks>
// sealed
@immutable
class Era {
  /// The "Common" era (CE), also known as Anno Domini (AD). This is used in the ISO, Gregorian and Julian calendars.
  /// 
  /// <value>The "Common" era (CE), also known as Anno Domini (AD).</value>
  static const Era Common = const Era("CE", "Eras_Common");

  /// The "before common" era (BCE), also known as Before Christ (BC). This is used in the ISO, Gregorian and Julian calendars.
  /// 
  /// <value>The "before common" era (BCE), also known as Before Christ (BC).</value>
  static const Era BeforeCommon = const Era("BCE", "Eras_BeforeCommon");

  /// The "Anno Martyrum" or "Era of the Martyrs". This is the sole era used in the Coptic calendar.
  /// 
  /// <value>The "Anno Martyrum" or "Era of the Martyrs".</value>
  static const Era AnnoMartyrum = const Era("AM", "Eras_AnnoMartyrum");

  /// The "Anno Hegira" era. This is the sole era used in the Hijri (Islamic) calendar.
  /// 
  /// <value>The "Anno Hegira" era.</value>
  static const Era AnnoHegirae = const Era("EH", "Eras_AnnoHegirae");

  /// The "Anno Mundi" era. This is the sole era used in the Hebrew calendar.
  /// 
  /// <value>The "Anno Mundi" era.</value>
  static const Era AnnoMundi = const Era("AM", "Eras_AnnoMundi");

  /// The "Anno Persico" era. This is the sole era used in the Persian calendar.
  /// 
  /// <value>The "Anno Persico" era.</value>
  static const Era AnnoPersico = const Era("AP", "Eras_AnnoPersico");

  /// The "Bahá'í" era. This is the sole era used in the Wondrous calendar.
  /// 
  /// <value>The "Bahá'í" era.</value>
  static const Era Bahai = const Era("BE", "Eras_Bahai");

  @internal final String resourceIdentifier;

  /// Returns the name of this era, e.g. "CE" or "BCE".
  /// 
  /// <value>The name of this era.</value>
  final String name;

  @internal const Era(this.name, this.resourceIdentifier);

  
  /// Returns the name of this era.
  /// 
  /// <returns>The name of this era.</returns>
  @override String toString() => name;
}