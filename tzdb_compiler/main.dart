// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:io';

// import 'package:time_machine/src/time_machine_internal.dart';
import 'package:path/path.dart' as path;

import 'compiler_options.dart';
import 'tzdb/tzdb_zone_info_compiler.dart';
import 'tzdb/cldr_windows_zone_parser.dart';
// import 'tzdb/tzdb_stream_writer.dart';
// import 'tzdb/named_id_mapping_support.dart';

// import 'tzdb/utility/binary_writer.dart';

/// Main entry point for the time zone information compiler. In theory we could support
/// multiple sources and formats but currently we only support one:
/// http://www.twinsun.com/tz/tz-link.htm. This system refers to it as TZDB.
/// This also requires a windowsZone.xml file from the Unicode CLDR repository, to
/// map Windows time zone names to TZDB IDs.

/// Runs the compiler from the command line.
///
/// <param name='arguments'>The command line arguments. Each compiler defines its own.</param>
/// <returns>0 for success, non-0 for error.</returns>
// int main_old(List<String> args) {
//   CompilerOptions options = CompilerOptions(args);

//   var tzdbCompiler = TzdbZoneInfoCompiler();
//   var tzdb = tzdbCompiler.compile(options.sourceDirectoryName);
//   tzdb.logCounts();
//   if (options.zoneId != null) {
//     tzdb.generateDateTimeZone(options.zoneId!);
//     return 0;
//   }

//   var windowsZones = LoadWindowsZones(options, tzdb.version);
//   if (options.windowsOverride != null) {
//     var overrideFile = CldrWindowsZonesParser.parseFile(options.windowsOverride!);
//     windowsZones = MergeWindowsZones(windowsZones, overrideFile);
//   }
//   LogWindowsZonesSummary(windowsZones);
//   var writer = TzdbStreamWriter();

//   var stream = BinaryWriter(CreateOutputStream(options));
//   {
//     writer.write(tzdb, windowsZones, NameIdMappingSupport.StandardNameToIdMap, stream);
//   }
//   stream.close();

//   if (options.outputFileName != null) {
//     print('Reading generated data and validating...');
//     // ignore: unused_local_variable
//     var source = Read(options);
//     throw Exception('need validation');
//     // source.validate();
//   }
//   return 0;
// }

void main(List<String> args) {
  // https://nodatime.org/tzdb/latest.txt --> https://nodatime.org/tzdb/tzdb2018g.nzd
  // https://data.iana.org/time-zones/releases/tzdata2018g.tar.gz
  var tzdbCompiler = TzdbZoneInfoCompiler();
  var tzdb = tzdbCompiler.compile('https://data.iana.org/time-zones/releases/tzdata2018g.tar.gz');
  tzdb.logCounts();
}

/// <summary>
/// Loads the best windows zones file based on the options. If the WindowsMapping option is
/// just a straight file, that's used. If it's a directory, this method loads all the XML files
/// in the directory (expecting them all to be mapping files) and then picks the best one based
/// on the version of TZDB we're targeting - basically, the most recent one before or equal to the
/// target version.
/// </summary>
WindowsZones LoadWindowsZones(CompilerOptions options, String targetTzdbVersion) {
  var mappingPath = options.windowsMapping;
  if (mappingPath == null) {
    throw Exception('No mappingPath was provided');
  }
  if (File(mappingPath).existsSync()) {
    return CldrWindowsZonesParser.parseFile(mappingPath);
  }
  if (!Directory(mappingPath).existsSync()) {
    throw Exception(
        '$mappingPath does not exist as either a file or a directory');
  }
  var xmlFiles = Directory(mappingPath)
      .listSync()
      .where((f) => f is File && f.path.endsWith('.xml'))
      .toList();
  if (xmlFiles.isEmpty) {
    throw Exception('$mappingPath does not contain any XML files');
  }
  var allFiles = xmlFiles
      .map((file) => CldrWindowsZonesParser.parseFile(file.path))
      .toList()
    ..sort((a, b) => a.tzdbVersion.compareTo(b.tzdbVersion));

  var versions = allFiles.map((z) => z.tzdbVersion).join(', ');

  var potentiallyBestFiles = allFiles
      .where((zones) => (zones.tzdbVersion.compareTo(targetTzdbVersion)) <= 0);
  if (potentiallyBestFiles.isEmpty) {
    throw Exception(
        'No zones files suitable for version $targetTzdbVersion. Found versions targeting: [$versions]');
  }
  var bestFile = potentiallyBestFiles.first;

  print("Picked Windows Zones with TZDB version ${bestFile
      .tzdbVersion} out of [$versions] as best match for $targetTzdbVersion");
  return bestFile;
}

