// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/text/globalization/time_machine_globalization.dart';

@internal
abstract class PatternResources
{
  // Resource files have a structure similar to:
  // ResourcesName.resx           Default resources
  //  ResourcesName.en.resx       General English Culture
  //    ResourcesName.en-AU.resx  Australian English Culture
  //    ResourcesName.en-US.resx  United States English Culture
  //    ResourcesName.en-GB.resx  United Kingdom English Culture
  //  ResourcesName.de.resx       General German Culture
  //    ResourcesName.de-AT.resx  Austrian German Culture
  //    ResourcesName.de-DE.resx  Germany's German Culture
  //    ResourcesName.de-CH.resx  Switzerland's German Culture
  // Since, Noda Time only has the Default, I'm assuming that is used for all cultures.
  // A quick, totally non exhaustive test, seems to confirm that.
  // For now, we'll just include this in code, we may change this to an Future<String> and
  // load from data files if the resource files get branched out.
  static String getString(String name, Culture culture) => _data[name]!;

  static final Map<String, String> _data = {
    'Eras_AnnoHegirae': 'A.H.|AH',
    'Eras_AnnoMartyrum': 'A.M.|AM',
    'Eras_AnnoMundi': 'A.M.|AM',
    'Eras_AnnoPersico': 'A.P.|AP',
    'Eras_Bahai': 'B.E.|BE',
    'Eras_BeforeCommon': 'B.C.|B.C.E.|BC|BCE',
    'Eras_Common': 'A.D.|AD|C.E.|CE',
    'OffsetPatternLong': '+HH:mm:ss',
    'OffsetPatternLongNoPunctuation': '+HHmmss',
    'OffsetPatternMedium': '+HH:mm',
    'OffsetPatternMediumNoPunctuation': '+HHmm',
    'OffsetPatternShort': '+HH',
    'OffsetPatternShortNoPunctuation': '+HH'
  };
}

