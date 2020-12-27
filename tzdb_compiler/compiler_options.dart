// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:args/args.dart';

/// Defines the command line options that are valid.
class CompilerOptions
{
  final String? outputFileName;
  final String sourceDirectoryName; // = '';
  // todo: is this something we still need?
  final String? windowsMapping; // = '';
  final String? windowsOverride;

  /*[Option('z', "zone",
  Required = false,
  HelpText = 'Single zone ID to compile data for, for test purposes. (Incompatible with -o.)',
  MutuallyExclusiveSet = 'Output')] */
  final String? zoneId;

  CompilerOptions._(this.outputFileName, this.sourceDirectoryName, this.windowsMapping, this.windowsOverride, this.zoneId);

  factory CompilerOptions(List<String> args) {
    var parser = ArgParser();

    parser.addSeparator('Usage: NodaTime.TzdbCompiler -s <tzdb directory> -w <windowsZone.xml file/dir> -o <output file> [-t ResX/Resource/NodaZoneData]');

    // Required = false
    parser.addOption('output', abbr: 'o', defaultsTo: null, help: 'The name of the output file.');

    // Required = true, // defaultsTo: 'none'
    parser.addOption('source', abbr: 's', help: 'Source directory or archive containing the TZDB input files.');

    // Required = true;
    parser.addOption('windows', abbr: 'w', help: 'Windows to TZDB time zone mapping file (e.g. windowsZones.xml) or directory');

    // Required = false
    parser.addOption('windows-override', abbr: null, help: 'Additional \'override\' file providing extra Windows time zone mappings');

    var results = parser.parse(args);
    return CompilerOptions._(results['output'],
      results['source'],
      results['windows'],
      results['windows-override'],
      results['zone']);
  }
}