void LogWindowsZonesSummary(WindowsZones windowsZones)
{
  print('Windows Zones:');
  print('  Version: ${windowsZones.version}');
  print('  TZDB version: ${windowsZones.tzdbVersion}');
  print('  Windows version: ${windowsZones.windowsVersion}');
  print('  ${windowsZones.mapZones.length} MapZones');
  print('  ${windowsZones.primaryMapping.length} primary mappings');
}

IOSink CreateOutputStream(CompilerOptions options)
{
  // If we don't have an actual file, just write to an empty stream.
  // That way, while debugging, we still get to see all the data written etc.
  if (options.outputFileName == null)
  {
    return stdout; // new MemoryStream();
  }

  String file = path.setExtension(options.outputFileName!, 'nzd');
  return File(file).openWrite();
}

// TzdbDateTimeZoneSource Read(CompilerOptions options)
// {
//   String file = path.setExtension(options.outputFileName!, 'nzd');
//   var stream = File(file).openRead();
//   return TzdbDateTimeZoneSource.FromStream(stream);
// }

/// Merge two WindowsZones objects together. The result has versions present in override,
/// but falling back to the original for versions absent in the override. The set of MapZones
/// in the result is the union of those in the original and override, but any ID/Territory
/// pair present in both results in the override taking priority, unless the override has an
/// empty 'type' entry, in which case the entry is removed entirely.
///
/// While this method could reasonably be in WindowsZones class, it's only needed in
/// TzdbCompiler - and here is as good a place as any.
///
/// The resulting MapZones will be ordered by Windows ID followed by territory.
/// </summary>
/// <param name='windowsZones'>The original WindowsZones</param>
/// <param name='overrideFile'>The WindowsZones to override entries in the original</param>
/// <returns>A merged zones object.</returns>
WindowsZones MergeWindowsZones(WindowsZones originalZones, WindowsZones overrideZones) {
  var version = overrideZones.version == ''
      ? originalZones.version
      : overrideZones.version;
  var tzdbVersion = overrideZones.tzdbVersion == '' ? originalZones
      .tzdbVersion : overrideZones.tzdbVersion;
  var windowsVersion = overrideZones.windowsVersion == '' ? originalZones
      .windowsVersion : overrideZones.windowsVersion;

  // Work everything out using dictionaries, and then sort.
  Map<Map<String, String>, MapZone> mapZones = {
    for (MapZone mz in originalZones.mapZones)
      {
        'windowsId': mz.windowsId,
        'territory': mz.territory,
      }:mz
  };

  for (var overrideMapZone in overrideZones.mapZones) {
    var key = {
      'windowsId': overrideMapZone.windowsId,
      'territory': overrideMapZone.territory
    };
    if (overrideMapZone.tzdbIds.isEmpty) {
      mapZones.remove(key);
    }
    else {
      mapZones[key] = overrideMapZone;
    }
  }

  var mapZoneList = (mapZones
      .entries
      .toList()
    ..sort((a, b) {
      // order by 'windowsId'
      var cmp = a.key['windowsId']!.compareTo(b.key['windowsId']!);
      if (cmp != 0) return cmp;

      // then by 'territory'
      return a.key['territory']!.compareTo(b.key['territory']!);
    }))
      .map((a) => a.value).toList();

  return WindowsZones(version, tzdbVersion, windowsVersion, mapZoneList);
}
